# 规范质量门禁

本文件是所有规范生成、评审和状态流转的 canonical policy。Skill 包内的 `quality-gate.md` 只能作为 workflow adapter，必须引用本文件。

## 1. 门禁总览

| 门禁 | 负责人 / 角色 | 不通过时去向 |
| --- | --- | --- |
| 证据门禁 | Evidence Auditor | `pending-confirmation` |
| 团队级抽象门禁 | Team Standard Reviewer | 重写或 `rejected` |
| AI 可执行性门禁 | AI Executability Reviewer | 重写 |
| Review 可检查性门禁 | Review Checklist Reviewer | 重写 |
| 正反例门禁 | Evidence Auditor | 补 evidence 或降级 |
| 规则数量门禁 | Quality Gate | 合并、拆分或延期 |
| 人工确认门禁 | 领域负责人 | `draft` 保持或升级 `active` |
| 冲突门禁 | Conflict Reviewer | `conflict` |
| 行业风险门禁 | Industry Risk Reviewer | `pending-confirmation` 或高风险 warning |

## 2. 进入 `draft` 的最低条件

1. `source_kind` 是 `extracted` 或 `owner-confirmed`。
2. `evidence_tier` 不是 `none`。
3. 规则正文不包含具体项目路径。
4. 有 AI 生成代码要求。
5. 有 Code Review 检查项。
6. P0 / FORBIDDEN 有正反例或真实问题 evidence。

## 3. 进入 `active` 的最低条件

1. 已经是 `draft`。
2. 对应领域负责人确认（端规范由端负责人，行业规范由行业负责人）。
3. 高风险规则建议邀请架构、安全、行业或合规负责人参与评审；第一阶段不强制会签，端 / 行业负责人确认后即可升级。
4. 无未解决 `conflict`。
5. 规则没有和现有 `active` 规则冲突。

## 4. 必须进入 `pending-confirmation`

1. 只有行业共性或模板建议，没有团队 evidence。
2. 单项目事实不足以抽象成团队标准。
3. 存在风险但缺少 Review 检查项。
4. 负责人或 reviewer 无法判断适用范围。

## 5. 必须进入 `conflict`

1. 多项目实践相互矛盾。
2. 新规则和已有 `active` 冲突。
3. 同一主题出现不同等级、不同禁止范围或不同 AI 行为。

## 6. 必须 `rejected`

1. 把历史包袱写成推荐规则。
2. 把项目说明书写成团队标准。
3. 规则正文包含敏感信息。
4. 无法被 AI 执行，也无法被 Review 检查。
