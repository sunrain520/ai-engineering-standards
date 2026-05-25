# Trigger Cases

这些用例应触发 `project-standard-extractor` 的公开稳定路径。

## TC-001 Broad Repository Profile

```yaml
request: 从这个 Java 服务仓库萃取团队后端开发规范
project_paths:
  - /repo/order-service
```

期望：

- 触发本 skill。
- 进入 `profile-first`，只输出 `project-profile.md`、`extraction-map.md`、`batch-plan.md`。
- 未选择 batch 前不得生成 `standard-{sub_domain}.md`、`ai-rules.md` 或 `review-checklist.md`。

## TC-002 Selected Batch Generation

```yaml
request: 基于已生成的 batch plan 继续萃取订单 API 规范
project_paths:
  - /repo/order-service
extraction_mode: batch-extraction
selected_batch:
  batch_id: backend-java-api-order
```

期望：

- 触发本 skill。
- 只读取 `backend-java-api-order` 的 candidate files 与必要邻近 evidence。
- 使用 `generation_profile: phase1-selected-batch`。
- 输出 evidence-backed draft `standard-{sub_domain}.md`、`ai-rules.md`、`review-checklist.md` 和 review summary。

## TC-003 Focused Module Extraction

```yaml
request: 从支付回调模块提炼可复用的幂等和状态机规范
project_paths:
  - /repo/payment-service/src/main/java/com/acme/payment/callback
extraction_mode: focused-module
```

期望：

- 触发本 skill。
- 将模块路径作为 evidence 范围，而不是团队全域事实。
- 若证据足够，输出 draft 规则；若证据不足，输出 `pending-confirmation.md`。
