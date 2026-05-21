---
doc_id: "{domain}-conflicts"
title: "冲突规则"
domain: "{domain}"
sub_domain: "common"
doc_type: "conflicts"
version: "v0.1.0"
status: "pending"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
tags:
  - "{domain}"
  - "common"
  - "conflicts"
---

# 冲突规则

本文件记录多项目事实、规则等级或 AI 行为冲突。冲突项**不得**进入默认 AI 执行路径。

> 引用规则统一使用 `{source_doc}「{section_title}」`。本文件条目自身用 `CONFLICT-{DOMAIN}-{NUMBER}` 编号。

## CONFLICT-{DOMAIN}-{NUMBER}: {标题}

- conflict_kind: `level-conflict` / `behavior-conflict` / `scope-conflict` / `cross-project-fact-conflict` / `industry-vs-codebase`
- 涉及规则 / 事实（N 元）：
  1. `{source_doc}「{section_title}」` 或 `evidence/code-facts.md「EV-{DOMAIN}-{NUMBER}」`
  2. `{source_doc}「{section_title}」` 或 `evidence/code-facts.md「EV-{DOMAIN}-{NUMBER}」`
  3. `{source_doc}「{section_title}」` 或 `evidence/code-facts.md「EV-{DOMAIN}-{NUMBER}」`
- 影响范围：
- 风险：
- 建议处理（recommended_action）：
  - [ ] `defer`
  - [ ] `mark-conflict` 维持冲突标记
  - [ ] 选择其中一条作为唯一规则，其余 `reject`
  - [ ] 拆分适用范围（场景 / 子领域 / 业务模块）后并存
  - [ ] 升级到行业 / 安全 / 合规决策
- 需要确认人角色：端 / 架构 / 安全 / 合规 / 行业
- 需要确认人：
- 截止日期 (SLA)：YYYY-MM-DD
