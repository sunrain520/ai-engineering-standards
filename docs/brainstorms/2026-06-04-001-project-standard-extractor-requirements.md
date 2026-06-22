---
date: 2026-06-04
topic: project-standard-extractor
spec_id: 2026-06-04-001-project-standard-extractor
---

# project-standard-extractor 实现收敛(Phase 0 骨架 + Java 单端闭环)

## Summary

构建一个 domain-scoped 的研发规范萃取 skill:本轮一次性落地完整共享骨架(薄 SKILL 入口、8 个 agent、7 道质量门禁、9 个版本化数据合同、domain-router、merge-coordinator),并用真实的 9627 KAZ Java 中台项目跑通 `backend/java-spring` 单端闭环,产出带 evidence、过 ajv 校验、派生纪律可信的规范产物到 `engineering-standards/04-backend/`。

---

## Problem Frame

部门有 1000+ 工程,各端长期实践沉淀了大量隐性开发规范,但这些规范散落在代码与 PR Review 里,没有被显式化成「AI 可执行、Reviewer 可检查、Owner 可裁定、Evidence 可追溯」的契约。现有做法要么靠人写通用最佳实践(空泛、与真实代码脱节),要么靠 LLM 直接读代码生成规范(会伪造 evidence、把单仓局部习惯当部门规范、把高风险规则自动激活)。

设计基线(`docs/技术方案/README.md`)已把产品形态、9 合同、7 gate、规则生命周期、运行模型全部锁定。当前缺的不是「想清楚做什么」,而是把这份基线从设计稿收敛为可被 `/spec:plan` 直接执行的结构化需求,并用一个真实项目证明整条链路成立——否则后续前端/APP/Owner 治理接入时会因契约漂移反复返工(这正是已舍弃的旧分支的失败模式)。

---

## Actors

- A1. 抽取运行者(工程师):提供单端 `extraction_target` 与 `project_paths`,运行 skill,消费产出的规范产物。
- A2. 规则负责人(Owner):对 pending / conflict / 高风险规则做裁定,决定规则能否升级到 active 或部门级。本轮不实现交互式裁定流程,但产物必须为其留出 `owner-decision-queue` 决策入口。
- A3. 下游 AI 消费方(spec-first / AI Coding / Review):读 `ai-rules-*.md` 写代码、读 `review-checklist-*.md` 做检查。本轮只保证产物格式可被消费,不实现接入。
- A4. skill 内部 agent 链(intake → profiler → fact-collector → pattern-miner → rule-synthesizer → quality-gate → publisher → owner-review):每个 agent 的输入输出受对应数据合同约束。

---

## Key Flows

- F1. 单端规范萃取主链路
  - **Trigger:** A1 以单一 `extraction_target{domain, sub_domain}` + `project_paths` 运行 skill
  - **Actors:** A1, A4
  - **Steps:**
    1. intake 校验输入、识别敏感文件、对源码目录算指纹生成 `snapshot_id` 与 `run_id`
    2. domain-router 据 `extraction_target` 选定该端的 collectors / miners / template / 输出目录 / 风险策略
    3. profiler 扫描结构、识别技术栈、校验 domain 匹配、拆 batch plan
    4. fact-collector 按 batch 用脚本抽锚点级确定性事实,绑定 evidence 锚点
    5. pattern-miner 把事实聚成候选模式(含反模式、冲突)
    6. rule-synthesizer(LLM)把模式归纳成规范候选,绑定 evidence
    7. quality-gate 跑 7 道门禁,产出每条规则的 decision 与 next_action
    8. merge-coordinator 以 append-only 合并到端目录,校验跨端硬边界
  - **Outcome:** `engineering-standards/{domain}/` 下产出 standard / ai-rules / review-checklist / rules-index / lineage / pending / conflicts / owner-queue / evidence,且 `.runs/{run_id}/` 留存全部中间产物
  - **Covered by:** R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11

- F2. 质量门禁拦截链路
  - **Trigger:** 一条规范候选进入 quality-gate
  - **Actors:** A4
  - **Steps:** 依次过 Evidence / Actionability / Abstraction / Conflict / Risk / Derivation / GIT-001 七道门禁;任一门禁判定降级或阻断时,规则不得进入 active 路径,转入 pending 或 conflict 或 owner-queue
  - **Outcome:** 只有满足 auto-active 硬门槛的规则进入 active;其余如实降级并记录原因
  - **Covered by:** R5, R6, R7, R12

---

## Requirements

**运行模型与输入(domain-scoped)**
- R1. 每次运行必须绑定唯一一个 `extraction_target{domain, sub_domain}`;输入若含多个端,必须拒绝混合运行并提示拆分为多个 run。
- R2. `run_id` 采用 `{yyyyMMdd-HHmmss}-{domain}-{sub_domain}-{short_input_hash}` 格式;所有中间产物落 `.runs/{run_id}/`,正式产物落 `engineering-standards/{domain}/`,两者物理分离。
- R3. 每个 run 必须生成 `manifest.json`,记录 run_id、domain/sub_domain、输入指纹、源项目锚点信息、输出目录、运行状态(running/completed/failed/aborted)。

**确定性事实与证据锚定**
- R4. fact-collector 必须以脚本(rg + 文件扫描)抽取锚点级确定性事实,每条事实绑定可追溯的 evidence 锚点(文件 + 行号 + 片段哈希);本轮不依赖 AST / 调用图。
- R5. 源码可追溯性分级:Git 项目用 commit 强锚定;非 Git 项目用 `snapshot_id + path_hash + file + line + snippet_hash` 中等锚定,缺 Git 不得阻断抽取;无法读取源码则不生成规则。

**质量门禁(7 道)**
- R6. 必须实现 7 道门禁(Evidence / Actionability / Abstraction / Conflict / Risk / Derivation / GIT-001),并产出每条规则的门禁结果与 next_action。
- R7. Evidence / Derivation / GIT-001 三道门禁必须由可执行校验(ajv schema 不变量 + 结构检查)硬判定;Abstraction / Actionability 由 LLM 语义判定;Conflict 由结构检查 + LLM 协同。
- R12. auto-active 硬门槛为「确定性出现次数 ≥ 2 且高置信且无冲突且低/中风险」;不满足任一条件即降级为 draft / pending / conflict;交易/资金/权限/安全/合规等高风险域必须 Owner 确认,不得自动 active。

**规范产物与派生纪律**
- R8. 正式产物文件统一带 `sub_domain` 后缀(standard / ai-rules / review-checklist / evidence 子目录),避免同 domain 下多 sub_domain 互相覆盖。
- R9. `ai-rules-*.md` 与 `review-checklist-*.md` 只能从已接受的 standard 规则派生,不得新增 standard 中不存在的规则或未过门禁的检查项。
- R10. 每条规则必须可追溯:`rules-index` + `lineage-ledger` 记录其来源 run、来源事实、来源项目与状态变更历史;待裁定项进入 `owner-decision-queue`。

**骨架完整性与边界**
- R11. 本轮必须一次性落地完整共享骨架:薄 SKILL 入口、8 个 agent、domain-router、merge-coordinator、9 个版本化数据合同(ajv 可校验)、7 道门禁、scripts、backend 模板;`tools/adapters/{codewiki,codegraph,pr-review}/` 仅留 README 占位。
- R13. merge-coordinator 必须以 append-only 写入,且校验跨端硬边界——当前端运行只允许写入自己的 `engineering-standards/{domain}/` 目录,不得污染其他端目录。

---

## Acceptance Examples

- AE1. **Covers R1.** Given 输入 `project_paths` 同时包含 Java 服务与前端工程,when 运行 skill,then 拒绝混合抽取并提示按端拆分为多个 run。
- AE2. **Covers R5, R7, GIT-001.** Given 目标项目不是 Git 仓库,when 抽取事实,then evidence 以 `snapshot_id + path_hash + file + line + snippet_hash` 锚定、抽取不被阻断,且该项目生成的规则默认最高只到 draft / this-repo auto-active。
- AE3. **Covers R9.** Given 一条规则候选只有 advisory 来源(无源码 evidence),when 过 Derivation/Evidence 门禁,then 该规则不得出现在 `ai-rules-*.md` 中。
- AE4. **Covers R6, R12.** Given 同一模式既有正例又有反例,when 过 Conflict 门禁,then 写入 conflicts、不得 auto-active,并生成 owner-decision-queue 决策项。
- AE5. **Covers R13.** Given 当前 run 的 domain 为 backend,when merge-coordinator 写产物,then 仅写入 `engineering-standards/04-backend/`,任何写其他端目录的尝试被阻断。
- AE6. **Covers R2, R3.** Given 一次成功的 backend/java-spring 运行,when 运行结束,then `.runs/{run_id}/` 下存在 manifest 与全部中间产物且 status=completed,正式产物落 `engineering-standards/04-backend/`。

---

## Success Criteria

- 从真实的 9627 KAZ Java 中台项目跑出至少一份 evidence-backed 的 `standard-java-spring.md`,其规则可追溯到具体文件与行号。
- 整条链路的 9 个数据合同与 7 道门禁不变量均有可执行校验且全部通过(ajv 全绿)。
- 至少触发一条真实的 conflict 或 pending-confirmation,证明门禁确实在拦截而非全部放行。
- `ai-rules-java-spring.md` 不含任何无 evidence 规则;`review-checklist-java-spring.md` 的每一项都能回溯到 standard 中的规则。
- 产出仅落 `engineering-standards/04-backend/`,无跨端目录污染。
- `/spec:plan` 接手时无需发明产品行为、范围边界或验收标准;仅需细化合同字段、门禁判定算法、rg 规则集等实现细节。

---

## Scope Boundaries

- 前端 / APP 等其他端 collector 的**实现**:骨架与 domain-router 必须支持它们,但本轮只实现 Java collector;其余端的 `domains/` 配置可留空壳或最小占位。
- `tools/adapters/{codewiki,codegraph,pr-review}/` 的**实现**:仅留 README 占位,声明定位与接入契约,本轮不接入任何外部工具。
- AST / tree-sitter / 调用图 / LSP / CodeGraph:本轮全部不引入,事实抽取止于锚点级。
- 规则的团队级 / 部门级升级流程、交互式 Owner 裁定 UI:本轮只产出 owner-decision-queue 数据,不实现裁定交互。
- 跨端公共规范二次提炼(`00-global/`):需各端规范先就绪,本轮不做。
- 向量库、图数据库、Web 平台、多 Agent 编排框架、CI 全量扫描:全部排除(属平台建设,非本 skill 范围)。
- 本分支的 CHANGELOG / CLAUDE.md 治理:旧分支产物已随「从 0 开始」舍弃,本轮不重建,除非另行决定。

---

## Key Decisions

- 完整骨架一步到位(而非 Java 最小集):前期投入大,但避免后续前端/APP/Owner 治理接入时返工。来源:用户确认。
- 运行严格单端 + 骨架支持三端:`run_id` 内嵌单一 domain/sub_domain,与单端抽取方案 7 原则一致。来源:用户确认(修正了早期「三端一起跑」的设想)。
- 混合实现形态:脚本抽确定性事实 / LLM 归纳规则 / ajv 硬校验三道结构门禁 / LLM 软判定两道语义门禁。来源:用户确认。这把「LLM 不立法」红线落为可执行校验,代价是门禁分两类维护。
- Git 降级为可选 + evidence 三级锚定:适配非 Git 的真实企业代码形态(多仓聚合、交付包、压缩包解压),不违反「不改业务代码」。来源:用户确认。
- 产物统一带 sub_domain 后缀:解决同 domain 下多 sub_domain 文件互盖。来源:用户确认。
- 中间产物集中 `.runs/{run_id}/`:run 产物与正式产物物理分离,可整体 gitignore。来源:用户确认。

---

## Dependencies / Assumptions

- 运行时:Node.js 单语言 + Git + ripgrep,Node 依赖 `ajv / ajv-formats / fast-glob / gray-matter / yaml`。本轮不引入 Python。
- 验证项目:`/Users/kuang/ops/code/9627_KAZ展业项目-MVP版本-CRM需求_中台开发`(已核实:Maven 多模块、非 Git、3683 个 Java 文件、Spring 注解锚点充足——`@RestController`×46 / `@Service`×285 / `@Repository`×37 / `@Mapper`×109 / `@Transactional`×105 / `@RestControllerAdvice`×2)。该路径为本机绝对路径,仅作运行输入,不写入任何源产物。
- 设计基线 `docs/技术方案/README.md` 为权威输入;三份原始方案为其支撑文档。
- 假设(待 plan 验证):Java 闭环至少能触发一条真实 conflict 或 pending——若该真实项目恰好高度一致而无冲突,需在 evals 中补一个含反例的 golden sample 来证明门禁生效。

---

## Outstanding Questions

### Resolve Before Planning

- (无)产品级决策已全部锁定。

### Deferred to Planning

- [Affects R6, R7][Technical] 7 道门禁各自的判定算法与阈值(尤其 Abstraction/Actionability 的 LLM 判定 prompt 与 Conflict 的结构检查规则)如何实现。
- [Affects R4][Technical] Java collector 的完整 rg 规则集与锚点 → 事实的映射规则(哪些注解/命名组合产出哪类 fact、main/test scope 如何区分)。
- [Affects R3, R10][Technical] 9 个数据合同的字段级 JSON Schema 定义与版本演进策略。
- [Affects R11][Technical] 8 个 agent 各自的 Markdown 指令边界与彼此交接的契约校验点。
- [Affects R5][Needs research] `snapshot_id` 内容指纹的具体算法(全量内容哈希 vs 增量/抽样),在 3683 文件规模下的性能取舍。
