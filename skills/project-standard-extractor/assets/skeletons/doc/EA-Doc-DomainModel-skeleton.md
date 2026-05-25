---
doc_id: "{{domain}}-ea-doc-domain-model"
dimension_id: EA-Doc-DomainModel
status: "{{status}}"
evidence_tier: "{{evidence_tier}}"
domain: "{{domain}}"
generated_by: phase-2-extractor
---

# §EA-Doc-DomainModel 领域模型 / Bounded Context [{{activation_state}}]

> ```yaml
> dimension_id: EA-Doc-DomainModel
> activation_state: {{activation_state}}
> layer: doc
> evidence_count: {{evidence_count}}
> depth_score: {{depth_score}}
> signal_hits: {{signal_hits}}
> ```

## 核心实体（从 `evidence/knowledge/domain-model.md` 提炼）

| 实体名 | 所属 BC | 简述 | 来源 |
| --- | --- | --- | --- |
| {{entity_1}} | {{bc_1}} | {{desc_1}} | {{source_1}} |
| （更多实体见 `evidence/knowledge/domain-model.md`） | | | |

## Bounded Context 边界

（从 docs/architecture.md 或 docs/domain-model.md 提炼，当前状态 {{activation_state}}）

## 跨上下文通信契约

- 跨 BC 通信应通过明确的 Anti-Corruption Layer 或 Open-Host Service
- 禁止直接跨 BC 引用内部实体 ID（应使用 event / contract DTO）

## 升级条件（当前 state 为 {{activation_state}}）

{{#if (eq activation_state "candidate")}}
- 提供 `docs/domain-model.md` 或 `docs/architecture.md` 含实体定义
- 或 Wiki/Confluence 导出含"领域模型"/"Bounded Context" 相关文档
{{/if}}
