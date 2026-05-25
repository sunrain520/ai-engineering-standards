# Diff Scoper Contract

## 角色目标

在 `extraction_mode=diff` 增量模式下，根据 `git diff` 把变更文件映射到受影响维度集合，并把范围裁剪后的输入透传到下游。**不替换** `profile-and-batch-planner` 的画像产物——而是把"全量画像"收窄到"被本次 diff 触及的维度"。

> 上游：`intake-and-scope`（当 `extraction_mode == diff`）。下游：`profile-and-batch-planner`（消费 `affected_dimensions[]` 与 `changed_files[]` 缩小 batch 候选）。

## 与其它 agent 的边界

| 本 agent | profile-and-batch-planner | dimension-activator |
| --- | --- | --- |
| 只在 `extraction_mode=diff` 启用 | 永远启用（无论 mode） | 永远启用（无论 mode） |
| 输入 `git diff <baseline>..HEAD` + `file-to-dimension-map.yaml` | 输入完整目录扫描 | 输入 batch + scope + 维度池 + signals |
| 输出 `affected_dimensions[]` + `changed_files[]` 缩小 scope | 输出 batch-plan + candidate_dimension_ids[] | 输出 activation-report.json (state 唯一权威源) |
| 不做激活态判定 | 不做激活态判定 | 唯一激活态判定者 |

**铁律**：本 agent 仅产出"哪些维度被本次 diff 触及"——是否激活仍由 dimension-activator 用激活规则 + 信号库判定。

## 输入

```yaml
inputs:
  scope_summary:                   # 来自 intake-and-scope
  extraction_mode: diff            # 必填,本 agent 仅在此值时执行
  diff_baseline:                   # 可选,缺省按下方 Step 1 推断
    type: commit | branch | last-extraction
    ref: <git ref>                 # commit hash / branch name / "main"
  config_refs:
    - references/config/diff-scoper/file-to-dimension-map.yaml
    - references/config/dimension-framework/                     # 用于校验 dimension_id 非孤儿
```

## 输出（Handoff Schema）

### `temp/{run_id}-diff-scope.md`

```yaml
---
doc_id: "{domain}-{run_id}-diff-scope"
doc_type: diff-scope
indexable: false
run_id: "{run_id}"
status: draft
---
```

正文结构：

```yaml
diff_scope:
  baseline:
    type: last-extraction | commit | branch
    ref: "<resolved git ref>"
    resolved_from: |              # 推断依据
      "evidence/dimension-activation-report.json.last_commit"
      | "scope_summary.diff_baseline.ref"
      | "git merge-base main HEAD"
  diff_stats:
    total_changed: 47
    code_files: 35
    test_files: 8
    config_files: 4
    excluded_count: 2             # 命中 sensitive 或 build artifact 模式被剔除
  changed_files:
    - path: "shared/data/repo/OrderRepository.kt"
      change_kind: modified | added | deleted | renamed | copied
      old_path: null              # rename / copy 时填
      hunks_count: 3
      mapped_dimensions: ["EA-Client-04", "D05"]
    - path: "..."
  affected_dimensions:
    - dimension_id: "EA-Client-04"
      mapping_source: "data/**/*Repository*.kt"
      hit_files: 4
    - dimension_id: "D05"
      mapping_source: "...同上..."
      hit_files: 4
  unmapped_files:
    - path: "scripts/legacy-fix.sh"
      reason: "no glob pattern matched"
  affected_sub_domains:           # 推断的子领域,供 batch-planner 缩小 scope
    - domain: app-client
      sub_domain: kmp-shared
    - domain: app-client
      sub_domain: android
  limitations: null               # 例如 shallow clone / non-git repo / no baseline
  fallback_to_full_scan: false    # 任一停止条件命中时降级为全量并标 true
  stop_conditions_hit: []
```

## 执行步骤

### Step 1 — Baseline 解析

按优先级解析 baseline ref：

1. `scope_summary.diff_baseline.ref` 显式指定 → 直接用，校验 `git rev-parse <ref>` 成功。
2. `evidence/dimension-activation-report.json` 存在且 `last_commit` 字段非空 → 用 `last_commit`。
3. `git merge-base main HEAD` 成功 → 用 merge-base。
4. 上述全部失败 → `LIMITATIONS_NO_BASELINE`，写入 `limitations`，`fallback_to_full_scan=true` 移交全量。

任一 ref 不可解析 → `BASELINE_UNRESOLVABLE`，停止本 agent，移交回 intake 让用户选择降级。

### Step 2 — 仓库 / shallow clone 探测

1. 项目根 `.git/` 不存在 → `NON_GIT_REPO`，`fallback_to_full_scan=true`。
2. `git rev-parse --is-shallow-repository` 返回 true → `SHALLOW_CLONE`，限制 baseline 必须 ≥ 仓库 fetch 深度，否则 `fallback_to_full_scan=true`。
3. 工作树有未提交修改：仍可继续，但在 `limitations` 标注 `dirty_worktree: true`。

### Step 3 — diff 提取

执行命令（仅本 agent，每次 run 一次）：

```
git diff --name-status --diff-filter=ACDMR <baseline>..HEAD
git diff --numstat <baseline>..HEAD
```

按 `--name-status` 解析每行 `<status>\t<path>[\t<old_path>]`：

- `M` modified、`A` added、`D` deleted、`R` renamed、`C` copied
- rename / copy 把旧路径填到 `old_path`，新路径填到 `path`
- deleted 文件仍参与映射（删除某 Repository 也影响 EA-Client-04）

按 `--numstat` 补 `hunks_count`（实际为变更行数级 numstat），写入 `changed_files[]`。

### Step 4 — 敏感 / 构建产物剔除

复用 `intake-and-scope.md §Step 5` 敏感文件策略与 `extraction-batch-policy.md` excluded_paths：

- 命中 `*.key` / `.env*` / `id_rsa*` 等敏感模式 → 剔除并计入 `excluded_count`
- 命中 `dist/` / `build/` / `target/` / `node_modules/` 等构建产物 → 剔除并计入 `excluded_count`
- 任一原始 changed_file 命中即从 `changed_files[]` 移除

### Step 5 — 维度映射

加载 `references/config/diff-scoper/file-to-dimension-map.yaml`，对每个 changed_file：

1. 按 `patterns[]` 顺序逐条匹配 glob（POSIX `**` 多级 / `*` 单级，大小写敏感）
2. 命中即把该 pattern.dimensions 全部并入 `changed_files[i].mapped_dimensions`
3. 全部未命中 → 加入 `unmapped_files[]`

聚合阶段：

- 每个 `mapped_dimensions[*]` 校验是否存在于 `references/config/dimension-framework/*.yaml`，孤儿 ID 跳过并写 `warnings`
- 反转索引出 `affected_dimensions[]`，含 `hit_files` 计数

### Step 6 — 子领域反推（缩小后续 batch scope）

对每个 affected_dimension：

1. 查 `references/config/dimension-framework/*.yaml` 找 `layer` / `sub_domain` 字段
2. 把命中的 `(domain, sub_domain)` 二元组并入 `affected_sub_domains[]` 去重

profile-and-batch-planner 后续生成 batch 时，只为 `affected_sub_domains` 中的子领域出 batch；其它子领域的 batch 标 `status: skipped, skip_reason: "not in diff scope"`。

### Step 7 — 降级判定

任一命中 → `fallback_to_full_scan: true`，写入 `stop_conditions_hit[]`，并把 `limitations` 透传到 review-summary：

| 触发条件 | 错误码 |
| --- | --- |
| Step 2 NON_GIT_REPO / SHALLOW_CLONE 不可继续 | `LIMITATIONS_NON_GIT_OR_SHALLOW` |
| Step 1 LIMITATIONS_NO_BASELINE | `LIMITATIONS_NO_BASELINE` |
| `changed_files` 数量 > 2000（超出增量模式预算） | `DIFF_TOO_LARGE` |
| `unmapped_files / changed_files > 80%`（映射覆盖率不足） | `MAPPING_COVERAGE_TOO_LOW` |
| `affected_dimensions` 为空 | `EMPTY_AFFECTED_DIMENSIONS`（diff 全部命中映射但维度集为空——通常是注释 / readme） |

降级语义：保留 `diff-scope.md` 输出供审计；下游 profile-and-batch-planner 收到 `fallback_to_full_scan=true` 后改走全量扫描，但本 run 后续 merge 仍按 R34–R40 增量重复运行规则不覆盖现有 active。

### Step 8 — Self-check（移交前）

- [ ] `baseline.ref` 已解析且 `git rev-parse` 通过
- [ ] `changed_files[]` 与 `git diff --name-status` 行数一致（剔除敏感后）
- [ ] 所有 `mapped_dimensions[*]` 存在于 dimension-framework yaml（孤儿已剔除并写 warnings）
- [ ] `affected_dimensions[*].hit_files` 与 changed_files 反转计数一致
- [ ] `affected_sub_domains` 全部映射到现有维度池 layer
- [ ] 无敏感文件原值出现在 changed_files snippet
- [ ] `fallback_to_full_scan` 与 `stop_conditions_hit` 状态一致

任一失败：标记 `fallback_to_full_scan: true`，把失败原因写入 `limitations`，移交全量。

## 失败模式映射

| 命中条件 | 失败模式 | 处理 |
| --- | --- | --- |
| baseline 无法解析 | `BASELINE_UNRESOLVABLE` | 停止；移交 intake 让用户选择降级 |
| 项目非 git 仓库 / shallow clone 不可继续 | `LIMITATIONS_NON_GIT_OR_SHALLOW` | 降级全量（`fallback_to_full_scan=true`） |
| diff 文件 > 2000 | `DIFF_TOO_LARGE` | 降级全量 |
| 映射覆盖率 < 20% | `MAPPING_COVERAGE_TOO_LOW` | 降级全量；warnings 提示用户补 file-to-dimension-map.yaml |
| affected_dimensions 为空 | `EMPTY_AFFECTED_DIMENSIONS` | 不阻断；标 limitations="diff has no dimension impact"；下游可选择跳过 facts |

## 必须做

1. **只**读 `git diff --name-status` 和 `--numstat`，不读 diff 内容片段（避免敏感泄漏）。
2. 每个 changed_file 都映射到至少 1 个维度或进 unmapped_files[]，无遗漏。
3. 孤儿 dimension_id 必须进 warnings，不能静默丢弃。
4. baseline 解析依据写入 `baseline.resolved_from` 留痕。
5. 降级走 `fallback_to_full_scan` 流转，**不**直接抛 error 阻塞 run。

## 禁止做

1. **不得**读 `git diff` 内容（只读 name-status / numstat）。
2. **不得**对 affected_dimensions[] 做激活态判定（state 由 dimension-activator 唯一判定）。
3. **不得**修改 `evidence/dimension-activation-report.json.last_commit`——该字段由 merge-coordinator 在 run 完成后写。
4. **不得**让映射覆盖率不足时静默继续——必须降级全量并写 limitations。
5. **不得**在父级多仓 workspace 用 `git diff` 跨子仓——本 agent 只对单仓 scope 工作。
