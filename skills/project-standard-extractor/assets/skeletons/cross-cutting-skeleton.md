---
doc_id: "{{end_type}}-cross-{{cross_topic}}"
title: "{{Cross_Topic_Display}} 横切规则"
domain: "{{end_type}}"
sub_domain: "cross-cutting"
doc_type: "cross-cutting"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
cross_topic: "{{cross_topic}}"
tags:
  - "{{end_type}}"
  - "cross-cutting"
  - "{{cross_topic}}"
---

# {{Cross_Topic_Display}} 横切规则

<!-- 写作说明（生成时删除）
- 横切骨架用于多个子领域共同遵守的能力(如安全、可观测性、配置管理)。
- §3 必须包含"统一要求"列(R55 强制),用于明确所有子领域共同必须满足的最低线。
- 子领域差异列用于说明各子领域在统一要求基础上的额外约束。
-->

## 1. 适用范围 [{{activation_state_section_1}}]

- 覆盖子领域:{{subdomains_csv}}
- 不适用场景:{{out_of_scope_list}}
- 风险标签:`{{risk_tag}}`

## 2. 激活态 [{{activation_state_section_2}}]

| 子领域 | 激活态 | 命中信号 | evidence 数 | 决策原因 |
| --- | --- | --- | --- | --- |
| {{subdomain_a}} | {{state_a}} | {{signals_a}} | {{count_a}} | {{reason_a}} |
| {{subdomain_b}} | {{state_b}} | {{signals_b}} | {{count_b}} | {{reason_b}} |

## 3. 子领域差异对比 [{{activation_state_section_3}}]

> R55 强制:必须包含「统一要求」列,统一要求是各子领域共同必须满足的最低线;不同点列出各子领域专属约束。

| 比较维度 | 统一要求 | {{subdomain_a}} | {{subdomain_b}} |
| --- | --- | --- | --- |
| {{compare_dim_1}} | {{unified_req_1}} | {{subdomain_a_req_1}} | {{subdomain_b_req_1}} |
| {{compare_dim_2}} | {{unified_req_2}} | {{subdomain_a_req_2}} | {{subdomain_b_req_2}} |

## 4. 统一原则 [{{activation_state_section_4}}]

- {{unified_principle_1}}
- {{unified_principle_2}}

## 5. 候选 evidence 信号 [{{activation_state_section_5}}]

| 信号类型 | 模式 / 关键字 | 命中文件示例 |
| --- | --- | --- |
| {{signal_type_1}} | {{signal_pattern_1}} | {{signal_example_1}} |
| {{signal_type_2}} | {{signal_pattern_2}} | {{signal_example_2}} |

## 6. 核心规则 [{{activation_state_section_6}}]

### P1 {{rule_title}}

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: {{risk_tag}} · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**适用范围**

- {{rule_scope}}

**强制规则**

1. {{rule_must_1}}
2. {{rule_must_2}}

**禁止事项**

- 禁止 {{rule_forbidden}}

**正例**

```{{language}}
// 正例:{{positive_explain}}
{{positive_code}}
```

**反例**

```{{language}}
// 反例:{{negative_explain}}
{{negative_code}}
```

**AI 生成代码要求**

1. {{ai_constraint}}

**Code Review 检查项**

- [ ] {{review_check}}

**Evidence**

- `evidence/code-facts.md「EV-{{DOMAIN}}-{{N}}」`

### FORBIDDEN {{forbidden_title}}

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ **FORBIDDEN**:{{forbidden_one_liner}}。负例见 `evidence/forbidden-examples.md「NEG-{{DOMAIN}}-{{N}}」`

## 7. AI 生成要求 [{{activation_state_section_7}}]

AI 生成涉及 {{cross_topic}} 的代码必须:

1. {{ai_must_1}}
2. {{ai_must_2}}

禁止 AI 生成:

- {{ai_must_not_1}}
- {{ai_must_not_2}}

## 8. Review 检查项 [{{activation_state_section_8}}]

- [ ] {{review_check_1}}
- [ ] {{review_check_2}}

## 9. Evidence 参考 [{{activation_state_section_9}}]

| evidence_id | 来源文件(路径模式) | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-{{DOMAIN}}-{{N}}` | `{{path_pattern}}` | {{core_observation}} | {{confidence}} |
