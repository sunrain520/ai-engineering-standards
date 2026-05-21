---
doc_id: "{domain}-{sub_domain}-{slug}-state-decision"
title: "规则状态决策记录"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "rule-state-decision"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
tags:
  - "{domain}"
  - "{sub_domain}"
  - "rule-state-decision"
---

# 规则状态决策记录

> 规则不使用 Rule ID。本记录用 `source_doc + section_title` 二元组定位规则；`{slug}` 是 `section_title` 的 kebab-case 简写，仅用于 `doc_id` 唯一性，不用于规则引用。

## 1. 规则定位

- source_doc：`{source_doc}`
- section_title：`{section_title}`
- 引用串：`{source_doc}「{section_title}」`

## 2. 当前状态

- status: `draft` / `active` / `pending-confirmation` / `conflict` / `legacy-compatible` / `rejected`
- level: `P0` / `P1` / `P2` / `FORBIDDEN`
- risk_tag: `high` / `medium` / `low` / `none`

## 3. 建议动作（recommended_action）

取值之一：

- [ ] `keep-draft`
- [ ] `promote-to-active`
- [ ] `move-to-pending`
- [ ] `mark-conflict`
- [ ] `mark-legacy`
- [ ] `reject`
- [ ] `defer`

## 4. 决策依据

- evidence 引用：
  - `evidence/code-facts.md「EV-{DOMAIN}-{NUMBER}」`
  - `evidence/positive-examples.md「POS-{DOMAIN}-{NUMBER}」`
  - `evidence/forbidden-examples.md「NEG-{DOMAIN}-{NUMBER}」`
  - `evidence/legacy-compatible.md「LEG-{DOMAIN}-{NUMBER}」`
- review findings：
- 负责人确认：

## 5. 决策审计 (audit trail)

按时间倒序追加，**不删除历史**。

| 日期 | 决策人角色 | 决策人 | 决策动作 | 备注 |
| --- | --- | --- | --- | --- |
| YYYY-MM-DD | 端负责人 / 架构负责人 / 安全 / 合规 / 行业负责人 |  |  |  |

## 6. 升级到 active 的剩余阻塞项

- [ ] {阻塞项 1}
- [ ] {阻塞项 2}

## 7. 下次复审

- 计划日期：YYYY-MM-DD
- 触发条件：
