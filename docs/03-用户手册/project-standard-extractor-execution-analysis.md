# project-standard-extractor 执行逻辑分析

## 1. 结论

当前公开稳定路径是 Phase 1 full-auto：用户提供真实 `project_paths` 后，Skill 内部完成 profile-first、`ordered_batch_queue`、逐 batch worker、quality gate、append-only merge、lineage、owner queue、artifact contract validation 和 review summary。

人工选择 `selected_batch` 仍保留，但它是诊断/重跑单 batch 的路径，不是 broad input 默认停点。

## 2. 公开入口

```yaml
project_paths:
  - /path/to/project
output_dir: ""
extraction_mode: ""      # full-auto | profile-first | batch-extraction | focused-module
selected_batch:
  batch_id: ""           # batch-extraction/diagnostic 使用；full-auto 为空
run_mode: auto
```

公开入口不得传 `output_action`、`restore_from`、`keep`、`full` 或 maintainer-only `domain`。

## 3. Phase 1 Full-auto 流程

```text
project_paths
  -> intake-and-scope
  -> profile-and-batch-planner
       -> project-profile
       -> extraction-map
       -> batch-plan
       -> ordered_batch_queue
       -> coverage_report
  -> for each queue item:
       ready -> normal-confidence selected-batch worker
       pending-confirmation -> low-confidence selected-batch worker
       skipped/blocked -> coverage only
  -> facts-and-classification
  -> generation(phase1-selected-batch)
  -> review-and-quality-gate(phase1-full-auto)
  -> merge-coordinator(target_state routing)
  -> artifact validators + review summary
```

每次 worker 调用仍只消费一个 batch 的 candidate files。full-auto 是外层 orchestrator 串行循环，不是把整个仓库一次性交给 generation。

## 4. Phase 1 与 Phase 2 分流

| 条件 | 路径 | activation-report |
| --- | --- | --- |
| 缺失 `activation_report` 且有 batch id | Phase 1 full-auto | 不要求、不生成、不持久化 |
| 存在合法 `activation_report.v1` | Phase 2 repair-only | 由 dimension-activator 提供 |
| 缺失 report 且无 batch id | 无效输入 | 停止 |

Phase 1 review 只跑 Content Gate、structure/runtime policy 和 auto-active 闸；Gate B activation gate 只属于 Phase 2。Phase 1 merge 直接按 `target_state` 路由，不能按空 `dimension_state` 分桶。

## 5. Queue 与 Coverage

`ordered_batch_queue` 包含：

- `ready`: normal confidence worker，可生成 draft 或 auto-active。
- `pending-confirmation`: low confidence worker，只能生成 pending/low-confidence draft。

`skipped` / `blocked` 不进入 worker，只进入 `coverage_report`。coverage 必须区分 profile 矩阵内覆盖与 blind spots，不能宣称全仓 100% 无盲区。

## 6. Quality Gate

Phase 1 auto-active 闸要求：

- `deterministic_occurrence_count >= 2`。
- `confidence: high`。
- 多文件/多角色覆盖。
- evidence 充分、结构完整、无未裁定 conflict。
- 未命中 `anti-pattern-blocklist.yaml`。
- 非 security/auth/cryptography/permission/compliance 等高风险域。

未过闸的规则降为 `draft` 或 `pending-confirmation`。高风险域和黑名单命中项即使高频也不得 auto-active。

## 7. Merge 与状态

Phase 1 merge 的主字段是 `target_state`：

| target_state | 写入 |
| --- | --- |
| `auto-active` | standard + ai-rules 默认执行段 + review checklist + lineage + owner queue |
| `draft` | standard + evidence，作为参考上下文 |
| `pending-confirmation` | pending + owner queue |
| `conflict` | conflicts + owner queue |
| `legacy-compatible` | evidence/legacy-compatible |
| `stale-auto-active` | 移出默认执行路径 + owner queue |
| `owner-rejected` | 终态记录 + 移出默认执行路径 |
| `rejected` | 只记录 review 结果 |

`owner-confirmed-active` 只能由 owner 手动确认。full-auto 不自动改写已有 owner-confirmed/legacy active 规则。

## 8. 增量运行

重复运行同一仓库时，merge 先用 `existing_index` 对齐 `(source_doc, section_title)` 和 normalized title fingerprint：

- 新规则：`added`。
- evidence 改变：`evidence-changed`。
- pending 被 standard 承接：旧 pending 标 `superseded_by`。
- 已有 active/draft 与新 evidence 不一致：写 conflicts / merge suggestions / owner queue，标 `stale-active-needs-owner-review`。
- auto-active 不再满足闸：标 `stale-auto-active` 并移出默认执行路径。

## 9. 产物契约

机器契约在 `skills/project-standard-extractor/references/config/output-artifact-contract.json`。结构 validator 在：

```bash
tools/maintainer/project-standard-extractor/artifact-contract-validate.sh
```

它校验 doc_type/status 枚举、rule locator、candidate/formal 边界、lineage 最小字段和 Phase1 activation-report 泄漏。

## 10. Repair-only 边界

以下能力不是普通 full-auto 路径：

- `dimension-activator` 和 activation-report Gate B。
- cross-project aggregator。
- EA-Doc / securities PoC。
- force-rebuild / restore / pin / unpin / list。
- backup-manager。

如果普通请求触发这些字段，应返回 `MAINTAINER_CONTEXT_REQUIRED` 或 repair-only 提示。
