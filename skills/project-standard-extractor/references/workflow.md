# Workflow

## Phase 2 Status: BLOCKED

Phase 2 Dimension Framework 当前为 `blocked / repair-in-progress`。本文件描述目标数据流和修复中的机器契约；在 N-01/N-02/N-03、force-rebuild safety 和最终 eval 全部通过前，不得把 Phase 2 default append/full、cross-project、EA-Doc、证券 PoC 或 force-rebuild 系列作为可用 runtime 发布。

稳定路径仍是 Phase 1：`profile-first` 生成 project profile / extraction map / batch plan，用户确认 batch 后再执行受控 `batch-extraction`。

## Stable Public Workflow

公开 skill 入口只执行以下稳定路径：

```
intake-and-scope
  -> profile-and-batch-planner
  -> stop-for-batch-selection
  -> facts-and-classification(selected batch only)
  -> generation(generation_profile: phase1-selected-batch)
  -> review-and-quality-gate
  -> merge-coordinator(draft-only append)
```

稳定路径不读取 `dimension-activator`，不要求 `activation-report`，不启动 `extraction_mode=full`，也不接收 `output_action`。Generation 在该路径只消费单个 batch 的 `code_facts` / `classification` / `selected_batch_summary`，所有可执行规则必须追溯到本 batch evidence。

## Maintainer / Repair-Only

`force-rebuild` / `restore` / `pin` / `unpin` / `list` 是仓库维护者能力，不属于公开 skill 触发面。对应脚本位于仓库根：

```text
tools/maintainer/project-standard-extractor/backup.sh
tools/maintainer/project-standard-extractor/force-rebuild-validate.sh
```

维护者入口说明见 `tools/maintainer/project-standard-extractor/README.md`。这些工具只应在 Phase 2 repair / force-rebuild 验证任务中手动调用；普通规范萃取不得调用。

## 1. 执行模式

| run_mode | 说明 | 适用场景 |
| --- | --- | --- |
| `auto` | 自动调度阶段；Phase 2 blocked 期间只用于 fixture / repair validation | 修复验证 |
| `interactive` | 关键决策点暂停等待用户确认 | 高风险或 force-rebuild 设计验证 |

## 2. Phase 2 目标数据流

```
project_paths / doc_paths
    │
    ▼
[Agent 1] intake-and-scope
    输出: scope_summary, run_id
    │
    ▼
[Agent 2] profile-and-batch-planner
    输出: project-profile, extraction-map, batch-plan, ordered_batch_queue
    │
    ▼
[Agent 3] doc-source-scanner（可选但必须在 activator 前）
    输入: project_paths + doc_paths
    输出: evidence/knowledge/doc-inventory.json (schema=doc-inventory.v1)
    │
    ▼
[Agent 4] facts-and-classification
    输入: batch-plan + candidate files + doc-inventory
    输出: signal_scan.v1
      ├─ signal_hits[]     # grep/ast/file_existence/dependency/gitnexus/doc-content
      ├─ doc_facts[]       # sanitized doc evidence
      └─ fact_candidates[] # 描述性事实候选，不含 dimension_state
    │
    ▼
[Agent 5] dimension-activator（唯一激活态权威源）
    输入: dimension pools + activation rules + signal_scan
    输出: temp/{run_id}-activation-report.json (schema=activation-report.v1)
      ├─ dimensions[]      # 唯一主数组
      ├─ summary{*_count}
      ├─ gitnexus_readiness
      └─ limitations
    │
    ▼
[Agent 6] generation
    输入: activation-report + fact_candidates + skeletons + baseline default_content
    输出: draft standards / evidence / ai-rules / review-checklist / pending-confirmation
    │
    ▼
[Agent 7] review-and-quality-gate
    输入: generated docs + activation-report
    输出: quality_gate_decisions[] + machine summary
    │
    ▼
[Agent 8] merge-coordinator
    输入: quality gate + activation-report
    输出: append-only merge, persisted evidence/dimension-activation-report.json, review-summary
```

**单一数据流规则：**

- `facts-and-classification` 只产生 signal/fact evidence，不消费 activation-report，不决定 state。
- `dimension-activator` 只消费 signal evidence 并计算 state；下游不得本地重算 state。
- `generation` 必须先校验 `activation-report-schema.json`，`dimensions[]` 为空时硬失败。
- baseline-only 输入必须通过 `baseline-dimensions.yaml.default_content` 或 pending route 生成最小输出，不得崩溃。
- EA-Doc 必须在 activator 前产生 sanitized doc facts，并写入 activation-report `dimensions[]`。
- cross-project aggregator 只消费 `schema == "activation-report.v1"` 的 per-project reports。

## 3. 状态机

| state | 生成路径 | AI 默认执行路径 |
| --- | --- | --- |
| `baseline` | `default_content` 最小章节或 pending 记录 | 不进入强制规则 |
| `activated` | standard / evidence / ai-rules / review-checklist | 可进入，待 owner 确认 |
| `pending-confirmation` | pending-confirmation.md 独占 | 不进入 |
| `shallow` | standard + low-coverage 标记，review 强制 `keep-draft-low-coverage` | 限制进入 |
| `candidate` | overview §9 未激活地图 | 不进入 |

## 4. Activation Report Contract

- 文件：`references/config/dimension-framework/activation-report-schema.json`
- 主字段：`schema: "activation-report.v1"`
- 主数组：`dimensions[]`
- 禁止：旧数组别名、`schema_version`、空 `dimensions[]` 继续进入 generation
- 持久化：merge-coordinator 必须写入 `engineering-standards/<domain>/evidence/dimension-activation-report.json`，失败时 run 标记 failed/incomplete

## 5. GitNexus Readiness

GitNexus 是 advisory evidence。readiness 可用必须同时满足：

- `.spec-first/graph/graph-facts.json` 可读
- `capabilities.query_global_graph == true`
- provider summary 中 ready primary providers 包含 `gitnexus`
- freshness window 内的 mtime
- 如存在 `worktree_status_hash`，必须与当前 worktree 匹配

不满足时降级 fallback，不阻塞流程；fallback evidence 的 `source` 必须写真实来源，不能写 `gitnexus`。

## 6. Force Rebuild Boundary

`force-rebuild` / `restore` / `pin` / `unpin` / `list` 当前是 blocked/design-only。发布前必须通过 lock、path traversal、manifest schema、atomic rollback、CHANGELOG helper 和 temp fixture 验证。真实破坏性 IO 不得在 repair validation 之前执行。

## 7. Final Review Summary

最终 `review-summary.md` 必须包含：

- activation summary（baseline / activated / pending / shallow / candidate）
- blocked capabilities
- validation command / fixture evidence
- pending-confirmation 列表
- conflicts 列表
- NOT_RUN / BLOCKED / NOT_MEASURED 场景，不得写结构性全通过结论

## 8. 激活态铁律

- candidate 不得进入 standard / ai-rules / review-checklist；出现即抛 `CANDIDATE_LEAKED_TO_STANDARD`。
- pending-confirmation 不得变成强制规则；出现即抛 `PENDING_FORCED_TO_ACTIVE`。
- shallow 必须在 standard / ai-rules 双侧都标 low-coverage；缺失即抛 `SHALLOW_MISSING_LOW_COVERAGE`。
- overview §9 永不删除历史条目；本 run 转 activated 的维度仅追加 `-> activated since {run_id}` 标注。
- 即使 candidate=0，overview §9 章节标题仍保留（`preserved_when_empty=true`）。
