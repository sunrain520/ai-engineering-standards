# Evidence Templates

> 本文件给出 4 份独立 evidence 文件的模板。Generation 阶段按 `output-targets.md` 拆为 4 个文件，分别落到 `evidence/code-facts.md` / `evidence/positive-examples.md` / `evidence/forbidden-examples.md` / `evidence/legacy-compatible.md`。
>
> 每个 evidence 条目供规则正文用 `evidence/{kind}.md「{条目编号}」` 二元组回引。

---

## 1. code-facts.md（写入 `evidence/code-facts.md`）

```markdown
---
doc_id: "{domain}-{sub_domain}-evidence-code-facts"
title: "{Domain} Code Facts"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "evidence-code-facts"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
tags:
  - "{domain}"
  - "{sub_domain}"
  - "evidence"
  - "code-facts"
---

# {Domain} Code Facts

## EV-{DOMAIN}-{NUMBER}: {事实标题}

- 来源项目：
- 路径：
- 子领域：
- 观察事实：
- 推导边界：
- evidence_tier: direct-code / cross-project / single-project / inferred
- 置信度：high / medium / low
- 敏感信息处理：
- run_id：
- first_seen：YYYY-MM-DD
- last_seen：YYYY-MM-DD
- 关联规则：`{source_doc}「{section_title}」`
```

---

## 2. positive-examples.md（写入 `evidence/positive-examples.md`）

```markdown
---
doc_id: "{domain}-{sub_domain}-evidence-positive"
title: "{Domain} Positive Examples"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "evidence-positive"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
tags:
  - "{domain}"
  - "{sub_domain}"
  - "evidence"
  - "positive"
---

# {Domain} Positive Examples

## POS-{DOMAIN}-{NUMBER}: {正例标题}

- 关联 code-facts: `evidence/code-facts.md「EV-{DOMAIN}-{NUMBER}」`
- 来源项目：
- 路径：
- 推荐模式：
- 支撑规则：`{source_doc}「{section_title}」`
- run_id：
- first_seen：YYYY-MM-DD
- last_seen：YYYY-MM-DD
```

---

## 3. forbidden-examples.md（写入 `evidence/forbidden-examples.md`）

```markdown
---
doc_id: "{domain}-{sub_domain}-evidence-forbidden"
title: "{Domain} Forbidden Examples"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "evidence-forbidden"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
tags:
  - "{domain}"
  - "{sub_domain}"
  - "evidence"
  - "forbidden"
---

# {Domain} Forbidden Examples

## NEG-{DOMAIN}-{NUMBER}: {反例标题}

- 关联 code-facts: `evidence/code-facts.md「EV-{DOMAIN}-{NUMBER}」`
- 来源项目：
- 路径：
- 问题：
- 风险：
- 替代做法：
- 支撑规则：`{source_doc}「{section_title}」`
- run_id：
- first_seen：YYYY-MM-DD
- last_seen：YYYY-MM-DD
```

---

## 4. legacy-compatible.md（写入 `evidence/legacy-compatible.md`）

```markdown
---
doc_id: "{domain}-{sub_domain}-evidence-legacy"
title: "{Domain} Legacy Compatible"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "evidence-legacy"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
tags:
  - "{domain}"
  - "{sub_domain}"
  - "evidence"
  - "legacy-compatible"
---

# {Domain} Legacy Compatible

## LEG-{DOMAIN}-{NUMBER}: {历史兼容标题}

- 关联 code-facts: `evidence/code-facts.md「EV-{DOMAIN}-{NUMBER}」`
- 来源项目：
- 路径：
- 历史背景：
- 兼容范围：
- 截止时间：YYYY-MM-DD
- 不得扩散范围：
- 支撑规则：`{source_doc}「{section_title}」`
- run_id：
- first_seen：YYYY-MM-DD
- last_seen：YYYY-MM-DD
```
