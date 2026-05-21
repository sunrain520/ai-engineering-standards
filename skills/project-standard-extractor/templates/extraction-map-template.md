---
doc_id: "{domain}-{run_id}-extraction-map"
title: "{Domain} Extraction Map"
domain: "{domain}"
sub_domain: "common"
doc_type: "extraction-map"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
tags:
  - "{domain}"
  - "extraction-map"
  - "context-governance"
---

# {Domain} Extraction Map

## 1. 来源

- run_id: `{run_id}`
- source_profile: `{domain}/{run_id}-project-profile.md`
- extraction_mode: `profile-first`

## 2. 映射矩阵

| domain | sub_domain | module | task_type | evidence_kind | candidate_paths | excluded_paths |
| --- | --- | --- | --- | --- | --- | --- |
| `{domain}` | `{sub_domain}` | `{module}` | `{task_type}` | positive / forbidden / legacy |  |  |

## 3. 代表性 evidence 候选

| candidate_id | path | reason | expected_fact | read_priority |
| --- | --- | --- | --- | --- |
| CAND-001 |  |  |  | high |

## 4. 排除范围

| path | reason |
| --- | --- |
|  | secret / generated / dependency / out-of-scope |

## 5. batch 生成提示

- 同一 batch 只能覆盖一个主要 `domain + sub_domain + module/task_type`。
- 如果候选路径不足以支撑规则，batch 应标记为 `pending-confirmation` 或 `skipped`。
- 不得把多个不相关模块塞进一个 batch。
