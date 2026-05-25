# Trigger Cases

这些输入应该触发 `project-standard-extractor`。

## TC-001 多项目后端规范萃取

```yaml
request: 从这些 Java 服务里萃取后端 Controller / Service / DTO 规范
project_paths:
  - /repo/order-service
  - /repo/account-service
dev_domain: Backend
output_scope: full package
```

期望：

- 进入 Intake and Scope。
- 推断或确认 Backend / Java / API 子领域。
- 因为是多服务输入，先进入 `profile-first`。
- 输出 `project-profile`、`extraction-map` 和 `batch-plan`。
- 选择单个 batch 后才输出 `code_facts` 并生成规范候选。

## TC-002 APP KMP 规范萃取

```yaml
request: 从 APP 代码里萃取 KMP、Android、iOS 的团队规范
project_paths:
  - /repo/mobile-app/shared
  - /repo/mobile-app/android
  - /repo/mobile-app/ios
dev_domain: APP
```

期望：

- 识别 KMP、Android、iOS、DataCenter 等子领域候选。
- 先生成 APP batch plan，不直接跨端生成规则。
- 双端共性必须先进入 facts，不直接写强制规则。
- 平台路径只能进入 evidence，不进入规则正文。

## TC-003 行业规范独立输出

```yaml
request: 从交易、订单、账户模块萃取证券行业规范
project_paths:
  - /repo/trade-service
  - /repo/order-service
industry_domain: securities
output_scope: full package
```

期望：

- 生成 `engineering-standards/09-industry/` 候选输出。
- 行业共性如果没有团队 evidence 或负责人确认，只能进入 `pending-confirmation.md`。

## TC-004 已选 batch 的后端 API 萃取

```yaml
request: 基于已生成的 batch plan 萃取订单 API 规范
project_paths:
  - /repo/order-service
extraction_mode: batch-extraction
selected_batch:
  batch_id: backend-java-api-order
  source_batch_plan: engineering-standards/04-backend/20260521-180000-backend-batch-plan.md
```

期望：

- 只读取 `backend-java-api-order` 的 candidate files。
- 使用 `generation_profile: phase1-selected-batch`。
- 不要求 `activation-report`，不读取 `dimension-activator`。
- 输出 code facts、classification、evidence-backed draft `standard-{sub_domain}.md`、`ai-rules.md`、`review-checklist.md` 和 review summary。
- 不读取其它 batch 的数据库、MQ 或 job 文件。
