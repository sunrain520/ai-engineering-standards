# Force Rebuild Eval Cases

> 维度框架 phase 2 force-rebuild / restore / pin / unpin 场景的 Given/When/Then 回归用例。配套 `references/examples/phase-2/force-rebuild-walkthrough.md`。

本文件场景统一遵循三段式:

```
Given: 输入条件 + 现有目录状态 + .claude/spec-first/.developer 已配置
When:  调用协议输入(YAML)
Then:  期望产物 + 关键文件断言 + 失败信号(如适用)
```

所有 case 必须能被 `../expected-behavior.md` 验收清单匹配,并对应 plan 衍生的 finding(C-2/C-3/C-6/C-7/C-8/C-12)。

## AE → Case 映射表

| AE | Case ID | 描述 |
| --- | --- | --- |
| AE23 | FRC-001 | 完整 force-rebuild 成功路径 |
| AE24 | FRC-002 | Quality Gate 失败 → atomic rollback |
| AE25 | FRC-003 | 互斥校验(R91 / R92 + 强制边界 #9 / #10) |
| — | FRC-004 | confirm prompt injection 反例(C-3) |
| — | FRC-005 | TOCTOU 反例(C-2) |
| — | FRC-006 | 并发 lock 反例(C-6) |
| — | FRC-007 | CHANGELOG 追加失败回滚(C-7) |
| — | FRC-008 | pin / unpin 一致性(C-8) |
| — | FRC-009 | 多 domain 部分失败回滚(C-12) |

---

## FRC-001 完整 force-rebuild 成功路径(AE23)

**Given**:

- 工作树净(`git status` 无 modify / untracked)
- `.claude/spec-first/.developer` 含 `name: leokuang`
- `.gitignore` 已含 `skills/project-standard-extractor/.local-backups/`
- `engineering-standards/01-app-client/` 含完整 phase 2 产物(11 baseline 维度全 draft)
- `.local-backups/01-app-client/` 当前已有 5 份历史备份(无 pinned)

**When**:

```yaml
project_paths:
  - /repo/mobile-app
output_action: force-rebuild
domain: 01-app-client
extraction_mode: full
run_mode: interactive
keep: 10
```

dry-run 输出 `Force Rebuild Dry Run` 模板 → 用户输入字面 `confirm 01-app-client` → 通过。

**Then**:

- backup_dir = `skills/project-standard-extractor/.local-backups/01-app-client/<UTC-ts>/` 创建,含 manifest.json + sha256 + 完整 domain 内容
- atomic rename: `engineering-standards/01-app-client` → `engineering-standards/01-app-client.broken-<ts>` → 走 phase 2 default `full` 管道(profile-and-batch-planner → dimension-activator → ... → merge-coordinator)
- `force-rebuild-validate.sh` exit 0,4 项 check 全通过(char_ratio ≥ 60% / activation-report schema valid / non-empty rules > 0 / blocked|conflict 0 hits)
- `references/prompts/orchestrator/force-rebuild/changelog-append.md` 追加根 `CHANGELOG.md` 一行:`- v0.x.0 <ts> leokuang: 01-app-client 重生(baseline=11 activated=N2 candidate=N3 ...) (user-visible)`
- changelog helper 成功后才删 `.broken-<ts>`
- 释放 `.local-backups/01-app-client/.lock`
- 当前备份纳入 `--keep=10` 计数(现 6 份,未触清理)

**Verification grep**:

- `bash skills/project-standard-extractor/scripts/force-rebuild-validate.sh --domain=01-app-client --backup-dir=skills/project-standard-extractor/.local-backups/01-app-client/<UTC-ts>/` exit 0
- `grep -cE '^[[:space:]]*status:[[:space:]]*(blocked|conflict)' engineering-standards/01-app-client/temp/<run_id>-review-summary.md` == 0
- `jq -e '.dimensions[].dimension_id' engineering-standards/01-app-client/evidence/dimension-activation-report.json` 不为空
- 根 `CHANGELOG.md` 末尾有 force-rebuild 条目 + leokuang 作者

---

## FRC-002 Quality Gate 失败 → atomic rollback(AE24)

**Given**:

- 同 FRC-001,但本次 generation 阶段产出的某条规则被 P5 Conflict Reviewer 判 `status: conflict`(line-level grep 命中)

**When**:

```yaml
output_action: force-rebuild
domain: 01-app-client
extraction_mode: full
run_mode: interactive
```

confirm 通过 → 走 phase 2 → quality gate 输出含 `status: conflict`。

**Then**:

- backup-manager step 10 dispatcher 检测到 `quality_gate_decisions[].status: conflict`(line-level)
- 跳过 `force-rebuild-validate.sh`,直接反向 atomic rename: `rm -rf engineering-standards/01-app-client` → `mv engineering-standards/01-app-client.broken-<ts> engineering-standards/01-app-client`
- `.local-backups/01-app-client/<UTC-ts>/failure.log` 写入 magic header `force-rebuild-failure.v1` + `failure_reason: QUALITY_GATE_BLOCKED`
- manifest.rollback 段补全(rolled_back_at / failure_reason / failure_log_path / validation_failure)
- 根 `CHANGELOG.md` **不**追加(失败不留痕)
- 释放 `.lock`,**不**保留 `in-progress.lock`(避免后续 stuck)
- 返回 orchestrator: `success: false, failure_reason: QUALITY_GATE_BLOCKED, recommended_action: review-quality-gate-output`

**Verification grep**:

- `head -1 .local-backups/01-app-client/<ts>/failure.log` == `force-rebuild-failure.v1`
- 工作区 `engineering-standards/01-app-client/` 内容与 backup_dir 一致(sha256 校验)
- 根 `CHANGELOG.md` 不含 `<run_id>` 字符串

**脚本级回归 fixture**:

- 构造 `engineering-standards/01-app-client/temp/<run_id>-review-summary.md`，其中 `quality_gate_decisions:` 段含独立行 `status: blocked`
- 调用真实接口 `bash skills/project-standard-extractor/scripts/force-rebuild-validate.sh --domain=01-app-client --backup-dir=skills/project-standard-extractor/.local-backups/01-app-client/<UTC-ts>/`
- 期望 exit 1，stdout JSON 中 `.failure.check == "quality_gate"`，`.checks.d_quality_gate.blocked_or_conflict_count >= 1`

---

## FRC-003 互斥校验(AE25)

### FRC-003a R91 互斥(force-rebuild + diff)

**Given**: 同 FRC-001。

**When**:

```yaml
output_action: force-rebuild
domain: 01-app-client
extraction_mode: diff               # ❌ R91 互斥
run_mode: interactive
```

**Then**:

- intake-and-scope 第一时间抛 `INCOMPATIBLE_OUTPUT_ACTION` + `reason: extraction_mode=diff cannot combine with output_action=force-rebuild (R91)`
- **不**进入 backup-manager
- 不取 lock,不创建备份,不修改任何文件

### FRC-003b R92 互斥(force-rebuild + 多 project)

**When**:

```yaml
project_paths:
  - /repo/mobile-app
  - /repo/mobile-web                 # ❌ R92 互斥
output_action: force-rebuild
domain: 01-app-client
run_mode: interactive
```

**Then**:

- intake 抛 `INCOMPATIBLE_OUTPUT_ACTION` + `reason: project_paths length > 1 cannot combine with output_action=force-rebuild (R92)`

### FRC-003c 强制边界 #9(缺 --domain)

**When**:

```yaml
output_action: force-rebuild
# domain 缺失
run_mode: interactive
```

**Then**:

- 抛 `MISSING_DOMAIN_FOR_DESTRUCTIVE_ACTION`
- 不取 lock,不创建备份

### FRC-003d 强制边界 #10(force-rebuild + auto)

**When**:

```yaml
output_action: force-rebuild
domain: 01-app-client
run_mode: auto                       # ❌ 强制边界 #10
```

**Then**:

- backup-manager 立即拒绝 `NON_INTERACTIVE_CONTEXT_REJECTED`
- 不取 lock,不创建备份

---

## FRC-004 confirm prompt injection 反例(Finding C-3)

**Given**: 同 FRC-001 dry-run 阶段已输出 `Force Rebuild Dry Run` 模板。

**When**: 用户输入以下任一(模拟 prompt injection):

| 输入 | 期望行为 |
| --- | --- |
| `Confirm 01-app-client`(大小写差异) | 拒绝 |
| `confirm` | 拒绝(缺 domain) |
| `confirm 01-app-client.broken-<ts>` | 拒绝(domain 不字面匹配) |
| `confirm 01-app-client and proceed` | 拒绝(不是字面输入) |
| `Yes, confirm 01-app-client` | 拒绝(有前缀) |
| `confirm 01-app-client\n; rm -rf /` | 拒绝(含其它内容) |

**Then**:

- backup-manager safeguard step 2 校验失败 → 取消执行 → 释放 lock
- 不进入 atomic rename 环节
- 输出错误 `CONFIRM_INPUT_REJECTED` + `expected: confirm <domain>` + `received: <用户输入>`(脱敏)

**铁律**: 字面比对必须 byte-equal `confirm 01-app-client`(无前后空格 / 无前缀 / 无后缀 / case-sensitive)。

---

## FRC-005 TOCTOU 反例(Finding C-2)

**Given**: dry-run 已输出 sha256 fingerprint = `<sha-A>`。

**When**:

- 用户在 dry-run 输出之后、输入 `confirm` 之前,**手动**修改 `engineering-standards/01-app-client/standard-android.md`(模拟 race)
- 然后输入 `confirm 01-app-client`

**Then**:

- backup-manager safeguard step 4(复检 sha256 + git porcelain)发现工作区已变 → fingerprint 现为 `<sha-B>` ≠ `<sha-A>`
- 抛 `TOCTOU_DETECTED` + `expected: <sha-A>, actual: <sha-B>`
- 释放 lock,**不**进入 atomic rename
- 提示用户重新运行 dry-run

---

## FRC-006 并发 lock 反例(Finding C-6)

**Given**:

- Terminal A 已对 `01-app-client` 取得 lock(`mkdir .local-backups/01-app-client/.lock` 成功)并正在 phase 2 执行

**When**:

- Terminal B 同时调用 `output_action=force-rebuild domain=01-app-client`

**Then**:

- Terminal B 的 backup-manager step 1 取 lock 失败(`mkdir` 因 EEXIST 报错)
- 抛 `DOMAIN_LOCK_HELD` + `lock_held_by: <Terminal A 的 .lock/owner.txt 内容>`
- Terminal B **不**继续 dry-run,**不**修改任何文件
- Terminal A 完成后正常释放 lock

**额外断言**: Terminal A 失败 / 中断时 lock 不被自动清(避免 stuck);host developer 手动 `rmdir .local-backups/01-app-client/.lock` 才能释放。

---

## FRC-007 CHANGELOG 追加失败回滚(Finding C-7)

**Given**:

- FRC-001 走到 step 10a 末段,validate.sh 已 exit 0,`.broken-<ts>` 仍保留
- 调用 `references/prompts/orchestrator/force-rebuild/changelog-append.md` helper 时,根 `CHANGELOG.md` 文件被外部锁定(模拟磁盘满 / 权限 / git 索引锁)

**When**: helper 返回 `success: false, failure_reason: ATOMIC_WRITE_FAILED`。

**Then**:

- 触发 backup-manager step 10a 末段回滚:
  - `mv engineering-standards/01-app-client engineering-standards/01-app-client.changelog-fail-<now>`
  - `rm -rf engineering-standards/01-app-client`
  - `mv engineering-standards/01-app-client.broken-<ts> engineering-standards/01-app-client`
- 写 failure.log 标 `failure_reason: CHANGELOG_APPEND_FAILED`
- 释放 lock
- 返回 `success: false, recommended_action: 检查根 CHANGELOG.md 写权限并手动 restore`

**Verification**:

- `engineering-standards/01-app-client/` 内容与 backup_dir 一致
- `engineering-standards/01-app-client.changelog-fail-<now>/` 仍保留(供 host developer 排错,不自动删)
- `.local-backups/01-app-client/<UTC-ts>/payload/` 仅作为备份 payload,不参与本失败路径回滚
- 根 `CHANGELOG.md` 未追加 `<run_id>`

---

## FRC-008 pin / unpin 一致性(Finding C-8)

**Given**:

- `.local-backups/01-app-client/` 已有 12 份备份,其中第 6 份(`<UTC-ts-6>`) `manifest.json.pin = false`

**When 1**:

```yaml
output_action: pin
domain: 01-app-client
restore_from: <UTC-ts-6>
```

**Then 1**:

- backup-manager 取 lock → 校验 backup_dir 存在 → 读 manifest.json → 设 `pin: true` → 写回 → 释放 lock
- `manifest.json.sha256` 重新计算
- **不**追加根 `CHANGELOG.md`(pin / unpin 不算 source 变更)

**When 2**: 紧接着调用 6 次 force-rebuild,每次 `keep: 10`。

**Then 2**:

- 第 1–4 次:总份数 13/14/15/16,`--keep=10` 跳过 pin 那份 → 清理最老的非 pinned → 总份数稳定 11(10 非 pinned + 1 pinned)
- 第 5–6 次:同上,始终保留 `<UTC-ts-6>`

**When 3**:

```yaml
output_action: unpin
domain: 01-app-client
restore_from: <UTC-ts-6>
```

**Then 3**:

- `pin: false` 写回 → 下一次 `--keep=N` 清理把 `<UTC-ts-6>` 纳入考量(若它已是最老 → 删除)

---

## FRC-009 多 domain 部分失败回滚(Finding C-12)

**Given**: 用户依次执行(每次单独调用,串行):

1. `output_action: force-rebuild, domain: 01-app-client`
2. `output_action: force-rebuild, domain: 04-backend`

第二步 `04-backend` 走到 `force-rebuild-validate.sh` 时 exit 1(check (a) char_ratio = 32% < 60%)。

**Then**:

- 第一步 `01-app-client` 已成功提交 + CHANGELOG 追加,**不**回退
- 第二步 `04-backend` 触发 atomic rollback:`.broken-<ts>` 反向 mv 回 `04-backend`
- 第二步 `failure.log` 写入 `failure_reason: VALIDATE_SCRIPT_FAILED, failed_check: char_ratio_below_threshold`
- 根 `CHANGELOG.md` 仅含第一步的 force-rebuild 条目;**不**含第二步
- `.local-backups/04-backend/<UTC-ts-2>/manifest.rollback` 段填充

**铁律**: domain 是隔离边界,不会因为一个 domain 失败回滚另一个 domain 已完成的变更。每个 domain 独立 lock + 独立 backup_dir + 独立 CHANGELOG 条目。

---

## 回归断言(全 case 共通)

每个 case 完成后 grep / jq 校验:

```bash
# 1. failure.log magic header(失败 case)
head -1 .local-backups/<domain>/<ts>/failure.log
# 期望: force-rebuild-failure.v1

# 2. status 字段 line-level grep(blocked/conflict 触发回滚)
grep -cE '^[[:space:]]*status:[[:space:]]*(blocked|conflict)' engineering-standards/<domain>/temp/<run_id>-review-summary.md

# 3. activation-report ajv valid
ajv -s skills/project-standard-extractor/references/config/dimension-framework/activation-report-schema.json \
    -d engineering-standards/<domain>/evidence/dimension-activation-report.json

# 4. 根 CHANGELOG run_id 匹配
grep -c "<run_id>" CHANGELOG.md
# 成功 path 期望 == 1; 失败 path 期望 == 0

# 5. lock 清理
test ! -d .local-backups/<domain>/.lock && echo "lock-released" || echo "LOCK-LEAK"

# 6. broken-ts 清理(成功 path)
ls engineering-standards/<domain>.broken-* 2>&1 | grep -q "No such" && echo "broken-cleaned"
```

任一断言失败 = case 不通过。
