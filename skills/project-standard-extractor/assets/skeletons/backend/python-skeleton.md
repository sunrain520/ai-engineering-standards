---
doc_id: "backend-python-standard"
title: "Python 后端开发规范"
domain: "backend"
sub_domain: "python"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["backend", "python", "fastapi", "django"]
---

# Python 后端开发规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`python`(FastAPI / Django / Flask 后端服务)
- 端类型:`backend`
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:Web API、异步任务、ORM、数据科学服务接入。
**不应承载**:前端、客户端业务。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
app/
├── api/                         — 路由 / endpoint
├── services/
├── models/                      — pydantic / SQLAlchemy
├── repositories/
├── core/                        — settings / security
└── main.py
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| api | 路由、Pydantic 入参 | 业务规则 |
| service | 编排业务、事务 | 直接 SQL |
| repository | DB 操作 | 业务规则 |
| model | 数据结构 | 持有 ORM session |

## 5. 命名规范 [{{activation_state_section_5}}]

- 模块 / 文件 snake_case;类 PascalCase
- API 函数 `*_endpoint` 或与 path 一致
- 异常 `*Error`,业务异常继承自 `BusinessError`

## 6. 核心规则 [{{activation_state_section_6}}]

### P1 类型注解必填 [{{activation_state}}]

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**强制规则**:公开函数 / endpoint 必须类型注解,使用 `from __future__ import annotations`;mypy 严格模式无错误。

### FORBIDDEN 同步阻塞调用进入 async endpoint

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ **FORBIDDEN**:在 `async def` endpoint 中调用阻塞 IO(`requests.get` / 同步 ORM session),必须使用 async client / `run_in_executor`。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
Request → Endpoint(async) → Service → Repository(async ORM / executor) → DB
```

## 8. 平台差异 [{{activation_state_section_8}}]

- FastAPI vs Django:新服务默认 FastAPI;Django 仅维护既有 admin / ORM 重型场景

## 9. 错误模型 [{{activation_state_section_9}}]

- 自定义 `BusinessError` + 异常处理器输出 `{code, message, trace_id}`
- 422 由 FastAPI Pydantic 自动产出,不要二次包装

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成 endpoint 必须 async + 类型注解
- 数据模型用 Pydantic,DB 模型与 API 模型分离
- Settings 通过 `pydantic-settings`,**不得** `os.getenv` 散落使用

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] 公共函数有类型注解
- [ ] async endpoint 无阻塞调用
- [ ] settings 集中

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-BE-{{N}}` | `app/**` | {{core_observation}} | {{confidence}} |
