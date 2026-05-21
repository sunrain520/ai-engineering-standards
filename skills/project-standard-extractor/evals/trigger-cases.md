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
- 先输出 `code_facts`，再生成规范候选。

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
