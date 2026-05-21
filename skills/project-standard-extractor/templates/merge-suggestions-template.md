---
doc_id: "{domain}-merge-suggestions"
title: "合并建议"
domain: "{domain}"
sub_domain: "common"
doc_type: "merge-suggestions"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
tags:
  - "{domain}"
  - "common"
  - "merge-suggestions"
---

# 合并建议

本文件记录相近规则、重复规则或 evidence 可合并的候选项。Merge Coordinator 只能追加建议，**不能自动覆盖已有规则**。

> 引用规则统一使用 `{source_doc}「{section_title}」`。本文件条目自身用 `MERGE-{DOMAIN}-{NUMBER}` 编号。

## MERGE-{DOMAIN}-{NUMBER}: {标题}

- 新规则候选：`{source_doc}「{section_title}」` 或 `pending-confirmation.md「PENDING-{DOMAIN}-{NUMBER}」`
- 相关已有规则（N 元）：
  1. `{source_doc}「{section_title}」`
  2. `{source_doc}「{section_title}」`
- 相似点：
- 差异点：
- 关联 evidence：
  - `evidence/code-facts.md「EV-{DOMAIN}-{NUMBER}」`
  - `evidence/positive-examples.md「POS-{DOMAIN}-{NUMBER}」`
- 建议处理（recommended_action）：
  - [ ] `merge`：合并为一条新规则，旧规则 `superseded_by` 指向新规则
  - [ ] `split`：按子领域 / 场景拆分为多条独立规则
  - [ ] `replace`：用新规则替换旧规则
  - [ ] `keep-separate`：维持独立，仅在文档间互相引用
  - [ ] `defer`：延期决策
- 需要确认人角色：端 / 架构 / 安全 / 合规 / 行业
- 需要确认人：
- 截止日期 (SLA)：YYYY-MM-DD
