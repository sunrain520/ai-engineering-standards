---
doc_id: "industry-healthcare-standard"
title: "医疗健康业务规范"
domain: "industry"
sub_domain: "healthcare"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["industry", "healthcare", "phi", "ehr"]
---

# 医疗健康业务规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`healthcare`(EHR / 处方 / 诊断 / PHI)
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:患者档案、就诊记录、处方、诊断、PHI 脱敏、HIPAA / 等保对齐。
**不应承载**:通用 IM / 通用支付。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
{module}/
├── patient/
├── encounter/                   — 就诊
├── prescription/
├── diagnosis/
├── ehr/
└── consent/                     — 知情同意
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 职责 | 禁止 |
| --- | --- | --- |
| patient | 患者主索引 (MPI) | 处方写入 |
| encounter | 就诊单 | 患者编辑 |
| prescription | 处方 | 诊断变更 |
| ehr | 电子病历 | 业务路由 |
| consent | 知情同意 | 业务规则 |

## 5. 命名规范 [{{activation_state_section_5}}]

- `patient_id` 必须为机构内主索引,避免暴露身份证号
- ICD-10 / SNOMED 编码字段统一前缀

## 6. 核心规则 [{{activation_state_section_6}}]

### P0 PHI 数据必须加密静态存储

> level: P0 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

> ⛔ PHI(姓名 / 身份证 / 病历内容)落库必须字段级加密;访问需审计日志。

### FORBIDDEN 处方未电子签名

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

> ⛔ 电子处方 **必须** 医师电子签名,禁止裸文本生成。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
登记 → 就诊 → 诊断 → 处方 → 调剂 → 随访
```

## 8. 平台差异 [{{activation_state_section_8}}]

- 与 HIS / LIS / PACS 系统对接走 HL7 / FHIR 协议

## 9. 错误模型 [{{activation_state_section_9}}]

- `PHI_ACCESS_DENIED` / `PRESCRIPTION_NOT_SIGNED` / `DIAGNOSIS_INVALID_CODE`

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成涉及 PHI 字段的代码必须使用 `@PHI` 注解并加密
- 处方接口必须验证医师电子签名
- 不得日志输出原始 PHI

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] PHI 字段加密
- [ ] 处方签名验证
- [ ] 审计日志覆盖访问 / 修改 / 删除

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-IND-{{N}}` | `**/{patient,prescription}/**` | {{core_observation}} | {{confidence}} |
