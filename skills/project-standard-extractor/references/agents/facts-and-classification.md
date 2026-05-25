# Facts And Classification Contract

## 角色目标

从 profile / batch-plan / doc-source-scanner 的输入中产出可验证 `signal_hits[]`、`doc_facts[]` 与事实候选，供 `dimension-activator` 统一计算激活态。此阶段不消费 activation-report，也不决定维度状态。

> 上游：`profile-and-batch-planner` + `doc-source-scanner`。下游：`dimension-activator`（消费 signal_hits / doc_facts），随后由 `generation` 消费 activation-report 和本阶段已锁定的事实候选。

## 输入

```yaml
inputs:
  scope_summary:
  profile_doc:
  extraction_map:
  batch_plan:
  selected_batch_id:
  doc_inventory: "evidence/knowledge/doc-inventory.json" # 可选，来自 doc-source-scanner
  existing_standards:
  domain_taxonomy:
  dimension_pools:
    - references/config/dimension-framework/baseline-dimensions.yaml
    - references/config/dimension-framework/dimensions-app-client.yaml
    - references/config/dimension-framework/dimensions-frontend.yaml
    - references/config/dimension-framework/dimensions-backend.yaml
    - references/config/dimension-framework/dimensions-industry.yaml
    - references/config/dimension-framework/dimensions-industry-securities.yaml
    - references/config/dimension-framework/dimensions-doc.yaml
  activation_rules:
    - references/config/dimension-framework/activation-rules-app-client.yaml
    - references/config/dimension-framework/activation-rules-frontend.yaml
    - references/config/dimension-framework/activation-rules-backend.yaml
    - references/config/dimension-framework/activation-rules-industry.yaml
    - references/config/dimension-framework/activation-rules-doc.yaml
```

## 输出（Handoff Schema）

```yaml
signal_scan:
  schema: signal-scan.v1
  run_id: ""
  batch_id: ""
  signal_hits:
    - dimension_id: "EA-Client-02"
      signal_id: "kmp-source-set"
      signal_type: "file_existence"
      source: "file_existence"
      hit: true
      weight: 1
      evidence_paths: ["shared/src/commonMain/"]
      confidence: high
      sanitized: true
  doc_facts:
    - dimension_id: "EA-Doc-Decision"
      signal_id: "doc-adr-dir"
      source: "doc-content"
      evidence_paths: ["docs/adr/0001-record.md"]
      heading_signature: "sha256:<hash>"
      sensitive_handling: sanitized
  fact_candidates:
    - id: "EV-{DOMAIN}-{NUMBER}"
      dimension_id: "EA-Client-02"
      path: "shared/src/commonMain/"
      observed_pattern: ""
      file_role: ""
      evidence_kind: "positive | negative | legacy | unknown"
      occurrences: 0
      boundary: ""
      confidence: "high | medium | low"
      sensitive_handling: "sanitized | none"
  unread_candidates: []
  stop_conditions_hit: []
```

`signal_hits[].source` 必须是真实来源：`grep` / `ast` / `file_existence` / `dependency` / `gitnexus` / `doc-content`。GitNexus 命中必须写 `source: gitnexus`；fallback 不得冒充图谱 evidence。

## 执行步骤

### Step 1 — 选定 batch 验证

1. 在 `batch_plan` 中定位 `selected_batch_id`；若不存在，抛出 `BATCH_NOT_SELECTED`。
2. 确认 batch `status == ready`；若为 `pending-confirmation / skipped / blocked`，停止并说明原因。
3. 读取 batch 的 `candidate_files`、`excluded_paths`、`evidence_limit`、`rule_limit`、`stop_conditions`。

### Step 2 — 维度候选域锁定

1. 从 batch 的 `candidate_dimension_ids[]`、scope 的 domain/sub_domain、dimension pool 交集计算候选维度。
2. `candidate_dimension_ids[]` 只是搜索提示；不得把它当作激活状态。
3. 空集时输出 `NO_CANDIDATE_DIMENSIONS_FOR_BATCH`，回到 planner 修 batch-plan。

### Step 3 — signal 执行

按 `activation-rules-*.yaml` 对候选维度执行信号：

| signal_type | 执行来源 | 输出 source |
| --- | --- | --- |
| `grep` | ripgrep + regex | `grep` |
| `ast` | ast-grep，失败时显式 fallback grep | `ast` 或 `grep` |
| `file_existence` | glob / any / all | `file_existence` |
| `dependency` | manifest parser | `dependency` |
| `gitnexus` | host GitNexus readiness available 时查询 | `gitnexus`；fallback 时写真实 fallback source |
| `doc-content` | doc-source-scanner inventory | `doc-content` |

每个 signal 输出 `{dimension_id, signal_id, signal_type, source, hit, weight, evidence_paths, confidence, sanitized}`。路径必须相对项目根或为 path hash，不写真实绝对路径。

### Step 4 — 事实候选萃取

对命中的 evidence paths 生成描述性事实候选。此阶段只描述观察，不写规范结论：

- `occurrences >= 2` 可标 `confidence: high`
- `occurrences == 1` 标 `medium` 或 `low`，写明 `boundary`
- 仅 README / profile 推断的事实必须写 `inferred_from`
- 敏感文件只记录 sanitized existence，不读取原文

### Step 5 — 分类候选

分类桶只是给 generation/review 的素材，不代表维度激活态：

```yaml
classification_candidates:
  recommended: []
  forbidden: []
  legacy_compatible: []
  pending_confirmation: []
  conflict: []
```

维度状态由下游 `dimension-activator` 消费 `signal_hits[]` 后统一裁决；本阶段不得写 `dimension_state`。

### Step 6 — Self-check

- [ ] 输出中没有 `activation_report` 输入依赖。
- [ ] 每条 `signal_hit` 都有 `dimension_id`、`signal_id`、`signal_type`、`source`、`hit`、`weight`。
- [ ] GitNexus 命中使用 `source: gitnexus`，fallback 使用真实 fallback source。
- [ ] `doc-content` 命中只来自 doc-source-scanner 的 sanitized inventory。
- [ ] 每条 fact candidate 都是描述性事实，不是规范结论。
- [ ] 分类候选没有新增不存在于 fact_candidates 的 fact id。
- [ ] 不读取敏感文件原文。

## 失败模式映射

| 命中条件 | 处理 |
| --- | --- |
| `selected_batch_id` 不存在或状态非 ready | `BATCH_NOT_SELECTED`；停止，要求选择有效 batch |
| 候选维度为空 | `NO_CANDIDATE_DIMENSIONS_FOR_BATCH`；回 planner 修复 batch-plan |
| signal library 超时 | 记录 `SIGNAL_LIBRARY_TIMEOUT`，保留已完成 signal，交由 activator 判断 limitations |
| GitNexus readiness 不可用 | 降级 fallback source，写 limitations，不阻塞 |
| 候选文件全部不可读 | `NO_REPRESENTATIVE_EVIDENCE`；输出空 signal_scan 并说明原因 |
| 敏感文件命中 | 只写 sanitized existence，不读原文 |

## 必须做

1. 先产出 signal_hits，再让 dimension-activator 统一判定 state。
2. 每条 signal/fact 都绑定 dimension_id。
3. source 字段必须反映真实 evidence 来源。
4. 对 doc-source-scanner 产物只消费 sanitized inventory。

## 禁止做

1. 不得消费或本地重算 activation-report。
2. 不得在本阶段决定 `baseline / activated / pending-confirmation / shallow / candidate`。
3. 不得把 pending / candidate / shallow 的后续写入策略放在本阶段处理。
4. 不得读取敏感文件内容或输出绝对路径。
