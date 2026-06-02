---
doc_id: "industry-ecommerce-standard"
title: "电商业务规范"
domain: "industry"
sub_domain: "ecommerce"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["industry", "ecommerce"]
---

# 电商业务规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`ecommerce`(SKU / 购物车 / 订单 / 履约)
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:商品 / SKU、购物车、下单、库存扣减、履约、售后。
**不应承载**:支付通道实现(见 finance)。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
{module}/
├── product/
├── sku/
├── cart/
├── order/
├── inventory/
├── fulfillment/
└── after-sales/
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 职责 | 禁止 |
| --- | --- | --- |
| product / sku | 商品库 | 库存写入 |
| cart | 购物车持久化与营销 | 直接扣库存 |
| order | 订单状态机 | 商品库读 |
| inventory | 库存扣减 | 业务路由 |
| fulfillment | 发货 / 物流 | 营销活动 |

## 5. 命名规范 [{{activation_state_section_5}}]

- 商品 `product_id` / SKU `sku_id` / 订单 `order_id` / 物流 `shipment_id`
- 状态枚举 PascalCase:`OrderStatus.Created` / `Paid` / `Shipped` / `Completed` / `Cancelled`

## 6. 核心规则 [{{activation_state_section_6}}]

### P1 库存扣减必须幂等

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**强制规则**:库存扣减以订单号 + 商品行 ID 幂等;支持回滚补偿。

### FORBIDDEN 订单状态绕过状态机直接修改

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ 直接 `update orders set status = ?`。必须经状态机服务。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
浏览 → 加购 → 下单 → 锁库 → 支付 → 扣库 → 履约 → 售后
```

## 8. 平台差异 [{{activation_state_section_8}}]

- 跨境电商场景下需结合 `cross-border` 子域(汇率 / 关税 / 物流时效)

## 9. 错误模型 [{{activation_state_section_9}}]

- `INVENTORY_INSUFFICIENT` / `ORDER_STATUS_INVALID` / `CART_EXPIRED`
- 营销冲突使用 `PROMOTION_CONFLICT_*`

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成订单代码必须使用状态机服务,不得直接 SQL 改 status
- 库存扣减必须幂等 key 来自订单 + 商品行

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] 库存扣减幂等
- [ ] 订单状态机闭合
- [ ] 营销规则单测覆盖

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-IND-{{N}}` | `**/order/**` | {{core_observation}} | {{confidence}} |
