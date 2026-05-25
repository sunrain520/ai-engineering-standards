---
date: 2026-05-24
topic: project-standard-extractor-dimension-framework
spec_id: 2026-05-24-001-project-standard-extractor-dimension-framework
phase: 2
references:
  - docs/brainstorms/2026-05-21-001-project-standard-extractor-requirements.md
---

# Project Standard Extractor — Dimension Framework Requirements (Phase 2)

## Summary

本需求定义 `project-standard-extractor` 的第二阶段：在第一阶段已落地的 6-agent 编排管道之上，注入**维度框架驱动 + 混合三态激活**的萃取机制，并补充三项能力——GitNexus 代码图谱集成、增量更新模式、跨项目对比与统一。同时把第一阶段已有的端规范 agent 升级为"端 adapter"，新增 Dimension Activator 与 Dimension Coverage Reviewer 两个角色，由 skill 作为 workflow orchestrator 统一调度。

目标是把萃取产出从"发现什么写什么"的浅层 bottom-up，升级为"按维度池 + 代码 signal 三态激活、按端 adapter 分发子领域"的标杆质量。AI 辅助开发要拿到一份既不漏关键面（规范性）、跨项目结构一致（一致性）、章节都有真实 evidence（准确性）的团队规范。

第一阶段定义的 actor、key flow、状态机、agent 角色清单、写入规则与基础质量门禁全部继承不变；本期只做增量。

---

## Problem Frame

第一阶段 skill 已经实际跑出端规范产出（参考 `engineering-standards/01-app-client/standard-*.md`），但与人工编写的标杆 `00-*` 系列文档对比存在显著质量差距：

| 维度 | 标杆 `00-app-client-overview.md` 系列 | 自动萃取 `standard-*.md` |
| --- | --- | --- |
| 规则数 | 单子领域 ~30 条 | 单子领域 3–5 条 |
| 分层职责矩阵 | 完整（层级 / 职责 / 禁止表） | 仅简单分层图 |
| 目录结构推荐 | 推荐目录树 | 缺失 |
| 命名规范 | UseCase / Repository / DTO / Mapper 命名表 | 缺失 |
| DTO 转换链路 | 推荐链路 + 禁止链路图 | 缺失 |
| 平台差异处理 | 4 级优先级 + 禁止事项 | 缺失 |
| 错误模型 | ≥6 类错误 + 满足要求 | 缺失 |
| 单测规范 | 强制 + 推荐规则 | 缺失 |

根本原因有两层：

1. **缺少自上而下的维度框架**：skill 不知道"一份完整的子领域规范应该长什么样"，只能从代码事实底部向上萃取命中的 pattern，无法主动检查"还差哪些维度"。
2. **缺少代码驱动的激活机制**：即使引入维度框架，固定清单也会产出一堆 pending 章节噪音；需要让代码事实决定每个项目实际激活哪些维度，同时保留关键维度的保底产出。

同时，单项目运行无法捕捉跨模块依赖与调用链路结构性事实；全量重跑成本高、无法响应代码演进；多项目运行会产出 N 份独立规范而不是团队统一规范。

---

## Relation To Phase 1

- 不覆盖、不重写第一阶段任何 requirement（R1–R46）。
- 维度框架与维度激活门禁作为**增量质量门禁项**，与 R41–R46 并存。
- 第一阶段已有的端规范 agent（APP / Frontend / Backend / Industry Standard）**升级为"端 adapter"**，角色名保留，职责扩展。
- 新增 agent 角色（Dimension Activator / Dimension Coverage Reviewer / Diff Scoper / Cross-Project Aggregator）作为第一阶段 R13 agent 清单的增量。
- 三个新能力（GitNexus / 增量 / 跨项目对比）作为**可选增强**，不破坏第一阶段单项目全量萃取的默认入口。

---

## Actors

只列出与第一阶段（A1–A6）的差异；其他 actor 不变。

- **A7. GitNexus Provider**：作为外部 read-only advisory facts 提供方，输出代码模块依赖图、调用链路、分层结构等结构性事实。不可写入、不可作为唯一证据来源。
- **A8. Cross-Project Aggregator**（agent 角色）：在 `profile-and-batch-planner` 与 `generation` 阶段执行多项目 profile 对比，产出统一规范 + 项目差异说明。
- **A9. Diff Scoper**（agent 角色）：在 `intake-and-scope` 阶段读取 git diff，识别变更影响的维度，驱动增量萃取。
- **A10. Dimension Activator**（agent 角色，本期新增）：在通用阶段 Pattern Classifier 之后、端 adapter 之前判定每端 / 每子领域的维度激活态（`baseline` / `activated` / `candidate`），输出统一的"维度激活 map"。
- **A11. 端 Adapter 集**（第一阶段 APP / Frontend / Backend / Industry Standard agent 升级版）：每个端 adapter 持有该端的维度池配置、激活 signal 清单、文件骨架、子领域骨架模板；消费 Dimension Activator 的激活 map；按 profile 分发子领域；只产出激活维度的章节。
- **A12. Dimension Coverage Reviewer**（agent 角色，本期新增）：评审阶段并行执行的分面 reviewer，专门核验维度激活准确性（保底是否真覆盖、激活维度 evidence 是否达深度指标、候选未激活是否准确反映项目状态）。

---

## Key Flows

- **F5. 混合三态维度激活萃取**
  - **Trigger:** 进入 `profile-and-batch-planner` 阶段。
  - **Actors:** A3, A4, A10, A11
  - **Steps:** Profiler 完成项目画像后，Code Facts 与 Pattern Classifier 输出端无关的代码事实；Dimension Activator 读取维度池配置 + 事实，按代码 signal 匹配规则判定每端每子领域的维度激活态（三态：`baseline` / `activated` / `candidate`），输出维度激活 map；skill 把激活 map 传递给各端 adapter，端 adapter 仅对 `baseline` 与 `activated` 维度按文件骨架填充章节，`candidate` 维度写入 overview"未激活维度地图"提示。
  - **Outcome:** 每个项目的产物章节贴合代码实际，关键维度由 baseline 兜底，未激活维度透明可见。
  - **Covered by:** R47, R48, R49, R50, R51, R52, R53, R54, R70, R71, R72, R74, R75, R76, R77, R78, R79, R80

- **F6. GitNexus 图谱辅助证据**
  - **Trigger:** `facts-and-classification` 阶段启动。
  - **Actors:** A4, A7
  - **Steps:** 检查 `.spec-first/graph/graph-facts.json`（或等效 readiness 文件）确认 GitNexus 可用；可用时查询模块依赖、调用链、分层结构作为 advisory evidence，evidence 标注来源 `gitnexus`；不可用时 fallback 到文件扫描与 import 分析并记录降级原因。GitNexus 事实同时作为 Dimension Activator 的 signal 源之一。
  - **Outcome:** 跨模块结构性事实进入 D01 / D03 / D04 / D05 维度的 evidence 池与激活 signal。
  - **Covered by:** R56, R57, R58, R59

- **F7. 增量更新模式**
  - **Trigger:** 端负责人通过 `--mode=diff` 或等效参数启动萃取，或 skill 检测到上次萃取产物存在且 git 状态可读。
  - **Actors:** A1, A3, A9
  - **Steps:** Diff Scoper 读取 git diff，把变更文件映射到受影响维度；只对受影响维度执行 facts/classification/activation/generation；Merge Coordinator 按第一阶段 R34–R40 追加 draft 与 evidence，不覆盖已有规则。增量模式下激活态可能从 `candidate` 变为 `activated`，必须更新 overview"未激活维度地图"。
  - **Outcome:** 短周期内能跟随代码演进刷新规范，激活态变迁可追溯。
  - **Covered by:** R60, R61, R62

- **F8. 跨项目对比与统一**
  - **Trigger:** 端负责人提供多个项目路径作为最小启动输入。
  - **Actors:** A1, A3, A8
  - **Steps:** Profiler 对每个项目独立产出 profile 与激活 map；Cross-Project Aggregator 合并多个激活 map（同维度多项目都激活 → 统一激活；仅部分项目激活 → 标 `partial_activated` 进差异列）；横切维度文件 §3 输出"子领域差异对比 + 统一要求"；项目特有差异写入 `evidence/project-specific-divergence.md`。
  - **Outcome:** 多项目运行产出**一份统一规范 + 项目差异说明**，激活态跨项目可对齐。
  - **Covered by:** R63, R64, R65, R66

- **F9. 端 adapter 子领域分发**
  - **Trigger:** 端 adapter 收到 Dimension Activator 的激活 map 与 Profiler 的子领域标签。
  - **Actors:** A11
  - **Steps:** 端 adapter 根据 profile 中的子领域标签（如 `app/kmp`、`app/android`、`web/admin`、`backend/java`）从端 adapter 内置的骨架模板池选取对应模板；按激活态填充章节内容，子领域特有维度（如 KMP 的 expect/actual、Admin 的复杂表单、Java 的 Spring Boot Bean 生命周期）作为该子领域骨架内置内容；子领域不另建独立 agent。
  - **Outcome:** 同一端 adapter 能在一次运行内产出多个子领域规范，子领域差异由骨架承载而非 agent 协调。
  - **Covered by:** R72, R73, R79

---

## Requirements

编号延续第一阶段（R1–R46），本期从 R47 起。

### 维度框架与三态机制

- R47. Skill 必须建立明确的**维度框架（Dimension Framework）**作为萃取的自上而下驱动机制。维度框架定义"维度池"，每个维度在具体项目上的激活状态由代码事实决定，分**三态**：
  - **`baseline`**：保底必出。无论代码 signal 有无都必须产出章节，无 evidence 时标 `pending` 并附候选信号清单。
  - **`activated`**：代码 signal 命中后激活。必须有真实 evidence，章节内容贴合实际技术栈。
  - **`candidate`**：候选未激活。不产出章节，但必须在 overview"未激活维度地图"中列出（维度名 + 未使用原因 + 候选信号 + 启用条件）。
- R48. **Layer 1 通用维度**必须至少覆盖以下 13 项：D01 架构概览、D02 目录与命名、D03 模块化与依赖、D04 数据流与状态、D05 数据访问、D06 错误处理、D07 路由与导航、D08 UI 与组件、D09 测试策略、D10 性能、D11 安全与合规、D12 可观测性、D13 构建与依赖治理。
- R49. **Layer 2 端类型扩展维度**必须按端类型分别定义，覆盖范围为：
  - **客户端**（子领域：KMP shared / Android / iOS）：多端共享与跨端架构、平台差异处理、生命周期与资源管理、多市场与多展业地、设备能力与权限、网络与离线、启动性能与包体积、本地存储与数据安全。
  - **前端**（子领域：H5 / Admin / SDK）：渲染策略、路由与导航、状态管理、类型系统、组件设计与样式体系、性能与加载、包体积与构建、安全防护、兼容性与降级、监控与可观测性、SEO 与元信息。
  - **后端**（子领域：Java / Python / Go / Node）：API 设计与版本化、数据库与持久化、缓存与一致性、消息队列与异步、并发与限流、鉴权与权限粒度、配置与密钥、可观测性、部署与运行时、错误处理与重试。
  - **行业**（独立维度集，与端类型并列）：高风险模块识别、合规要求、数据敏感分级、日志与审计、术语与领域模型、关键链路一致性。
  - 详细每端 / 行业的维度核心关切与必检子项见本文档"Per-End Dimension Catalog"附录。
- R50. 规范输出目录结构必须遵循：每个 domain 下包含 `00-{domain}-overview.md`（含"未激活维度地图"章节，列出所有 `candidate` 维度）+ `0N-{sub_domain}-standard.md`（子领域全景）+ `M-{cross_cutting}-standard.md`（横切维度）+ `ai-rules.md` / `review-checklist.md`（派生视图）+ `evidence/`。
- R51. 文档必须遵循三种统一文件骨架，**每个章节标题旁必须标注激活态**（`[baseline]` / `[activated]` / `[pending]`）：
  - **Overview**：适用范围、架构目标、分层依赖图、分层职责矩阵、文档索引、强制规则摘要、落地要求、规则等级定义、**未激活维度地图**（列出 `candidate` 维度名 + 未使用原因 + 候选 evidence 信号 + 启用条件）。
  - **子领域**：规范定位、职责边界（应 / 不应承载）、推荐目录、分层规则、命名规范、核心规则（含正反例）；数据流链路、平台差异、错误模型按激活态产出；AI 生成要求、Review 检查项、Evidence 参考。
  - **横切维度**：适用范围、激活态、统一原则、子领域差异对比、候选 evidence 信号、规则（强制 / 推荐 / 禁止）、正反例、AI 生成要求、Review 检查项、Evidence 参考。
- R52. Skill 必须维护并对外可读的**维度激活规则配置**（machine-readable，建议 YAML 或 JSON），结构至少包含：
  - `baseline_dimensions`：保底维度清单（至少覆盖 D01 架构概览、D02 目录与命名、D06 错误处理、D09 测试策略、D11 安全与合规、D12 可观测性 6 项）。
  - `dimension_signals`：每个候选维度的代码激活 signal 清单，signal 类型包括 grep pattern / AST pattern / 文件存在性 / 依赖声明（package.json / pom.xml / build.gradle / requirements.txt 等）/ GitNexus 图谱事实。
  - `signal_combination`：每个维度的激活逻辑组合（`any` / `all` / `weighted`），支持"任一命中即激活"或"必须多源命中"。
  - `depth_indicator`：深度指标（`min_rules_per_dimension`、`min_evidence_per_rule`、`min_code_examples`、`min_positive_negative_pair`）。
- R53. **维度激活门禁**（替代第一阶段表述的"维度覆盖门禁"）：
  - `baseline` 维度无 evidence 时不得跳过章节，必须输出 `pending` 标记 + 必检 evidence 候选信号；`baseline` 维度 `pending` 状态下规范不得直接进入 `draft`，必须由端负责人显式确认"项目确实未实现该维度"才能降级为 `candidate_with_warning`。
  - `activated` 维度章节必须有至少 1 条 evidence；激活但 evidence 不达 `depth_indicator` 阈值的章节标 `shallow`，不得进入 `draft`。
  - `candidate` 维度不产出章节，但必须在 overview"未激活维度地图"列出。
- R54. Skill 必须输出**维度激活报告**（machine-readable，建议 JSON，路径 `evidence/dimension-activation-report.json`），记录每个候选维度的激活态、命中的 signal、evidence 数量、深度指标核验结果，作为产物附属物供后续审核、增量更新比对、跨项目合并使用。
- R55. 横切维度文件 §3 子领域差异对比章节必须明确给出"统一要求"列；统一要求与子领域差异并存时必须以统一要求为规则正文，差异写入对比表。

### GitNexus 图谱集成

- R56. GitNexus 必须以 **read-only advisory facts** 形式接入；skill 必须先读取 GitNexus readiness 信号（例如 `.spec-first/graph/graph-facts.json` 或等效 manifest）并确认 `capabilities.query_global_graph` 为 true 才能查询。
- R57. GitNexus 不可用、未 ready 或返回错误时，skill 必须 fallback 到文件扫描 / import 分析，并在 evidence 文件中标注降级原因；不得静默丢弃维度证据。
- R58. 所有来自 GitNexus 的 evidence 条目必须显式标注 `source: gitnexus`，并与代码文件位置可交叉验证。
- R59. GitNexus 不得作为某条规则的**唯一**证据来源；图谱事实必须与至少一个具体代码片段或文件路径关联，否则规则降级为待人工确认。

### 增量更新模式

- R60. Skill 必须支持**增量模式**（建议 `--mode=diff` 或等效启动参数）；全量模式仍为默认入口，不强制用户使用增量。
- R61. 增量模式必须以 git diff 为输入，识别变更文件并映射到受影响的维度清单；仅对受影响维度执行 facts/classification/activation/generation。
- R62. 增量模式的产出必须仍走第一阶段 R34–R40 的重复运行与冲突处理规则：追加 draft、追加 evidence、不覆盖 active、相近规则进入待合并、冲突进入待确认。

### 跨项目对比与统一

- R63. Skill 必须支持多个项目路径作为最小启动输入；单项目运行仍然必须能完整工作。
- R64. 多项目运行时，profile-and-batch-planner 必须为每个项目独立产出 profile 与激活 map，Cross-Project Aggregator 必须按关键维度对比差异。
- R65. 多项目运行的最终产出必须是**一份统一规范 + 项目差异说明**，不是 N 份独立规范；横切维度文件必须在 §3 给出"子领域差异对比 + 统一要求"。
- R66. 项目特有差异必须写入独立 evidence（建议 `evidence/project-specific-divergence.md`），不得污染统一规范正文。

### 与 6-agent 管道的对接

- R67. 维度框架不得新增对外暴露的 skill 入口；现有对外 skill `project-standard-extractor` 仍是唯一对外入口，作为 workflow orchestrator 统一调度内部 agent。
- R68. 维度框架的注入点限定在以下 agent 与新增 agent 角色：
  - `profile-and-batch-planner`：生成维度池适用清单 batch-plan。
  - `facts-and-classification`：按维度池定向扫描，输出端无关代码事实。
  - **新增 `Dimension Activator`**：在 `facts-and-classification` 之后、端 adapter 之前判定激活态。
  - `generation`（端 adapter 升级版）：按文件骨架与激活态逐维度填充。
  - **新增 `Dimension Coverage Reviewer`**：评审阶段并行核验激活准确性。
- R69. 第一阶段质量门禁 R41–R46 与本期维度激活门禁 R53 必须并存；Quality Gate agent 在汇总评审时必须覆盖两套门禁。

### 端 Adapter 升级与子领域分发

- R70. 第一阶段已有的端规范 agent（APP Standard / Frontend Standard / Backend Standard / Industry Standard）**升级为"端 adapter"**：角色名保留，职责扩展为持有该端的维度池配置、激活 signal 清单、文件骨架、子领域骨架模板。
- R71. 每个端 adapter 必须持有该端的：
  - 维度池子集（Layer 1 通用 + Layer 2 端类型扩展中归属该端的维度）。
  - 该端独有的子领域骨架模板（覆盖该端每个子领域的目录推荐、命名规范、典型链路图、错误模型、AI 生成要求）。
  - 该端语言生态对应的代码激活 signal（如 Frontend adapter 持有 `package.json` 依赖匹配规则、`tsconfig.json` 类型严格度判定规则等）。
- R72. 端 adapter 内部必须按 Profiler 输出的子领域标签分发子领域，子领域骨架由端 adapter 内置而非外部 agent 协调：
  - APP adapter 分发到 KMP shared / Android / iOS 子骨架。
  - Frontend adapter 分发到 H5 / Admin / SDK 子骨架。
  - Backend adapter 分发到 Java / Python / Go / Node 子骨架。
  - Industry adapter 分发到金融 / 电商 / 教育 / 医疗 / 政企 / SaaS 子骨架。
- R73. 子领域**不另建独立 sub-agent**；子领域差异由端 adapter 内部骨架模板承载。理由是子领域差异主要在内容层面，独立 sub-agent 会显著增加协调成本而收益有限。
- R74. 端 adapter 消费 Dimension Activator 输出的激活 map，仅对 `baseline` 与 `activated` 维度产出章节；`candidate` 维度的呈现由端 adapter 提交到 overview 汇总而不在子领域文件展开。

### Dimension Activator 与激活信号

- R75. **Dimension Activator** 必须作为独立 agent 角色存在，不得把激活判定职责并入端 adapter，理由是激活判定是端无关的元决策，独立 agent 保证跨端口径一致。
- R76. Dimension Activator 的激活 signal 来源必须至少支持以下类型，并可在维度激活规则配置中按维度组合：
  - **grep pattern**：文件内字符串匹配（关键字 / 注解 / 导入语句）。
  - **AST pattern**：基于 ast-grep 或等效工具的结构匹配。
  - **文件存在性**：特定文件 / 目录的存在（如 `migrations/` 触发 D 数据库迁移激活）。
  - **依赖声明**：`package.json` / `pom.xml` / `build.gradle` / `requirements.txt` / `go.mod` 中的依赖项匹配。
  - **GitNexus 图谱事实**：模块依赖图 / 调用链 / 分层结构。
- R77. 激活逻辑必须支持 `any`（任一命中即激活）、`all`（必须多源命中）、`weighted`（按权重累加阈值）三种组合；维度激活规则配置必须为每个维度显式声明组合方式与阈值。

### Workflow 编排扩展

- R78. workflow 阶段必须在第一阶段 R14 分阶段并行结构上**插入维度激活判定阶段**，新顺序为：
  - 前置串行：Intake → Profiler → Evidence Collector → Code Facts → Pattern Classifier → **[新] Dimension Activator**。
  - 端规范并行：APP / Frontend / Backend / Industry Standard adapter（消费激活 map）。
  - 派生并行：AI Rules / Review Checklist / Evidence Writer（按端的语言生态适配）。
  - 评审并行：Team Standard / AI Executability / Review Checklist / Conflict / Industry Risk / **[新] Dimension Coverage Reviewer**。
  - 串行汇总：Quality Gate（双门禁）→ Merge Coordinator。
- R79. Skill 作为 workflow orchestrator 必须执行**路由决策**：根据 Profiler 输出的端覆盖情况跳过未识别到代码的端 adapter（项目只有后端代码 → 不触发 APP / Frontend adapter），避免空跑。
- R80. Skill 必须在 generation 完成后做**三态汇总**：合并所有端 adapter 上报的 `candidate` 维度，写入 `00-{domain}-overview.md` 的"未激活维度地图"章节，跨端去重并按维度类型分组。
- R81. **Dimension Coverage Reviewer** 必须在评审阶段并行执行，核验三件事：
  - `baseline` 维度是否真覆盖（包括 `pending` 状态下的端负责人确认链路）。
  - `activated` 维度 evidence 是否达深度指标。
  - `candidate` 维度是否准确反映项目实际状态（不得把代码已有 signal 的维度误判为 candidate）。

### 行业维度独立性

- R82. 行业维度集与端类型扩展维度**并列**而非嵌套，由 Industry Standard adapter 独立处理；端 adapter 不得自行生成行业规则。
- R83. Industry Standard adapter 必须支持多行业子领域并存：单次运行可识别项目同时涉及的多个行业（如电商 + 金融支付），分别生成行业子骨架内容；行业子领域识别 signal 由维度激活规则配置承载。

---

## Acceptance Examples

- **AE7. Covers R47, R48, R49, R50, R51.** Given 端负责人对一个 KMP App 项目启动萃取，when skill 进入 `profile-and-batch-planner`，then batch-plan 必须包含 Layer 1 全部 13 维 + 客户端扩展维度，并按目录结构与三种文件骨架生成产物；每个章节标题旁必须标注激活态。
- **AE8. Covers R52, R53.** Given 某子领域代码中找不到 D11 安全与合规的任何 evidence，when Dimension Activator 判定激活态，then D11 因属于 `baseline_dimensions` 仍必须产出章节并标 `pending` + 候选信号清单（auth 模块、token 管理、加密使用等）；规范不得直接进入 `draft`，必须端负责人确认"项目确实未实现"才能降级为 `candidate_with_warning`。
- **AE9. Covers R52, R76, R77.** Given 维度激活规则配置中 D04 数据库与持久化的 signal 组合是 `any`（命中：`pom.xml` 含 `mybatis` 或 `build.gradle` 含 `room` 或 `migrations/` 目录存在或 GitNexus 报告 Repository 依赖图），when 项目 `pom.xml` 命中 mybatis，then D04 进入 `activated` 态，端 adapter 必须产出对应章节并至少携带 1 条 evidence。
- **AE10. Covers R47, R51, R80.** Given 一个纯后端微服务项目无 MQ 代码，when 激活判定完成，then D14 消息队列与异步进入 `candidate` 态，不产出独立章节；skill 必须在 `00-backend-overview.md` 的"未激活维度地图"列出"消息队列与异步：项目未使用，候选信号：依赖 kafka/rocketmq、@KafkaListener 注解、producer/consumer 包目录，启用条件：引入异步通信"。
- **AE11. Covers R55, R65.** Given 多项目运行覆盖了 KMP App 与 Android Native App，when 生成横切维度文件 `M-state-error-standard.md`，then §3 必须以表格形式列出两个子领域差异 + 统一要求，统一要求作为规则正文。
- **AE12. Covers R56, R57, R58.** Given `.spec-first/graph/graph-facts.json` 不存在或 readiness 为 false，when skill 启动，then skill 必须输出降级原因并 fallback 到文件扫描；当 GitNexus 可用时，模块依赖 evidence 必须标注 `source: gitnexus` 且能与代码文件交叉验证。
- **AE13. Covers R59.** Given GitNexus 返回了一条调用链事实，when skill 想据此生成规则，then 该规则必须至少关联一个具体代码片段或文件路径，否则规则降级为待人工确认。
- **AE14. Covers R60, R61, R62.** Given 上次萃取产物已存在且 git diff 显示仅 5 个 Repository 文件变更，when 端负责人启动 `--mode=diff`，then skill 仅对 D03/D05 等受影响维度执行萃取，新增 draft 与 evidence 按 R34–R40 追加，已 active 规则不被覆盖。
- **AE15. Covers R63, R64, R66.** Given 端负责人输入三个后端项目路径，when skill 运行，then 必须独立产出三份 profile 与激活 map 后再统一合并；项目特有差异写入 `evidence/project-specific-divergence.md`，统一规范正文保持团队级抽象；同维度仅部分项目激活时标 `partial_activated` 并写入差异列。
- **AE16. Covers R67, R68, R69.** Given 一次完整萃取运行，when 检查 skill 入口与 agent 调度，then 对外只暴露 `project-standard-extractor` 一个 skill；维度框架仅在 5 个 agent 注入（含新增 Dimension Activator 与 Dimension Coverage Reviewer），其他 agent 角色与执行顺序与第一阶段一致；Quality Gate 同时执行 R41–R46 与 R53 两套门禁。
- **AE17. Covers R70, R71, R72, R73.** Given 一个 KMP + Android Native 双子领域的客户端项目，when APP Standard adapter 运行，then adapter 不调用任何 sub-agent，必须内部从骨架模板池选取 KMP shared 与 Android 两套子骨架并行填充；KMP shared 文件必须出现 expect/actual 边界、共享 ViewModel 范围等子领域特有维度章节，Android 文件必须出现 Compose vs XML 选型、Hilt DI、ViewModel/Flow 等章节。
- **AE18. Covers R74, R75, R76, R77.** Given Dimension Activator 已输出激活 map，when 端 adapter 启动生成，then 端 adapter 不得重新执行激活判定，必须直接消费 Dimension Activator 的 map；当配置中 D08 UI 与组件的 signal 组合是 `weighted`（XML 布局文件 +1、Compose `@Composable` 注解 +2、SwiftUI `View` 协议 +2，阈值 2），则 Compose 单源命中即可激活，仅 XML 单源不达阈值。
- **AE19. Covers R78, R79, R80.** Given 一个项目 Profiler 输出仅识别到 `backend/java` 子领域，when skill 启动 workflow，then APP / Frontend adapter 必须被跳过、不参与并行阶段；最终 overview"未激活维度地图"必须只汇总 backend 与行业 adapter 上报的 candidate 维度，不出现 APP / Frontend 维度噪音。
- **AE20. Covers R81.** Given Dimension Coverage Reviewer 在评审阶段运行，when 发现某 `baseline` 维度被 skill 误标为 `candidate`（代码实际有 signal 但被规则配置遗漏），then Reviewer 必须把该维度状态翻转为 `activated` 并要求重新生成章节，或要求维度激活规则配置补充对应 signal。
- **AE21. Covers R82, R83.** Given 一个电商项目同时涉及支付（金融）和教育内容（教育）两个行业，when Industry Standard adapter 运行，then adapter 必须并行生成两份行业子骨架内容；其他端 adapter 不得自行生成行业相关规则（如不得在 Backend adapter 里写支付幂等规则）；端规则与行业规则的交叉关系由 Quality Gate 阶段汇总。
- **AE22. Covers R82, R83 + Per-End Catalog 证券 / 跨境交易子领域.** Given 公司主营的证券经纪业务系统（含订单管理 / 实时风控 / 清算 / 港美股交易），when Industry Standard adapter 运行，then 必须按"证券"子领域骨架产出 SEC-01 ~ SEC-10 与 XSEC-01 ~ XSEC-06 章节；交易日历 / 报送格式 / FIX 协议接入 / 港美股跨时区与多币种等特有维度按代码 signal 激活产出；Backend adapter 在生成 EA-Backend-* 章节遇到证券相关 evidence 时必须引用 SEC-* / XSEC-* 章节而不复述规则；端规则与行业规则的交叉关系由 Quality Gate 阶段汇总。

---

## Success Criteria

- 萃取产出的子领域文件平均规则数显著上升（基线参考标杆 `00-*` 系列：单子领域 ≥10 条核心规则、≥2 个正反例、≥1 个数据流 / 错误模型图）。
- 维度激活规则配置可作为产物自动核验依据；端负责人能从 `evidence/dimension-activation-report.json` 与 overview"未激活维度地图"直接看到全量维度地图与每个维度的激活态。
- 萃取产出无大量 `pending` 噪音章节：`baseline` 维度无 evidence 时显式标 `pending` 等待确认，`candidate` 维度不进入子领域文件正文。
- AI 辅助开发时拿到的规范规范性、一致性、准确性均达标：保底维度兜底关键面，跨端跨项目结构一致，激活章节都有真实代码 evidence。
- GitNexus 可用时萃取产物中跨模块依赖、调用链事实的 evidence 数量明显上升；不可用时萃取仍能完整运行。
- 端负责人能在小范围代码变更后用增量模式快速刷新对应维度规则，激活态变迁可在维度激活报告中追溯。
- 多项目运行产出一份团队统一规范 + 差异说明，端负责人无需手工合并多个项目规范；激活态跨项目对齐而非各自独立判定。
- 端 adapter 数量不超过第一阶段 4 个（APP / Frontend / Backend / Industry），子领域差异由内部骨架承载；agent 协调成本可控。
- 后续 `spec-plan` 不需要重新发明维度池、文件骨架、激活规则配置、端 adapter 升级方式、workflow 阶段调整、跨项目合并策略。

---

## Scope Boundaries

- 不推翻第一阶段 6-agent 核心管道，不重写 actor、key flow、状态机或现有 agent 角色清单（仅升级端规范 agent 为端 adapter）。
- 不为子领域新建独立 sub-agent；子领域差异由端 adapter 内部骨架承载。
- 不改变产物格式约定（inline blockquote 元数据、evidence 编号体系）。
- 不引入向量库、复杂检索系统或外部规范管理平台。
- 不要求第一阶段已生成的 `engineering-standards/01-app-client/standard-*.md` 强制迁移；迁移策略留给 `spec-plan` 决定。
- 不解决第一阶段 outstanding question 中"AI 使用 draft 时的未审核提示如何进入 AI 开发输入模板"问题。
- 不强制要求 GitNexus 必须接入；GitNexus 是 advisory，不可用时整体流程仍可工作。
- 不强制要求增量模式与跨项目对比同时启用；两者均为可选增强。
- 不在本期定义维度池、激活信号、文件骨架的完整 JSON Schema；schema 由 `spec-plan` 阶段产出。
- 不支持客户端鸿蒙子领域（仅 KMP shared / Android / iOS）。
- 不支持端 adapter 的"代码自动学习新维度"——维度池由人工配置维护，端 adapter 仅按配置激活，避免维度命名漂移。

---

## Key Decisions

- **采用混合三态激活机制**：固定清单产出 pending 噪音，纯代码驱动会漏关键维度（如安全）。三态机制在 `baseline` 兜底关键面、`activated` 贴合实际、`candidate` 显式提示之间取得平衡，同时回应规范性 / 一致性 / 准确性三个目标。
- **Dimension Activator 独立 agent**：激活判定是端无关元决策，独立 agent 保证跨端口径一致；端 adapter 只消费、不重新判定，避免同维度在不同端 adapter 产生不一致激活态。
- **端规范 agent 升级为端 adapter（不新建 agent）**：第一阶段 R10–R14 已经规划了端专项 agent，本期只扩展职责（持有维度池 + 激活 signal + 骨架模板），保持对外 skill 唯一入口与 agent 数量稳定。
- **子领域不新建独立 sub-agent**：子领域差异主要在内容层面，独立 sub-agent 会增加协调成本而收益有限；子领域骨架作为端 adapter 内置模板池处理。
- **维度框架分两层 + 行业并列**：Layer 1 跨端通用、Layer 2 按端扩展、行业作为独立维度集。行业并列而非嵌套是因为行业关切跨端存在（同一支付链路在 App、Web、Backend 都有），独立处理避免重复。
- **三种统一文件骨架 + 章节激活态标注**：骨架统一让 AI 萃取、人阅读、Review 引用、AI 消费遵循同结构；激活态标注让"为什么有 / 为什么无"该章节透明可见。
- **维度激活规则配置走人工维护 + 多源 signal**：维度框架不自动学习以避免命名漂移；signal 支持 grep / AST / 文件 / 依赖 / GitNexus 多源，逻辑组合支持 `any` / `all` / `weighted`，兼顾灵活性与可解释性。
- **GitNexus 走 read-only advisory facts**：与 spec-first 仓库 GitNexus 接入策略对齐；图谱事实只是补充结构性 evidence 与激活 signal，不能替代代码扫描，更不可作为唯一证据。
- **增量模式与跨项目作为可选增强**：单项目全量仍是默认；可选机制不破坏第一阶段已稳定的最小启动语义。
- **客户端不含鸿蒙**：当前团队未覆盖鸿蒙子领域，强行加入会产出空骨架；后续如需支持作为单独需求引入。

---

## Dependencies / Assumptions

- 维度框架依赖 `engineering-standards/01-app-client/` 现有 `00-*` 系列文档作为标杆质量参照；如果该参照后续发生大幅结构变更，维度池需同步更新。
- 维度激活规则配置依赖人工维护：端负责人或架构负责人负责为新维度补充 signal 规则，错配的代价是激活态误判（由 Dimension Coverage Reviewer 兜底翻转）。
- GitNexus 接入依赖目标项目已经过 GitNexus 索引并产生 `.spec-first/graph/graph-facts.json` 或等效 readiness 信号；该 readiness 信号的生成不在本 skill 职责内。
- 增量模式依赖目标项目可读 git diff；非 git 仓库或浅克隆环境降级为全量模式。
- 跨项目对比依赖端负责人提供同一研发域内的多个项目路径；跨域多项目（例如 App + 后端混入）不在本期支持范围。
- 端 adapter 子领域骨架模板池规模随团队覆盖技术栈增长；首期覆盖 KMP/Android/iOS、H5/Admin/SDK、Java/Python/Go/Node 与 6 个行业子领域。
- 当前会话的设计成果（混合三态 + 端 adapter + Dimension Activator + Per-End Catalog）已经由用户在 2026-05-24 设计会话中明确确认；本文档是该设计的需求固化版本。

---

## Outstanding Questions

### Resolve Before Planning

- 无。三个建议优先级问题（GitNexus / 增量 / 跨项目谁先落地）由 plan 阶段排序。

### Deferred to Planning

- [Affects R47–R55, R70–R77][Technical] 维度池、激活规则配置、文件骨架的完整 JSON Schema（包含三态枚举、signal 类型完整列表、组合阈值定义）。
- [Affects R52][Technical] 维度激活规则配置的存储位置与版本演进策略（建议放在 skill 的 `config/dimension-rules.{yaml,json}`，但 plan 阶段需要确认）。
- [Affects R56–R59][Technical] GitNexus readiness 检测与查询的具体 API / 命令选择（CLI、MCP tool、graph-facts.json 直读三选一）。
- [Affects R60–R62][Technical] 增量模式的 diff 基线选择（HEAD vs main vs 上次萃取 commit）与 commit 元信息存储位置。
- [Affects R63–R66][Technical] 跨项目对比时 profile 与激活 map 合并算法（多数票 / 最强约束 / 加权）的具体实现。
- [Affects R70–R74][Technical] 端 adapter 子领域骨架模板的物理组织方式（嵌入 agent prompt vs 外部模板文件 vs 配置目录）。
- [Affects R76][Technical] AST signal 是否统一通过 ast-grep 实现，还是允许端 adapter 选用语言原生 AST 工具（Java 用 JavaParser、Python 用 ast 模块、Go 用 go/ast 等）。
- [Affects R50–R51, R17–R22 from Phase 1] 现有 `engineering-standards/01-app-client/` 文件结构是否要按新目录结构与文件骨架迁移；迁移路径与历史 standard 文档的废弃策略。
- [Affects R83][Product] 行业子领域识别 signal 的来源（依赖关键字 / 模块名 / 文档关键词 / 端负责人显式指定）哪种更可靠。
- [Affects 整体] 维度框架启用是否需要新增 feature flag / 灰度开关，让端负责人能在 plan 阶段选择"按旧 bottom-up 模式继续"或"按新维度框架运行"。
- [Affects Per-End Catalog 证券 / 跨境交易子领域][Product] 证券业务线（经纪 / 自营 / 资管 / 投行 / 量化 / 港美股 / 期权期货 / 融资融券）是否需要进一步拆分为各自独立的子骨架文件，还是统一在 SEC-01 ~ SEC-10 与 XSEC-01 ~ XSEC-06 维度下产出。当前默认按维度产出，不按业务线拆，理由是业务线在维度上有大量共享；如团队希望按业务线分文件，需要在 plan 阶段定义业务线骨架映射。
- [Affects XSEC-01 ~ XSEC-06][Product] 港美股交易扩展维度的激活规则配置首期是否覆盖港股通 / 美股通 / 直接美股 / 直接港股四种业务模式的全部 signal 差异，还是只覆盖公司当前主营的业务模式。
- [Affects Output Directory Structure Reference][Product] 是否启用 `00-cross-domain/` 顶级横切目录，承载跨端跨行业的安全 / 合规 / 数据治理总纲；本期 R50 不强制要求，由 plan 阶段决定。
- [Affects 01-securities-standard.md][Technical] 证券子领域文件预期较长（约 12 大节 + 16 个维度子节）：保持单文件，还是拆为 `04-industry/01-securities/` 子目录每个 SEC-* / XSEC-* 单独成文。前者阅读连贯但单文件可能超 2000 行，后者结构清晰但需要扩展 R50 允许"子领域内部再拆"。

---

## Force Rebuild 模式增量

> 在 Phase 2 维度框架与三态机制基础上,新增第三种运行模式 `--mode=force-rebuild`,作为规范产物的"反悔棋"。覆盖维度框架升级、draft / pending 噪音过多、代码库重大重构三类典型场景,以备份作为唯一安全网,与 `full`(R47–R55 默认)、`diff`(R60–R62 增量)并列。

### Actors

- **A13. Backup Manager**(skill 内部能力,非独立 agent):负责备份目录写入、`manifest.json` 元信息记录、保留份数清理、`--restore` 反向恢复。

### Key Flows

- **F10. force-rebuild 完整流程**
  - **Trigger:** 端负责人执行 `--mode=force-rebuild --domain=<domain>`,可选 `--keep=<N>` 调整保留份数。
  - **Actors:** A1, A13, 全部 Phase 2 端 adapter。
  - **Steps:** 预检(净 git 状态 + `.spec-first/backups/` 可写)→ dry-run 预览(待覆盖文件清单 + 备份路径 + evidence 数量 + 激活报告摘要)→ 用户输入 `confirm` → Backup Manager 整目录拷贝至 `.spec-first/backups/<domain>/<timestamp>/` 并写 manifest → 清空 domain 目录全量产出 → 走 Phase 2 默认 `full` 管道从零重生 → 强制追加根 `CHANGELOG.md`。
  - **Outcome:** 目标 domain 规范完整刷新,原产物在备份目录可追溯。
  - **Covered by:** R84, R85, R86, R87, R88, R90

- **F11. force-rebuild 失败回滚**
  - **Trigger:** F10 清空或重生阶段任一环节失败(Quality Gate 双门禁不通过、generation 异常、IO 错误)。
  - **Actors:** A1, A13。
  - **Steps:** Backup Manager 自动从最新备份目录回滚整 domain;skill 输出失败原因与回滚结果;CHANGELOG 不追加;事后端负责人可用 `--restore=<timestamp>` 再次恢复。
  - **Outcome:** domain 目录不停留半成品脏状态。
  - **Covered by:** R89

- **F12. 反向恢复**
  - **Trigger:** 端负责人执行 `--mode=restore --domain=<domain> --restore=<timestamp>`。
  - **Actors:** A1, A13。
  - **Steps:** Backup Manager 校验备份目录与 manifest 完整性 → 直接覆盖目标 domain 目录 → 追加 CHANGELOG 恢复条目。
  - **Outcome:** 端负责人可在保留份数内任意切回历史规范版本。
  - **Covered by:** R87

### Requirements

#### 模式定义

- R84. Skill 必须支持 `--mode=force-rebuild` 作为与 `full`(R47–R55 默认)、`diff`(R60–R62)并列的**第三种独立运行模式**;force-rebuild 必须**跳过** R34–R40 的追加与冲突处理规则,在备份后清空目标 domain 并从零重生。
- R85. force-rebuild 的最小重生单元必须为 **domain 级**(`01-app-client` / `02-frontend` / `03-backend` / `04-industry`),由 `--domain=<domain>` 显式指定;支持一次指定多个 domain,未指定的 domain 不受影响;不支持子领域 / 单文件 / 单维度的局部 force。
- R86. force-rebuild 必须覆盖目标 domain 目录下**全部产出文件**:`00-{domain}-overview.md`、所有 `0N-{sub_domain}-standard.md`、所有横切文件、`ai-rules.md`、`review-checklist.md`、`evidence/` 整目录;原 evidence 中的人工补充由备份保护,只能通过 `--restore` 恢复。

#### 备份机制

- R87. force-rebuild 必须在执行前完成完整备份:
  - **位置**:`.spec-first/backups/<domain>/<timestamp>/`,默认被 `.gitignore` 排除。
  - **保留份数**:默认 `N=5`,可由 `--keep=<N>` 调整;超出后自动清理最旧份。
  - **manifest**:每份备份必须包含 `manifest.json`,字段至少含 `domain` / `timestamp` / `git_commit_hash` / `mode_args` / `dimension_activation_report_summary` / `operator`(读 `.claude/spec-first/.developer` 或 `.codex/spec-first/.developer`)。
  - **反向恢复**:必须支持 `--mode=restore --domain=<domain> --restore=<timestamp>`,直接覆盖目标 domain;恢复操作本身也要追加 CHANGELOG。

#### 安全确认

- R88. force-rebuild 启动时必须依次执行三项 safeguard,任一不通过则中止:
  1. **净 git 状态校验**:目标 domain 目录及 `.spec-first/backups/` 不允许 unstaged 改动;非 git 仓库或 shallow clone 直接拒绝。
  2. **dry-run 预览**:列出待覆盖文件清单、备份目标路径、原 evidence 数量、`dimension-activation-report.json` 摘要、操作员标识。
  3. **二次确认**:用户必须输入 `confirm`(全字匹配)才执行;输入其他内容或非交互模式无 `--yes` 则中止。
- R89. force-rebuild 在备份完成后的清空 + 重生过程中任何环节失败,Backup Manager 必须**自动回滚**至刚生成的备份;失败原因写入运行日志,CHANGELOG 不追加。

#### 治理对接

- R90. force-rebuild 完整执行(含成功重生)后,必须按项目 `CLAUDE.md` Changelog 治理约束追加根 `CHANGELOG.md` 条目,标注 `(user-visible)`、记录 domain、备份路径、新激活 map 摘要;未追加则视为执行未完成,后续 review / commit 流程必须拒绝。
- R91. force-rebuild 与 Phase 2 跨项目对比模式(R63–R66)互斥:同时指定 `--projects=<paths>` 与 `--mode=force-rebuild` 时必须报错;force-rebuild 一次只作用于团队统一规范目录,不递归各项目子目录。
- R92. force-rebuild 与 `diff` 模式(R60–R62)互斥;同时指定 `--mode=force-rebuild` 与 diff 相关参数必须报错。force-rebuild 与 GitNexus(R56–R59)、Dimension Activator(R75–R77)逻辑共用,不引入新激活态。

### Acceptance Examples

- **AE23. Covers R84, R85, R87, R88.** Given 端负责人在 `engineering-standards/01-app-client/` 干净状态下执行 `--mode=force-rebuild --domain=01-app-client`,when skill 启动,then 必须先输出 dry-run 预览(被覆盖文件清单 + 备份路径 + 原 evidence 数量),用户输入 `confirm` 后,Backup Manager 必须先把整个 `01-app-client/` 拷贝到 `.spec-first/backups/01-app-client/<timestamp>/` 并生成 manifest,再清空原目录后从零重生;最终 `.spec-first/backups/01-app-client/` 下保留份数不超过 5。
- **AE24. Covers R86, R89.** Given 一次 force-rebuild 在 generation 阶段因 Quality Gate 双门禁未通过而失败,when skill 检测到失败,then Backup Manager 必须自动用刚生成的备份覆盖回 `01-app-client/`,使 domain 目录恢复到 force 之前状态;CHANGELOG 不追加;skill 输出失败原因与回滚结果。
- **AE25. Covers R90, R91, R92.** Given 端负责人尝试 `--mode=force-rebuild --domain=03-backend --projects=projA,projB` 或 `--mode=force-rebuild --mode=diff`,when skill 启动,then 必须直接报错 "force-rebuild 与跨项目 / diff 模式互斥" 并中止;成功 force-rebuild 完成后,根 `CHANGELOG.md` 必须新增一条 `(user-visible)` 条目记录此次重生。

### Scope Boundaries(Force Rebuild 增量)

- 不支持子领域 / 单文件 / 单维度的局部 force,理由是部分 force 会破坏横切文件与 overview "未激活维度地图" 的整体一致性。
- 不支持备份压缩或远程对象存储;备份是普通目录拷贝。
- 不修改 R34–R40 追加语义,full / diff 模式行为完全不变。
- 不引入备份差异比对 UI;差异核验由 git diff / 人工完成。
- 不引入 force-rebuild 灰度或独立 dry-run-only 模式;dry-run 是 safeguard 的一部分,不能脱离 force-rebuild 主流程独立运行。
- 不支持非 git 仓库 / shallow clone。
- 不与 R63–R66 跨项目对比、R60–R62 diff 模式叠加。

### Key Decisions(Force Rebuild 增量)

- **作为独立第三种 mode 而非开关**:`full / diff / force-rebuild` 三模式让语义边界清晰,避免 "diff + force" 这种语义复杂的交叉组合。
- **覆盖到 evidence 全量**:取最激进档,把备份当作唯一安全网。理由是 force-rebuild 的核心场景就是 "反悔棋",保留 evidence 会让 "清空" 语义不彻底。
- **domain 级颗粒度**:与 R49 / R50 的 domain 划分对齐;子领域级会带来横切文件与子领域文件的一致性维护成本,产品价值不高。
- **`.spec-first/backups/` 而非 git commit 备份**:不污染 commit 历史;与 spec-first 工作区一致;`.gitignore` 默认排除避免备份进 PR。
- **保留 N 份(默认 5)而非永久保留**:避免长期累积占用磁盘;5 份足够覆盖 "反悔后再反悔" 场景;超出由用户 `--keep=<N>` 调高。
- **失败自动回滚**:force-rebuild 是高风险操作,自动回滚降低事故代价;端负责人事后仍可显式 `--restore` 切到任意历史份。
- **强制 CHANGELOG 追加**:与项目 CLAUDE.md 治理约束一致;未追加则视为执行未完成,锁住后续 review / commit。

### Dependencies / Assumptions(Force Rebuild 增量)

- 依赖目标项目是 git 仓库且非 shallow clone;`.spec-first/backups/` 默认进入 `.gitignore`(skill 首次运行时确认或写入)。
- 依赖项目 `CLAUDE.md` Changelog 治理已配置 host developer profile;否则强制 CHANGELOG 追加无法读取作者标识。
- 依赖 Phase 2 默认 `full` 模式管道(R47–R55、R67–R69、R78–R80)已稳定,因 force-rebuild 重生阶段直接复用 full 管道。

### Outstanding Questions(Force Rebuild 增量)

#### Resolve Before Planning

- 无。

#### Deferred to Planning

- [Affects R87][Technical] `.spec-first/backups/` 的 `.gitignore` 自动维护策略:首次运行时 skill 是否需要主动写入 `.gitignore`,还是要求项目预先配置。
- [Affects R88][Technical] 二次确认在非交互(CI / 脚本)环境下的具体行为:本期默认拒绝非交互;`--yes` 是否配 `--ci` 双标志由 plan 阶段决定。
- [Affects R87][Technical] `manifest.json` 的完整 schema(字段命名、必填项、版本字段)留给 plan 阶段固化。
- [Affects R89][Technical] 自动回滚的实现方式:目录级覆盖 vs git stash + apply vs 文件级 diff 应用,plan 阶段决策。
- [Affects R85][Product] 多 domain 一次 force(`--domain=01-app-client,02-frontend`)的失败语义:其中一个 domain 失败时,其他 domain 是否也回滚,还是各自独立处理。

---

## Per-End Dimension Catalog（附录）

本附录列出每端 / 每行业的扩展维度核心关切与必检子项，供端 adapter 内部骨架模板与 Dimension Activator 配置参考。维度细节未到 evidence pattern 与 AI Rules 话术层级，那些细节由 `spec-plan` 阶段在 catalog 文件中产出。

### 客户端 Catalog（覆盖 KMP shared / Android / iOS）

**EA-Client-01. 多端共享与跨端架构**
- 核心关切：共享业务逻辑边界、跨端代码组织、平台适配优先级。
- 必检子项：expect/actual 模式适用范围、共享 ViewModel / UseCase / Repository 能力清单、共享层依赖隔离规则、共享逻辑能力清单与不可共享清单。
- 激活 signal：`shared/`、`commonMain/`、`iosMain/`、`androidMain/` 目录存在；KMP / Flutter / React Native 依赖声明。

**EA-Client-02. 平台差异处理**
- 核心关切：iOS Sandbox vs Android Scoped Storage、Permission 模型、通知机制、后台执行限制差异。
- 必检子项：Permission 请求流程与降级 UX、隐私清单（Info.plist / Privacy Manifest / Android Manifest）、APNs vs FCM 接入、后台任务策略。
- 激活 signal：`Info.plist`、`AndroidManifest.xml`、Permission 请求代码、`PrivacyInfo.xcprivacy`。

**EA-Client-03. 生命周期与资源管理**
- 核心关切：Activity / ViewController 生命周期、后台被杀、内存压力、进程边界数据持久化。
- 必检子项：onCreate / onDestroy 配对、viewDidLoad / viewWillDisappear 配对、Application / AppDelegate 边界、内存预警响应。
- 激活 signal：生命周期方法定义、`Application` / `AppDelegate` 类、`onLowMemory` / `didReceiveMemoryWarning`。

**EA-Client-04. 多市场与多展业地**
- 核心关切：国际化（i18n）资源、地区合规差异（GDPR / 个保法 / 中东合规）、Feature flag、Build variant / Scheme / Flavor。
- 必检子项：`strings.xml` / `Localizable.strings` 组织、地区合规边界声明、feature flag 配置中心、构建变体管理。
- 激活 signal：`values-*/strings.xml`、`*.lproj/`、`BuildConfig` / `xcconfig`、feature flag SDK 依赖。

**EA-Client-05. 设备能力与权限**
- 核心关切：相机 / 定位 / 推送 / 生物识别 / 传感器、Privacy Manifest / Data Safety。
- 必检子项：权限请求最小化、降级 UX、隐私清单完整性、生物识别失败处理。
- 激活 signal：相机 / 定位 / 推送相关 import、`requestPermission` 调用、`LAContext` / `BiometricPrompt`。

**EA-Client-06. 网络与离线**
- 核心关切：弱网检测、重试策略、离线缓存、图片加载策略。
- 必检子项：超时配置、指数退避、缓存有效期、SSL Pinning。
- 激活 signal：Retrofit / Alamofire / Ktor Client 配置、Coil / Glide / SDWebImage 依赖、NetworkObserver。

**EA-Client-07. 启动性能与包体积**
- 核心关切：冷启动 / 热启动指标、启动任务编排、包体积优化（ProGuard / R8 / App Thinning / Dynamic Feature）。
- 必检子项：启动任务异步化、Splash 处理、动态化策略、bytecode shrinker 配置。
- 激活 signal：`Application.onCreate` 自定义逻辑、ProGuard / R8 配置、`SceneDelegate`、Dynamic Feature 模块。

**EA-Client-08. 本地存储与数据安全**
- 核心关切：Keychain / Keystore / EncryptedSharedPreferences、敏感数据生命周期、本地数据库加密。
- 必检子项：敏感数据加密强度、Token 刷新与失效、日志脱敏、生物识别绑定。
- 激活 signal：`Keychain Item Access` 配置、`KeyStore` / `EncryptedSharedPreferences` 用法、Room / SQLDelight 加密配置。

**子领域骨架特有内容**：
- **KMP shared**：expect/actual 边界规则、Coroutines/Flow 跨端模式、`commonTest` 测试约定。
- **Android**：Compose vs XML 选型、Hilt/Dagger DI、Jetpack 组件选择、ViewModel/Flow/StateFlow 模式、ProGuard 规则。
- **iOS**：SwiftUI vs UIKit 选型、Combine / async-await 模式、Coordinator / MVVM 模式、Swift Concurrency 安全。

### 前端 Catalog（覆盖 H5 / Admin / SDK）

**EA-Web-01. 渲染策略**
- 核心关切：SSR / CSR / ISR / SSG 选择、Hydration 处理、首屏指标。
- 必检子项：Hydration mismatch 防护、SEO 关键页面渲染策略、FCP / LCP 预算。
- 激活 signal：`getServerSideProps` / `generateStaticParams` / `use client` 指令、`next` / `nuxt` / `remix` 依赖。

**EA-Web-02. 路由与导航**
- 核心关切：文件路由 vs 配置式路由、Layout 嵌套、Route Guard、Deep Link。
- 必检子项：嵌套路由 Layout 复用、路由级权限拦截、URL 设计规范。
- 激活 signal：`app/` 或 `pages/` 目录、`router.config`、`<Route>` / `<Routes>` 用法。

**EA-Web-03. 状态管理**
- 核心关切：全局 / Server / URL / Component 状态边界、状态库选型、状态持久化。
- 必检子项：Server state 由 React Query / SWR / TanStack Query 管理、URL state 不重复存全局、持久化敏感度判定。
- 激活 signal：Redux / Zustand / Jotai / Pinia / Vuex 依赖、`useQuery` / `useSWR` 用法、`localStorage` / `sessionStorage` 调用。

**EA-Web-04. 类型系统**
- 核心关切：TS 严格度、Type 导出策略、运行时校验、范型规范。
- 必检子项：`strict` / `noImplicitAny` / `strictNullChecks` 开启、API 类型与运行时校验（Zod / Yup）配套、范型命名规范。
- 激活 signal：`tsconfig.json` strict 配置、`export type` 用法、Zod / Yup / io-ts 依赖。

**EA-Web-05. 组件设计与样式体系**
- 核心关切：Atomic Design / Container-Presenter、组件复用度、样式方案、主题系统。
- 必检子项：基础组件 / 业务组件分层、Headless UI 边界、主题变量、响应式断点。
- 激活 signal：`components/` 子目录结构、Storybook 配置、Tailwind / CSS-in-JS / Sass / CSS Modules 依赖。

**EA-Web-06. 性能与加载**
- 核心关切：Code Splitting、懒加载、虚拟列表、缓存策略。
- 必检子项：路由级懒加载、长列表虚拟化、HTTP / SW / React Cache 层级、Bundle 预算。
- 激活 signal：`dynamic(import())` / `React.lazy` 用法、`IntersectionObserver`、`react-window` / `react-virtuoso` 依赖。

**EA-Web-07. 包体积与构建**
- 核心关切：Tree shaking、第三方库选型、资源 CDN、构建配置。
- 必检子项：依赖体积审计、`lodash` → `lodash-es` 替换、字体优化、构建工具配置。
- 激活 signal：`package.json` 依赖项、`vite.config` / `webpack.config`、`browserslist`。

**EA-Web-08. 安全防护**
- 核心关切：XSS / CSRF / CSP、Token 存储位置。
- 必检子项：`dangerouslySetInnerHTML` 使用边界、CSRF Token 或 SameSite Cookie、CSP header、Token 存储（HttpOnly Cookie vs localStorage）。
- 激活 signal：DOMPurify / sanitize-html 依赖、Cookie 配置代码、CSP meta 标签。

**EA-Web-09. 兼容性与降级**
- 核心关切：浏览器矩阵、polyfill、降级策略。
- 必检子项：`browserslist` 明确、`@babel/preset-env` 配置、能力检测降级路径。
- 激活 signal：`browserslist` 字段、polyfill 引用、`core-js` 依赖。

**EA-Web-10. 监控与可观测性**
- 核心关切：错误上报、Web Vitals、用户行为埋点。
- 必检子项：Sentry / Bugsnag 接入、`reportWebVitals` 上报、埋点规范。
- 激活 signal：Sentry / Bugsnag / DataDog RUM SDK 依赖、`reportWebVitals` 调用、analytics 代码。

**EA-Web-11. SEO 与元信息**
- 核心关切：Meta 标签、结构化数据、sitemap。
- 必检子项：Open Graph / Twitter Card、JSON-LD、canonical URL。
- 激活 signal：`<Head>` 用法、`next-sitemap` / 等效 sitemap 工具、`schema.org` JSON-LD 标记。

**子领域骨架特有内容**：
- **H5（移动 Web）**：移动适配（rem / viewport / safe-area）、微信内嵌兼容、JSBridge。
- **Admin（中后台）**：复杂表单（动态字段 / 嵌套验证 / 批量）、大表格（虚拟滚动 / 固定列 / 行内编辑）、权限粒度（菜单 / 按钮 / 字段 / 数据）、导入导出。
- **SDK（前端 SDK）**：包打包格式（ESM / CJS / UMD）、副作用控制、兼容性矩阵、Tree-shaking 友好入口。

### 后端 Catalog（覆盖 Java / Python / Go / Node）

**EA-Backend-01. API 设计与版本化**
- 核心关切：RESTful / GraphQL / gRPC 选型、URL 命名、HTTP 状态码、版本策略、幂等性。
- 必检子项：版本策略（URL / Header / Media Type）、契约文档（OpenAPI / Protobuf）、幂等 Key 设计。
- 激活 signal：Controller / Resolver / RPC 服务定义、OpenAPI / Protobuf schema 文件、`X-Idempotency-Key` 处理。

**EA-Backend-02. 数据库与持久化**
- 核心关切：ORM / DAO / Repository 选型、Migration 规范、事务边界、索引、分库分表。
- 必检子项：Migration forward-only vs reversible 政策、事务隔离级别、慢查询审计、索引设计原则。
- 激活 signal：Entity / Mapper / Repository 定义、`migrations/` 目录、`@Transactional` 用法。

**EA-Backend-03. 缓存与一致性**
- 核心关切：多级缓存、缓存穿透 / 击穿 / 雪崩、Cache-aside / Write-through / Write-behind、缓存与 DB 一致性。
- 必检子项：缓存 Key 设计、过期策略、防击穿（singleflight）、双写一致性策略。
- 激活 signal：Redis / Caffeine 操作、`@Cacheable` 用法、缓存中间件依赖。

**EA-Backend-04. 消息队列与异步**
- 核心关切：MQ 选型、生产者幂等、消费者幂等 / 重试 / 死信、消息顺序与分区。
- 必检子项：生产事务消息、消费幂等键、死信处理与回溯、消费速率控制。
- 激活 signal：Kafka / RocketMQ / RabbitMQ 依赖、`@RocketMQMessageListener` / `@KafkaListener` 注解、producer/consumer 包目录。

**EA-Backend-05. 并发与限流**
- 核心关切：线程池配置、锁选择、限流策略、熔断与降级。
- 必检子项：线程池隔离、分布式锁选型、令牌桶 / 漏桶 / Sliding Window、Sentinel / Resilience4j 接入。
- 激活 signal：`ThreadPoolExecutor` 配置、`@SentinelResource`、`RateLimiter`、Redisson / Curator 依赖。

**EA-Backend-06. 鉴权与权限粒度**
- 核心关切：认证（JWT / OAuth2 / Session）、授权（RBAC / ABAC）、网关层 vs 服务层鉴权、Token 刷新。
- 必检子项：Token 失效策略、刷新机制、资源粒度权限、网关/服务鉴权边界。
- 激活 signal：`SecurityFilterChain`、`@PreAuthorize`、JWT 解析代码、OAuth2 client 配置。

**EA-Backend-07. 配置与密钥**
- 核心关切：配置中心、环境隔离、密钥管理、配置变更监听。
- 必检子项：敏感配置不入代码、配置版本化、`@RefreshScope` 边界、密钥旋转。
- 激活 signal：`@ConfigurationProperties`、Nacos / Apollo / Vault SDK 依赖、`application-*.yml`。

**EA-Backend-08. 可观测性**
- 核心关切：日志结构化、链路追踪、Metrics、错误上报。
- 必检子项：MDC 注入、TraceId 贯穿、Prometheus / Micrometer 指标、Sentry / Bugsnag 接入。
- 激活 signal：`log4j2.xml` / `logback.xml`、`@NewSpan`、OpenTelemetry / SkyWalking 依赖、`MeterRegistry` 用法。

**EA-Backend-09. 部署与运行时**
- 核心关切：容器化、K8s（HPA / PDB / 健康检查）、优雅启停、配置注入。
- 必检子项：Dockerfile 最佳实践、readiness vs liveness 区分、SIGTERM 处理、ConfigMap / Secret 使用。
- 激活 signal：`Dockerfile`、`deployment.yaml`、`application.yml` `graceful-shutdown`、`SpringApplication.shutdownGracefully`。

**EA-Backend-10. 错误处理与重试**
- 核心关切：统一异常处理、业务异常 vs 系统异常分类、重试策略、幂等保护。
- 必检子项：`@ControllerAdvice` 统一处理、错误码体系、exponential backoff、幂等注解。
- 激活 signal：`@ExceptionHandler`、`RetryTemplate` / Spring Retry / Resilience4j Retry、自定义错误码枚举。

**子领域骨架特有内容**：
- **Java（Spring Boot）**：Bean 生命周期与 DI、AOP 切面、JVM 调优、Lombok 边界、Stream API 用法。
- **Python**：依赖管理（Poetry / uv / pip-tools）、`asyncio` / FastAPI、类型提示（mypy / pyright）、数据类（dataclass / pydantic）。
- **Go**：包组织、goroutine / channel、Context 传播、error wrapping、接口设计原则。
- **Node**：异步模式（async/await / Stream）、包管理（pnpm workspace）、TS 严格度、内存管理。

### 行业 Catalog（覆盖金融 / 电商 / 教育 / 医疗 / 政企 / SaaS）

**IND-01. 高风险模块识别**
- 核心关切：资金链路、隐私链路、安全链路。
- 必检子项：高风险模块清单、变更评审强度、回滚策略。
- 激活 signal：支付 / 订单 / 用户中心模块名、关键字（balance / amount / refund / consent）。

**IND-02. 合规要求**
- 核心关切：GDPR / 个保法 / PCI-DSS / HIPAA / 等保 / 教育部合规。
- 必检子项：数据采集同意、数据出境、留存期、删除权落地。
- 激活 signal：privacy policy 文件、`consent` / `gdpr` 代码、地区合规中间件依赖。

**IND-03. 数据敏感分级**
- 核心关切：PII / PCI / PHI 识别、敏感字段加密、传输安全。
- 必检子项：敏感字段标注、字段级加密、传输 TLS 配置、脱敏策略。
- 激活 signal：`@Sensitive` 注解、加密工具调用、`mask` / `desensitize` 函数。

**IND-04. 日志与审计**
- 核心关切：审计日志、操作可追溯、审计日志不可篡改。
- 必检子项：审计字段（who / what / when / where / why）、审计日志独立存储、保留期。
- 激活 signal：`audit_log` 表 / 模块、`@Audit` 注解、审计中间件。

**IND-05. 术语与领域模型**
- 核心关切：领域统一术语、防腐层、限界上下文。
- 必检子项：术语表、跨服务术语翻译规则、防腐层适用场景。
- 激活 signal：`domain/` 目录、`anti-corruption` / `acl` 命名、术语词典文件。

**IND-06. 关键链路一致性**
- 核心关切：跨服务事务、最终一致性、补偿机制。
- 必检子项：Saga / TCC / 本地消息表选型、对账机制、补偿超时。
- 激活 signal：Saga / TCC 框架依赖、对账任务定义、`compensation` 命名。

**子领域骨架特有内容**：
- **证券（公司主营，独立子领域，与"金融"并列）**：
  - **SEC-01 行情系统**：高频实时数据接入（Level 1 / Level 2 / Tick）、订阅管理、压缩与延迟、行情切片快照、TCP/UDP 协议选型、行情合规与延迟披露。
  - **SEC-02 交易系统**：订单生命周期（接收 → 风控 → 撮合 → 回报）、订单类型（限价 / 市价 / 算法单 / 条件单 / FOK / IOC）、订单状态机、回报推送、错单处理。
  - **SEC-03 盘前与实时风控**：自成交防护、频繁报撤拦截、单只标的限额、单账户限额、合规规则引擎、异常交易识别、反洗钱（AML）。
  - **SEC-04 清算与结算**：T+0 / T+1 / T+2 模式、净额轧差、对账机制、资金交收、过户处理、错单纠正。
  - **SEC-05 账户与权限**：资金账户 / 证券账户 / 衍生品账户隔离、业务权限模型（融资融券 / 期权交易权限 / 港股通 / 北交所交易权限）、KYC 与适当性管理。
  - **SEC-06 监管报送与审计**：报送格式（监管 XML / CSV / FIX 接口）、报送时效（T+0 / T+1）、留痕审计、合规存证（不可篡改）、监管标签注入。
  - **SEC-07 时序与交易日历**：交易时段（集合竞价 / 连续竞价 / 收盘集合）、节假日与停牌处理、交易日历驱动的业务逻辑、夜盘 / 港股通时差。
  - **SEC-08 接入协议**：FIX 协议、CTP API（期货）、行情网关、券商内部协议、低延迟优化（内核旁路 / RDMA / 共享内存）、协议版本兼容。
  - **SEC-09 金融工程与定价**：定价模型（BS / 二叉树 / 蒙特卡洛）、希腊字母（Delta / Gamma / Vega / Theta）、VaR / 压力测试、组合管理、收益归因。
  - **SEC-10 灾备与稳定性**：双中心 / 异地多活、毫秒级切换、交易系统 SLA、降级开关、断线重连、限速保护。
  - **跨境交易扩展（港美股 / 港股通 / 美股通 / QDII，公司核心业务延伸）**：
    - **XSEC-01 跨时区与交易时段**：美股盘前 / 盘中 / 盘后时段、夏令时与冬令时切换、港股交易时段、跨时段订单生命周期、隔夜挂单处理、跨时区时间字段标准化（UTC 存储 + 时区转换显示）。
    - **XSEC-02 多币种与外汇**：USD / HKD / CNY 多币种账户、汇率风险敞口、外汇结售汇、跨币种 PnL 计算、汇率定价基准（中间价 / 实时价 / 银行牌价）。
    - **XSEC-03 跨境合规与额度**：QDII / 港股通 / 北上资金 / 美股通额度管理、外管局申报、跨境数据流转合规、投资者适当性（港股通开通条件、美股 W-8BEN 表填写）。
    - **XSEC-04 跨境行情源**：HKEx / NASDAQ / NYSE 直连或转发、不同延迟级别（实时 / 15 分钟延迟 / 1 分钟延迟）、第三方行情商（彭博 / Refinitiv / WIND）接入、行情授权与计费、行情合规与展示限制。
    - **XSEC-05 交易规则差异**：港股 T+0 撤单 vs A 股 T+1、Lot size（手数）差异、美股盘前盘后交易（4:00–9:30 / 16:00–20:00 ET）、Limit-on-close 等特殊订单类型、最小报价单位（tick size）、停牌与熔断规则差异、做空与融券规则差异。
    - **XSEC-06 跨境结算与税务**：T+2 国际结算惯例、外汇交收链路、美股股息预扣税（30% 默认 / 协议优惠）、港股印花税、跨境清算路径（DTCC / CCASS / 中国结算）、税务报告（1042-S / 1099-DIV）。
    - **激活 signal 示例**：`hk-stock` / `us-stock` / `cross-border` / `qdii` / `northbound` / `southbound` 等模块或包名；HKEx / NASDAQ / NYSE 行情接入代码；外汇汇率服务依赖；跨时区时间处理代码（`ZoneId.of("America/New_York")` / `Asia/Hong_Kong`）；夏令时切换处理；W-8BEN / 1042-S 等税务表单生成模块。
  - **业务线子方向**：经纪业务（零售，含 A 股 / 港股 / 美股 / 港美股通）、自营、资管 / 公募、投行、量化交易、期权 / 期货、融资融券、固定收益。
  - **激活 signal 示例**：`market-data` / `quote` / `level2` / `order` / `trading` / `match` / `risk-control` / `clearing` / `regulatory` 等模块名；FIX SDK、CTP API、交易所网关 SDK 依赖；订单状态机类、交易日历类、监管报送任务定义。
- **金融（非证券：银行 / 支付 / 信贷 / 保险）**：资金幂等、对账、风控接入点、PCI-DSS、KYC、反欺诈、信贷决策、保险精算。
- **电商**：订单状态机、库存一致性、营销规则隔离、价格风控。
- **教育**：未成年人保护、课程版权、家校互动隐私。
- **医疗**：HIPAA / 医保合规、患者数据访问审计、生命科学数据完整性。
- **政企**：等保 / 商密合规、数据本地化、跨网传输管控。
- **SaaS**：多租户隔离、配额计费、租户级配置。

---

## Output Directory Structure Reference（附录）

本附录展示按 R47–R55 + R49 + Per-End Catalog 跑完后**实际产出的目录结构**，供 `spec-plan` 阶段直接消费，避免从 R50 反推。激活态决定哪些文件实际产出（`baseline` / `activated` 产出独立文件或章节；`candidate` 不产出文件，仅在 overview"未激活维度地图"中列出）。

### 顶层结构与四端 domain

```text
engineering-standards/
│
├── 01-app-client/                                  ← 客户端 domain
│   ├── 00-app-client-overview.md                   # Overview + 未激活维度地图
│   │
│   ├── 01-kmp-shared-standard.md                   # 子领域: KMP shared
│   ├── 02-android-standard.md                      # 子领域: Android
│   ├── 03-ios-standard.md                          # 子领域: iOS
│   │
│   ├── 11-state-error-standard.md                  # 横切 D04+D06 [baseline]
│   ├── 12-naming-conventions-standard.md           # 横切 D02 [baseline]
│   ├── 13-platform-diff-standard.md                # 横切 EA-Client-02 [activated]
│   ├── 14-multi-market-standard.md                 # 横切 EA-Client-04 [activated|candidate]
│   ├── 15-security-data-standard.md                # 横切 D11+EA-Client-08 [baseline]
│   ├── 16-observability-standard.md                # 横切 D12 [baseline]
│   ├── 17-launch-performance-standard.md           # 横切 EA-Client-07 [activated]
│   ├── 18-testing-standard.md                      # 横切 D09 [baseline]
│   ├── 19-build-dependency-standard.md             # 横切 D13 [activated]
│   │
│   ├── ai-rules.md                                 # 派生: AI 生成规范
│   ├── review-checklist.md                         # 派生: Review 检查项
│   │
│   └── evidence/
│       ├── code-facts.md
│       ├── positive-examples.md
│       ├── forbidden-examples.md
│       ├── legacy-compatible.md
│       ├── project-specific-divergence.md          # 多项目对比时
│       ├── dimension-activation-report.json        # R54 激活报告
│       └── gitnexus-facts.md                       # GitNexus 接入时
│
├── 02-frontend/                                    ← 前端 domain
│   ├── 00-frontend-overview.md
│   │
│   ├── 01-h5-standard.md                           # 子领域
│   ├── 02-admin-standard.md                        # 子领域
│   ├── 03-sdk-standard.md                          # 子领域（candidate 时不出）
│   │
│   ├── 11-state-management-standard.md             # EA-Web-03 [baseline]
│   ├── 12-routing-standard.md                      # D07+EA-Web-02 [baseline]
│   ├── 13-typescript-standard.md                   # EA-Web-04 [activated]
│   ├── 14-rendering-strategy-standard.md           # EA-Web-01 [activated]
│   ├── 15-component-design-standard.md             # D08+EA-Web-05 [baseline]
│   ├── 16-performance-loading-standard.md          # D10+EA-Web-06 [baseline]
│   ├── 17-bundle-build-standard.md                 # D13+EA-Web-07 [activated]
│   ├── 18-security-standard.md                     # D11+EA-Web-08 [baseline]
│   ├── 19-compatibility-standard.md                # EA-Web-09 [activated]
│   ├── 20-monitoring-standard.md                   # D12+EA-Web-10 [baseline]
│   ├── 21-seo-meta-standard.md                     # EA-Web-11 [activated|candidate]
│   ├── 22-testing-standard.md                      # D09 [baseline]
│   │
│   ├── ai-rules.md
│   ├── review-checklist.md
│   └── evidence/...
│
├── 03-backend/                                     ← 后端 domain
│   ├── 00-backend-overview.md
│   │
│   ├── 01-java-standard.md                         # 子领域
│   ├── 02-python-standard.md                       # 子领域（candidate 时不出）
│   ├── 03-go-standard.md                           # 子领域（candidate 时不出）
│   ├── 04-node-standard.md                         # 子领域（candidate 时不出）
│   │
│   ├── 11-api-design-standard.md                   # EA-Backend-01 [baseline]
│   ├── 12-database-persistence-standard.md         # EA-Backend-02 [activated]
│   ├── 13-cache-consistency-standard.md            # EA-Backend-03 [activated]
│   ├── 14-mq-async-standard.md                     # EA-Backend-04 [activated|candidate]
│   ├── 15-concurrency-throttling-standard.md       # EA-Backend-05 [activated]
│   ├── 16-auth-permission-standard.md              # D11+EA-Backend-06 [baseline]
│   ├── 17-config-secrets-standard.md               # EA-Backend-07 [baseline]
│   ├── 18-observability-standard.md                # D12+EA-Backend-08 [baseline]
│   ├── 19-deployment-runtime-standard.md           # EA-Backend-09 [activated]
│   ├── 20-error-retry-standard.md                  # D06+EA-Backend-10 [baseline]
│   ├── 21-state-data-flow-standard.md              # D04 [baseline]
│   ├── 22-testing-standard.md                      # D09 [baseline]
│   │
│   ├── ai-rules.md
│   ├── review-checklist.md
│   └── evidence/...
│
└── 04-industry/                                    ← 行业 domain
    ├── 00-industry-overview.md
    │
    ├── 01-securities-standard.md                   # 证券（公司主营，长文）
    ├── 02-finance-standard.md                      # 金融非证券（candidate 时不出）
    ├── 03-ecommerce-standard.md                    # 候选
    │
    ├── 11-high-risk-modules-standard.md            # IND-01 [baseline]
    ├── 12-compliance-standard.md                   # IND-02 [activated]
    ├── 13-data-sensitivity-standard.md             # IND-03 [activated]
    ├── 14-audit-log-standard.md                    # IND-04 [baseline]
    ├── 15-domain-terminology-standard.md           # IND-05 [activated]
    ├── 16-critical-path-consistency-standard.md    # IND-06 [activated]
    │
    ├── ai-rules.md
    ├── review-checklist.md
    └── evidence/...
```

### 证券子领域文件内部章节结构

证券是公司主营业务，单文件 `01-securities-standard.md` 较长。文件内部章节按 R51 子领域骨架 + 证券特有维度组织如下：

```text
01-securities-standard.md

§1.  规范定位                                       [baseline]
§2.  职责边界（应承载 / 不应承载）                   [baseline]
§3.  推荐目录结构                                    [baseline]
§4.  分层规则                                        [baseline]
§5.  命名规范                                        [baseline]

§6.  核心维度（SEC-01 ~ SEC-10）
    §6.1  SEC-01 行情系统                           [activated]
    §6.2  SEC-02 交易系统                           [activated]
    §6.3  SEC-03 盘前与实时风控                     [activated]
    §6.4  SEC-04 清算与结算                         [activated]
    §6.5  SEC-05 账户与权限                         [activated]
    §6.6  SEC-06 监管报送与审计                     [activated|baseline]
    §6.7  SEC-07 时序与交易日历                     [activated]
    §6.8  SEC-08 接入协议                           [activated]
    §6.9  SEC-09 金融工程与定价                     [activated|candidate]
    §6.10 SEC-10 灾备与稳定性                       [baseline]

§7.  跨境交易扩展（XSEC-01 ~ XSEC-06）              [activated|candidate]
    §7.1  XSEC-01 跨时区与交易时段
    §7.2  XSEC-02 多币种与外汇
    §7.3  XSEC-03 跨境合规与额度
    §7.4  XSEC-04 跨境行情源
    §7.5  XSEC-05 交易规则差异
    §7.6  XSEC-06 跨境结算与税务

§8.  数据流链路（订单 / 行情 / 清算）                [activated]
§9.  错误模型                                        [baseline]
§10. AI 生成代码要求                                 [baseline]
§11. Code Review 检查项                              [baseline]
§12. Evidence 参考                                   [baseline]
```

### Overview "未激活维度地图" 示例样式

每个 domain 的 `00-{domain}-overview.md` 必须包含本章节（R51 Overview 骨架要求），呈现所有 `candidate` 维度，让团队规范保留"以后可能用到的维度地图"：

```markdown
## 未激活维度地图

以下维度在本次萃取的项目中未发现 evidence，因此不产出独立章节。
团队规范保留这些维度作为"以后可能用到的维度地图"，
新项目引入对应技术或场景时启用相应规则。

| 维度 | 未使用原因 | 候选 evidence 信号 | 启用条件 |
| --- | --- | --- | --- |
| EA-Backend-04 消息队列与异步 | 项目当前为同步调用 | Kafka / RocketMQ / RabbitMQ 依赖、`@KafkaListener` 注解、producer/consumer 目录 | 引入异步通信 |
| SEC-09 金融工程与定价 | 经纪业务不含自营定价 | `pricing/` 模块、BS / 蒙特卡洛实现、希腊字母计算 | 接入自营或量化业务 |
| XSEC-04 跨境行情源 | 仅做 A 股 | HKEx / NASDAQ 行情接入、第三方行情商 SDK | 上线港美股业务 |
```

### 横切文件 vs 子领域文件分工规则

并非所有 Layer 1 通用维度都拆为独立横切文件。拆分原则：

- **拆为横切文件**：维度跨多个子领域有显著差异且需要统一对比时（如 D04 状态、D06 错误、D09 测试、D11 安全、D12 可观测性、D13 构建治理）。
- **嵌入子领域文件**：维度在子领域内部表达更清晰时（如 D01 架构概览、D02 目录命名、D07 路由——客户端的路由与前端 / 后端的路由形态差异大）。
- **端类型扩展维度**（Layer 2）默认拆为横切文件，但项目未激活的维度走 `candidate` 通道，不产出文件。

具体映射规则由 plan 阶段固化到维度激活规则配置（R52）中。

### 跨 domain 横切的可选扩展

当前结构里安全 / 合规 / 可观测性等横切文件**在各 domain 下各自存在**（`01-app-client/15-security-data-standard.md` 与 `03-backend/16-auth-permission-standard.md` 互相独立）。若团队希望在四个 domain 之上提供"全公司统一总纲"，可选项是新增顶级目录：

```text
engineering-standards/
├── 00-cross-domain/                              ← 跨 domain 顶级横切（可选）
│   ├── 00-cross-domain-overview.md
│   ├── 11-security-architecture-standard.md      # 跨端安全总纲
│   ├── 12-data-governance-standard.md            # 跨端数据治理总纲
│   ├── 13-compliance-master-standard.md          # 跨端合规总纲
│   ├── 14-incident-response-standard.md          # 跨端事故响应总纲
│   └── evidence/
├── 01-app-client/...
├── 02-frontend/...
├── 03-backend/...
└── 04-industry/...
```

是否启用 `00-cross-domain/` 由团队决定，作为 plan 阶段的可选项。本期 R50 不强制要求。
