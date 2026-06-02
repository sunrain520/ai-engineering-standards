# Artifact Contract Cases

这些用例检查 `output-artifact-contract.json`、`artifact-contract-validate.sh`、lineage、owner queue 和 fast-index candidate/formal 边界。

## AC-001 Contract Enum Drift

输入：

```yaml
frontmatter_rule_statuses:
  - auto-active
  - owner-confirmed-active
  - draft
contract_rule_statuses:
  - draft
  - active
```

期望：

- `artifact-contract-validate.sh` 对 enum mismatch 输出 BLOCK。
- 不允许 `frontmatter-format.md` 与 `output-artifact-contract.json` 各自维护不同状态表。

## AC-002 Candidate Index Boundary

输入：

```yaml
candidate_file: temp/20260602-backend-rules-index-candidate.json
candidate: true
shape: canonical rules[]
attempted_dest: .index/rules-index.json
```

期望：

- validator 识别为 candidate artifact。
- 没有用户显式 publish / owner 确认时，不得覆盖正式 `.index/rules-index.json`。
- `rules-index` 候选必须使用顶层 `rules[]`，不得回退到旧 `sections[]` 或 `activation_report_ref` 形态。
- `rules-index` 条目不得含 `rule_id` 或 `anchor`，必须含 `title`、`domain`、`sub_domain`、`level`、`status`、`source_doc`、`section_title`、`evidence_doc`、`authority_scope`、`upgrade_mode` 和 `tags`。

## AC-003 Lineage Incomplete

输入：

```yaml
rule:
  source_doc: standard-backend-api.md
  section_title: "P0 Controller 只做请求编排"
  status: auto-active
lineage_edge:
  evidence_id: EV-BACKEND-1
  source_doc: standard-backend-api.md
  section_title: "P0 Controller 只做请求编排"
  derived_view_type: ai-rules
  gate_result: auto-active
  deterministic_occurrence_count: null
```

期望：

- 触发 `LINEAGE_INCOMPLETE` 或 `AUTO_ACTIVE_LINEAGE_INCOMPLETE`。
- auto-active 规则不得进入 AI 默认执行路径。
- reviewer 能区分 lineage 不完整与真正 orphan rule；不能把残缺账本误报成全量 orphan。

## AC-004 Phase1 Activation Report Leak

输入：

```yaml
review_profile: phase1-full-auto
temp_files:
  - temp/20260602-backend-activation-report.json
```

期望：

- 触发 `PHASE1_ACTIVATION_REPORT_LEAK`。
- Phase1 不得合成、复制或持久化 activation-report。
- merge 必须继续按 `target_state` 路由，而不是按空 `dimension_state` 分桶。

## AC-005 Owner Rejected Exit

输入：

```yaml
previous_rule:
  locator: standard-backend-api.md「P0 Controller 只做请求编排」
  status: auto-active
owner_decision:
  status: owner-rejected
owner_queue_item:
  current_status: owner-rejected
  owner_queue_action: no-action-terminal
next_run:
  deterministic_occurrence_count: 3
```

期望：

- 下次运行标 `owner-rejected`。
- 从 `ai-rules.md §2` 和 review checklist 默认执行段移出。
- owner queue 使用 `owner_queue_action`，不得把规则级 `recommended_action` 当负责人队列动作。
- owner rejection 是终态，不因 occurrence 足够自动恢复。

## AC-006 Stale Auto-active Exit

输入：

```yaml
previous_rule:
  locator: standard-backend-api.md「P0 Controller 只做请求编排」
  status: auto-active
next_run_gate:
  deterministic_occurrence_count: 1
  conflict_status: new-unresolved-conflict
```

期望：

- 标 `stale-auto-active`。
- 从默认执行路径移出并进入 owner decision queue。
- 正文 append-only 保留，降级不等于删除或改写历史规则。

## AC-007 Phase2 Activation Report Persistence

输入：

```yaml
review_profile: phase2-dimension-aware
temp_source: temp/20260602-backend-activation-report.json
persisted_dest: evidence/dimension-activation-report.json
```

期望：

- Phase2 允许存在 temp activation-report 输入。
- merge 完成后必须持久化 `evidence/dimension-activation-report.json`，并通过 `activation-report.v1` schema 检查。
- `merge_summary.activation_report_path` 指向正式 evidence 路径，不得只留下 temp ref。

## AC-008 Committed Fixture Coverage

输入：

```yaml
valid_fixtures:
  - docs/evals/project-standard-extractor/fixtures/artifact-contract/valid-phase1
  - docs/evals/project-standard-extractor/fixtures/artifact-contract/valid-phase2
invalid_fixtures:
  - docs/evals/project-standard-extractor/fixtures/artifact-contract/invalid-phase1-activation-leak
```

期望：

- valid Phase1/Phase2 fixtures 作为最小 generated-domain 样本随仓库提交，`artifact-contract-validate.sh` 必须对它们返回 0。
- invalid Phase1 fixture 是诊断负例，必须返回非 0，并至少输出 `PHASE1_ACTIVATION_REPORT_LEAK`。
- public-surface validator 必须检查这些 fixture 路径仍被 README 和 artifact contract cases 引用。

## AC-009 LLM Candidate Boundary

输入：

```yaml
candidate_file: temp/20260602-backend-llms-candidate.txt
attempted_dest: llms.txt
```

期望：

- `llms-candidate.txt` 只能停留在 run temp 目录。
- 没有用户显式 publish / owner 确认时，不得覆盖根 `llms.txt`。
- validator 对 candidate 覆盖正式入口输出 BLOCK。
