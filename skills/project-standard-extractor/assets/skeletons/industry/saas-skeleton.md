---
doc_id: "industry-saas-standard"
title: "SaaS / B 端业务规范"
domain: "industry"
sub_domain: "saas"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["industry", "saas", "multi-tenant"]
---

# SaaS / B 端业务规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`saas`(多租户 / 计费 / 席位 / 工作区)
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:Tenant / Workspace 隔离、订阅与计费、席位、用量计量、用户邀请。
**不应承载**:具体业务模块(应放各业务子域)。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
{module}/
├── tenant/
├── workspace/
├── subscription/
├── billing/
├── seat/
├── invitation/
└── usage/
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 职责 | 禁止 |
| --- | --- | --- |
| tenant | 租户主索引 / 配额 | 业务路由 |
| workspace | 工作区 / 资源隔离 | 计费规则 |
| subscription | 套餐 / 续费 | 用量计量 |
| billing | 账单 / 发票 | 业务路由 |
| seat | 席位分配 | 业务规则 |
| usage | 用量计量 | 计费规则 |

## 5. 命名规范 [{{activation_state_section_5}}]

- `tenant_id` / `workspace_id` 必须出现在所有业务请求上下文
- 订阅状态:`Trial` / `Active` / `PastDue` / `Cancelled`

## 6. 核心规则 [{{activation_state_section_6}}]

### P0 所有业务查询必须携带 tenant_id

> level: P0 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ 业务 SQL / Repository 查询 **必须** WHERE tenant_id = ?,**禁止** 全表扫描。

### FORBIDDEN 跨租户数据共享

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ 业务接口禁止跨 tenant 关联或缓存共享 key。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
注册 → 创建租户 → 订阅 → 邀请席位 → 业务使用 → 用量上报 → 计费
```

## 8. 平台差异 [{{activation_state_section_8}}]

- 多租户隔离策略:share-db / share-schema / silo,需在 tenant 配置中显式声明

## 9. 错误模型 [{{activation_state_section_9}}]

- `TENANT_QUOTA_EXCEEDED` / `SEAT_LIMIT_REACHED` / `SUBSCRIPTION_EXPIRED`

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成 Repository / Service 必须强制 tenant_id 入参
- 缓存 key 必须含 `tenant:{id}:` 前缀

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] 所有 SQL 含 tenant_id
- [ ] 缓存 key 隔离
- [ ] 用量上报与计费对账

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-IND-{{N}}` | `**/{tenant,workspace,subscription}/**` | {{core_observation}} | {{confidence}} |
