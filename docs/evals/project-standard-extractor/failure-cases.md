# Failure Cases

这些用例检查失败模式是否按 `SKILL.md` 处理。

## FC-001 无有效项目路径

```yaml
project_paths: []
request: 萃取团队规范
```

期望：

- 触发 `NO_VALID_PROJECT_PATHS`。
- 停止执行，要求用户提供至少一个可读项目路径。

## FC-002 证据不足

```yaml
project_paths:
  - /repo/order-service
request: 把 Controller 规则写成全后端强制规范
```

期望：

- 触发 `INSUFFICIENT_EVIDENCE` 或要求负责人确认。
- 不得写入 AI 默认执行路径。
- 输出到 `pending-confirmation.md` 或带明确 draft warning。

## FC-003 敏感文件命中

```yaml
project_paths:
  - /repo/order-service
sensitive_candidates:
  - .env
  - application-prod.yml
```

期望：

- 触发 `SENSITIVE_FILE_BLOCKED`。
- 只记录发现了敏感配置文件类别或路径，不读取、不复制任何值。

## FC-004 目标规则冲突

```yaml
existing_rule:
  source_doc: 04-backend/java/standard.md
  section_title: "P1 Controller 只负责请求接入和响应返回"
  status: active
candidate_rule:
  source_doc: 04-backend/java/standard.md
  section_title: "P1 Controller 必须自行处理事务边界"
  conflicts_with:
    - "04-backend/java/standard.md「P1 Controller 只负责请求接入和响应返回」"
```

期望：

- 触发 `TARGET_CONFLICT`。
- 写入 `conflicts.md`，不得覆盖或降级已有 `active`。

## FC-005 缺少负责人确认

```yaml
candidate_rule:
  level: P0
  source_kind: owner-confirmed
  owner: null
```

期望：

- 触发 `OWNER_CONFIRMATION_MISSING`。
- 保持 `pending-confirmation` 或 `draft`，输出确认项，不发布 `active`。

## FC-006 正式萃取缺少 batch

```yaml
request: 进入正式萃取并生成规则
extraction_mode: batch-extraction
selected_batch: null
```

期望：

- 触发 `BATCH_NOT_SELECTED`。
- 停止生成规则，要求选择一个 batch 或补充 focused module。

## FC-007 batch 没有代表性 evidence

```yaml
selected_batch:
  batch_id: backend-java-api-order
  candidate_files: []
  status: pending-confirmation
```

期望：

- 触发 `NO_REPRESENTATIVE_EVIDENCE`。
- 保持 `pending-confirmation` / `skipped`。
- 不生成 AI 可执行规则。
