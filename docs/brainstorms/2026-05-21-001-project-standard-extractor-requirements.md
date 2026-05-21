---
date: 2026-05-21
topic: project-standard-extractor
spec_id: 2026-05-21-001-project-standard-extractor
---

# Project Standard Extractor Requirements

## Summary

本需求定义第一阶段的 `project-standard-extractor`：一个以 Skill 作为 workflow 编排器、以多个专业 agent 执行具体萃取任务的规范萃取能力。它从真实项目代码和团队上下文中提炼 APP、前端、后端和行业维度的团队级规范，并直接写入正式规范目录，初始状态为 `draft`。

---

## Problem Frame

当前团队沉淀规范主要依赖端负责人人工编写。这种方式成本高，容易写成抽象原则，也容易遗漏真实代码中的推荐模式、历史旧写法、反例和团队隐性约定。

第一阶段要解决的不是“如何建设一个规范平台”，而是如何让 Skill 基于真实代码萃取出准确反映团队当前编码习惯的规范文档。输出结果不能变成某个项目的代码说明书，而必须是从多个项目、多个微服务或多个端工程实践中提炼出的团队级标准。

相关背景和技术方案见：

- `docs/01-版本路线/产品定位说明.md`
- `docs/01-版本路线/同类产品调研与借鉴.md`
- `docs/02-技术方案/第一阶段技术方案.md`
- `docs/02-技术方案/skill建设.md`
- `docs/02-技术方案/高质量萃取.md`
- `docs/02-技术方案/AI快速索引最终方案.md`

---

## Actors

- A1. 端负责人：提供项目样本、确认萃取范围、审核 `draft` 规范并将其升级为 `active`。
- A2. 架构负责人：参与高影响规则讨论，帮助判断团队级架构边界，但第一阶段不是 `draft -> active` 的必需审批人。
- A3. Skill Workflow：负责交互式输入引导、任务拆解、agent 调度、产物汇总、状态写入和质量门禁。
- A4. 专业 Agent：在 workflow 调度下完成项目画像、证据收集、代码事实提取、模式分类、端规范生成、行业规范生成、AI Rules 生成、Review Checklist 生成和分面评审等任务。
- A5. AI 使用者：在真实开发或评审中临时使用 `draft` 规范，并关注高风险 draft 规则的未审核提示。
- A6. Reviewer：使用规范和 Checklist 检查人工或 AI 生成代码，并把高频问题反哺为新规则。

---

## Key Flows

- F1. 交互式萃取启动
  - **Trigger:** 端负责人要求从一个或多个项目中萃取规范。
  - **Actors:** A1, A3
  - **Steps:** Skill 先接收最小启动输入，再按引导顺序逐步补齐研发域、行业、输出范围、技术栈、业务模块、候选正反例、已有文档、质量关注点和输出目标。
  - **Outcome:** Skill 获得足够上下文，可以启动 agent 编排。
  - **Covered by:** R5, R6, R7, R8, R9

- F2. 分阶段 agent 萃取
  - **Trigger:** 输入上下文确认完成。
  - **Actors:** A3, A4
  - **Steps:** 前置阶段串行统一项目画像、证据口径、代码事实和模式分类；端规范、行业规范进入并行生成；AI Rules、Review Checklist、evidence 和分面评审进入辅助生成；最后统一质量门禁和写入。
  - **Outcome:** 生成可进入正式规范目录的 `draft` 规范内容。
  - **Covered by:** R10, R11, R12, R13, R14, R15, R16, R41, R42

- F3. 规范写入和重复运行
  - **Trigger:** agent 产物通过质量门禁。
  - **Actors:** A3, A4
  - **Steps:** Merge Coordinator 将新增规则追加为 `draft`，将证据写入独立 evidence，识别相近规则和冲突规则，避免覆盖已有 `draft` 或 `active` 内容。
  - **Outcome:** 规范目录产生可用的 `draft` 文档和待确认项。
  - **Covered by:** R29, R34, R35, R36, R37, R38, R39, R40

- F4. 审核和使用
  - **Trigger:** `draft` 规范被写入正式规范目录。
  - **Actors:** A1, A5, A6
  - **Steps:** `draft` 默认可被 AI 临时使用；命中高风险 draft 规则时 AI 提示未审核状态；端负责人审核后将 `draft` 升级为 `active`；Review 问题和 AI 出错案例反向沉淀。
  - **Outcome:** 规范形成使用、审核、修订闭环。
  - **Covered by:** R30, R31, R32, R33, R43, R44, R45, R46

---

## Requirements

**产品定位与范围**

- R1. Skill 的主路径必须是“萃取规范”：从真实项目代码和团队上下文中生成规范文档草稿，而不是以 AI 开发执行或 Review 治理作为第一主路径。
- R2. Skill 输出必须是团队级规范，不得写成某个项目、某个微服务或某个代码目录的说明书。
- R3. 第一阶段必须覆盖 APP、前端、后端三个研发域，并输出完整端规范。
- R4. 第一阶段必须生成独立行业规范，行业规范结合行业共性和从代码中萃取出的团队特性；不得写成脱离团队实践的行业白皮书。

**交互式输入**

- R5. Skill 必须采用交互式引导输入，不得要求用户一次性填写完整表单。
- R6. Skill 至少支持以一个或多个项目路径作为最小启动输入。
- R7. Skill 的引导顺序必须先确定萃取边界，再补充质量增强信息：项目路径、研发域、行业场景、输出范围、技术栈或子领域、业务模块、正例候选、反例或历史兼容候选、已有文档、质量关注点、输出目标、确认声明。
- R8. 如果用户已提供某项输入，Skill 不得重复追问；如果可从代码结构自动推断，Skill 应给出推断结果并让用户确认。
- R9. 行业输入应在研发域之后尽早确认，用于影响高风险模块、合规、日志、权限、状态一致性和术语关注点。

**Agent 编排**

- R10. 第一阶段对外只暴露一个 Skill：`project-standard-extractor`；它必须作为 workflow orchestrator，而不是单体大 Prompt，也不拆成 APP / 前端 / 后端 / 行业多个对外入口。
- R11. 第一阶段必须采用混合 agent 模型：通用阶段 Agent 保证流程一致和证据口径一致，领域专项 Agent 保证 APP、前端、后端和行业规范的专业性。
- R12. `project-standard-extractor` 负责输入引导、任务拆解、agent 调度、产物汇总、状态写入和质量门禁；内部 agent 才负责具体萃取、生成和评审任务。
- R13. 第一阶段 agent 角色必须至少覆盖：Intake、Project Profiler、Evidence Collector、Code Facts、Pattern Classifier、APP Standard、Frontend Standard、Backend Standard、Industry Standard、AI Rules、Review Checklist、Evidence Writer、Evidence Auditor、Team Standard Reviewer、AI Executability Reviewer、Review Checklist Reviewer、Conflict Reviewer、Industry Risk Reviewer、Quality Gate、Merge Coordinator。
- R14. agent 执行必须采用分阶段并行：前置事实与模式分类串行统一，端规范和行业规范并行生成，AI Rules、Review Checklist、Evidence 和分面评审并行生成，最后串行质量门禁和写入。
- R15. 所有专项 Agent 必须基于同一份代码事实和模式分类输出，不得自行重新定义证据口径。
- R16. AI Rules 和 Review Checklist 必须基于已归一的规则候选生成，不得直接脱离规则候选自由发挥。

**规范输出**

- R17. APP、前端、后端规范输出必须采用统一主结构，并允许端内扩展。
- R18. 统一主结构必须至少包含 overview、standard、ai-rules、review-checklist、examples、evidence。
- R19. APP 端扩展必须覆盖 KMP、Android、iOS、数据中台、多展业地等子领域。
- R20. 前端扩展必须覆盖 H5、Admin、组件、API、状态、权限、类型等子领域。
- R21. 后端扩展必须覆盖 Java、Python、API、数据库、缓存、MQ / 任务等子领域。
- R22. 行业规范必须至少包含行业通用关注点、团队代码萃取规则、高风险模块规则、AI 生成规则和 Review Checklist。

**规则与证据**

- R23. 规则正文必须抽象为跨项目、跨微服务、跨代码库可复用的团队级约束。
- R24. 代码路径、项目来源、正例、反例和历史兼容证据必须放入独立 evidence 附录或 evidence 目录，不得让规则正文绑定具体项目路径。
- R25. 证据只用于萃取、审核和追溯，不得限定规则适用范围。
- R26. 单项目或单微服务萃取出的高质量规则只要来自真实代码并通过质量门禁，就可以直接进入 `draft` 规范。
- R27. 推荐写法、反例和历史旧写法都可以输出到规范体系中，但必须标明类型，避免把历史旧写法当成推荐规范。
- R28. 行业共性可以作为行业规范框架和关注点；没有代码证据或负责人确认的行业规则必须标记为 `draft` 或待确认。

**状态与审核**

- R29. Skill 必须直接写入正式规范目录，初始状态标记为 `draft`。
- R30. `draft` 规范默认可被 AI 临时使用。
- R31. `draft -> active` 由对应端负责人审核确认即可；架构负责人可参与评审，但不是第一阶段必需审批人。
- R32. AI 命中高风险 draft 规则时必须提示未审核状态；高风险 draft 包括 P0、FORBIDDEN、行业高风险、与 active 冲突或 pending-confirmation 的规则。
- R33. 低风险 draft 规则可默认使用，不要求每次额外提示，避免输出噪音。

**重复运行和冲突处理**

- R34. Skill 重复运行时不得覆盖已有 `active` 规则。
- R35. Skill 重复运行时默认不得覆盖已有 `draft` 规则。
- R36. 新发现规则必须追加为 `draft`。
- R37. 与已有规则语义相近的内容必须进入待合并建议。
- R38. 与已有规则冲突的内容必须进入冲突待确认。
- R39. 新增证据应追加到 evidence，不直接改写规则正文。
- R40. 历史旧写法应追加到 legacy-compatible 或等效区域，不得覆盖推荐规则。

**质量门禁**

- R41. 进入 `draft` 的规则必须通过质量门禁：证据门禁、团队级抽象门禁、AI 可执行门禁、Review 可检查门禁、冲突门禁、行业风险门禁、正反例门禁、规则数量门禁和人工确认门禁。
- R42. 质量门禁必须由多个内部评审 agent 分面完成，并由 Quality Gate 汇总，不得只依赖生成 agent 自评。
- R43. P0 和 FORBIDDEN 规则必须有明确 AI 生成要求和 Review 检查项。
- R44. 规则必须区分 P0、P1、P2、LEGACY、FORBIDDEN 或等效等级。
- R45. Skill 输出必须区分推荐模式、禁止模式、历史兼容模式和待人工确认模式。
- R46. Skill 不得仅凭行业输入生成缺少代码证据或负责人确认的团队强制规则。

---

## Acceptance Examples

- AE1. **Covers R5, R6, R7, R8.** Given 用户只提供三个后端服务路径，when Skill 启动萃取，then Skill 应先确认研发域、行业场景和输出范围，而不是要求用户一次性填写完整表单。
- AE2. **Covers R2, R23, R24, R25.** Given Skill 从某个交易服务发现 Controller / Service 分层模式，when 输出后端规范，then 规则正文应表达团队级分层约束，具体服务代码路径应写入 evidence，而不是写成该服务的代码说明。
- AE3. **Covers R26, R29, R30, R31.** Given 单个高质量微服务提供了真实证据，when 规则通过质量门禁，then 该规则可以直接进入正式规范目录并标记为 `draft`，AI 可临时使用，端负责人审核后可升级为 `active`。
- AE4. **Covers R10, R11, R12, R13, R14, R15, R41, R42.** Given 一次萃取同时覆盖 APP、前端、后端和行业规范，when agent 执行，then 前置事实和模式分类必须先统一，专项规范和分面评审可并行执行，但所有专项 Agent 必须使用同一份事实和分类结果。
- AE5. **Covers R32, R33.** Given AI 使用 `draft` 规范生成代码，when 命中一个 P0 或行业高风险 draft 规则，then AI 必须提示该规则未审核；when 命中低风险 draft 命名建议，then 可默认使用且无需额外提示。
- AE6. **Covers R34, R35, R36, R37, R38, R39, R40.** Given 同一研发域已有 `active` 和 `draft` 规范，when Skill 再次运行，then 它不得覆盖已有规则，应追加新 draft、追加证据，并把相近或冲突规则写入待合并或冲突待确认。

---

## Success Criteria

- 端负责人能用少量交互输入启动规范萃取，而不再完全依赖人工从零编写规范。
- Skill 输出的 APP、前端、后端和行业规范能准确反映当前团队代码实践。
- 输出规范能被人阅读、被 AI 临时使用、被 Review 引用检查。
- 规则正文保持团队级抽象，证据保持可追溯，不把规范写成项目代码说明书。
- `draft`、`active`、待确认、冲突和历史兼容的状态边界清晰。
- 后续 `spec-plan` 不需要重新发明输入流程、agent 拆分、状态机制、输出结构或质量门禁。

---

## Scope Boundaries

- 不建设规范管理 Web 平台。
- 不建设完整 CLI 产品。
- 不做全量历史代码整改。
- 不要求 Skill 自动发布 `active` 规范。
- 不做多 AI 工具规则自动导出。
- 不做向量库或复杂检索系统。
- 不要求第一阶段把所有规则接入静态扫描或 CI。
- 不把行业规范写成脱离团队代码实践的行业白皮书。
- 不要求第一阶段指定具体 APP、前端、后端项目路径；具体项目由端负责人在执行阶段提供。

---

## Key Decisions

- 主路径选择“萃取规范”：因为当前最大痛点是端负责人靠人工写规范，第一阶段应优先让 Skill 生产准确规范草稿。
- 采用直接写入正式规范目录且状态为 `draft`：因为用户希望输出直接进入规范体系，人工审核后再升级为 `active`。
- `draft` 默认可被 AI 使用：因为第一阶段需要让规范草稿尽快参与 AI 开发和 Review，但高风险 draft 规则必须提示未审核状态。
- 采用独立 evidence：因为规范正文必须保持团队级抽象，代码路径证据只用于萃取、审核和追溯。
- 采用统一主结构 + 端内扩展：因为 APP、前端、后端需要统一使用方式，同时保留各自技术栈差异。
- 生成独立行业规范：因为行业共性会影响高风险模块、合规、日志、权限、状态一致性和术语，但行业规则必须结合团队代码特性。
- 对外只保留一个 Skill：因为用户只需要启动一次规范萃取流程，APP / 前端 / 后端 / 行业 / 评审拆分应该由 Skill 内部编排。
- 采用混合 agent 模型：因为通用阶段 Agent 能保证流程一致性，领域专项 Agent 能保证萃取质量和端内专业性，分面评审 Agent 能保证证据、团队级抽象、AI 可执行性和 Review 可检查性。
- 采用分阶段并行：因为前置事实必须统一，端规范、行业规范和分面评审可以并行提升效率，最后需要统一质量门禁。
- 重复运行不覆盖已有规范：因为规范是团队资产，Skill 新一轮推断不能直接替代已存在规则。

---

## Dependencies / Assumptions

- 执行阶段需要端负责人提供真实项目路径和必要权限。
- 执行阶段需要能读取真实项目代码、已有文档、Review 问题或 AI 出错案例中的至少一部分证据。
- 不同项目中的敏感文件、密钥、证书、生产配置等不得被采集为规范证据正文。
- 端负责人负责确认 `draft -> active`，并对最终规则的团队适用性负责。
- 行业共性可以作为关注点和框架，但不得替代团队代码证据或负责人确认。

---

## Outstanding Questions

### Resolve Before Planning

- 无。

### Deferred to Planning

- [Affects R12-R14][Technical] 每个 Agent 在当前宿主环境中以 skill、subagent、prompt 文件还是其他机制落地。
- [Affects R17-R22][Technical] 现有 `engineering-standards/01-app-client/` 文件结构是否需要迁移到统一主结构 + 端内扩展，还是保留现状并建立映射规则。
- [Affects R24][Technical] evidence 采用单文件、按规则分文件，还是按领域分目录组织。
- [Affects R32][Technical] AI 使用 draft 时的未审核提示如何进入实际 AI 开发输入模板。
- [Affects R41-R46][Technical] 质量门禁采用 agent 分面复核、人工 checklist，还是后续脚本校验。
