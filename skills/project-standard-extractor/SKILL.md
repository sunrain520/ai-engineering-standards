---
name: project-standard-extractor
description: "从真实项目代码路径中一步萃取可使用的团队级研发规范；稳定路径先做 profile-first，再自动按 ordered_batch_queue 逐个执行单 batch，生成 evidence-backed standard、ai-rules、review-checklist、pending/conflicts、lineage 和 review-summary。Use when: user provides project_paths and asks to extract/generate engineering standards, coding conventions, AI rules, or review checklists from an existing codebase. Do not trigger for: code review, single-file explanation, business code edits, generic best-practice docs without code, or querying existing standards."
x-external-evals-root: docs/evals/project-standard-extractor/
---

# Project Standard Extractor

## Purpose

本 Skill 从存量代码反向萃取团队研发规范，供后续 AI 编码与人工 review 复用。公开入口默认是 full-auto：用户只提供 `project_paths` 时，内部完成 profile-first、两档 batch queue、逐 batch worker、质量门禁、append-only merge、产物契约校验和 review summary。Phase 2 维度框架和 force-rebuild 系列仍是 repair-only。

## When To Use

- 用户提供一个或多个本地 `project_paths`，并要求从真实代码萃取工程规范、编码约定、AI rules 或 review checklist。
- 用户已经拿到 batch plan，并提供单个 `selected_batch.batch_id` 要继续诊断或重跑某个 batch。
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
output_dir: ""                # 可选，默认 engineering-standards/{domain}/；{domain} 格式由 intake-and-scope 推断；如目标仓库已有带数字前缀目录（如 04-backend/），自动匹配已有目录；否则使用无前缀形式（如 backend/）
extraction_mode: ""           # 可选；full-auto（默认）| profile-first | batch-extraction | focused-module | diff（需 git 仓库 + 单仓，需提供 diff_baseline.ref）| review-only | merge-only | full（Phase 2 repair-only, blocked）
selected_batch:
  batch_id: ""                # batch-extraction/diagnostic 必填；full-auto 不需要
run_mode: auto                # auto | interactive
```

调用时只要提供 `project_paths` 即可进入 `full-auto`。`profile-first` 和 `batch-extraction` 保留为诊断/聚焦路径，不再是 broad input 的默认停点。不得通过本入口传入 `output_action`、`domain`、`restore_from`、`keep` 或 `full`。

## Workflow

稳定公开路径：

1. **Intake**：校验路径、排除敏感文件、推断 domain / sub_domain；完整仓库、多服务或未知范围强制进入 `profile-first`。
2. **Profile first**：只做轻量画像，输出 project profile、extraction map、batch plan、ordered batch queue 和 coverage blind-spots；不把画像直接升级为规则。
3. **Full-auto loop**：orchestrator 按 queue 串行调用单 batch worker；每次 worker 仍只消费一个 `batch_id` 的 candidate files。
4. **Per-batch generation**：ready batch 可产出 high-confidence 规则；pending-confirmation batch 可产出 low-confidence draft 并隔离到 `pending-confirmation.md`；skipped/blocked 只进入 coverage report。
5. **Quality and merge**：phase1 不要求也不生成 `activation-report`；review 只跑 content/structure/runtime gate，merge 按 `target_state` append-only 写入 standard、derived views、lineage、owner queue 和候选索引。
6. **Review handoff**：通过高置信自动升级闸的规则可标 `auto-active` 并进入 AI/Review 默认执行；未过闸、冲突、legacy、rejected 或 low-confidence 内容不得进入默认执行。owner 保留事后否决/降级权。

Phase 2 `dimension-activator`、cross-project、EA-Doc、securities PoC 和 force-rebuild runtime 仍保持 `blocked / repair-only`，普通萃取不得读取这些管道。

## Outputs

- `project-profile.md`：项目画像和范围判断，不是团队规范。
- `extraction-map.md`：domain / sub_domain / module / task_type 到候选 evidence 的映射。
- `batch-plan.md`：ordered batch queue、可执行/不可执行 batch 列表、候选文件、排除路径、coverage blind-spots 和 stop conditions。
- `standard-{sub_domain}.md`：full-auto 或 selected batch 后生成的开发规范。
- `ai-rules.md`：从 standard 派生的 AI 编码约束，不新增独立规则。
- `review-checklist.md`：从 standard 派生的 review 检查项。
- `pending-confirmation.md` / `merge-suggestions.md` / `conflicts.md`：证据不足、相近规则或冲突规则的处理结果。
- `lineage-ledger.json` / `owner-decision-queue.json`：auto-active provenance、撤销链、owner 事后裁定队列。

## Safety Boundaries

- 不读取敏感配置、生产凭据或认证材料的原文；只记录脱敏存在事实。
- 规则正文不写真实项目绝对路径；路径只允许出现在 evidence 文件中。
- 没有代码 evidence、未过高置信闸或负责人确认缺失的高风险内容不得写成 AI 默认执行规则。
- 自动运行不得发布 `owner-confirmed-active`；只有通过 BR-016/BR-017 护栏的规则可标 `auto-active`，并必须记录撤销链。
（BR-016 核心条件：deterministic_occurrence_count >= 2 + confidence: high + 多角色 evidence + 无未裁定 conflict + 未命中反范式黑名单；BR-017：security/auth/payment 等高风险域强制 pending，完整条件见 references/agents/review-and-quality-gate.md）
- 不覆盖已有 active 或 draft；相近写 merge suggestions，冲突写 conflicts。
- 本入口不执行 destructive IO，不调用 maintainer backup / restore 脚本。

## Failure Modes

| 失败模式 | 触发 | 处理 |
| --- | --- | --- |
| `NO_VALID_PROJECT_PATHS` | 无可读项目路径 | 停止，要求重新提供路径 |
| `ALL_PATHS_SENSITIVE` / `SENSITIVE_FILE_BLOCKED` | 继续萃取必须读取敏感内容 | 停止，只记录脱敏存在事实 |
| `BROAD_INPUT_REQUIRES_PROFILE` | 完整仓库或多服务请求直接出规则 | 强制 profile-first |
| `BATCH_NOT_SELECTED` | batch-extraction/diagnostic 未提供单个 batch | 停止，要求选择一个 ready 或 pending-confirmation batch |
| `NO_REPRESENTATIVE_EVIDENCE` | selected batch 没有代表性 evidence | 只写 pending-confirmation / review summary |
| `TARGET_CONFLICT` | 候选规则与 active 规则冲突 | 写 conflicts，不覆盖旧规则 |
| `AUTO_ACTIVE_GATE_FAILED` | 规则未满足 BR-016/BR-017 护栏 | 降级 draft/pending，移出 AI 默认执行路径 |
| `ALL_BATCHES_NON_EXECUTABLE` | profile 识别范围内 batch 全部 skipped/blocked | 只输出 coverage report 和 blind-spots，不伪造规则 |

## Maintainer References

- 完整 workflow、Phase 2 blocked 状态和 repair-only 说明：`references/workflow.md`
- 阶段契约：`references/agents/{stage}.md`
- 生成格式与骨架：`assets/standard-template.md`、`assets/skeletons/`、`references/agents/generation.md`
- 质量门禁：`references/quality-gate.md`
- 公开入口 evals：`evals/`（package-local smoke subset）
- 外部 evals：`docs/evals/project-standard-extractor/`（完整 source-of-truth）
- Maintainer 工具：`tools/maintainer/project-standard-extractor/README.md`（仓库根路径，不进入 skill 包）
