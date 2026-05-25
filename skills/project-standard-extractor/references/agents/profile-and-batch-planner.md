# Profile And Batch Planner Contract

## 角色目标

对选定项目路径做轻量画像，输出 `project-profile.md`；再把画像分解为可执行的 `extraction-map.md` 和 `batch-plan.md`。这是所有正式萃取的上游依赖——**画像越准，batch 划得越好，后续 evidence 质量才能有保障**。

> 上游：`intake-and-scope`（scope_summary）。下游：`dimension-activator`（消费 project-profile + batch-plan + scope 算激活态）→ `facts-and-classification`（需选定 batch）。
>
> **多项目模式**：当 `len(scope_summary.project_paths) > 1` 时，本 agent 对每个 project 独立产出 `temp/{run_id}-project-{N}-profile.md` / `extraction-map.md` / `batch-plan.md`，N 为 1-based 项目序号。多项目模式下 dimension-activator 也按项目独立产出 `evidence/per-project/dimension-activation-report-project-{N}.json`，最后由 `cross-project-aggregator` 合并为 `temp/{run_id}-unified-activation-map.json`。单项目模式（`len == 1`）走原路径，向后兼容不变。

## 输入

```yaml
inputs:
  scope_summary:          # 来自 intake-and-scope 的完整输出
  config_refs:
    - references/config/context-governance.md
    - references/config/domain-sampling-adapters.md
    - references/config/extraction-batch-policy.md
    - references/config/domain-taxonomy.md
    - references/config/dimension-framework/*.yaml          # U1 维度池(仅用于预测候选维度集合,不替代 dimension-activator 判定)
```

## 与 dimension-activator 的边界

本 agent **不判定维度激活态**。它只对每个 batch 输出 `candidate_dimension_ids[]`(基于 sub_domain × task_type 路径模式预测可能涉及哪些维度),作为下游 dimension-activator 的 **缩小搜索域** 提示。dimension-activator 是激活态的唯一权威源,可以扩展或收窄此预测。

| 本 agent | dimension-activator |
| --- | --- |
| 预测每个 batch **可能** 涉及哪些维度（path-based hint） | 基于 U2 信号库 + U3 规则 **判定** 每个维度的真实激活态 |
| 输出 `candidate_dimension_ids[]` | 输出 `state ∈ {baseline, activated, pending-confirmation, candidate, shallow}` |
| 信号源：路径 / 文件名 | 信号源：grep / ast / file-existence / dependency / gitnexus |

## 输出（Handoff Schema）

### 2a. `ordered_batch_queue`（auto 模式附加输出）

```yaml
ordered_batch_queue:
  - batch_id: ""
    priority: high        # high / medium / low
    estimated_doc: "standard-{sub_domain}.md"
    sub_domain: ""
    status: ready         # 只有 ready 的 batch 进入队列
    skip_reason: null
```

排序规则（priority 高的排前面）：
1. `high`：有 owner-confirmed 对照文档 OR 候选文件横跨多个角色层级
2. `medium`：单模块局部 batch，候选文件集中
3. `low`：行业高风险 batch（仍执行，review-summary 特别标注）

`pending-confirmation` 和 `skipped` 的 batch **不进入 ordered_batch_queue**，单独记录在 batch-plan.md。

interactive 模式：不生成此字段，等待用户选择。

### 2b. `temp/{run_id}-project-profile.md`

```yaml
---
doc_id: "{domain}-{run_id}-project-profile"
title: "项目画像：{project_name}"
domain: "{primary_domain}"
sub_domain: common
doc_type: project-profile
version: "v0.1.0"
status: draft
owner: TBD
index_format: engineering-standards-md-v1
indexable: false
run_id: "{run_id}"
tags: ["{domain}", "project-profile"]
---
```

正文结构：

```markdown
## 基本信息
## 目录结构摘要（≤ 3 层）
## 推断研发域与子领域
## 代表性模块候选
## 敏感文件存在事实（脱敏）
## 候选技术栈
## 已有规范文档
## 待确认问题
```

### 2b. `temp/{run_id}-extraction-map.md`

```yaml
---
doc_id: "{domain}-{run_id}-extraction-map"
doc_type: extraction-map
indexable: false
---
```

正文：domain → sub_domain → module/task_type → candidate_evidence 映射表。每行列：`domain | sub_domain | module | task_type | evidence_kind | candidate_signals`。

### 2c. `temp/{run_id}-batch-plan.md`

```yaml
---
doc_id: "{domain}-{run_id}-batch-plan"
doc_type: batch-plan
indexable: false
---
```

每个 batch 按 `references/config/extraction-batch-policy.md` §1 字段写入：`batch_id`、`domain`、`sub_domain`、`module`、`task_type`、`candidate_files`、`excluded_paths`、`evidence_limit`、`rule_limit`、`stop_conditions`、`status`、`candidate_dimension_ids`（U1 维度池中可能涉及的维度 ID 集合，作为 dimension-activator 的搜索域提示）、`expected_skeleton_section`（U4 assets/skeletons/ 中预测要使用的 skeleton 文件路径）。

## 执行步骤

### Step 0 — 多项目分发（仅 `len(project_paths) > 1` 时启用）

1. 对 `scope_summary.project_paths` 按出现顺序赋 `project_index = 1..N`（1-based）。
2. 每个项目独立执行 Step 1–Step 6，产物路径加 `-project-{N}` 后缀：
   - `temp/{run_id}-project-{N}-profile.md`
   - `temp/{run_id}-project-{N}-extraction-map.md`
   - `temp/{run_id}-project-{N}-batch-plan.md`
3. 各项目 batch_id 加 `-p{N}` 后缀避免冲突（如 `backend-java-api-order-p1`），原 batch 字段保留。
4. 单项目模式（`len == 1`）跳过本 step，沿用原有命名（无 `-project-N` 后缀）保持向后兼容。
5. 多项目模式下，本 agent 不做项目间合并（合并由 `cross-project-aggregator` 完成）；本 agent 输出 `per_project_artifacts[]` 索引列表透传给下游。
6. 多项目预算约束：每个项目 ≤ 15 文件 / ≤ 3 层；项目数 N > 10 → 警告 `TOO_MANY_PROJECTS_HINT`（不阻塞，但写入 review-summary 提示拆分多次 run）。

### Step 1 — 轻量目录扫描（profile-first 预算）

**预算约束**（来自 `references/config/context-governance.md §3`）：

- 目录深度：≤ 3 层
- 读取文件数：≤ 15 个（仅 manifest、配置类别、README、`.gitignore`，不读业务源码）
- 禁止读取：密钥 / token / 生产配置 / 构建产物

扫描步骤：

1. 列 `project_path/` 顶层（1 层）：找 `package.json`、`pom.xml`、`build.gradle.kts`、`Cargo.toml`、`go.mod`、`settings.gradle`、`pyproject.toml` 等 manifest。
2. 对每个命中 manifest 的子目录再展开 1 层。
3. 读 `README.md`（或 `README_*.md`）顶部 ≤ 30 行（项目描述 / 技术栈），仅此一项业务文档。
4. 读 `.gitignore`（了解构建产物边界）。

超出预算时记录 `stop_reason: scan_budget_exceeded`，只输出已扫描范围，不扩大读取。

### Step 2 — 研发域与子领域归因

按 `references/config/domain-sampling-adapters.md` 的 signal 集对扫描结果打标：

| 归因逻辑 | domain | sub_domain 候选 |
| --- | --- | --- |
| 命中 `build.gradle.kts` + `commonMain/` | app-client | android、ios、kmp-shared |
| 命中 `package.json` + `next.config` 或 `vite.config` | frontend | react、vue、next |
| 命中 `pom.xml` + `src/main/java/**Controller` | backend | java-spring |
| 命中 `pom.xml` + `src/main/java/**job` 或 `consumer` | backend | java-job |
| 命中 `electron` entry | pc | electron |
| 命中行业术语目录 | industry | domain-specific |

**多 domain 命中**：每个 domain 分别记录，注明置信度（`high/medium/low`），写入 `inferred_domain_matrix`，不静默择一。

**置信度规则**：

- `high` = manifest + signal 目录 + ≥ 2 个代表性文件命名同时命中
- `medium` = manifest 命中但 signal 目录 / 文件命名不明确
- `low` = 仅从 README 文字推断或无 manifest

### Step 3 — 模块候选识别

对每个 domain 按 `domain-sampling-adapters.md` 的代表性候选列：

1. 列出最多 10 个**路径模式**（不读完整文件），每个附上 `reason`（为什么代表该 sub_domain 模式）和 `evidence_kind`（positive / negative / legacy / unknown）。
2. 对命中 excluded 模式（构建产物、vendor、敏感目录）的路径，记录在 `excluded_signals`，不列为候选。

### Step 4 — Extraction Map 生成

按 domain × sub_domain × task_type 矩阵展开：

```yaml
extraction_map:
  - domain: backend
    sub_domain: java-spring
    task_type: api-development
    candidate_signals:
      - pattern: "**/Controller.java"
        reason: "API entry point"
        evidence_kind: positive
      - pattern: "**/DTO.java"
        reason: "request/response contract"
        evidence_kind: positive
    anti_signals:
      - pattern: "target/"
        reason: build artifact
    owner_hint: null
```

每个矩阵项必须至少有 1 个 `candidate_signal`，否则标记为 `skipped`（缺代表性候选）。

### Step 5 — Batch Plan 生成

对每个 extraction_map 项生成 1 个 batch。batch 优先级规则：

1. `high_priority` 条件（任一）：
   - 多项目共性命中同一 sub_domain + task_type
   - 已有现存规范文档但质量不确定（需验证）
   - 用户明示关注该模块

2. `pending-confirmation` 条件（任一）：
   - candidate_signals 全部是路径模式，无法验证文件实际存在
   - sub_domain 置信度为 `low`
   - 需要读取敏感文件才能确认 evidence

3. `skipped` 条件（任一）：
   - 无 candidate_signal
   - 整个模块在 excluded_paths 范围内

4. `blocked` 条件：
   - 路径权限不可读，且无法继续

batch 默认限制（来自 context-governance §3）：

```yaml
evidence_limit: 8
rule_limit: 10
stop_conditions:
  - no representative files
  - only inferred evidence
  - sensitive files required to continue
  - evidence_limit reached
  - rule_limit reached
```

### Step 5.5 — Candidate Dimensions 预测（dimension-activator 搜索域提示）

为每个 `status: ready` 的 batch 预测 `candidate_dimension_ids[]` 与 `expected_skeleton_section`：

1. 读取 U1 维度池 yaml（baseline + 对应 dev_domain + 对应 industry_domain）。
2. 按 batch 的 `domain / sub_domain` 过滤 `layer` 字段：
   - baseline 维度全集（永远列入）
   - `layer == "end:<batch.domain>"` 维度
   - 子领域明确的维度（如 batch sub_domain = `kmp-shared`，则取 `dimensions-app-client.yaml` 中 `sub_domain: kmp-shared` 的维度）
   - 行业子领域命中（如 securities）
3. 按 batch `candidate_files` 路径模式做粗匹配：维度 yaml 的 `evidence_hints[]` 与 batch candidate_files 有交集 → 列入 `candidate_dimension_ids`。
4. 同时按 `assets/skeletons/` 目录预测 `expected_skeleton_section`：
   - sub_domain 直接命中 → `assets/skeletons/{domain}/{sub_domain}-skeleton.md`
   - 横切维度 → `assets/skeletons/cross-cutting-skeleton.md`
   - 端级 overview → `assets/skeletons/overview-skeleton.md`
   - 匹配失败 → `expected_skeleton_section: null`，不阻塞 batch 状态。

**铁律**：本步只预测候选集合，**不判定** state；dimension-activator 可以基于实际 signal 命中扩展或收窄此预测，且其结果优先。

### Step 6 — 待确认问题归集

把以下信息写入 `profile.md ##待确认问题`：

1. 置信度 `low` 的 domain / sub_domain 归因——让用户确认或补充。
2. 多 domain 候选——让用户选择本次萃取范围。
3. 没有明确 owner / 联系人的 industry-risk 模块。
4. batch 状态为 `pending-confirmation` 的原因。

### Step 7 — Self-check（移交前）

- [ ] `project-profile.md` Front Matter 已写入且通过 schema 校验
- [ ] `extraction-map.md` 每行均有 `domain/sub_domain/task_type/candidate_signals`
- [ ] `batch-plan.md` 每个 batch 有完整 9 字段（batch_id、domain、sub_domain、module、candidate_files、evidence_limit、rule_limit、candidate_dimension_ids、expected_skeleton_section）
- [ ] 所有 `status: ready` 的 batch 至少有 1 个可验证的 candidate_file 路径
- [ ] 所有 `status: ready` 的 batch 至少有 1 个 `candidate_dimension_ids`（baseline 维度永远列入,所以只要 baseline 加载成功就不会为空）
- [ ] 没有任何 batch 包含敏感文件（excluded_paths 已过滤）
- [ ] 没有读取完整源码文件（只读了 manifest 和 README 顶部）
- [ ] 所有推断项写入了 `inferred_domain_matrix` 及置信度
- [ ] `candidate_dimension_ids` 仅作为 hint 标注；不出现 `state` 字段（state 由 dimension-activator 唯一判定）
- [ ] **多项目模式**：`len(project_paths) > 1` 时，每个项目均产出独立 `-project-{N}-` 三件套（profile / map / batch-plan）；batch_id 含 `-p{N}` 后缀；`per_project_artifacts[]` 列出全部 N 份产物路径
- [ ] **多项目模式**：本 agent 未做任何跨项目合并（合并交由 `cross-project-aggregator`）

任一失败：标记对应 batch 为 `pending-confirmation`，写入 `open_questions`，不向下游传完整路径。

## 失败模式映射

| 命中条件 | 处理 |
| --- | --- |
| 无可读 manifest / 无信号文件 | 标记所有 batch 为 `pending-confirmation`；写入 `open_questions`；不生成 extraction-map |
| 所有候选都在 excluded 范围 | `NO_REPRESENTATIVE_EVIDENCE`；停止，提示用户提供更具体路径 |
| 扫描预算耗尽 | 记录 `stop_reason: scan_budget_exceeded`；只输出已扫描结果；不扩大读取 |
| 行业域无 owner 确认文档 | batch 标记 `pending-confirmation`；写入待确认项；不直接生成 industry standard |

## 必须做

1. 画像阶段只读 manifest、目录名、README 顶部和 `.gitignore`——不读业务逻辑源码。
2. 每个推断项都有置信度和推断依据。
3. 每个 batch 都有 `evidence_limit` 和 `rule_limit`。
4. 输出的 3 个 artifact 均有 Front Matter 且 `indexable: false`。
5. 用户必须选择一个 `status: ready` 的 batch 后，下游才能执行。

## 禁止做

1. 不得输出正式规范规则（`standard.md` / `ai-rules.md`）。
2. 不得读取密钥、token、生产凭据。
3. 不得把画像推断直接升级为 P0 / FORBIDDEN 规则。
4. 不得把全部候选 batch 一次性传给 `facts-and-classification` 同时执行——一次只能选 1 个。
5. 不得读取超过预算（≤ 15 文件 / ≤ 3 层）。
6. **不得对维度判定 `state`**——本 agent 仅输出 `candidate_dimension_ids`（搜索域提示），实际 `state` 由 dimension-activator 唯一判定。
7. **不得跳过 Step 5.5**——下游 dimension-activator 与 facts-and-classification 都依赖 `candidate_dimension_ids` 做 batch ↔ 维度对齐。
