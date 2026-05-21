---
doc_id: "{domain}-{sub_domain}-standard"
title: "{Domain} 团队规范"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
tags:
  - "{domain}"
  - "{sub_domain}"
  - "standard"
  - "ai-coding"
---

# {Domain} 团队规范

## 状态说明

本文件只承载 evidence-backed 或 owner-confirmed 的团队级规则。无 evidence 内容应进入 `pending-confirmation.md` 或模板区。

> 规则定位约定：本文件每条规则使用 `## P0|P1|P2|FORBIDDEN {规则标题}` 作为 H2 标题。外部文档（review、merge、conflict、decision、ai-rules、review-checklist）引用规则时统一使用 `{source_doc}「{section_title}」` 二元组，**不使用 Rule ID，不使用 HTML anchor**。

## 规则示例

### P0 示例

## P0 {规则标题}

```yaml
status: draft                       # draft / active / pending-confirmation / conflict / legacy-compatible / rejected
level: P0                           # P0 / P1 / P2 / FORBIDDEN
source_kind: extracted              # extracted / owner-confirmed / industry-reference / template-placeholder
evidence_tier: direct-code          # direct-code / cross-project / single-project / inferred / none
risk_tag: high                      # high / medium / low / none
owner: TBD
last_reviewed: null                 # 形如 "2026-05-21"，未评审填 null
recommended_action: keep-draft      # keep-draft / promote-to-active / move-to-pending / mark-conflict / mark-legacy / reject / defer
conflicts_with: []                  # 引用其它规则二元组，例如 ["04-backend/02-java/java-standard.md「P0 Controller 不得写业务逻辑」"]
superseded_by: null                 # 同上格式；被新规则替代时填写
```

### 规则

{团队级标准。不写具体代码路径，不写单项目命名。}

### 适用范围

- 研发域：
- 子领域：
- 业务模块：
- 适用场景：

### 推荐做法

1. {推荐做法}

### 禁止做法

1. {禁止做法}

### AI 生成代码要求

1. {生成前检查}
2. {生成时约束}
3. {生成后自检}

### Code Review 检查项

- [ ] {检查项}

### Evidence

- evidence_tier:
- code-facts：`evidence/code-facts.md「EV-{DOMAIN}-{NUMBER}」`
- 正例：`evidence/positive-examples.md「POS-{DOMAIN}-{NUMBER}」`
- 反例：`evidence/forbidden-examples.md「NEG-{DOMAIN}-{NUMBER}」`
- 历史兼容：`evidence/legacy-compatible.md「LEG-{DOMAIN}-{NUMBER}」`

---

### FORBIDDEN 示例

## FORBIDDEN {规则标题}

```yaml
status: draft
level: FORBIDDEN
source_kind: extracted
evidence_tier: cross-project
risk_tag: high
owner: TBD
last_reviewed: null
recommended_action: keep-draft
conflicts_with: []
superseded_by: null
```

### 规则

{明确禁止的写法。}

### 适用范围

- 研发域：
- 子领域：
- 业务模块：
- 适用场景：

### 替代做法

1. {替代写法}

### Code Review 检查项

- [ ] {强制 review 项}

### Evidence

- evidence_tier:
- 反例：`evidence/forbidden-examples.md「NEG-{DOMAIN}-{NUMBER}」`

---

### legacy-compatible 示例

## P2 {规则标题}

```yaml
status: legacy-compatible
level: P2
source_kind: extracted
evidence_tier: single-project
risk_tag: low
owner: TBD
last_reviewed: null
recommended_action: mark-legacy
conflicts_with: []
superseded_by: "{source_doc}「{section_title}」"
```

### 规则

{保留以兼容历史项目，不得在新代码扩散。}

### 历史兼容范围

- 项目类型：
- 截止时间：

### Evidence

- evidence_tier:
- 历史兼容：`evidence/legacy-compatible.md「LEG-{DOMAIN}-{NUMBER}」`
