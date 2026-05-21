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

- 单项目事实可进入 `draft` 或 `pending-confirmation`，但不得自动升级为 P0 / FORBIDDEN。
- 必须标注推导边界和负责人确认项。
