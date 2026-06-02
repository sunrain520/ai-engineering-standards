# Generation Contract

## 角色目标

基于 `code_facts` + `classification` 生成**开发者可直接使用的团队规范指南**，以及派生的 AI Coding Rules、Review Checklist 和候选索引产物。

核心转变：**不是填写规则条目表格，而是综合编写开发指南**。产出文档必须像有经验的架构师写的工作手册，开发者打开就能看懂、能用。工序仍然严格：evidence 先行 → 选 skeleton 综合编写 standard → 派生 ai-rules / review-checklist → 索引聚合。

本 agent 支持两条输入剖面：

- **Phase 1 selected-batch**：稳定公开路径。消费单个 batch 的 `code_facts` / `classification` / `selected_batch_summary`，不要求 `activation-report`。
- **Phase 2 dimension-aware**：repair-only 路径。额外消费 `activation-report.v1`，按维度激活态选择 skeleton 和章节标注。

> 上游：`facts-and-classification`（Phase 1 / Phase 2 共用）；`dimension-activator`（仅 Phase 2 dimension-aware）。下游：`review-and-quality-gate`。

## 输入

```yaml
inputs:
  code_facts:             # facts-and-classification 的全量输出（Phase1 每条 fact 只含 batch/evidence 边界;Phase2 可含 dimension_id）
  classification:         # recommended / forbidden / legacy_compatible / pending_confirmation / conflict / rejected
  activation_report:      # 可选；仅 Phase 2 dimension-aware 必填
                          # temp/{run_id}-activation-report.json (schema=activation-report.v1)
                          # 来自 dimension-activator,是 Phase 2 唯一权威激活态来源
  selected_batch_summary: # batch_id / domain / sub_domain / evidence_limit / confidence_tier
  project_profile:        # temp/{run_id}-project-profile.md（用于理解架构背景）
  global_templates:       # assets/ 目录（standard-template.md 主参考）
  skeletons_pool:         # assets/skeletons/ 目录（按 activation_report.dimensions[].skeleton_section 选用）
  baseline_dimensions:    # references/config/dimension-framework/baseline-dimensions.yaml（baseline 默认填充内容来源）
  frontmatter_format:     # references/config/frontmatter-format.md
  output_targets:         # references/config/output-targets.md
  existing_standards:     # 若 standard-{sub_domain}.md 已存在，列出已有章节标题列表
```

## 输入剖面判定

| 剖面 | 必填输入 | 生成策略 |
| --- | --- | --- |
| `phase1-selected-batch` | `selected_batch_summary.batch_id` + `code_facts` + `classification` | 使用 `standard-template.md` 和可匹配的 sub-domain skeleton 写 evidence-backed draft；不读取 `activation-report`，不生成维度未激活地图。`confidence_tier: low` 时只生成 pending draft，不进入 AI 默认执行。 |
| `phase2-dimension-aware` | `activation_report.schema == "activation-report.v1"` | 按 `activation_report.dimensions[]` 消费 baseline / activated / pending / shallow / candidate 状态。 |

剖面选择规则：

1. 存在合法 `activation_report` → `phase2-dimension-aware`。
2. 不存在 `activation_report`，但存在 `selected_batch_summary.batch_id` → `phase1-selected-batch`。
3. 两者都不存在 → 抛 `GENERATION_INPUT_PROFILE_MISSING`，停止。

## Phase 2 维度激活态消费契约

仅在 `phase2-dimension-aware` 剖面中，本阶段对 `activation_report.dimensions[]` 的每个维度按 `state` 决定生成策略：

| state | 章节标注 `[{{activation_state_section_N}}]` | 章节正文来源 | 写入位置 |
| --- | --- | --- | --- |
| `baseline` | `baseline` | 从 `baseline-dimensions.yaml` 取 default 内容直接渲染（不依赖 code_facts） | standard-{sub_domain}.md |
| `activated` | `activated` | 综合 code_facts + classification.recommended/forbidden/legacy_compatible 编写实质内容 | standard-{sub_domain}.md |
| `pending-confirmation` | `pending` | 占位章节 + 触达原因 + warning + 跳到 pending-confirmation.md 的指针 | standard-{sub_domain}.md（占位）+ pending-confirmation.md（详情） |
| `shallow` | `shallow` | 与 activated 相同生成,但额外加 `> ⚠️ 本节 coverage=low,等待 review 改判` warning | standard-{sub_domain}.md |
| `candidate` | （不出现在端规范） | 仅落入 overview-skeleton 的「未激活维度地图」段（AE7） | `overview.md` 的 §9 未激活维度地图 |

**铁律**:Phase 2 中本阶段**不重新判定** state,只消费 `activation-report.json`。任何与 activation-report 不一致的章节标注视为 schema violation。

## 输出（完整产物清单）

| 产物 | doc_type | indexable | 生成时机 |
| --- | --- | --- | --- |
| `evidence/code-facts.md` | evidence-code-facts | true | Sub-step A |
| `evidence/positive-examples.md` | evidence-positive | true | Sub-step A |
| `evidence/forbidden-examples.md` | evidence-forbidden | true | Sub-step A |
| `evidence/legacy-compatible.md` | evidence-legacy | true | Sub-step A |
| `standard-{sub_domain}.md` | standard | true | Sub-step B（每 sub_domain 一份 Developer Guide） |
| `pending-confirmation.md` | pending-confirmation | true | Sub-step B |
| `ai-rules.md` | ai-rules | true | Sub-step C |
| `review-checklist.md` | review-checklist | true | Sub-step C |
| `temp/{run_id}-rules-index-candidate.json` | — | — | Sub-step D |
| `temp/{run_id}-llms-candidate.txt` | — | — | Sub-step D |
| `temp/{run_id}-ai-context-pack.md` | ai-context-pack | false | Sub-step D |

## 生成管线（严格工序）

```
Sub-step A0: Input Profile Loader（前置）
  ├── Phase 1 selected-batch: 校验 selected_batch_summary + code_facts + confidence_tier,建立 batch 写作上下文
  └── Phase 2 dimension-aware: 校验 activation-report.json schema=activation-report.v1
      └── 计算每个维度的 skeleton 选型 + 章节标注映射

Sub-step A: Evidence Writer
  └── 写 evidence/*，固定 EV/POS/NEG/LEG 编号
  └── Phase 1: 仅来自 selected batch 的 fact 进入 evidence
  └── Phase 2: 仅来自 activated / shallow / pending-confirmation 维度的 fact 进入 evidence
  └── 完成标志: code_facts 全部编号完毕

Sub-step B: Developer Guide Author（核心）
  ├── Phase 1: 从 selected batch 的 evidence/classification 综合编写 standard-{sub_domain}.md
  └── Phase 2:
      └── 按 activation_report.dimensions[].skeleton_section 选定 skeleton 文件
      └── 替换 {{activation_state}} 与 {{activation_state_section_N}} 占位符
      └── baseline 维度 → 直接从 baseline-dimensions.yaml default 内容填充
      └── activated / shallow 维度 → 综合 code_facts + classification 实质编写
      └── pending-confirmation 维度 → 占位章节 + warning + pending-confirmation.md 指针
      └── candidate 维度 → 仅在 overview-skeleton 的「未激活维度地图」段输出

Sub-step C: Derivative Generator（可并行）
  ├── ai-rules.md    ← 从 standard-{sub_domain}.md §"AI 生成规则" 汇总段提取
  │                    （pending / candidate 维度不进入 ai-rules,但可在 §3 警告中提及）
  └── review-checklist.md ← 从 standard-{sub_domain}.md §"Code Review 检查项" 汇总段提取
  └── 完成标志: 每条条目引用了来源章节;shallow 维度条目附 `coverage=low` 标注

Sub-step D: Index & Pack Aggregator（B + C 完成后）
  ├── rules-index-candidate.json  ← 按规则索引 standard 内容(Phase 1 不含 activation 字段;Phase 2 可附 dimension_id/dimension_state)
  ├── llms-candidate.txt          ← 领域入口地图
  └── ai-context-pack.md          ← 摘要包(含三态分布统计)
```

**工序约束**：Sub-step A0 不通过整个管线停止；Sub-step B 不得在 evidence 编号未锁定前开始；Sub-step D 不得在 B + C 完成前执行。

---

## 执行步骤

### Sub-step A0 — Input Profile Loader（前置门禁）

**A0.0 输入剖面判定**

1. 若提供 `activation_report`，进入 `phase2-dimension-aware`，执行 A0.1-A0.5。
2. 若未提供 `activation_report` 但存在 `selected_batch_summary.batch_id`，进入 `phase1-selected-batch`，执行 A0-P1。
3. 若两类输入都不存在，抛 `GENERATION_INPUT_PROFILE_MISSING`，停止。

**A0-P1 Phase 1 selected-batch 校验**

1. 校验 `selected_batch_summary.batch_id`、`domain`、`sub_domain` 非空；缺失抛 `SELECTED_BATCH_CONTEXT_INVALID`。
2. 校验 `code_facts` 已限定在该 batch 的 `candidate_files` 内；发现跨 batch fact 抛 `BATCH_BOUNDARY_LEAK`。
3. `code_facts` 为空时不生成 `standard-{sub_domain}.md`；只写 `pending-confirmation.md` 与 review summary，失败模式为 `NO_REPRESENTATIVE_EVIDENCE`。
4. `selected_batch_summary.confidence_tier == low` 时，所有生成规则默认标 `target_state: pending-confirmation`、`confidence_tier: low`，只作为 low-confidence draft 输入后续 review/owner queue。
5. 使用 `assets/standard-template.md` 作为主结构；如果存在匹配 `assets/skeletons/{domain}/{sub_domain}-skeleton.md`，只作为章节提示，不引入 activation-state 占位符。
6. 建立 `generation_profile: phase1-selected-batch`，后续 self-check 跳过 Phase 2 activation-state 检查。

**A0.1 schema 校验**

以下规则仅适用于 `phase2-dimension-aware`：

1. 读取 `temp/{run_id}-activation-report.json`,验证 `schema == "activation-report.v1"`;不匹配抛 `ACTIVATION_REPORT_SCHEMA_INVALID`,停止。
2. 校验 `run_id` 与当前 run 一致;不匹配抛 `ACTIVATION_REPORT_RUN_MISMATCH`,停止。
3. 校验 `dimensions[]` 非空;空集抛 `EMPTY_ACTIVATION_REPORT`,停止。
4. 若 `dimensions[]` 全部为 `candidate`，且没有 baseline / activated / pending-confirmation / shallow 维度可生成，抛 `NO_DIMENSION_CAN_GENERATE`,停止。

**A0.2 维度分组**

按 `state` 计算 5 组维度:

```yaml
dimension_groups:
  baseline_dims:    []   # state == baseline,从 baseline-dimensions.yaml 直出
  activated_dims:   []   # state == activated,完整生成
  pending_dims:     []   # state == pending-confirmation,占位生成
  shallow_dims:     []   # state == shallow,完整生成 + low-coverage warning
  candidate_dims:   []   # state == candidate,只进入 overview 未激活地图
```

**A0.3 skeleton 选型映射**

对每个非 candidate 维度,取 `dimensions[].skeleton_section` 字段:

| 维度归属 | skeleton 文件 | 落点 |
| --- | --- | --- |
| 端级 overview | `assets/skeletons/overview-skeleton.md` | `overview.md`(端级聚合) |
| sub-domain 强标识 | `assets/skeletons/{domain}/{sub_domain}-skeleton.md` | `standard-{sub_domain}.md` |
| 横切(命名 / 错误模型) | `assets/skeletons/cross-cutting-skeleton.md` | `standard-common.md` 对应章节 |
| industry sub | `assets/skeletons/industry/{name}-skeleton.md` | `standard-{industry_sub}.md` |

skeleton_section 为 null 但维度状态非 candidate / 非 baseline → 抛 `MISSING_SKELETON_FOR_ACTIVE_DIM`,停止。

**A0.4 章节标注映射表生成**

为每个目标 skeleton 生成 `placeholder_replacement_map`:

```yaml
placeholder_replacement_map:
  - skeleton_path: "assets/skeletons/app-client/kmp-shared-skeleton.md"
    target_doc: "standard-kmp-shared.md"
    section_state_map:           # 章节级激活态(对应 [{{activation_state_section_N}}])
      "1": "activated"           # 章节序号 → 标签
      "2": "activated"
      "3": "pending"
      "4": "baseline"
      ...
    document_state: "activated"  # 整文档态(对应 {{activation_state}}),取 max(各章节态)
```

`section_state_map` 字段值规则:
- `baseline` / `activated` / `pending` / `shallow`(对应 4 种 state,`pending-confirmation` 简写为 `pending`)
- `candidate` 不进入端规范文档,只进入 overview 未激活地图,**不出现在 section_state_map**

**A0.5 验证**

- [ ] 所有 baseline_dims 都能在 `baseline-dimensions.yaml` 找到 default 内容
- [ ] 所有 activated_dims / shallow_dims 都至少有 1 个 code_fact 引用
- [ ] 所有 pending_dims 都至少有 1 条占位事实(evidence_kind=unknown)
- [ ] placeholder_replacement_map 覆盖所有目标 skeleton 的所有章节(章节遗漏 → `INCOMPLETE_SECTION_STATE_MAP`)

任一失败,停止管线,不进 Sub-step A。

---

### Sub-step A — Evidence Writer（不变）

**A1.** 对每个 evidence 文件写入 YAML Front Matter（`doc_id`、`domain`、`sub_domain`、`doc_type`、`indexable: true`、`tags`）。

**A2.** 编号分配：

```
EV-{DOMAIN}-{N}   → evidence/code-facts.md
POS-{DOMAIN}-{N}  → evidence/positive-examples.md
NEG-{DOMAIN}-{N}  → evidence/forbidden-examples.md
LEG-{DOMAIN}-{N}  → evidence/legacy-compatible.md
```

`{N}` 单调递增，不复用。若文件已存在条目，从最大 N+1 追加。

**A3.** 写入原则：

- code-facts：每条 fact（`observed_pattern`、`boundary`、`confidence`、`file_role`）
- positive-examples：正向 evidence，附路径模式（不写绝对路径）和解释
- forbidden-examples：反向 evidence，附反例模式和风险说明
- legacy-compatible：历史兼容 evidence，附兼容边界说明

---

### Sub-step B — Developer Guide Author（核心，全面重写）

**B-1. Skeleton 加载与占位符替换前置**（在 B0 综合理解之前先完成）

按 A0.4 的 `placeholder_replacement_map` 处理每个目标文档:

1. 读取 `skeleton_path` 文件原文,作为目标文档骨架。
2. 占位符替换契约:
   - `{{activation_state}}` → `document_state`(取 `placeholder_replacement_map.document_state`)
   - `{{activation_state_section_N}}` → `section_state_map["N"]`
   - 章节序号缺失或与 skeleton 实际序号不匹配 → `INCOMPLETE_SECTION_STATE_MAP`,停止
3. **占位符替换必须 100% 覆盖**:替换后用 grep 验证目标文档不再存在任何 `{{activation_state` 字面量;残留 → `PLACEHOLDER_LEAK`,停止
4. Front Matter 中的 `activation_state: "{{activation_state}}"` 替换为 `activation_state: "{document_state}"`
5. 章节生成策略由 `section_state_map[N]` 决定(下方 B1 ~ B4 按状态分支)

**B0. 编写前：综合理解阶段（全领域通用）**

不要立刻开始写规则条目。先用内部推导回答以下 3 个问题：

1. **这个 sub_domain 的核心架构是什么？** 有哪些层级、角色、关键模式？（从 code_facts 的 `file_role` 和 `observed_pattern` 推断；同时查阅 `references/config/domain-sampling-adapters.md` 里对应 domain 的信号集和代表性候选描述）
2. **代码事实揭示了哪些真实规律？** 哪些是团队共同遵循的正向模式？哪些是被避开的反模式？
3. **开发者最需要知道什么？** 如果一个新同事第一天接手这个 sub_domain，哪些知识最关键？

**各领域架构推导参考**（从 code_facts file_role 对应关系推断分层）：

| domain | sub_domain 典型 | 推断分层关键词 | 代码示例语言 |
| --- | --- | --- | --- |
| app-client | android | `fragment`, `viewmodel`, `usecase`, `repository`, `dto` | Kotlin |
| app-client | ios | `viewcontroller`, `reactor`, `action`, `mutation`, `state` | Swift |
| app-client | kmp-shared | `usecase`, `repository`, `presenter`, `mapper`, `domain-model` | Kotlin |
| frontend | react/vue/next | `page`, `component`, `store`, `api-client`, `hook`, `type` | TypeScript |
| backend | java-spring | `controller`, `service`, `repository`, `mapper`, `dto` | Java/Kotlin |
| backend | golang | `handler`, `service`, `repository`, `model`, `middleware` | Go |
| backend | python | `view/router`, `service`, `repository`, `schema`, `model` | Python |
| pc-client | electron | `main-process`, `ipc-handler`, `renderer`, `preload` | TypeScript |
| testing | unit/integration | `test-class`, `mock`, `fixture`, `assert` | 随 domain |
| security | — | `validator`, `auth-middleware`, `permission`, `audit-log` | 随 domain |
| industry | — | `workflow`, `risk-check`, `state-transition`, `compliance` | 随 domain |

只有回答清楚这 3 个问题后，才开始写文档。

**B1. 文档路由**

`batch.sub_domain` → 写入 `standard-{sub_domain}.md`。跨 sub_domain 共性内容 → `standard-common.md`（`sub_domain: common`）。文件不存在时新建并写入 Front Matter：

```yaml
doc_id: "{domain}-{sub_domain}-standard"
doc_type: standard
status: draft    # 文档级状态固定 draft;规则级 auto-active 只写在规则 inline 元数据行
evidence_tier: "{从 code_facts 中最高的 tier}"
source_batch: "{batch_id}"
```

**B2. 文档结构（按 standard-template.md）**

按以下章节顺序综合编写，每节都必须有实质内容（不留空节）：

**§1 技术栈与工程约束**

- 从 build 脚本 evidence（EV-* 中 file_role=gradle-module-config 等）和 import 语句提取
- 列出框架、库、工具名称 + 一行说明用途
- 只写团队真实在用的，不写"推荐"的行业通用方案

**§2 分层职责**

- 从 code_facts 的 `file_role` 分布（controller、viewmodel、usecase、repository 等）推断层级
- 画 ASCII 依赖关系图（上层 → 下层）
- 写责任矩阵表格（层级 | 核心职责 | 禁止事项）

**§3—§N 各层级/角色规范**（数量由 evidence 决定，每层一节）

每个**规则节**（H3 子节，标题以 `P0|P1|P2|FORBIDDEN ` 前缀开头）按以下结构写：

1. **inline 元数据行**（紧跟 H3，blockquote 单行，` · ` 分隔）：

   ```markdown
   > level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: {YYYY-MM-DD} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null
   ```

   字段全集与顺序：`level`、`status`、`source_kind`、`evidence_tier`、`risk_tag`、`owner`、`last_reviewed`、`recommended_action`、`confidence_tier`、`authority_scope`、`upgrade_mode`、`deterministic_occurrence_count`、`last_evidence_confirmed_run`、`conflicts_with`（仅非空时追加）、`superseded_by`（仅非空时追加）。

   `status` 自动运行默认 `draft`；只有通过 BR-016/BR-017 高置信自动升级闸时可写 `auto-active`。不得输出 `owner-confirmed-active` 或 legacy `active`。**禁止**整块 yaml。

2. **说明**（粗体标题 + bullet）：讲清这条规则的 why——背后原理/动机/要防止的具体问题（对齐阿里《Java开发手册》「说明:」）。基于 evidence 观察，不空泛。让读者和 AI 不只知道做什么，还知道为什么。
3. **适用范围**（粗体标题 + bullet）
4. **强制规则**（numbered list）：对应 classification.recommended，confidence: high + occurrences ≥ 2
5. **推荐规则**（numbered list）：confidence: medium 或 occurrences = 1 的正向 evidence
6. **禁止事项**（bullet list）：对应 classification.forbidden；FORBIDDEN 条目用 `⛔ FORBIDDEN` 标注
7. **正例**（fenced code block）：基于 POS-* evidence **泛化为通用示例**——用 `OrderService` / `UserRepository` 等通用名,去除项目特征与路径(守 BR-008),展示「模式」而非照搬项目代码;注释说明正确原因。evidence/ 仍保留带溯源的原始片段供审计。
8. **反例**（fenced code block）：基于 NEG-* evidence 泛化,注释说明错误原因和改法
9. **AI 生成代码要求**（粗体标题 + numbered list，正向约束句式）
10. **Code Review 检查项**（粗体标题 + 复选框 bullet，可二值判断）
11. **Evidence**（粗体标题 + bullet，引用 `evidence/{kind}.md「{条目编号}」`）

**FORBIDDEN 标注格式**（内联在元数据行下方或禁止事项节内）：

```markdown
> ⛔ **FORBIDDEN**：{具体禁止写法，一句话}。负例见 `evidence/forbidden-examples.md「NEG-{DOMAIN}-{N}」`
```

**§"目录与命名规范"**（如果 evidence 中有命名模式，写此节；否则删除）

**§"AI 生成规则"汇总**

> 本节是各规则节 `AI 生成代码要求` 的派生视图，不新创内容；只摘要、不重写。

综合所有规则节的 AI 要求，分三段：
1. 生成前必须判断（列出 sub_domain 特有的判断点）
2. 必须遵守（正向约束摘要，对应§3-N 强制规则）
3. 禁止生成（负向约束摘要，对应§3-N 禁止事项）

**§"Code Review 检查项"汇总**

> 本节是各规则节 `Code Review 检查项` 的派生视图，不新创内容。

按维度分组（架构合规 / 各层级合规 / AI 生成专项），每条必须可 pass/fail 判断。reviewer 看代码就能得出结论。

**§"Evidence 参考"**（文档末尾）

简化表格，列出本文档主要规则依据的 evidence 编号：

```markdown
| evidence_id | 来源文件（路径模式） | 核心观察 | 置信度 |
| --- | --- | --- | --- |
```

**B3. 写作质量标准**

| 质量维度 | 要求 |
| --- | --- |
| 可读性 | 开发者打开 3 分钟内能理解该 sub_domain 的架构 |
| 可操作性 | 每条规则说明**怎么做**，而不只是"应该" |
| 代码示例 | 至少有 1 个正例 + 1 个反例，直接来自 evidence |
| 密度 | 信息密度高，不写废话，不重复 evidence 文件内容 |
| 架构视角 | §2 分层图能让新人快速定位自己在哪里、能做什么 |

**B3.5 章节按激活态分支生成（铁律）**

按 `section_state_map[N]` 决定每个章节(R51 12 章节)的正文写法:

**(a) `baseline` 章节**

- 直接从 `references/config/dimension-framework/baseline-dimensions.yaml` 取对应维度的 default 内容(每个 baseline 维度都有预置默认描述、规则、正例片段)
- 不依赖 code_facts;即使本次萃取没产生任何 fact 也必须填充
- 章节首行加引导 blockquote: `> 本节为 baseline 默认要求,适用所有 sub_domain。`
- 不允许出现 `[TODO]` 或空段
- 章节末尾 Evidence 引用使用 `evidence/baseline-defaults` 占位 ID

**(b) `activated` 章节**

- 综合 `code_facts`(本维度对应 fact)+ `classification.recommended/forbidden/legacy_compatible`(本维度的桶)编写实质内容
- 必须满足 R51 章节子段要求(说明 / 适用范围 / 强制规则 / 推荐规则 / 禁止事项 / 正例 / 反例 / Evidence)
- 章节首行加引导 blockquote: `> 本节由本次萃取激活,基于 {N} 条 code_fact 综合生成。`
- 至少 1 条强制规则 + 1 条禁止事项;否则降级为 `pending`

**(c) `pending` 章节**

- **不写实质规则**;仅占位 + 触达原因 + 跳转指针
- 章节首行强制 blockquote 警告:

```markdown
> ⚠️ **本节激活态为 pending-confirmation**,触达 1 项信号但未达 weighted threshold(详见 `temp/{run_id}-activation-report.json` 该维度 rationale)。
> 详细占位事实见 `pending-confirmation.md` PENDING-{DOMAIN}-{N};需 owner 确认后由 review-and-quality-gate 升级为 activated 才能写入正式规则。
```

- 章节本体只保留 R51 标题与 1 句"该领域是否治理由 owner 确认"的引导,不输出强制规则、不输出 FORBIDDEN
- 派生 ai-rules.md 不收录此章节

**(d) `shallow` 章节**

- 与 `activated` 同样综合编写,但**额外**在章节首行追加 warning:

```markdown
> ⚠️ **本节 coverage=low**,depth_score 未达 `depth-indicator.yaml` 端阈值,review 阶段将强制改判 keep-draft-low-coverage。
```

- inline 元数据行 `recommended_action` 字段固定为 `keep-draft-low-coverage`
- 章节末尾追加 `evidence_tier: shallow` 标签
- 派生 ai-rules.md 收录但加 `> ⚠️ 本规则来自 shallow 维度,执行前请加倍验证` 警告

**(e) `candidate` 维度**

- **不在端规范文档中生成章节**;仅由 overview-skeleton.md §9 「未激活维度地图」段聚合输出(由本阶段下方 B5 处理)
- 派生 ai-rules.md / review-checklist.md **不收录**

**B3.6 整文档级 `{{activation_state}}` 决议**

`document_state` = max-precedence 规则:

```
activated > shallow > pending > baseline
```

- 任一章节 `activated` → 整文档 `activated`
- 否则任一章节 `shallow` → `shallow`
- 否则任一章节 `pending` → `pending`
- 全部 `baseline` → `baseline`

Front Matter `status` 字段独立于 `activation_state`:文档级 status 仍为 `draft`;规则级 `auto-active` 只写在 inline 元数据行,`owner-confirmed-active` 只能由负责人手动确认。

**B4. Pending Confirmation 落点**

以下内容不写进 `standard-{sub_domain}.md`，写进 `pending-confirmation.md`：

- classification.pending_confirmation 的所有内容
- confidence: low 的 fact
- 没有代码 evidence 的规则推断（只有 README/文档来源，无代码验证）
- 需要负责人确认的行业规则

```yaml
PENDING-{DOMAIN}-{N}:
  source_fact: EV-{DOMAIN}-{N}
  dimension_id: "{对应 activation-report.dimensions[].dimension_id}"
  dimension_state: pending-confirmation
  reason: "{low_confidence|single_project|owner_required|no_code_evidence|weighted_threshold_unmet}"
  promotion_criteria: "{明确升级所需条件}"
```

**B5. 未激活维度地图（AE7 强制章节）**

仅在 `phase2-dimension-aware` 生成端级 overview 文档(`overview.md`,从 `assets/skeletons/overview-skeleton.md`)时执行；Phase 1 full-auto 不生成本节，只在 coverage report / review summary 中记录 blind spots:

1. 从 `activation_report.dimensions[]` 过滤 `state == "candidate"` 的维度集合
2. 按 `layer`(baseline / end / industry) 分组
3. 写入 overview §9「未激活维度地图」表格:

```markdown
## 9. 未激活维度地图 [{{activation_state_section_9}}]

> 本表列出本次萃取未激活的维度;触发任一 `trigger_when` 条件后,owner 确认即可升级为正式章节。
> AE7 强制保留:即使 candidate 列表为空也保留章节标题与"无候选维度"说明。

| dimension_id | name | layer | trigger_when | suggested_owner_question |
| --- | --- | --- | --- | --- |
| EA-Client-07 | 启动性能 | end:app-client | 出现 baseline-profiler / Macrobenchmark / Startup library import | 项目当前是否有冷启动 P95 / TTFD 指标治理? |
| ... | ... | ... | ... | ... |
```

4. candidate 列表为空时保留章节标题 + 单行说明: `> 本次萃取未发现 candidate 维度。所有维度处于 baseline / activated / pending / shallow 之一。`
5. 此章节标注 `[{{activation_state_section_9}}]` 替换为 `activated`(地图本身一旦被生成即视为已激活,即使内容为空)

**铁律**:overview-skeleton.md §9 不允许被省略,即使 candidate=0;否则 R51 + AE7 校验失败。

---

### Sub-step C — Derivative Generator

**C1. ai-rules.md**

- 从 `standard-{sub_domain}.md` 的 `§"AI 生成规则"` 汇总段提取，**不新写内容**
- 结构：§1 全局约束 + §2 可执行规则（按 sub_domain 分组）+ §3 使用边界警告
- 每条规则来源引用：`standard-{sub_domain}.md §「AI 生成规则」`
- 状态为 `draft` 的文档在 §3 输出 warning：`> ⚠️ 本规则来自 draft 状态文档，领域负责人确认前请谨慎强制执行`

**C2. review-checklist.md**

- 从 `standard-{sub_domain}.md` 的 `§"Code Review 检查项"` 章节提取，**不新写内容**
- 结构：§1 必检项（含 FORBIDDEN 标注的规则）+ §2 推荐检查项 + §3 AI 生成专项
- 每条检查项来源引用：`standard-{sub_domain}.md §「Code Review 检查项」`

**C3. 派生声明**

在 `ai-rules.md` 和 `review-checklist.md` 顶部写：

```markdown
> 本文件是 `standard-{sub_domain}.md` 的派生视图，由 generation 阶段自动生成，不接受手工修改。
> 修改规则请更新 `standard-{sub_domain}.md`，然后重新运行 generation。
```

---

### Sub-step D — Index & Pack Aggregator

**D1. rules-index-candidate.json**

按 `standard-{sub_domain}.md` 的规则章节（`##/### {P0|P1|P2|FORBIDDEN} {标题}`）生成索引，每条规则一条。Phase 1 不写 activation 字段；Phase 2 若需要关联维度，可额外写 `dimension_id` / `dimension_state`，但不得替代下列 canonical 字段：

```json
{
  "index_format": "engineering-standards-rules-index-v1",
  "generated_at": "{ISO8601}",
  "batch_id": "{batch_id}",
  "candidate": true,
  "rules": [
    {
      "title": "{规则标题}",
      "domain": "{domain}",
      "sub_domain": "{sub_domain}",
      "level": "P1",
      "status": "draft|auto-active|pending-confirmation|conflict|legacy-compatible|stale-auto-active|owner-rejected|rejected",
      "source_doc": "standard-{sub_domain}.md",
      "section_title": "P1 {规则标题}",
      "evidence_doc": "evidence/code-facts.md",
      "authority_scope": "this-repo|none",
      "upgrade_mode": "auto-active|none",
      "deterministic_occurrence_count": 2,
      "last_evidence_confirmed_run": "{run_id}",
      "tags": ["{domain}", "{sub_domain}", "{task_type}"]
    }
  ]
}
```

**D2. llms-candidate.txt**

```
# Engineering Standards — {domain} — {sub_domain} — candidate
# Generated: {ISO8601}, Batch: {batch_id}, Mode: guide

## 规范文件（Developer Guide）
- standard-{sub_domain}.md  — {sub_domain} 完整开发指南（{N} 个主要章节）
- standard-common.md        — 跨 sub_domain 共性规范（如有）
- ai-rules.md               — AI 编码规则汇总视图
- review-checklist.md       — Review 检查项汇总视图

## Evidence
- evidence/code-facts.md（{N} 条事实）
- evidence/positive-examples.md
- evidence/forbidden-examples.md
- evidence/legacy-compatible.md

## 状态
- draft 文档：{N} 份
- pending-confirmation：{N} 条待处理
- 候选状态，需人工确认后合并到正式 llms.txt
```

**D3. ai-context-pack.md**

```markdown
---
doc_id: "{domain}-{run_id}-ai-context-pack"
doc_type: ai-context-pack
indexable: false
---

# AI Context Pack — {domain} — {sub_domain}

## 本次萃取摘要
Batch: {batch_id} | 模式: Developer Guide | 章节数: {N} | Evidence: {N} 条

## 维度激活态分布
- baseline: {N} 维度 (默认要求,自动写入)
- activated: {N} 维度 (本次萃取激活,完整规则)
- pending-confirmation: {N} 维度 (触达信号但未达阈值,需 owner 确认)
- shallow: {N} 维度 (深度未达,review 强制 keep-draft-low-coverage)
- candidate: {N} 维度 (未触达,落入 overview §9 未激活地图)

## 核心规范文件
- `standard-{sub_domain}.md` — {sub_domain} 完整开发指南
- `overview.md` — 端级概览(Phase 2 含 §9 未激活维度地图)

## 关键约束摘要(FORBIDDEN 和强制规则,仅 activated / shallow 维度)
{从 standard 的禁止事项 + FORBIDDEN 标注中提取,每条一行}

## AI 使用边界
{文档状态 draft 的警告;pending 维度规则在 owner 确认前禁止由 AI 强制执行;shallow 维度规则需加倍验证}

## 来源 Batch 信息
Phase 1: {batch_id, domain, sub_domain, evidence_tier, generation_profile}
Phase 2: {batch_id, domain, sub_domain, evidence_tier, generation_profile, activation_report_source: temp/{run_id}-activation-report.json}
```

---

## Self-check（全局，Sub-step B 完成后执行）

- [ ] `standard-{sub_domain}.md` 包含 §技术栈、§分层职责、≥1 个角色/层级规范节、§AI 规则、§Review 检查项、§Evidence 参考
- [ ] 每个角色/层级节有强制规则 + 禁止事项（至少各 1 条）
- [ ] 每条规则有「说明」段，讲清 why（对齐阿里「说明:」），非空泛套话
- [ ] 有至少 1 个正例代码块（基于 POS-* evidence 泛化为通用示例，无项目路径）
- [ ] 有至少 1 个反例代码块（基于 NEG-* evidence 泛化）
- [ ] FORBIDDEN 规则已用 `⛔ FORBIDDEN` 标注，并引用 NEG-* evidence
- [ ] Evidence 参考表格已填写（无空行）
- [ ] 规则 `status` 只能是 `draft` / `auto-active` / `pending-confirmation` / `conflict` / `legacy-compatible` / `stale-auto-active` / `owner-rejected` / `rejected`；自动运行不得输出 `owner-confirmed-active` 或 legacy `active`
- [ ] 规则正文没有具体项目绝对路径
- [ ] `ai-rules.md` 和 `review-checklist.md` 引用了 standard 章节
- [ ] Sub-step D 在 B+C 完成后才执行
- [ ] `rules-index-candidate.json` 中 `status: candidate`（不是 published）
- [ ] pending_confirmation 的内容写入了 `pending-confirmation.md`
- [ ] **每个规则节(P0/P1/P2/FORBIDDEN H2/H3)紧跟标题都有 inline 元数据 blockquote 单行**(`> level: ... · status: ... · ...`),**没有任何 \`\`\`yaml ... \`\`\` 整块元数据**(catalog 风格已废弃)
- [ ] **inline 元数据行字段完整**:必含 `level`、`status`、`source_kind`、`evidence_tier`、`risk_tag`、`owner`、`last_reviewed`、`recommended_action`、`confidence_tier`、`authority_scope`、`upgrade_mode`、`deterministic_occurrence_count`、`last_evidence_confirmed_run` 共 13 项;`conflicts_with`、`superseded_by` 仅在非空时追加;字段顺序与 `references/prompts/rule-generation.md` 一致

**激活态 / Skeleton / 占位符相关**(U8 新增):

- [ ] `generation_profile` 已记录为 `phase1-selected-batch` 或 `phase2-dimension-aware`
- [ ] Phase 1 selected-batch: `standard-{sub_domain}.md` 的所有可执行规则都引用本 batch 的 EV/POS/NEG/LEG evidence
- [ ] Phase 1 selected-batch: 未读取其它 batch 的 candidate_files，未生成 activation-state 字段或未激活维度地图
- [ ] Phase 2 dimension-aware: Sub-step A0 通过(activation-report schema=v1 + run_id 一致 + dimensions 非空)
- [ ] Phase 2 dimension-aware: 每个非 candidate / 非 baseline 维度都有 `skeleton_section` 文件路径,且文件存在于 `assets/skeletons/`
- [ ] Phase 2 dimension-aware: 占位符 100% 替换;目标文档不存在任何 `{{activation_state` 字面残留(grep 验证)
- [ ] Phase 2 dimension-aware: Front Matter `activation_state` 字段值 ∈ {baseline, activated, pending, shallow}(不是 `candidate`,不是占位符)
- [ ] Phase 2 dimension-aware: 每个章节标注 `[{baseline|activated|pending|shallow}]` 与 `activation-report.dimensions[].state` 一致(不允许本地修改)
- [ ] Phase 2 dimension-aware: `baseline` 章节不依赖 code_facts 也能填充(从 baseline-dimensions.yaml default 取)
- [ ] Phase 2 dimension-aware: `pending` 章节不输出强制规则 / FORBIDDEN,只输出占位 + warning + 跳转指针
- [ ] Phase 2 dimension-aware: `shallow` 章节首行 warning 行已写入,`recommended_action` 含 `keep-draft-low-coverage`
- [ ] Phase 2 dimension-aware: `candidate` 维度未出现在端规范文档章节中(只在 overview §9)
- [ ] Phase 2 dimension-aware: `overview.md` 的 §9「未激活维度地图」存在,即使 candidate=0 也保留章节标题(AE7)
- [ ] ai-rules.md 不收录 `pending` / `candidate` 维度的规则
- [ ] review-checklist.md 不收录 `pending` / `candidate` 维度的检查项
- [ ] `rules-index-candidate.json.rules[]` 每条都有 `title`、`domain`、`sub_domain`、`level`、`status`、`source_doc`、`section_title`、`evidence_doc`、`authority_scope`、`upgrade_mode`、`tags`;Phase 1 不含 activation 字段,Phase 2 可额外含 `dimension_id` / `dimension_state`
- [ ] Phase 2 dimension-aware: `ai-context-pack.md` 摘要包含三态分布统计(baseline / activated / pending / shallow / candidate 数量)

任一检查未通过:**不向 review 阶段移交**,回到 Sub-step B 修正。

## 失败模式映射

| 命中条件 | 处理 |
| --- | --- |
| code_facts 为空或全部 pending | 不生成 standard；仅输出 pending-confirmation |
| evidence 不足以写完整章节 | 用已有 evidence 写能覆盖的节；其余节用 pending-confirmation 占位 |
| 发现规则与已有 `auto-active` / `owner-confirmed-active` / legacy `active` 冲突 | 写入 `conflicts.md`，不写入 standard |
| B0 推导阶段无法理解架构 | 回到 profile 阶段补充画像，不凭空编写 |
| `GENERATION_INPUT_PROFILE_MISSING` | 停止管线;要求提供 `selected_batch_summary` 或合法 activation-report |
| `SELECTED_BATCH_CONTEXT_INVALID` | 停止管线;回到 batch-plan 选择单个有效 batch |
| `BATCH_BOUNDARY_LEAK` | 停止管线;清理跨 batch facts,不得扩大读取范围 |
| `NO_REPRESENTATIVE_EVIDENCE` | 不生成 standard;仅输出 pending-confirmation 与 review summary |
| `ACTIVATION_REPORT_SCHEMA_INVALID` | 停止管线;要求重跑 dimension-activator |
| `ACTIVATION_REPORT_RUN_MISMATCH` | 停止管线;清理 temp/ 重跑 |
| `EMPTY_ACTIVATION_REPORT` | 停止管线;dimensions[] 为空意味 dimension-activator 异常 |
| `NO_DIMENSION_CAN_GENERATE` | 停止管线;activation-report 只有 candidate,没有可渲染维度 |
| `MISSING_SKELETON_FOR_ACTIVE_DIM` | 停止管线;对应维度配置 skeleton_section=null 但 state=activated/shallow,需补 assets/skeletons/ |
| `INCOMPLETE_SECTION_STATE_MAP` | 停止管线;skeleton 章节序号未被覆盖,可能 skeleton 与 R51 12 章节模板不一致 |
| `PLACEHOLDER_LEAK` | 停止管线;目标文档残留 `{{activation_state` 字面量,替换不彻底 |

## 必须做

1. 先在 B0 阶段理解 sub_domain 架构，再动笔写文档。
2. `standard-{sub_domain}.md` 是开发者工作手册，不是规则注册表——每节要有实质内容。
3. 代码示例（正例+反例）必须内联在主文档，基于真实 evidence，路径脱敏。
4. 自动运行默认输出 `draft`；只有通过 BR-016/BR-017 高置信自动升级闸时可输出 `auto-active`，`owner-confirmed-active` 只能由领域负责人手动确认。
5. ai-rules 和 review-checklist 是 standard 的派生，不得新创内容。
6. 候选索引产物标记 `candidate`，不得默认发布。
7. **Sub-step A0 必须先于 A 执行**:输入剖面不合法时整个管线停止。
8. Phase 1 selected-batch 只写本 batch evidence-backed draft,不得隐式启动 dimension-activator 或跨 batch 扩大读取。
9. Phase 2 中 **skeleton 选型必须从 activation_report.dimensions[].skeleton_section 取**,不允许本阶段重新决策。
10. Phase 2 中 **占位符必须 100% 替换**:`{{activation_state}}` / `{{activation_state_section_N}}` 不得在最终输出中残留。
11. Phase 2 中 **baseline 章节必须从 baseline-dimensions.yaml default 内容直出**,即使 code_facts 为空。
12. Phase 2 中 **overview-skeleton.md §9「未激活维度地图」必须保留**,即使 candidate 列表为空(AE7)。

## 禁止做

1. 不得为每条规则写整块 yaml 元数据块（catalog 风格）——元数据只能用紧跟规则 H2/H3 的 inline blockquote 行表达，使用 ` · ` 分隔字段。这是本次重写的核心改变。
2. 不得在 Sub-step A 未完成时开始写 standard。
3. 不得把无 evidence 的内容写成强制规则或 FORBIDDEN 标注。
4. 不得在 ai-rules.md 里强制执行 pending/conflict/legacy-compatible 规则。
5. 不得在任何自动运行路径输出 legacy `active` 或 `owner-confirmed-active`；只有过 BR-016/BR-017 闸的规则可输出 `auto-active`。
6. 不得默认发布候选索引产物。
7. 不得凭空编写架构图——从 code_facts 推断，不确定的打「?」标注。
8. 不得在规则节同时写"AI 生成代码要求"小节和文档末尾另一份 AI 规则汇总段重复内容；汇总段只摘要、不重写。
9. Phase 1 selected-batch 不得伪造 `activation-report` 或 `activation_state`;该分支只表达 evidence-backed draft。
10. **不得本地重新计算维度激活态**——Phase 2 中 `activation-report.json` 是唯一权威源;任何与之不一致的章节标注视为 schema violation。
11. **不得为 `candidate` 维度生成端规范章节**——candidate 只在 overview §9 未激活地图出现。
12. **不得跳过占位符替换或选择性替换**——所有 `{{activation_state` 占位符必须替换为具体状态值。
13. **不得把 `pending` 章节的占位规则写为强制规则或 FORBIDDEN**——pending 章节不输出可执行规则,只输出 owner 确认指针。
14. **不得为 `shallow` 章节省略 low-coverage warning**——必须在章节首行写入 warning 与 `recommended_action: keep-draft-low-coverage`。
15. **不得让 ai-rules.md / review-checklist.md 收录 `pending` / `candidate` 维度的规则**——派生视图严格按激活态过滤。

## EA-Doc 扩展（U27）

当 activation-report.json 中存在 EA-Doc-* 评估结果时，generation agent 在主规范末尾追加 §EA-Doc 节，并产出副产物：

```
generation EA-Doc 流程:
  1. 读取 activation-report.json 中 EA-Doc-* 5 维评估（dimension_id 以 "EA-Doc-" 开头）
  2. 对每个 activated 维度：
     - 选择对应骨架（assets/skeletons/doc/EA-Doc-{sub_domain}-skeleton.md）
     - 填充 activation_state / evidence_count / signal_hits / depth_score
     - 读取 evidence/knowledge/doc-inventory.json 获取 heading_signature / file_path
     - 追加到 standard.md 末尾（§EA-Doc 独立小节组）
  3. 产出副产物到 evidence/knowledge/（仅对 activated 维度）：
     - EA-Doc-Glossary activated → evidence/knowledge/glossary.md（≥5 条术语 + 来源）
     - EA-Doc-DomainModel activated → evidence/knowledge/domain-model.md（实体 + BC）
     - EA-Doc-Decision activated → evidence/knowledge/decisions-summary.md（摘要表，不重写原文）
     - EA-Doc-API activated → evidence/knowledge/api-contract.md（端点列表 + shape）
     - EA-Doc-Standard activated → 不产出独立副产物（融入 standard.md §EA-Doc-Standard 节）
  4. Wiki 注入留痕（如 doc_paths 有 wiki-export 来源）：
     - evidence/knowledge/wiki-snapshot-YYYYMMDD.md（文件数、导出时间、source 字段）
  5. baseline 维度（EA-Doc-Decision）→ 直出骨架 §baseline 注释说明，不产出副产物
  6. candidate 维度 → 不追加 §EA-Doc 节；只在 overview §未激活维度地图 中列出升级条件
```

**副产物内容约束**：
- 只从 heading_signature + doc-inventory.json 元数据提炼，不全文读取文档（保护内容边界）
- 每条术语 / 决策 / 端点条目含 `source: file_path:line`（line 为 doc-inventory 中 heading 序号）
- 不重写原始文档内容；decisions-summary.md 只含编号 + 标题 + 状态，不含决策正文
