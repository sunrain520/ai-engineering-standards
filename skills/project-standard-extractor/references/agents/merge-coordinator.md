# Merge Coordinator Contract

## 角色目标

把通过 Quality Gate 的结果**以 append-only 方式写入规范目录**。Phase 1 full-auto 缺失 `activation_report` 时,按 `target_state` 直接合并规则、lineage、owner queue 与候选产物；Phase 2 repair-only 提供 `activation_report` 时,额外消费维度激活态并聚合 overview §9 未激活维度地图。分层知识库模型下,Merge Coordinator 是 extracted→draft/auto-active 的最后一道门——写入即固化,不可隐性覆盖。

> 上游：`review-and-quality-gate`（quality_gate_decisions + review_report；Phase 2 可额外透传 activation_report）。下游：规范目录、lineage ledger、owner decision queue、候选索引；Phase 2 另写 overview 未激活维度地图。

## 输入

```yaml
inputs:
    quality_gate_decisions: []  # 每条规则一个决策；Phase 1 含 target_state,Phase 2 另含 dimension_id / dimension_state
    review_report:              # 包含 review_profile / debate_records / persona_findings / overrides / candidate_dim_summary
    activation_report:          # 可选；Phase 2 temp/{run_id}-activation-report.json（schema=activation-report.v1）
    coverage_report:            # Phase 1 profile/batch coverage + blind_spots
  target_domain_dir: ""       # 目标 domain 目录（如 engineering-standards/04-backend/）
  existing_index:             # 见下方 Schema
  candidate_artifacts:        # rules-index-candidate.json, llms-candidate.txt, ai-context-pack.md
  overview_skeleton:          # assets/skeletons/overview-skeleton.md（提供 §9 段落模板）
  cross_batch_aggregation:    # 同 run 已合并的 batch 历史（多 batch 跨次运行时使用）
    completed_batches: []
    candidate_dim_accumulated: {}   # {dimension_id: {layer, name, batches: [], suggested_owner_question}}
```

**existing_index Schema**（写入前必须先建立）：

```yaml
existing_index:
  docs:
    - doc_id: ""
      doc_type: ""
      domain: ""
      sub_domain: ""
      indexable: false
    rule_locators:     # [{source_doc, section_title, level, status, target_state, confidence_tier, dimension_id?, dimension_state?}]
    - source_doc: ""
      section_title: ""
        level: ""
        status: ""
        target_state: ""
        confidence_tier: ""     # high / normal / low
        authority_scope: ""     # auto-active 必填 this-repo；owner-confirmed 可为 this-repo/cross-project
        upgrade_mode: ""        # auto-active / owner-confirmed / none
        deterministic_occurrence_count: null
        last_evidence_confirmed_run: ""
        dimension_id: ""        # Phase 2 关联到 activation-report.dimensions[]
        dimension_state: ""     # Phase 2 baseline / activated / pending-confirmation / shallow / candidate
  evidence_ids:      # [EV-/POS-/NEG-/LEG-{DOMAIN}-{NUMBER}]
    - ""
  title_fingerprints: []   # section_title 的 normalized 形式，用于相似度检测
    states:
      auto_active: []
      owner_confirmed_active: []
      draft: []
      stale_auto_active: []
      owner_rejected: []
      pending_confirmation: []
      conflict: []
      legacy_compatible: []
  activation_states:        # 当前 domain 已收录的维度激活态分布（跨 batch 持久化）
    baseline: []
    activated: []
    pending_confirmation: []
    shallow: []
    candidate: []           # overview §9 未激活维度地图来源
  overview_doc:             # 当前 domain 的 overview 文档定位
    path: ""                # 如 engineering-standards/04-backend/overview.md
    has_section_9: false    # §9「未激活维度地图」是否已建段
    last_section_9_update: ""
```

## Phase 1 / Phase 2 路由边界

| 条件 | routing_profile | activation_report 处理 | 主路由 |
| --- | --- | --- | --- |
| `activation_report` 缺失且 `review_report.review_profile == phase1-full-auto` | `phase1-full-auto` | 必须跳过 Step 1.5 schema gate / Step 4.5 / Step 4.6；不得合成或落盘 activation-report | 直接按 `quality_gate_decisions[].target_state` 写入 |
| `activation_report` 存在 | `phase2-dimension-aware` | 必须校验 schema/run_id 并透传落盘 | 先按 `dimension_state` 分桶，再按 `target_state` 二级路由 |
| `activation_report` 缺失且 review profile 不是 Phase 1 | invalid | `ACTIVATION_REPORT_MISSING_WITHOUT_PHASE1` | 停止写入 |

**Phase 1 铁律**:不得生成、复制、持久化 `activation-report.json`。一旦 Phase 1 temp 目录出现该文件,后续 generation/review 会误判为 Phase 2,必须由 validator BLOCK。

## Phase 2 维度激活态消费契约

仅在 `routing_profile == phase2-dimension-aware` 时,本阶段对 `quality_gate_decisions[].dimension_state` 与 `activation_report.dimensions[]` 做双重消费：

| dimension_state | 写入策略 | 写入位置 |
| --- | --- | --- |
| `baseline` | 仅在 standard-{sub_domain}.md 写入对应章节（章节正文来自 baseline-dimensions.yaml default，由 generation 已渲染） | standard-{sub_domain}.md |
| `activated` | 完整规则 + evidence 写入 | standard-{sub_domain}.md + ai-rules.md + review-checklist.md + evidence/* |
| `shallow` | 写入 standard-{sub_domain}.md 但保留 `recommended_action: keep-draft-low-coverage`；ai-rules.md 加 ⚠️ 标注 | standard-{sub_domain}.md（low-coverage 标记）+ ai-rules.md（带 warning）+ pending-confirmation.md（升级条件） |
| `pending-confirmation` | 仅写入 pending-confirmation.md；不写 standard / ai-rules / review-checklist | pending-confirmation.md |
| `candidate` | **不写入端规范**；汇总到 `overview.md` §9「未激活维度地图」 | `overview.md` §9 |

**铁律**：Phase 2 不重新判定 state；activation-report 是唯一权威源。任何与 activation-report / quality_gate_decisions[].dimension_state 不一致的写入视为 schema violation。Phase 1 没有 dimension_state,不得用空维度字段触发本节逻辑。

### 跨项目合并扩展（仅多项目模式启用）

当 `cross-project-aggregator` 已产出 `temp/{run_id}-unified-activation-map.json` 时，本 agent **以 unified map 为权威源**（替代单项目 activation-report.json），并按以下扩展规则处理：

| unified_state | 写入策略（叠加上表） | 写入位置 |
| --- | --- | --- |
| `unified_baseline` / `unified_activated` / `unified_pending_confirmation` / `unified_shallow` / `unified_candidate` | 同上表对应单项目 state 行 | 同上表 |
| `partial_activated` | 写入 `standard-{domain}-{sub_domain}.md §3 子领域差异对比章节` 的「统一要求」列与「各项目当前实现」列；不写入 `standard.md §1/§2 主体规则`；该维度同时进 `evidence/project-specific-divergence.md`（由 cross-project-aggregator 已渲染） | standard-{sub_domain}.md §3 子领域差异列 + project-specific-divergence.md |

跨项目铁律（叠加上方铁律）：

1. 单项目 state 已被 unified_state 取代，不得再以单项目 state 决策写入位置。
2. `partial_activated` 维度**绝不**写入 `standard.md §1/§2`，只能进 §3 差异列与 divergence.md。
3. divergence.md 中「裁定结果」未填时，`partial_activated` 维度的 §3 差异列必填 `⚠️ 待人工裁定`，不得静默升级为 unified_activated。
4. 多项目模式下 `overview.md §9 未激活维度地图` 仍按 unified_candidate 维度写入；`partial_activated` 不进 §9（它在 §3 差异列已显性出现）。

## 输出（Run Summary）

```yaml
merge_summary:
  run_id: ""
  executed_at: ""
  final_status: ""             # success | partial | failed（U24 必填，force-rebuild step 10 dispatcher 据此分流）
  final_status_reason: ""      # final_status ≠ success 时必填，canonical 失败原因（见 §final_status 决策算法）
  routing_profile: ""          # phase1-full-auto | phase2-dimension-aware
  activation_report_source: "" # Phase 2 输入 temp/{run_id}-activation-report.json；Phase 1 为 null，不作为正式产物
  activation_report_path: ""   # Phase 2 Step 4.6 落盘后的正式 evidence 路径；Phase 1 为 null
  lineage_ledger_path: ""      # {output_dir}/{domain}/lineage-ledger.json
  owner_decision_queue_path: "" # {output_dir}/{domain}/owner-decision-queue.json
  written_files: []            # 写入或追加的文件列表
  new_rule_locators: []        # 新增 [{source_doc, section_title, level, target_state, dimension_id?, dimension_state?}]
  new_evidence_ids: []         # 新增 [EV/POS/NEG/LEG-DOMAIN-N]
  merged_to_draft: 0           # 写入 standard-{sub_domain}.md 的规则数
  promoted_to_auto_active: 0
  moved_to_stale_auto_active: 0
  owner_rejected_removed_from_execution: 0
  moved_to_pending: 0
  moved_to_conflicts: 0
  added_to_merge_suggestions: 0
  candidate_artifacts_written: []
  pending_human_actions: []    # 需要负责人手动操作的项
  dry_run: false               # true 时只输出 plan，不实际写入
  activation_summary:          # 三态汇总（U10 强制）
    baseline_count: 0
    activated_count: 0
    pending_confirmation_count: 0
    shallow_count: 0
    candidate_count: 0
    shallow_overrides_applied: 0     # 来自 review.shallow_overrides[]
    pending_overrides_applied: 0     # 来自 review.pending_overrides[]
  overview_section_9:           # AE7 未激活维度地图写入摘要
    written: false              # 是否触达 §9 写入逻辑
    overview_path: ""
    candidate_dim_count: 0
    new_candidate_dims: []      # 本次新增的 candidate 维度 id 列表
    preserved_when_empty: false # candidate=0 时是否仍保留 §9 标题段（必须 true）
  rule_evolution:              # Phase 1/2 共享的批次演进摘要；跨项目模式同时写入 cross_project_summary.rule_evolution
    previous_report_path: null
    added: []
    evidence_changed: []
    superseded: []
    stale_active_needs_owner_review: []
  cross_project_summary:        # 仅多项目模式存在；单项目模式整段为 null
    enabled: false              # len(project_paths) > 1 才为 true
    project_count: 0
    unified_map_ref: ""         # temp/{run_id}-unified-activation-map.json
    divergence_doc_ref: ""      # evidence/project-specific-divergence.md
    partial_activated_count: 0
    section_3_filled_count: 0   # 写入 §3 差异列的维度数
    pending_human_decisions: 0  # divergence.md 第 4 节「团队规范裁定」未填的维度数
    warnings: []
    rule_evolution: （同上 merge_summary.rule_evolution 共享）
```

## 执行步骤

### Step 0 — Dry-run 预检（可选，建议首次合并时启用）

在实际写入前，以 `dry_run: true` 运行整个 Step 1-4，输出：

```yaml
dry_run_plan:
  would_write: []          # 会写入的文件 + 追加内容摘要
  would_skip: []           # 因已存在而跳过的
  would_conflict: []       # 发现新冲突的
  would_suggest_merge: []  # 发现相似规则的
  risk_level: ""           # low / medium / high（基于 conflict 和 owner-confirmed-active/legacy active 规则数量）
```

`risk_level: high` 时（命中任一）：
- 有 ≥ 1 条规则与已有 `owner-confirmed-active` 或 legacy `active` 冲突
- 有规则要写入已有 `standard-{sub_domain}.md` 且该文件现有规则 ≥ 30 条（或文件行数 ≥ 1000 行）

**高风险时**：输出 dry-run 计划并暂停，等待负责人确认后再执行实际写入。

### Step 1 — 建立 Existing Index

读取目标 domain 目录下的所有 Markdown 文件，提取：

1. Front Matter 中的 `doc_id`、`doc_type`、`domain`、`sub_domain`、`indexable`。
2. 所有 `## {P0|P1|P2|FORBIDDEN} {title}` H2 标题（section_title 提取）。
3. 所有 `EV-/POS-/NEG-/LEG-{DOMAIN}-{N}` 条目编号。
4. 每条规则的 `status`（从规则 YAML 提取）。

生成 `existing_index`，贯穿后续所有合并决策。

### Step 1.5 — Routing Profile 判定与 Activation Report 门禁

1. 若 `activation_report` 缺失且 `review_report.review_profile == "phase1-full-auto"`:
   - 设置 `merge_summary.routing_profile = "phase1-full-auto"`。
   - 设置 `merge_summary.activation_report_source = null` 与 `merge_summary.activation_report_path = null`。
   - 跳过本步骤的 activation-report schema/run_id/维度一致性门禁。
   - 校验 `quality_gate_decisions[]` 每条都包含 `target_state`;`target_state: auto-active` 必须含 `deterministic_occurrence_count`、`authority_scope: this-repo`、`upgrade_mode: auto-active`、反范式黑名单结果和高风险域结果。
2. 若 `activation_report` 存在:
   - 设置 `merge_summary.routing_profile = "phase2-dimension-aware"`。
   - 读取 `activation_report` JSON，校验 `schema == "activation-report.v1"`；不匹配抛 `ACTIVATION_REPORT_SCHEMA_INVALID`。
   - 校验 `run_id` 与当前 run 一致；不匹配抛 `ACTIVATION_REPORT_RUN_MISMATCH`。
   - 读取 `review_report` 中的 `shallow_overrides[]`、`pending_overrides[]`、`candidate_dim_summary{}`。
   - 把 `activation_report.dimensions[]` 按 state 分组并写入 `merge_summary.activation_summary`（5 个计数）。
   - 校验**激活态-决策一致性**（强校验）：
     - 任一 `quality_gate_decision.dimension_state == "candidate"` 进入 standard 类目录（standard-/ai-rules/review-checklist）→ 抛 `CANDIDATE_LEAKED_TO_STANDARD`，停止写入。
     - 任一 `quality_gate_decision.dimension_state == "pending-confirmation"` 但 `target_state == "auto-active"` 或 `recommended_action == "auto-activate"` → 抛 `PENDING_FORCED_TO_ACTIVE`，停止写入。
     - 任一 `dimension_state == "shallow"` 但 `recommended_action != "keep-draft-low-coverage"` 且 `final_gate_decision != "keep-draft-low-coverage"` → 抛 `SHALLOW_MISSING_LOW_COVERAGE`。
3. 若 `activation_report` 缺失且 review profile 不是 Phase 1,抛 `ACTIVATION_REPORT_MISSING_WITHOUT_PHASE1` 并停止写入。

### Step 2 — 决策路由

**Phase 1 决策优先级**：直接按 `target_state` 决定文件级路由,不读取 `dimension_state`,不要求 `dimension_id`。

| target_state 条件 | 写入位置 | 说明 |
| --- | --- | --- |
| `auto-active` | `standard-{sub_domain}.md` + `ai-rules.md §2` + `review-checklist.md §1/§2` + `evidence/*` + `lineage-ledger.json` + `owner-decision-queue.json` | 进 AI 默认执行；规则元数据写 `status: auto-active`, `authority_scope: this-repo`, `upgrade_mode: auto-active`, `last_evidence_confirmed_run: {run_id}` |
| `draft` | `standard-{sub_domain}.md` + `ai-rules.md §3` / review checklist 按需参考 + `evidence/*` + `lineage-ledger.json` | 结构化可读但不进 AI 默认强制执行 |
| `pending-confirmation` | `pending-confirmation.md` + `owner-decision-queue.json` | low-confidence / 高风险 / 命中黑名单 / evidence 不足；不进 ai-rules 可执行段 |
| `conflict` | `conflicts.md` + `owner-decision-queue.json` | 不进 standard；保留冲突双方定位和 evidence |
| `legacy-compatible` | `evidence/legacy-compatible.md` | 不写为推荐规则 |
| `stale-auto-active` | `conflicts.md` 或 `merge-suggestions.md` + `owner-decision-queue.json`;从 ai-rules/review-checklist 默认执行段移出 | 自动复检发现原 auto-active 不再满足 BR-016/BR-017；移出执行路径不等于改写正文 |
| `owner-rejected` | `owner-decision-queue.json` 记录终态;从 ai-rules/review-checklist 默认执行段移出 | owner 否决 auto-active；下次运行不得重新加入执行路径,除非 owner 重新确认 |
| `rejected` | review_report 记录 | 不写入任何规范文件 |
| candidate artifact | `temp/{run_id}-rules-index-candidate.json` + `temp/{run_id}-llms-candidate.txt` + `temp/{run_id}-ai-context-pack.md` | 候选，不发布 |

**Phase 2 决策优先级**：先按 `dimension_state` 决定写入目录大类（baseline / activated / shallow / pending / candidate），再按 `final_gate_decision` 与 `target_state` 决定文件级路由。

| dimension_state | final_gate_decision | 写入位置 | 说明 |
| --- | --- | --- | --- |
| `baseline` | `pass` / `keep-draft` | `standard-{sub_domain}.md`（章节正文已由 generation 从 baseline-dimensions.yaml default 渲染） | 不进 ai-rules.md（baseline 章节属常识陈述，不需 AI 强制清单） |
| `activated` | `auto-activate` / `keep-draft` | `standard-{sub_domain}.md` + `ai-rules.md` + `review-checklist.md` + `evidence/*` | 主路径 |
| `shallow` | `keep-draft-low-coverage` | `standard-{sub_domain}.md`（low-coverage 标记保留）+ `ai-rules.md`（带 ⚠️ warning）+ `pending-confirmation.md`（升级条件 promotion_criteria） | 双写 standard 与 pending |
| `pending-confirmation` | `move-to-pending` | `pending-confirmation.md`（独占） | 不进 standard/ai-rules/review-checklist |
| `candidate` | （P8 已 BLOCK，不应出现 final_gate_decision；理论上不进入本步骤） | `overview.md §9`（仅地图条目，不写规则） | 由 Step 4.5 单独聚合 |

**Phase 2 target_state 二级路由**（仅对 baseline/activated/shallow 适用）：

| target_state 条件 | 写入位置 | 说明 |
| --- | --- | --- |
| target_state=auto-active, recommended_action=auto-activate | `standard-{sub_domain}.md` + `ai-rules.md §2` + `review-checklist.md` + `evidence/*` + lineage / owner queue | 单项目高置信自动升级；仅在非高风险、未命中黑名单且闸判据完整时允许 |
| target_state=draft, recommended_action=keep-draft | `standard-{sub_domain}.md` + `ai-rules.md §3` + `review-checklist.md` + `evidence/*` | 不进 AI 默认强制执行 |
| target_state=pending-confirmation | `pending-confirmation.md` | 不进 ai-rules |
| target_state=conflict | `conflicts.md` | 不进 standard |
| similar existing rule（title fingerprint 相似度 ≥ 0.8） | `merge-suggestions.md` | 不重复写规则 |
| target_state=legacy-compatible | `evidence/legacy-compatible.md` | 不写为推荐规则 |
| target_state=rejected | review_report 记录，不写入任何文件 |
| candidate artifact | `temp/{run_id}-rules-index-candidate.json` + `temp/{run_id}-llms-candidate.txt` + `temp/{run_id}-ai-context-pack.md` | 候选，不发布 |

### Step 3 — 幂等合并协议

**规则合并决策（以 `(source_doc, section_title)` 为唯一定位）**：

1. **精确匹配** `(source_doc, section_title)` 已在 `existing_index.rule_locators` 中：
   - 不重写规则正文
   - 只追加新 evidence 条目编号到该规则的 Evidence 小节
   - 把差异记入 `merge-suggestions.md`（`MERGE-{DOMAIN}-{N}`）

2. **相似匹配**（`title_fingerprint` 相似度 ≥ 0.8，或同 source_doc 下措辞差异）：
   - 写入 `merge-suggestions.md`，列出两条规则的 diff 摘要
   - 不新增重复规则

3. **冲突匹配**（与已有 `owner-confirmed-active` 或 legacy `active` 逻辑矛盾）：
   - 写入 `conflicts.md`（`CONFLICT-{DOMAIN}-{N}`）
   - 保留两方 evidence
   - 不降级、不覆盖已有 `owner-confirmed-active` / legacy `active`

4. **与已有 `draft` 冲突**：
   - 写入 `conflicts.md`
   - 保留两个候选的 evidence
   - 等待负责人裁定

5. **新规则（无匹配）**：
   - 按决策路由写入对应文件
   - 追加到 `existing_index`

6. **跨运行置信升级 / supersede**：
   - 若同一 `(source_doc, section_title)` 或 normalized title fingerprint 在历史 `pending-confirmation.md` 中存在,本次通过 `auto-active` 或 `draft` 路由写入 standard,则历史 pending 条目只追加 `superseded_by: {source_doc}「{section_title}」` 与 `superseded_run_id: {run_id}`。
   - coverage 统计按 normalized locator 去重,不得把 pending 旧条目和 standard 新条目重复计数。

7. **存量刷新检测（不改写 active）**：
   - 若已有 `owner-confirmed-active` / legacy `active` / `draft` 与本次 evidence 语义不一致,写入 `conflicts.md` 或 `merge-suggestions.md`,并在 owner queue 中标记 `stale-active-needs-owner-review`。
   - 不自动改写已有 active/draft 正文,不自动降级 `owner-confirmed-active`。

8. **auto-active 自动失效出口**：
   - 对历史 `auto-active` 规则,若本次 deterministic occurrence 掉破阈值、出现未裁定 conflict、命中新黑名单或落入高风险域,将执行路径状态标为 `stale-auto-active`,并从 `ai-rules.md §2` / review checklist 默认执行段移出。
   - 正文仍保留 append-only 记录；owner queue 记录 `stale-auto-active` 的 evidence diff 与建议动作。

**Evidence 合并决策**（以 `EV/POS/NEG/LEG-DOMAIN-N` 为唯一定位）：

- 编号已存在：只追加 `observations`（新观察时间、来源项目、补充说明）；不复制重复段落
- 编号不存在：分配下一个编号（当前最大 N+1），写入对应文件
- **Front Matter 数组累积**：evidence 文件是 domain 级（不是 sub_domain 级）；每次写入新条目后，必须在 Front Matter 的 `sub_domains` 与 `source_batches` 数组中追加该条目对应的值并去重，使头部反映文件覆盖范围而非首次写入快照

**rule_evolution 输出**：

```yaml
rule_evolution:
  previous_report_path: null
  added:
    - source_doc: ""
      section_title: ""
      target_state: ""
  evidence_changed:
    - source_doc: ""
      section_title: ""
      previous_evidence_ids: []
      current_evidence_ids: []
  superseded:
    - previous_locator: "pending-confirmation.md「PENDING-{DOMAIN}-{N}」"
      superseded_by: "{source_doc}「{section_title}」"
  stale_active_needs_owner_review:
    - source_doc: ""
      section_title: ""
      reason: "evidence_changed | conflict_detected | auto_active_gate_failed | owner_rejected"
```

### Step 4 — 写入执行

**standard 文件路由（按 sub_domain）**：

| batch.sub_domain | 写入目标文件 |
| --- | --- |
| 明确的 sub_domain（如 `java-spring`） | `standard-java-spring.md` |
| 跨 sub_domain 共性规则 | `standard-common.md` |
| sub_domain 未知 | 写入 `pending-confirmation.md`，标注 `reason: sub_domain_unknown` |

每次写入操作：

1. 先读取目标文件（若已存在），确认不会覆盖已有 `owner-confirmed-active` / legacy `active` 内容。
2. 追加到文件末尾（或对应 section 末尾），保留已有内容。
3. 若目标文件不存在：按 `references/config/frontmatter-format.md` 新建，写入 Front Matter（`doc_id: {domain}-{sub_domain}-standard`），规则 H2 满足 `^(P0|P1|P2|FORBIDDEN) ` 前缀。
4. 若目标文件缺少 Front Matter（历史遗留）：追加到 `merge-suggestions.md`，不直接修改头部。
5. **⚠️ 文档大小预警**：写入后若 `standard-{sub_domain}.md` 超过 **1500 行**，在 `merge_summary.warnings` 追加：`"{sub_domain} 规范文件已达 {N} 行，建议按 task_type 拆分为多个 sub_domain 文件"`。

**冲突严重度分级**（写入 `conflicts.md` 时标注）：

| 严重度 | 条件 | 负责人优先级 |
| --- | --- | --- |
| `breaking` | 新规则与已有 owner-confirmed-active / legacy active 逻辑矛盾，AI 若同时执行会产生冲突行为 | 阻塞发布，优先处理 |
| `warning` | 新规则与已有 draft 语义重叠，尚无矛盾 | 建议合并 |
| `info` | 新规则与已有规则表述相似但涵盖不同场景 | 可保留两条，注明差异 |

**每次写入都必须同步追加 lineage edge**：

```yaml
lineage_edge:
  run_id: ""
  batch_id: ""
  evidence_id: ""
  source_doc: ""
  section_title: ""
  derived_view_type: "standard | ai-rules | review-checklist | rules-index | pending | conflict | legacy"
  gate_result: "auto-active | draft | pending-confirmation | conflict | legacy-compatible | stale-auto-active | owner-rejected | rejected"
  upgrade_mode: "auto-active | owner-confirmed | none"
  deterministic_occurrence_count: null
  authority_scope: "this-repo | cross-project | none"
  last_evidence_confirmed_run: ""
```

V1 lineage 不复制规则正文,只记录 locator、evidence、派生视图和 gate 判据快照。每个写入点实时 append,不得等所有文件写完后凭记忆补账。

**owner decision queue 写入规则**：

- `auto-active`: 进入 owner queue,`owner_queue_action: review-auto-active`;若需安全负责人复核可用 `security-review`。
- `pending-confirmation`: 进入 owner queue,`owner_queue_action: confirm-or-reject`;高风险域可用 `security-review`。
- `conflict`: 进入 owner queue,`owner_queue_action: resolve-conflict`。
- `stale-auto-active`: 进入 owner queue,`owner_queue_action: review-stale-auto-active`,并从默认执行路径移出。
- `owner-rejected`: 记录终态,`owner_queue_action: no-action-terminal`,下次运行不得恢复默认执行。

### Step 4.5 — Phase 2 Overview §9 未激活维度地图聚合（AE7 强制段，跨 batch 持久化）

**触发**：仅 `routing_profile == phase2-dimension-aware` 时执行。每次 batch 合并完成后**必须**执行；即使本 batch 无 candidate 维度，仍需校验 overview §9 段标题存在（`preserved_when_empty: true`）。Phase 1 full-auto 不运行本步骤,其 coverage 缺口写入 review summary / coverage report。

**执行步骤**：

1. **定位 overview 文档**：
   - 路径：`{target_domain_dir}/overview.md`（如 `engineering-standards/04-backend/overview.md`）
   - 不存在 → 用 `assets/skeletons/overview-skeleton.md` 创建（10 节齐全），但仅渲染 §9 段；其余章节标记 `[draft]` 留空待后续补充。

2. **聚合 candidate 维度**：
   - 来源 1：本 batch 的 `activation_report.dimensions[]` 中 `state == "candidate"` 的维度。
   - 来源 2：`existing_index.activation_states.candidate[]`（历史已收录）。
   - 来源 3：`cross_batch_aggregation.candidate_dim_accumulated{}`（同 run 已合并 batch）。
   - 三方合并去重，按 `dimension_id` 唯一。

3. **生成 §9 表格**（按 layer 分组）：

```markdown
## §9 未激活维度地图

> 本节为 AE7 强制段。列出当前 domain 中**已知但未激活**的维度（state=candidate），帮助负责人判断未来是否要扩展。维度激活态会随项目演进变化，此地图仅反映 {run_id} 时点状态。

### 9.1 端级未激活维度（layer = end:{domain}）

| 维度 ID | 名称 | 触发条件（trigger_when） | 建议负责人提问（suggested_owner_question） | 首次发现 batch | 最近更新 |
| --- | --- | --- | --- | --- | --- |
| EA-Backend-09 | 灰度发布与回滚 | 出现 release 流水线 + canary 配置 | 当前是否有灰度发布需求? | batch-001 | 2026-05-25 |

### 9.2 行业未激活维度（layer = industry:*）

| 维度 ID | 行业 | 名称 | 触发条件 | 建议负责人提问 | 首次发现 batch | 最近更新 |
| --- | --- | --- | --- | --- | --- | --- |

### 9.3 baseline 未激活维度

> 默认情况下 baseline 维度全部激活；本节仅记录极少数 baseline 维度因 ad-hoc 配置被标记为 candidate 的异常情况。

| 维度 ID | 名称 | 触发条件 | 建议负责人提问 | 首次发现 batch | 最近更新 |
| --- | --- | --- | --- | --- | --- |
```

4. **写入策略（append-only）**：
   - 已存在的 `dimension_id`：仅更新「最近更新」列与「首次发现 batch」（若已更早，则保留）；其它字段保留原值。
   - 新 `dimension_id`：追加到对应 layer 子表（9.1/9.2/9.3）。
   - 删除：**不允许**——即使本 run 该维度变成 activated，§9 仍保留历史条目并把「最近更新」列标 `→ activated since {run_id}`，由负责人手动决定是否清理。
   - 表格按 `dimension_id` 升序排列。

5. **记录到 merge_summary**：
   ```yaml
   overview_section_9:
     written: true
     overview_path: "engineering-standards/04-backend/overview.md"
     candidate_dim_count: 12
     new_candidate_dims: ["EA-Backend-09", "SEC-04"]
     preserved_when_empty: false   # 本次有内容
   ```

6. **空集兜底**：若 candidate 集合为空，仍执行步骤 1-2-3-5，但 §9 各子表只保留表头与一行 `> 当前 domain 暂无未激活维度（candidate=0）。`，并设置 `preserved_when_empty: true`。

**Phase 2 铁律**：
- 不得跳过本步——即使全部维度都是 activated。
- 不得删除已有 candidate 条目（append-only / soft-archive）。
- 不得把 §9 写到 standard-{sub_domain}.md（必须写到 overview 文档）。

### Step 4.6 — Phase 2 Activation Report 持久化（R54 强制落盘 / U17）

仅 `routing_profile == phase2-dimension-aware` 时,每次 run 必须把 `temp/{run_id}-activation-report.json` 拷贝并补字段后落盘到正式 evidence 目录,作为下次增量 run 的基线 + 跨项目合并源 + Coverage Reviewer 复核的产物附属物。Phase 1 full-auto **不得**执行本步骤,也不得在 temp/ 或 evidence/ 生成 activation-report。

```yaml
activation_report_persistence:
  source: "temp/{run_id}-activation-report.json"      # 来自 dimension-activator
  dest_single_project: "{output_dir}/{domain}/evidence/dimension-activation-report.json"
  dest_per_project: "{output_dir}/{domain}/evidence/per-project/dimension-activation-report-project-{N}.json"
  dest_unified_map: "{output_dir}/{domain}/evidence/unified-activation-map.json"
  schema_template: "assets/dimension-activation-report-template.json"
```

#### 4.6.1 单项目模式

1. 读取 `temp/{run_id}-activation-report.json`,校验 `schema == "activation-report.v1"`(已在 Step 1.5 校验,此处复用结果)。
2. 按 `assets/dimension-activation-report-template.json` 补齐字段:
   - `timestamp`：当前 ISO8601 时间戳
   - `project_paths`：来自 `scope_summary.project_paths`
   - `last_commit`：调用 `git rev-parse HEAD` / `git log -1 --format=%cI` / `git rev-parse --abbrev-ref HEAD`(非 git 仓库 → 三字段全 null,写入 warnings)
   - `dimensions[]` 是 activation-report 的唯一主数组；不得再写旧数组别名。
   - `summary` 5 计数从 `merge_summary.activation_summary` 直接搬入
3. 增量模式追加 `evolution{}`(见 §4.6.2)。
4. 写入路径:`{output_dir}/{domain}/evidence/dimension-activation-report.json`。
5. 写入策略:**覆盖**（本文件不是 append-only;每次 run 都是当次的完整快照,历史快照通过 git diff 与 evolution.previous_report_path 追溯)。
6. 把落盘路径回写 `merge_summary.activation_report_path`(替代 temp-only source)。

#### 4.6.2 增量模式态变迁记录

`scope_summary.extraction_mode == "diff"` 或上次 run 的 `evidence/dimension-activation-report.json` 存在时,生成 `evolution{}`:

1. 读取上次 `evidence/dimension-activation-report.json`(若不存在 → `evolution.previous_report_path = null`,`transitions = []`)。
2. 按 `dimension_id` 比对前后两次 `state`:
   - `from_state != to_state` → 记录 1 条 transition
   - `from_state == to_state` → 计入 `stable_count`
3. 每条 transition 必填 `transition_reason`(规则推断,例如"signal `kmp-source-set` 由 hit=false 变 hit=true" / "depth_score 由 0.45 提升到 0.82" / "owner 在 pending-confirmation.md 确认")与 `evidence_diff[]`(本次新增 / 删除的 evidence_paths)。
4. 上次 run_id / timestamp 写入 `previous_run_id` / `previous_timestamp`。
5. 增量模式但前序无 baseline → `evolution.previous_report_path = null`,只记当次快照,不写 transitions(intake-and-scope 已在 LIMITATIONS_NO_BASELINE 中提示用户)。

#### 4.6.3 跨项目模式产物布局

`len(scope_summary.project_paths) > 1` 时,按下表分流写入:

| 文件 | 路径 | 内容来源 | 说明 |
| --- | --- | --- | --- |
| 每项目独立报告 | `{output_dir}/{domain}/evidence/per-project/dimension-activation-report-project-{N}.json` | dimension-activator 对项目 N 单独跑出的 report | N=1..M(M=project_count);保留各项目原始 state |
| 主统一 map | `{output_dir}/{domain}/evidence/unified-activation-map.json` | `temp/{run_id}-unified-activation-map.json`(来自 cross-project-aggregator) | schema=unified-activation-map.v1 |
| 主激活报告 | `{output_dir}/{domain}/evidence/dimension-activation-report.json` | 跨项目模式下**复用** unified map 的 `dimensions[]`(含 `unified_state` + `partial_activated`),并在头部 `cross_project.enabled = true` + `unified_map_ref` 指向上面主 map | 团队级视角的总报告 |
| 项目特有差异说明 | `{output_dir}/{domain}/evidence/project-specific-divergence.md` | cross-project-aggregator 渲染 | 仅 partial_activated 维度 |

跨项目模式下 `merge_summary.activation_report_path` 指向 **主激活报告**,`merge_summary.cross_project_summary.unified_map_ref` 指向 **主统一 map**。

#### 4.6.4 失败处理

| 失败模式 | 错误码 | 处理 |
| --- | --- | --- |
| temp 源文件不存在 | `ACTIVATION_REPORT_TEMP_MISSING` | 停止写入,要求 dimension-activator 重跑 |
| 写入目标目录不可写 | `ACTIVATION_REPORT_PERSIST_DENIED` | 写 review-summary warning,不阻塞其它 step,但记入 `pending_human_actions` |
| 跨项目模式 unified map 缺失 | `UNIFIED_MAP_MISSING` | 停止持久化主报告,per-project 报告仍写入(单项目视角降级仍可用) |
| git 命令不可用 / 非 git 仓库 | (非阻塞) | `last_commit` 三字段全 null + 写 warning;允许 evolution.transitions 为空 |

#### 4.6.5 Self-check（4.6 完成后）

- [ ] `evidence/dimension-activation-report.json` 存在且 `schema == "activation-report.v1"`
- [ ] `summary` 5 计数与 `merge_summary.activation_summary` 数值一致
- [ ] 单项目模式:`cross_project.enabled = false` 或字段缺省
- [ ] 跨项目模式:`evidence/per-project/dimension-activation-report-project-{N}.json` 数等于 `project_count`
- [ ] 跨项目模式:`evidence/unified-activation-map.json` 存在且 schema=unified-activation-map.v1
- [ ] 增量模式:`evolution.previous_report_path` 与 `evolution.transitions[]` 至少一项非空(除非 LIMITATIONS_NO_BASELINE)
- [ ] `merge_summary.activation_report_path` 指向落盘后的正式路径,而非 temp/

### Step 4.7 — Phase 1 Lineage / Owner Queue / Coverage Summary

`routing_profile == phase1-full-auto` 时,每个 batch 合并后必须写入或追加：

| 产物 | 路径 | 说明 |
| --- | --- | --- |
| lineage ledger | `{target_domain_dir}/lineage-ledger.json` | 记录 evidence → standard/pending/conflict/AI/review/index 的派生边,不复制规则正文 |
| owner decision queue | `{target_domain_dir}/owner-decision-queue.json` | 列出 auto-active、pending、conflict、stale-auto-active、owner-rejected 的待裁定/终态项 |
| coverage summary | `temp/{run_id}-review-summary.md` | 聚合 profile 矩阵内覆盖、low-confidence 覆盖、skipped/blocked gap、blind_spots |

Phase 1 lineage 最小字段集:

```yaml
lineage_minimum:
  evidence_id: ""
  source_doc: ""
  section_title: ""
  derived_view_type: ""
  gate_result: ""
  upgrade_mode: ""
  deterministic_occurrence_count: null
  authority_scope: ""
  last_evidence_confirmed_run: ""
```

Phase 1 owner queue 最小字段集:

```yaml
owner_queue_item:
  locator: "{source_doc}「{section_title}」"
  current_status: "auto-active | pending-confirmation | conflict | stale-auto-active | owner-rejected"
  owner_queue_action: "review-auto-active | confirm-or-reject | resolve-conflict | review-stale-auto-active | no-action-terminal | security-review"
  evidence_ids: []
  risk_tags: []
  blocking_reason: ""
  requires_security_review: false
```

### Step 5 — 候选索引产物处理

```yaml
candidate_handling:
  rules_index:
    dest: "temp/{run_id}-rules-index-candidate.json"
    status: candidate
    must_not_overwrite: [".index/rules-index.json"]

  llms:
    dest: "temp/{run_id}-llms-candidate.txt"
    status: candidate
    must_not_overwrite: ["llms.txt"]

  ai_context_pack:
    dest: "temp/{run_id}-ai-context-pack.md"
    indexable: false
    must_not_overwrite: []
```

所有候选文件都需在文件顶部标注：`> 候选产物，需人工确认后合并到正式索引。`

### Step 6 — Self-check（写入后）

- [ ] 无任何 `owner-confirmed-active` / legacy `active` 规则被修改或覆盖
- [ ] 无任何 `draft` 规则被直接替换（只追加或写入 merge-suggestions）
- [ ] `conflicts.md` 包含所有 `target_state: conflict` 的规则，含严重度标注
- [ ] `pending-confirmation.md` 包含所有 `target_state: pending-confirmation` 的规则；Phase 2 另包含所有 `dimension_state: pending-confirmation` 的维度，含 `promotion_criteria`
- [ ] 候选索引产物均有 `candidate` 标记，未覆盖正式文件
- [ ] `merge_summary.written_files` 列出所有实际写入的文件
- [ ] `pending_human_actions` 列出所有需要负责人手动操作的项目
- [ ] evidence 编号无重复（追加了 `existing_index.evidence_ids` 后验证）

**Phase 1 full-auto self-check**:

- [ ] `merge_summary.routing_profile == phase1-full-auto`
- [ ] `merge_summary.activation_report_source == null` 且 `merge_summary.activation_report_path == null`
- [ ] 本 run temp/evidence 输出中没有 `activation-report.json`
- [ ] 所有规则按 `target_state` 路由；不要求 `dimension_id` / `dimension_state`
- [ ] `target_state: auto-active` 规则写入 standard、ai-rules 默认执行段、review checklist、lineage ledger 和 owner queue
- [ ] `target_state: draft` 规则不进入 ai-rules 默认强制执行段
- [ ] `target_state: stale-auto-active` / `owner-rejected` 已移出默认执行路径并进入 owner queue
- [ ] lineage ledger 覆盖每条写入/派生规则,字段含 `evidence_id`、`source_doc`、`section_title`、`derived_view_type`、`gate_result`
- [ ] owner decision queue 覆盖所有 auto-active、pending、conflict、stale-auto-active、owner-rejected 项
- [ ] `rule_evolution` 标注 added / evidence_changed / superseded / stale_active_needs_owner_review 或显式 `LIMITATIONS_NO_BASELINE`

**Phase 2 dimension-aware self-check**:

- [ ] 没有 `dimension_state == "candidate"` 的 decision 进入 standard-/ai-rules.md/review-checklist.md（仅 overview §9）
- [ ] 没有 `dimension_state == "pending-confirmation"` 的 decision 进入 standard-/ai-rules.md（仅 pending-confirmation.md）
- [ ] 所有 `dimension_state == "shallow"` 的规则在 standard 中带 low-coverage 标注，且在 ai-rules.md 中带 warning
- [ ] `overview.md` §9 已建段（即使 candidate=0 也保留标题）
- [ ] §9 未激活地图条目按 layer 分组，且 dimension_id 升序
- [ ] §9 历史 candidate 条目未被删除（append-only / soft-archive 验证）
- [ ] `merge_summary.activation_summary` 5 个计数与 `activation_report.dimensions[]` 实际分布一致
- [ ] `merge_summary.activation_report_source` 指向有效 temp 输入路径
- [ ] `merge_summary.activation_report_path` 指向 `evidence/dimension-activation-report.json` 已落盘文件（U17 / R54 强制持久化）
- [ ] 跨项目模式 `evidence/per-project/dimension-activation-report-project-{N}.json` 数等于 `project_count`
- [ ] 跨项目模式 `evidence/unified-activation-map.json` 存在且 schema=`unified-activation-map.v1`
- [ ] 增量模式 `evidence/dimension-activation-report.json.evolution` 含态变迁记录或显式标注 `LIMITATIONS_NO_BASELINE`
- [ ] `existing_index.rule_locators[]` 每条 Phase 2 locator 都包含 `dimension_id` 与 `dimension_state` 字段

### Step 7 — Run Summary 输出（每 batch 执行后）

每个 batch 合并完成后追加到 `run_log`：

```yaml
run_log_entry:
  batch_id: ""
  status: completed | skipped | failed
  skip_reason: null
  written_files: []
  new_sections: []       # standard-{sub_domain}.md 新增的章节标题
  evidence_count: 0
  pending_count: 0
  conflict_count: 0
```

### Step 8 — Review Summary 生成（所有 batch 完成后，auto 模式执行一次）

所有 batch 循环结束后，生成 `temp/{run_id}-review-summary.md`（见模板 `assets/review-summary-template.md`）：

```
`temp/{run_id}-review-summary.md` 包含：

1. 执行概览
   - run_id、执行时间、处理 batch 数、成功/跳过/失败统计

2. 新增/更新的规范文档
   - 每份文档：文件名 + 章节清单 + evidence 数量

3. 需要审查的标记项
   - FORBIDDEN 标注规则（需负责人确认有效性）
   - 置信度 low 的推断（需确认是否准确）
   - industry 域规则（需行业负责人确认）

4. 待处理清单
   - pending-confirmation.md 中的所有条目（附 promotion_criteria）
   - conflicts.md 中的所有冲突（附严重度 breaking/warning/info）
   - merge-suggestions.md 中的相似规则建议

5. 跳过的 batch
   - batch_id + skip_reason + 如何解决（补充哪些 evidence 或确认）

6. 下一步行动指引
   - `auto-active` → 已进入默认执行路径；owner 可事后确认、否决或降级
   - `draft` → 可阅读/参考,但不作为默认强制执行
   - `owner-confirmed-active` → 仅 owner 手动确认产生；本流程不自动发布
   - 不认可 auto-active → owner 标记 `owner-rejected`,下次运行移出执行路径
   - conflict → 手动裁定保留哪个版本
   - pending → 补充 evidence 或负责人确认后重新运行
```

所有 batch 完成后，将 `temp/{run_id}-review-summary.md` 复制/重命名为 `{output_dir}/{domain}/review-summary.md`（文件名固定，不含 run_id），方便 orchestrator 在流程结束后确定性读取。

### Step 9 — `final_status` 计算（U24 force-rebuild 必读）

所有 batch 合并完成后,在 Run Summary 输出前必须计算 `final_status`,供 force-rebuild orchestrator step 10 dispatcher 分流:

| final_status | 命中条件(任一) | final_status_reason | force-rebuild 后续 |
| --- | --- | --- | --- |
| `failed` | 任一 batch `status: failed`(写入异常 / 路径不可写)| `BATCH_WRITE_FAILED` | 跳过 validate.sh,直接 step 10b 回滚 |
| `failed` | quality_gate_decisions[] 出现 `final_gate_decision: blocked` | `QUALITY_GATE_BLOCKED` | step 10b 回滚 |
| `failed` | conflicts.md 新增 ≥ 1 条 breaking 严重度冲突 | `BREAKING_CONFLICT_INTRODUCED` | step 10b 回滚 |
| `failed` | Phase 2 activation_report 与 quality_gate_decisions[].dimension_state 不一致 | `STATE_INCONSISTENCY` | step 10b 回滚 |
| `failed` | Phase 1 `auto-active` 缺 lineage 判据快照或 deterministic occurrence | `AUTO_ACTIVE_LINEAGE_INCOMPLETE` | step 10b 回滚 |
| `partial` | 任一 batch `status: skipped`(skip_reason ≠ "not in diff scope") | `BATCH_SKIPPED_WITH_GAPS` | force-rebuild 视为失败,step 10b 回滚(force-rebuild 要求完整重生) |
| `partial` | shallow_overrides_applied > 0 / pending_overrides_applied > 0 但用户未确认 | `MANUAL_OVERRIDE_PENDING` | force-rebuild 视为失败,step 10b 回滚 |
| `success` | 全部 batch `status: completed`,无 blocked,无 breaking,无 skipped | — | 进入 validate.sh + step 10a |

**force-rebuild 严格模式**:本 agent 输出 `partial` 或 `failed` 时,force-rebuild orchestrator 一律走 step 10b 回滚(不接受部分成功)。普通 append 模式可接受 `partial`,只在 review-summary 标注。

写入位置:`merge_summary.final_status` + `merge_summary.final_status_reason`(必填)。

## 失败模式映射

| 命中条件 | 处理 |
| --- | --- |
| 写入前检测到与 owner-confirmed-active / legacy active 冲突 | `TARGET_CONFLICT`;进 conflicts.md;不覆盖 active |
| 目标文件无 Front Matter | 写入 merge-suggestions，不直接修改历史文件头 |
| quality_gate_decision 为空 | 不写入任何规范文件；输出 merge_summary 说明原因 |
| dry_run: high risk 且未确认 | 暂停；输出 dry_run_plan；等待确认 |
| activation_report.json 缺失且 `review_report.review_profile == phase1-full-auto` | Phase 1 正常路径；跳过 dimension gate,按 `target_state` 路由 |
| activation_report.json 缺失且不是 Phase 1 profile | `ACTIVATION_REPORT_MISSING_WITHOUT_PHASE1`；停止写入 |
| activation_report.json 存在但 schema 不匹配 | `ACTIVATION_REPORT_SCHEMA_INVALID`；停止写入，要求重跑 dimension-activator |
| activation_report.run_id 与当前 run 不一致 | `ACTIVATION_REPORT_RUN_MISMATCH`；停止写入 |
| Phase 1 run 产出 activation-report.json | `PHASE1_ACTIVATION_REPORT_LEAK`;停止并要求清理错误产物 |
| auto-active lineage 缺 deterministic occurrence / upgrade_mode / authority_scope | `AUTO_ACTIVE_LINEAGE_INCOMPLETE`;停止写入默认执行派生视图 |
| candidate 维度的决策被路由到 standard/ai-rules/review-checklist | `CANDIDATE_LEAKED_TO_STANDARD`；停止；不写入；提示 P8 失职 |
| pending-confirmation 维度被强制为 auto-active / auto-activate | `PENDING_FORCED_TO_ACTIVE`；停止；要求 review 重跑 |
| shallow 维度缺 low-coverage 标注或 keep-draft-low-coverage 不一致 | `SHALLOW_MISSING_LOW_COVERAGE`；停止；要求 review 重跑 |
| overview 文档不存在且 skeleton 加载失败 | `OVERVIEW_SKELETON_MISSING`；标记 §9 写入失败；其它路由继续；记入 pending_human_actions |
| §9 历史 candidate 条目意外缺失（说明前次写入有 bug） | `OVERVIEW_SECTION_9_REGRESSION`；记入 warnings 但不阻塞；要求人工核查 |
| activation-report temp 源文件不存在（Step 4.6） | `ACTIVATION_REPORT_TEMP_MISSING`；停止持久化；要求 dimension-activator 重跑 |
| 落盘目录不可写（Step 4.6） | `ACTIVATION_REPORT_PERSIST_DENIED`；写 review-summary warning + `pending_human_actions`；不阻塞其它 step |
| 跨项目模式 unified map 缺失（Step 4.6） | `UNIFIED_MAP_MISSING`；停止主报告写入；per-project 子报告仍允许落盘 |

## 必须做

1. 写入前建立完整 `existing_index`，防止意外覆盖。
2. 所有写入操作都是追加（append），不替换已有内容。
3. 候选索引产物标记 `candidate`，不覆盖正式文件。
4. 记录每次运行的 `merge_summary`（包含 AI 使用警告、负责人确认项、routing_profile；Phase 2 另含 activation_summary 三态计数）。
5. 首次大批量合并前建议执行 `dry_run: true`。
6. **Phase 1 每次合并都必须更新 lineage ledger 与 owner decision queue**；auto-active 必须带闸判据快照。
7. **Phase 2 每次合并完成都必须更新 `overview.md` §9 未激活维度地图**——AE7 强制段，即使 candidate=0 也保留章节标题。
8. **Phase 2 rule_locators[] 每条都必须带 `dimension_id` 与 `dimension_state`**；Phase 1 只要求 `target_state` 与 locator。
9. **Phase 2 激活态-决策一致性强校验**（Step 1.5）：candidate 不进 standard、pending 不变 active、shallow 必带 low-coverage——任一违反立即抛错停止写入。
10. **Phase 2 §9 历史 candidate 条目永久保留**（append-only / soft-archive）；即使本 run 维度变 activated，也只在「最近更新」列追加 `→ activated since {run_id}`，不删除原条目。
11. Phase 2 activation_report.json 的 temp 输入只透传到 `merge_summary.activation_report_source`；review-summary 对外引用必须优先使用 `merge_summary.activation_report_path`。
12. **Phase 2 每次 run 必须执行 Step 4.6 把 activation-report 持久化到 `evidence/dimension-activation-report.json`**（R54 / U17 强制；落盘路径回写 `merge_summary.activation_report_path`）；增量模式生成 `evolution{}` 段；跨项目模式同时落盘 per-project + unified map + 主报告三件套。

## 禁止做

1. 不得覆盖 `owner-confirmed-active` / legacy `active` 规则。
2. 不得覆盖已有 `draft` 规则（只追加 evidence 或写 merge-suggestions）。
3. 不得删除历史 evidence 条目。
4. 不得把 `pending-confirmation` 写入 `ai-rules.md §2` 可执行段。
5. 不得默认发布候选索引产物为正式 `.index/rules-index.json` 或根 `llms.txt`。
6. 不得在没有完整 `existing_index` 的情况下执行写入。
7. **Phase 2 不得本地重新计算 dimension_state**——activation_report 与 quality_gate_decisions[].dimension_state 是唯一权威源，merge 阶段不得擅自调整。
8. **Phase 2 不得把 candidate 维度规则写入 standard/ai-rules.md/review-checklist.md**——candidate 维度只能进 overview §9 地图。
9. **不得把 pending-confirmation 强制升为 owner-confirmed-active 或 auto-active**——Phase 1/2 都只能写 pending-confirmation.md。
10. **Phase 2 不得跳过 Step 4.5 §9 写入**——即使本 batch 全部激活，也必须校验 §9 段标题存在。
11. **Phase 2 不得删除 overview §9 中的历史 candidate 条目**（append-only 铁律），只能 soft-archive 标注 `→ activated since {run_id}`。
12. **Phase 2 不得在 §9 表格中混入 activated/baseline/shallow/pending 维度**——§9 仅展示 candidate 状态。
13. **Phase 1 不得生成或持久化 activation-report.json**。
