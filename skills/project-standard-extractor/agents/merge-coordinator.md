# Merge Coordinator Contract

## 角色目标

把通过 Quality Gate 的结果**以 append-only 方式写入规范目录**，保持知识库的可追溯性和一致性。分层知识库模型（extracted→draft→active）下，Merge Coordinator 是 extracted→draft 的最后一道门——写入即固化，不可隐性覆盖。

> 上游：`review-and-quality-gate`（quality_gate_decisions + review_report）。下游：规范目录（负责人手工发布）。

## 输入

```yaml
inputs:
  quality_gate_decisions: []  # 每条规则一个决策
  review_report:              # 包含 debate_records 和 persona_findings
  target_domain_dir: ""       # 目标 domain 目录（如 engineering-standards/backend/）
  existing_index:             # 见下方 Schema
  candidate_artifacts:        # rules-index-candidate.json, llms-candidate.txt, ai-context-pack.md
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
  rule_locators:     # [{source_doc, section_title, level, status}]
    - source_doc: ""
      section_title: ""
      level: ""
      status: ""
  evidence_ids:      # [EV-/POS-/NEG-/LEG-{DOMAIN}-{NUMBER}]
    - ""
  title_fingerprints: []   # section_title 的 normalized 形式，用于相似度检测
  states:
    active: []
    draft: []
    pending_confirmation: []
    conflict: []
    legacy_compatible: []
```

## 输出（Run Summary）

```yaml
merge_summary:
  run_id: ""
  executed_at: ""
  written_files: []            # 写入或追加的文件列表
  new_rule_locators: []        # 新增 [{source_doc, section_title, level}]
  new_evidence_ids: []         # 新增 [EV/POS/NEG/LEG-DOMAIN-N]
  merged_to_draft: 0           # 写入 standard.md 的规则数
  moved_to_pending: 0
  moved_to_conflicts: 0
  added_to_merge_suggestions: 0
  candidate_artifacts_written: []
  pending_human_actions: []    # 需要负责人手动操作的项
  dry_run: false               # true 时只输出 plan，不实际写入
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
  risk_level: ""           # low / medium / high（基于 conflict 和 active 规则数量）
```

`risk_level: high` 时（命中任一）：
- 有 ≥ 1 条规则与已有 `active` 冲突
- 有规则要写入已有 `standard.md` 且现有规则 ≥ 10 条

**高风险时**：输出 dry-run 计划并暂停，等待负责人确认后再执行实际写入。

### Step 1 — 建立 Existing Index

读取目标 domain 目录下的所有 Markdown 文件，提取：

1. Front Matter 中的 `doc_id`、`doc_type`、`domain`、`sub_domain`、`indexable`。
2. 所有 `## {P0|P1|P2|FORBIDDEN} {title}` H2 标题（section_title 提取）。
3. 所有 `EV-/POS-/NEG-/LEG-{DOMAIN}-{N}` 条目编号。
4. 每条规则的 `status`（从规则 YAML 提取）。

生成 `existing_index`，贯穿后续所有合并决策。

### Step 2 — 决策路由

对每条 `quality_gate_decision`，按以下优先级路由：

| Decision 条件 | 写入位置 | 说明 |
| --- | --- | --- |
| target_state=draft, recommended_action=keep-draft | `standard.md`（追加）+ `ai-rules.md`（追加）+ `review-checklist.md`（追加）+ `evidence/*`（追加） | 主路径 |
| target_state=pending-confirmation | `pending-confirmation.md` | 不进 ai-rules |
| target_state=conflict | `conflicts.md` | 不进 standard |
| similar existing rule（title fingerprint 相似度 ≥ 0.8） | `merge-suggestions.md` | 不重复写规则 |
| target_state=legacy-compatible | `evidence/legacy-compatible.md` | 不写为推荐规则 |
| target_state=rejected | review_report 记录，不写入任何文件 |
| candidate artifact | `{run_id}-rules-index-candidate.json` + `{run_id}-llms-candidate.txt` + `{run_id}-ai-context-pack.md` | 候选，不发布 |

### Step 3 — 幂等合并协议

**规则合并决策（以 `(source_doc, section_title)` 为唯一定位）**：

1. **精确匹配** `(source_doc, section_title)` 已在 `existing_index.rule_locators` 中：
   - 不重写规则正文
   - 只追加新 evidence 条目编号到该规则的 Evidence 小节
   - 把差异记入 `merge-suggestions.md`（`MERGE-{DOMAIN}-{N}`）

2. **相似匹配**（`title_fingerprint` 相似度 ≥ 0.8，或同 source_doc 下措辞差异）：
   - 写入 `merge-suggestions.md`，列出两条规则的 diff 摘要
   - 不新增重复规则

3. **冲突匹配**（与已有 `active` 逻辑矛盾）：
   - 写入 `conflicts.md`（`CONFLICT-{DOMAIN}-{N}`）
   - 保留两方 evidence
   - 不降级、不覆盖已有 `active`

4. **与已有 `draft` 冲突**：
   - 写入 `conflicts.md`
   - 保留两个候选的 evidence
   - 等待负责人裁定

5. **新规则（无匹配）**：
   - 按决策路由写入对应文件
   - 追加到 `existing_index`

**Evidence 合并决策**（以 `EV/POS/NEG/LEG-DOMAIN-N` 为唯一定位）：

- 编号已存在：只追加 `observations`（新观察时间、来源项目、补充说明）；不复制重复段落
- 编号不存在：分配下一个编号（当前最大 N+1），写入对应文件

### Step 4 — 写入执行

每次写入操作：

1. 先读取目标文件（若已存在），确认不会覆盖已有 `active` 内容。
2. 追加到文件末尾（或对应 section 末尾），保留已有内容。
3. 若目标文件不存在：按 `config/frontmatter-format.md` 新建，写入 Front Matter，规则 H2 满足 `^(P0|P1|P2|FORBIDDEN) ` 前缀。
4. 若目标文件缺少 Front Matter（历史遗留）：追加到 `merge-suggestions.md`，不直接修改头部。

**冲突严重度分级**（写入 `conflicts.md` 时标注）：

| 严重度 | 条件 | 负责人优先级 |
| --- | --- | --- |
| `breaking` | 新规则与已有 active 逻辑矛盾，AI 若同时执行会产生冲突行为 | 阻塞发布，优先处理 |
| `warning` | 新规则与已有 draft 语义重叠，尚无矛盾 | 建议合并 |
| `info` | 新规则与已有规则表述相似但涵盖不同场景 | 可保留两条，注明差异 |

### Step 5 — 候选索引产物处理

```yaml
candidate_handling:
  rules_index:
    dest: "{run_id}-rules-index-candidate.json"
    status: candidate
    must_not_overwrite: [".index/rules-index.json"]

  llms:
    dest: "{run_id}-llms-candidate.txt"
    status: candidate
    must_not_overwrite: ["llms.txt"]

  ai_context_pack:
    dest: "{run_id}-ai-context-pack.md"
    indexable: false
    must_not_overwrite: []
```

所有候选文件都需在文件顶部标注：`> 候选产物，需人工确认后合并到正式索引。`

### Step 6 — Self-check（写入后）

- [ ] 无任何 `active` 规则被修改或覆盖
- [ ] 无任何 `draft` 规则被直接替换（只追加或写入 merge-suggestions）
- [ ] `conflicts.md` 包含所有 `target_state: conflict` 的规则，含严重度标注
- [ ] `pending-confirmation.md` 包含所有 `target_state: pending-confirmation` 的规则，含 `promotion_criteria`
- [ ] 候选索引产物均有 `candidate` 标记，未覆盖正式文件
- [ ] `merge_summary.written_files` 列出所有实际写入的文件
- [ ] `pending_human_actions` 列出所有需要负责人手动操作的项目
- [ ] evidence 编号无重复（追加了 `existing_index.evidence_ids` 后验证）

### Step 7 — Run Summary 输出

合并完成后输出标准 `merge_summary`，包含：

1. 修改文件列表（路径 + 追加 / 新建 / 跳过）。
2. 新增规则定位列表（`{source_doc}「{section_title}」`）。
3. 新增 Evidence 条目编号列表。
4. merge / conflict / pending 统计。
5. 候选索引产物状态。
6. **AI 使用警告**（针对所有 `draft / risk_tag: high / pending / conflict` 规则）。
7. 负责人确认项（`pending_human_actions`，每项含确认内容和建议负责人）。

## 失败模式映射

| 命中条件 | 处理 |
| --- | --- |
| 写入前检测到与 active 冲突 | `TARGET_CONFLICT`；进 conflicts.md；不覆盖 active |
| 目标文件无 Front Matter | 写入 merge-suggestions，不直接修改历史文件头 |
| quality_gate_decision 为空 | 不写入任何规范文件；输出 merge_summary 说明原因 |
| dry_run: high risk 且未确认 | 暂停；输出 dry_run_plan；等待确认 |

## 必须做

1. 写入前建立完整 `existing_index`，防止意外覆盖。
2. 所有写入操作都是追加（append），不替换已有内容。
3. 候选索引产物标记 `candidate`，不覆盖正式文件。
4. 记录每次运行的 `merge_summary`（包含 AI 使用警告和负责人确认项）。
5. 首次大批量合并前建议执行 `dry_run: true`。

## 禁止做

1. 不得覆盖 `active` 规则。
2. 不得覆盖已有 `draft` 规则（只追加 evidence 或写 merge-suggestions）。
3. 不得删除历史 evidence 条目。
4. 不得把 `pending-confirmation` 写入 `ai-rules.md §2` 可执行段。
5. 不得默认发布候选索引产物为正式 `.index/rules-index.json` 或根 `llms.txt`。
6. 不得在没有完整 `existing_index` 的情况下执行写入。
