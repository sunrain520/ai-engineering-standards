---
doc_id: "{domain}-pending-confirmation"
title: "待确认规则"
domain: "{domain}"
sub_domain: "common"
doc_type: "pending-confirmation"
version: "v0.1.0"
status: "pending"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
tags:
  - "{domain}"
  - "common"
  - "pending-confirmation"
---

# 待确认规则

本文件收纳无足够 evidence、存在适用范围疑问或需要负责人确认的规则候选。这里的内容**不得**被 AI 当作强制规范执行。

> 引用规则统一使用 `{source_doc}「{section_title}」`。本文件条目自身用 `PENDING-{DOMAIN}-{NUMBER}` 编号，仅用于跨文档回引。

## PENDING-{DOMAIN}-{NUMBER}: {标题}

- 拟定规则正文标题：`{section_title}`（按 `^(P0|P1|P2|FORBIDDEN) ` 前缀；正式入库后写入 `standard.md` 的对应 H2）
- 拟定 source_doc：`{domain}/{sub_domain}/standard.md`
- 来源（事实 / 行业 / 用户提议）：
- 关联 evidence：
  - `evidence/code-facts.md「EV-{DOMAIN}-{NUMBER}」`
  - `evidence/positive-examples.md「POS-{DOMAIN}-{NUMBER}」`
  - `evidence/forbidden-examples.md「NEG-{DOMAIN}-{NUMBER}」`
- 缺失 evidence：
- 需要确认的问题：
- 建议负责人角色：端 / 架构 / 安全 / 合规 / 行业
- 建议负责人：
- 截止日期 (SLA)：YYYY-MM-DD
- 下一步：
- 状态迁移意向：
  - [ ] 升级到 `standard.md` 的 `status: draft`
  - [ ] 标记为 `conflict` 写入 `conflicts.md`
  - [ ] `rejected`
  - [ ] 继续 `pending`，新截止日期：YYYY-MM-DD
