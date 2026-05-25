---
name: project-standard-extractor
description: 从真实项目代码路径中萃取团队级研发规范，输出 standard-{sub_domain}.md、ai-rules.md、review-checklist.md 等可复用文档。Use when: user provides project_paths and asks to extract/generate engineering standards, coding conventions, AI rules, or review checklists from an existing codebase. Do not trigger for: code review, single-file explanation, or querying existing standards.
---

# Project Standard Extractor

本 Skill 是 Spec-Driven Development 的源头工具：从存量代码反向还原结构化团队规范，供 AI 后续编码时复用。本文件只保留入口协议、硬边界和导航；细节按需读取 `references/`。

## Phase 2 Status: BLOCKED

Phase 2 Dimension Framework 当前处于 `blocked / repair-in-progress`。在 `activation-report.v1`、baseline-only generation、主 workflow handoff 和 final eval 全部通过前，以下路径不得作为可运行能力执行或宣传：

- Phase 2 default append / `extraction_mode=full`
- 跨项目 `unified-activation-map`
- EA-Doc 文档源萃取 runtime
- 证券 synthetic PoC 作为 evidence
- `force-rebuild` / `restore` / `pin` / `unpin` / `list` runtime

稳定可用路径仍是 Phase 1：`profile-first` 生成 project profile / extraction map / batch plan，随后由用户选择 batch 进入受控的 batch-extraction。

## 调用协议

```yaml
project_paths:                # 必填，至少 1 个本地可读绝对路径
  - /path/to/project-a
output_dir: ""                # 可选，默认 engineering-standards/{domain}/
extraction_mode: ""           # 可选，留空由 intake 推断；profile-first | batch-extraction | focused-module | diff | full
output_action: append         # append | force-rebuild | restore | pin | unpin | list；非 append 目前均为 blocked/design-only
selected_batch:
  batch_id: ""                # 仅 batch-extraction 模式必填
domain: ""                    # output_action ∈ {force-rebuild, restore, pin, unpin, list} 必填
restore_from: ""              # output_action ∈ {restore, pin, unpin} 必填，UTC-ts(YYYYMMDDTHHMMSSZ)
keep: 10                      # force-rebuild 的 --keep=N 自动清理阈值
run_mode: auto                # auto | interactive；force-rebuild 强制 interactive
```

调用时只要提供 `project_paths`，其余字段由 `references/agents/intake-and-scope.md` 推断。

**互斥规则**：

- R91：`output_action != append` 与 `extraction_mode = diff` 互斥。
- R92：`output_action != append` 与 `len(project_paths) > 1` 互斥。
- 违规抛 `INCOMPATIBLE_OUTPUT_ACTION`，intake-and-scope 做二层防御。

## 执行步骤

1. 输入校验：无可读路径抛 `NO_VALID_PROJECT_PATHS`；全部命中敏感策略抛 `ALL_PATHS_SENSITIVE`。
2. 普通调用只走 Phase 1 稳定路径：`profile-first` 生成 project profile / extraction map / batch plan；未提供 `selected_batch.batch_id` 时到此停止并提示用户选 batch。
3. 已选 batch 时进入受控 `batch-extraction`，只处理该 batch 的 evidence / draft rules / review summary；不得启动 Phase 2 `dimension-activator` 管道。
4. 仅当任务明确是 Phase 2 repair validation 时，才按 `references/workflow.md` 的 blocked 管道读取 `dimension-activator` 等契约。

```text
intake-and-scope
  -> profile-and-batch-planner
  -> stop-for-batch-selection
  -> selected-batch-only extraction
```

## 维度激活态

Phase 2 repair validation 中，`dimension-activator` 是唯一激活态权威源；下游 facts / generation / review / merge 全程透传 `activation-report`，不得本地重算。详细铁律见 `references/workflow.md#8-激活态铁律`。

| state | 触发条件 | 写入位置 | recommended_action |
| --- | --- | --- | --- |
| `baseline` | Layer 1 通用维度默认列入 | standard 或 pending-confirmation | keep-draft |
| `activated` | 信号命中且深度核验达标 | standard + evidence + ai-rules + review-checklist | promote-to-active |
| `pending-confirmation` | 信号弱命中或 weighted 未过阈值 | 仅 pending-confirmation | move-to-pending |
| `shallow` | 已激活但 evidence / depth_score 不足 | standard + ai-rules 双侧 low-coverage 标注 | keep-draft-low-coverage |
| `candidate` | 维度存在但本期未命中 | overview §9 未激活维度地图 | defer |

## 强制边界

| # | 约束 |
| --- | --- |
| 1 | 规范正文不写具体项目路径，路径只用于读取代码 evidence。 |
| 2 | 不读取密钥、token、生产凭据、`.env` 文件原值。 |
| 3 | 没有代码 evidence 的规则只能写入 `pending-confirmation.md`。 |
| 4 | 输出文档保持 `status: draft`；`active` 只能由领域负责人手动升级。 |
| 5 | 不覆盖已有 `active` 或 `draft`；相近写 `merge-suggestions.md`，冲突写 `conflicts.md`。 |
| 6 | 规则节元数据使用 inline blockquote 行，不使用整块 yaml。 |
| 7 | 激活态只由 `dimension-activator` 判定；下游重算抛 `STATE_RECOMPUTATION_FORBIDDEN`。 |
| 8 | GitNexus readiness 只消费宿主项目 `.spec-first/graph/graph-facts.json`，不可用时降级 fallback signal。 |
| 9 | `output_action ∈ {force-rebuild, restore, pin, unpin, list}` 必须显式指定 `domain`。 |
| 10 | `output_action = force-rebuild` 必须 interactive，并要求用户字面输入 `confirm <domain>`。 |

## 关键引用

| 想了解 | 看这里 |
| --- | --- |
| 完整 workflow 与状态机 | `references/workflow.md` |
| 各阶段 agent 契约 | `references/agents/{stage}.md` |
| 生成格式与骨架 | `assets/standard-template.md` + `assets/skeletons/` + `references/agents/generation.md` |
| 维度池 / 激活规则 / 信号库 | `references/config/dimension-framework/` + `references/prompts/signal-library/` |
| 质量门禁 | `references/quality-gate.md` |
| Backup / Force Rebuild / Restore | `references/agents/backup-manager.md` + `references/prompts/orchestrator/force-rebuild/` + `scripts/backup.sh` |
| Phase 1 / Phase 2 示例 | `references/examples/` |
