---
doc_id: "industry-finance-standard"
title: "金融(非证券)业务规范"
domain: "industry"
sub_domain: "finance-nonsec"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["industry", "finance"]
---

# 金融(非证券)业务规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`finance-nonsec`(支付 / 钱包 / 退款 / 风控)
- 端类型:`industry`
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:支付通道、订单 / 账单、风控、对账、退款、KYC。
**不应承载**:证券特有逻辑(见 securities-skeleton)。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
{module}/
├── payment/
├── balance-account/
├── refund/
├── risk/
└── reconciliation/
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 职责 | 禁止 |
| --- | --- | --- |
| payment | 收单 / 通道路由 | 钱包余额变更 |
| balance-account | 余额账户 | 渠道直连 |
| risk | 反欺诈 / 限额 | 业务路由 |
| reconciliation | 对账 / 差错 | 实时交易 |

## 5. 命名规范 [{{activation_state_section_5}}]

- 金额字段统一使用最小货币单位 + currency 字段;**禁止** 浮点
- 流水号 `*_no`,业务订单 `*_order_id`

## 6. 核心规则 [{{activation_state_section_6}}]

### P0 金额必须使用 BigDecimal / 整型最小单位

> level: P0 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ 金额计算 **禁止** 使用 `double` / `float`。

### FORBIDDEN 退款不走幂等

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ 退款 / 出金 接口必须幂等,以业务流水号 + 状态机控制重复调用。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
下单 → 风控 → 通道 → 回调 → 钱包 → 对账
```

## 8. 平台差异 [{{activation_state_section_8}}]

- 各支付通道(微信 / 支付宝 / 银联 / Stripe)在 `payment/adapters/` 实现统一接口

## 9. 错误模型 [{{activation_state_section_9}}]

- `PAYMENT_FAILED_*` / `RISK_BLOCKED_*` / `BALANCE_INSUFFICIENT_*`
- 通道错误统一映射至业务错误码,保留通道原始码于 `extra`

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成支付逻辑必须使用 BigDecimal + currency
- 异步回调必须幂等 + 重试

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] 金额非浮点
- [ ] 出金 / 退款幂等
- [ ] 对账任务每日跑

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-IND-{{N}}` | `**/payment/**` | {{core_observation}} | {{confidence}} |
