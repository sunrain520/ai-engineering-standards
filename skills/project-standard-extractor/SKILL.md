---
name: project-standard-extractor
description: 从一个或多个真实项目代码路径中萃取团队级研发规范，输出规范文档、AI Coding Rules、Review Checklist 和 evidence。适用于部门级 engineering-standards 仓库，不用于自动修改业务代码。
---

# Project Standard Extractor

## Purpose / 目的

本 Skill 是单一对外入口，内部按阶段角色完成规范萃取。最终产物是团队级规范文档，不是某个项目或微服务的代码说明书。

## When To Use / 何时使用

- 需要从真实代码中沉淀 APP、PC、前端、后端或行业规范。
- 需要生成 AI Coding Rules、Review Checklist、正反例和 evidence。
- 需要把多项目实践整理为团队级标准。

## When Not To Use / 何时不要使用

- 只想解释某个项目代码。
- 只想生成行业通用最佳实践，且没有团队代码或负责人确认。
- 需要自动扫描、CLI、CI 或向量索引，本阶段不提供。
- 需要修改业务代码。

## Inputs / 输入

最小输入是一个或多个 `project_paths`。其余信息按 `input-guide.md` 交互补齐：

1. 项目路径。
2. 萃取模式 `extraction_mode`。
3. 研发域。
4. 行业场景。
5. 输出范围。
6. 子领域。
7. 业务模块。
8. 选定 batch（`batch-extraction` 时必填）。
9. 正反例候选。
10. 已有规范或文档。
11. 质量关注点。
12. 输出目标。
13. 确认声明。

## Workflow / 工作流

1. Intake and Scope：确认输入、边界、`extraction_mode` 和敏感文件处理策略。
2. Project Profile：广范围输入先输出项目画像，不生成正式规范规则。
3. Extraction Map and Batch Plan：生成 extraction map 和 batch plan，由用户或调用方选择一个 batch。
4. Selected-Batch Facts and Classification：只读取选定 batch 的代表性 evidence，先输出事实，再分类为推荐、禁止、历史兼容、待确认。
5. Generation：生成团队级标准、AI Rules、Review Checklist、evidence 和候选索引产物。
6. Review and Quality Gate：按全局门禁评审并给出状态建议。
7. Merge Coordinator：追加写入 `draft`、evidence、合并建议、冲突、待确认文件和候选索引建议。

完整说明见 `workflow.md`。阶段角色契约见 `agents/`。输出模板见 `templates/`。

## 强制边界

1. 规则正文不得包含具体项目路径；路径只能进入 `evidence/`。
2. 没有真实 evidence 或负责人确认的内容不得进入 AI 可执行 `draft`。
3. 不得覆盖已有 `active` 或 `draft`。
4. P0 / FORBIDDEN 必须有 evidence 和 Review 检查项。
5. 敏感配置、密钥、token、生产凭据只记录脱敏存在事实。
6. `active` 只能由领域负责人确认，Skill 不自动发布。
7. 所有输出 Markdown 顶部必须包含 `config/frontmatter-format.md` 定义的 YAML Front Matter。
8. 规则不使用 Rule ID 或 HTML anchor;规则 H2 必须以 `P0 / P1 / P2 / FORBIDDEN ` 前缀开头,跨文档引用统一为 `{source_doc}「{section_title}」` 二元组。
9. evidence 默认按 `sub_domain` 拆分,每个 sub_domain 各有一组 4 文件;跨 sub_domain 共性事实使用 `sub_domain: "common"` 的 evidence 文件,需在评审报告中显式记录。
10. 完整项目、完整仓库、多服务、未知域或广范围输入默认只能进入 `profile-first`，不得一次性读取完整代码或直接生成 `standard.md`。
11. 正式萃取必须限定到一个 batch；后续阶段优先读取 `project-profile`、`extraction-map`、`batch-plan` 和 `code-facts` 摘要，不跨阶段携带完整源码。

## Outputs / 输出

根据 `config/output-targets.md` 写入：

- `overview.md`
- `{run_id}-project-profile.md`
- `{run_id}-extraction-map.md`
- `{run_id}-batch-plan.md`
- `standard.md`
- `ai-rules.md`
- `review-checklist.md`
- `pending-confirmation.md`
- `merge-suggestions.md`
- `conflicts.md`
- `examples/README.md`
- `evidence/README.md`
- `evidence/code-facts.md`
- `evidence/positive-examples.md`
- `evidence/forbidden-examples.md`
- `evidence/legacy-compatible.md`
- `{run_id}-ai-context-pack.md`（候选）
- `{run_id}-rules-index-candidate.json`（候选）
- `{run_id}-llms-candidate.txt`（候选）

所有输出文档必须使用 `index_format: engineering-standards-md-v1`，并按 `doc_id`、`domain`、`sub_domain`、`doc_type`、`tags` 支持快速索引。

## Failure Modes / 失败模式

| 失败模式 | 触发条件 | 处理方式 |
| --- | --- | --- |
| `NO_VALID_PROJECT_PATHS` | `project_paths` 为空、不可读或都不在允许范围内 | 停止萃取，请用户重新提供路径 |
| `INSUFFICIENT_EVIDENCE` | 只有单点事实、行业共性或模板建议，无法支撑团队级规则 | 写入 `pending-confirmation.md`，不得进入 AI 默认执行路径 |
| `SENSITIVE_FILE_BLOCKED` | 命中敏感配置、凭据文件或生产环境敏感字段 | 只记录脱敏存在事实，不读取、不复制原值 |
| `BROAD_INPUT_REQUIRES_PROFILE` | 输入是完整仓库、多服务、未知域或广范围路径，但请求直接萃取规则 | 只运行 `profile-first`，输出 project profile、extraction map 和 batch plan |
| `BATCH_NOT_SELECTED` | 请求正式萃取但没有选定 batch | 停止生成规则，要求选择 batch 或补充 focused module |
| `NO_REPRESENTATIVE_EVIDENCE` | 选定 batch 没有代表性文件候选或证据不足 | 标记为 skipped / pending-confirmation，不生成 AI 可执行规则 |
| `TARGET_CONFLICT` | 新候选规则与已有 `active` / `draft` 或多项目事实冲突 | 写入 `conflicts.md` 或 `merge-suggestions.md`，不得覆盖旧内容 |
| `OWNER_CONFIRMATION_MISSING` | 高风险规则、行业规则或 `active` 升级缺少负责人确认 | 保持 `draft` 或 `pending-confirmation`，只输出确认项 |

## 最小验收

一次有效运行必须证明：

1. `SKILL.md` 是唯一入口。
2. 所有生成规则都能追溯到 `code-facts` 或负责人确认。
3. 广范围输入已经先输出 project profile、extraction map 和 batch plan，且没有直接生成正式规则。
4. 正式萃取只处理一个选定 batch，且记录读取文件候选、排除范围、规则数量上限和 evidence 数量上限。
5. Quality Gate 给出状态建议。
6. Merge Coordinator 不覆盖已有规则。
7. 高风险 draft 在 AI 使用路径里有提示。
