---
doc_id: "{domain}-{run_id}-project-profile"
title: "{Domain} 项目画像"
domain: "{domain}"
sub_domain: "common"
doc_type: "project-profile"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
tags:
  - "{domain}"
  - "project-profile"
  - "context-governance"
---

# {Domain} 项目画像

## 1. 本次输入

- run_id: `{run_id}`
- extraction_mode: `profile-first`
- project_paths:
  - `{project_path}`
- output_target:
- sensitive_file_policy: `sanitized-existence-only`

## 2. 推断结果

| 项 | 推断 | 置信度 | 需要确认 |
| --- | --- | --- | --- |
| domain | `{domain}` |  |  |
| sub_domain | `{sub_domain}` |  |  |
| industry | `{industry}` |  |  |
| project_shape | monorepo / service-group / focused-module |  |  |

## 3. 结构信号

| 信号 | 路径或证据 | 说明 |
| --- | --- | --- |
|  |  |  |

## 4. 候选模块

| module | domain | sub_domain | task_type 候选 | 代表性路径候选 | 风险 |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

## 5. 敏感与排除范围

| path | reason | handling |
| --- | --- | --- |
|  | secret / generated / dependency / out-of-scope | sanitized-existence-only |

## 6. 需要用户确认

- [ ] 研发域是否正确？
- [ ] 是否允许进入 batch plan？
- [ ] 是否有必须排除的路径？
- [ ] 是否有负责人确认材料？

## 7. 禁止事项

- 本文件不是团队规范规则。
- 不得把本文件的推断直接升级为 `standard.md` 规则。
- 后续正式萃取必须选择一个 batch。
