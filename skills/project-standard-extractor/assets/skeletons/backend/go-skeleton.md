---
doc_id: "backend-go-standard"
title: "Go 后端开发规范"
domain: "backend"
sub_domain: "go"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["backend", "go"]
---

# Go 后端开发规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`go`(Gin / Echo / Kratos / 标准库 net/http)
- 端类型:`backend`
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:HTTP / gRPC 服务、并发协程任务、轻量中间件。
**不应承载**:前端、客户端业务。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
cmd/
internal/
├── handler/
├── service/
├── repository/
├── model/
└── references/config/
pkg/
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| handler | HTTP / gRPC 协议层 | 业务规则 |
| service | 业务编排、事务 | 直接 SQL |
| repository | DB 操作 | 业务规则 |
| model | 结构体 / DTO | 持有连接池 |

## 5. 命名规范 [{{activation_state_section_5}}]

- 包名小写、单数;接口以行为命名(`Reader` / `OrderFinder`)
- 错误变量 `Err*` 前缀:`ErrOrderNotFound`
- 内部包放 `internal/`,对外暴露才放 `pkg/`

## 6. 核心规则 [{{activation_state_section_6}}]

### P1 错误必须包裹 context [{{activation_state}}]

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

**强制规则**:`fmt.Errorf("xxx: %w", err)` 包裹底层错误;调用方使用 `errors.Is` / `errors.As` 判定。

### FORBIDDEN 忽略 error 返回值

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

> ⛔ **FORBIDDEN**:`_, _ = doSomething()` 忽略错误。必须显式处理或包装并返回。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
Request → Handler → Service → Repository → DB
```

## 8. 平台差异 [{{activation_state_section_8}}]

- 框架(Gin/Echo/Kratos)选型由项目固化,新模块沿用既有框架

## 9. 错误模型 [{{activation_state_section_9}}]

- 业务错误用 sentinel error + `errors.Is`,或带状态码的 `BizError` 结构体
- HTTP 层统一中间件转换:`{code, message, trace_id}`

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成函数必须返回 error 显式处理
- context.Context 必须作为第一个参数
- 并发使用 errgroup / sync.WaitGroup,**不得** 裸 `go func()` 不带错误聚合

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] 所有 error 显式处理
- [ ] context 贯穿调用栈
- [ ] 没有 panic-as-control-flow

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-BE-{{N}}` | `internal/**/*.go` | {{core_observation}} | {{confidence}} |
