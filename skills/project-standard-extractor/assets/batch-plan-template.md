---
doc_id: "{domain}-{run_id}-batch-plan"
title: "{Domain} Batch Plan"
domain: "{domain}"
sub_domain: "common"
doc_type: "batch-plan"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
tags:
  - "{domain}"
  - "batch-plan"
  - "context-governance"
---

# {Domain} Batch Plan

## 1. 来源

- run_id: `{run_id}`
- source_profile: `{domain}/temp/{run_id}-project-profile.md`
- source_extraction_map: `{domain}/temp/{run_id}-extraction-map.md`

## 2. Ordered Batch Queue

```yaml
ordered_batch_queue:
  - batch_id: "{domain}-{sub_domain}-{module}-{task_type}"
    priority: high
    status: ready
    confidence_tier: normal
    estimated_doc: "standard-{sub_domain}.md"
    selection_provenance:
      - source: direct-scan
        path: "{path}"
        verified_by_direct_scan: true
  - batch_id: "{domain}-{sub_domain}-{module}-{task_type}-pending"
    priority: low
    status: pending-confirmation
    confidence_tier: low
    estimated_doc: "pending-confirmation.md"
    low_confidence_reason: "{reason}"
```

> Full-auto 只执行 `ready` 与 `pending-confirmation` queue item；每次 worker call 仍只处理一个 `batch_id`。`pending-confirmation` 产出必须隔离到 pending surfaces，不进入 AI 默认执行路径。

## 3. Batch 明细

```yaml
batches:
  - batch_id: "{domain}-{sub_domain}-{module}-{task_type}"
    domain: "{domain}"
    sub_domain: "{sub_domain}"
    module: "{module}"
    task_type: "{task_type}"
    candidate_files:
      - path: "{path}"
        reason: "{why this file is representative}"
        evidence_kind: positive
    excluded_paths:
      - path: "{excluded_path}"
        reason: "secret / generated / dependency / out-of-scope"
	    evidence_limit: 25
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
	    status: ready # ready | pending-confirmation | skipped | blocked
	    confidence_tier: normal # normal | low
	    selection_provenance:
	      - source: direct-scan
	        path: "{path}"
	        verified_by_direct_scan: true
```

## 4. Coverage Report

```yaml
coverage_report:
  matrix_total: {N}
  ready_count: {N}
  pending_confirmation_count: {N}
  skipped_count: {N}
  blocked_count: {N}
  blind_spots:
    - path: "{top_level_path}"
      reason: "scan_budget_exceeded | unreadable | sensitive | unsupported_manifest"
      impact: "profile may have missed sub_domain/task_type"
```

> 覆盖率只代表 profile 识别范围内的覆盖；blind_spots 是潜在漏项，不得在 review-summary 中写成无边界“全部完成”。

## 5. 选择说明

- Full-auto 外层循环可执行多个 queue item，但一次 worker call 只选择一个 `batch_id`。
- `ready` batch 进入 normal-confidence worker。
- `pending-confirmation` batch 进入 low-confidence worker，输出隔离到 `pending-confirmation.md`。
- `skipped` / `blocked` batch 不生成规则。

## 6. 用户确认（仅诊断/重跑路径）

```yaml
selected_batch:
  batch_id:
  source_batch_plan: "{domain}/temp/{run_id}-batch-plan.md"
```
