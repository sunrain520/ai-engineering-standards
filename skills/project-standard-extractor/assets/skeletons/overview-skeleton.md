---
doc_id: "{{end_type}}-overview"
title: "{{End_Type_Display}} 规范概览"
domain: "{{end_type}}"
sub_domain: "common"
doc_type: "overview"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "{{run_id}}"
activation_report: "{{end_dir}}/temp/{{run_id}}-dimension-activation.json"
tags:
  - "{{end_type}}"
  - "common"
  - "overview"
  - "engineering-standards"
---

# {{End_Type_Display}} 规范概览

<!-- 写作说明（生成时删除）
- 本文件为端级 overview,严格按 R51 强制章节顺序输出
- §9「未激活维度地图」为 R51 + AE7 强制章节,即使 candidate 列表为空也必须保留章节标题与"无候选维度"说明
- 跨文档引用使用 `{source_doc}「{section_title}」` 二元组,不使用 Rule ID
-->

## 1. 适用范围

{{scope_description}}

- 覆盖端类型:`{{end_type}}`
- 覆盖子领域:{{subdomains_csv}}
- 不覆盖:{{out_of_scope_list}}

## 2. 架构目标

{{architecture_goals}}

## 3. 分层依赖图

```text
{{layer_dependency_diagram}}
```

## 4. 分层职责矩阵

| 层级 | 核心职责 | 禁止事项 | 主要子领域 |
| --- | --- | --- | --- |
| {{layer_a}} | {{layer_a_responsibility}} | {{layer_a_forbidden}} | {{layer_a_subdomain}} |
| {{layer_b}} | {{layer_b_responsibility}} | {{layer_b_forbidden}} | {{layer_b_subdomain}} |
| {{layer_c}} | {{layer_c_responsibility}} | {{layer_c_forbidden}} | {{layer_c_subdomain}} |

## 5. 文档索引

| 子领域 | 状态 | 风险等级 | 负责人 | 最近评审日期 | evidence | 负责人确认 |
| --- | --- | --- | --- | --- | --- | --- |
| {{sub_domain}} | {{status}} | {{risk_tag}} | {{owner}} | {{last_reviewed}} | {{evidence_ref}} | {{confirmation}} |

字段取值:

- 状态:`evidence-backed` / `pending-confirmation` / `no-evidence` / `out-of-scope`
- 风险等级:`high` / `medium` / `low` / `none`

子领域规范入口:

- `standard-{{sub_domain}}.md`:子领域开发规范(对应骨架 `sub-domain-skeleton.md`)
- `cross-cutting/{{cross_topic}}.md`:跨子领域横切规则(对应骨架 `cross-cutting-skeleton.md`)
- `evidence/`:`code-facts.md` / `positive-examples.md` / `forbidden-examples.md` / `legacy-compatible.md`

## 6. 强制规则摘要

> 本节为各子领域 P0 / FORBIDDEN 规则的端级汇总视图,正文与修改请改对应子领域文档。

- {{forbidden_summary_1}}
- {{forbidden_summary_2}}

## 7. 落地要求

AI 与人工生成 {{end_type}} 代码时默认必须执行:

- 规则 `status: active` 的 `level: P0` / `FORBIDDEN`
- 或 `status: draft`,且 `source_kind ∈ {extracted, owner-confirmed}`、`evidence_tier ≠ none`

不得执行:

- `status: pending-confirmation` / `conflict` / `legacy-compatible` / `rejected`
- `source_kind: template-placeholder` 或 `evidence_tier: none`

## 8. 规则等级定义

| 等级 | 含义 | AI 默认行为 |
| --- | --- | --- |
| `P0` | 强制执行,违反即阻断 | 必须遵守 |
| `P1` | 强制执行,违反需 review 拦截 | 必须遵守 |
| `P2` | 推荐执行 | 应当遵守 |
| `FORBIDDEN` | 严禁出现 | 不得生成 |

## 9. 未激活维度地图

> R51 + AE7 强制章节。列出本次运行中处于 `candidate` 状态(命中默认配置但未在代码中观察到充分 evidence)的维度,供后续启用判断。

| 维度 ID | 维度名称 | 子领域 | 未使用原因 | 候选 evidence 信号 | 启用条件 |
| --- | --- | --- | --- | --- | --- |
| {{candidate_dim_id}} | {{candidate_dim_name}} | {{candidate_subdomain}} | {{candidate_reason}} | {{candidate_signals_csv}} | {{enable_condition}} |

如本次无 candidate 维度,本表保留首行表头与「无候选维度」说明,**不删除整节**。

## 10. 本次运行追溯

- review-report:`{{end_dir}}/temp/{{run_id}}-review-report.md`(`indexable: false`)
- 维度激活报告:`{{end_dir}}/temp/{{run_id}}-dimension-activation.json`(`indexable: false`)
- 规则状态决策:`{{end_dir}}/temp/{{run_id}}-rule-state-decision/*.md`(`indexable: false`)
- project-profile / extraction-map / batch-plan:`{{end_dir}}/temp/{{run_id}}-*.md`(`indexable: false`)
- fast-index candidates:`{{end_dir}}/temp/{{run_id}}-rules-index-candidate.json`、`{{end_dir}}/temp/{{run_id}}-llms-candidate.txt`、`{{end_dir}}/temp/{{run_id}}-ai-context-pack.md`
