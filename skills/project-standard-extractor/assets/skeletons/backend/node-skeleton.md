---
doc_id: "backend-node-standard"
title: "Node.js 后端开发规范"
domain: "backend"
sub_domain: "node"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["backend", "node", "nestjs", "express"]
---

# Node.js 后端开发规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`node`(NestJS / Express / Fastify / Koa)
- 端类型:`backend`
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:Web / GraphQL API、BFF、轻量微服务、SSR Backend(配合 Next/Nuxt)。
**不应承载**:前端渲染层、客户端业务。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
src/
├── modules/                     — NestJS feature module
├── controllers/
├── services/
├── repositories/
├── dtos/
└── main.ts
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| Controller | HTTP / GraphQL 协议 | 业务规则 |
| Service | 业务编排、事务 | 直接 SQL |
| Repository | DB 操作(Prisma / TypeORM) | 业务规则 |
| DTO | class-validator 校验 | 持久化逻辑 |

## 5. 命名规范 [{{activation_state_section_5}}]

- 文件 kebab-case `*.controller.ts` / `*.service.ts`
- 类 PascalCase;DTO 后缀 `*Dto`
- 异常继承 `HttpException`(NestJS)或自定义 `BusinessError`

## 6. 核心规则 [{{activation_state_section_6}}]

### P1 全部启用 strict TypeScript [{{activation_state}}]

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**强制规则**:`tsconfig.json` `strict: true`;public 函数显式声明返回类型。

### FORBIDDEN 直接 `process.env` 散落 [{{activation_state}}]

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ **FORBIDDEN**:业务代码直接读 `process.env.X`,必须经 `ConfigModule` / `zod` 校验后注入。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
Request → Controller → Service → Repository → DB / MQ
```

## 8. 平台差异 [{{activation_state_section_8}}]

- NestJS / Express / Fastify 选型由项目固化;新服务推荐 NestJS + Fastify adapter

## 9. 错误模型 [{{activation_state_section_9}}]

- 全局 ExceptionFilter:`BusinessError` → 业务码 + 200,`HttpException` → 标准状态码,未知 → 5xx + traceId

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成 Controller 必须使用 DTO + class-validator
- 异步函数标记 `async` / 返回 `Promise`,显式类型
- 不得在 Controller 中实例化 Repository

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] strict TypeScript 编译通过
- [ ] 没有裸 `process.env` 使用
- [ ] DTO 校验完整

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-BE-{{N}}` | `src/**/*.ts` | {{core_observation}} | {{confidence}} |
