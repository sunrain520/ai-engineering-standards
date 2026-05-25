# Force Rebuild Orchestrator Prompt

> 本 prompt 在 `output_action = force-rebuild` 时由 `references/agents/intake-and-scope.md` 加载。整体流程 = backup-manager safeguard 阶段 + phase 2 default `full` 管道 + 重生校验 + success/failure 收尾。

## 适用场景

- `output_action = force-rebuild`
- 必须有 `--domain=<>` 显式参数(强制边界 #9)
- 必须 `run_mode = interactive`(强制边界 #10);auto / headless / pipeline 直接拒绝
- `extraction_mode` ≠ `diff`(R91 互斥);`project_paths` 长度 ≤ 1(R92 互斥)

## 主流程

```
intake-and-scope            (识别 output_action=force-rebuild + 互斥校验)
        ↓
backup-manager Step 1–8     (safeguard 三步 → cp -a → atomic rename → --keep=N)
        ↓
[ 等待 backup-manager 返回 success=true 才进入下一步;awaiting_user_confirmation 时挂起等用户输入 ]
        ↓
intake-and-scope            (转入 phase 2 default `full` 管道)
        ↓
profile-and-batch-planner → dimension-activator → facts-and-classification → generation
        → review-and-quality-gate → merge-coordinator
        ↓
scripts/force-rebuild-validate.sh  (U24,4 项确定性校验)
        ↓
        ┌─────── valid=true ───────┐         ┌─────── valid=false ───────┐
        ↓                            ↓        ↓                            ↓
backup-manager Step 10a            backup-manager Step 10b
(success path)                     (failure path: atomic rollback)
        ↓                                    ↓
changelog-append helper            写 failure.log + manifest.rollback
        ↓                                    ↓
释放 lock + 删 .broken-<ts>        释放 lock(保留 .broken-<ts> 已被 mv 回原位置)
        ↓                                    ↓
返回 success=true                  返回 success=false + failure_reason
```

## 调用契约

backup-manager 输入(由 intake-and-scope 注入):

```yaml
run_id: "<UTC-ts>-<domain-tag>"
output_action: force-rebuild
domain: "01-app-client"          # 必填
mode_args:
  extraction_mode: full          # force-rebuild 必走 full,避免漏维度
  keep: 10                       # 默认值,可由用户 --keep= 覆盖
operator: "<host developer>"
run_mode: interactive
```

backup-manager 输出消费方:

- `success=true && awaiting_user_confirmation=true` → orchestrator 挂起,等用户消息;**只接受字面 `confirm <domain>`**(对抗 prompt injection)
- `success=true && action_taken=backup-and-rename` → 进入 phase 2 `full` 管道
- `success=false` → 输出 `failure_reason` + `recommended_action`(见 `references/agents/backup-manager.md §canonical recommended_action`)给用户,**不**触发 phase 2 管道

## safeguard 用户交互模板

dry-run 预览输出格式(orchestrator 渲染给用户):

```
== Force Rebuild Dry Run ==
domain: <domain>
backup target: skills/project-standard-extractor/.local-backups/<domain>/<UTC-ts>/
sha256 fingerprint: <64 hex>
files: <N>  bytes: <M>
exclude: evidence/raw-*, temp/, .git
operator: <name>
git head: <sha> @ <branch> (clean)
dimension activation summary:
  baseline=<N1> activated=<N2> candidate=<N3> pending=<N4> shallow=<N5>
gitignore status: <ok | "建议把 skills/project-standard-extractor/.local-backups/ 加入 .gitignore">

输入 `confirm <domain>` 确认重生(其他输入将取消并释放 lock)
```

## 失败回滚监听

任意阶段返回的失败信号都视为重生失败,触发 backup-manager Step 10b:

- `merge-coordinator.final_status: failed` 或 `partial`(force-rebuild 严格模式不接受 partial)
- `review-and-quality-gate` 输出 `quality_gate_decisions[].status: blocked` 或 `conflict`(任一命中即失败,U24 用 grep 校验)
- `force-rebuild-validate.sh` 输出 `valid: false`(exit 1)或 runtime error(exit 2)
- `references/prompts/orchestrator/force-rebuild/changelog-append.md` 追加失败(磁盘满 / 权限 / git 锁)→ step 10a 末段**特例回滚**(用 backup_dir 重建,不反向 mv,见 backup-manager.md step 10a)

## §rollback — atomic rollback 决策矩阵

| 触发点 | broken-ts 状态 | 回滚动作 |
| --- | --- | --- |
| validate.sh exit 1 | `<domain>.broken-<ts>` 存在 | 反向 mv `<domain>.broken-<ts>` → `<domain>`(先 rm -rf 破损 `<domain>`)|
| validate.sh exit 2 | `<domain>.broken-<ts>` 存在 | 同上 + 写 failure.log 标 `VALIDATE_SCRIPT_RUNTIME_ERROR` |
| merge-coordinator.failed | `<domain>.broken-<ts>` 存在 | 跳过 validate.sh,直接反向 mv |
| quality-gate blocked | `<domain>.broken-<ts>` 存在 | 跳过 validate.sh,直接反向 mv |
| changelog-append failed | `<domain>.broken-<ts>` 仍保留 | 反向 mv `<domain>.broken-<ts>` → `<domain>`；不从 backup payload 复制 |

回滚铁律:

1. 任意失败路径**必须**释放 domain lock(`rmdir .lock`)
2. CHANGELOG **不**追加(失败不留痕)
3. manifest.rollback 段必须补全(`rolled_back_at / failure_reason / failure_log_path / validation_failure`)
4. failure.log 用 magic header `force-rebuild-failure.v1`
5. `.broken-<ts>` 删除时机仅一个:step 10a 末段 changelog-append 成功之后；changelog 失败必须保留它用于反向 rename

## §changelog — success path CHANGELOG 追加

backup-manager step 10a 通过 helper 追加根 `CHANGELOG.md`:

入参契约(由本 orchestrator 在 step 10 dispatcher 通过 → success path 时填):

```yaml
event_type: force-rebuild
domain: "01-app-client"
backup_path: ".local-backups/01-app-client/<UTC-ts>/"
dimension_activation_report_summary:        # 从 dimension-activator 输出读
  baseline: <N1>
  activated: <N2>
  candidate: <N3>
  pending: <N4>
  shallow: <N5>
run_id: "<run_id>"
operator: "<host developer>"                # 来自 .claude/spec-first/.developer
user_visible: true
version: "0.1.0"                            # 从 CHANGELOG.md 头部继承
```

helper 返回 `success: false` 时,本 orchestrator 触发 step 10a 末段**特例回滚**(详见 §rollback)。

## 互斥保护

| 调用层级 | 校验项 | 失败处置 |
| --- | --- | --- |
| SKILL 调用协议 | `output_action ≠ append` && `extraction_mode = diff` | schema 层拒绝 |
| SKILL 调用协议 | `output_action ≠ append` && `len(project_paths) > 1` | schema 层拒绝 |
| intake-and-scope | 重复上述两项校验(R91 / R92 双层防御) | 抛 `INCOMPATIBLE_OUTPUT_ACTION` |
| backup-manager | `run_mode != interactive` | 立即拒绝 `NON_INTERACTIVE_CONTEXT_REJECTED` |

## 关键引用

- `references/agents/backup-manager.md` — 决策算法 12 步 + safeguard / failure mode 全表
- `references/prompts/orchestrator/force-rebuild/backup-manager.md` — backup-manager 内部短 prompt(简化 host LLM 调用)
- `references/prompts/orchestrator/force-rebuild/changelog-append.md` — U24 CHANGELOG 追加 helper(本 prompt 在 success path 末段调用)
- `scripts/backup.sh` / `scripts/backup.sh` — 跨平台 cp/rsync/sha256 实现
- `scripts/force-rebuild-validate.sh` — U24 4 项确定性校验
- `references/config/backup/manifest-schema.json` — manifest.json ajv schema
- `assets/backup-manifest-template.json` — manifest.json 写入骨架
