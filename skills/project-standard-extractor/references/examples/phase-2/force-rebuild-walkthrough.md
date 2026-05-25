# Force Rebuild Walkthrough

> phase 2 force-rebuild / restore / pin / unpin / list 五种 `output_action` 的走查样例。本样例为合成输入,不代表真实团队规则;真实运行必须替换为项目代码路径与实际 evidence。

本走查覆盖 4 段:

| 段 | 场景 | 关键输出 |
| --- | --- | --- |
| §1 | 完整成功 force-rebuild | dry-run 预览 / `confirm <domain>` / 备份目录树 / CHANGELOG 条目 |
| §2 | Quality Gate 失败 atomic rollback | failure.log 片段 / manifest.rollback / lock 释放 |
| §3 | restore 反向恢复 | `output_action=restore --restore=<ts>` / 脚本内部 .pre-restore-<now> |
| §4 | pin / unpin 管理 | manifest.json `pin: bool` 切换 / `--keep` 交互 |

---

## §1 完整成功 force-rebuild

### 1.1 输入

```yaml
project_paths:
  - /repo/mobile-app
output_action: force-rebuild
domain: 01-app-client
extraction_mode: full
run_mode: interactive
keep: 10
```

### 1.2 backup-manager dry-run 输出

```
== Force Rebuild Dry Run ==
domain: 01-app-client
backup target: tools/maintainer/project-standard-extractor/.local-backups/01-app-client/20260525T021045Z/
sha256 fingerprint: 9f2c4ab1...e7d3
files: 28  bytes: 184320
exclude: evidence/raw-*, temp/, .git
operator: leokuang
git head: be4e305 @ feat/project-standard-extractor (clean)
dimension activation summary:
  baseline=11 activated=4 candidate=2 pending=1 shallow=0
gitignore status: ok

输入 `confirm 01-app-client` 确认重生(其他输入将取消并释放 lock)
```

### 1.3 用户输入

```
confirm 01-app-client
```

(byte-equal 字面比对,大写 / 前后空格 / yes / y 都拒)

### 1.4 backup-manager 执行序列

```
1. mkdir tools/maintainer/project-standard-extractor/.local-backups/01-app-client/.lock                     ← 取 domain lock
2. tools/maintainer/project-standard-extractor/backup.sh --domain=01-app-client \
        --target=tools/maintainer/project-standard-extractor/.local-backups/01-app-client/20260525T021045Z/ ← payload 备份(--exclude evidence/raw-*, temp/, .git)
3. shasum -a 256 ... > manifest.json.sha256                    ← 完整性 fingerprint
4. mv engineering-standards/01-app-client \
      engineering-standards/01-app-client.broken-20260525T021045Z   ← atomic rename(原子操作,最小窗口)
5. (phase 2 default `full` 管道执行:profile → batch → activator → ... → merge)
6. bash tools/maintainer/project-standard-extractor/force-rebuild-validate.sh \
        --domain=01-app-client \
        --backup-dir=tools/maintainer/project-standard-extractor/.local-backups/01-app-client/20260525T021045Z/
   stdout: {"valid": true, "checks": {...}}
   exit: 0
7. (调用 changelog-append helper,见 1.6)
8. rm -rf engineering-standards/01-app-client.broken-20260525T021045Z   ← changelog 成功后删除旧点位
9. rmdir tools/maintainer/project-standard-extractor/.local-backups/01-app-client/.lock                     ← 释放 lock
```

### 1.5 备份目录树

```
tools/maintainer/project-standard-extractor/.local-backups/01-app-client/
├── 20260525T021045Z/                       ← 本次 backup_id
│   ├── manifest.json                        ← {sha256, files, bytes, operator, run_id, pin: false, ...}
│   ├── manifest.json.sha256
│   └── payload/
│       ├── standard-android.md
│       ├── standard-kmp-shared.md
│       ├── ...
│       └── evidence/
└── (前 10 份历史备份按 UTC-ts 字典序;触发 `--keep=10` 时滚动清理最老的非 pinned)
```

### 1.6 CHANGELOG 追加(根 `CHANGELOG.md`)

```markdown
- v0.1.0 2026-05-25 02:11:08 leokuang: 01-app-client 重生(baseline=11 activated=4 candidate=2 pending=1 shallow=0,backup: tools/maintainer/project-standard-extractor/.local-backups/01-app-client/20260525T021045Z/) (user-visible)
```

(作者从 `.claude/spec-first/.developer` 读 `name: leokuang`;version 从 CHANGELOG 头部继承 `0.1.0`)

### 1.7 验收命令

```bash
# 1. validate 通过
bash tools/maintainer/project-standard-extractor/force-rebuild-validate.sh \
     --domain=01-app-client \
     --backup-dir=tools/maintainer/project-standard-extractor/.local-backups/01-app-client/20260525T021045Z/; echo $?
# 期望: 0

# 2. broken-ts 已删
ls engineering-standards/01-app-client.broken-* 2>&1 | grep -q "No such" && echo "ok"

# 3. lock 已释放
test ! -d tools/maintainer/project-standard-extractor/.local-backups/01-app-client/.lock && echo "ok"

# 4. CHANGELOG 含 run_id
grep -c "20260525T021045Z" CHANGELOG.md   # 期望 ≥ 1
```

---

## §2 Quality Gate 失败 atomic rollback

### 2.1 输入(同 §1.1)

### 2.2 异常注入

第 5 步 phase 2 管道 review-and-quality-gate 输出 `engineering-standards/01-app-client/temp/<run_id>-review-summary.md` 的 `quality_gate_decisions:` 段含一行(line-level):

```yaml
- source_doc: 01-app-client/standard-android.md
  section_title: "[FORBIDDEN] DataStore 主线程访问"
  status: blocked          ← line-level grep 命中
  evidence_result: pass
  ai_executability_result: block
  reason: 缺少 evidence file_path
```

### 2.3 backup-manager step 10 dispatcher 行为

```
1. grep -cE '^[[:space:]]*status:[[:space:]]*(blocked|conflict)' engineering-standards/01-app-client/temp/<run_id>-review-summary.md
   → 1(命中)
2. 跳过 force-rebuild-validate.sh
3. rm -rf engineering-standards/01-app-client     ← 破损产物清除
4. mv engineering-standards/01-app-client.broken-20260525T021045Z \
      engineering-standards/01-app-client          ← 反向 atomic rename(回滚)
5. 写 tools/maintainer/project-standard-extractor/.local-backups/01-app-client/20260525T021045Z/failure.log:
```

### 2.4 failure.log 片段

```
force-rebuild-failure.v1
run_id: 20260525T021045Z-01-app-client
domain: 01-app-client
operator: leokuang
failure_reason: QUALITY_GATE_BLOCKED
failed_check: quality_gate_decisions[].status == blocked
failed_at: 2026-05-25T02:14:32Z
rolled_back_at: 2026-05-25T02:14:33Z
rollback_action: reverse-atomic-rename
rollback_source: engineering-standards/01-app-client.broken-20260525T021045Z
rollback_target: engineering-standards/01-app-client
recommended_action: 检查 engineering-standards/01-app-client/temp/<run_id>-review-summary.md 中 blocked 项的 reason,补充 evidence 后重新调用
```

### 2.5 manifest.rollback 段

```json
{
  "backup_id": "20260525T021045Z",
  "domain": "01-app-client",
  "operator": "leokuang",
  "pin": false,
  "rollback": {
    "rolled_back_at": "2026-05-25T02:14:33Z",
    "failure_reason": "QUALITY_GATE_BLOCKED",
    "failure_log_path": "tools/maintainer/project-standard-extractor/.local-backups/01-app-client/20260525T021045Z/failure.log",
    "validation_failure": "quality_gate_decisions[].status: blocked"
  }
}
```

### 2.6 关键不变量

- 根 `CHANGELOG.md` **不**追加(失败不留痕)
- `tools/maintainer/project-standard-extractor/.local-backups/01-app-client/.lock` 已 `rmdir` 释放
- `engineering-standards/01-app-client/` 内容与 `tools/maintainer/project-standard-extractor/.local-backups/01-app-client/20260525T021045Z/` 一致(sha256 校验通过)
- 备份点 `20260525T021045Z` 保留(供 host developer 复盘 + restore)
- **不**保留 `in-progress.lock`(避免后续 stuck)

---

## §3 restore — 从指定备份恢复

### 3.1 触发场景

用户对 `force-rebuild` 后的新规范不满意,要回退到历史某个备份点。

### 3.2 输入

```yaml
output_action: restore
domain: 01-app-client
restore_from: 20260524T130000Z          # 必须与 backup_id 字面一致
run_mode: interactive                    # restore 不强制 interactive,但建议
```

### 3.3 backup-manager 行为(只读 + cp -a,不创建新 backup)

```
1. mkdir tools/maintainer/project-standard-extractor/.local-backups/01-app-client/.lock
2. 校验 tools/maintainer/project-standard-extractor/.local-backups/01-app-client/20260524T130000Z/ 存在 + manifest.json schema / manifest.json.sha256 / domain+backup_id 身份校验通过
3. tools/maintainer/project-standard-extractor/backup.sh --restore --domain=01-app-client \
         --source=tools/maintainer/project-standard-extractor/.local-backups/01-app-client/20260524T130000Z/            ← 从 payload 恢复内容
   脚本内部: mv engineering-standards/01-app-client \
      engineering-standards/01-app-client.pre-restore-20260525T021830Z
   校验 restore source 与恢复后目录 file_count / byte_count / sha256_fingerprint 均等于 manifest.stats
   校验成功后删除 .pre-restore-20260525T021830Z
4. (调用 changelog-append helper,event_type: restore)
5. rmdir tools/maintainer/project-standard-extractor/.local-backups/01-app-client/.lock
```

### 3.4 CHANGELOG 追加

```markdown
- v0.1.0 2026-05-25 02:18:30 leokuang: 01-app-client 恢复至备份 20260524T130000Z (user-visible)
```

### 3.5 与 force-rebuild 的差异

| 维度 | force-rebuild | restore |
| --- | --- | --- |
| 是否创建新 backup | ✅(本次执行点) | ❌(只读历史 backup) |
| atomic rename 操作 | `<domain>` → `<domain>.broken-<ts>` | `backup.sh --restore` 内部 `<domain>` → `<domain>.pre-restore-<now>` |
| 失败回滚 | 反向 mv `<broken>` → `<domain>` | 脚本内部反向 mv `<pre-restore>` → `<domain>` |
| 是否要求 interactive | ✅ 强制(强制边界 #10) | ❌ 不强制(只恢复历史 payload) |
| 是否进 phase 2 管道 | ✅ 必走 | ❌ 不进管道 |
| validate.sh 校验 | ✅ 4 项 | ❌ 跳过(校验 manifest schema / manifest.json.sha256 / domain+backup_id / stats 三元组) |

### 3.6 失败回滚

restore 任意步骤失败:

- manifest schema / sha256 / domain+backup_id / payload stats 校验失败 → 拒绝执行,不改 `engineering-standards/<domain>/`
- `backup.sh --restore` copy 或恢复后 stats 校验失败 → 脚本反向 mv `<pre-restore>` → `<domain>`
- `.pre-restore-<now>` 删除失败 → host developer 看到残留,可手动 `rm -rf` 处理(不阻塞下次 restore)

---

## §4 pin / unpin — 标记备份保留状态

### 4.1 触发场景

某次 force-rebuild 产出的新规范是关键反悔点(例如 phase 2 升级前的最后一个稳定版),host developer 希望即使后续 force-rebuild 累计超过 `--keep=10` 也保留这份。

### 4.2 输入(pin)

```yaml
output_action: pin
domain: 01-app-client
restore_from: 20260524T130000Z          # 要 pin 的 backup_id
```

### 4.3 backup-manager 行为(只改 manifest.json)

```
1. mkdir tools/maintainer/project-standard-extractor/.local-backups/01-app-client/.lock
2. 读 tools/maintainer/project-standard-extractor/.local-backups/01-app-client/20260524T130000Z/manifest.json
3. 改 pin: false → pin: true
4. 写回 manifest.json
5. shasum -a 256 manifest.json > manifest.json.sha256   ← 重新计算
6. rmdir tools/maintainer/project-standard-extractor/.local-backups/01-app-client/.lock
```

(**不**追加 CHANGELOG;pin / unpin 不算 source 变更)

### 4.4 manifest.json 关键字段

```json
{
  "backup_id": "20260524T130000Z",
  "domain": "01-app-client",
  "operator": "leokuang",
  "created_at": "2026-05-24T13:00:00Z",
  "git_head": "374c0de",
  "git_branch": "feat/project-standard-extractor",
  "files": 27,
  "bytes": 178944,
  "sha256": "9f2c4ab1...",
  "pin": true,                          ← 切换字段
  "extraction_mode": "full",
  "dimension_activation_summary": {
    "baseline": 11, "activated": 4, "candidate": 2, "pending": 1, "shallow": 0
  }
}
```

### 4.5 与 `--keep=N` 清理交互

假设当前 `tools/maintainer/project-standard-extractor/.local-backups/01-app-client/` 有 12 份(其中 `20260524T130000Z` pinned),用户调用 `force-rebuild keep: 10`:

- 备份新增 1 份 → 总 13 份
- 清理算法:跳过 pinned → 非 pinned 共 12 份 → 保留最近 10 份非 pinned + 1 pinned = 11 份
- 即使连续跑 6 次 force-rebuild,pinned 始终保留

### 4.6 输入(unpin)

```yaml
output_action: unpin
domain: 01-app-client
restore_from: 20260524T130000Z
```

(与 pin 对称,只是 `pin: true → false`)

### 4.7 老备份兼容(无 `pin` 字段)

phase 2 升级前的 backup manifest 可能不含 `pin` 字段。`references/config/backup/manifest-schema.json` 把 `pin` 标必填 + default = false,实际处理时:

- 缺字段 → 视为 `pin: false`(向后兼容)
- 不阻塞清理算法
- 下次 pin / unpin 该 backup 时自动补全 `pin` 字段

### 4.8 list 子命令(配合 pin / restore 使用)

```yaml
output_action: list
domain: 01-app-client
```

输出表格:

```
| backup_id          | created_at           | git_head  | pin   | size    |
| ------------------ | -------------------- | --------- | ----- | ------- |
| 20260525T021045Z   | 2026-05-25 02:10:45Z | be4e305   | false | 184.3KB |
| 20260524T130000Z   | 2026-05-24 13:00:00Z | 374c0de   | true  | 178.9KB |
| 20260523T084500Z   | 2026-05-23 08:45:00Z | 4a1d53c   | false | 175.2KB |
| ...                                                                     |
```

(按 `backup_id` 字典序 = UTC 时序;pin 列直观显示哪些备份不会被自动清理)

---

## 引用

- `references/agents/backup-manager.md`(决策算法 12 步 + Step 10 dispatcher)
- `references/prompts/orchestrator/force-rebuild/force-rebuild.md`(主流程 + §rollback + §changelog)
- `references/prompts/orchestrator/force-rebuild/changelog-append.md`(success path 追加 helper)
- `tools/maintainer/project-standard-extractor/force-rebuild-validate.sh`(4 项确定性 check)
- 项目级 `docs/evals/project-standard-extractor/dimension-framework/force-rebuild-cases.md`(对应 9 个 Given/When/Then 回归 case)
- `SKILL.md` 调用协议(用户视角的输入字段 + blocked runtime 边界)
- `references/quality-gate.md §5.5`(force-rebuild 模式下双门禁失败回滚链路)
