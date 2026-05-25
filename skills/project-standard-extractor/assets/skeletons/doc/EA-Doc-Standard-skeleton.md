---
doc_id: "{{domain}}-ea-doc-standard"
dimension_id: EA-Doc-Standard
status: "{{status}}"
evidence_tier: "{{evidence_tier}}"
domain: "{{domain}}"
generated_by: phase-2-extractor
---

# §EA-Doc-Standard 团队开发规范文档 [{{activation_state}}]

> ```yaml
> dimension_id: EA-Doc-Standard
> activation_state: {{activation_state}}
> layer: doc
> evidence_count: {{evidence_count}}
> depth_score: {{depth_score}}
> signal_hits: {{signal_hits}}
> ```

## 规范文档来源

（由 doc-source-scanner 自动识别）

| 文件 | 类型 | 关键内容摘要 |
| --- | --- | --- |
| {{file_1}} | {{type_1}} | {{summary_1}} |

## 提炼规则

以下规则直接从 `{{signal_source}}` 提炼，与 AI 规范产物（`ai-rules.md`）互引：

1. （generation agent 填充）

## 冲突说明

如发现本节内容与代码维度规则（EA-Client / EA-Backend 等）有重叠，以代码维度的 `evidence: real-evidence` 版本为准；本节仅补充文档化规范中额外的规范点。

## 升级条件（当前 state 为 {{activation_state}}）

{{#if (eq activation_state "candidate")}}
- 提供 `CONTRIBUTING.md` 或 `docs/conventions/` 等规范文档
{{/if}}
