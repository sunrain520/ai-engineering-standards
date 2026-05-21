---
doc_id: "{domain}-examples-readme"
title: "{Domain} Examples 索引"
domain: "{domain}"
sub_domain: "common"
doc_type: "overview"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
tags:
  - "{domain}"
  - "common"
  - "examples"
---

# {Domain} Examples 索引

> 本目录仅作为「正反例 / 历史兼容」evidence 的可读性增强,**不**作为 AI 默认执行路径。AI 必须从 `standard.md` + `ai-rules.md` 命中规则后,再按需查阅本目录。

## 1. 目录约定

```text
examples/
├── README.md                  # 本文件
├── positive/                  # 推荐做法可读片段
│   └── {sub_domain}-{slug}.md
├── forbidden/                 # 反例可读片段
│   └── {sub_domain}-{slug}.md
└── legacy/                    # 历史兼容片段
    └── {sub_domain}-{slug}.md
```

## 2. 每个示例文件的最小约定

- 顶部包含 YAML Front Matter,`indexable: false`。
- 标题用 H1。
- 必须引用对应 evidence 条目: `evidence/{kind}.md「{条目编号}」`。
- 必须引用支撑规则: `{source_doc}「{section_title}」`。
- **不写**真实生产路径、密钥、token、生产环境标识。

## 3. 与 evidence 的差异

| 项 | `evidence/` | `examples/` |
| --- | --- | --- |
| 目的 | 沉淀可追溯事实 | 给 reviewer / 新人可读的代码片段 |
| indexable | true | false |
| 是否进 rules-index.json | 是(作为 `evidence_doc`) | 否 |
| 是否被 AI 默认加载 | 否(仅命中规则时按需) | 否 |

## 4. 写入约束

- 不得用本目录承载强制规则。
- 不得用本目录替代 `evidence/`。
- 同一规则下示例追加优于覆盖;旧示例可标 `deprecated: true` 但不删除。
