---
doc_id: "{{domain}}-ea-doc-decision"
dimension_id: EA-Doc-Decision
status: "{{status}}"
evidence_tier: "{{evidence_tier}}"
domain: "{{domain}}"
generated_by: phase-2-extractor
---

# §EA-Doc-Decision ADR / RFC / 设计决策 [{{activation_state}}]

> ```yaml
> dimension_id: EA-Doc-Decision
> activation_state: {{activation_state}}
> layer: doc
> high_risk_fallback: baseline      # 任何团队都应有决策记录；无 ADR 时保留入口章节
> evidence_count: {{evidence_count}}
> depth_score: {{depth_score}}
> signal_hits: {{signal_hits}}
> ```

## 决策记录来源

| 目录 | 决策数 | 最新 ADR |
| --- | --- | --- |
| {{adr_dir_1}} | {{adr_count_1}} | {{latest_adr_1}} |

详见 `evidence/knowledge/decisions-summary.md`。

## 关键决策摘要（从 `evidence/knowledge/decisions-summary.md` 提炼）

| 编号 | 标题 | 状态 | 来源 |
| --- | --- | --- | --- |
| {{adr_id_1}} | {{adr_title_1}} | {{adr_status_1}} | {{adr_file_1}} |
| （更多决策见 `evidence/knowledge/decisions-summary.md`） | | | |

## 决策记录规则

- 所有影响架构、技术选型、外部依赖的决策 **必须有对应 ADR**（见 `docs/adr/`）
- ADR 格式：`# ADR-NNN 标题` + `## 状态` + `## 背景` + `## 决策` + `## 后果`
- 已被推翻的决策改状态为 `superseded by ADR-NNN`，不删除文件

{{#if (eq activation_state "baseline")}}
> **[baseline 说明]** 当前项目未发现 ADR/RFC 文件。已保留本节入口（高风险兜底）。
> 建议团队在 `docs/adr/` 目录创建至少一条 ADR，升级为 `activated` 后本节将自动填充摘要。
{{/if}}

## 升级条件（当前 state 为 {{activation_state}}）

{{#if (eq activation_state "candidate")}}
- 创建 `docs/adr/` 或 `docs/decisions/` 目录并添加 ≥ 1 条 ADR 文件
{{/if}}
{{#if (eq activation_state "baseline")}}
- 同上：添加 ≥ 1 条 ADR 文件后重跑萃取
{{/if}}
