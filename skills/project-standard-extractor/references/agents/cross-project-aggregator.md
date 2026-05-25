# Cross-Project Aggregator Contract

## 角色目标

在多项目运行（`len(scope_summary.project_paths) > 1`）下，把每个项目独立产出的 `project-profile + extraction-map + activation-report` 合并为**统一激活 map**，并把项目特有差异写入 `evidence/project-specific-divergence.md`，作为团队级横切规范的输入。

> 上游：`dimension-activator`（每项目独立产出 `activation-report-project-{N}.json`）。下游：`generation` / `review-and-quality-gate` / `merge-coordinator`（按合并后的 dimension_state 写横切规范与项目特有差异）。

## 与其它 agent 的边界

| 本 agent | profile-and-batch-planner | dimension-activator | merge-coordinator |
| --- | --- | --- | --- |
| 仅 `len(project_paths) > 1` 触发 | 永远启用，多项目时分别产出 N 份 profile / map | 永远启用，多项目时分别产出 N 份 activation-report | 永远启用，本 agent 完成后由 merge 写差异列 |
| 输入 N 份 project-profile + activation-report | 输入 scope_summary | 输入 batch + scope + 维度池 + signals | 输入 quality_gate_decisions + activation_report |
| 输出 unified activation map + project-specific-divergence.md | 输出每项目独立 profile / map / batch-plan | 输出每项目独立 activation-report.v1 | 输出 standard / ai-rules / overview §9 |
| 不重新判定单项目激活态 | 不判定激活态 | 唯一激活态判定者 | 不重新判定 state |

**铁律**：本 agent **不**重新判定任一项目内部的 dimension_state——它只在 N 份 activation-report 之间做合并；合并结果通过新增字段 `partial_activated` + 差异说明列表达，单项目原始 state 保留在 `per_project_states[]`。

## 输入

```yaml
inputs:
  scope_summary:                                      # 来自 intake-and-scope，含 project_paths 列表
  per_project_artifacts:
    - project_index: 1                                # 1-based
      project_path: "/path/to/project-a"
      project_name: "project-a"                       # 从路径末段或 manifest 推断
      profile_path: "temp/{run_id}-project-1-profile.md"
      extraction_map_path: "temp/{run_id}-project-1-extraction-map.md"
      batch_plan_path: "temp/{run_id}-project-1-batch-plan.md"
      activation_report_path: "evidence/per-project/dimension-activation-report-project-1.json"
    - project_index: 2
      project_path: "/path/to/project-b"
      ...
  config_refs:
    - references/config/dimension-framework/*.yaml               # 校验 dimension_id 非孤儿
    - assets/project-specific-divergence-template.md
```

## 触发条件

- `len(scope_summary.project_paths) > 1` → 启用本 agent。
- 单项目 (`len == 1`) → **不触发**，跳过本 agent，profile / activation-report 直接走单项目路径，向后兼容不变。

## 输出（Handoff Schema）

### 1. `temp/{run_id}-unified-activation-map.json`

```json
{
  "schema": "unified-activation-map.v1",
  "run_id": "{run_id}",
  "project_count": 3,
  "projects": [
    { "index": 1, "name": "project-a", "path": "/path/to/project-a" },
    { "index": 2, "name": "project-b", "path": "/path/to/project-b" },
    { "index": 3, "name": "project-c", "path": "/path/to/project-c" }
  ],
  "dimensions": [
    {
      "dimension_id": "EA-Backend-06",
      "layer": "end:backend",
      "sub_domain": "java-spring",
      "unified_state": "activated",
      "partial_activated": false,
      "per_project_states": [
        { "project_index": 1, "state": "activated", "depth_indicator": "deep", "evidence_count": 6 },
        { "project_index": 2, "state": "activated", "depth_indicator": "deep", "evidence_count": 5 },
        { "project_index": 3, "state": "activated", "depth_indicator": "shallow", "evidence_count": 1 }
      ],
      "rationale": "all 3 projects activated; min depth=shallow → unified shallow when shallow_min_strategy=conservative"
    },
    {
      "dimension_id": "SEC-03",
      "layer": "industry:securities",
      "unified_state": "partial_activated",
      "partial_activated": true,
      "per_project_states": [
        { "project_index": 1, "state": "activated", "depth_indicator": "deep" },
        { "project_index": 2, "state": "candidate", "depth_indicator": null },
        { "project_index": 3, "state": "candidate", "depth_indicator": null }
      ],
      "rationale": "only project-1 activated; partial_activated=true → 写入差异列",
      "divergence_summary": "project-a 命中 RiskLimitChecker；project-b/c 未命中风控信号"
    }
  ],
  "merge_strategy": "permissive",
  "stats": {
    "unified_baseline": 12,
    "unified_activated": 18,
    "unified_partial_activated": 5,
    "unified_pending": 2,
    "unified_shallow": 3,
    "unified_candidate": 7
  }
}
```

### 2. `evidence/project-specific-divergence.md`

按 `assets/project-specific-divergence-template.md` 渲染，含：

- 每个 `partial_activated` 维度一节
- 列出哪些项目激活、哪些项目未激活
- 项目特有的代表性 evidence（脱敏路径）
- 给端规范作者的"差异列填充建议"

## 执行步骤

### Step 1 — 输入校验

1. 校验 `len(per_project_artifacts) == len(scope_summary.project_paths)`，缺失任一 activation-report → `MISSING_PER_PROJECT_REPORT`，停止。
2. 校验每份 activation-report 的 `schema == "activation-report.v1"`，否则 `SCHEMA_MISMATCH` 停止。
3. 校验各项目 `run_id` 一致（同一次跨项目 run 的子产物），否则 `RUN_ID_MISMATCH` 停止。

### Step 2 — 维度集合归一

1. 收集所有项目 activation-report.dimensions[].dimension_id，做集合并集。
2. 对每个维度，建 `per_project_states[]`：未在某项目 report 出现 → 视为 `state: candidate, evidence_count: 0`（即该项目维度池中没命中信号）。
3. 校验所有 `dimension_id` 存在于 `references/config/dimension-framework/*.yaml`，孤儿 ID 写入 `warnings`，不进 unified map。

### Step 3 — 合并策略

每个维度按以下规则计算 `unified_state`（默认 `permissive` 策略，可配 `merge_strategy: strict`）：

| 各项目 state 分布 | permissive (默认) | strict |
| --- | --- | --- |
| 全部 `activated` | `activated`（取最浅 depth：保守对待团队规范深度） | `activated`（同左） |
| 全部 `baseline` | `baseline` | `baseline` |
| 全部 `candidate` | `candidate` | `candidate` |
| 全部 `pending-confirmation` | `pending-confirmation` | `pending-confirmation` |
| 部分 `activated` + 部分非 activated | `partial_activated` + `divergence_summary` | `candidate`（只有团队全员激活才统一激活） |
| 任一 `shallow` + 其它 activated | `shallow`（取最浅深度） | 同 permissive |
| 任一 `pending-confirmation` 其余 candidate | `pending-confirmation`（保留人工确认入口） | 同 permissive |
| 全部 `pending` 或 `pending+candidate` 混合 | `pending-confirmation` | `pending-confirmation` |
| `baseline + candidate` 混合 | `baseline`（baseline 优先） | `baseline` |

**Open Question 锚点**：plan §10.3 第 5 项标注 partial_activated 默认策略由 permissive 起步；strict 模式仅在 config 显式开启。

`partial_activated=true` 时必填：

- `divergence_summary`：≤ 60 字简述哪几个项目激活、哪几个未激活；列出代表性 evidence_path（脱敏）
- 进入 Step 4 渲染到 divergence template

### Step 4 — 项目特有差异渲染

加载 `assets/project-specific-divergence-template.md`，按 unified map 中所有 `partial_activated == true` 的维度渲染：

```markdown
## 维度 {dimension_id}：{dimension_name}

- **layer**: {layer}
- **sub_domain**: {sub_domain | -}
- **激活项目**: project-1 (project-a), project-3 (project-c)
- **未激活项目**: project-2 (project-b)
- **代表性 evidence（仅激活项目）**:
  - project-1: `app/risk/RiskLimitChecker.kt:42`
  - project-3: `service/order/OrderRiskGuard.kt:58`
- **差异说明**: project-2 未实现风控前置校验；如需团队统一要求，必须由各项目负责人确认是否补齐。
- **差异列填充建议**:
  - 横切维度文件 §3 子领域差异对比：「统一要求」列填 "必须做风控前置校验"；「project-b 当前实现」列填 "未实现，需补齐"
  - 写入：`{merge_coordinator}` 在合并 standard-{sub_domain}.md §3 时按本节自动填充
```

未触发 partial_activated 的维度**不**进 divergence.md。

### Step 5 — 横切维度子领域差异收敛

对 `layer ∈ {end:*}` 且 `sub_domain` 字段非空的维度（KMP / Android / iOS / java-spring / java-job 等），把每个项目对应 sub_domain 的激活态汇总成端规范的「统一要求」列输入：

```yaml
cross_cutting_section_3_input:
  - dimension_id: "EA-Client-04"
    sub_domain_states:
      kmp-shared:    activated   # project-a/c 命中
      android:       activated   # project-a 命中
      ios:           candidate   # 无项目激活
    unified_requirement: "数据访问需统一收敛到 Repository + DataSource 两层"
    project_a_state: activated
    project_b_state: candidate
    project_c_state: activated
```

合并 `merge-coordinator` 在写 `standard-{domain}-{sub_domain}.md §3` 时直接消费此结构填充统一要求 + 各子领域差异列（AE11）。

### Step 6 — 性能与超时

- 项目数 N ≤ 10：合并耗时预算 ≤ 5 分钟（不含原 N 项目自身 run 时间）。
- 维度池规模 ≥ 100 时，按 `dimension_id` 分批合并（每批 ≤ 50），保持线性 O(N×D)。
- 单维度合并时间 > 2s → 写入 warnings，不阻塞整体。

### Step 7 — Self-check（移交前）

- [ ] `unified-activation-map.json` `schema == "unified-activation-map.v1"`
- [ ] 维度数 == 各项目 dimensions 集合并集；孤儿 dimension_id 已剔除并写 warnings
- [ ] 所有 `partial_activated == true` 维度均在 divergence.md 有节
- [ ] `per_project_states[*].state` 均与原始 activation-report 一致（未篡改单项目状态）
- [ ] `merge_strategy` 字段非空（默认 `permissive`）
- [ ] 横切维度 `sub_domain_states` 至少覆盖每个项目对应 sub_domain 一次
- [ ] 项目数 == 1 时本 agent 未启用（向后兼容校验）

## 失败模式映射

| 命中条件 | 错误码 | 处理 |
| --- | --- | --- |
| 缺失任一项目 activation-report | `MISSING_PER_PROJECT_REPORT` | 停止，要求 dimension-activator 补齐 |
| `schema != "activation-report.v1"` | `SCHEMA_MISMATCH` | 停止，要求 dimension-activator 重跑 |
| run_id 不一致 | `RUN_ID_MISMATCH` | 停止，要求 intake 用同一 run_id 协调 |
| 项目数 == 1 | （不触发） | 跳过本 agent；单项目走原路径 |
| 项目数 > 10 | `TOO_MANY_PROJECTS` | 停止，建议拆分为多次跨项目 run；overshoot 上限保护 |
| 维度孤儿 ID 占比 > 30% | `ORPHAN_DIMENSIONS_TOO_MANY` | 不停止，但 warnings 提示用户校验 dimension-framework yaml |

## 必须做

1. 单项目原始 state 必须保留在 `per_project_states[]`，不得篡改。
2. `partial_activated == true` 必须在 divergence.md 渲染对应节，不能静默忽略。
3. `divergence_summary` 必须列出激活与未激活项目名（脱敏 path 可省）。
4. `merge_strategy` 默认 `permissive`，strict 必须显式 config 开启并在 unified-map 标注。
5. 横切维度 `sub_domain_states` 必须覆盖每个项目实际命中的 sub_domain，未覆盖即写 candidate。

## 禁止做

1. 不得重新判定任一项目内部 `state`——本 agent 仅做合并，不替代 dimension-activator。
2. 不得把 `partial_activated` 维度直接写入 standard-*.md 主体——必须先经 merge-coordinator 按合并结果决定章节归属。
3. 不得把项目原始路径写入 divergence.md 之外的产物（保护项目隔离）。
4. 不得在 `len(project_paths) == 1` 时启用本 agent——向后兼容铁律。
5. 不得跨 run_id 合并 activation-report——单次跨项目 run 的子产物必须共享 run_id。
