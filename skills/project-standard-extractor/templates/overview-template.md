# {Domain} 规范概览

## 1. 定位

{说明该研发域规范覆盖什么，不覆盖什么。}

## 2. 子领域覆盖矩阵

| 子领域 | 状态 | evidence | 负责人确认 |
| --- | --- | --- | --- |
| {sub_domain} | no-evidence | 无 | 待确认 |

状态取值：`evidence-backed`、`pending-confirmation`、`no-evidence`、`out-of-scope`。

## 3. 使用入口

- 规范正文：`standard.md`
- AI 规则：`ai-rules.md`
- Review 清单：`review-checklist.md`
- 待确认：`pending-confirmation.md`
- 合并建议：`merge-suggestions.md`
- 冲突：`conflicts.md`
- 证据：`evidence/`

## 4. AI 使用提醒

只有 `source_kind` 为 `extracted` 或 `owner-confirmed`，且 `evidence_tier` 不为 `none` 的规则可进入默认 AI 执行路径。
