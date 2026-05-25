---
date: 2026-05-25
reviewed_at: 2026-05-25 01:31:54
last_reviewed_at: 2026-05-25 03:31:42
reviewer: Codex
second_pass_at: 2026-05-25 04:30:00
second_pass_reviewer: Opus 4.7
third_pass_at: 2026-05-25 12:44:53
third_pass_reviewer: Codex
mode: report-only
plan: docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md
requirements: docs/brainstorms/2026-05-24-001-project-standard-extractor-dimension-framework-requirements.md
scope: Phase 2 Dimension Framework
completed_units_reviewed:
  - U1
  - U2
  - U3
  - U4
  - U5
  - U6
  - U7
  - U8
  - U9
  - U10
  - U11
  - U12
  - U13
  - U14
  - U15
  - U16
  - U17
  - U18
  - U19
  - U20
  - U21
  - U22
  - U23
  - U24
  - U25
  - U26
  - U27
status: final-review-complete
second_pass_status: confirmed-with-additions
third_pass_status: action-plan-updated
phase2_runtime_status: blocked
release_recommendation: hold-with-tiered-cleanup
p0_blockers:
  - N-01-generation-activation-report-interface-break
  - N-02-baseline-default-content-missing
critical_blockers:
  - N-01-generation-activation-report-interface-break
  - N-02-baseline-default-content-missing
  - N-03-schema-version-drift
  - F2-activation-report-contract
  - F3-workflow-handoff-order
  - F4-baseline-default-content-missing
  - F1-config-schema-cannot-load
blocked_capabilities:
  - phase2-default-append-pipeline
  - cross-project-unified-activation-map
  - ea-doc-dimension-group
  - securities-poc-as-evidence
---

# Phase 2 Dimension Framework 代码审查报告

## 监听状态

截至 2026-05-25 03:31:42，计划文档中 U1-U27 已全部标记 `Status: ✅ 已完成`，本报告已覆盖全部完成单元并完成最终全量复审。第一轮覆盖 U1-U8；第二轮覆盖新增完成的 U9-U14；第三轮覆盖新增完成的 U15-U16；第四轮覆盖新增完成的 U17；第五轮覆盖新增完成的 U23；第六轮覆盖新增完成的 U24；第七轮覆盖新增完成的 U25；第八轮覆盖新增完成的 U26；第九轮覆盖新增完成的 U18；第十轮覆盖新增完成的 U19；第十一轮覆盖新增完成的 U20-U21；第十二轮覆盖新增完成的 U22；第十三轮覆盖新增完成的 U27。此前 01:44:28 的范围修正记录保留为历史说明，当前有效审查范围以本节和 frontmatter 为准。

## 已审范围

- U1 维度池配置与 schema
- U2 激活信号库 prompt 模板
- U3 激活规则配置
- U4 文件骨架模板池
- U5 新增 dimension-activator agent
- U6 改造 facts-and-classification agent
- U7 改造 profile-and-batch-planner agent
- U8 重构 generation agent 为端 adapter
- U9 改造 review-and-quality-gate agent
- U10 改造 merge-coordinator agent
- U11 workflow.md 阶段图与流程更新
- U12 SKILL.md 路由决策与三态对外说明
- U13 GitNexus 集成 readiness 检测与查询封装
- U14 增量模式 Diff Scoper agent + intake 扩展
- U15 跨项目对比 Cross-Project Aggregator agent + planner 扩展
- U16 quality-gate.md 双门禁汇总文档
- U17 维度激活报告输出与持久化
- U18 证券子领域 PoC 端到端跑通
- U19 evals 套件扩展：维度框架场景
- U20 examples 扩展：phase 2 walkthrough
- U21 文档与 CHANGELOG 全面更新
- U22 集成验证 + smoke test
- U23 Backup Manager agent + helper script
- U24 Force Rebuild 重生流程对接 + atomic rollback + CHANGELOG helper
- U25 Force Rebuild 文档 + evals + walkthrough
- U26 Pin / Unpin 子命令 + manifest schema 扩展
- U27 EA-Doc 维度组：文档源萃取

## 第一轮 Findings（U1-U8）

### P1. U1 没有满足 AE7 / R48 的 13 个 Layer 1 通用维度

`docs/brainstorms/2026-05-24-001-project-standard-extractor-dimension-framework-requirements.md:118` 要求 Layer 1 通用维度至少覆盖 D01-D13 共 13 项；`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:520` 的 U1 测试场景也要求 KMP App 加载后维度池总数 >= 8 + 13。

当前 `skills/project-standard-extractor/config/dimension-framework/baseline-dimensions.yaml:10` 只有 6 个 baseline 维度：D01、D02、D06、D09、D11、D12；`skills/project-standard-extractor/config/dimension-framework/schema.json:82` 到 `:95` 也只强制这 6 个 key。结果是 U1 的 schema 校验会放过缺失 D03/D04/D05/D07/D08/D10/D13 的配置，后续 batch-plan 不可能稳定产出 13 个 Layer 1 维度。

建议修复：把 R48 的 13 个 Layer 1 维度作为 common dimension pool 全量落地，并让 schema 的 common 层强制这 13 个 key；如果只想保留 6 个 baseline，则需要把 “Layer 1 全量维度” 与 “baseline_dimensions 最小 6 项” 拆成两个明确配置，而不是让 U1/AE7 指向同一个不完整池。

### P1. U5 / U6 的数据流方向与计划和验收目标相反

计划高层设计 `docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:176` 到 `:181` 定义 `facts-and-classification` 输出 `signal_hits`，再由 `dimension-activator` 消费；U5 goal 也写明 activator 消费 `signal_hits`，U6 goal 写明 facts 额外产出 `signal_hits`。

当前实现把顺序反过来了：`skills/project-standard-extractor/agents/dimension-activator.md:5` 到 `:7` 声明 activator 在 profile 后、facts 前，并自己执行 U2 信号库；`skills/project-standard-extractor/agents/facts-and-classification.md:7` 到 `:20` 则把 `activation_report` 作为输入消费。这样 U6 “输出 signal_hits 供 dimension-activator 消费”的完成声明没有落地，且 pipeline 中 `signal_hits` 这个计划契约被移除。

建议修复：二选一收敛。若按原计划，恢复 `facts-and-classification -> signal_hits -> dimension-activator`；若按当前实现，正式修订 plan 的高层设计、U5/U6 goal、test scenarios 和 verification，并移除 “signal_hits 由 facts 输出” 的验收口径。

### P1. baseline 无 evidence 的 pending / owner 确认门禁被绕过

需求 `docs/brainstorms/2026-05-24-001-project-standard-extractor-dimension-framework-requirements.md:135` 到 `:138` 要求 baseline 无 evidence 时必须输出 pending 标记，且不得直接进入 draft，必须由端负责人确认。计划 U8 也要求 baseline 无 evidence 时章节标 `[pending]` 并写候选 evidence 信号清单：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:820` 到 `:821`。

当前实现不形成这条门禁链路：`skills/project-standard-extractor/agents/dimension-activator.md:192` 写 baseline 维度直接 `state = baseline`；`skills/project-standard-extractor/agents/facts-and-classification.md:31` 到 `:35` 规定 baseline 跳过萃取；`skills/project-standard-extractor/agents/dimension-activator.md:259` 到 `:262` 也明确 baseline 不做 facts 萃取。随后 `skills/project-standard-extractor/agents/generation.md:36` 和 `:331` 到 `:335` 又要求 baseline 从 yaml default 内容直接渲染，但当前 `baseline-dimensions.yaml` 只有 concerns/check_items，没有 default 规则内容或候选 evidence 清单 schema。

结果是 baseline 无 evidence 不会落 pending，也不会进入 owner 确认；generation 还可能按不存在的 default 内容生成看似完整的 baseline 章节。

建议修复：baseline 维度必须区分 `baseline_with_evidence` 与 `baseline_pending`，或直接在 activation-report 中把无 evidence baseline 标为 `pending-confirmation` / `pending`；同时补齐 baseline 默认内容 schema，避免 generation 引用不存在的 default 字段。

### P1. U7 没有同步 batch-plan 模板，按模板生成的产物缺少维度字段

U7 文件清单要求修改 `skills/project-standard-extractor/templates/batch-plan-template.md` 并增加 dimensions 字段：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:773` 到 `:790`。当前 agent 文档已要求每个 batch 写入 `candidate_dimension_ids` 和 `expected_skeleton_section`：`skills/project-standard-extractor/agents/profile-and-batch-planner.md:109`、`:216` 到 `:231`。

但模板 `skills/project-standard-extractor/templates/batch-plan-template.md:28` 到 `:49` 仍是旧结构，只有 `batch_id/domain/sub_domain/module/task_type/candidate_files/excluded_paths/evidence_limit/rule_limit/stop_conditions/status`，没有 `dimensions`、`candidate_dimension_ids`、`expected_skeleton_section`。按模板生成 batch-plan 时，下游 activator / facts 无法拿到 U7 承诺的维度搜索域提示。

另外，planner 的 Step 5.5 使用 `evidence_hints[]` 做粗匹配：`skills/project-standard-extractor/agents/profile-and-batch-planner.md:226`，但 U1 schema 和 fixture 字段实际是 `activation_signal_hints`，例如 `skills/project-standard-extractor/config/dimension-framework/schema.json:62` 到 `:65`。这会让候选维度预测规则引用不存在的字段。

建议修复：同步更新 batch-plan-template，并把 `evidence_hints[]` 改为已有的 `activation_signal_hints[]`，或在 schema/fixtures 中正式新增 `evidence_hints`。

### P1. U5 要求的 activation-report schema 文件缺失，U8 已经依赖它

U5 文件清单明确新增 `skills/project-standard-extractor/config/dimension-framework/activation-report-schema.json`：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:685` 到 `:688`，U5 测试场景也要求输出通过该 schema 校验：`:724`。当前文件不存在。

缺失影响已经扩散到 U8：`skills/project-standard-extractor/agents/generation.md:17` 到 `:19` 要求输入 `activation_report` schema 为 `activation-report.v1`，`skills/project-standard-extractor/agents/generation.md:62` 到 `:66` 的 A0 loader 也要求校验 activation-report schema。没有 schema 文件时，U5/U8 的关键校验只能停留在 prompt 文本，无法形成可复用的确定性契约。

建议修复：在 U5 或当前最早可用节点补齐 `activation-report-schema.json`，并让 dimension-activator / generation / review / merge 统一引用同一路径。

### P2. U8 要求的 orchestrator prompt 文件缺失

U8 文件清单要求新增：

- `skills/project-standard-extractor/prompts/orchestrator/end-adapter-dispatch.md`
- `skills/project-standard-extractor/prompts/orchestrator/activation-map-passing.md`

证据见 `docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:804` 到 `:807`。当前 `skills/project-standard-extractor/prompts/orchestrator/` 下没有这两个文件。虽然 `agents/generation.md` 内部已经写了 activation-report 消费逻辑，但计划要求的端分发与激活 map 传递规约没有落地，后续 orchestrator / workflow 文档无法引用稳定契约。

建议修复：补齐两个 prompt 文件，或把计划中这两个文件从 U8 明确移除并把 generation.md 设为唯一权威来源。

## 验证记录

- `ruby -e 'require "yaml"; ...' skills/project-standard-extractor/config/dimension-framework/*.yaml`：通过，所有 YAML 可解析。
- `ruby -e 'require "json"; ...' skills/project-standard-extractor/config/dimension-framework/*.json`：通过，现有 JSON 可解析。
- 缺失文件检查：`activation-report-schema.json`、`end-adapter-dispatch.md`、`activation-map-passing.md` 均缺失。
- 未运行项目测试：本轮为 report-only 审查，且仓库没有发现常规 `package.json` / `pyproject.toml` 等统一测试入口。

## 范围修正记录

- 2026-05-25 01:44:28：根据用户确认，当前实际开发只到 U8。此前针对 U9-U13 的第二轮、第三轮审查结论从有效 Findings 中撤回；后续仅在 U9+ 明确开发完成后重新审查，不把未完成任务当作缺陷。

## 第二轮 Findings（U9-U14）

### P1. U9 的外部门禁入口仍是旧契约，双门禁没有真正对外落地

U9 文件清单要求同步修改 `skills/project-standard-extractor/quality-gate.md` 与 `skills/project-standard-extractor/prompts/quality-review.md`，并增加双门禁说明。当前 `agents/review-and-quality-gate.md` 已包含 P8 Coverage Reviewer、Gate A/B、`dimension_id`、`dimension_state`、`coverage_result`、`override_rationale` 等字段。

但 `skills/project-standard-extractor/quality-gate.md:11` 到 `:15` 仍写“运行七个分面 reviewer”，输出 schema `:34` 到 `:49` 仍缺 `dimension_id`、`dimension_state`、Gate A/B outcome、`coverage_result`、`override_rationale`。`skills/project-standard-extractor/prompts/quality-review.md:26` 到 `:45` 仍是旧 `quality_gate_decision`，`confidence` 还写基于 7 persona，且没有 activation-report 字段。

影响：调用方如果按这两个外部入口执行，仍会产出 Phase 1 的旧门禁结果；merge-coordinator 期望的 U9/U10 字段拿不到，双门禁会被绕过。

建议修复：把 `quality-gate.md` 和 `prompts/quality-review.md` 同步到 8 persona + Gate A/B schema；这两个文件不能只保留旧适配说明。

### P1. U9/U12 的 `recommended_action` 枚举漂移，会导致机器校验互相打架

`skills/project-standard-extractor/config/frontmatter-format.md:130` 到 `:140` 仍只有 7 个旧枚举，没有 `keep-draft-low-coverage`。但 `agents/review-and-quality-gate.md`、`merge-coordinator.md` 和 `SKILL.md` 已使用新值或变体。

具体冲突包括：`skills/project-standard-extractor/SKILL.md:85` 使用 `submit-for-active-review / merge-suggestion`，`:87` 使用 `keep-draft + low-coverage`，`:88` 使用 `none`；这些都不在 §4.7 枚举内。`skills/project-standard-extractor/agents/merge-coordinator.md:176` 同时接受 `keep-draft + low-coverage` 与 `keep-draft-low-coverage` 两种拼写，`:186` 又把 shallow 路由绑定到 `keep-draft-low-coverage`。

影响：Quality Gate、Front Matter、SKILL 对外说明、merge-coordinator 强校验对同一状态使用不同字符串，后续 schema 校验和路由判断会误报或漏报。

建议修复：统一一个权威枚举。若接受 `keep-draft-low-coverage`，就加入 `frontmatter-format.md §4.7` 并替换所有 `keep-draft + low-coverage` / `none` / `submit-for-active-review` / `merge-suggestion`；否则用独立字段表达 low coverage，不要扩展 `recommended_action`。

### P1. U10 声明的 activation report 持久化链路仍缺关键文件和写入步骤

U10 要求新增 `skills/project-standard-extractor/prompts/orchestrator/candidate-aggregation.md`，并把完整激活报告写入 `engineering-standards/{domain}/evidence/dimension-activation-report.json`。当前该 prompt 文件不存在；同时 U5 要求的 `config/dimension-framework/activation-report-schema.json` 仍不存在。

`skills/project-standard-extractor/agents/merge-coordinator.md:99` 只在 `merge_summary.activation_report_ref` 中透传 `temp/{run_id}-activation-report.json`，`:167` 到 `:176` 只读取和校验输入 report，未定义把 report 复制 / 规范化写入 `evidence/dimension-activation-report.json` 的步骤。`skills/project-standard-extractor/agents/diff-scoper.md:99` 和 `:206` 已经依赖 `evidence/dimension-activation-report.json.last_commit`，但 U10 没有建立这个持久文件。

影响：U14 的默认 baseline 推断会长期找不到 `last_commit`，增量模式会退回 merge-base 或全量；U17/Phase F 后续也缺稳定输入。

建议修复：补 `candidate-aggregation.md` 和 `activation-report-schema.json`；在 merge-coordinator 增加明确持久化步骤，写入 `{target_domain_dir}/evidence/dimension-activation-report.json`，包含 `last_commit`、schema 校验结果和 run metadata。

### P1. U11 workflow.md 固化的数据流仍与计划目标相反

U11 目标要求把 Dimension Activator 插入到 `facts-and-classification` 之后、`generation` 之前，并消费 `signal_hits + activation_rules`。当前 `skills/project-standard-extractor/workflow.md:40` 到 `:55` 把 `dimension-activator` 放在 profile/planner 后、batch loop 前；`:41` 到 `:44` 还要求它自己执行 5 类 signal。

这与第一轮已发现的 U5/U6 数据流倒置相同：计划契约是 `facts-and-classification -> signal_hits -> dimension-activator -> generation`，实际文档固化为 `profile-and-batch-planner -> dimension-activator -> facts-and-classification`。

影响：按 workflow 执行时，facts 阶段不会产出 `signal_hits` 给 activator；后续所有下游都围绕一个与计划不同的 activation-report 契约运行。

建议修复：要么按计划恢复 `facts-and-classification -> signal_hits -> dimension-activator`，要么正式修订计划中的高层设计、U5/U6/U11 目标与验收，不要让计划和实现同时作为权威。

### P2. U12 usage-guide 仍是 Phase 1 用法，没有说明如何读 activation report

U12 测试场景要求 `usage-guide.md` 含“如何读 dimension-activation-report.json”段落。当前 `skills/project-standard-extractor/usage-guide.md` 中没有 `dimension-activation-report` 或 activation report 阅读说明。

同一文件仍保留 Phase 1 逐 batch 口径：`:33` 到 `:36` 建议先 `profile-first` 再 `batch-extraction`；`:112` 到 `:114` 明确写“不会一次处理多个 batch”。这与 `workflow.md` 当前 auto 模式遍历 `ordered_batch_queue` 的描述冲突。

影响：用户指南没有教用户读取 Phase 2 的核心 artifact，也会误导用户认为新版仍必须手动逐 batch 运行。

建议修复：增加三态产物使用章节，覆盖 `temp/{run_id}-activation-report.json`、overview §9、pending/shallow/candidate 的处理方式；同时更新“不会一次处理多个 batch”的旧边界。

### P1. U13 readiness-check 少了 `query_global_graph` 与 `worktree_status_hash` 校验，且 mtime 条件写反

U13 要求 readiness 读取 `.spec-first/graph/graph-facts.json` 并确认 `capabilities.query_global_graph: true`，还要求 `worktree_status_hash` 与当前 git 状态匹配。当前 `skills/project-standard-extractor/prompts/gitnexus/readiness-check.md:49` 到 `:55` 的 available 条件只检查入口、JSON/schema、overall_status、provider query_ready、mtime 和 MCP list_repos，没有 `capabilities.query_global_graph` 或 `worktree_status_hash` 校验。

同处 `:54` 把新鲜度写成 `mtime <= now - freshness_window_days` 才通过，否则 stale。这个方向反了：14 天前以前的旧文件会通过，新生成的 graph-facts 反而会进入 `stale: mtime_exceeded`。文件自己的测试表还要求 “mtime 距今 30 天” 是 stale。

影响：GitNexus readiness 可能在能力未开启或 graph 已陈旧时误判 available，也可能把新 graph 误判 stale。

建议修复：available 条件补 `capabilities.query_global_graph == true` 和 `worktree_status_hash` 匹配；mtime 改为 `mtime >= now - freshness_window_days` 通过，`mtime < now - freshness_window_days` stale。

### P2. U13 的 gitnexus-signal 输出示例仍缺 `source: gitnexus`

R58 要求 GitNexus evidence 显式标注 `source: gitnexus`。`query-and-fallback.md` 的统一 schema 已包含 `source`，但对外 signal 文件 `skills/project-standard-extractor/prompts/signal-library/gitnexus-signal.md:60` 到 `:69` 的输出示例仍只有 `file_path / line / snippet`，没有 `source`。`prompts/signal-library/README.md` 的通用 evidence schema也只列 `file_path / line / snippet`。

影响：调用方如果只按 signal-library 的示例实现，会生成不带 source 的 GitNexus evidence，违反 R58，也无法区分 graph evidence 和 fallback evidence。

建议修复：同步更新 `gitnexus-signal.md` 示例和 signal-library README，把 graph evidence 的 `source: gitnexus` 设为必填扩展字段，fallback evidence 的 source 使用真实信号类型。

### P1. U14 diff-scoper 的 baseline 维度 ID 与维度池不一致，核心映射会被孤儿校验丢弃

`skills/project-standard-extractor/config/diff-scoper/file-to-dimension-map.yaml:18` 到 `:92` 使用短 ID：`D01`、`D02`、`D06`、`D09`、`D11`、`D12`；后续 APP/Frontend/Backend 映射中还引用 `D05`、`D08`。但当前维度池实际 baseline ID 是 `D01-architecture`、`D02-naming`、`D06-error-handling`、`D09-testing`、`D11-security`、`D12-observability`。我用 YAML 解析脚本交叉校验后，`file-to-dimension-map.yaml` 中缺失的维度 ID 为：`D01,D02,D06,D09,D11,D12,D05,D08`。

该文件自己的 resolution rule `:8` 到 `:12` 规定 dimension_id 不存在于 dimension-framework 时视为孤儿映射跳过。结果是构建、命名、日志、安全、测试、D05/D08 等核心变更都会在 U14 自检阶段被剔除或产生大量 warning，增量模式的 `affected_dimensions` 不可信。

建议修复：把 diff-scoper 映射的 baseline ID 与 U1 维度池统一；同时补齐 D05/D08 在维度池中的真实 ID，或把 U1 恢复到计划要求的 D01-D13 短 ID 体系。

### P2. U14 intake 对 diff 模式的优先级说明自相矛盾

`skills/project-standard-extractor/agents/intake-and-scope.md:69` 写 `broad_input = true` 时强制 `extraction_mode = profile-first`；但 `:89` 到 `:91` 的 Step 4 又把用户明示 `--mode=diff` 放在 `broad_input` 之前，允许 diff 优先生效。`input-guide.md:43` 到 `:46` 也同时写 broad scope 默认 `profile-first`、用户明示 diff 则进入 diff。

影响：完整仓库正是 diff 模式最常见输入，但文档同时说“强制 profile-first”和“明示 diff 优先”。不同 agent 可能按不同段落执行，导致 diff-scoper 在全仓输入下有时被跳过、有时被启用。

建议修复：把优先级写成单一规则：用户显式 diff 且满足 target_repo/git/baseline 条件时优先 diff；只有未显式 diff 的 broad scope 才强制 profile-first。同步更新 intake、input-guide 和 failure mode。

## 验证记录（第二轮）

- 已重新读取计划完成状态：U1-U14 标记 `Status: ✅ 已完成`，U15+ 尚未标记完成。
- 文件存在性检查：`quality-gate.md`、`prompts/quality-review.md`、`agents/diff-scoper.md`、`config/diff-scoper/file-to-dimension-map.yaml`、`input-guide.md` 存在；`activation-report-schema.json`、`prompts/orchestrator/candidate-aggregation.md`、`end-adapter-dispatch.md`、`activation-map-passing.md` 仍缺失。
- YAML 解析：`skills/project-standard-extractor/config/dimension-framework/*.yaml` 与 `config/diff-scoper/file-to-dimension-map.yaml` 可解析。
- 维度 ID 交叉校验：diff-scoper 映射引用的 `D01,D02,D05,D06,D08,D09,D11,D12` 不存在于当前 dimension-framework ID 集。
- 本轮仍为 report-only 审查，未修改被审源码，未运行完整项目测试。

## 第三轮 Findings（U15-U16）

### P1. U15 没有插入顶层 workflow / SKILL 编排，跨项目聚合 agent 不会被调用

U15 目标要求多项目运行时合并 profile + activation map。当前 `skills/project-standard-extractor/agents/cross-project-aggregator.md` 已存在，并在 `:43` 到 `:44` 定义 `len(scope_summary.project_paths) > 1` 时启用。

但顶层执行入口没有任何调用点：`skills/project-standard-extractor/workflow.md:40` 到 `:57` 仍是 `profile-and-batch-planner -> dimension-activator -> batch loop`，中间没有 cross-project-aggregator；`skills/project-standard-extractor/SKILL.md` 中也没有 `cross-project` / `unified-activation` / `partial_activated` 引用。也就是说，多项目输入只会按现有 7-agent 流继续走单项目 activation-report 路径，不会生成 U15 要求的统一激活 map。

影响：U15 的新增 agent 文件无法被实际 workflow 触发；AE15/AE11 相关的统一规范与项目差异说明不会进入主链路。

建议修复：在 workflow 和 SKILL 顶层流程中加入条件阶段：多项目时先对每个项目产出独立 profile / activation-report，再运行 cross-project-aggregator，之后下游 facts/review/merge 消费 `unified-activation-map.json`；单项目路径保持原链路。

### P1. U15 cross-project-aggregator 与上游 activation-report schema 字段不一致

`skills/project-standard-extractor/agents/cross-project-aggregator.md:113` 到 `:115` 要求每份 activation-report 的 `schema_version == "activation-report.v1"`，否则停止。上游 `skills/project-standard-extractor/agents/dimension-activator.md:47` 到 `:52` 的输出示例却是：

```json
{ "schema": "activation-report.v1" }
```

也就是上游使用 `schema`，U15 新 agent 校验 `schema_version`。在当前契约下，多项目聚合会把真实的 activator 输出判为 `SCHEMA_MISMATCH`。

建议修复：统一 activation-report schema 字段名。若采用 `schema_version`，需要同步修改 dimension-activator、generation/review/merge 所有引用和缺失的 `activation-report-schema.json`；若保留 `schema`，cross-project-aggregator 应按 `schema == "activation-report.v1"` 校验。

### P1. U15 统一激活 map 与 divergence 模板泄露项目原始路径，违反自身保护边界

`cross-project-aggregator.md:56` 到 `:58` 的 unified map 示例直接写 `"path": "/path/to/project-a"`；输入 schema `:27`、`:34` 也保留 `project_path` 原始绝对路径。`templates/project-specific-divergence-template.md:13` 到 `:16` 还在 Front Matter 中提供 `projects[].path` 字段，正文 `:32` 到 `:34` 示例也写 `{/path/.../project-a}`。

但 U15 自己的禁止项 `cross-project-aggregator.md:226` 要求不得把项目原始路径写入 divergence.md 之外的产物；项目规范整体也要求正式规范正文不写真实项目路径。当前 unified map 是 temp 产物，仍会被后续 merge / review 引用；直接保留绝对路径会把多项目本地路径传播到下游。

建议修复：unified map 和 divergence frontmatter 只保留 `project_index`、脱敏 `project_name`、`scope_label` 或 path hash；如果需要可追溯，原始路径只保留在 run-local 非持久日志中，并明确不得写入 evidence/规范目录。

### P1. U16 quality-gate.md 仍使用未注册的 `keep-draft-low-coverage`，source-of-truth 与全局枚举冲突

U16 把 `quality-gate.md` 更新为双门禁 source of truth，这部分已覆盖 Gate A/Gate B。但该文件 `skills/project-standard-extractor/quality-gate.md:275` 明确说 `recommended_action` 取值见 `config/frontmatter-format.md §4.7` 且不得自创枚举，随后 `:280`、`:299` 又使用 `keep-draft-low-coverage`。

当前 `skills/project-standard-extractor/config/frontmatter-format.md:130` 到 `:140` 的 §4.7 仍只有 `keep-draft`、`promote-to-active`、`move-to-pending`、`mark-conflict`、`mark-legacy`、`reject`、`defer`，没有 `keep-draft-low-coverage`。

影响：U16 试图把 `quality-gate.md` 作为 source of truth，但它自身引用了非法枚举；Quality Gate 输出一旦带这个值，Front Matter / merge 校验仍会失败。

建议修复：把 `keep-draft-low-coverage` 正式加入 `frontmatter-format.md §4.7`，并同步 `prompts/quality-review.md` 与所有 agent；或把 shallow 表达拆成 `recommended_action: keep-draft` + `coverage_result: low`。

### P1. U16 shallow 门禁与计划验收口径冲突

U16 计划要求 shallow 检测：“activated 但 evidence 不达深度 → 标 shallow，不进 draft”。当前 `quality-gate.md:206` 到 `:207` 把 activated depth 不达和 shallow 都设置为 `final target_state = draft`、`recommended_action = keep-draft-low-coverage`；`:179` 到 `:180` 还要求 shallow 进入 standard 与 ai-rules。

影响：计划要求 shallow 不进 draft，但 U16 source-of-truth 明确允许 shallow 进入 draft。后续评审和 merge 会按文档放行 low coverage 规则，和验收目标相反。

建议修复：明确最终产品口径。若 shallow 允许作为 low-coverage draft，请修订 U16 计划、R53/验收和 usage-guide；若按计划“不进 draft”，则 Gate B 应把 shallow 路由到 `pending-confirmation` 或单独 low-coverage pending 桶，而不是 draft。

## 验证记录（第三轮）

- 已重新读取计划完成状态：U1-U16 标记 `Status: ✅ 已完成`，U17+ 尚未标记完成。
- U15 文件存在性：`agents/cross-project-aggregator.md`、`templates/project-specific-divergence-template.md`、`agents/profile-and-batch-planner.md`、`agents/merge-coordinator.md` 均存在。
- U16 文件存在性：`skills/project-standard-extractor/quality-gate.md` 存在，且已改为 Gate A / Gate B 双门禁结构。
- 顶层编排引用检查：`workflow.md` / `SKILL.md` 未引用 `cross-project`、`unified-activation`、`partial_activated`。
- 本轮仍为 report-only 审查，未修改被审源码，未运行完整项目测试。

## 第四轮 Findings（U17）

### P1. U17 要求 schema valid，但仍没有可执行的 activation-report JSON Schema

U17 验收要求单项目报告存在且 `schema valid`，并要求所有模式落盘且 schema valid：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1183` 到 `:1188`。但当前仓库仍不存在 `skills/project-standard-extractor/config/dimension-framework/activation-report-schema.json`；`skills/project-standard-extractor/config/dimension-framework/README.md:21` 也仍标注该 schema 为 `U17（待落地）`。

U17 新增的是 `skills/project-standard-extractor/templates/dimension-activation-report-template.json`，它是带占位符的模板 / schema 参考，不是 JSON Schema：文件 `:1` 到 `:107` 是一个示例对象，包含 `<ISO8601>`、`"<absolute path to project root>"`、`"baseline | activated | ..."` 等占位值，无法作为 ajv / Draft-7 之类的确定性校验契约。结果是 U17 的 “schema valid” 仍无法被机器验证，后续 U24 的 force-rebuild 验证也会继续找不到计划中引用的 `activation-report-schema.json`。

建议修复：补齐 `config/dimension-framework/activation-report-schema.json`，并让 dimension-activator、generation、review、merge 和 U24 验证统一引用它；模板可以保留为生成样例，但不能替代 schema。

### P1. U17 持久化链路自身仍混用 `schema` 与 `schema_version`

U17 模板 `skills/project-standard-extractor/templates/dimension-activation-report-template.json:2` 到 `:3` 注释写 `schema_version=activation-report.v1`，实际字段却是 `"schema": "activation-report.v1"`。`merge-coordinator` Step 1.5 和 Step 4.6 读取时也按 `schema == "activation-report.v1"` 校验：`skills/project-standard-extractor/agents/merge-coordinator.md:170`、`:342`。

但同一个 U17 Step 4.6 self-check 在 `skills/project-standard-extractor/agents/merge-coordinator.md:390` 要求落盘文件 `schema_version="activation-report.v1"`。这意味着按模板生成并通过 Step 4.6 校验的报告，会在 U17 自检里失败；反过来如果改成 `schema_version`，现有 facts/generation/review/merge 的 `schema` 校验又会失败。U15 的 cross-project-aggregator 也仍按 `schema_version` 校验 per-project activation-report，跨项目模式会放大这个漂移。

建议修复：立即选定一个权威字段名。若采用 `schema`，则把 U17 self-check、cross-project-aggregator、README 和后续 schema 都改为 `schema`；若采用 `schema_version`，则同步修改 dimension-activator、facts、generation、review、merge 的所有校验点。

### P1. 跨项目主 report 复用 unified map，没有规范化为 activation-report.v1 形状

U17 要求跨项目模式下主 report 与子 report 都存在且 schema valid：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1180`、`:1186`。当前 `merge-coordinator` 规定主激活报告直接复用 `unified-activation-map.json` 的 `dimensions[]`，包含 `unified_state` 与 `partial_activated`：`skills/project-standard-extractor/agents/merge-coordinator.md:372` 到 `:375`。

但 U17 模板和下游 activation-report 消费方的字段是 `dimensions[].state` / `evaluations[].state`，见 `skills/project-standard-extractor/templates/dimension-activation-report-template.json:27` 到 `:76`；现有 facts/generation/review/merge 也都按 activation-report 的 `state` 口径读取。直接把 unified map 的 `unified_state` 当主 activation report，会让跨项目主报告不是 activation-report.v1 形状，`schema valid` 和 Coverage Reviewer 复核都没有稳定输入。

建议修复：跨项目主报告落盘时做一次规范化映射：`unified_state -> state`，保留 `per_project_states[]` / `partial_activated` 作为扩展字段，并按同一个 activation-report schema 校验；`unified-activation-map.json` 可以作为旁路 artifact 保留，不要冒充主 activation report。

### P1. `ACTIVATION_REPORT_PERSIST_DENIED` 被降级为 warning，违反 U17 “保证落盘”的验收口径

U17 Goal 是“保证 `evidence/dimension-activation-report.json` 在每次萃取 run 落盘”，Verification 也要求所有模式下落盘且 schema valid：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1167`、`:1188`。

当前 `skills/project-standard-extractor/agents/merge-coordinator.md:383` 到 `:386` 对 `ACTIVATION_REPORT_PERSIST_DENIED` 的处理是写 review-summary warning、不阻塞其它 step，只记入 `pending_human_actions`。这样一次 run 可以在没有正式 `evidence/dimension-activation-report.json` 的情况下继续完成，下一次 diff baseline、force-rebuild schema 校验、Coverage Reviewer 都会缺关键产物。

建议修复：把 activation-report 持久化失败升级为阻断当前 run 的 hard failure；如果确实要允许其它文件生成，也必须把最终 run 状态标为 failed / incomplete，不能把缺 report 的 run 视为成功。

## 验证记录（第四轮）

- 已重新读取计划完成状态：U1-U17 标记 `Status: ✅ 已完成`，U23-U26、U18-U22 尚未标记完成。
- U17 文件存在性：`skills/project-standard-extractor/templates/dimension-activation-report-template.json` 与 `skills/project-standard-extractor/agents/merge-coordinator.md` 存在。
- 缺失文件检查：`skills/project-standard-extractor/config/dimension-framework/activation-report-schema.json` 仍不存在。
- 字段一致性检查：`dimension-activation-report-template.json`、facts/generation/review/merge 使用 `schema`；U17 self-check 与 cross-project-aggregator 仍出现 `schema_version`。
- 本轮仍为 report-only 审查，未修改被审源码，未运行完整项目测试。

## 第五轮 Findings（U23）

### P1. force-rebuild 的 domain lock 用 `mkdir -p`，并发锁永远不会失败

U23 计划要求取 domain lock：`mkdir skills/project-standard-extractor/.local-backups/<domain>/.lock` 失败时拒绝并提示另一个 force-rebuild 正在进行：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1233` 到 `:1235`。当前 `skills/project-standard-extractor/agents/backup-manager.md:88` 到 `:92` 写的是 `mkdir -p skills/project-standard-extractor/.local-backups/<domain>/.lock`，inline prompt 也同样写 `mkdir -p`：`skills/project-standard-extractor/prompts/orchestrator/force-rebuild/backup-manager.md:21`。

`mkdir -p` 在目录已存在时仍会返回成功，不能作为互斥信号量。结果是两个终端并发 force-rebuild 同一 domain 时，第二个不会命中 `ANOTHER_FORCE_REBUILD_IN_PROGRESS`，两边都可能继续通过净 git / dry-run / atomic rename，直接破坏 U23 的 I1 并发保护。

建议修复：先 `mkdir -p skills/project-standard-extractor/.local-backups/<domain>` 创建父目录，再用不带 `-p` 的 `mkdir "$lockdir"` 原子创建 `.lock`；已存在时必须失败并退出。脚本层也应提供同一行为，而不是只停留在 prompt 文本。

### P1. restore 会把 backup 元数据拷回规范目录，污染 `engineering-standards/<domain>/`

U23 restore 目标是把历史快照恢复到 `engineering-standards/<domain>/`，而 manifest 用于校验备份自身：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1259` 到 `:1263`。当前实现把 manifest 写在备份目录根：`skills/project-standard-extractor/agents/backup-manager.md:130` 到 `:144`，模板也是根层 `manifest.json` 结构：`skills/project-standard-extractor/templates/backup-manifest-template.json:1` 到 `:52`。

但 `scripts/backup.sh` 的 restore 模式直接把整个 `SOURCE/` 同步到 `engineering-standards/<domain>/`：`skills/project-standard-extractor/scripts/backup.sh:211` 到 `:215`。这会把 `.local-backups/<domain>/<ts>/manifest.json`，以及后续可能存在的 `failure.log` / rollback 元数据，一起复制进正式规范目录。更糟的是 restore 的 file_count 校验同样对 `SOURCE` 全目录计数：`:217` 到 `:224`，因此包含 manifest 的污染结果也能通过校验。

建议修复：把备份 payload 与元数据分离，例如 `.local-backups/<domain>/<ts>/payload/` 保存规范目录内容，manifest/failure.log 留在 backup 根；restore 只从 `payload/` 拷回。或者在 restore 明确排除 `manifest.json`、`failure.log`、运行日志等备份元数据，并用 manifest.stats 校验 payload 而非整个 backup 根。

### P1. destructive `domain` 参数只校验非空，缺少路径穿越防护

U23 的 destructive action 都以 `domain` 拼接路径。`SKILL.md` 只要求 `domain` 显式存在：`skills/project-standard-extractor/SKILL.md:27`、`:119`；`intake-and-scope.md` Step 4.5 也只检查 `domain` 非空：`skills/project-standard-extractor/agents/intake-and-scope.md:118`，未校验 `^[0-9]{2}-[a-z0-9-]+$` 或必须属于 `engineering-standards/` 的现有 domain。实际脚本随后直接拼接：`skills/project-standard-extractor/scripts/backup.sh:129` 的 `SRC_DIR="$REPO_ROOT/engineering-standards/$DOMAIN"`，restore 还会构造并 rename `engineering-standards/${DOMAIN}.pre-restore-$NOW`：`:203` 到 `:209`。

这意味着 `domain` 若被传成 `../skills/project-standard-extractor`、带斜杠的相对路径或类似值，backup / restore / atomic rename 的目标会逃出预期 domain 目录。U23 正是在治理 destructive IO，这个校验不能只靠调用方自觉。

建议修复：在 SKILL 调用协议、intake Step 4.5、backup-manager 和 `scripts/backup.sh` 四层都校验 domain：必须匹配 `^[0-9]{2}-[a-z0-9-]+$`，且 `realpath engineering-standards/$domain` 必须位于 `realpath engineering-standards` 之下；restore_from 也要校验为 `^[0-9]{8}T[0-9]{6}Z$`。

### P2. backup.sh 声明“写 manifest.json”，实际只向 stdout 输出 JSON，agent 与脚本契约不一致

U23 文件清单要求 `scripts/backup.sh` 做 manifest.json 写入：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1215`，backup-manager Step 6 又要求用模板补齐 manifest 并通过 ajv 后写文件：`skills/project-standard-extractor/agents/backup-manager.md:130` 到 `:144`。脚本自身注释也写 backup 模式“写 manifest.json 必需字段到 stdout(JSON)”：`skills/project-standard-extractor/scripts/backup.sh:9` 到 `:10`。

当前 `scripts/backup.sh` backup 模式只在 `:184` 到 `:196` 把 JSON 打到 stdout，没有创建 `manifest.json`，也没有 ajv 校验或 atomic write。也就是说 U23 的 manifest 落盘责任在 agent 文档和脚本注释之间漂移；如果调用方只运行 helper script，会得到一个没有 manifest 的备份目录，后续 restore / pin / keep 都找不到权威 metadata。

建议修复：明确唯一职责。更稳妥是让脚本接收 `--manifest=<path>` 或 `--run-id/operator/...` 后负责 atomic write + schema 校验；如果 manifest 必须由 agent 写，则修改脚本注释和 U23 验收，不要声明 helper script 会写 manifest。

## 验证记录（第五轮）

- 已重新读取计划完成状态：U1-U17、U23 标记 `Status: ✅ 已完成`，U24-U26、U18-U22 尚未标记完成。
- U23 文件存在性：`agents/backup-manager.md`、`scripts/backup.sh`、`scripts/README.md`、`config/backup/manifest-schema.json`、`templates/backup-manifest-template.json`、`prompts/orchestrator/force-rebuild/{force-rebuild,backup-manager}.md` 均存在。
- JSON 解析：`config/backup/manifest-schema.json` 与 `templates/backup-manifest-template.json` 可解析。
- 脚本语法：`bash -n skills/project-standard-extractor/scripts/backup.sh` 通过；`backup.sh --dry-run --domain=01-app-client` 能输出 JSON。
- 安全边界检查：`intake-and-scope.md` 未出现 domain 正则校验；lock 文档和 inline prompt 均使用 `mkdir -p .../.lock`。
- 本轮仍为 report-only 审查，未修改被审源码，未运行完整项目测试。

## 第六轮 Findings（U24）

### P1. U24 的 schema 校验会在 schema 文件缺失时降级为 JSON parse，无法拦住错误 activation report

U24 计划把失败信号 (b) 定义为 `evidence/dimension-activation-report.json` 必须通过 `config/dimension-framework/activation-report-schema.json` 校验：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1319`。当前脚本也固定引用该路径：`skills/project-standard-extractor/scripts/force-rebuild-validate.sh:93` 到 `:95`。

但该 schema 文件当前仍不存在；本轮检查 `test -f skills/project-standard-extractor/config/dimension-framework/activation-report-schema.json` 返回缺失。脚本在 `:103` 到 `:149` 又把校验设计成三级降级：没有 ajv 或 schema 文件时进入 python 分支，若 `jsonschema` 可用但 schema 文件不存在，`if ... isfile('$SCHEMA_JSON')` 不成立后直接 `sys.exit(0)`；若 `jsonschema` 不可用则只做 JSON parse；完全无 validator 时也设置 `pass: true`。因此一个字段漂移、缺必填、状态枚举错误的 report 只要 JSON 可解析就能通过 force-rebuild success path。

影响：U24 最核心的 deterministic guard 被软化，且会继承 U17 已发现的 `schema` / `schema_version` 漂移问题；force-rebuild 可能删除 `.broken-<ts>` 并追加 CHANGELOG，留下不符合 activation-report.v1 的新产物。

建议修复：把 schema 文件缺失视为 `activation_report_schema` failure 或 runtime error，不能通过；补齐 `activation-report-schema.json` 后，脚本只允许 `ajv` 或 `python jsonschema + schema file` 通过，`json-parse-only` 最多作为诊断输出，不应在 force-rebuild 下返回 valid。

### P1. CHANGELOG 失败回滚前已经删除 `.broken-<ts>`，回滚不再是 U24 要求的 atomic rename

U24 计划要求 success path 先完成 changelog-append，且追加失败触发 backup-manager failure path 回滚：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1314` 到 `:1331`。rollback 测试还要求 CHANGELOG 写失败时 atomic rename 回滚并保留 `in-progress.lock`：`:1354`。

当前 `backup-manager.md` 的 Step 10a 顺序是先删旧目录：`skills/project-standard-extractor/agents/backup-manager.md:192` 到 `:195` 写 “删 `engineering-standards/<domain>.broken-<ts>`” 后才调用 changelog helper；helper 失败时 `:202` 到 `:207` 承认 `.broken-<ts>` 已删，只能 `mv <domain> <domain>.changelog-fail-<now>` 再 `cp -a <backup_dir>/. engineering-standards/<domain>/` 重建。

这已经不是 U24 计划的反向 atomic rename：一旦 `cp -a` 中途失败，会留下半恢复目录；同时它复用了 U23 已发现的问题，会把 backup 根下的 `manifest.json` / `failure.log` / `in-progress.lock` 等元数据拷回正式规范目录。

建议修复：调整 Step 10a 顺序为 `validate pass -> changelog helper success -> manifest finalize -> 删除 .broken-<ts>`；在 changelog 成功前绝不删除 `.broken-<ts>`。若 helper 失败，直接走 Step 10b 的反向 rename，不要从 backup_dir `cp -a` 重建正式目录。

### P1. `in-progress.lock` 计划要求真实文件治理，实现却混用 manifest 字段与文档树，残留检测无法按计划工作

U24 Approach 要求备份阶段写 `.local-backups/<domain>/<ts>/in-progress.lock`，changelog 成功后才删除，后续任意 mode 启动时扫描残留文件并提示未完成：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1332` 到 `:1335`。

当前 `backup-manager.md` Step 6 只写 `manifest.in_progress_lock.run_id / expected_changelog_anchor / started_at`：`skills/project-standard-extractor/agents/backup-manager.md:130` 到 `:144`；success / failure path 也只是把 `manifest.in_progress_lock` 置 null：`:194`、`:223`。Self-check 进一步写成检查 `.local-backups/<domain>/*/manifest.json.in_progress_lock != null`：`:303`。与此同时 `config/backup/README.md:19` 到 `:22` 的目录布局又列出真实 `in-progress.lock` 文件，`:51` 写回滚后删除 `in-progress.lock`。

影响：不同调用方会按不同契约执行。若只写 manifest 字段，计划要求的残留文件扫描不会触发；若按 README 写文件，backup-manager 的 success/failure path 不会清理它。尤其 U24 要求 changelog 失败时 `in-progress.lock` 仍在以便后续启动告警，当前 Step 10a 特例路径没有明确保留或清理真实 lock 文件。

建议修复：统一为真实文件或 manifest 字段其中一种。若采用真实文件，就在 Step 6 创建 `<backup_dir>/in-progress.lock`，success path 仅在 changelog 成功后删除，failure / changelog-fail 按计划保留或明确策略，并让启动扫描查文件；若采用 manifest 字段，则修订 U24 plan / README / evals，且启动检查必须读取 JSON 字段。

### P1. U24 计划的多 domain 事务语义没有接入调用协议，当前入口仍禁止多项目且只把 `domain` 当单值处理

U24 明确新增多 domain 一次 force 的事务语义：`--domain=01-app-client,02-frontend` 时任一 domain 校验失败要回滚全部已处理 domain，且不追加任何 CHANGELOG：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1342`、`:1357`。

当前顶层 `SKILL.md` 的调用协议仍把 `domain` 写成单个字符串示例：`skills/project-standard-extractor/SKILL.md:27`；`intake-and-scope.md` Step 4.5 只校验 domain 非空并把单个 `domain` 注入 backup-manager：`skills/project-standard-extractor/agents/intake-and-scope.md:118` 到 `:121`。`force-rebuild.md` 还保留 `project_paths` 长度 ≤ 1 的互斥限制：`skills/project-standard-extractor/prompts/orchestrator/force-rebuild/force-rebuild.md:7` 到 `:10`。全局搜索只在 eval 草案里出现多 domain 场景，主 workflow / backup-manager 没有“已处理 domain 列表”“跨 domain rollback coordinator”或“最后统一 changelog append”的契约。

影响：用户传 `--domain=01-app-client,04-backend` 时，要么被当作非法/不存在单 domain，要么被路径拼接到 `engineering-standards/01-app-client,04-backend`；不会产生 U24 承诺的 per-domain lock / backup / manifest / all-or-nothing rollback。

建议修复：要么把 U24 多 domain 场景移出已完成范围，留给 U25/U26；要么在 SKILL/intake/force-rebuild/backup-manager 中正式引入 `domains[]`，按顺序处理并维护 transaction state：`processed_domains[]`、每个 domain 的 `backup_dir` / `.broken_ts` / lock，所有 domain 校验和 changelog 都成功后才 finalize，任一失败按反序回滚全部已处理 domain。

### P2. `force-rebuild-validate.sh` 的标准文件查找没有按 U24 的 `0N-{sub_domain}-standard.md` 契约计数，可能漏掉新版产物

U24 的字符数比对和非空规则节都针对 `0N-{sub_domain}-standard.md`：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1318` 到 `:1320`。计划前文也描述新输出结构使用 `01-kmp-shared-standard.md`、`02-android-standard.md` 这类编号文件：`:831`。

当前脚本的 `count_chars()` 只找 `standard-*.md` 或 `standard*.md`：`skills/project-standard-extractor/scripts/force-rebuild-validate.sh:64` 到 `:73`；规则节检查同样只找这两类文件：`:152` 到 `:156`。这会漏掉现有仓库中的 `engineering-standards/01-app-client/01-kmp-shared-layer-standard.md`、`02-android-standard.md`、`03-ios-standard.md`、`05-module-standard.md` 等编号产物。

影响：如果 force-rebuild 新版只生成编号标准文件，`NEW_CHARS` 与 `OLD_CHARS` 可能都是 0，脚本进入 `old=0 first-rebuild-skip` 并跳过字符比；随后非空规则节也可能误报 0 files matched。反过来，如果旧 `standard-*.md` 遗留文件存在，脚本可能只比较旧命名文件，忽略真正被重生的新结构。

建议修复：把标准文件发现规则统一到 Phase 2 输出契约，至少包含 `*-standard.md` 并排除非规范模板 / review 报告 / `ai-rules.md`；更稳妥是由 merge-coordinator 输出本 run 写入的 `standard_docs[]`，validate.sh 读取这份清单做字符比与规则节检查。

### P2. Quality Gate 检查没有截取 `quality_gate_decisions:` 段，可能被段外文本误伤

U24 计划要求检查 review 输出的 `quality_gate_decisions:` 段，且段内没有 `status: blocked|conflict`：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1321`。

当前脚本只先确认文件中存在 `quality_gate_decisions:`，然后对整个 review 文件执行 `grep -cE '^\s*status:\s*(blocked|conflict)'`：`skills/project-standard-extractor/scripts/force-rebuild-validate.sh:178` 到 `:190`。这没有限定 YAML 段范围，也没有排除 code block、示例、历史 notes 或其它章节里的 `status: blocked`。

影响：合法的 review-summary 只要在解释文字或示例里包含 `status: blocked` 行，就会误触发回滚；反之，如果 `quality_gate_decisions:` 段使用嵌套结构但真实阻断状态不在行首，也可能漏检。force-rebuild 的成败不应依赖全文 grep 的偶然命中。

建议修复：让 review-and-quality-gate 额外输出机器可读 JSON/YAML 摘要，例如 `temp/{run_id}-quality-gate-decisions.json`；validate.sh 用 `jq` / `ruby` / `python` 解析 `quality_gate_decisions[]`。若短期仍读 Markdown，至少用 awk 截取 `quality_gate_decisions:` 到下一个同级标题 / YAML 段结束后再 grep。

## 验证记录（第六轮）

- 已重新读取计划完成状态：U1-U17、U23、U24 标记 `Status: ✅ 已完成`，U25-U26、U18-U22、U27 尚未标记完成。
- U24 文件存在性：`scripts/force-rebuild-validate.sh`、`prompts/orchestrator/force-rebuild/changelog-append.md`、`prompts/orchestrator/force-rebuild/force-rebuild.md` 存在。
- 脚本语法：`bash -n skills/project-standard-extractor/scripts/force-rebuild-validate.sh` 通过。
- 缺失文件检查：`skills/project-standard-extractor/config/dimension-framework/activation-report-schema.json` 仍不存在。
- 契约检查：主入口未发现 `domains[]` / 多 domain transaction state；`in-progress.lock` 同时以 README 文件树和 manifest `in_progress_lock` 字段出现，backup-manager 主流程只写 manifest 字段。
- 本轮仍为 report-only 审查，未修改被审源码，未运行完整项目测试。

## 第七轮 Findings（U25）

### P1. FRC-009 把 U24 要求的多 domain 事务语义改成了“独立提交”，eval 会验收错误行为

U24 计划明确要求 `--domain=01-app-client,02-frontend` 这种一次 force-rebuild 的事务语义：任一 domain 在校验阶段失败，全部已处理 domain 回滚，且 CHANGELOG 不追加任一 domain 条目：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1342`、`:1357`。

U25 新增的 `skills/project-standard-extractor/evals/dimension-framework/force-rebuild-cases.md:309` 到 `:326` 把同一 Finding C-12 写成两个串行单独调用：第一步 `01-app-client` 已成功提交并追加 CHANGELOG，第二步 `04-backend` 失败时只回滚第二步；`:326` 还写成“domain 是隔离边界，不会因为一个 domain 失败回滚另一个 domain 已完成的变更”。这与 U24 的 all-or-nothing transaction 完全相反。

影响：U25 的回归用例会把错误行为固化为通过标准。后续即使实现没有多 domain transaction，FRC-009 也会通过；而真正的 U24 验收场景会被文档层覆盖掉。

建议修复：FRC-009 应改为单次调用 `domains: [01-app-client, 04-backend]` 或明确 `domain: 01-app-client,04-backend`，并断言第二个 domain 失败后第一个 domain 也按其 manifest 反向回滚，根 CHANGELOG 不含任一 force-rebuild 条目。如果产品决定放弃多 domain transaction，则应先回改 U24 计划、Approach、test scenarios 和 release notes，而不是在 eval 中静默改口。

### P1. U25 文档把 CHANGELOG 失败后的非原子 `cp -a backup_dir` 特例回滚固化为预期

第六轮已指出 U24 当前 success path 在 changelog helper 前删除 `.broken-<ts>`，导致 CHANGELOG 失败时只能从 backup_dir `cp -a` 重建，已经不再是 atomic rename。U25 又把这条有风险路径写成正式文档和 eval。

具体证据：`skills/project-standard-extractor/quality-gate.md:333` 写 changelog-append 失败时执行 `mv <domain> <domain>.changelog-fail-<now>` + `cp -a backup_dir/. <domain>/`；`skills/project-standard-extractor/evals/dimension-framework/force-rebuild-cases.md:242` 到 `:264` 的 FRC-007 明确以 `.broken-<ts>` 已删为 Given，并验收 `cp -a .local-backups/.../. engineering-standards/...`；`skills/project-standard-extractor/examples/phase-2/force-rebuild-walkthrough.md:56` 到 `:74` 也把删除 `.broken-<ts>` 放在 changelog helper 前。

影响：这会让 U25 用户文档、walkthrough 和回归用例共同接受一个不可原子、会复制 backup 元数据回正式目录的回滚路径。它不仅继承 U24 的回滚顺序问题，也继承 U23 的 backup payload / manifest 污染问题。

建议修复：U25 文档和 FRC-007 应按目标契约写：validate 通过后先调用 changelog helper，helper 成功后才删除 `.broken-<ts>`；helper 失败直接走 reverse atomic rename。所有 `cp -a backup_dir/. <domain>/` 的特例路径应删除，除非另行实现 payload/metadata 分离并把该路径降级为非原子救援流程。

### P1. Walkthrough 使用的 validate.sh 参数与真实脚本不匹配，验收命令会直接失败

当前真实 `skills/project-standard-extractor/scripts/force-rebuild-validate.sh:44` 到 `:53` 只接受两个参数：`--domain=<domain>` 与 `--backup-dir=<backup_dir>`。我实际运行 `bash skills/project-standard-extractor/scripts/force-rebuild-validate.sh --domain=01-app-client --activation-report temp/x --quality-gate temp/y`，脚本返回 `ERR: unknown arg: --activation-report`，退出码 2。

但 U25 walkthrough 在 `skills/project-standard-extractor/examples/phase-2/force-rebuild-walkthrough.md:66` 到 `:70` 和 `:102` 到 `:107` 使用的是 `--domain 01-app-client --activation-report ... --quality-gate ...`，既用了非 `--domain=` 形式，又传了脚本不支持的 `--activation-report` / `--quality-gate`。这不是单纯示例格式差异，用户照着 §1.7 验收命令会得到 runtime error，而不是 U25 声称的 exit 0。

建议修复：walkthrough 和 eval 统一改成真实脚本接口：`scripts/force-rebuild-validate.sh --domain=01-app-client --backup-dir=<absolute-or-repo-relative-backup-dir>`；如果希望显式传 activation-report / quality-gate 文件，则先修改脚本接口和 backup-manager Step 10 调用契约，再同步所有文档。

### P1. U25 文档与 eval 对 `in-progress.lock` 的残留策略互相矛盾，且都没有对齐 U24 计划

U24 计划要求 `in-progress.lock` 在 changelog-append 成功后才删除，后续任意 mode 启动时检查残留并提示上次 force-rebuild 未完成：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1332` 到 `:1335`。第六轮已发现实现层又混用了真实文件和 `manifest.in_progress_lock` 字段。

U25 进一步把口径写散：`skills/project-standard-extractor/quality-gate.md:340` 写 `in-progress.lock` 残留不自动清，看到 lock 残留即失败信号；但 `skills/project-standard-extractor/evals/dimension-framework/force-rebuild-cases.md:97` 和 `skills/project-standard-extractor/examples/phase-2/force-rebuild-walkthrough.md:190` 又写失败回滚后不保留 `in-progress.lock`，理由是避免 stuck。

影响：失败路径到底应该保留残留信号还是清理掉，U25 的正式质量门禁、eval 和 walkthrough 给出相反答案。后续实现无论选择哪边都会被另一份文档判错，也无法满足 U24 的“后续启动告警”治理目标。

建议修复：先决定单一策略。若按 U24 原计划，失败或 changelog-fail 后保留真实 `in-progress.lock`，后续启动告警，人工 restore / inspect 后清理；若决定失败后清理，必须删除 U24 的残留治理要求，并改成 failure.log / manifest.rollback 是唯一恢复信号。无论哪种，quality-gate、force-rebuild-cases、walkthrough、config/backup/README 和 backup-manager 必须同一口径。

### P2. U25 暴露 `output_action=list`，但当前 SKILL 调用协议尚未包含该枚举

U25 walkthrough §4.8 给出了 list 子命令示例：`skills/project-standard-extractor/examples/phase-2/force-rebuild-walkthrough.md:323` 到 `:341`，使用 `output_action: list` 列出备份。可是当前 `skills/project-standard-extractor/SKILL.md:24` 的 `output_action` 枚举仍只有 `append | force-rebuild | restore | pin | unpin`；`domain` / `restore_from` 说明 `:27` 到 `:28` 也没有 list。U26 计划才把 list 作为新增子命令：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1455`。

影响：U25 作为对外文档已标记完成，但现在用户照 walkthrough 传 `output_action=list` 会被入口协议视为未定义；这会让文档超前于已完成实现单元，也破坏“只审查已完成 U”的状态边界。

建议修复：在 U25 文档中把 list 标注为 U26 后可用 / upcoming，或暂时移除 §4.8；待 U26 完成时再把 SKILL.md、intake、backup-manager、scripts/backup.sh 和 walkthrough 一起切到正式可用。

### P2. U25 的示例仍写 11 个 baseline，与当前维度池和既有 findings 不一致

`skills/project-standard-extractor/evals/dimension-framework/force-rebuild-cases.md:38` 写 `engineering-standards/01-app-client/` 含 “11 baseline 维度全 draft”，`:61` 的 CHANGELOG 示例也写 `baseline=11`；walkthrough `skills/project-standard-extractor/examples/phase-2/force-rebuild-walkthrough.md:41` 到 `:42`、`:95` 同样使用 `baseline=11`。

当前 U1 实现的 baseline 只有 6 个，第一轮审查已经指出它也不满足需求文档要求的 13 个 Layer 1 通用维度。U25 文档又引入第三个数字 11，却没有解释它是 APP activated 维度数、baseline count，还是 Phase 2 完整维度总数。

影响：force-rebuild 的 CHANGELOG 摘要和 eval 断言会围绕错误计数建立预期，后续 U1 修成 13 个 common dimensions 后，U25 示例仍会误导用户和测试作者。

建议修复：示例不要硬编码 `baseline=11`。短期用占位 `baseline=<N>` 并注明来自 `dimension_activation_report.summary.baseline`；若需要真实数值，必须先统一 U1 baseline/common dimension 定义，再由 schema / fixture 推导。

## 验证记录（第七轮）

- 已重新读取计划完成状态：U1-U17、U23-U25 标记 `Status: ✅ 已完成`，U26、U18-U22、U27 尚未标记完成。
- U25 文件存在性：`README.md`、`SKILL.md`、`usage-guide.md`、`quality-gate.md`、`installation-or-consumption.md`、`evals/dimension-framework/force-rebuild-cases.md`、`evals/dimension-framework/README.md`、`examples/phase-2/force-rebuild-walkthrough.md` 均存在。
- grep 覆盖：5 个对外文档均出现 force-rebuild / output_action 相关说明；evals 含 FRC-001 到 FRC-009；walkthrough 含成功 / 回滚 / restore / pin-unpin 四段。
- 脚本接口验证：真实 `force-rebuild-validate.sh` 对 `--activation-report` / `--quality-gate` 返回 `unknown arg`，与 walkthrough 命令不一致。
- 本轮仍为 report-only 审查，未修改被审源码，未运行完整项目测试。

## 第八轮 Findings（U26）

### P1. `output_action=list` 已在 backup-manager / usage-guide 暴露，但顶层入口和 intake 仍不接受 list

U26 Goal 要求提供 `output_action=list --domain=<>` 查看备份与 pin 状态：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1457`。当前 `backup-manager.md` 已新增 list 分支：`skills/project-standard-extractor/agents/backup-manager.md:271` 到 `:300`；`usage-guide.md` 也把 list 写成正式用户模式：`skills/project-standard-extractor/usage-guide.md:157` 到 `:184`；脚本也支持 `--list`：`skills/project-standard-extractor/scripts/backup.sh:126`、`:257` 到 `:304`。

但对外入口没有同步：`skills/project-standard-extractor/SKILL.md:24` 的 `output_action` 枚举仍是 `append | force-rebuild | restore | pin | unpin`，没有 `list`；`skills/project-standard-extractor/input-guide.md:74` 到 `:90` 的可选值和字段枚举也没有 `list`；`skills/project-standard-extractor/agents/intake-and-scope.md:118` 的 domain 必填校验只覆盖 `{force-rebuild, restore, pin, unpin}`，`:137` 的 `scope_summary.output_action` 枚举也没有 `list`。

影响：用户按 U26 / usage-guide 调 `output_action: list` 时，入口协议层不是一个合法模式；即使没有被拒绝，intake 也不会强制 domain 必填，可能把空 domain 交给 backup-manager / script。U26 的 list 能力只在局部 helper 和文档里存在，没有贯通主 workflow。

建议修复：把 `list` 纳入 `SKILL.md`、`input-guide.md`、`intake-and-scope.md` 的 `output_action` 枚举；`output_action=list` 必须要求 `domain`，不要求 `restore_from`，跳过 destructive / interactive 约束，分流到 backup-manager Step 11 list 分支并返回 `action_taken: listed`。

### P1. pin / unpin 的唯一可执行脚本会直接改 manifest，没有取 domain lock，无法满足与 force-rebuild 互斥

U26 测试场景要求 pin 与 force-rebuild 取同一 domain lock，不允许并发执行：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1468`。`backup-manager.md` 也写 pin / unpin 先取 lock：`skills/project-standard-extractor/agents/backup-manager.md:255` 到 `:269`。

但实际可执行的 mutating 路径是 `scripts/backup.sh --pin/--unpin`：`skills/project-standard-extractor/scripts/backup.sh:307` 到 `:345`。这段只校验 `--backup-id`、读写 `manifest.json`、`mv` 临时文件并重算 sha256；没有创建或检查 `.local-backups/<domain>/.lock`，也没有拒绝 lock 已存在。脚本 README 也没有说明 pin/unpin 需要由外层持锁调用。

影响：两个 agent / 终端可以在 force-rebuild 正持有 lock 时直接运行 `backup.sh --pin`，并发修改同一个 backup manifest。对于当前这种 prompt + helper script 架构，脚本是唯一真正执行写入的边界，缺少锁会让 U26 的并发验收不可被机器保证。

建议修复：二选一收敛。更稳妥是给 `backup.sh --pin/--unpin` 增加 `--lock-held` 或内部 `mkdir "$BACKUPS_DIR/.lock"` 机制，并在 lock 已存在时拒绝；如果锁只允许 backup-manager 持有，则脚本文档和参数应明确必须由已持锁调用，且 backup-manager 需要传入可验证的 lock token / owner。

### P1. pin / unpin 写回前后没有做 manifest schema 校验，和 U26 Verification 不一致

U26 Verification 要求 manifest schema 通过 ajv valid：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1472`。`backup-manager.md` 也要求 pin/unpin “写回前 ajv valid 校验”：`skills/project-standard-extractor/agents/backup-manager.md:258`、`:266`。

但 `scripts/backup.sh` 的 pin/unpin 实现只用 Python `json.load` 解析，再设置 `m["pin"]` 并写回：`skills/project-standard-extractor/scripts/backup.sh:321` 到 `:336`。它没有调用 `ajv`，没有读取 `config/backup/manifest-schema.json`，也没有校验 required 字段、`backup_id` 格式、`domain` 格式、`stats.sha256_fingerprint` 或 `additionalProperties: false`。

影响：一个结构已经漂移或字段错误的 manifest 会被 pin/unpin 成功写回，随后 `manifest.json.sha256` 也会重新生成，形成“完整性看似有效但 schema 无效”的备份元数据。restore / keep / list 对这些元数据的后续行为会变得不可信。

建议修复：pin/unpin 写回前应先按兼容规则补齐 `pin: false`，再用 `manifest-schema.json` 校验完整 manifest；写回后再次校验再 `mv`。如果不想让脚本依赖 ajv，可用 Python `jsonschema`，但 schema 文件不存在或 validator 不可用时应拒绝 mutating 写入。

### P2. `--backup-id` 只做路径字符过滤，没有按 UTC-ts 契约校验

U26 plan 把 `restore_from` / backup id 定义为 UTC-ts，测试和用法都使用 `YYYYMMDDTHHMMSSZ`：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1455` 到 `:1457`。manifest schema 对 `backup_id` 也有 `^[0-9]{8}T[0-9]{6}Z$` pattern：`skills/project-standard-extractor/config/backup/manifest-schema.json:25` 到 `:29`。

当前脚本只拒绝 `..`、绝对路径、反斜杠和空格：`skills/project-standard-extractor/scripts/backup.sh:307` 到 `:315`。如果 `.local-backups/<domain>/foo/manifest.json` 恰好存在，`backup.sh --pin --backup-id=foo` 会继续修改它；这和 list 输出“按 backup_id 字典序 = UTC 时序”的契约也不一致。

建议修复：`--backup-id` / `restore_from` 统一校验 `^[0-9]{8}T[0-9]{6}Z$`；list 可以把非 timestamp 目录标记为 `invalid_backup_id: true` 供排查，但 pin/unpin/restore 不应修改它们。

### P2. `scripts/README.md` 没同步 U26 子命令，脚本文档仍只展示 backup / restore

U26 扩展了 `scripts/backup.sh` 的 `--list` / `--pin` / `--unpin`，但 `skills/project-standard-extractor/scripts/README.md:7` 到 `:10` 仍把 `backup.sh` 描述为 “force-rebuild / restore 子命令的 cp/rsync 实现”；使用示例 `:20` 到 `:39` 只包含 dry-run、backup、restore，没有 list / pin / unpin。

影响：用户或后续 agent 读取脚本目录说明时看不到 U26 的新增子命令，只能从脚本头注释或 usage-guide 猜测；这与 U25/U26 强调的文档一致性目标冲突。

建议修复：更新 `scripts/README.md` 文件清单和使用示例，明确 `--list` 输出 JSON、`--pin/--unpin` mutating 语义、锁要求、schema 校验要求和失败码。

## 验证记录（第八轮）

- 已重新读取计划完成状态：U1-U17、U23-U26 标记 `Status: ✅ 已完成`，U18-U22、U27 尚未标记完成。
- U26 文件存在性：`agents/backup-manager.md`、`scripts/backup.sh`、`config/backup/manifest-schema.json`、`usage-guide.md` 存在。
- 脚本语法：`bash -n skills/project-standard-extractor/scripts/backup.sh` 通过。
- 脚本 smoke：`backup.sh --list --domain=01-app-client` 在无备份目录时输出 `[]`；`backup.sh --pin --domain=01-app-client --backup-id=not-exist` 返回 backup not found。
- JSON 解析：`config/backup/manifest-schema.json` 可解析。
- 本轮仍为 report-only 审查，未修改被审源码，未运行完整项目测试。

## 第九轮 Findings（U18）

### P1. U18 标记为“端到端跑通”，但实际只交付 synthetic mock PoC，不能满足 AE22 的真实证券代码验证

U18 Goal 要求“用真实证券系统代码（或脱敏样例）跑全链路萃取”，并以证券经纪业务系统跑完后产出 SEC + XSEC 全 16 维章节作为 AE22 通过条件：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1484`、`:1490`、`:1493`、`:1514`。同一任务还要求端负责人 review 反馈“骨架结构可用 + 内容准确”：`:1519`。

当前产物明确是 synthetic PoC：`engineering-standards/09-industry/01-securities-standard.md:11` 写 `evidence_tier: "synthetic-poc"`，`:16` 和 `:21` 说明全部 evidence 路径与代码片段为合成示例；`engineering-standards/09-industry/evidence/dimension-activation-report.json:6` 到 `:12` 的 `project_paths` 是 `/mock/demo-broker-platform`，commit 是 `synthetic-poc`；`skills/project-standard-extractor/examples/phase-2/golden-sample-securities-run.md:14` 到 `:16` 也写“不代表真实 evidence 团队规范”。本轮在仓库内查找 `demo-broker-platform` 没有找到真实样例目录。

影响：synthetic PoC 能证明 16 维骨架“可写出来”，但不能证明 dimension-activator、facts、generation、review、merge 对真实或脱敏证券代码端到端可用，也不能支撑“章节激活态准确率 ≥ 80%”或“端负责人 review 通过”。将 U18 标记完成会让后续 U22 集成验证误以为 AE22 已有真实链路基线。

建议修复：把当前产物明确降级为 “U18a synthetic skeleton dry-run”，或回改 U18 完成口径；真正的 U18 完成应补一次真实/脱敏/可复现 demo 项目扫描，保存输入项目摘要、实际 signal hit 证据、端负责人 review 反馈，并把 `evidence_tier` 从 `synthetic-poc` 升级为可区分的 `real-evidence` / `sanitized-evidence`。

### P1. `dimension-activation-report.json` 的主消费字段仍不是 16 个 dimensions，后续消费者会读到空激活图

U5/U8/U17 的主契约都围绕 `activation-report.v1` 的 `dimensions[]` 消费；U18 计划也要求检查 `dimension-activation-report.json` 的 baseline / activated / candidate 维度：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1506` 到 `:1509`。

当前 U18 report 把 16 个维度放在非主契约字段 `evaluations[]`：`engineering-standards/09-industry/evidence/dimension-activation-report.json:27`；真正的 `dimensions[]` 只有一个 `$comment` 占位对象：`:389` 到 `:393`。本轮解析结果为 `evaluations_count=16`，但 `dimensions_count=1`，且该对象没有 `dimension_id/state/evidence_paths`。此外文件仍使用 `schema: "activation-report.v1"` 而不是前几轮已经反复指出的统一 `schema_version` 口径：`:3`。

影响：任何按 U5/U8/U17 正常读取 `dimensions[]` 的 generation、merge、overview 或验证脚本都会看不到 16 个激活维度；summary 虽写 `total_dimensions=16`，但主数组与 summary 不一致。U18 的“report 存在”会掩盖 activation-report 主契约仍不可执行的问题。

建议修复：把 16 个 `evaluations[]` 条目迁移/复制为标准 `dimensions[]` 条目，并按可执行 `activation-report-schema.json` 校验；如果确实要引入 `evaluations[]` 作为别名，必须先更新 schema、所有消费者和 U17/U18 验收，不要只用注释对象占位。

### P1. baseline / pending owner 确认链路没有写入 `pending-confirmation.md`，团队 review 反馈也没有归档

U18 计划要求把 “PoC 跑出来的产物 + activation-report + 团队 review 反馈” 写到 golden sample：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1511`，并要求 baseline 维度兜底时 SEC-06 即使无 evidence 也产出 pending：`:1517`。

当前标准正文有多处 owner 待确认：SEC-03 在 `engineering-standards/09-industry/01-securities-standard.md:127` 到 `:132`，SEC-10 在 `:221` 到 `:224`，XSEC-01 在 `:235` 到 `:240`，未激活地图也列出 6 条 owner 问题 `:394` 到 `:403`。activation-report 中也有 `owner_confirmations`，例如 `engineering-standards/09-industry/evidence/dimension-activation-report.json:87` 到 `:94`、`:236` 到 `:243`、`:264` 到 `:270`、`:313` 到 `:319`。但 `engineering-standards/09-industry/pending-confirmation.md:1` 到 `:3` 仍写“当前暂无待确认规则”。

同时 golden sample 只有 review-and-quality-gate 自评摘要：`skills/project-standard-extractor/examples/phase-2/golden-sample-securities-run.md:159` 到 `:181`，没有实际端负责人姓名、时间、结论或反馈原文；`01-securities-standard.md:9` 的 owner 也仍是 TBD。

影响：U18 的 owner 门禁断在正文和 JSON 里，没有进入仓库现有 pending-confirmation 入口；后续 reviewer / agent 读取 `pending-confirmation.md` 会误判无需确认。团队 review 反馈缺失也使 U18 的 “骨架结构可用 + 内容准确” 验收无法复核。

建议修复：把 SEC-03、SEC-10、XSEC-01、XSEC-03 以及 candidate owner 问题同步写入 `pending-confirmation.md`，并在 golden sample 增加 `review_feedback` 段，记录 reviewer、reviewed_at、结论、保留意见和是否允许进入 draft/active。synthetic PoC 没有负责人 review 时，应显式标为未满足 U18 通过条件。

### P2. U18 产物路径从计划的 `04-industry` 改为 `09-industry`，但计划和后续任务引用没有同步

U18 Files 明确要求输出到 `engineering-standards/04-industry/01-securities-standard.md` 与 `engineering-standards/04-industry/evidence/dimension-activation-report.json`：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1494` 到 `:1495`；U18 Approach 还要求检查 overview `00-industry-overview.md`：`:1510`。

当前实际产物在 `engineering-standards/09-industry/`，且仓库没有 `engineering-standards/04-industry/`。`CHANGELOG.md` 的 U18 条目特别说明“产物路径 09-industry/（非 plan 写的 04-industry/），以现有仓库真实结构为准”；golden sample 也把 domain 写成 `09-industry`：`skills/project-standard-extractor/examples/phase-2/golden-sample-securities-run.md:8`、`:155` 到 `:157`。

影响：这可能是合理的目录编号修正，但现在只在 changelog 和 example 里局部改口，计划、U20 walkthrough、U22 集成验证和任何按 `04-industry` 查找 U18 产物的脚本都会失败。`00-industry-overview.md` vs `overview.md` 也存在同类漂移。

建议修复：选择一个权威路径并全链路同步。若 `09-industry` 是正确编号，应更新 U18/U20/U22 plan、usage/example 引用、输出目标配置和验证脚本；若 `04-industry` 是计划契约，应移动/生成兼容入口，避免后续任务按计划路径找不到 PoC 产物。

## 验证记录（第九轮）

- 已重新读取计划完成状态：U1-U18、U23-U26 标记 `Status: ✅ 已完成`，U19-U22、U27 尚未标记完成。
- U18 文件存在性：`engineering-standards/09-industry/01-securities-standard.md`、`engineering-standards/09-industry/evidence/dimension-activation-report.json`、`engineering-standards/09-industry/overview.md`、`skills/project-standard-extractor/examples/phase-2/golden-sample-securities-run.md` 存在；计划中的 `engineering-standards/04-industry/` 不存在。
- 维度覆盖：`01-securities-standard.md` 共 425 行，SEC-01~SEC-10 与 XSEC-01~XSEC-06 均出现，未发现 `{{...}}` 占位符残留。
- JSON 解析：`dimension-activation-report.json` 可解析；`evaluations[]` 数量为 16，`dimensions[]` 数量为 1 且仅为 `$comment` 占位对象。
- evidence 边界：产物和 golden sample 均标注 `evidence_tier=synthetic-poc`，未发现真实 `demo-broker-platform` 项目目录。
- 本轮仍为 report-only 审查，未修改被审源码，未运行完整项目测试。

## 第十轮 Findings（U19）

### P1. 多数 eval 断言读取 `evaluations[]`，会把 activation-report 主契约漂移固化为通过标准

U19 目标是补 AE7-AE22 的维度框架评估场景：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1529` 到 `:1531`。但这些 eval 大量把激活报告的权威维度数组写成 `evaluations[]`：`skills/project-standard-extractor/evals/dimension-framework/securities-poc-cases.md:49` 到 `:53`、`:58` 到 `:65`；`activation-signal-cases.md:46` 到 `:47`；`three-state-cases.md:74` 到 `:75`、`:106` 到 `:107`；`gitnexus-cases.md:57`；`incremental-mode-cases.md:51` 到 `:55`。

这正好会让 U18 当前错误 report 通过：U18 的 `evaluations[]` 有 16 条，但 `dimensions[]` 只有一个 `$comment` 占位对象。与之相反，force-rebuild 共通断言又用 `.dimensions[].dimension_id`：`skills/project-standard-extractor/evals/dimension-framework/force-rebuild-cases.md:68`。也就是说同一 eval 套件内部对 activation-report 主字段的读法不一致。

影响：U19 本应用来拦截 U17/U18 的 activation-report 契约漂移，现在反而会把非主字段 `evaluations[]` 当作合格接口。后续 U22 集成验证若沿用这些 jq 断言，会在下游消费者实际读不到 `dimensions[]` 时仍显示 PASS。

建议修复：先确定 activation-report.v1 的唯一权威字段。若维持 U5/U8/U17 的 `dimensions[]` 契约，所有 U19 case 必须改读 `.dimensions[] | select(.dimension_id==...)`，并额外断言 `summary.total_dimensions == dimensions.length`；如果要引入 `evaluations[]`，必须同步 schema、agent 文档、generation / merge / validate 脚本和此前报告里的字段口径。

### P1. AE22 证券 PoC case 把 synthetic mock 定义为全量通过，覆盖了 U18 要求的真实/脱敏代码验收

U18 计划要求“真实证券系统代码（或脱敏样例）”跑全链路，且通过条件包含证券经纪业务系统产物、随机章节状态准确率、端负责人 review 反馈：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1484`、`:1493`、`:1514` 到 `:1519`。

U19 的 `SPC-001` 却把 Given 固定为 `evidence_tier: synthetic-poc` 和 `project: /mock/demo-broker-platform`：`skills/project-standard-extractor/evals/dimension-framework/securities-poc-cases.md:15` 到 `:20`，并把 `T1~T8 全部 PASS → SPC-001 = PASS` 写为全量通过标准：`:98` 到 `:113`。这些断言只检查 synthetic-poc 边界标注和 GitNexus fallback，不检查真实/脱敏项目存在、实际 signal scan 可复现、端负责人 review 反馈或状态抽样准确率。

影响：这会把第九轮指出的 U18 缺口固定成验收标准。U19 通过后，团队可能误以为 AE22 已经被 eval 覆盖；实际只覆盖了 mock 文档一致性，没有覆盖真实证券代码端到端能力。

建议修复：把 `SPC-001` 拆成两个 case：`SPC-001a synthetic skeleton dry-run` 只验证骨架可写和边界标注，不标 AE22 全量通过；`SPC-001b real/sanitized securities e2e` 才覆盖 AE22，必须包含可复现项目路径、实际 scan 输出、端负责人 review 反馈和 5 个章节状态抽样。

### P1. Orchestration PASS case 允许 synthetic-poc 进入 merge，且假定 pending 引用正确，掩盖 U18 的 pending 断链

`ORC-001` 的 Given 将 `evidence_tier_labeled: true`、`A4_pending_refs_valid: true` 和 `B_avg_depth_score: 0.538` 写为可接受输入：`skills/project-standard-extractor/evals/dimension-framework/orchestration-cases.md:15` 到 `:28`。Then 又明确总裁决 PASS、merge-coordinator 被允许继续执行，并称 `synthetic-poc` 的低深度分不阻塞：`:34` 到 `:40`。

这与 U18 当前事实冲突：`engineering-standards/09-industry/pending-confirmation.md:1` 到 `:3` 写“当前暂无待确认规则”，但 U18 标准和 report 内含多处 owner 待确认。synthetic-poc 也明确“不代表真实 evidence 团队规范”，不应成为默认可 merge 的质量门禁通过样例。

影响：U19 的编排 eval 会把“pending 引用实际为空”和“synthetic-poc 可合并”都放行，后续 U22 smoke test 即使没有真实 owner 确认、没有 pending 文件同步，也可能显示 quality-gate PASS。

建议修复：`ORC-001` 应区分 `poc-draft-pass` 与 `merge-pass`。synthetic-poc 最多允许生成 draft/advisory 产物，不允许作为 active 或 merge-complete 成功样例；`A4_pending_refs_valid` 必须通过实际读取 `pending-confirmation.md` 和 report 的 `owner_confirmations[]` 对齐来判定。

### P2. End adapter dispatch case 引用不存在的 skeleton 文件名，无法按当前骨架池执行

`EAD-001` 的骨架池写了 `app-client/rn-cross-platform-skeleton.md` 与 `backend/java-spring-skeleton.md`：`skills/project-standard-extractor/evals/dimension-framework/end-adapter-dispatch-cases.md:37` 到 `:43`，Then 也要求选择这两个文件：`:52` 到 `:54`，回归断言还 grep `rn-cross-platform-skeleton` 和 `java-spring-skeleton`：`:68` 到 `:72`。

当前实际骨架池没有这两个文件；存在的是 `skills/project-standard-extractor/templates/skeletons/app-client/hybrid-bridge-skeleton.md` 和 `skills/project-standard-extractor/templates/skeletons/backend/java-skeleton.md`。U4 增量也把 RN/H5 嵌入原生壳场景落在 hybrid-bridge skeleton，而不是 rn-cross-platform skeleton。

影响：EAD-001 作为 AE17 的唯一 case，会要求实现选择不存在的文件。真实 generation 若按当前骨架池正确选择 `hybrid-bridge-skeleton.md` / `java-skeleton.md`，反而会被 U19 eval 判失败。

建议修复：把 EAD-001 的 `sub_domain` 与 skeleton 文件名同步到当前骨架池：RN/H5 跨端用 `hybrid-bridge-skeleton.md`，Java 后端用 `java-skeleton.md`；如果产品确实需要 `rn-cross-platform` 和 `java-spring` 作为显式子领域，应先补 skeleton 文件与 planner/generation 映射。

### P2. U19 README 把范围扩到 AE23-AE25，但复用了已知错误的 force-rebuild case

U19 计划范围是 AE7-AE22：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1529` 到 `:1531`，文件清单也只列维度框架相关 case：`:1535` 到 `:1545`。当前 README 却写 “AE → Case 完整映射（AE7-AE25）”，并把 `force-rebuild-cases.md` 的 AE23-AE25 纳入总索引：`skills/project-standard-extractor/evals/dimension-framework/README.md:20` 到 `:42`。

这些 FRC case 仍包含前几轮已指出的错误口径：`FRC-007` 固化 `cp -a .local-backups/.../. engineering-standards/...` 的非原子回滚路径：`skills/project-standard-extractor/evals/dimension-framework/force-rebuild-cases.md:255`；`FRC-009` 明确写 “domain 是隔离边界，不会因为一个 domain 失败回滚另一个 domain 已完成的变更”：`:309` 到 `:326`，与 U24 计划的 multi-domain all-or-nothing 语义冲突。

影响：U19 README 作为 eval 套件入口会把已知错误的 force-rebuild case 重新包装成“完整映射”。后续执行者从 README 跑全套回归时，会把 U24/U25 的错误语义再次验收为正确。

建议修复：U19 README 先只声明 AE7-AE22 的完成状态；AE23-AE25 应标注为 `known failing / pending correction`，或在修正 FRC-007/FRC-009 后再纳入完整映射。

## 验证记录（第十轮）

- 已重新读取计划完成状态：U1-U19、U23-U26 标记 `Status: ✅ 已完成`，U20-U22、U27 尚未标记完成。
- U19 文件存在性：`evals/dimension-framework/README.md` 以及 9 个维度框架 case 文件存在；目录内另有 U25 的 `force-rebuild-cases.md`。
- 覆盖检查：README 映射 AE7-AE25 共 19 条；U19 计划要求 AE7-AE22 共 16 条。新 case 均采用 Given / When / Then 结构。
- 字段检查：多个 case 使用 `jq '.evaluations[] ...'` 读取 activation-report；同目录 force-rebuild case 使用 `.dimensions[]`，字段口径不一致。
- 骨架池检查：实际存在 `app-client/hybrid-bridge-skeleton.md` 与 `backend/java-skeleton.md`，不存在 `app-client/rn-cross-platform-skeleton.md` 或 `backend/java-spring-skeleton.md`。
- 本轮仍为 report-only 审查，未修改被审源码，未运行完整项目测试。

## 第十一轮 Findings（U20-U21）

### P1. U20 复用的证券 walkthrough 仍没有端负责人 review 反馈，未满足 U20 自身归档要求

U20 Approach 明确要求 `golden-sample-securities-run.md` 包含“输入 / 调用 / 产物片段 / 关键决策 / 端负责人 review 反馈”：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1581` 到 `:1583`。这也是 U18 的 PoC 通过条件之一。

当前 `skills/project-standard-extractor/examples/phase-2/golden-sample-securities-run.md:159` 到 `:181` 只有 `review-and-quality-gate agent` 的自评摘要，`rg review_feedback|端负责人` 没有找到真实 reviewer、reviewed_at、结论或反馈原文。文件仍写 `evidence_tier: synthetic-poc`，且 `:14` 到 `:16` 明确“不代表真实 evidence 团队规范”。

影响：U20 把 U18 的归档文件纳入 phase-2 walkthrough 套件后，仍未补齐最关键的人类 review 证据。后续用户按 README “先读 golden sample” 会看到一个完整故事，但它缺少 U20 承诺的“内容准确 / 骨架可用”外部确认。

建议修复：在 `golden-sample-securities-run.md` 增加 `review_feedback` 段，至少包含 reviewer、角色、reviewed_at、结论、保留问题、是否允许 draft/active、以及 synthetic-poc 边界声明；没有负责人反馈时，应在 U20 验证里标为未满足，而不是 PASS。

### P1. U20 incremental walkthrough 使用旧的 diff 输入字段和 `evaluations[]` 口径，继续偏离 U14/U17 契约

U14 和 `input-guide.md` 已把 diff 输入收敛到 `diff_baseline.{type, ref}`：`skills/project-standard-extractor/input-guide.md:48` 到 `:64`。U20 的 `incremental-mode-walkthrough.md` 却使用 `diff_scope: auto` 与 `prior_run_id`：`skills/project-standard-extractor/examples/phase-2/incremental-mode-walkthrough.md:19` 到 `:27`，这两个字段不在当前 input-guide 的正式字段示例里。

同一 walkthrough 还把无状态变化的条目写入 `evolution.transitions`，例如 `EA-Client-01` 和 `EA-Client-02` 都是 `state_before=activated`、`state_after=activated`、`changed=false`：`:83` 到 `:95`、`:113` 到 `:124`。但 U19 incremental case 写的是“若无变更则不新增条目”，README 也提醒“只有状态变更的维度才写入” `evolution.transitions[]`：`skills/project-standard-extractor/examples/phase-2/README.md:50` 到 `:54`。

最后，U20 仍把 activation report 更新描述为 “2 条 evaluations 更新”：`incremental-mode-walkthrough.md:138` 到 `:143`、`:181` 到 `:183`，继续沿用前一轮已指出的 `evaluations[]` 非主契约口径。

影响：U20 作为用户教程会教用户传入无效/旧字段，并教实现把 unchanged depth 更新放进 `evolution.transitions`。后续 U22 若按这个 walkthrough 验证，会和 input-guide、U19 case、activation-report 主契约互相打架。

建议修复：把 walkthrough 输入改成 `diff_baseline`，或明确 `prior_run_id` 如何被 intake 转译为 `diff_baseline.ref`；`evolution.transitions[]` 只记录状态变化，depth/evidence 变化另放 `evaluations_updated[]` 或 `dimensions[].last_evaluated_at`；所有示例统一读写 `dimensions[]`。

### P1. U21 文档收尾没有贯通 U26 的 `list`，入口文档仍拒绝 README/usage-guide 已公开的模式

U21 目标是做 README、CHANGELOG、workflow 和一致性核查收尾：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1602` 到 `:1629`。但 U26 已把 `output_action=list` 作为正式能力写入 `usage-guide.md:157` 到 `:176`，Host Adaptation Matrix 也把 list 作为一列：`:178` 到 `:184`。

顶层入口仍未同步：`skills/project-standard-extractor/SKILL.md:24` 的枚举只有 `append | force-rebuild | restore | pin | unpin`；`SKILL.md:27` 的 domain 必填范围也只含 `{force-rebuild, restore, pin, unpin}`。`input-guide.md:74` 到 `:90` 同样没有 `list`，互斥/强制边界 `:94` 到 `:97` 也没有把 list 纳入只读 domain 必填分支。

影响：U21 声称 grep 一致性核查通过，但核心调用协议仍不一致：README/usage-guide/backup-manager/script 公开了 list，SKILL/input-guide/intake 层却不知道 list。用户照 U20/U25/U26 文档执行 list 仍可能在入口层被拒绝。

建议修复：U21 收尾必须把 `list` 纳入 SKILL、input-guide、intake-and-scope、README 能力清单和脚本 README 的同一套调用协议；`list` 需要 `domain`，不需要 `restore_from`，只读，不取 lock，不写 CHANGELOG。

### P2. U21 README 把未完成的 U27 EA-Doc 能力列入 Phase 2 能力清单，且引用的配置文件不存在

当前计划显示 U27 仍未完成；U27 说明也是 phase 2 最后任务，要在 U18-U22 集成验证后启动：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1862` 到 `:1868`、`:1990`。但 U21 README 已在 Phase 2 能力清单中公开 “文档源萃取（EA-Doc-*）”，入口文档写成 `config/dimension-framework/dimensions-ea-doc.yaml`（U27 产出）：`skills/project-standard-extractor/README.md:41` 到 `:52`。

本轮检查 `skills/project-standard-extractor/config/dimension-framework/dimensions-ea-doc.yaml` 不存在。把未完成能力放入主能力表，会让用户以为 EA-Doc 已可用；这也和“只审查已完成 U”的开发节奏冲突。

建议修复：在 U27 完成前，README 主能力清单不要把 EA-Doc 放在正式可用能力里；可以移到 “Upcoming / planned” 小节，明确 `status: pending U27`，并不要引用不存在的配置文件作为入口。

### P2. U21 的 CHANGELOG 更新没有按计划生成聚合 phase 2 release 条目

U21 计划要求 `CHANGELOG.md` 追加一条聚合变更记录，示例为 `feat(project-standard-extractor): phase 2 维度框架与三态激活...`：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1613` 到 `:1620`。

当前 `CHANGELOG.md` 有逐 unit 条目和 U21 条目：`CHANGELOG.md:105`、`:106`，但没有计划示例中的聚合 `feat(project-standard-extractor): phase 2...` 条目。U21 条目只描述 README / installation 收尾和 grep 核查，不等价于对目标仓库用户可见 release 的聚合说明。

影响：如果 U21 是 phase 2 文档收尾和发布口径来源，缺少聚合条目会让最终 changelog 只能靠散落的 U1-U26 逐项记录阅读；也不满足计划要求的 “target_repo CHANGELOG.md 含新条目，遵循现行格式” 的具体内容。

建议修复：追加一条聚合 release 条目，或明确修改 U21 plan，说明逐 unit changelog 已替代聚合 release。若保留聚合条目，应使用当前 host developer profile `leokuang`，并标注 `(user-visible)`。

## 验证记录（第十一轮）

- 已重新读取计划完成状态：U1-U21、U23-U26 标记 `Status: ✅ 已完成`，U22、U27 尚未标记完成。
- U20 文件存在性：`examples/phase-2/README.md`、`golden-sample-securities-run.md`、`incremental-mode-walkthrough.md`、`cross-project-walkthrough.md` 存在；目录内还存在 U25 的 `force-rebuild-walkthrough.md`。
- U21 文件检查：`README.md` 与 `installation-or-consumption.md` 已更新 Phase 2 / 三态消费内容；`SKILL.md` 与 `input-guide.md` 仍未包含 `output_action=list`。
- EA-Doc 检查：`skills/project-standard-extractor/config/dimension-framework/dimensions-ea-doc.yaml` 不存在，U27 仍待监听。
- 本轮仍为 report-only 审查，未修改被审源码，未运行完整项目测试。

## 第十二轮 Findings（U22）

### P1. U22 把结构性断言当作完整端到端 smoke PASS，未满足集成验证目标

U22 Goal 要求“跑一次完整端到端萃取，验证 phase 2 全链路工作”，并要求 8 个 smoke 场景跑完都产出规范文档与 activation-report、Quality Gate 决策合理、性能基线达标：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1639` 到 `:1683`。

当前 `skills/project-standard-extractor/examples/phase-2/integration-validation-report.md:7` 到 `:9` 标记 `overall_result: PASS`、`scenarios_passed: 8`。但同文件 `:14` 到 `:16` 明确说明“由于无真实项目运行环境”，验证方式只是“结构验证 + 配置断言 + 样例文档存在性检查”。这不是 U22 要求的端到端萃取 smoke test，也不能证明 dimension-activator、facts、generation、review、merge、backup-manager 在同一次真实运行里完成 handoff。

影响：U22 会把设计文档齐全误报成全链路可运行，掩盖前面已发现的 activation-report 契约、入口协议、force-rebuild、restore/pin 等集成断裂。最终全量复审前不能把该 8/8 PASS 当作真实验收基线。

建议修复：把当前报告降级为 “design/structure validation”，`overall_result` 不应为 smoke PASS；补跑至少一个真实或脱敏项目端到端 run，记录输入路径、run_id、实际生成文件、activation-report schema 校验、Quality Gate 输出、merge summary 和失败限制。无法真实运行的场景应标为 BLOCKED / NOT_RUN，而不是 PASS。

### P1. force-rebuild、restore、pin 场景没有实际执行关键行为，却被标为 PASS

U22 场景 7 要求验证 safeguard 三步、atomic rename 备份、重生、4 项确定性校验、CHANGELOG 自动追加，并故意触发 Quality Gate fail 验证 rollback、failure.log、CHANGELOG 不追加和 lock 释放；场景 8 要求 pinned 备份经过连续 6 次 force-rebuild 后仍保留，并验证 restore 后 domain 与 pinned 备份 byte-level 一致。

当前报告只用 grep / ls 检查这些文件和文档是否存在：`integration-validation-report.md:120` 到 `:133` 检查 backup-manager、脚本、prompt、case 和 walkthrough；`:137` 到 `:149` 检查 pin/unpin/list 字样和 usage 文档。没有执行 `scripts/backup.sh`、没有跑 `force-rebuild-validate.sh`、没有制造失败回滚、没有 `diff -r` byte-level 比对、没有验证 CHANGELOG success/failure 分支，也没有验证 lock 释放或 `--keep=N + pinned` 保留计数。

影响：这正好绕过了 U23-U26 中风险最高的行为边界。前面已记录的 lock 失效、schema 校验降级、CHANGELOG 失败回滚非原子、pin/unpin 无 lock/schema 等问题，都不会被这种 grep 型“集成验证”发现。

建议修复：为场景 7/8 建立最小临时 domain fixture，实际执行 dry-run、backup、force-rebuild validate、失败 rollback、pin、unpin、list、restore；验证输出包括退出码、manifest、failure.log、lock 生命周期、CHANGELOG diff、`diff -r` 结果和保留计数。未执行前这两个场景应标为 NOT_RUN。

### P1. U22 继续验收已知错误契约，导致集成验证反向固化漂移

当前集成报告包含多个已在前轮审查中确认有问题的契约，但仍标 PASS：

- `integration-validation-report.md:80` 用 `jq '.evaluations | length'` 验证证券 16 维，而 U17/U18/U19 已反复记录 `dimensions[]` 才应是 activation-report 主字段。
- `integration-validation-report.md:30` 声称 `backend/java-spring-skeleton.md` 存在；实际骨架池只有 `templates/skeletons/backend/java-skeleton.md`。
- `integration-validation-report.md:47` 用 `rn-cross-platform` 证明 app-client dispatch；实际骨架池没有 `app-client/rn-cross-platform-skeleton.md`，只有 `app-client/hybrid-bridge-skeleton.md`。
- `integration-validation-report.md:73` 到 `:86` 把 `evidence_tier=synthetic-poc` 的证券 PoC 标为行业 adapter 端到端 PASS，仍未补真实或脱敏证券代码与端负责人 review。

影响：U22 本应作为集成层拦截 U17-U21 的契约漂移，现在反而把 `evaluations[]`、不存在的骨架命名、synthetic mock PASS 等问题纳入“全链路通过”结论，后续修复会更难界定权威契约。

建议修复：先统一 activation-report schema、骨架文件命名和证券 PoC 验收边界，再重写 U22 断言；集成验证必须失败在不存在文件、非主契约字段、synthetic-only 不能代表 AE22 的场景上。

### P2. 性能基线只是设计目标，没有实测数据却进入总 PASS

U22 通过条件要求性能基线：单项目全量 < 10 分钟、增量 < 3 分钟、跨项目 < 25 分钟、force-rebuild < 12 分钟、restore < 2 分钟、pin/unpin/list < 5 秒。

当前 `integration-validation-report.md:165` 到 `:174` 标题写的是“性能基线（设计目标）”，`:183` 也承认“性能基线未实测”。但 frontmatter 和总结仍给出 `8/8 PASS`：`:188` 到 `:202`。

影响：性能门槛没有任何 wall-clock、项目规模、机器环境或命令输出，无法判断是否满足 U22 的 smoke test 通过条件。把设计目标计入 PASS 会让后续优化/回归没有可比较基线。

建议修复：至少记录每个实际场景的 `started_at`、`ended_at`、duration、项目文件数、命令/agent 阶段耗时和是否达标；未实测时性能项应从 PASS 中剔除并标为 NOT_MEASURED。

### P2. GitNexus ready 路径和 `list` 入口完整性只做文档存在性检查，未覆盖真实入口

U22 要求 GitNexus 可用 / 不可用各跑一次，且场景 8 覆盖 restore + pin 模式。当前 GitNexus ready 路径只是“假设路径” eval case：`integration-validation-report.md:153` 到 `:161`，`:182` 还承认 GNC-001 未实际消费。`list` 场景也只 grep 文档和脚本：`:143` 到 `:149`。

同时当前入口仍显示 `SKILL.md:24` 的 `output_action` 枚举缺 `list`，`input-guide.md:85` 到 `:97` 也没有把 `list` 纳入字段、domain 必填和互斥规则。U22 的 grep 没有发现这一点。

影响：GitNexus ready 分支和 list 顶层入口仍可能在真实调用时不可达，但 U22 已把它们计入 PASS。用户照 README/usage-guide 执行 list 或启用 GitNexus ready 路径时仍会遇到入口层拒绝或只能走 fallback。

建议修复：GitNexus ready 至少用一份真实 `graph-facts.v1` fixture 或已 bootstrap 项目跑通一次；list/pin/unpin/restore 验证必须从 SKILL 调用协议和 intake 输入开始，而不是只检查脚本文本。

## 验证记录（第十二轮）

- 已重新读取计划完成状态：U1-U26 标记 `Status: ✅ 已完成`，U27 尚未标记完成。
- U22 文件存在性：`skills/project-standard-extractor/examples/phase-2/integration-validation-report.md` 存在，frontmatter 标记 `overall_result: PASS`、`scenarios_passed: 8`、`scenarios_total: 8`。
- U22 报告自述：验证方式为结构性断言、配置断言和样例文档存在性检查；无真实项目运行，GitNexus ready 未实际触发，性能未实测，U27 未纳入。
- 骨架池交叉检查：实际存在 `backend/java-skeleton.md` 与 `app-client/hybrid-bridge-skeleton.md`；不存在 U22 报告引用的 `backend/java-spring-skeleton.md` 和 `app-client/rn-cross-platform-skeleton.md`。
- 入口协议检查：`SKILL.md` 与 `input-guide.md` 仍未包含 `output_action=list`，U22 场景 8 的 list PASS 未覆盖顶层调用入口。
- 本轮仍为 report-only 审查，未修改被审源码，未运行完整项目测试。

## 第十三轮 Findings（U27）

### P1. `dimensions-doc.yaml` 不是有效 YAML，EA-Doc 维度池无法被加载

U27 Verification 要求 “EA-Doc 5 维度全部就绪（dimensions-doc.yaml schema valid）”：`docs/plans/2026-05-24-001-feat-skill-phase-2-dimension-framework-plan.md:1987`。当前 `skills/project-standard-extractor/config/dimension-framework/dimensions-doc.yaml:93` 到 `:98` 中包含：

```yaml
- "*.graphql" / "schema.graphql"
```

这不是合法 YAML。使用 `python3 -c 'import yaml; yaml.safe_load(...)'` 读取该文件会在第 97 行报 `expected <block end>, but found '<scalar>'`。更早的 loader / schema 校验阶段会直接失败，U27 的 5 个 EA-Doc 维度无法进入 dimension-activator。

影响：U27 虽然标记完成，但新增维度池在最基础的配置解析阶段不可用；任何依赖 `dimensions-doc.yaml` 的 doc-source 运行都会中止或跳过 EA-Doc。

建议修复：先把 YAML 修成可解析结构，例如拆成两个 list item；然后用同一条配置校验命令纳入 U27 验证记录，不要只写 walkthrough。

### P1. U27 新配置与现有 dimension / activation schema 形状不兼容

即使修正 YAML 语法，当前 U27 文件仍不符合既有 schema。`schema.json:7` 要求根字段 `layer` 和 `dimensions`，`dimensions` 必须是以 dimension_id 为 key 的 object；`schema.json:12` 的 `layer` 只允许 `common / extension / industry`。但 `dimensions-doc.yaml:1` 到 `:9` 使用 `schema / domain / dimension_group / activation_mode / default_state`，没有 `layer`，且 `dimensions` 是 list。

`activation-rules.schema.json:7` 要求根字段 `end / version / dimensions`，`end` 只允许 `app-client / frontend / backend / industry`，signal `type` 只允许 `grep / ast / file_existence / dependency / gitnexus`。但 `activation-rules-doc.yaml:1` 到 `:15` 使用 `schema / domain / dimension_group / global`，没有 `end`；`dimensions` 是 list；信号类型是 `doc-content`；版本是 `1.0.0` 而不是 `vN.N.N`。实测 jsonschema 校验返回 5 类错误：缺 `end`、根字段 additionalProperties、`dimensions` 非 object、`subdomain_signals/wiki-export` 非 array、`version` 格式不匹配。

影响：U27 并不是“新增一个维度组”，而是引入了第三套未被 schema / loader 承认的配置格式。现有 U1/U3 校验链路不会接受它，dimension-activator 也无法可靠合并 EA-Doc 与代码维度。

建议修复：二选一收敛。若 EA-Doc 应是新 layer，就先扩展 `schema.json`、`activation-rules.schema.json`、loader 和所有 config README；若复用现有 schema，就把 `dimensions-doc.yaml` 改为 `layer: extension` 或新增受控 `layer: doc`，把 `dimensions` 改成 object，并把 activation rules 改成既有 `end/version/dimensions{}` 形状。

### P1. doc-source-scanner 接入顺序与主 workflow 相反，EA-Doc 信号来不及参与激活

U27 计划说 doc-source-scanner 与 facts-and-classification 串接，并输出 `doc-inventory.json` 供 dimension-activator 消费。当前实现把调用写在 `facts-and-classification.md:252` 到 `:260`：在代码事实萃取之前调用 doc-source-scanner，追加 `doc_facts[]`，再让 dimension-activator 消费。

但主编排 `workflow.md:40` 到 `:55` 和 `SKILL.md:51` 到 `:66` 仍是 `profile-and-batch-planner -> dimension-activator -> facts-and-classification -> generation`。也就是 dimension-activator 运行时，facts-and-classification 还没执行，`batch_facts.doc_facts[]` 不存在。`dimension-activator.md:257` 又写“当 batch_facts 含 doc_facts[] 时”才追加 EA-Doc 评估。

影响：EA-Doc 激活链路在真实 workflow 中不可达。即使 doc-source-scanner 文件存在，activator 也拿不到 doc-content signal；后续 generation 只能在 activation-report 已含 EA-Doc 结果时工作，但该结果不会由当前顺序产生。

建议修复：把 doc-source-scanner 明确插入 dimension-activator 之前，作为 profile/planner 后的独立阶段或 activator 内部前置信号执行器；同时修订 workflow、SKILL、facts、activator 的 handoff，保证唯一数据流不是循环依赖。

### P1. U27 继续把 EA-Doc 写入 `evaluations[]`，没有回到 activation-report 主契约

前面 U17/U18/U19/U22 已多次记录 activation-report 主字段应统一到 `dimensions[]`，而 `evaluations[]` 是漂移字段。U27 新增逻辑仍在 `dimension-activator.md:270` 写“评估结果追加到 `activation-report.json` 的 `evaluations[]`”；`doc-source-cases.md:45` 到 `:47`、`:76` 到 `:77`、`:111` 也全部用 `jq '.evaluations[] ...'` 验收。

影响：U27 没有修复主契约漂移，反而把新维度组继续绑定到错误字段。generation 的 EA-Doc 扩展 `generation.md:638` 只说读取 activation-report 中 `EA-Doc-*` 评估，未明确 `dimensions[]`，因此真实消费者仍可能找不到 EA-Doc 状态。

建议修复：先补齐唯一权威 `activation-report-schema.json`，把 EA-Doc 写入 `dimensions[]`，再把 eval、walkthrough、generation、review、merge 的读取点全部替换为同一字段；如需保留 `evaluations[]`，必须声明为兼容镜像并由 schema 约束。

### P2. README 对外入口仍引用不存在的 `dimensions-ea-doc.yaml`

U21 已发现 README 提前引用 `config/dimension-framework/dimensions-ea-doc.yaml`。U27 完成后，实际新增文件是 `dimensions-doc.yaml`，但 `skills/project-standard-extractor/README.md:51` 仍写入口文档为 `config/dimension-framework/dimensions-ea-doc.yaml`。

影响：用户按 README 查找 EA-Doc 配置会找不到文件；这说明 U27 没有回扫 U21 公开入口，也削弱了 “文档源萃取能力可用” 的对外可信度。

建议修复：统一命名。要么把文件改名为计划 / README 中的 `dimensions-ea-doc.yaml`，要么更新 README、plan、全局说明和所有 grep 引用为 `dimensions-doc.yaml`。

### P2. doc-source-scanner 的敏感文件策略与 eval 期望不一致

`doc-source-scanner.md:57` 到 `:67` 写文件枚举时排除 sensitive patterns，heading 提取时“不读取 heading 以外内容”；`doc-source-cases.md:129` 到 `:141` 却期望 `docs/secrets/api-keys.md` 出现在 `doc-inventory.json`，并带 `read_blocked: true`。这两种行为不同：排除文件意味着 inventory 没有条目；记录 `read_blocked` 意味着必须枚举敏感路径但不读内容。

影响：敏感文件测试会在实现层没有确定行为。若按 scanner 文档排除，eval 失败；若按 eval 记录敏感 path，又违反“排除 sensitive patterns”的当前描述。更严重的是 Wiki/Confluence 导出可能含内部信息，策略必须明确“是否记录路径”和“记录到什么粒度”。

建议修复：把安全策略写成单一契约：敏感路径可记录 `path_class` / redacted path hash，但不记录完整敏感文件名；或明确 inventory 包含完整路径但不读内容。然后同步 doc-source-scanner、eval、usage-guide 和全局说明。

## 验证记录（第十三轮）

- 已重新读取计划完成状态：U1-U27 全部标记 `Status: ✅ 已完成`。
- U27 文件存在性：`dimensions-doc.yaml`、`activation-rules-doc.yaml`、`doc-content-signals.md`、`agents/doc-source-scanner.md`、5 个 doc skeleton、`doc-source-cases.md`、`doc-source-walkthrough.md`、`engineering-standards/00-global/ea-doc-dimensions.md` 存在。
- YAML / schema 校验：`dimensions-doc.yaml` 在 YAML 解析阶段失败；`activation-rules-doc.yaml` YAML 可解析但不符合 `activation-rules.schema.json`。
- 主链路检查：`workflow.md` / `SKILL.md` 仍把 dimension-activator 放在 facts-and-classification 前；U27 的 doc-source-scanner 调用却写在 facts-and-classification 中，形成反向依赖。
- 入口检查：README 仍引用不存在的 `config/dimension-framework/dimensions-ea-doc.yaml`；实际文件为 `dimensions-doc.yaml`。
- 本轮仍为 report-only 审查，未修改被审源码，未运行完整项目测试。

## 最终全量复审结论

**结论：当前 Phase 2 Dimension Framework 不建议发布 / 合并为可用能力。** 计划中 U1-U27 均已标记完成，但关键链路仍存在 P1 级阻断：配置 schema 不可加载、主数据流前后倒置、activation-report 主契约漂移、force-rebuild / restore / pin 行为未被真实验证、U22 集成验证以结构断言误报 8/8 PASS、U27 EA-Doc 维度组在 loader 和 workflow 层不可达。

### 阻断类问题

1. **配置与 schema 基座不可靠**：U1 未覆盖 13 个 Layer 1 common 维度；U27 `dimensions-doc.yaml` 无法解析；U27 activation rules 不符合现有 schema。
2. **主 workflow 数据流未收敛**：U5/U6/U11 把原计划的 `facts -> signal_hits -> dimension-activator` 反转；U27 又要求 facts 先产出 `doc_facts[]` 给 activator，和当前编排冲突。
3. **activation-report 契约未统一**：`activation-report-schema.json` 缺失或未成为强制入口，`dimensions[]` / `evaluations[]` / `schema` / `schema_version` 持续漂移，eval 和 examples 反复验收错误字段。
4. **用户可见入口不一致**：`output_action=list` 未贯通 SKILL / input-guide / intake；U27 README 引用不存在的 EA-Doc 配置文件；recommended_action 枚举仍有多套拼写。
5. **高风险行为缺真实验证**：U22 没有实际跑端到端 smoke；force-rebuild / rollback / restore / pin / list / GitNexus ready / 性能基线均缺真实执行证据。

### 建议修复顺序

1. 先收敛机器契约：维度池 schema、activation-rules schema、activation-report schema、backup manifest schema，确保所有新增 yaml/json 可被同一套 loader 校验。
2. 再收敛 workflow：明确唯一顺序，尤其是 code signal、doc signal、facts、dimension-activator 的先后关系；删除循环依赖和重复 state 判定。
3. 然后修复入口面：SKILL / input-guide / usage-guide / README / workflow / scripts README 使用同一组枚举、文件名和字段。
4. 最后重跑真实集成验证：至少一个 backend、一个 app-client、一个 frontend、一个证券或脱敏行业样例、一个 EA-Doc 样例、一次 force-rebuild 失败回滚、一次 restore/pin/list 和 GitNexus ready/fallback 双路径；把命令、duration、产物路径和 schema 校验结果写回 integration report。

### 复查清单

- 13 个 Layer 1 维度、`signal_hits` 数据流、baseline pending 门禁、batch-plan 模板、activation-report schema、U8/U10 orchestrator prompt。
- Quality Gate 双门禁外部 prompt/schema、recommended_action 枚举、持久化 `evidence/dimension-activation-report.json`、GitNexus readiness 的 `capabilities.query_global_graph` / freshness / `worktree_status_hash` 校验。
- diff-scoper 维度 ID 映射、cross-project-aggregator 顶层编排与 schema 字段一致性、U17 跨项目主 report 的 activation-report.v1 规范化。
- U23-U26 force-rebuild lock / restore payload / destructive domain 校验、schema 校验硬失败、CHANGELOG 失败回滚顺序、`in-progress.lock` 治理、多 domain transaction、pin/unpin 锁与 manifest schema 校验、list 入口贯通。
- U18-U22 synthetic PoC 与真实 AE22 验收边界、owner review、路径同步、eval 字段口径、端 skeleton 文件名、walkthrough 输入字段、性能和端到端 smoke 真实性。
- U27 EA-Doc YAML/schema、doc-content signal schema、doc-source-scanner 接入顺序、`dimensions[]` 主契约、README 文件名、敏感文档 inventory 策略。

## 问题归并视图

原始审查共记录 70 条 finding（P1 50 条、P2 20 条）。其中多条属于同一根因在不同 unit、文档、eval 和 walkthrough 中的重复暴露；修复时不建议逐条零散处理。建议合并为 13 个主修复包，原始 finding 保留为每个修复包的验收清单。

| 修复包 | 严重度 | 合并处理范围 | 覆盖原始 finding |
| --- | --- | --- | --- |
| F1. 维度池与 activation-rules schema 统一 | P1 | 收敛 common / extension / industry / doc 维度池形状、ID 命名、version 格式、doc-content signal schema；补齐 13 个 Layer 1 维度；让所有 yaml/json 能被同一 loader 校验。 | U1 Layer 1 缺失、U14 维度 ID 映射、U25 baseline 示例漂移、U27 `dimensions-doc.yaml` 非法 YAML、U27 activation-rules-doc schema 不兼容 |
| F2. activation-report v1 契约统一 | P1 | 补可执行 `activation-report-schema.json`；统一 `dimensions[]`、`schema_version`、summary、last_commit、cross-project 主 report、EA-Doc 写入字段；废弃或镜像 `evaluations[]`。 | U5/U10/U15/U17/U18/U19/U20/U22/U27 中所有 activation-report schema / `dimensions[]` / `evaluations[]` / `schema` vs `schema_version` / 持久化问题 |
| F3. 主 workflow 与 agent handoff 重排 | P1 | 明确 profile/planner、doc-source-scanner、signal scan、facts、dimension-activator、generation 的唯一顺序，删除循环依赖和本地重算 state。 | U5/U6 数据流反向、U11 workflow 固化反向、U15 aggregator 未插入顶层、U27 doc-source-scanner 晚于 activator |
| F4. 三态与 owner-confirmation 状态机 | P1 | 统一 baseline / activated / pending-confirmation / shallow / candidate 的入口、生成、quality gate、merge、pending-confirmation.md 和 owner review 归档。 | baseline 无 evidence 门禁、U16 shallow 口径、U18 pending 断链、U19 orchestration PASS 掩盖 pending、U20 缺 owner review |
| F5. Quality Gate 与 `recommended_action` 枚举 | P1 | 统一 frontmatter-format、quality-gate.md、quality-review prompt、review agent、merge-coordinator 的 action/status 枚举；修复段级解析。 | U9 外部门禁旧契约、U9/U12 枚举漂移、U16 `keep-draft-low-coverage`、U24 Quality Gate grep 脆弱 |
| F6. 用户入口与文档文件名一致性 | P1 | 统一 SKILL / input-guide / usage-guide / README / workflow / scripts README 的字段、枚举、文件名、模式互斥规则。 | U12 usage-guide 旧口径、U14 diff 优先级矛盾、U21/U25/U26/U22 `list` 入口未贯通、U27 README 引用 `dimensions-ea-doc.yaml` 不存在、U26 scripts README 未同步 |
| F7. GitNexus readiness 与 evidence source | P2 | 统一 readiness 条件、mtime 方向、`query_global_graph`、`worktree_status_hash`、fallback limitations、`source: gitnexus` 输出。 | U13 readiness 缺能力/状态 hash 且 mtime 条件反、U13 signal 示例缺 source、U22 GitNexus ready 未实跑 |
| F8. diff / cross-project / path privacy | P1 | 统一 diff-scoper 字段和维度映射；接入 cross-project-aggregator；规范 unified map 与 divergence 输出，避免泄露本地绝对路径。 | U14 diff-scoper ID、U14 intake 优先级、U15 aggregator 未接入、U15 schema 字段漂移、U15 路径泄露 |
| F9. force-rebuild / backup / restore / rollback 安全链路 | P1 | 用真实 lock、path traversal 防护、manifest 写入、atomic rename rollback、CHANGELOG helper 原子失败处理、in-progress.lock、multi-domain transaction 和 validate.sh 统一实现。 | U23 lock/restore/domain/manifest，U24 schema 降级/CHANGELOG 回滚/in-progress.lock/multi-domain/validate，U25 force-rebuild eval 与 walkthrough 固化错误语义，U22 场景 7 未实跑 |
| F10. pin / unpin / list / backup manifest CLI | P1 | 将 list 纳入入口；pin/unpin 获取 domain lock；写前后 schema 校验；backup-id UTC-ts 校验；脚本文档同步；与 force-rebuild `--keep` 互斥一致。 | U25 list 超前暴露、U26 list 入口、pin/unpin 无 lock、manifest 未校验、backup-id 未校验、scripts README 未同步、U22 list 只做 grep |
| F11. evals / walkthrough / integration-report 重写 | P1 | 把 eval 和 example 从“验收旧/错契约”改为“拦截错契约”；移除不存在 skeleton、旧 diff 字段、错误 validate 参数、结构断言冒充 smoke 和设计目标冒充性能。 | U19 eval 读取 `evaluations[]`、端 adapter skeleton 文件名、force-rebuild case 错误；U20 incremental walkthrough 旧字段；U22 结构性断言 8/8 PASS、性能未实测 |
| F12. 证券 PoC 改为真实或脱敏端到端验收 | P1 | 把 synthetic-poc 降级为 skeleton dry-run；新增真实/脱敏证券项目跑批、actual signal scan、状态抽样准确率、owner review 反馈、路径同步。 | U18 synthetic mock 冒充 AE22、U18 owner review 缺失、U18 04/09-industry 路径漂移、U19 AE22 case、U20 securities walkthrough、U22 证券 PoC PASS |
| F13. EA-Doc 维度组重新接入主框架 | P1 | 在 F1/F2/F3 后重做 EA-Doc：合法 schema、doc-content 信号接入 activator 前置、写入 `dimensions[]`、README 文件名一致、敏感文档 inventory 策略明确、mock/真实样例跑通。 | U27 6 条 finding；同时依赖 F1/F2/F3/F6；EA-Doc 最小契约用例随 F13 补齐，最终集成回归归入 F11 |

### 合并后的修复优先级

1. **第一批：F1 → F2 → F3 → F4**。先串行修机器契约、activation-report、主数据流和 baseline/default_content 状态机；N-01/N-02 未被端到端验证关闭前，Phase 2 主管线保持 blocked。
2. **第二批：F5 + F6 + F8**。收敛门禁、入口和增量/跨项目编排；F8 依赖 F3 完成。
3. **第三批：F9 + F10**。集中修 force-rebuild / backup 系列的破坏性操作安全链路；可与主管线修复并行，但 F9/F10 通过前不可发布为 runtime 能力。
4. **第四批：F12 + F13**。在主框架稳定后补真实证券验收和 EA-Doc 维度组。
5. **最后：F11**。重写 eval / walkthrough / integration report，作为前四批的最终回归验收集合；不要让 F11 成为 F13 的前置依赖闭环。

---

## 二次复核（Opus 4.7，2026-05-25 04:30:00）

> 本节由独立 reviewer（Opus 4.7）对 Codex 第一轮 ~ 第十三轮 Findings 做实测复核 + 增量发现。原文未修改，本节只追加。

### 一、关键技术断言实测验证（13/13 命中）

对原报告中 13 项可机器验证的核心技术断言全量实测，**全部命中**（即原报告所述事实存在）：

| # | 原报告断言 | 实测命令 / 结果 | 命中 |
|---|---|---|---|
| 1 | `dimensions-doc.yaml` 不可解析（第十三轮 P1） | `python3 -c "yaml.safe_load(...)"` 抛 `expected <block end>, but found '<scalar>'` | ✅ |
| 2 | `activation-report-schema.json` 缺失（第一/四/六/十三轮反复出现） | `ls` 返回 `No such file or directory` | ✅ |
| 3 | activation-report.json `dimensions[1]` 仅 `$comment` 占位（第九/十轮） | `evaluations=16 / dimensions=1 / dimensions[0].keys()=['$comment']` | ✅ |
| 4 | mtime 方向逻辑反转（第二轮 U13 P1） | readiness-check.md:54 `mtime <= now - freshness_window_days → 通过`，逻辑上 14 天前的旧文件通过、新文件 stale | ✅ |
| 5 | schema vs schema_version 字段名跨 agent 漂移（第三/四/十三轮） | dimension-activator 输出 `"schema"`；cross-project-aggregator 校验 `schema_version`；merge-coordinator self-check 写 `schema_version` 而其它 step 用 `schema` | ✅ |
| 6 | baseline 维度无 default_content 字段（第一轮 U6 P1） | `baseline-dimensions.yaml` 字段集 = `[name, owner_phase, core_concerns, must_check_items, activation_signal_hints]`，无 `default_content` | ✅ |
| 7 | EAD-001 引用不存在的骨架文件（第十轮 P2） | 实际 `app-client/` 下是 `hybrid-bridge-skeleton.md` 不是 `rn-cross-platform-skeleton.md`；`backend/` 下是 `java-skeleton.md` 不是 `java-spring-skeleton.md` | ✅ |
| 8 | baseline 仅 6 个 ≠ 计划要求 13 个（第一轮 P1） | `baseline-dimensions.yaml` 实测 6 维（D01/D02/D06/D09/D11/D12）；R48 明确要求 13 项 | ✅ |
| 9 | pending-confirmation.md 与 standard.md 不一致（第九轮 P1） | `09-industry/pending-confirmation.md` 写"当前暂无待确认规则"；`01-securities-standard.md` 多处 owner 待确认（SEC-03/SEC-10/XSEC-01 等） | ✅ |
| 10 | `backup.sh --pin/--unpin` 无 lock（第八轮 U26 P1） | 脚本 pin/unpin 分支无 `mkdir .lock`，直接修改 manifest | ✅ |
| 11 | activation-rules schema 拒绝 `doc-content` 信号类型（第十三轮 P1） | schema `signal.type.enum = [grep, ast, file_existence, dependency, gitnexus]`，无 `doc-content`；`end.enum = [app-client, frontend, backend, industry]`，无 `doc` 或 `cross-cutting` | ✅ |
| 12 | workflow.md 数据流方向倒置（第二轮 U11 P1） | workflow.md:40 `dimension-activator` 在 :60 `facts-and-classification` 之前 | ✅ |
| 13 | integration-validation-report 自承"无真实运行"但标 PASS 8/8（第十二轮 P1） | 第 14-16 行明确写"由于无真实项目运行环境，所有场景采用结构验证"；frontmatter 仍 `overall_result: PASS`、`scenarios_passed: 8` | ✅ |

**结论**：原报告 13 项核心技术断言 100% 经实测确认。报告的事实陈述质量极高，可作为修复 backlog 直接使用。

### 二、二次复核新增发现（非 Codex 原报告范围）

下列发现由二次复核独立得出，原报告未明确点出或未充分强调严重性：

#### N-01 [P0] generation agent 与 U18 PoC 产物存在硬阻断接口断裂

`generation.md:32` 明确读取 `activation_report.dimensions[]`；`:106` 写"`dimensions[]` 非空校验，空抛 `EMPTY_ACTIVATION_REPORT` 停止"。

而 U18 实际产出的 `engineering-standards/09-industry/evidence/dimension-activation-report.json` 中 `dimensions[1]` 仅含一条 `{"$comment": "..."}` 占位对象，无 `dimension_id` / `state` / `evidence_paths`。

**推论**：U18 PoC 产物**不可能**由当前 `generation.md` 流程产生——若按现有 generation 跑，会立即抛 `EMPTY_ACTIVATION_REPORT` 并停止。当前的 `01-securities-standard.md`（425 行 16 维章节齐全）必然是**绕过 generation 真实流程手工书写**的。

**进一步影响**：
- 这等同确认了第十二轮 P1（U22 PASS 是结构断言）的最深层证据——PoC 产物本身就不是 generation 输出，所以 U22 检查它"存在 + 章节齐全"完全无法说明 generation 在任何真实输入上可工作。
- 第十轮 P1（U19 eval 读 `evaluations[]`）不仅是"固化错误字段"，更是**屏蔽 generation 真实失败信号**——eval 通过等于在掩盖 generation 在真实链路下永远抛 EMPTY 的事实。

**修复建议**：F2 修复包必须包含一项可执行验证："用现有 dimension-activator 跑任意真实/mock 项目 → 把输出直接喂给 generation → 不抛 EMPTY 且产出非空 standard.md"。如果没有此 end-to-end 闭环，F2 不算完成。

#### N-02 [P0] baseline 维度链路在 generation 处必定硬失败

`generation.md:36` 与 `:331` 到 `:335` 写 baseline 从 yaml `default_content` 内容直接渲染。`baseline-dimensions.yaml` 实测无 `default_content` 字段。

**推论**：任何包含至少一个 baseline 维度的项目跑到 generation 时，渲染 baseline 章节会引用不存在的字段。由于当前 6 个 baseline 维度（D01 架构 / D02 命名 / D06 错误处理 / D09 测试 / D11 安全 / D12 可观测性）**几乎覆盖所有真实项目必有的维度**，这意味着 **generation 在 baseline 维度路径上 100% 失败**。

**与 N-01 的协同后果**：
- generation 既无法处理 baseline 维度（因为 default_content 不存在），也无法处理"dimensions[] 为空"的 activation-report（因为会抛 EMPTY）
- 实际 generation 唯一能跑通的路径是"activation-report.dimensions[] 非空 + 全部维度 state ≠ baseline"，这在真实项目里几乎不存在
- 所以当前 Phase 2 的 generation 实际可执行覆盖率 ≈ 0%

**修复建议**：F4 修复包必须包含两个分支：
1. 决定 baseline 维度的 default_content 由谁产出（yaml schema 扩展 / 独立 templates 目录 / 还是回归"baseline = candidate alias"）
2. 建立"任意 6 baseline 维度 + 0 activated 维度"输入下 generation 不报错且产出最小章节的回归测试

#### N-03 [P1] schema-version 漂移已扩散到 R3 三个互不兼容的位置

第二轮提到 schema vs schema_version 漂移，但未列出全部漂移点。二次复核完整盘点：

| 文件 | 行 | 字段名 |
|---|---|---|
| `agents/dimension-activator.md` | 51 | `"schema": "activation-report.v1"` |
| `agents/facts-and-classification.md` | 88 | 校验 `schema == "activation-report.v1"` |
| `agents/merge-coordinator.md` | 172 / 342 | 校验 `schema == "activation-report.v1"` |
| `agents/merge-coordinator.md` | 390 (self-check) | 要求落盘文件 `schema_version="activation-report.v1"` |
| `agents/cross-project-aggregator.md` | 52 | 输出 `"schema_version": "unified-activation-map.v1"` |
| `agents/cross-project-aggregator.md` | 114 | 校验 per-project report `schema_version == "activation-report.v1"` |
| `templates/dimension-activation-report-template.json` | 2-3 注释 | 注释写 `schema_version=...` |
| `templates/dimension-activation-report-template.json` | 实际字段 | `"schema": "activation-report.v1"` |
| `engineering-standards/09-industry/evidence/dimension-activation-report.json` | 3 | `"schema": "activation-report.v1"` |

**漂移种类**：
- 主流（输出端 + 大多数消费者）：`schema`
- 少数派（cross-project-aggregator + merge self-check）：`schema_version`
- 模板内部冲突：注释 vs 实际字段

**实际后果**：跨项目模式下 cross-project-aggregator 会把所有真实 dimension-activator 输出判为 `SCHEMA_MISMATCH` 停止。这等同于跨项目能力（U15）整体不可用。

**修复建议**：F2 修复包应包含一次性 grep replace（统一 `schema` 或 `schema_version`），并在 `activation-report-schema.json` 中固化字段名作为唯一真理。

### 三、修复包之间的依赖关系图（依赖关系强约束）

原"合并后的修复优先级"按四批次给出，但批次内 / 批次间的依赖关系未显式标注。二次复核补充依赖关系图：

```
[第一批 - 必须串行]
  F1 (config schema) → F2 (activation-report contract) → F3 (workflow handoff)
       │                    │                                │
       │                    │                                ↓
       │                    └──── F4 (state machine + baseline default_content) [N-02 加入此批]
       │
       └──── 阻断: F4 需 F1 提供合法 schema 才能添加 default_content 字段定义

[第二批 - 部分可并行]
  F5 (recommended_action 枚举)  ─┐
  F6 (entry consistency)         ├─→ 依赖 F1+F2 完成
  F8 (diff/cross-project)        ─┘   F8 同时依赖 F3

[第三批 - 可并行修复，发布受 F9/F10 安全链路约束]
  F9 (force-rebuild safety)      ─┐
  F10 (pin/unpin/list)            ├─→ 仅依赖 F1（schema base）
                                  ─┘   不依赖 F2/F3 (可与 Phase 2 主链路并行修复；F9/F10 关闭前不可发布为 runtime)

[第四批 - 内容补全]
  F12 (real securities PoC) ← 必须在 F1+F2+F3+F4 全部就绪后才能开始
  F13 (EA-Doc re-integration) ← 同上；EA-Doc 自身补最小契约用例，最终集成回归交给 F11

[最后 - 验收回归]
  F11 (evals + walkthroughs + integration) ← 必须在所有上述完成后重写
       含 N-01 验证项: end-to-end "activator → generation 不抛 EMPTY"
       含 N-02 验证项: "6 baseline + 0 activated 输入 → generation 产出最小章节"
```

### 四、分级发布建议（取代原"二元裁决"）

原最终结论是"不建议发布 / 合并为可用能力"——这是单一裁决。二次复核基于实际能力分布给出分级建议：

#### Tier A：建议立即下线 / 标记不可用（P0 阻断，不能在任何场景使用）

| 能力 | 状态 | 依据 |
|---|---|---|
| Phase 2 默认 append 管道（`extraction_mode=full`） | **不可用** | N-01 + N-02：generation 在真实输入下必抛 EMPTY 或引用不存在 default_content |
| 跨项目对比（U15 unified-activation-map） | **不可用** | N-03：schema_version vs schema 漂移导致 100% SCHEMA_MISMATCH |
| EA-Doc 维度组（U27） | **不可用** | dimensions-doc.yaml 不可解析 + activation-rules-doc 不符 schema + 接入顺序反向 |
| 证券子领域 PoC（U18 产物） | **不能作为 evidence** | evidence_tier=synthetic-poc，且产物不可能由真实流程产生（N-01 推论） |

**立即动作**：在 SKILL.md / README.md / usage-guide.md 顶部添加 `Phase 2 Status: BLOCKED`，明确告知用户在 F1-F4 修复完成前不要尝试运行；保留产物供修复参考但不允许下游消费。

#### Tier B：可独立修复，不阻塞主管线（P1，修复前不可发布为 runtime 能力）

| 能力 | 状态 | 依据 |
|---|---|---|
| force-rebuild / restore / pin / unpin / list（U23-U26） | **可并行修复，暂不可发布为 runtime 能力** | helper script 局部可运行；但 lock 原语、path traversal 防护、manifest schema 校验、restore/rollback 元数据污染仍是 P1 阻断 |
| Backup Manager 治理产物 | **可作为设计素材保留，暂不可作为破坏性 IO 入口发布** | scripts/backup.sh 大部分路径存在，但第五/八轮 P1 finding 未关闭前不能把它宣传为可安全执行的治理能力 |
| Phase 2 文档资产（README / workflow / quality-gate.md） | **可发布为 design spec** | 标注 status=design，不作为 runtime 入口 |

**立即动作**：把 force-rebuild 系列从 Phase 2 主管线修复中拆出来并行处理，但对外只标记为 `design / repair-in-progress`；F9/F10 的 lock、path、manifest、rollback、schema 校验全部关闭后，才允许作为 Phase F runtime 子能力发布。

#### Tier C：保持现状（已稳定）

| 能力 | 状态 | 依据 |
|---|---|---|
| Phase 1 默认管道（profile-first / batch-extraction） | **稳定** | 第一阶段交付，已通过 examples/golden-sample-run.md 验证 |
| 维度池配置基础设施（schema.json / activation-rules.schema.json） | **稳定** | 仅需 F1 扩展，不需要重写 |

**立即动作**：用户实际萃取需求路由到 Phase 1 路径；Phase 1 文档保持现状直到 Phase 2 修复完成。

### 五、二次复核未覆盖事项

以下原报告未提及、二次复核也未深查的潜在风险，留给后续审查：

1. **多 host 兼容性**：scripts/backup.sh 标注跨 macOS BSD / Linux GNU 兼容，但只在 macOS 实测过；Linux GNU 下 `find -exec` / `cpio` / `python3` 路径差异未验证。
2. **大型项目性能**：所有性能基线均为设计目标；真实跑过的合成 PoC 总量 < 1MB，无法外推到 100K+ 文件级别项目的 dimension-activator + facts-and-classification 联合开销。
3. **prompt 注入面扩大**：U23 的 `confirm <domain>` 字面校验依赖 host 提供的 `AskUserQuestion`，不同 host 实现差异可能引入新注入面（如 IDE 集成场景下 prompt 由 LLM 接收预处理）。
4. **CHANGELOG helper 与 host developer profile 同步**：`.claude/spec-first/.developer` / `.codex/spec-first/.developer` 缺失时如何降级，原报告未深查。

### 六、二次复核结论

**事实层**：原报告 13 项关键技术断言全部经实测确认；新增 N-01 / N-02 / N-03 三个 P0/P1 级阻断，分别说明 generation 在真实输入下必失败、baseline 链路 100% 失败、跨项目能力 100% 失败。

**结构层**：报告的"问题归并视图"已经做了根因聚合工作（13 个修复包），但批次依赖关系未显式标注；本次复核补充了依赖图。

**结论层**：从原"不建议发布"二元裁决升级为三层分级建议——Tier A（4 项能力立即下线）+ Tier B（force-rebuild 系列可独立修复但暂不可作为 runtime 发布）+ Tier C（Phase 1 稳定路径继续保留）。

**信任度**：原报告作为修复 backlog 可直接采信，无需再次盘点 Findings。修复执行时应：
1. 优先验收 N-01 / N-02 / N-03 三个推论级阻断（这三项是"问题已被推论级证明，但尚未被独立测试覆盖"）
2. 严格遵守修复包依赖图（F1 → F2 → F3 → F4 必须串行）
3. F11 evals 重写必须包含端到端 generation 闭环验证（不能只 grep 文件存在）

如果按此分级建议执行，Phase 2 主管线 ETA 估计需要 2-3 周修复 Tier A + 1 周修复 Tier B 安全链路；Tier C 不阻塞用户当前萃取需求。

---

## 三次方案更新（Codex，2026-05-25 12:44:53）

> 本节根据对二次复核方案的再审查追加，只更新修复治理口径，不重盘原始 70 条 finding。

### 更新内容

1. **frontmatter 增加机器可读阻断状态**：新增 `phase2_runtime_status: blocked`、`p0_blockers`、`blocked_capabilities`，并把 N-01 / N-02 / N-03 纳入 `critical_blockers`，避免只读 frontmatter 的下游漏掉二次复核新增阻断。
2. **消除 F11 / F13 依赖闭环**：F13 不再依赖 F11；EA-Doc 自身最小契约用例随 F13 补齐，最终 integration / walkthrough / eval 重写统一归入 F11。
3. **修复优先级改为强约束串行首批**：第一批从 `F1 + F2 + F3` 调整为 `F1 -> F2 -> F3 -> F4`，因为 N-02 证明 baseline/default_content 状态机也是主管线硬阻断。
4. **收紧 Tier B 发布口径**：force-rebuild / restore / pin / unpin / list 可并行修复，但在 F9/F10 的 lock、path traversal、manifest schema、rollback、schema validation 全部关闭前，不得作为 runtime 能力发布；Backup Manager 只能作为 design / repair-in-progress 素材保留。

### 更新后的执行口径

- **主管线 blocked 条件**：N-01 / N-02 未被端到端测试关闭前，`extraction_mode=full` 和 Phase 2 默认 append 管道保持不可用。
- **首批修复顺序**：先 F1，再 F2，再 F3，最后 F4；不要并行改写 eval 来“适配”当前错误契约。
- **EA-Doc 修复边界**：F13 只负责让 EA-Doc 回到合法 schema、正确 handoff 和 `dimensions[]` 主契约；全套 walkthrough / integration PASS 由 F11 统一验收。
- **破坏性 IO 发布边界**：F9/F10 可并行修复，但任何实际 `force-rebuild` / `restore` / `pin` / `unpin` 入口在安全链路关闭前都不能对外宣传为可用。
