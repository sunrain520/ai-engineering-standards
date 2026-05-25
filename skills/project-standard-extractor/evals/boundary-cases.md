# Boundary Cases

> Authority: package-local smoke subset only. Full source-of-truth: `docs/evals/project-standard-extractor/boundary-cases.md`.

这些用例不应触发本 skill，或必须停在公开稳定路径边界内。

## BC-001 Single File Explanation

```yaml
request: 帮我解释这个 Controller 做了什么
project_paths:
  - /repo/order-service/src/main/java/OrderController.java
```

期望：

- 不作为团队规范萃取任务处理。
- 可建议用户改用普通代码解释；若用户坚持萃取，要求补充模块或仓库级 evidence 范围。

## BC-002 Generic Best Practices

```yaml
request: 不看代码，直接生成后端开发规范
project_paths: []
```

期望：

- 不生成 AI 可执行规则。
- 只能说明需要真实代码路径或负责人确认。

## BC-003 Maintainer Force Rebuild

```yaml
request: 对 04-backend 执行 force-rebuild 并恢复旧备份
output_action: force-rebuild
domain: 04-backend
```

期望：

- 不走公开 skill 入口。
- 指向 maintainer 工具边界；普通规范萃取不得调用 backup / restore 脚本。

## BC-004 Multiple Selected Batches

```yaml
request: 把这三个 batch 一次性合并萃取
selected_batch:
  - backend-java-api-order
  - backend-java-db-order
```

期望：

- 停止生成。
- 要求一次选择一个 ready batch。
- 跨 batch 共性只能由独立 common batch 或后续人工合并处理。
