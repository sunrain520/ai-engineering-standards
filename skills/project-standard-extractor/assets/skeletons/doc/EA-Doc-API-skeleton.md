---
doc_id: "{{domain}}-ea-doc-api"
dimension_id: EA-Doc-API
status: "{{status}}"
evidence_tier: "{{evidence_tier}}"
domain: "{{domain}}"
generated_by: phase-2-extractor
---

# §EA-Doc-API API 契约 [{{activation_state}}]

> ```yaml
> dimension_id: EA-Doc-API
> activation_state: {{activation_state}}
> layer: doc
> evidence_count: {{evidence_count}}
> depth_score: {{depth_score}}
> signal_hits: {{signal_hits}}
> ```

## API 契约来源

| 文件 | 格式 | 端点数 | 最后更新 |
| --- | --- | --- | --- |
| {{api_file_1}} | {{format_1}} | {{count_1}} | {{date_1}} |

详见 `evidence/knowledge/api-contract.md`。

## 关键端点摘要（从 `evidence/knowledge/api-contract.md` 提炼）

| 端点 | Method | 简述 | 请求 | 响应 |
| --- | --- | --- | --- | --- |
| {{endpoint_1}} | {{method_1}} | {{desc_1}} | {{req_1}} | {{resp_1}} |
| （更多端点见 `evidence/knowledge/api-contract.md`） | | | | |

## API 契约规则

- 所有公开 REST API 必须有 OpenAPI 3.x 定义（`openapi.yaml` / `openapi.json`）
- 响应格式统一：成功 `200` 含数据结构；失败 `4xx/5xx` 含 `code` + `message` 字段
- 版本变更遵循语义化版本，破坏性变更需单独 ADR 记录

## 升级条件（当前 state 为 {{activation_state}}）

{{#if (eq activation_state "candidate")}}
- 提供 `openapi.yaml` / `swagger.yaml` 或 `*.graphql` schema 文件
{{/if}}
