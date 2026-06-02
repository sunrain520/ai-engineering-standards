---
spec_id: 2026-06-01-002-project-standard-extractor-output-artifact-contract
artifact_kind: prd-requirements
target_surface: cli
status: ready-for-planning
evidence_grade: mixed
author: reviewer
created: 2026-06-01
target_path: skills/project-standard-extractor
supersedes:
  - docs/brainstorms/2026-06-01-001-project-standard-extractor-code-standard-extraction-requirements.md
related:
  - docs/ideation/2026-06-01-project-standard-extractor-output-artifacts-ideation.md
  - docs/plans/2026-06-01-002-feat-output-artifact-contract-and-full-auto-plan.md
  - docs/brainstorms/2026-05-26-002-project-standard-extractor-full-auto-draft-pipeline-requirements.md
---

# project-standard-extractor 一步生成与产物契约统一需求

## Summary

为 `project-standard-extractor` 定义统一的一步生成能力：用户提供现有代码路径后，系统内部完成 profile-first、ordered batch queue、逐 batch evidence 萃取、质量门禁、跨 batch 聚合、产物契约校验和 owner 决策队列，最终输出可被开发者、AI 编码、Reviewer 和规范 owner 稳定消费的 `standard-*`、`ai-rules.md`、`review-checklist.md`、evidence、fast index candidate、review summary 和审计信息。

本文融合 `docs/brainstorms/2026-06-01-001-project-standard-extractor-code-standard-extraction-requirements.md` 的“一步生成可使用规范文档”目标，以及原 002 的“产物目录结构、快速索引、可消费边界和 validator”要求。后续规划应以本文作为统一 PRD 输入；001 保留为历史需求来源。

## Problem Frame

001 解决了“从现有代码一步生成可使用规范文档”的产品体验问题，但仍留下一个关键问题：生成结果怎样证明自己可用。002 解决了“产物目录结构和文档是否满足开发规范落地”的治理问题，但如果脱离 full-auto 流水线，就只能成为静态契约补丁。

两者必须融合。只做 full-auto，pipeline 可能快速生成一批 `draft` 规则，但缺少结构完整性、索引一致性、派生追溯和 owner 决策边界，产物会退化成规则堆；只做产物契约，仍无法满足用户“一步到位，从代码生成可用规范”的核心诉求。

统一后的产品边界是：

1. 默认体验从“两段式 profile-first + 人工选择 batch”升级为“一步 full-auto 生成可使用规范文档”。
2. full-auto 不是无边界全仓库生成；profile-first 仍是内部安全阶段，用于建立 batch 队列、敏感排除、预算和 evidence 边界。
3. “可使用” = 通过高置信自动升级闸（BR-016）的规则**自动标记为可直接使用**（无需逐条 owner 确认）；未过闸者降级 draft/pending。所有规则仍带状态、风险、结构完整性、来源追溯;owner 保留事后否决权。（定位转向 2026-06-02,见 Decision Notes。）
4. 目录结构完整不等于规范可用；产物必须通过机器可判定契约、fast index 边界、lineage 派生关系和 drift linter。
5. owner 从事前选择 batch 迁移为事后审批和裁定，但仍拥有团队强制规范的最终 ownership。

## Current System Snapshot

| 当前事实 | 证据 tag | 证据 |
| --- | --- | --- |
| `project-standard-extractor` 已定义为从存量代码反向萃取团队研发规范，供 AI 编码与人工 review 复用。 | confirmed-source | `skills/project-standard-extractor/SKILL.md` |
| 当前公开稳定路径仍保留 `profile-first -> selected batch generation` 的两段式语义；完整仓库不会自动遍历全部 ready batch。 | confirmed-source | `skills/project-standard-extractor/SKILL.md`, `skills/project-standard-extractor/references/workflow.md` |
| `profile-and-batch-planner` 已能生成 project profile、extraction map、batch plan 和 `ordered_batch_queue` 语义。 | confirmed-source | `skills/project-standard-extractor/references/agents/profile-and-batch-planner.md` |
| selected-batch generation 已支持 `phase1-selected-batch`，不要求 `activation-report`，不读取 `dimension-activator`。 | confirmed-source | `skills/project-standard-extractor/references/agents/generation.md`, `docs/evals/project-standard-extractor/expected-behavior.md` |
| 输出目标已定义 `overview.md`、`standard-{sub_domain}.md`、`ai-rules.md`、`review-checklist.md`、evidence、pending、merge suggestions、conflicts、run-level handoff、candidate rules-index、candidate llms 和 ai-context-pack。 | confirmed-source | `skills/project-standard-extractor/references/config/output-targets.md` |
| 新建 Markdown 产物应包含 Front Matter，且规则正文不使用 Rule ID 或 HTML anchor；规则以 `(source_doc, section_title)` 二元组定位。 | confirmed-source | `skills/project-standard-extractor/references/config/frontmatter-format.md` |
| `rules-index` 候选不得包含 `rule_id` 或 `anchor`，`llms-candidate.txt` 不得默认覆盖根 `llms.txt`，正式发布需要显式确认。 | confirmed-source | `skills/project-standard-extractor/references/config/output-targets.md`, `docs/evals/project-standard-extractor/expected-behavior.md` |
| `ai-rules.md` 和 `review-checklist.md` 应从 `standard-{sub_domain}.md` 派生，不拥有独立规则来源。 | confirmed-source | `docs/evals/project-standard-extractor/expected-behavior.md` |
| 现有 full-auto 计划已把 high-confidence draft 缺少结构完整性 gate 识别为 P0 风险，并提出 `usable_now`、owner action、candidate provenance 等补强方向。 | confirmed-source | `docs/plans/2026-06-01-002-feat-output-artifact-contract-and-full-auto-plan.md` |
| 敏感配置、生产凭据、认证材料只允许记录脱敏存在事实，不得读取或输出原文。 | confirmed-source | `skills/project-standard-extractor/SKILL.md`, `skills/project-standard-extractor/references/agents/intake-and-scope.md` |
| 多层 Skill 契约曾出现入口、workflow、agents、prompts、templates、examples、evals 之间口径漂移；历史经验要求建立单一权威源和自动化防线。 | confirmed-source | `docs/solutions/architecture-patterns/multi-layer-skill-contract-drift-2026-05-23.md` |
| 实际 `engineering-standards/` 中存在早期编号专题结构、后续 skill 产物结构、占位 domain、正式 domain 索引和候选 run artifacts 并存；部分 Markdown 首行不是 Front Matter。 | confirmed-source | `engineering-standards/`, shell inspection 2026-06-01 |
| GitNexus 当前可作为文件定位线索，但图谱为 dirty-advisory、definitions-only，不能作为影响分析或已确认当前状态事实。 | gitnexus-pointer | `.spec-first/graph/graph-facts.json`, GitNexus query 2026-06-01 |

## Change Delta

| 变化类型 | 内容 | 涉及现有能力 | 风险/权限/数据影响 | 证据 tag |
| --- | --- | --- | --- | --- |
| replace | 默认体验从“两段式 profile-first + 人选 batch”改为“一步 full-auto 生成可使用规范文档”。 | 公开入口、workflow、planner、generation、merge | 提升自动化体验，同时扩大运行范围 | user-stated |
| keep | profile-first 仍作为内部前置阶段执行，用于建立边界、batch 队列、敏感排除和 evidence 预算。 | Intake、Profile、Batch Plan | 降低误萃取和敏感信息风险 | confirmed-source |
| extend | 两档自动执行：`status: ready` batch 产出高置信 draft 进 ai-rules；`pending-confirmation` batch 纳入执行产出 low-confidence draft 隔离到 `pending-confirmation.md`（不进 ai-rules）；skipped、blocked batch 不产出规范，进覆盖完整性报告。 | Planner、Batch Worker、orchestrator | 在「自动跑出全部」与证据治理间取平衡 | user-stated |
| extend | 输出覆盖完整性报告，列出 profile 识别矩阵项、batch 状态分布与缺口，让 owner 判断「全部」是否穷尽。 | Planner、orchestrator、review summary | 避免误以为已穷尽全部规范 | user-stated |
| extend | 每个 ready batch 仍按单 batch 边界执行 facts、classification、generation 和 quality gate，full-auto 由外层 orchestrator 串行迭代。 | Context Governance、generation profile | 避免全仓库无边界生成 | confirmed-source |
| extend | 跨 batch 聚合生成 standard、AI rules、review checklist、evidence、pending、conflict、candidate index 和 review summary。 | Generation、Merge | 需要去重、冲突归并和状态分层 | user-stated |
| extend | 增加机器可判定的产物契约，统一 required/optional artifacts、`doc_type`、`indexable`、candidate/formal、status 和消费角色。 | `output-targets.md`, `frontmatter-format.md`, templates, evals | 降低契约漂移 | user-stated |
| extend | 将 fast index 定义为一等消费 API，明确 root registry、domain registry、domain `rules-index`、`llms`、`ai-context-pack` 和 candidate artifacts 的职责边界。 | AI 快速索引 | 避免 AI 误读候选索引 | confirmed-source |
| extend | 增加结构完整性 gate，阻止 evidence-backed 但结构不足的 draft 进入 AI 默认消费路径。 | full-auto draft 生成 | 降低规则堆污染 AI 上下文风险 | confirmed-source |
| extend | 增加 owner decision queue、draft runtime policy 和 `usable_now`，让 draft/pending/conflict/rejected 的消费边界可被机器列出。 | owner 审批、review summary | 避免 draft 被当作 active | user-stated |
| extend | 增加 lineage / audit ledger，记录 evidence 到派生视图和索引的关系。 | evidence-first、派生视图 | 降低规则来源不可追溯风险 | user-stated |
| extend | 增加 drift linter/validator，把历史契约漂移模式固定成可检查项。 | public surface validator、evals | 降低回归风险 | confirmed-source |
| replace | 通过高置信自动升级闸（BR-016）的规则**自动标记为可直接使用**,无需逐条 owner 确认;未过闸者降级 draft/pending;owner 保留事后否决权。 | 发布治理、quality gate、merge | 满足「萃取即可用」终极目标,同时用高置信闸防止单样本/坏味道升权威 | user-stated |
| keep | 不恢复 Rule ID、HTML anchor、向量库或重型知识库；仍用 Front Matter 做文件级索引，`rules-index` 做规则级过滤。 | 快速索引设计 | 保持轻量治理 | confirmed-source |
| keep | Phase 2 dimension-aware、force-rebuild、restore、pin、unpin、list 不纳入普通 full-auto runtime。 | 维护者边界 | 避免 destructive IO 暴露 | confirmed-source |

## Decision Notes

- 002 是后续规划的统一 PRD。001 的核心目标已并入本文，后续不应让计划分别从两份 PRD 发明不同 WHAT。
- “一步到位”指用户路径不再停在 batch selection；不是指内部跳过 profile-first、batch 边界、evidence、review 或 validator。
- “可使用 draft”必须同时满足 evidence、结构完整性、派生追溯、索引一致性和 runtime policy；只满足 evidence 的规则不能直接进入 AI 默认规则。
- fast index 是产品 API，不是临时副产物；候选与正式入口必须分离。
- owner 从 in-the-loop 选择 batch 迁移为 on-the-loop 审批。
- **【产品定位转向 2026-06-02：萃取即权威】** 用户明确终极目标是「萃取直接输出一套可直接使用的代码开发规范」（开箱即用,像阿里手册可直接发团队/喂 AI）。据此转向:**通过高置信自动升级闸（BR-016）的规则自动标记为「可直接使用」,不再逐条等 owner 手动确认**。这取代了原 001/002 及历史版本中「active 仅由 owner 手动确认」的核心定位。
  - **保留的护栏**:自动升级**必须**过高置信闸（occurrences≥2 + confidence:high + 多角色覆盖 + evidence 充分 + 无 conflict + 结构完整）——防止单样本/�avbe味道代码被升为团队强制规范。达不到的仍降级 draft/pending。
  - **owner 角色**:从「逐条确认才生效」变为「事后可否决/降级任何自动升级规则」(on-the-loop 保留最终 ownership,但不阻塞默认产出)。
  - **已知风险(用户知情接受)**:(1) AI 从单项目现状自封团队标准,坏味道可能被固化;(2) single-project 证据升权威的代表性风险;(3) 团队若发现自动规范有错可能损失信任。高置信闸是对这三者的缓解,非消除。
  - **默认体验**:用户跑一次 full-auto,「打开就有一批可直接使用的规范」,而非「打开全是待确认 draft」。
- 「自动跑出全部规范」的边界：ready + pending-confirmation 两档都自动执行（前者进 ai-rules，后者隔离为 low-confidence draft）；skipped/blocked 与 profile 漏识别项不伪造规则，而是在覆盖完整性报告里诚实列出缺口。「全部」= 能产出的全部产出 + 不能产出的全部列明，绝不为追求覆盖率违反 BR-001 证据治理。

## Actors

- A1. Skill 使用者：提供现有项目路径，期望一次运行得到可使用规范文档。
- A2. Full-auto orchestrator：自动执行 profile-first、ready batch queue、逐 batch worker、跨 batch aggregation 和最终 summary。
- A3. Batch worker：在单 batch 边界内执行 facts、classification、generation 和 quality gate。
- A4. 规范 owner：审查 high-confidence draft、pending、conflict、legacy、rejected，决定是否升级 `active`。
- A5. AI 编码使用者：消费 AI rules、fast index 和 context pack，避免执行 pending/conflict/rejected 内容。
- A6. Reviewer：消费 review checklist 检查人工或 AI 生成代码。
- A7. 规范维护者：验证产物结构、索引发布、契约一致性和历史漂移风险。
- A8. 目标代码仓库：提供真实代码、manifest、README、目录结构、正反例和历史兼容证据。

## Requirements

> 编号说明：R-01..R-15 延续原 002 的产物契约要求；R-16..R-32 吸收并融合 001 的一步 full-auto 生成要求。后续新增需求从 R-33 起。

### 产物契约与消费要求

| 编号 | 优先级 | 触发条件 | 角色 | 系统行为 | 用户可见结果 |
| --- | --- | --- | --- | --- | --- |
| R-01 | P0 | 生成或校验任意 domain 规范产物 | pipeline | 应有单一产物契约说明每类 artifact 的必需性、`doc_type`、Front Matter 字段、`indexable` 默认值、candidate/formal 状态、消费角色和发布条件。 | 使用者能判断目录缺什么，不靠人工猜测。 |
| R-02 | P0 | domain 目录生成完成或进入发布前校验 | validator | 应检查必需文件、Front Matter、`doc_type`、`index_format`、`indexable`、规则 H2 前缀、无 Rule ID / anchor、run-level artifact 默认不可索引。 | 不合格产物被明确标出阻断原因。 |
| R-03 | P0 | 生成或发布 fast index | pipeline | 应区分 candidate index 和正式消费 index；candidate 不得覆盖正式 `rules-index`、`llms` 或根入口。 | 用户知道哪些索引只是候选，哪些会被 AI 默认读取。 |
| R-04 | P0 | AI 需要定位规则 | fast-index consumer | 应能通过 domain、sub_domain、task_type、level、status、evidence_tier、risk、tags 过滤规则，并用 `source_doc + section_title` 定位正文。 | AI 不需要全文扫描所有规范。 |
| R-05 | P0 | `rules-index` 指向规范正文 | validator | 应验证每条 `rules-index` 的 `source_doc` 存在，`section_title` 与正文 H2 字面一致，且不使用 `rule_id` 或 `anchor`。 | 失配索引不会进入正式消费路径。 |
| R-06 | P0 | high-confidence draft 准备进入 AI rules 或 ai-context-pack | quality gate | 应先通过结构完整性 gate；低于结构底线的 batch 或规则集只能进入 pending/review summary，不能进入 AI 默认执行规则。 | “可使用 draft”不会退化为规则堆。 |
| R-07 | P0 | AI 消费规则 | runtime policy | 应明确 `active` 是团队强约束；high-confidence evidence-backed draft 可作为工作输入但必须可见标识风险；pending/conflict/rejected/none-evidence 永远不得进入 AI 默认执行路径。 | AI 使用者能区分强约束和待确认规则。 |
| R-08 | P0 | 生成 `ai-rules.md` 或 `review-checklist.md` | pipeline | 每条 AI rule 和 review check 必须引用来源 `standard` 章节和 evidence；不得独立新增规则。 | 派生视图可追溯到规范正文。 |
| R-09 | P0 | domain 目录被人或 AI 打开 | consumer control surface | 应提供一个第一屏入口，说明 AI 编码、人工 Review、owner 审批、维护者审计各自应读取哪些文件、哪些文件不能作为执行规则。 | 不同角色从同一个 domain 入口进入，不误用占位文档。 |
| R-10 | P1 | 运行完成并存在 draft/pending/conflict/legacy/rejected | owner workflow | 应输出 owner decision queue，列出规则标题、二元组定位、evidence、风险、`recommended_action`、`usable_now` 和阻断原因。 | owner 不必全文扫描即可处理后续决策。 |
| R-11 | P1 | 需要审计规则来源 | audit consumer | 应提供 lineage / audit ledger，记录 `evidence -> standard -> ai-rules -> review-checklist -> rules-index` 的派生关系和质量门禁结果；ledger 默认不进入 AI 执行上下文。 | Reviewer 和维护者能验证派生视图没有造规则。 |
| R-12 | P1 | 校验已有仓库或未来变更 | linter | 应检查旧路径、旧 schema、`.index` 与 domain index 口径冲突、Rule ID / anchor、candidate 误发布、auto active、`activation-report` 误用于 Phase 1 等历史漂移模式。 | 契约漂移能在评审前暴露。 |
| R-13 | P1 | domain 主要是占位或 no-evidence | pipeline | 应在入口和索引中明确该 domain 当前不可作为 AI 默认执行规则来源。 | PC、Frontend、Backend、Industry 等占位目录不会被误认为已可执行。 |
| R-14 | P1 | 运行完成输出 review summary | pipeline | 应给出机器可判定的 `usable_now` 结论、原因、可消费文件列表、阻断项和 owner 后续动作。 | 用户知道本次结果是否能直接进入开发使用。 |
| R-15 | P2 | 建立回归测试 | maintainer | 应提供覆盖典型 domain、placeholder domain、candidate index、bad frontmatter、orphan ai-rule、section mismatch 的 golden fixtures。 | 后续改动可通过 fixture 回归发现产物契约破坏。 |

### 一步 full-auto 生成要求

| 编号 | 优先级 | 触发条件 | 角色 | 系统行为 | 用户可见结果 |
| --- | --- | --- | --- | --- | --- |
| R-16 | P0 | 使用者提供一个或多个 `project_paths` | orchestrator | 应校验路径存在、可读、授权范围和敏感路径策略；无有效路径时停止并给出 `NO_VALID_PROJECT_PATHS`。 | 用户获得可执行范围或明确失败原因。 |
| R-17 | P0 | 输入是完整仓库、多服务、多 manifest、多个研发域或范围不明确 | orchestrator | 必须先执行内部 profile-first，生成项目画像、extraction map、batch plan 和 ordered batch queue。 | 用户不需要手动选 batch，也能看到运行边界。 |
| R-18 | P0 | profile-first 完成 | orchestrator | 应自动执行 `status: ready` 的 batch（高置信档）；`status: pending-confirmation` 的 batch 也纳入执行（低置信隔离档），产出标记为 `low-confidence draft` 写入 `pending-confirmation.md`，**不进 `ai-rules.md` 默认执行**；`skipped`（无代表性候选）、`blocked`（权限/敏感）batch 不产出规范，进覆盖完整性报告（R-33）。 | 用户一次运行拿到「证据充分（高置信）+ 有方向（低置信隔离）」两档覆盖，证据缺失项不被伪造为规则。 |
| R-19 | P0 | 多个 ready batch 被执行 | batch worker | 每个 batch 必须独立读取 candidate files、独立记录 evidence 和 stop conditions；单 batch 失败不得污染其他 batch。 | review summary 标明每个 batch 的成功、pending、conflict 或失败状态。 |
| R-20 | P0 | 进入 facts 阶段 | batch worker | 只应从当前 batch 的 candidate files 中提取描述性 code facts、signal hits 和 classification candidates，不得在 facts 阶段写规范结论。 | 后续规则能追溯到具体 fact。 |
| R-21 | P0 | 对代码事实做分类 | batch worker | 必须区分 recommended、forbidden、legacy_compatible、pending_confirmation、conflict、rejected；规则分类枚举不得与 batch status 枚举混用。 | 历史旧写法、反例、低证据项和冲突不会混入推荐规则。 |
| R-22 | P0 | 单个 ready batch 进入 generation | batch worker | 应使用 `phase1-selected-batch` 输入剖面生成该 batch 的 evidence-backed draft standard 内容，不读取 `activation-report` 或 `dimension-activator`。 | 每个 batch 产出可合并的规范片段。 |
| R-23 | P0 | 所有 ready batch 完成或跳过 | orchestrator | 应聚合生成可使用的 `standard-{sub_domain}.md`、`ai-rules.md`、`review-checklist.md`、evidence、pending、conflicts、candidate index 和 review summary。 | 用户一次运行后得到完整规范资产。 |
| R-24 | P0 | 新规则通过质量门禁 | merge | 应以 append-only 方式写入 draft、pending、conflict、legacy 或 merge suggestion；不得覆盖已有 active 或 draft。 | 既有团队规范不会被隐式替换。 |
| R-25 | P0 | 规则涉及敏感配置、生产凭据、token、私钥、用户数据或生产环境信息 | pipeline | 只允许记录脱敏存在事实，不得读取、复制、转述或输出原文片段。 | 规范产物不泄露敏感信息。 |
| R-26 | P0 | 候选规则缺 evidence、证据代表性不足、结构不完整或必须人工判断 | pipeline | 应将候选内容写入 pending、legacy、conflict 或 rejected，不得写入 AI 默认强制规则。 | 用户看到可审查项，AI 不会默认执行低证据规则。 |
| R-27 | P1 | 跨 batch 产出相似或相反规则 | merge | 相近内容应去重或写入 `merge-suggestions.md`；相反规则写入 `conflicts.md`。 | owner 能显式裁定合并或冲突。 |
| R-28 | P1 | 运行质量门禁 | quality gate | 应覆盖 evidence、团队级抽象、结构完整性、AI 可执行性、Review 可检查性、冲突、行业风险、上下文治理和跨 batch 聚合质量。 | 进入可使用文档的规则经过多维审查。 |
| R-29 | P1 | GitNexus 可用或不可用 | pipeline | 可用时只能作为 advisory evidence 或定位线索；陈旧、dirty、impact-unavailable 时必须降级并记录限制，candidate_files 的选择来源也必须保留 provenance。 | 规则不会只凭陈旧图谱事实成立。 |
| R-30 | P1 | 运行完成 | orchestrator | 应输出 review summary，汇总 batch 结果、draft/pending/conflict/rejected 分布、降级原因、`usable_now` 和 owner 待处理动作。 | 用户知道哪些规则可立即作为工作输入，哪些需要确认。 |
| R-31 | P1 | 同一 sub_domain 被多个 batch 或重复运行命中 | merge | 应使用稳定 section title 归一化和 existing index 对齐，避免近义规则因标题漂移无限追加。 | full-auto 不会把 append-only 变成规则污染放大器。 |
| R-32 | P2 | 聚焦模块输入而非完整仓库 | orchestrator | 可支持 focused-module 一步生成；若只是 full-repo 路径自然子集，不应新增独立路由复杂度，仍必须遵守 evidence、敏感信息、draft-only、结构 gate 和 append-only 规则。 | 小范围模块也能直接产出可使用规范文档。 |
| R-33 | P0 | 运行完成 | orchestrator | 应输出**覆盖完整性报告**（coverage report），列出 profile 识别到的全部 `domain × sub_domain × task_type` 矩阵项、每项 batch 归属与状态（ready/pending/skipped/blocked）、未识别或低置信归因的疑似遗漏点，以及「本次全部覆盖 vs 缺口」清单。 | 用户能判断「自动跑出的全部」覆盖了多少、漏了什么、为什么漏，而不是误以为已穷尽。 |
| R-36 | P0 | 规则通过质量门禁(定位转向 2026-06-02:萃取即权威) | quality gate | 应运行**高置信自动升级闸**(BR-016):满足 occurrences≥2 + confidence:high + 多角色/多文件覆盖 + evidence 充分 + 无未裁定 conflict + 通过结构完整性 gate 的规则,**自动标记为可直接使用**(进 ai-rules/review-checklist 默认执行路径),无需逐条 owner 确认;不满足者降级 draft/pending。owner queue 仍列出全部自动升级规则供事后否决/降级。 | 用户一次运行即得到一批可直接使用的规范,而非全是待确认 draft;同时单样本/坏味道不被自动升权威。 |

## Business Rules

- BR-001：没有代码 evidence 的内容，不得写成 AI 默认强制执行规则。（定位转向 2026-06-02：evidence 充分性是硬门槛；owner 确认不再是「可直接使用」的前置，但仍是高置信自动升级闸的组成判据之一——见 BR-016。）
- BR-002：通过**高置信自动升级闸**（BR-016）的 evidence-backed 规则**自动标记为可直接使用**（`auto-active` 或等价状态），无需逐条等 owner 确认；未通过闸的规则仍降级 draft/pending，不进 AI 默认执行。（取代原「active 仅由 owner 手动确认」——见 Decision Notes 定位转向。）
- BR-016：**高置信自动升级闸**。规则自动升为「可直接使用」必须同时满足：`occurrences ≥ 2`、`confidence: high`、多角色/多文件覆盖、evidence 充分、无未裁定 conflict、通过结构完整性 gate。单样本（`occurrences = 1` / `single-sample`）、`single-project` 孤证、有 conflict、结构不足者**一律不得自动升级**,仍走 draft/pending。owner 仍可事后降级或裁定任何自动升级的规则（on-the-loop 保留否决权,但不再是 in-the-loop 前置）。
- BR-003：完整仓库输入必须先内部 profile-first，再自动执行 ready batch queue；不得把完整仓库作为一个无边界上下文直接交给 generation。
- BR-004：full-auto 应通过外层 orchestrator 逐 batch 调用单-batch pipeline；单次 facts/generation 调用仍只处理一个 batch。
- BR-005：敏感文件只记录脱敏存在事实；如果继续萃取必须读取敏感原文，pipeline 必须停止对应 batch。
- BR-006：`standard-{sub_domain}.md` 是规范正文来源；`ai-rules.md` 和 `review-checklist.md` 只能作为派生视图。
- BR-007：pending、conflict、rejected、none-evidence、结构不完整和 legacy-compatible 不得进入 AI 默认执行规则。
- BR-008：规范正文不得包含真实本地绝对路径；项目路径证据只允许在 evidence 中以可审查且不泄密的形式出现。
- BR-009：产物契约是生成、模板、eval、validator 和用户手册的共同判断口径；同一字段不得在多层文档中出现不兼容定义。
- BR-010：正式 AI 消费路径不得读取 candidate artifacts，除非用户显式选择候选上下文。
- BR-011：规则定位继续使用 `source_doc + section_title`；不得引入 Rule ID 或 HTML anchor 作为 V1 强依赖。
- BR-012：Front Matter 只做文件级索引；规则级过滤由 `rules-index` 负责。
- BR-013：run-level handoff、review report、review summary、lineage ledger 和 owner queue 默认不进入 AI 默认规则上下文。
- BR-014：占位 domain 必须显式标记为不可执行，不能只靠空内容或散文描述隐含表达。
- BR-015：Phase 2 blocked / repair-only 能力不得作为普通 full-auto 用户路径宣传或执行。

## Scope Boundaries

### 本期做

- 从现有代码路径一步生成可使用团队级开发编码规范文档。
- 支持完整单仓库输入自动画像、batch queue、逐 batch 萃取、质量门禁和聚合。
- 支持两档自动执行：ready batch 产出高置信 draft；pending-confirmation batch 产出 low-confidence draft 并隔离（不进 ai-rules 默认执行）；skipped、blocked batch 不产出规范、进覆盖完整性报告。
- 支持 high-confidence draft、low-confidence draft、pending、legacy、conflict、rejected 的质量分层。
- 支持生成 `standard-*`、`ai-rules.md`、`review-checklist.md`、evidence、candidate index、review summary、覆盖完整性报告、owner decision queue 和 lineage / audit ledger。
- 定义机器可判定的产物契约和 validator/linter 结果。
- 明确 fast index 的正式/候选边界、root/domain 职责和 AI 最小加载路径。
- 校验 Front Matter、`doc_type`、`indexable`、规则标题、`rules-index` 与正文一致性。
- 为 high-confidence draft 增加 evidence + 结构完整性 gate。
- 为 AI 默认消费路径定义 draft/active/pending/conflict/rejected runtime policy。
- 支持 GitNexus 作为 advisory pointer，并在不可用、陈旧或 impact-unavailable 时降级。

### 本期不做

- 不自动发布 `active` 规范。
- 不把完整仓库直接作为无边界上下文生成最终规范。
- 不建设规范管理 Web 平台。
- 不执行业务代码修改、bug 修复或 PR 代码评审。
- 不生成脱离代码 evidence 的行业通用最佳实践。
- 不引入 Rule ID、HTML anchor、向量库或重型知识库。
- 不强制重排所有历史 `engineering-standards/` 目录。
- 不把 Diátaxis 四象限改造成新的物理目录结构。
- 不把 low-evidence 占位规范包装成可执行团队规则。
- 不自动删除或改写用户已有规范内容。
- 不把 Phase 2 dimension-aware、cross-project、EA-Doc、securities PoC、force-rebuild、restore、pin、unpin、list 作为普通用户 runtime。
- 不覆盖已有 active / draft 规则。

### 与其它需求的关系

- `docs/brainstorms/2026-06-01-001-project-standard-extractor-code-standard-extraction-requirements.md` 的 full-auto 主线已并入本文；后续规划以 002 为准。
- `docs/brainstorms/2026-05-26-002-project-standard-extractor-full-auto-draft-pipeline-requirements.md` 是 full-auto draft pipeline 的前置方向。
- `docs/plans/2026-06-01-002-feat-output-artifact-contract-and-full-auto-plan.md` 已识别 full-auto 的 P0/P1 实施风险；本文把其中的产物契约、结构 gate、runtime policy、`usable_now`、candidate provenance 和 validator/linter 上升为统一产品要求。
- `docs/ideation/2026-06-01-project-standard-extractor-output-artifacts-ideation.md` 是产物结构与规范落地的 ideation 输入。
- `docs/02-技术方案/AI快速索引最终方案.md` 是 fast index 的既有设计基础；本文不推翻轻量索引原则。

## Goals / Success Metrics

| 目标 | 可观察口径 |
| --- | --- |
| 一步到位生成可使用规范 | 用户提供完整单仓库路径后，一次运行能完成 profile、ready batch queue、per-batch generation、quality gate、merge aggregation、validator 和 review summary。 |
| 产物可判定 | 对任一 domain 目录，validator 能输出 PASS / BLOCK / WARN，并列出缺失 artifact、Front Matter、索引和派生关系问题。 |
| AI 可最小加载 | AI 能从入口定位到当前 domain/sub_domain/task_type 的相关规则，不需要全文扫描 `engineering-standards/`。 |
| 可使用 draft 不退化 | 进入 AI rules 或 ai-context-pack 的 draft 必须同时满足 evidence、结构完整性和派生追溯要求。 |
| 派生视图可追溯 | 每条 AI rule 和 review check 都能回到 `standard` 章节和 evidence。 |
| owner 决策可操作 | 每次运行后，owner 能看到结构化待处理项、推荐动作、`usable_now` 和阻断原因。 |
| 降低误发布风险 | draft、pending、legacy、conflict、rejected、active 的状态边界在 review summary 和 fast index 中清晰可见。 |
| 降低泄密风险 | 敏感路径只出现脱敏存在事实，无凭据原文或绝对本地路径泄露。 |
| 结果价值可度量 | 后续效果不以规则数量、行数或字段数衡量，而以 draft 升级 active 的资产化率、AI 正确复用率、Review 拦截价值和反范式复发率衡量。 |

## Acceptance Examples

### Full-auto 生成验收

- AE-01（覆盖 R-16, R-17, R-18, R-23）
  Given 使用者提供一个完整 git 仓库路径，when 启动 extractor，then pipeline 应先内部生成画像和 batch 队列，再自动执行 ready batch，最终输出可使用 `standard-*`、`ai-rules.md`、`review-checklist.md` 和 review summary，且不要求用户中途选择 batch。

- AE-02（覆盖 R-19, R-20, R-22）
  Given ordered batch queue 中有 3 个 ready batch，其中第 2 个 evidence 不足，when pipeline 执行，then 第 1 和第 3 个 batch 可继续生成并聚合，第 2 个 batch 进入 pending 或 failed summary，不得污染其它 batch 结论。

- AE-02b（覆盖 R-18, R-33）
  Given profile-first 产出 4 个 batch：2 个 ready、1 个 pending-confirmation、1 个 skipped（无代表性候选），when full-auto 执行，then 2 个 ready batch 产出高置信 draft 进 ai-rules，pending-confirmation batch 产出 low-confidence draft 隔离到 `pending-confirmation.md`（不进 ai-rules），skipped batch 不产出规范，且覆盖完整性报告列出全部 4 项的状态与「skipped 项=缺口」清单。

- AE-03（覆盖 R-21, R-26）
  Given 某个写法只在单个历史迁移模块出现且没有正向复用证据，when pipeline 做分类和生成，then 该内容应进入 legacy 或 pending，不得进入 recommended draft 规则。

- AE-04（覆盖 R-24, R-27, R-31）
  Given 目标 domain 已存在 active 规则，when 新候选规则与该 active 规则语义冲突或标题近义漂移，then pipeline 应写入 `conflicts.md` 或 `merge-suggestions.md`，不得覆盖、降级既有 active 规则，也不得无限追加近义规则。

- AE-05（覆盖 R-25, BR-005）
  Given candidate files 命中生产凭据、token、私钥或 secret 配置，when pipeline 需要处理该路径，then 它只能记录脱敏存在事实；如果必须读取原值才能继续，则停止对应 batch 并报告 `SENSITIVE_FILE_BLOCKED`。

- AE-06（覆盖 R-28, R-30）
  Given generation 产出多个 batch 的 draft 规则，when quality gate 和 merge aggregation 执行，then `ai-rules.md` 和 `review-checklist.md` 只包含可追溯 high-confidence draft 规则，并且 review summary 列出 evidence、结构完整性、AI 可执行性、Review 可检查性、冲突、`usable_now` 和推荐处理动作。

- AE-07（覆盖 R-29）
  Given `.spec-first/graph/graph-facts.json` 显示 GitNexus stale 或 impact unavailable，when pipeline 需要结构性代码事实，then GitNexus 只能作为定位线索，candidate files 必须记录选择来源并经 direct-scan 复核，最终规则必须由源码、文档或 owner 确认支撑。

- AE-08（覆盖 R-32）
  Given 使用者只提供一个聚焦模块路径，when workflow 进入 focused-module full-auto，then 可以直接生成可使用规范文档，但仍必须生成 evidence-backed draft，并遵守敏感信息、draft-only、结构 gate 和 append-only 规则。

### 产物契约与消费验收

- AE-09（覆盖 R-01, R-02）
  Given 一个 domain 目录缺少必需 Front Matter 或 `doc_type` 不在枚举内，when validator 执行，then 它应输出 BLOCK，并指出具体文件、字段和期望值。

- AE-10（覆盖 R-03）
  Given 一次运行生成 `temp/{run_id}-rules-index-candidate.json`，when 未得到用户显式发布确认，then candidate 不得覆盖正式 `rules-index.json`、根入口或 domain 入口。

- AE-11（覆盖 R-04, R-05）
  Given `rules-index` 中某条规则的 `section_title` 与 `source_doc` 内 H2 标题不一致，when 发布前校验，then 该 index 不能进入正式消费路径，并给出 mismatch 位置。

- AE-12（覆盖 R-06, R-07）
  Given 某 batch 有 evidence-backed draft 规则但缺少技术栈、核心分层/角色或必需规则节，when quality gate 判断可使用性，then 该 batch 不得进入 AI 默认执行规则，应进入 pending 或 review summary 阻断项。

- AE-13（覆盖 R-07, R-13）
  Given 一个 domain 仅包含占位 `standard.md` 和 no-evidence policy，when AI 读取入口，then 入口和索引应明确该 domain 当前不可作为默认执行规则来源。

- AE-14（覆盖 R-08, R-11）
  Given `ai-rules.md` 中出现一条无法回溯到 `standard` 章节和 evidence 的规则，when lineage 校验执行，then validator 应报告 orphan derived rule，并阻断该派生视图发布。

- AE-15（覆盖 R-09, R-10, R-14）
  Given 一次 full-auto 运行产生 draft、pending 和 conflict，when 用户打开 domain 入口或 review summary，then 应能看到 `usable_now`、可读文件列表、不可读文件列表、owner 待处理队列和每项推荐动作。

- AE-16（覆盖 R-12, R-15）
  Given 文档中重新出现 `rule_id`、HTML anchor、旧 `.index` 口径、auto active 或 Phase 1 强制 `activation-report`，when drift linter 执行，then 应输出 WARN 或 BLOCK，并指向对应契约来源；对应 fixture 应能在回归中复现。

## Evidence And Assumptions

### Evidence

- confirmed-source：`skills/project-standard-extractor/SKILL.md` 定义当前公开目的、输入、稳定流程、输出、安全边界和失败模式。
- confirmed-source：`skills/project-standard-extractor/references/workflow.md` 定义当前稳定公开路径和 Phase 2 blocked / repair-only 边界。
- confirmed-source：`skills/project-standard-extractor/references/agents/profile-and-batch-planner.md` 定义 profile-first、batch plan 和 ordered batch queue 语义。
- confirmed-source：`skills/project-standard-extractor/references/agents/generation.md` 定义 `phase1-selected-batch` 输入剖面、evidence writer、developer guide、AI rules 和 checklist 派生。
- confirmed-source：`skills/project-standard-extractor/references/agents/review-and-quality-gate.md` 定义多 persona 质量门禁。
- confirmed-source：`skills/project-standard-extractor/references/agents/merge-coordinator.md` 定义 append-only、冲突、pending 和候选产物写入策略。
- confirmed-source：`skills/project-standard-extractor/references/config/output-targets.md` 定义现有产物文件、写入规则、doc_id、append-only、Front Matter 和 candidate index 边界。
- confirmed-source：`skills/project-standard-extractor/references/config/frontmatter-format.md` 定义 Front Matter、`doc_type`、文档级/规则级状态、规则标题和 `(source_doc, section_title)` 定位。
- confirmed-source：`docs/evals/project-standard-extractor/expected-behavior.md` 定义可检查结果、Front Matter、Evidence-first、Context Governance、Fast Index Candidates、状态边界和成功指标反模式。
- confirmed-source：`docs/02-技术方案/AI快速索引最终方案.md` 定义轻量快速索引原则：入口文件、规则索引、最小规范集。
- confirmed-source：`docs/brainstorms/2026-05-26-002-project-standard-extractor-full-auto-draft-pipeline-requirements.md` 已定义 full-auto draft pipeline 的自动 batch queue、质量分层和 owner approval 边界。
- confirmed-source：`docs/brainstorms/2026-06-01-001-project-standard-extractor-code-standard-extraction-requirements.md` 是本文吸收的一步生成需求来源。
- confirmed-source：`docs/plans/2026-06-01-002-feat-output-artifact-contract-and-full-auto-plan.md` 已把结构完整性 gate、draft runtime policy、`usable_now`、candidate provenance 和 index/contract 漂移列为高风险或待补项。
- confirmed-source：`docs/solutions/architecture-patterns/multi-layer-skill-contract-drift-2026-05-23.md` 记录多层契约漂移的历史失败模式。
- confirmed-source：`engineering-standards/` 当前同时存在早期编号专题、skill 新结构、正式 domain index、candidate artifacts 和占位 domain。
- gitnexus-pointer：GitNexus 查询返回相关文件指针；由于 graph facts 为 dirty-advisory 且 impact/review 不可用，本文不把 GitNexus 输出作为 confirmed source。

### Assumptions

- assumption：本文中“可使用”指 high-confidence evidence-backed draft 可用于 AI 编码和 Review，仍保留 draft 状态、风险标识和 owner 后续确认边界。
- assumption：规范 owner 愿意在生成后承担 active 升级和 conflict 裁定职责。
- assumption：目标代码仓库由使用者授权读取，且 pipeline 有能力跳过敏感文件或只记录脱敏存在事实。
- assumption：V1 可以保留现有 domain 目录，不需要一次性迁移所有历史文件到新物理结构。
- assumption：owner decision queue 和 lineage ledger 可以作为结构化产物存在，但默认不进入 AI 执行上下文。
- assumption：root registry 的最终文件名可由计划阶段裁定；本 PRD 要求先明确职责边界，不强制把 `.index/` 作为唯一物理路径。

## Outstanding Questions

### Resolve Before Planning

- 无阻塞问题。用户已明确默认体验应一步到位，并要求将 001 方案融合到 002；本文可作为 `$spec-plan` 的统一输入。

### Deferred to Planning

- [Affects R-01, R-03, R-04] root registry、domain registry 和正式 `rules-index` 的具体文件名、位置和发布命令。
- [Affects R-06, R-28] 结构完整性 gate 的最小章节集、skeleton 命中规则、无 skeleton fallback 和判定字段。
- [Affects R-10, R-14, R-30] owner decision queue 与 review summary 是同一文件内结构化 section，还是独立 JSON/Markdown 产物。
- [Affects R-11] lineage / audit ledger 的最小字段集，避免复制规则正文造成第二套规则源。
- [Affects R-12, R-15] validator/linter 与现有 public-surface validator、eval fixtures 的集成边界。
- [Affects R-18, R-19] full-auto 队列总 batch 上限、失败标记、是否重试和是否定义 wall-clock timeout。
- [Affects R-21, R-24] phase1 classification bucket 到 merge `target_state` 的路由映射，以及 `dimension_state` 在 phase1 路径的 sentinel / nullable 规则。
- [Affects R-27, R-31] 跨 batch 去重、section title 归一化和 existing index 对齐策略。
- [Affects R-29] candidate file selection provenance 的记录位置和 direct-scan 复核标准。

## Readiness

- outcome: ready-for-planning
- current-state accuracy: PASS，关键现状来自 repo 文档、eval、实际目录检查和明确 GitNexus 降级说明。
- change delta clarity: PASS，本文明确把 001 的 full-auto 用户路径和 002 的产物契约治理合并为统一增量。
- exception coverage: PASS，覆盖无路径、batch 失败、低 evidence、结构不足、敏感文件、冲突、GitNexus 降级、candidate 误发布、Front Matter 缺失、索引失配、占位 domain 误用、派生视图孤儿规则和契约漂移。
- planning invention risk: LOW，计划阶段需要决定 artifact 名称、validator 集成、gate 字段和若干执行模型细节，但不需要重新发明 WHAT。
- terminology ambiguity: LOW，沿用当前仓库术语：profile-first、ordered batch queue、phase1-selected-batch、Front Matter、`doc_type`、`indexable`、`rules-index`、`ai-context-pack`、draft、active、pending、conflict、rejected。
