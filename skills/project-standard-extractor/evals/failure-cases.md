# Failure Cases

> Authority: package-local smoke subset only. Full source-of-truth: `docs/evals/project-standard-extractor/failure-cases.md`.

这些用例必须映射到 `SKILL.md` 的失败模式，并停止在安全状态。

## FC-001 No Valid Project Paths

```yaml
request: 萃取团队规范
project_paths: []
```

期望：

- 触发 `NO_VALID_PROJECT_PATHS`。
- 停止执行，要求提供至少一个本地可读路径。

## FC-002 Missing Batch Selection

```yaml
request: 进入正式 batch 萃取
project_paths:
  - /repo/order-service
extraction_mode: batch-extraction
selected_batch: null
```

期望：

- 触发 `BATCH_NOT_SELECTED`。
- 不生成规则文件。

## FC-003 Invalid Selected Batch Context

```yaml
request: 萃取指定 batch
project_paths:
  - /repo/order-service
extraction_mode: batch-extraction
selected_batch:
  batch_id: backend-java-api-order
  candidate_files: []
```

期望：

- 触发 `NO_REPRESENTATIVE_EVIDENCE` 或 `SELECTED_BATCH_CONTEXT_INVALID`。
- 只输出 pending / review summary，不生成 AI 可执行规则。

## FC-004 Target Conflict

```yaml
existing_rule:
  section_title: P1 Controller 只负责请求接入和响应返回
  status: owner-confirmed-active
candidate_rule:
  section_title: P1 Controller 必须自行处理事务边界
```

期望：

- 触发 `TARGET_CONFLICT`。
- 写入 `conflicts.md`，不得覆盖或降级已有 owner-confirmed-active 规则。

## FC-005 Anti-pattern Auto-active Block

```yaml
candidate_rule:
  status: auto-active
  deterministic_occurrence_count: 5
  anti_pattern_blocklist_hit: backend-raw-sql-concat
```

期望：

- 触发 `AUTO_ACTIVE_ANTI_PATTERN_BLOCKED`。
- 降为 `pending-confirmation`，不进入 AI 默认执行路径。
