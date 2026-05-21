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
- source_profile: `{domain}/{run_id}-project-profile.md`
- source_extraction_map: `{domain}/{run_id}-extraction-map.md`

## 2. 可执行 batch

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
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
    status: ready
```

## 3. 选择说明

- 一次正式萃取只选择一个 `batch_id`。
- `ready` batch 可以进入 `batch-extraction`。
- `pending-confirmation` batch 需要用户补充 evidence 或负责人确认。
- `skipped` / `blocked` batch 不生成规则。

## 4. 用户确认

```yaml
selected_batch:
  batch_id:
  source_batch_plan: "{domain}/{run_id}-batch-plan.md"
```
