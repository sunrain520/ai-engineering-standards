---
doc_id: "app-client-examples-readme"
title: "APP Examples 索引"
domain: "app-client"
sub_domain: "common"
doc_type: "overview"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "common"
  - "examples"
---

# APP Examples 索引

本目录仅作为正反例和历史兼容 evidence 的可读性增强，不作为 AI 默认执行路径。

## 1. 目录约定

```text
examples/
├── README.md
├── positive/
├── forbidden/
└── legacy/
```

## 2. 写入约束

- 示例必须引用对应 evidence 条目，例如 `evidence/positive-examples.md「POS-APP-2」`。
- 示例必须引用支撑规则，例如 `standard-android.md「P1 页面基类选择必须匹配页面状态复杂度」`。
- 不得写入密钥、token、生产凭据、用户隐私或交易数据原文。
- 不得用本目录替代 `evidence/` 或 `standard-*.md`。
