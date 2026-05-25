---
doc_id: "{domain}-overview"
title: "{Domain} 规范概览"
domain: "{domain}"
sub_domain: "common"
doc_type: "overview"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
tags:
  - "{domain}"
  - "common"
  - "overview"
  - "engineering-standards"
---

# {Domain} 规范概览

## 1. 定位

{说明该研发域规范覆盖什么，不覆盖什么。}

## 2. 子领域覆盖矩阵

| 子领域 | 状态 | 风险等级 | 负责人 | 最近评审日期 | evidence | 负责人确认 |
| --- | --- | --- | --- | --- | --- | --- |
| {sub_domain} | no-evidence | none | TBD | YYYY-MM-DD 或 - | 无 | 待确认 |

字段取值：

- 状态：`evidence-backed` / `pending-confirmation` / `no-evidence` / `out-of-scope`
- 风险等级：`high` / `medium` / `low` / `none`

## 3. 使用入口

- 规范正文：`standard.md`
- AI 规则：`ai-rules.md`
- Review 清单：`review-checklist.md`
- 待确认：`pending-confirmation.md`
- 合并建议：`merge-suggestions.md`
- 冲突：`conflicts.md`
- 示例：`examples/README.md`
- 证据：`evidence/README.md`
  - `evidence/code-facts.md`
  - `evidence/positive-examples.md`
  - `evidence/forbidden-examples.md`
  - `evidence/legacy-compatible.md`

## 4. AI 使用提醒

AI 默认必须执行：

- 规则 `status: active` 的 `level: P0` / `FORBIDDEN`。
- 或 `status: draft`，且 `source_kind ∈ {extracted, owner-confirmed}`、`evidence_tier ≠ none`。

AI 不得执行：

- `status: pending-confirmation` / `conflict` / `legacy-compatible` / `rejected`。
- `source_kind: template-placeholder` 或 `evidence_tier: none`。

跨文档引用规则统一使用 `{source_doc}「{section_title}」` 二元组，**不使用 Rule ID**。

## 5. 本次运行追溯

- review-report：`{domain}/temp/{run_id}-review-report.md`（`indexable: false`）
- 规则状态决策：`rule-state-decision/*.md`（`indexable: false`）
- project-profile / extraction-map / batch-plan：`{domain}/temp/{run_id}-*.md`（`indexable: false`）
- fast-index candidates：`{domain}/temp/{run_id}-rules-index-candidate.json`、`{domain}/temp/{run_id}-llms-candidate.txt`、`{domain}/temp/{run_id}-ai-context-pack.md`
