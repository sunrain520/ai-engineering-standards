# Boundary Cases

这些输入不应直接生成团队级规范，或必须降级到待确认 / 冲突处理。

## BC-001 只解释单个文件

```yaml
request: 帮我解释这个 Controller 做了什么
project_paths:
  - /repo/order-service/src/main/java/OrderController.java
```

期望：

- 不触发完整规范萃取。
- 回复应建议使用普通代码解释；如用户坚持萃取，要求补充范围和证据边界。

## BC-002 只有行业通用最佳实践

```yaml
request: 生成银行业后端开发规范，不需要看代码
project_paths: []
industry_domain: banking
```

期望：

- 不生成 AI 可执行规则。
- 如需输出，只能作为模板建议或 `pending-confirmation`，不能进入 `draft`。

## BC-003 修改业务代码

```yaml
request: 按规范直接修改这些服务代码
project_paths:
  - /repo/order-service
```

期望：

- 拒绝把本 Skill 用作业务代码修改工具。
- 可提示先运行规范萃取，再由普通开发 workflow 执行业务代码修改。

## BC-004 单项目事实被过度推广

```yaml
request: 从一个服务提炼整个后端团队 P0 规范
project_paths:
  - /repo/order-service
dev_domain: Backend
```

期望：

- 单项目事实默认进入 `draft` 或 `pending-confirmation`。
- 只有满足 BR-016/BR-017（确定性 occurrence≥2、confidence high、多文件/多角色覆盖、结构完整、未命中黑名单、非高风险域）时才能标 `auto-active`。
- 所有 auto-active 必须标注 `authority_scope: this-repo` 和 owner 事后裁定队列。

## BC-005 完整仓库请求直接出规则

```yaml
request: 读取这个完整仓库，直接生成所有后端规范
project_paths:
  - /repo/backend-monorepo
dev_domain: unknown
```

期望：

- 强制进入 `profile-first`。
- `profile-first` 输出 `project-profile`、`extraction-map`、`batch-plan`、`ordered_batch_queue`、`coverage_report` 和代表性文件候选。
- full-auto 外层按 queue 逐 batch 执行；不得把完整仓库一次性交给 generation。
- 不发布正式 rules-index；只输出 candidate index 和 artifact validator 结果。

## BC-006 同时选择多个 batch

```yaml
request: 把这三个 batch 一次性都萃取完
selected_batch:
  - backend-java-api-order
  - backend-java-database-order
```

期望：

- 即便 auto 模式遍历多个 ready batch，每个 batch 仍是独立读取边界，不跨 batch 合并 candidate_files。
- interactive 模式要求用户一次只选择一个 batch；auto 模式按 `ordered_batch_queue` 顺序逐个执行，每完成一个 batch 才进入下一个。
- 跨 batch 共性事实必须由独立的 `sub_domain: common` batch 承载，不能由"多 batch 一次跑"绕过此约束。
