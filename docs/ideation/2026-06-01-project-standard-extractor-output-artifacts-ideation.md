---
date: 2026-06-01
topic: project-standard-extractor-output-artifacts
focus: 产物目录结构、快速索引和产物文档是否满足开发规范落地
mode: repo-grounded
---

# Ideation: project-standard-extractor 产物结构与规范落地

## Grounding Context

### Codebase Context

`project-standard-extractor` 已有较完整的产物骨架：`output-targets.md` 定义 `overview.md`、`standard-{sub_domain}.md`、`ai-rules.md`、`review-checklist.md`、`evidence/*`、`pending-confirmation.md`、`merge-suggestions.md`、`conflicts.md`、运行级 `temp/{run_id}-*` 和候选 fast-index artifacts。`frontmatter-format.md` 定义 Markdown Front Matter、规则标题前缀和 `(source_doc, section_title)` 二元组定位；`expected-behavior.md` 明确不使用 Rule ID / HTML anchor，且 `rules-index` 候选不得默认覆盖正式入口。

现状判断：目录结构和模板足以作为第一版规范产物基础，但还不能稳定回答“产物文档是否满足开发规范”。主要缺口是：实际 `engineering-standards/` 中大量 Markdown 首行不是 Front Matter；根 `.index/` 不存在但技术方案和手册反复提到；正式 domain 索引落地不均；候选索引、正式索引、draft、active 的消费边界仍依赖说明文字；full-auto 后如果缺结构完整性 gate，产物可能退化成规则堆。

### Past Learnings

- `docs/solutions/architecture-patterns/multi-layer-skill-contract-drift-2026-05-23.md` 表明该 skill 曾因 `SKILL.md` / workflow / agents / templates / evals 多层契约漂移导致产物回退到旧格式。任何新产物结构都必须有单一权威源和验证闭环。
- `docs/plans/2026-05-21-003-refactor-lightweight-fast-index-plan.md` 已定下轻量快速索引原则：Front Matter 做文件级索引，`rules-index` 做规则级过滤，不引入 Rule ID、HTML anchor、向量库或重型知识库。
- 最新 full-auto 计划已指出：若 high-confidence draft 缺少结构完整性 gate，一步生成会降低 owner 成本但损害 AI 上下文质量。

### External Context

- [Diátaxis](https://diataxis.fr/) 提醒文档应按读者任务区分 tutorial / how-to / reference / explanation。对本项目的迁移点是：规范产物不能只按生成文件类型陈列，还要给 AI 编码、人工 Review、owner 审批、维护者审计不同入口。
- [OpenAI Codex AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md)、[AGENTS.md standard](https://agents.md/index) 和 [Claude Code memory](https://code.claude.com/docs/en/memory) 都强调 agent 可消费指令需要短入口、作用域和就近覆盖语义。对本项目的迁移点是：目录和索引应表达作用域、优先级、来源路径和是否可执行。
- [Google Engineering Practices: Code Review](https://google.github.io/eng-practices/review/) 与 [GitLab Code Review Guidelines](https://docs.gitlab.com/development/code_review/) 强调作者责任和 reviewer 责任不同。对本项目的迁移点是：`ai-rules.md`、author preflight、reviewer checks 不应混成同一类消费视图。

## Ranked Ideas

### 1. 产物契约 Manifest + Domain Artifact Validator

**Description:** 将 `output-targets.md`、`frontmatter-format.md`、模板、eval 中散落的目录结构、`doc_type`、`indexable`、candidate/正式边界收敛成一个机器可读 manifest，再由它派生文档说明、模板校验和只读 validator。validator 检查每个 `engineering-standards/<domain>/` 是否满足必须文件、Front Matter、运行级 artifact `indexable:false`、candidate 不覆盖正式入口、无 `rule_id` / `anchor`、`rules-index.section_title` 与 H2 字面一致。

**Basis:** `direct:` `output-targets.md` 已定义统一输出文件、写入规则、doc_id 和 handoff/candidate 边界；`frontmatter-format.md` 要求所有 Markdown 产物包含 YAML Front Matter；历史 learning 明确多层契约漂移要用单一权威源和确定性校验兜住。

**Rationale:** 这是最根本的改进。现在的问题不是缺少文件类型，而是“文件类型、模板、eval、文档说明和实际目录”之间没有一个机器可判定的共同源。先把产物契约 manifest 化，后续快速索引、文档入口、owner 审批和 full-auto 结构 gate 才能稳定演进。

**Downsides:** 需要先定义 manifest schema，并迁移现有 prose 契约；短期会增加一个新权威文件，必须避免它变成第五套重复契约。

**Confidence:** 92%

**Complexity:** Medium

**Status:** Unexplored

### 2. Fast Index 作为一等 API

**Description:** 把 fast index 从运行附属物升级为规范产品的核心 API：明确 root registry、domain registry、`rules-index`、`llms` 和 `ai-context-pack` 的职责边界。保留 `(source_doc, section_title)`，但增强索引字段，支持按 domain、sub_domain、task_type、level、risk、status、evidence_tier、tags 和 applicable scope 做两跳定位。

**Basis:** `direct:` `docs/02-技术方案/AI快速索引最终方案.md` 已定义“先读入口文件，再查规则索引，最后只加载当前任务相关规范”；`expected-behavior.md` 已要求 `rules-index` 候选使用 `title/domain/sub_domain/level/source_doc/section_title/evidence_doc/tags` 且不得包含 `rule_id` 或 `anchor`。

**Rationale:** 用户关心“产物文档是否满足开发规范”，本质上是在问 AI 和 Reviewer 能否快速、准确、最小化加载规则。当前索引更多是候选产物；应把它当 API 来设计，有 schema、有兼容性、有发布边界、有根/域职责。

**Downsides:** 如果过早引入全局 `.index/`，可能与当前 domain 级 `rules-index.json` 冲突。第一步应先裁定 root vs domain index 的职责，而不是直接新增目录。

**Confidence:** 90%

**Complexity:** Medium

**Status:** Unexplored

### 3. Lineage / Audit Ledger

**Description:** 为每次萃取生成轻量 lineage 或 audit ledger，记录 `evidence -> standard section -> ai-rule -> review-check -> rules-index entry` 的派生关系，并引用 run profile、batch、quality gate、pending/conflict、candidate publish 状态和校验命令。ledger 默认不可执行，不进入 AI 默认上下文，但给 owner、reviewer 和 CI 做审计入口。

**Basis:** `direct:` 当前契约要求 evidence-first，`ai-rules.md` 与 `review-checklist.md` 必须从 standard 派生；`expected-behavior.md` 要求输出新增规则定位、Evidence 条目编号、Quality Gate、pending/merge/conflict 和 candidate fast-index 状态。

**Rationale:** 现在 evidence、standard、AI rules、review checklist、index 分散在多个文件里。没有 lineage，验证“派生视图没有独立造规则”只能靠人工读 Markdown。ledger 能把可追溯性变成一个可检查接口。

**Downsides:** ledger 容易变成大而全的重复索引。应只记录关系和校验结果，不复制规则正文。

**Confidence:** 88%

**Complexity:** Medium

**Status:** Unexplored

### 4. 消费路径控制面

**Description:** 保留 domain 目录作为治理底座，但为每个 domain 建立消费路径控制面：`README.md` 或 `manifest.md/json` 第一屏回答“现在哪些规则可执行、哪些只是占位、AI 应加载什么、Reviewer 应检查什么、owner 待审批什么、最近一次 run 状态是什么”。可以用 Diátaxis 标签标注文件服务 how-to、reference、explanation 还是 owner action。

**Basis:** `direct:` APP README 已承担编号文档体系、子领域覆盖矩阵和增量产物映射；grounding 指出 PC/Frontend/Backend 等 domain 多为占位或 evidence policy，容易被误用为可执行规范。`external:` Diátaxis 建议按读者任务组织文档。

**Rationale:** 目录结构完整不等于开发者能用。消费控制面可以把“按文件类型陈列”转为“按工作任务进入”：我要写代码、让 AI 写代码、review PR、审批 draft、排查冲突，各读哪几份，哪些不能读。

**Downsides:** 如果只是手写 README，会继续漂移。最好从 manifest、rules-index 和 review-summary 派生关键状态。

**Confidence:** 86%

**Complexity:** Medium

**Status:** Unexplored

### 5. 可使用 Draft 的结构完整性 Gate

**Description:** 将 high-confidence draft 的准入条件从“有 evidence + review pass”扩展为“有 evidence + 结构完整”。命中 skeleton 时必须填满 skeleton 必需章节；未命中时使用通用最小集：技术栈、核心分层/角色、至少 3 个规则节覆盖多个角色、每条 AI 可执行规则有正例引用，FORBIDDEN 有反例，且 review checklist 可二值判断。低于底线的 batch 降为 pending，不进入 AI 默认规则。

**Basis:** `direct:` `standard-template.md` 目标是开发者工作手册而不是规则注册表；最新 full-auto plan 已把“缺结构 gate 会退化为规则堆”列为 P0；`expected-behavior.md` 反对用规则数量、行数衡量成功。

**Rationale:** 用户希望一步生成“可使用规范文档”，因此不能只生成规则列表。结构 gate 是保证产物像开发手册而不是规则堆的最低门槛，也是 AI 能正确消费规则的前提。

**Downsides:** 对低 evidence 的小项目会更容易产出 pending 而不是 usable draft。需要在 review summary 里清楚解释降级原因。

**Confidence:** 91%

**Complexity:** Medium

**Status:** Unexplored

### 6. Owner Decision Queue + Draft Runtime Policy

**Description:** 把 owner 审批和 AI 默认执行边界做成机器可读结构。每次 run 产出 owner decision queue：规则标题、二元组定位、evidence 编号、风险、recommended_action、是否 `usable_now`、升级阻断原因。另定义 draft runtime policy：active 是强约束；high-confidence evidence-backed draft 可作为工作输入但必须带 warning；pending/conflict/rejected/none evidence 永远不进 AI 默认执行路径。

**Basis:** `direct:` `frontmatter-format.md` 已定义规则级 `status`、`evidence_tier`、`risk_tag`、`recommended_action`；最新 PRD 明确 high-confidence evidence-backed draft 可用但 `active` 由 owner 手动确认。

**Rationale:** 当前最大产品张力是“draft 直接可用”与“active 才是正式团队强约束”。如果不把运行策略写清楚，AI 会把 draft 当 active，或者完全忽略 draft。decision queue 能让 owner 从全文阅读变为状态迁移审批。

**Downsides:** 需要裁定 `ai-rules.md` 是否包含 draft，或是否拆出 `ai-rules.draft.md`。这是产品治理问题，不能只靠模板解决。

**Confidence:** 87%

**Complexity:** Medium

**Status:** Unexplored

### 7. 契约漂移与旧路径 Linter

**Description:** 沉淀一组只读 linter，检查已知漂移模式：旧路径引用、`Rule ID` / anchor、`.index` 与 domain index 口径冲突、`schema_version` vs `schema`、`evaluations[]` vs `dimensions[]`、auto 发布 active、Phase 1 误要求 `activation-report`、候选索引误发布正式入口。

**Basis:** `direct:` repo grounding 发现 README / 手册仍有旧路径；`multi-layer-skill-contract-drift` learning 指出同一 skill 的 SKILL / workflow / agents / templates / evals 曾发生多层漂移；`public-surface-validate.sh` 已证明确定性 validator 能有效兜住公开入口契约。

**Rationale:** 这类项目的风险不是一次性写错，而是多层文档在后续迭代中互相漂移。把历史失败模式变成 linter，能让每次修复都转化为长期防线。

**Downsides:** linter 能抓 token-level 漂移，抓不住全部语义问题。它应配合 eval 和文档审查，而不是替代它们。

**Confidence:** 84%

**Complexity:** Low

**Status:** Unexplored

## Rejection Summary

| # | Idea | Reason Rejected |
|---|------|-----------------|
| 1 | 正式索引只从 active 规则生成 | 过严。当前产品前提允许 high-confidence evidence-backed draft 作为工作输入；应由 draft runtime policy 控制，而不是把 draft 全部排除。 |
| 2 | 把 `activation-report` 变成 full-auto 强制产物 | 与当前 Phase 1 full-auto 方向冲突。计划已明确复用 `phase1-selected-batch`，不伪造 Phase 2 状态。结构 gate 比强制 activation-report 更贴合当前边界。 |
| 3 | 默认按 task_type 预拆所有 standard 文件 | 有价值但会推翻现有 `standard-{sub_domain}.md` 结构，成本高。先用结构 gate、规则预算和 1500 行拆分建议治理更稳。 |
| 4 | 根 `.index` 作为硬契约 | 问题真实，但单独指定目录名过早。更好的第一步是裁定 root/domain registry 职责，并把 fast index 当 API 管理。 |
| 5 | Diátaxis 四象限全面重排目录 | 方向正确但过重。更适合作为消费入口标签和文档导航模型，而不是重排所有产物文件。 |
| 6 | Stale-by-default indexable gate | 长期有价值，但需要 owner、last_reviewed 和使用数据支撑；当前可先纳入 runtime policy 的后续演进。 |
| 7 | Golden Domain Fixture Matrix | 很适合作为实施计划的测试支撑，但本轮 ideation 的核心是产物结构和文档消费，不单独作为产品方向。 |
