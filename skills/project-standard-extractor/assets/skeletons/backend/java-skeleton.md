---
doc_id: "backend-java-standard"
title: "Java / Kotlin 后端开发规范"
domain: "backend"
sub_domain: "java"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["backend", "java", "spring"]
---

# Java / Kotlin 后端开发规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`java`(覆盖 Spring Boot / Spring Cloud + Kotlin JVM 后端)
- 端类型:`backend`
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:Web / RPC API、领域服务、ORM、消息消费 / 投递、缓存、事务边界。
**不应承载**:前端模板渲染、客户端业务逻辑、临时脚本。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
src/main/{java,kotlin}/com/{org}/{module}/
├── api/                         — Controller / GrpcEndpoint
├── application/                 — UseCase / Service
├── domain/                      — Entity / 值对象 / Domain Service
├── infrastructure/              — Repository 实现 / 外部 SDK
└── references/config/                      — Spring Configuration
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| api | HTTP / RPC 协议层、参数校验 | 包含业务规则 |
| application | 编排 UseCase、事务边界 | 直接访问数据库 |
| domain | 业务规则、领域模型 | 依赖 Spring / DB Driver |
| infrastructure | DB / MQ / 外部服务实现 | 暴露给 api 层 |

## 5. 命名规范 [{{activation_state_section_5}}]

- Controller 后缀 `*Controller`;Service 后缀 `*Service`;Repository 后缀 `*Repository`
- DTO 后缀 `*Request` / `*Response`;领域对象不带后缀
- 异常 `*Exception`,业务异常继承 `BusinessException`

## 6. 核心规则 [{{activation_state_section_6}}]

### P1 事务边界放在 application 层 [{{activation_state}}]

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

**强制规则**:`@Transactional` 标注在 `*Service` / UseCase 方法上,Controller 与 Repository 不写事务。

### FORBIDDEN Controller 直接调 Repository

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

> ⛔ **FORBIDDEN**:`@RestController` 中注入 `*Repository` 直接 CRUD,必须经 `*Service`。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
HTTP/gRPC → Controller → Service(Tx) → Domain → Repository → DB/MQ
```

## 8. 平台差异 [{{activation_state_section_8}}]

- Java vs Kotlin 在协程 / 空安全上的差异;新模块 Kotlin 优先,旧模块按现状

## 9. 错误模型 [{{activation_state_section_9}}]

- 全局 `@RestControllerAdvice` 捕获 `BusinessException` → 业务错误码;未知异常 → 5xx + traceId
- 错误响应字段:`code` / `message` / `traceId`

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成 Controller 必须使用 DTO,**不得** 直接返回 Entity
- AI 生成事务方法必须使用 `@Transactional` + 显式 `rollbackFor`
- AI 生成 Repository 不得在 Service 之外调用

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] Controller 仅做协议适配
- [ ] 事务标注位于 Service 层
- [ ] Entity 不在 api 层暴露

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-BE-{{N}}` | `src/main/{java,kotlin}/**` | {{core_observation}} | {{confidence}} |
