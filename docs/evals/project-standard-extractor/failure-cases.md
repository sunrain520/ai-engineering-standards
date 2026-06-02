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
  status: owner-confirmed-active
candidate_rule:
  source_doc: 04-backend/java/standard.md
  section_title: "P1 Controller 必须自行处理事务边界"
  conflicts_with:
    - "04-backend/java/standard.md「P1 Controller 只负责请求接入和响应返回」"
```

期望：

- 触发 `TARGET_CONFLICT`。
- 写入 `conflicts.md` 和 owner decision queue，不得覆盖或降级已有 `owner-confirmed-active`。

## FC-005 缺少负责人确认

```yaml
candidate_rule:
  level: P0
  source_kind: owner-confirmed
  owner: null
```

期望：

- 触发 `OWNER_CONFIRMATION_MISSING`。
- 保持 `pending-confirmation` 或 `draft`，输出确认项，不发布 `owner-confirmed-active`。

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

## FC-008 maintainer action 缺少 repair-only 上下文

```yaml
request: 重建 APP 客户端规范
project_paths:
  - /repo/mobile-app
output_action: force-rebuild
maintainer_context: false
domain: 01-app-client
run_mode: interactive
```

期望：

- 触发 `MAINTAINER_CONTEXT_REQUIRED`。
- 不进入 `backup-manager`。
- 不调用 `tools/maintainer/project-standard-extractor/backup.sh`。
- 提示改用 maintainer 工具或显式 repair-only workflow。

## FC-009 高频反范式不得 auto-active

```yaml
candidate_rule:
  level: P0
  status: auto-active
  deterministic_occurrence_count: 5
  pattern: raw SQL string concatenates request parameter
  anti_pattern_blocklist_hit: backend-raw-sql-concat
```

期望：

- 触发 `AUTO_ACTIVE_ANTI_PATTERN_BLOCKED`。
- 规则降级为 `pending-confirmation`，不得进入 `ai-rules.md §2`。
- owner queue 标记 `requires_security_review: true` 或同等 owner review 动作。

## FC-010 高风险域不得自动升级

```yaml
candidate_rule:
  level: P0
  sub_domain: auth-permission
  deterministic_occurrence_count: 4
  confidence: high
```

期望：

- 触发 `AUTO_ACTIVE_HIGH_RISK_DOMAIN`。
- 即使 evidence 充分，也只能进入 `pending-confirmation.md`。
- owner queue 标记需要 security / permission owner review。

## FC-011 Phase1 泄漏 activation-report

```yaml
run_profile: phase1-full-auto
temp_files:
  - temp/20260602-backend-activation-report.json
```

期望：

- 触发 `PHASE1_ACTIVATION_REPORT_LEAK`。
- generation / review / merge 不得把该 run 改判成 Phase 2。
- `artifact-contract-validate.sh` 或 public validator 必须 BLOCK。
