---
spec_id: 2026-06-01-001-project-standard-extractor-code-standard-extraction
artifact_kind: prd-requirements
target_surface: cli
status: superseded
superseded_by: docs/brainstorms/2026-06-01-002-project-standard-extractor-output-artifact-contract-requirements.md
evidence_grade: mixed
author: leokuang
created: 2026-06-01
target_path: skills/project-standard-extractor
related:
  - docs/brainstorms/2026-05-21-001-project-standard-extractor-requirements.md
  - docs/brainstorms/2026-05-26-002-project-standard-extractor-full-auto-draft-pipeline-requirements.md
---

> **⚠️ 已被取代（superseded）**：本需求的 full-auto 主线已并入统一 PRD [`docs/brainstorms/2026-06-01-002-project-standard-extractor-output-artifact-contract-requirements.md`](2026-06-01-002-project-standard-extractor-output-artifact-contract-requirements.md)。后续规划以 002 为准。本文保留为历史需求来源与决策记录（含产品前提裁定）。R-18（pending 纳入执行）与 R-19（覆盖完整性报告）已迁移为 002 的 R-18 与 R-33。

# project-standard-extractor 一步生成可使用规范文档需求

## Summary

为规范 owner、AI 编码使用者和 Reviewer 提供一个从现有代码路径一步生成可使用开发编码规范文档的能力：用户提供项目路径后，系统自动完成项目画像、batch 队列、逐 batch evidence 萃取、质量门禁、冲突归并和规范产物聚合，最终输出可直接用于 AI 编码与 Code Review 的 `standard-*`、`ai-rules.md`、`review-checklist.md` 和 review summary。

## Problem Frame

用户期望的是“一步到位”：给一个现有代码项目，直接得到可以使用的规范文档，而不是先拿到 profile / batch plan 再手动选择 batch 继续跑。两段式路径虽然安全，但会打断使用体验，也不符合“从现有代码分析总结开发编码规范”的产品预期。

新的产品边界是：自动化应覆盖完整 draft 生产链路，但不能绕过 evidence 和风险治理。系统可以直接产出可使用规范文档，其中高置信 evidence-backed 规则可进入 AI rules 和 review checklist；证据不足、历史兼容、冲突或高风险项必须显式进入 pending、legacy、conflict 或 rejected，不得混入默认强约束。

“可使用”在本 PRD 中定义为：文档结构完整、规则可追溯、AI 可执行、Reviewer 可检查，并带有 `draft` / pending / conflict / risk 标识；owner 后续可把高置信 `draft` 手动升级为 `active`，但一步生成结果已经可以作为 AI 编码和 Review 的工作输入。

## Current System Snapshot

| 当前事实 | 证据 tag | 证据 |
| --- | --- | --- |
| `project-standard-extractor` 已定义为从存量代码反向萃取团队研发规范，供 AI 编码与人工 review 复用。 | confirmed-source | `skills/project-standard-extractor/SKILL.md` |
| 当前公开稳定路径仍是 `profile-first -> stop-for-batch-selection -> selected batch generation`，完整仓库不会自动遍历全部 ready batch。 | confirmed-source | `skills/project-standard-extractor/SKILL.md`, `skills/project-standard-extractor/references/workflow.md` |
| `profile-and-batch-planner` 已能生成 project profile、extraction map、batch plan 和 `ordered_batch_queue` 语义。 | confirmed-source | `skills/project-standard-extractor/references/agents/profile-and-batch-planner.md` |
| selected-batch generation 已支持 `phase1-selected-batch`，不要求 `activation-report`，不读取 `dimension-activator`。 | confirmed-source | `skills/project-standard-extractor/references/agents/generation.md` |
| 产物体系已包含 `standard-{sub_domain}.md`、`ai-rules.md`、`review-checklist.md`、evidence、pending、merge suggestions、conflicts、candidate rules-index、llms candidate 和 ai-context-pack。 | confirmed-source | `skills/project-standard-extractor/references/config/output-targets.md` |
| `ai-rules.md` 和 `review-checklist.md` 必须从 standard 派生，不得新增独立规则。 | confirmed-source | `skills/project-standard-extractor/SKILL.md`, `docs/evals/project-standard-extractor/expected-behavior.md` |
| 敏感配置、生产凭据、认证材料只允许记录脱敏存在事实，不得读取或输出原文。 | confirmed-source | `skills/project-standard-extractor/SKILL.md`, `skills/project-standard-extractor/references/agents/intake-and-scope.md` |
| 新规则默认不自动发布 `active`，重复运行必须 append-only，不覆盖已有 active 或 draft。 | confirmed-source | `skills/project-standard-extractor/references/config/output-targets.md` |
| 现有 full-auto draft pipeline 需求已提出自动画像、batch 队列、逐 batch 萃取、质量分层和 owner approval queue。 | confirmed-source | `docs/brainstorms/2026-05-26-002-project-standard-extractor-full-auto-draft-pipeline-requirements.md` |
| GitNexus 当前可作为查询定位线索，但图谱快照陈旧且无 impact/review 能力；本 PRD 不把 GitNexus 结论写成 confirmed current-state fact。 | gitnexus-pointer | `.spec-first/graph/graph-facts.json`, `spec-first startup-reminder --codex` |

## Change Delta

| 变化类型 | 内容 | 涉及现有能力 | 风险/权限/数据影响 | 证据 tag |
| --- | --- | --- | --- | --- |
| replace | 默认体验从“两段式 profile-first + 人选 batch”改为“一步 full-auto 生成可使用规范文档”。 | 公开入口、workflow、planner、generation、merge | 提升自动化体验，同时扩大运行范围 | user-stated |
| keep | profile-first 仍必须作为内部前置阶段执行，用于建立边界、batch 队列、敏感排除和 evidence 预算。 | Intake、Profile、Batch Plan | 降低误萃取和敏感信息风险 | confirmed-source |
| extend | 自动执行 `status: ready` 的 ordered batch queue；pending、skipped、blocked batch 只进入 summary，不强行萃取。 | Planner、Batch Worker | 避免低质量 batch 污染结果 | confirmed-source |
| extend | 跨 batch 聚合标准文档、AI rules、review checklist、candidate index 和 review summary。 | Generation、Merge | 需要去重、冲突归并和状态分层 | user-stated |
| keep | 高置信 draft 文档可使用，但 `active` 仍由 owner 手动确认。 | 发布治理 | 避免模型替代团队规范承诺 | confirmed-source |
| keep | Phase 2 dimension-aware、force-rebuild、restore、pin、unpin、list 不纳入普通 full-auto runtime。 | 维护者边界 | 避免 destructive IO 暴露 | confirmed-source |

## Actors

- A1. Skill 使用者：提供现有项目路径，期望一次运行得到可使用规范文档。
- A2. Full-auto pipeline：自动完成画像、batch 队列、逐 batch 萃取、质量门禁和归并输出。
- A3. 规范 owner：审查 high-confidence draft、pending、conflict，决定是否升级 `active`。
- A4. AI 编码使用者：消费生成的 AI rules 和 context pack，减少重复上下文说明。
- A5. Reviewer：消费 review checklist 检查人工或 AI 生成代码。
- A6. 目标代码仓库：提供真实代码、manifest、README、目录结构、正反例和历史兼容证据。

## Requirements

| 编号 | 优先级 | 触发条件 | 角色 | 系统行为 | 用户可见结果 |
| --- | --- | --- | --- | --- | --- |
| R-01 | P0 | 使用者提供一个或多个 `project_paths` | pipeline | 应校验路径存在、可读、授权范围和敏感路径策略；无有效路径时停止。 | 用户获得可执行范围或 `NO_VALID_PROJECT_PATHS`。 |
| R-02 | P0 | 输入是完整仓库、多服务、多 manifest、多个研发域或范围不明确 | pipeline | 必须先执行内部 profile-first，生成项目画像、extraction map、batch plan 和 ordered batch queue。 | 用户不需要手动选 batch，也能看到运行边界。 |
| R-03 | P0 | profile-first 完成 | pipeline | 应自动执行 `status: ready` 的 batch；pending、skipped、blocked batch 写入 review summary。 | 用户得到完整可审查结果，而不是中途停止。 |
| R-04 | P0 | 多个 ready batch 被执行 | pipeline | 每个 batch 必须独立读取 candidate files、独立记录 evidence 和 stop conditions；单 batch 失败不得污染其他 batch。 | review summary 标明每个 batch 的成功、pending、conflict 或失败状态。 |
| R-05 | P0 | 进入 facts 阶段 | pipeline | 只应从当前 batch 的 candidate files 中提取描述性 code facts、signal hits 和 classification candidates，不得在 facts 阶段写规范结论。 | 后续规则能追溯到具体 fact。 |
| R-06 | P0 | 对代码事实做分类 | pipeline | 必须区分 recommended、forbidden、legacy_compatible、pending_confirmation、conflict、rejected。 | 历史旧写法、反例、低证据项和冲突不会混入推荐规则。 |
| R-07 | P0 | 单个 ready batch 进入 generation | pipeline | 应使用 `phase1-selected-batch` 输入剖面生成该 batch 的 evidence-backed draft standard 内容。 | 每个 batch 产出可合并的规范片段。 |
| R-08 | P0 | 所有 ready batch 完成或跳过 | pipeline | 应聚合生成可使用的 `standard-{sub_domain}.md`、`ai-rules.md`、`review-checklist.md`、evidence、pending、conflicts 和 candidate index。 | 用户一次运行后得到完整规范资产。 |
| R-09 | P0 | 生成 AI rules 和 review checklist | pipeline | `ai-rules.md` 和 `review-checklist.md` 必须从 standard 派生并引用来源章节，不得新增独立规则。 | AI 和 Reviewer 消费同一份规范源。 |
| R-10 | P0 | 新规则通过质量门禁 | pipeline | 应以 append-only 方式写入 draft、pending、conflict、legacy 或 merge suggestion；不得覆盖已有 active 或 draft。 | 既有团队规范不会被隐式替换。 |
| R-11 | P0 | 规则涉及敏感配置、生产凭据、token、私钥、用户数据或生产环境信息 | pipeline | 只允许记录脱敏存在事实，不得读取、复制、转述或输出原文片段。 | 规范产物不泄露敏感信息。 |
| R-12 | P0 | 候选规则缺 evidence、证据代表性不足或必须人工判断 | pipeline | 应将候选内容写入 pending、legacy、conflict 或 rejected，不得写入 AI 默认强制规则。 | 用户看到可审查项，AI 不会默认执行低证据规则。 |
| R-13 | P1 | 跨 batch 产出相似或相反规则 | pipeline | 相近内容应去重或写入 `merge-suggestions.md`；相反规则写入 `conflicts.md`。 | owner 能显式裁定合并或冲突。 |
| R-14 | P1 | 运行质量门禁 | pipeline | 应覆盖 evidence、团队级抽象、AI 可执行性、Review 可检查性、冲突、行业风险、上下文治理和跨 batch 聚合质量。 | 进入可使用文档的规则经过多维审查。 |
| R-15 | P1 | GitNexus 可用或不可用 | pipeline | 可用时只能作为 advisory evidence 或定位线索；陈旧、dirty、impact-unavailable 时必须降级并记录限制。 | 规则不会只凭陈旧图谱事实成立。 |
| R-16 | P1 | 运行完成 | pipeline | 应输出 review summary，汇总 batch 执行结果、draft/pending/conflict/rejected 分布、降级原因和 owner 待处理动作。 | 用户知道哪些规则可立即使用，哪些需要确认。 |
| R-17 | P2 | 聚焦模块输入而非完整仓库 | pipeline | 可支持 focused-module 一步生成，但仍必须遵守 evidence、敏感信息、draft-only 和 append-only 规则。 | 小范围模块也能直接产出可使用规范文档。 |
| R-18 | P0 | profile-first 完成后存在 `pending-confirmation` batch（有方向但证据不足/单样本） | pipeline | 应将 `pending-confirmation` batch 纳入执行（不再仅进 summary），产出标记为 `low-confidence draft`，写入 `pending-confirmation.md` 隔离分区；**不得进入 `ai-rules.md` 默认执行清单**。`skipped`（无代表性候选）和 `blocked`（权限/敏感）batch 仍不产出规范，只进覆盖缺口报告。 | 用户在一次运行中拿到「证据充分（高置信）+ 有方向（低置信隔离）」两档覆盖，证据缺失项不被伪造为规则。 |
| R-19 | P0 | 运行完成 | pipeline | 应输出**覆盖完整性报告**（coverage report），列出：profile 识别到的全部 `domain × sub_domain × task_type` 矩阵项、每项的 batch 归属与状态（ready/pending/skipped/blocked）、未识别或低置信归因的疑似遗漏点、以及「本次全部覆盖 vs 缺口」的明确清单。 | 用户能判断「自动跑出的全部」到底覆盖了多少、漏了什么、为什么漏，而不是误以为已穷尽。 |

## Business Rules

- BR-001：没有代码 evidence 或 owner 确认的内容，不得写成 AI 默认强制执行规则。
- BR-002：高置信 evidence-backed `draft` 规则可以进入可使用规范文档；`active` 仍只能由 owner 手动确认。
- BR-003：完整仓库输入必须先内部 profile-first，再自动执行 ready batch queue；不得把完整仓库作为一个无边界上下文直接交给 generation。
- BR-004：敏感文件只记录脱敏存在事实；如果继续萃取必须读取敏感原文，pipeline 必须停止对应 batch。
- BR-005：`ai-rules.md` 和 `review-checklist.md` 是 `standard-{sub_domain}.md` 的派生视图，不拥有独立规则来源。
- BR-006：pending、conflict、rejected 不得进入 AI 默认执行规则。
- BR-007：Phase 2 blocked / repair-only 能力不得作为普通 full-auto 用户路径宣传或执行。
- BR-008：规范正文不得包含真实本地绝对路径；项目路径证据只允许在 evidence 中以可审查且不泄密的形式出现。

## Acceptance Examples

- AE-01（覆盖 R-01, R-02, R-03, R-08）
  Given 使用者提供一个完整 git 仓库路径，when 启动 extractor，then pipeline 应先内部生成画像和 batch 队列，再自动执行 ready batch，最终输出可使用 `standard-*`、`ai-rules.md`、`review-checklist.md` 和 review summary，且不要求用户中途选择 batch。

- AE-02（覆盖 R-04, R-05, R-07）
  Given ordered batch queue 中有 3 个 ready batch，其中第 2 个 evidence 不足，when pipeline 执行，then 第 1 和第 3 个 batch 可继续生成并聚合，第 2 个 batch 进入 pending 或 failed summary，不得污染其它 batch 结论。

- AE-03（覆盖 R-06, R-12）
  Given 某个写法只在单个历史迁移模块出现且没有正向复用证据，when pipeline 做分类和生成，then 该内容应进入 legacy 或 pending，不得进入 recommended draft 规则。

- AE-04（覆盖 R-10, R-13）
  Given 目标 domain 已存在 active 规则，when 新候选规则与该 active 规则语义冲突，then pipeline 应写入 `conflicts.md`，不得覆盖或降级既有 active 规则。

- AE-05（覆盖 R-11, BR-004）
  Given candidate files 命中生产凭据、token、私钥或 secret 配置，when pipeline 需要处理该路径，then 它只能记录脱敏存在事实；如果必须读取原值才能继续，则停止对应 batch 并报告 `SENSITIVE_FILE_BLOCKED`。

- AE-06（覆盖 R-09, R-14, R-16）
  Given generation 产出多个 batch 的 draft 规则，when quality gate 和 merge aggregation 执行，then `ai-rules.md` 和 `review-checklist.md` 只包含可追溯 high-confidence draft 规则，并且 review summary 列出 evidence、AI 可执行性、Review 可检查性、冲突和推荐处理动作。

- AE-07（覆盖 R-15）
  Given `.spec-first/graph/graph-facts.json` 显示 GitNexus stale 或 impact unavailable，when pipeline 需要结构性代码事实，then GitNexus 只能作为定位线索，最终规则必须由源码、文档或 owner 确认支撑。

- AE-08（覆盖 R-17）
  Given 使用者只提供一个聚焦模块路径，when workflow 进入 focused-module full-auto，then 可以直接生成可使用规范文档，但仍必须生成 evidence-backed draft，并遵守敏感信息、draft-only 和 append-only 规则。

## Scope Boundaries

### 本期做

- 从现有代码路径一步生成可使用团队级开发编码规范文档。
- 支持完整单仓库输入自动画像、batch queue、逐 batch 萃取和聚合。
- 支持**两档自动执行**：`ready` batch 产出高置信 draft；`pending-confirmation` batch 产出 `low-confidence draft` 并隔离到 `pending-confirmation.md`（不进 ai-rules 默认执行）。`skipped` / `blocked` batch 不产出规范，进覆盖缺口报告。
- 支持 high-confidence draft、low-confidence draft、pending、legacy、conflict、rejected 的质量分层。
- 支持生成 `standard-*`、`ai-rules.md`、`review-checklist.md`、evidence、candidate index、review summary 和**覆盖完整性报告**。
- 支持 GitNexus 作为 advisory pointer，并在不可用或陈旧时降级。

### 本期不做

- 不自动发布 `active` 规范。
- 不把完整仓库直接作为无边界上下文生成最终规范。
- 不建设规范管理 Web 平台。
- 不执行业务代码修改、bug 修复或 PR 代码评审。
- 不生成脱离代码 evidence 的行业通用最佳实践。
- 不把 Phase 2 dimension-aware、cross-project、EA-Doc、securities PoC、force-rebuild、restore、pin、unpin、list 作为普通用户 runtime。
- 不覆盖已有 active / draft 规则。

### 与其它需求的关系

- `docs/brainstorms/2026-05-21-001-project-standard-extractor-requirements.md` 是第一阶段原始需求。
- `docs/brainstorms/2026-05-26-002-project-standard-extractor-full-auto-draft-pipeline-requirements.md` 是本需求的重要前置：本 PRD 采纳其 full-auto draft 方向，并把用户目标进一步明确为“一步生成可使用规范文档”。
- `docs/brainstorms/2026-05-24-001-project-standard-extractor-dimension-framework-requirements.md` 描述 Phase 2 维度框架目标；当前不纳入普通 full-auto runtime。

## Goals / Success Metrics

| 目标 | 可观察口径 |
| --- | --- |
| 一步到位生成可使用规范 | 用户提供完整仓库路径后，一次运行得到 `standard-*`、`ai-rules.md`、`review-checklist.md` 和 review summary。 |
| 降低 owner 手写规范成本 | owner 从审查 high-confidence draft / pending / conflict 开始，而不是从 batch 选择和手工生成开始。 |
| 提高 AI 编码上下文质量 | `ai-rules.md` 中每条规则都能追溯到 standard 来源章节和 evidence。 |
| 提高 Review 一致性 | `review-checklist.md` 中每条检查项都能由 Reviewer 二值判断，并追溯到 standard 来源章节。 |
| 降低误发布风险 | draft、pending、legacy、conflict、rejected、active 的状态边界在 review summary 中清晰可见。 |
| 降低泄密风险 | 敏感路径只出现脱敏存在事实，无凭据原文或绝对本地路径泄露。 |

## Evidence And Assumptions

### Evidence

- confirmed-source：`skills/project-standard-extractor/SKILL.md` 定义当前公开目的、输入、稳定流程、输出、安全边界和失败模式。
- confirmed-source：`skills/project-standard-extractor/references/workflow.md` 定义当前稳定公开路径和 Phase 2 blocked / repair-only 边界。
- confirmed-source：`skills/project-standard-extractor/references/agents/profile-and-batch-planner.md` 定义 profile-first、batch plan 和 ordered batch queue 语义。
- confirmed-source：`skills/project-standard-extractor/references/agents/generation.md` 定义 `phase1-selected-batch` 输入剖面、evidence writer、developer guide、AI rules 和 checklist 派生。
- confirmed-source：`skills/project-standard-extractor/references/agents/review-and-quality-gate.md` 定义多 persona 质量门禁。
- confirmed-source：`skills/project-standard-extractor/references/agents/merge-coordinator.md` 定义 append-only、冲突、pending 和候选产物写入策略。
- confirmed-source：`docs/brainstorms/2026-05-26-002-project-standard-extractor-full-auto-draft-pipeline-requirements.md` 已定义 full-auto draft pipeline 的自动 batch queue、质量分层和 owner approval 边界。
- gitnexus-pointer：GitNexus 查询返回候选文件定位，但 graph facts 显示陈旧和 impact/review 不可用，因此本 PRD 不把 GitNexus 输出作为 confirmed source。

### Assumptions

- assumption：本 PRD 中“可使用”指 high-confidence evidence-backed draft 可用于 AI 编码和 Review，仍保留 draft 状态和风险标识。
- assumption：规范 owner 愿意在生成后承担 active 升级和 conflict 裁定职责。
- assumption：目标代码仓库由使用者授权读取，且 pipeline 有能力跳过敏感文件或只记录脱敏存在事实。

## Outstanding Questions

### Resolve Before Planning

- 无阻塞问题。用户已明确默认体验应一步到位，范围可进入 `$spec-plan`。

### Deferred to Planning

- [Affects R-03, R-04][Technical] full-auto 应如何控制最大 batch 数、上下文预算、失败重试和运行时间。
- [Affects R-08, R-13][Technical] 跨 batch 去重、合并建议和冲突归并的具体规则如何设计。
- [Affects R-14, R-16][Technical] review summary 是否升级为 owner action queue，或先扩展现有模板。
- [Affects R-06, R-12][Technical] high-confidence draft 与 pending/rejected 的阈值如何由 evidence tier、coverage 和 reviewer findings 组合。

### Product Premises（doc-review 2026-06-01, product-lens）

**用户裁定（2026-06-01）：** 产品方向确认为「直接从代码萃取开发规范文档，一步进入可用」。据此：

- [PP-2 已否决] 「默认全选 ready batch + 保留 profile 后可取消 checkpoint」的中间方案**不采纳**。完整仓库场景不保留人工 checkpoint，full-auto 一步到位即默认体验。
- [PP-1 已确认] 「high-confidence evidence-backed draft 可直接作为 AI 编码与 Review 的工作输入」是**预期产品行为**，不是临时妥协。

**仍需 owner 决策（裁定后的剩余风险）：**

- [PP-1 剩余][Affects R-09, BR-005, BR-006] 既然 draft 直接可用，而 A4 AI 编码使用者消费 `ai-rules.md` 时通常不读 `status: draft` 标识、会把规则当权威执行：draft 规则与 active 规则在 agent 行为层面是否应有区别（例如拆出独立 `ai-rules.draft.md`，让 `ai-rules.md` 仅含 owner 确认项），以及团队基于未确认 draft 编码时的误用后果归属。注：用户确认「直接可用」**放大**了 plan P0-2 的结构质量底线要求——若产物退化为无结构规则堆，「可用」名不副实，故 P0-2（high-confidence draft 须含结构完整性判据）必须在 plan 层解决，不能延后。
- [PP-3][Affects Goals/Success Metrics] 现有 6 个 Success Metric 多为功能存在性的同义反复（如「降低 owner 成本」口径=「owner 从审查 draft 开始」，只描述新流程形态、不度量成本是否真降；产物即使被 owner 全部拒绝，所有 metric 仍可判 PASS）。须为核心 goal 补一个可证伪的结果口径（如 draft 采纳率、owner 自评省时），无法度量时诚实标注为「过程指标，非结果指标」。
- [PP-trajectory][身份迁移] 本变更使 skill 从「owner in-the-loop 主导」迁向「owner on-the-loop 事后审批」。这是真实的产品定位迁移而非纯体验顺滑；须在用户手册（plan U8）显式表述，并维持 owner 对「团队强制规范」这一严肃产物的 ownership 与信任。

## Readiness

- outcome: ready-for-planning
- current-state accuracy: PASS，当前两段式路径、full-auto 前置需求和 excluded Phase 2 均有 source/doc evidence。
- change delta clarity: PASS，默认体验从手选 batch 改为 full-auto 一步生成，profile-first 保留为内部阶段。
- exception coverage: PASS，覆盖无路径、batch 失败、低 evidence、敏感文件、冲突和 GitNexus 降级。
- planning invention risk: LOW，规划不需要再发明产品目标，但需要决定 batch 队列、聚合和质量分层实现方式。
- terminology ambiguity: LOW，核心术语沿用当前源码和 full-auto PRD：profile-first、ordered batch queue、phase1-selected-batch、high-confidence draft、pending、conflict、active。
