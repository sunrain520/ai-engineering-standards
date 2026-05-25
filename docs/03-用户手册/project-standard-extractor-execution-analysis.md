# project-standard-extractor 执行逻辑分析

## 1. 分析范围

本文从当前工作树的 source-of-truth 文件出发，梳理 `skills/project-standard-extractor/` 的触发逻辑、执行流程、阶段产物、安全边界和 repair-only 能力边界。本文是用户手册的一部分，用于帮助使用者在执行前理解这个 Skill 到底会做什么、不会做什么，以及每个产物应该如何消费。

本次分析依据：

| 证据 | 作用 |
| --- | --- |
| `skills/project-standard-extractor/SKILL.md` | 公开触发面、稳定输入、稳定输出和安全边界 |
| `skills/project-standard-extractor/references/workflow.md` | 稳定公开路径、Phase 2 blocked 状态、repair-only 边界 |
| `skills/project-standard-extractor/references/agents/*.md` | 各阶段 agent 的输入、输出、失败模式和 handoff 契约 |
| `skills/project-standard-extractor/references/config/output-targets.md` | 统一输出文件、doc_id、append-only 和候选索引规则 |
| `tools/maintainer/project-standard-extractor/README.md` | 维护者工具入口，不属于公开 Skill 触发面 |

结论先行：当前公开稳定路径只有 `profile-first` 和选择单个 batch 后的 `batch-extraction`。Phase 2 `dimension-activator`、cross-project、EA-Doc、securities PoC、force-rebuild / restore / pin / unpin / list 仍是 `blocked / repair-only`，不能作为普通规范萃取 runtime 能力发布。

权威顺序：`SKILL.md` 决定公开触发面，`references/workflow.md` 决定稳定路径与 repair-only 边界，`references/agents/*.md` 决定阶段内部 handoff。若阶段契约中出现 `activation-report`、`dimension-activator`、`output_action != append` 或 backup-manager，这些内容只有在 `workflow.md` 明确进入 repair-only / maintainer 上下文时才生效；普通稳定路径不得把它们提升为公开输入或必经步骤。

## 2. 公开入口总览

`project-standard-extractor` 的目标是从真实代码路径中反向萃取团队级研发规范。它不是代码评审工具，不修改业务代码，也不生成行业通用最佳实践。

公开入口接受的稳定字段只有：

```yaml
project_paths:
  - /path/to/project
output_dir: ""
extraction_mode: ""      # profile-first | batch-extraction | focused-module
selected_batch:
  batch_id: ""
run_mode: auto           # auto | interactive
```

公开入口不得传入 `output_action`、`domain`、`restore_from`、`keep` 或 `full`。这些字段只存在于内部/维护者契约中，普通萃取不应把它们当成可用 API。

### 2.1 触发判断

```text
用户请求
  |
  +-- 提供真实 project_paths，并要求萃取规范 / AI rules / review checklist
  |     |
  |     +-- 触发 project-standard-extractor
  |
  +-- 代码评审 / 单文件解释 / bug 修复 / 业务代码修改
  |     |
  |     +-- 不触发
  |
  +-- 不看代码，只要通用最佳实践
        |
        +-- 不触发
```

## 3. 稳定公开流程

稳定流程是一个先画像、再选 batch、最后生成 draft 的两段式流程。

```text
project_paths
  |
  v
[1] intake-and-scope
  |  输出 scope_summary
  v
[2] profile-and-batch-planner
  |  输出 temp/{run_id}-project-profile.md
  |       temp/{run_id}-extraction-map.md
  |       temp/{run_id}-batch-plan.md
  v
stop-for-batch-selection
  |
  +-- 未选择 batch：停止，不生成标准规则
  |
  +-- 选择 1 个 ready batch
        |
        v
[3] facts-and-classification
  |  输出 code_facts / classification
  v
[4] generation
  |  generation_profile: phase1-selected-batch
  |  输出 evidence / standard / ai-rules / review-checklist / candidates
  v
[5] review-and-quality-gate
  |  输出 review report / quality gate decisions
  v
[6] merge-coordinator
     append-only 写入 draft / pending / conflicts / merge suggestions
```

稳定路径有 4 条硬边界：

1. 完整仓库、多服务或未知范围必须先 `profile-first`，不能直接出规则。
2. 正式生成必须选择单个 `ready` batch，不能一次处理多个 batch。
3. `generation` 使用 `phase1-selected-batch`，不读取 `dimension-activator`，不要求 `activation-report`。
4. 所有规则默认是 `draft`，只能 append-only 写入；`active` 必须由负责人确认。

## 4. 分步执行逻辑

### 4.1 Step 1: Intake And Scope

职责：收集最小输入，判断萃取范围，排除敏感文件，生成 `scope_summary`。

关键逻辑：

| 判断点 | 当前规则 |
| --- | --- |
| 路径校验 | `project_paths` 必须存在、可读、在授权范围内 |
| 广范围判定 | git 根、多个 manifest、多项目、多端、未指定范围等都视为 broad input |
| broad input | 强制 `extraction_mode = profile-first` |
| 敏感文件 | 只记录脱敏存在事实，不读取原文 |
| run_mode=auto | 自动推断并写入 `inferred_decisions`，low confidence 写入待确认 |
| run_mode=interactive | 关键输入未确认时停止 |

公开路径中，`output_action` 永远保持默认 `append`。如果用户试图通过公开入口传入 `force-rebuild`、`restore`、`pin`、`unpin` 或 `list`，必须触发 `MAINTAINER_CONTEXT_REQUIRED`，不得进入 backup-manager。

### 4.2 Step 2: Profile And Batch Planner

职责：轻量扫描项目，生成画像、萃取地图和 batch plan。

```text
scope_summary
  |
  +-- 轻量目录扫描：<= 3 层，<= 15 个 manifest / README / .gitignore 类文件
  |
  +-- 研发域与子领域归因：app-client / frontend / backend / pc / industry
  |
  +-- 模块候选识别：路径模式 + reason + evidence_kind
  |
  +-- extraction-map：domain x sub_domain x task_type x candidate_signals
  |
  +-- batch-plan：batch_id + candidate_files + excluded_paths + limits + status
```

产物：

| 产物 | 含义 |
| --- | --- |
| `temp/{run_id}-project-profile.md` | 项目画像、目录摘要、候选技术栈、敏感存在事实 |
| `temp/{run_id}-extraction-map.md` | 可萃取区域和证据候选矩阵 |
| `temp/{run_id}-batch-plan.md` | 可执行 batch 列表、候选文件、限制和停止条件 |

此阶段只预测 `candidate_dimension_ids[]` 作为搜索提示，不判定维度状态。维度状态只属于 Phase 2 的 `dimension-activator`，而 Phase 2 当前不是公开稳定路径。

### 4.3 Step 3: Stop For Batch Selection

`profile-first` 的完成点就是 batch plan。此时必须暂停，由使用者选择一个 `status: ready` 的 batch。

```text
batch-plan
  |
  +-- 无 selected_batch.batch_id
  |     -> BATCH_NOT_SELECTED
  |
  +-- selected batch 不存在或非 ready
  |     -> 停止，回到 batch-plan 修正或重新选择
  |
  +-- selected batch ready
        -> 进入 facts-and-classification
```

### 4.4 Step 4: Facts And Classification

职责：只从选定 batch 的候选文件中提取事实，不写规范结论。

输出包括：

| 输出 | 说明 |
| --- | --- |
| `signal_hits[]` | grep / ast / file_existence / dependency / gitnexus / doc-content 等信号命中 |
| `doc_facts[]` | 已脱敏的文档事实，仅来自 doc-source-scanner |
| `fact_candidates[]` | 描述性事实候选，不是规范规则 |
| `classification_candidates` | recommended / forbidden / legacy / pending / conflict 的材料分桶 |

此阶段不得消费或本地重算 `activation-report`，也不得决定 `baseline / activated / pending-confirmation / shallow / candidate`。

在稳定公开路径中，可以把这里理解为：把选定 batch 的真实证据整理成可写规范的素材。

### 4.5 Step 5: Generation

职责：先写 evidence，再综合编写开发者指南，最后派生 AI Rules、Review Checklist 和候选索引。

稳定公开路径使用：

```text
generation_profile: phase1-selected-batch
```

Phase 1 selected-batch 的输入门禁：

| 门禁 | 规则 |
| --- | --- |
| 必须有 `selected_batch_summary.batch_id` | 缺失则停止 |
| 必须有 `code_facts` 和 `classification` | 缺失则停止 |
| facts 必须限定在该 batch 的 `candidate_files` 内 | 跨 batch 则 `BATCH_BOUNDARY_LEAK` |
| `code_facts` 为空 | 不生成 `standard-{sub_domain}.md`，只写 pending 和 review summary |
| 不读取 `activation-report` | 不生成维度未激活地图 |

严格工序：

```text
Sub-step A0  Input Profile Loader
     |
     v
Sub-step A   Evidence Writer
     |
     v
Sub-step B   Developer Guide Author
     |
     +--> standard-{sub_domain}.md
     +--> pending-confirmation.md
     |
     v
Sub-step C   Derivative Generator
     |
     +--> ai-rules.md
     +--> review-checklist.md
     |
     v
Sub-step D   Index & Pack Aggregator
           +--> temp/{run_id}-rules-index-candidate.json
           +--> temp/{run_id}-llms-candidate.txt
           +--> temp/{run_id}-ai-context-pack.md
```

### 4.6 Step 6: Review And Quality Gate

职责：对生成产物做多 persona 分面评审，并输出每条规则的质量门禁决策。

公开路径中最重要的使用结论：

| 评审方向 | 检查内容 |
| --- | --- |
| Evidence | 规则是否有可追溯 evidence，是否泄露绝对路径或敏感内容 |
| Team Standard | 是否是团队级抽象，而不是单项目说明或个人偏好 |
| AI Executability | `ai-rules.md` 是否可被 AI 无歧义执行 |
| Review Checklist | 检查项是否可二值判断 |
| Conflict | 是否与已有 active / draft 规则冲突 |
| Industry Risk | 行业、安全、合规规则是否过度声明 |
| Context Governance | 是否遵守 batch 边界、候选索引和 append-only |
| Coverage | Phase 2 repair-only 中检查激活态和 coverage；稳定路径不依赖该能力 |

阶段契约中的 Activation Gate 只在 Phase 2 repair-only 且存在合法 `activation-report.v1` 时生效。稳定公开路径只要求对 evidence、团队抽象、AI 可执行性、review checklist、冲突和上下文治理做质量评审，不得因为缺少 `activation-report` 而要求用户补一个伪造报告。

### 4.7 Step 7: Merge Coordinator

职责：把通过质量门禁的结果 append-only 写入规范目录，并把冲突、待确认和相近项分流到对应文件。

```text
quality_gate_decisions
  |
  +-- keep-draft
  |     -> standard-{sub_domain}.md
  |     -> ai-rules.md
  |     -> review-checklist.md
  |     -> evidence/*
  |
  +-- move-to-pending
  |     -> pending-confirmation.md
  |
  +-- mark-conflict
  |     -> conflicts.md
  |
  +-- similar existing rule
  |     -> merge-suggestions.md
  |
  +-- candidate artifacts
        -> temp/{run_id}-rules-index-candidate.json
        -> temp/{run_id}-llms-candidate.txt
        -> temp/{run_id}-ai-context-pack.md
```

合并铁律：

1. 不覆盖已有 `active` 或 `draft`。
2. 相同规则按 `{source_doc}「{section_title}」` 定位，只追加 evidence。
3. 相似规则写 `merge-suggestions.md`。
4. 冲突规则写 `conflicts.md`。
5. 候选索引不会默认发布成正式 `.index/rules-index.json` 或根 `llms.txt`。

## 5. 产物地图

### 5.1 运行级 handoff 产物

| 路径 | 阶段 | 是否进入 AI 默认上下文 | 说明 |
| --- | --- | --- | --- |
| `temp/{run_id}-project-profile.md` | profile-first | 否 | 项目画像，不是规范 |
| `temp/{run_id}-extraction-map.md` | profile-first | 否 | 可萃取范围和候选 evidence |
| `temp/{run_id}-batch-plan.md` | profile-first | 否 | 用户选择 batch 的依据 |
| `temp/{run_id}-review-report.md` | review | 否 | 质量门禁评审细节 |
| `temp/{run_id}-review-summary.md` | review / merge | 否 | 本次运行摘要和待处理事项 |

### 5.2 规范资产产物

| 路径 | 状态 | 使用方式 |
| --- | --- | --- |
| `standard-{sub_domain}.md` | 默认 `draft` | 主规范文档；负责人确认后才能升级 `active` |
| `standard-common.md` | 默认 `draft` | 跨子领域共性规范 |
| `ai-rules.md` | 派生视图 | 只汇总可执行规则；draft 需标注候选状态 |
| `review-checklist.md` | 派生视图 | Reviewer 使用的检查项 |
| `evidence/code-facts.md` | evidence | 代码事实与推导边界 |
| `evidence/positive-examples.md` | evidence | 正例 |
| `evidence/forbidden-examples.md` | evidence | 反例 |
| `evidence/legacy-compatible.md` | evidence | 历史兼容说明 |
| `pending-confirmation.md` | 待确认 | 不进入 AI 默认执行路径 |
| `merge-suggestions.md` | 合并建议 | 维护者人工裁定 |
| `conflicts.md` | 冲突 | 阻止发布为强规则 |

### 5.3 候选索引产物

| 路径 | 规则 |
| --- | --- |
| `temp/{run_id}-rules-index-candidate.json` | 只能是 candidate，不得默认发布 |
| `temp/{run_id}-llms-candidate.txt` | 只能是候选入口地图，不覆盖根 `llms.txt` |
| `temp/{run_id}-ai-context-pack.md` | 运行级上下文包，默认 `indexable: false` |

## 6. Phase 2 与 repair-only 边界

当前源码中存在 Phase 2 目标管道，但它处于 `blocked / repair-in-progress`。普通用户不要把它当成可用 runtime。

```text
Phase 2 target flow (repair-only)

intake-and-scope
  -> profile-and-batch-planner
  -> doc-source-scanner
  -> facts-and-classification
  -> dimension-activator
  -> generation(phase2-dimension-aware)
  -> review-and-quality-gate
  -> merge-coordinator
```

Phase 2 相比稳定路径新增：

| 能力 | 当前状态 | 边界 |
| --- | --- | --- |
| `dimension-activator` | blocked / repair-only | 只在 repair 验证中作为激活态唯一权威源 |
| `activation-report.v1` | blocked / repair-only | 主数组必须是 `dimensions[]`，空数组不得进入 generation |
| cross-project aggregator | blocked / repair-only | 只消费合法 per-project activation reports |
| EA-Doc | blocked / repair-only | doc-source-scanner 必须在 activator 前输出脱敏 doc facts |
| securities PoC | blocked / repair-only | 不代表真实证券项目验收完成 |
| force-rebuild / restore / pin / unpin / list | maintainer-only | 不属于公开 Skill 触发面 |

### 6.1 维度状态机

```text
signal evidence
  |
  v
dimension-activator
  |
  +-- baseline
  |     -> 最小默认内容；不进入 AI 强制规则
  |
  +-- activated
  |     -> 可生成 standard / ai-rules / review-checklist，仍默认 draft
  |
  +-- pending-confirmation
  |     -> pending-confirmation.md，不进入 AI 默认执行路径
  |
  +-- shallow
  |     -> 可写 draft，但必须标 low coverage
  |
  +-- candidate
        -> 只进入 overview 未激活维度地图，不写端规范规则
```

这套状态机只适用于 Phase 2 repair-only 管道。稳定公开路径不会要求用户提供或消费 `activation-report`。

## 7. Maintainer 工具边界

维护者工具位于仓库根目录 `tools/maintainer/project-standard-extractor/`，不是 skill 包的一部分。

```text
public skill path
  |
  +-- output_action = append
  |     -> stable extraction
  |
  +-- output_action != append
        |
        +-- maintainer_context != true
        |     -> MAINTAINER_CONTEXT_REQUIRED
        |
        +-- maintainer_context = true
              -> backup-manager / maintainer scripts
```

维护者能力包括 `force-rebuild`、`restore`、`pin`、`unpin`、`list`。这些能力必须通过 maintainer / repair-only 上下文手动触发，普通规范萃取不得调用。

## 8. 一致性核对清单

执行或评审一次 `project-standard-extractor` 运行时，按下面清单判断是否仍与当前源码契约一致：

| 检查项 | 必须满足 |
| --- | --- |
| 公开输入 | 只使用 `project_paths`、`output_dir`、`extraction_mode`、`selected_batch`、`run_mode` |
| 广范围输入 | 必须先 `profile-first` |
| profile-first 输出 | 只生成 profile / extraction-map / batch-plan，不生成规则 |
| 正式生成 | 必须选择一个 ready batch |
| generation profile | 稳定路径必须是 `phase1-selected-batch` |
| activation-report | 稳定路径不得要求或伪造 |
| dimension-activator | 稳定路径不得读取 |
| 规则状态 | 自动输出只能是 draft / pending / conflict 等候选状态 |
| 合并策略 | append-only，不覆盖 active / draft |
| AI 默认上下文 | 只有负责人确认的 active 可作为强约束 |
| 候选索引 | 不得默认覆盖正式 rules-index 或 llms |
| 维护者动作 | `output_action != append` 必须有 maintainer context |
| 敏感文件 | 只记录脱敏存在事实，不读取原文 |

## 9. 推荐执行话术

### 9.1 第一步：生成画像和 batch plan

```text
使用 project-standard-extractor 萃取规范。
project_paths:
  - <项目路径>
extraction_mode: profile-first

只输出 project-profile、extraction-map 和 batch-plan；不要生成 standard、ai-rules 或 review-checklist。
```

### 9.2 第二步：选择一个 batch 生成 draft

```text
继续使用 project-standard-extractor 执行 batch-extraction。
project_paths:
  - <项目路径>
extraction_mode: batch-extraction
selected_batch:
  batch_id: <batch-plan 中的 ready batch id>

只读取该 batch 的 candidate_files，生成 evidence-backed draft standard、ai-rules、review-checklist、pending-confirmation、merge-suggestions、conflicts 和候选索引产物。
```

### 9.3 第三步：人工确认后再发布

```text
请按 review-summary、pending-confirmation 和 conflicts 检查本次萃取结果。
只有负责人确认的规则才能从 draft 升级为 active；
pending-confirmation、conflict 和 candidate 产物不得进入 AI 默认执行路径。
```

## 10. 常见误用

| 误用 | 正确做法 |
| --- | --- |
| 直接从完整仓库生成规范规则 | 先 `profile-first`，再选单个 batch |
| 把 `domain` 当公开参数传入 | 让 Intake 从路径和说明推断，必要时在确认环节修正 |
| 把 `output_action=force-rebuild` 当普通模式 | 这是 maintainer / repair-only 能力，公开入口会拒绝 |
| 把 `activation-report` 当稳定路径必需输入 | 只有 Phase 2 repair-only 才需要 |
| 把 `draft` 直接给 AI 当强制规则 | 只有 `active` 可默认强制执行 |
| 用候选 `llms-candidate.txt` 覆盖根 `llms.txt` | 必须显式发布确认 |
