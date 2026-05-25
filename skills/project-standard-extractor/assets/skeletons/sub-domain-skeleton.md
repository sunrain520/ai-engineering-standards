---
doc_id: "{{end_type}}-{{sub_domain}}-standard"
title: "{{Sub_Domain_Display}} 开发规范"
domain: "{{end_type}}"
sub_domain: "{{sub_domain}}"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags:
  - "{{end_type}}"
  - "{{sub_domain}}"
---

# {{Sub_Domain_Display}} 开发规范

<!-- 写作说明（生成时删除）
- 严格按 R51 §1–§12 强制章节顺序输出。即使本子领域不需要某节内容,也必须保留章节标题 + 一行说明（如"无平台差异"）。
- 每节标题旁的 `[{{activation_state}}]` 占位符在 generation 时替换为 baseline / activated / pending / shallow 之一。
- 节内规则节使用 `assets/standard-template.md` 的 metadata blockquote 风格,禁止整块 yaml。
- 跨文档引用使用 `{source_doc}「{section_title}」` 二元组。
-->

## 1. 规范定位 [{{activation_state_section_1}}]

{{positioning_text}}

- 子领域:`{{sub_domain}}`
- 端类型:`{{end_type}}`
- 激活态:`{{activation_state}}`
- 命中信号:{{hit_signals_csv}}
- evidence 数量:{{evidence_count}}

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**

- {{should_carry_1}}
- {{should_carry_2}}

**不应承载**

- {{should_not_carry_1}}
- {{should_not_carry_2}}

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
{{recommended_directory_tree}}
```

命名规则:

- {{naming_rule_1}}
- {{naming_rule_2}}

## 4. 分层规则 [{{activation_state_section_4}}]

```text
{{layer_diagram}}
```

| 层级 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| {{layer_a}} | {{layer_a_responsibility}} | {{layer_a_forbidden}} |
| {{layer_b}} | {{layer_b_responsibility}} | {{layer_b_forbidden}} |

## 5. 命名规范 [{{activation_state_section_5}}]

- {{naming_convention_1}}
- {{naming_convention_2}}

## 6. 核心规则 [{{activation_state_section_6}}]

### P1 {{rule_title_1}}

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: {{risk_tag}} · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

**适用范围**

- {{rule_scope_1}}

**强制规则**

1. {{rule_must_1}}
2. {{rule_must_2}}

**禁止事项**

- 禁止 {{rule_forbidden_1}}

**正例**

```{{language}}
// 正例:{{positive_explain_1}}
{{positive_code_1}}
```

**反例**

```{{language}}
// 反例:{{negative_explain_1}}
{{negative_code_1}}
```

**AI 生成代码要求**

1. {{ai_constraint_1}}

**Code Review 检查项**

- [ ] {{review_check_1}}

**Evidence**

- `evidence/code-facts.md「EV-{{DOMAIN}}-{{N}}」`
- `evidence/positive-examples.md「POS-{{DOMAIN}}-{{N}}」`

### FORBIDDEN {{rule_title_forbidden}}

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

> ⛔ **FORBIDDEN**:{{forbidden_one_liner}}。负例见 `evidence/forbidden-examples.md「NEG-{{DOMAIN}}-{{N}}」`

**适用范围**

- {{forbidden_scope}}

**禁止事项**

- 禁止 {{forbidden_action}}

**反例**

```{{language}}
// 反例:{{forbidden_explain}}
{{forbidden_code}}
```

**AI 生成代码要求**

1. AI 不得生成 {{forbidden_pattern}}。

**Code Review 检查项**

- [ ] {{forbidden_review}}

**Evidence**

- `evidence/forbidden-examples.md「NEG-{{DOMAIN}}-{{N}}」`

## 7. 数据流链路 [{{activation_state_section_7}}]

<!-- 条件章节:仅当本子领域涉及跨层数据流时填写;不涉及保留标题 + "本子领域无跨层数据流" -->

```text
{{data_flow_diagram}}
```

链路说明:

- {{data_flow_step_1}}
- {{data_flow_step_2}}

## 8. 平台差异 [{{activation_state_section_8}}]

<!-- 条件章节:仅当本子领域跨平台时填写;不涉及保留标题 + "本子领域无平台差异" -->

| 平台 | 差异点 | 处理策略 |
| --- | --- | --- |
| {{platform_a}} | {{diff_a}} | {{strategy_a}} |
| {{platform_b}} | {{diff_b}} | {{strategy_b}} |

## 9. 错误模型 [{{activation_state_section_9}}]

<!-- 条件章节:仅当本子领域有专属错误模型时填写;不涉及保留标题 + "沿用通用错误模型" -->

| 错误码 | 触发条件 | 处理方式 | 用户感知 |
| --- | --- | --- | --- |
| {{error_code}} | {{error_trigger}} | {{error_action}} | {{user_impact}} |

## 10. AI 生成要求 [{{activation_state_section_10}}]

> 本节是各规则节 `AI 生成代码要求` 的汇总视图,不新创内容;规则修改请改对应规则节。

AI 生成 {{sub_domain}} 代码时必须遵守:

1. {{ai_summary_1}}
2. {{ai_summary_2}}

禁止 AI 生成:

- {{ai_forbidden_summary_1}}
- {{ai_forbidden_summary_2}}

## 11. Review 检查项 [{{activation_state_section_11}}]

> 本节是各规则节 `Code Review 检查项` 的汇总视图,不新创内容。

- [ ] {{review_summary_1}}
- [ ] {{review_summary_2}}

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件(路径模式) | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-{{DOMAIN}}-{{N}}` | `{{path_pattern}}` | {{core_observation}} | {{confidence}} |
