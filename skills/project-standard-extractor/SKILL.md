---
name: project-standard-extractor
description: 从一个或多个真实项目代码路径中萃取团队级研发规范，输出规范文档、AI Coding Rules、Review Checklist 和 evidence。适用于部门级 engineering-standards 仓库，不用于自动修改业务代码。
---

# Project Standard Extractor

本 Skill 是单一对外入口，内部按阶段角色完成规范萃取。最终产物是团队级规范文档，不是某个项目或微服务的代码说明书。

## 何时使用

- 需要从真实代码中沉淀 APP、PC、前端、后端或行业规范。
- 需要生成 AI Coding Rules、Review Checklist、正反例和 evidence。
- 需要把多项目实践整理为团队级标准。

## 何时不要使用

- 只想解释某个项目代码。
- 只想生成行业通用最佳实践，且没有团队代码或负责人确认。
- 需要自动扫描、CLI、CI 或向量索引，本阶段不提供。
- 需要修改业务代码。

## 输入

最小输入是一个或多个 `project_paths`。其余信息按 `input-guide.md` 交互补齐：

1. 项目路径。
2. 研发域。
3. 行业场景。
4. 输出范围。
5. 子领域。
6. 业务模块。
7. 正反例候选。
8. 已有规范或文档。
9. 质量关注点。
10. 输出目标。
11. 确认声明。

## 工作流

1. Intake and Scope：确认输入、边界和敏感文件处理策略。
2. Facts and Classification：先输出代码事实，再分类为推荐、禁止、历史兼容、待确认。
3. Generation：生成团队级标准、AI Rules、Review Checklist 和 evidence。
4. Review and Quality Gate：按全局门禁评审并给出状态建议。
5. Merge Coordinator：追加写入 `draft`、evidence、合并建议、冲突和待确认文件。

完整说明见 `workflow.md`。阶段角色契约见 `agents/`。输出模板见 `templates/`。

## 强制边界

1. 规则正文不得包含具体项目路径；路径只能进入 `evidence/`。
2. 没有真实 evidence 或负责人确认的内容不得进入 AI 可执行 `draft`。
3. 不得覆盖已有 `active` 或 `draft`。
4. P0 / FORBIDDEN 必须有 evidence 和 Review 检查项。
5. 敏感配置、密钥、token、生产凭据只记录脱敏存在事实。
6. `active` 只能由领域负责人确认，Skill 不自动发布。

## 输出

根据 `config/output-targets.md` 写入：

- `overview.md`
- `standard.md`
- `ai-rules.md`
- `review-checklist.md`
- `pending-confirmation.md`
- `merge-suggestions.md`
- `conflicts.md`
- `evidence/code-facts.md`
- `evidence/positive-examples.md`
- `evidence/forbidden-examples.md`
- `evidence/legacy-compatible.md`

## 最小验收

一次有效运行必须证明：

1. `SKILL.md` 是唯一入口。
2. 所有生成规则都能追溯到 `code-facts` 或负责人确认。
3. Quality Gate 给出状态建议。
4. Merge Coordinator 不覆盖已有规则。
5. 高风险 draft 在 AI 使用路径里有提示。
