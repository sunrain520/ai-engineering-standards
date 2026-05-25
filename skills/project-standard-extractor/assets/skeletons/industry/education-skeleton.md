---
doc_id: "industry-education-standard"
title: "教育业务规范"
domain: "industry"
sub_domain: "education"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["industry", "education"]
---

# 教育业务规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`education`(课程 / 报名 / 学员)
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:课程目录、排课、报名、学习记录、成绩、证书。
**不应承载**:通用 LMS 第三方对接的具体协议(放 adapter)。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
{module}/
├── course/
├── enrollment/
├── lesson/
├── student/
├── progress/
└── certificate/
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 职责 | 禁止 |
| --- | --- | --- |
| course | 课程目录、版本 | 报名状态 |
| enrollment | 报名 / 退课 / 调班 | 课程编辑 |
| lesson | 课节 / 直播 / 录播 | 学员账号 |
| progress | 学习进度、记录 | 课程编辑 |

## 5. 命名规范 [{{activation_state_section_5}}]

- `course_id` / `lesson_id` / `enrollment_id` / `student_id`
- 进度状态:`NotStarted` / `InProgress` / `Completed` / `Expired`

## 6. 核心规则 [{{activation_state_section_6}}]

### P1 未成年人数据隔离

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

**强制规则**:未成年学员的 PII 字段单独加密,访问需家长授权 + 审计日志。

### FORBIDDEN 课程内容明文外泄

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

> ⛔ 录播 / 直播流地址 **禁止** 明文返回;必须签名 URL + 时效。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
课程发布 → 报名 → 排课 → 学习 → 进度 → 证书
```

## 8. 平台差异 [{{activation_state_section_8}}]

- B 端机构后台 vs C 端学员 App,共享课程目录服务

## 9. 错误模型 [{{activation_state_section_9}}]

- `ENROLLMENT_CLOSED` / `LESSON_NOT_STARTED` / `CERTIFICATE_NOT_ELIGIBLE`

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成涉及未成年人的接口必须经家长授权校验
- 录播流地址必须签名

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] 未成年人 PII 加密
- [ ] 录播流签名
- [ ] 进度更新幂等

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-IND-{{N}}` | `**/{course,enrollment}/**` | {{core_observation}} | {{confidence}} |
