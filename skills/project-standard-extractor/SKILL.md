---
name: project-standard-extractor
description: "从真实项目代码路径中萃取团队级研发规范；稳定路径先生成 project-profile、extraction-map、batch-plan，用户选择单个 batch 后生成 evidence-backed draft standard-{sub_domain}.md、ai-rules.md、review-checklist.md。Use when: user provides project_paths and asks to extract/generate engineering standards, coding conventions, AI rules, or review checklists from an existing codebase. Do not trigger for: code review, single-file explanation, business code edits, generic best-practice docs without code, or querying existing standards."
x-external-evals-root: docs/evals/project-standard-extractor/
---

# Project Standard Extractor

## Purpose

本 Skill 从存量代码反向萃取团队研发规范，供后续 AI 编码与人工 review 复用。公开入口只描述稳定萃取路径；Phase 2 维度框架和 force-rebuild 系列仍是 repair-only。

## When To Use

- 用户提供一个或多个本地 `project_paths`，并要求从真实代码萃取工程规范、编码约定、AI rules 或 review checklist。
- 用户已经拿到 batch plan，并提供单个 `selected_batch.batch_id` 要继续生成 draft 规范。
- 用户提供聚焦模块路径，希望从该模块 evidence 中提炼可复用的团队约束。

## When Not To Use

- 代码评审、PR 审查、单文件解释、bug 修复或直接修改业务代码。
- 不看代码只生成行业通用最佳实践。
- 查询、解释或消费已有规范文档。
- 维护者执行 `force-rebuild` / `restore` / `pin` / `unpin` / `list`；这些属于仓库 maintainer 工具，不是公开 skill 触发面。

## Inputs

```yaml
project_paths:                # 必填，至少 1 个本地可读路径
  - /path/to/project-a
output_dir: ""                # 可选，默认 engineering-standards/{domain}/
extraction_mode: ""           # 可选；profile-first | batch-extraction | focused-module
selected_batch:
  batch_id: ""                # batch-extraction 必填；一次只允许 1 个 batch
run_mode: auto                # auto | interactive
```

调用时只要提供 `project_paths` 即可进入 `profile-first`。不得通过本入口传入 `output_action`、`domain`、`restore_from`、`keep` 或 `full`。

## Workflow

稳定公开路径：

1. **Intake**：校验路径、排除敏感文件、推断 domain / sub_domain；完整仓库、多服务或未知范围强制进入 `profile-first`。
2. **Profile first**：只做轻量画像，输出 project profile、extraction map、batch plan；未选择 batch 时在这里停止。
3. **Selected batch**：用户选择单个 ready batch 后，读取该 batch 的 candidate files，生成 code facts 和 classification。
4. **Generation**：走 `generation_profile: phase1-selected-batch`，只基于本 batch evidence 生成 draft standard、ai-rules、review-checklist 和 review summary。
5. **Review handoff**：所有新规则保持 `status: draft`；需要负责人确认后才能升级为 `active`。

Phase 2 `dimension-activator`、cross-project、EA-Doc、securities PoC 和 force-rebuild runtime 仍保持 `blocked / repair-only`，普通萃取不得读取这些管道。

## Outputs

- `project-profile.md`：项目画像和范围判断，不是团队规范。
- `extraction-map.md`：domain / sub_domain / module / task_type 到候选 evidence 的映射。
- `batch-plan.md`：可执行 batch 列表、候选文件、排除路径和 stop conditions。
- `standard-{sub_domain}.md`：选择 batch 后生成的 draft 开发规范。
- `ai-rules.md`：从 standard 派生的 AI 编码约束，不新增独立规则。
- `review-checklist.md`：从 standard 派生的 review 检查项。
- `pending-confirmation.md` / `merge-suggestions.md` / `conflicts.md`：证据不足、相近规则或冲突规则的处理结果。

## Safety Boundaries

- 不读取敏感配置、生产凭据或认证材料的原文；只记录脱敏存在事实。
- 规则正文不写真实项目绝对路径；路径只允许出现在 evidence 文件中。
- 没有代码 evidence 或负责人确认的内容不得写成 AI 可执行强制规则。
- 自动运行只输出 draft，不发布 active。
- 不覆盖已有 active 或 draft；相近写 merge suggestions，冲突写 conflicts。
- 本入口不执行 destructive IO，不调用 maintainer backup / restore 脚本。

## Failure Modes

| 失败模式 | 触发 | 处理 |
| --- | --- | --- |
| `NO_VALID_PROJECT_PATHS` | 无可读项目路径 | 停止，要求重新提供路径 |
| `ALL_PATHS_SENSITIVE` / `SENSITIVE_FILE_BLOCKED` | 继续萃取必须读取敏感内容 | 停止，只记录脱敏存在事实 |
| `BROAD_INPUT_REQUIRES_PROFILE` | 完整仓库或多服务请求直接出规则 | 强制 profile-first |
| `BATCH_NOT_SELECTED` | batch-extraction 未提供单个 batch | 停止，要求选择一个 ready batch |
| `NO_REPRESENTATIVE_EVIDENCE` | selected batch 没有代表性 evidence | 只写 pending-confirmation / review summary |
| `TARGET_CONFLICT` | 候选规则与 active 规则冲突 | 写 conflicts，不覆盖旧规则 |

## Maintainer References

- 完整 workflow、Phase 2 blocked 状态和 repair-only 说明：`references/workflow.md`
- 阶段契约：`references/agents/{stage}.md`
- 生成格式与骨架：`assets/standard-template.md`、`assets/skeletons/`、`references/agents/generation.md`
- 质量门禁：`references/quality-gate.md`
- 公开入口 evals：`evals/`（package-local smoke subset）
- 外部 evals：`docs/evals/project-standard-extractor/`（完整 source-of-truth）
- Maintainer 工具：`tools/maintainer/project-standard-extractor/README.md`（仓库根路径，不进入 skill 包）
