---
doc_id: "industry-government-standard"
title: "政企业务规范"
domain: "industry"
sub_domain: "goventerprise"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["industry", "government", "等保"]
---

# 政企业务规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`goventerprise`(政务 / 国企 / 等保合规场景)
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:审批流、办件、文书、政务公开、等保 2.0 / 3.0 合规对齐。
**不应承载**:面向 C 端营销、第三方支付。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
{module}/
├── citizen/                     — 法人 / 自然人
├── filing/                      — 办件 / 申报
├── approval/                    — 审批流
├── document/
└── audit/
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 职责 | 禁止 |
| --- | --- | --- |
| citizen | 实名档案 | 业务路由 |
| filing | 办件单 | 文书生成 |
| approval | 审批流引擎 | 业务规则混入 |
| document | 文书生成 / 归档 | 审批状态 |
| audit | 审计日志 / 等保合规 | 业务执行 |

## 5. 命名规范 [{{activation_state_section_5}}]

- 办件号 `application_no`,审批流 `approval_flow_id`
- 文书模板 `*_template`,文书实例 `*_doc_id`

## 6. 核心规则 [{{activation_state_section_6}}]

### P0 数据存储位置必须本地化

> level: P0 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

> ⛔ 用户数据必须存储在境内合规机房 / gov-cloud,禁止跨境传输。

### FORBIDDEN 系统操作不留审计

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

> ⛔ 关键审批 / 数据修改必须留审计,审计日志不可篡改。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
申报 → 受理 → 审批 → 文书 → 归档 → 公示
```

## 8. 平台差异 [{{activation_state_section_8}}]

- 等保 2.0 三级 / 四级要求不同:四级需 SGX / 国密 / WAF 等加固

## 9. 错误模型 [{{activation_state_section_9}}]

- `APPROVAL_DENIED` / `FILING_INVALID` / `DOCUMENT_TEMPLATE_NOT_FOUND`

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成涉及个人 / 法人数据的接口必须显式合规标记
- 国密算法(SM2/SM3/SM4)优先于通用算法

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] 数据本地化
- [ ] 国密支持
- [ ] 审计日志不可篡改

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-IND-{{N}}` | `**/{filing,approval,audit}/**` | {{core_observation}} | {{confidence}} |
