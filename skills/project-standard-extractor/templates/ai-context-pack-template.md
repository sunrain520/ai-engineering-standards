---
doc_id: "{domain}-{run_id}-ai-context-pack"
title: "{Domain} AI Context Pack"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "ai-context-pack"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
tags:
  - "{domain}"
  - "{sub_domain}"
  - "ai-context-pack"
---

# AI Context Pack

## 1. 当前需求

{用户需求}

## 2. 任务识别

- domain: `{domain}`
- sub_domain: `{sub_domain}`
- task_type: `{task_type}`
- module: `{module}`
- batch_id: `{batch_id}`
- tags:
  - `{tag}`

## 3. 命中规则

| source_doc | section_title | level | evidence_doc | tags |
| --- | --- | --- | --- | --- |
| `{source_doc}` | `{section_title}` | P0 | `{evidence_doc}` | `{tags}` |

引用格式：

```text
{source_doc}「{section_title}」
```

## 4. 必须加载的规范

- `00-global/rule-lifecycle.md`
- `00-global/quality-gate.md`
- `{domain}/overview.md`
- `{source_doc}`
- `{ai_rules_doc}`

## 5. 相关代码路径

仅列本次任务需要读取或修改的路径，不列完整项目源码。

- `{code_path}`

## 6. 生成代码要求

- 必须遵守命中规则。
- 必须优先复用已有代码。
- 必须输出修改文件列表。
- 必须输出自检结果。

## 7. 自检要求

生成后必须逐条引用 `{source_doc}「{section_title}」` 输出遵守情况。
