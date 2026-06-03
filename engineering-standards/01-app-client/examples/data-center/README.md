---
doc_id: "app-client-examples-data-center-readme"
title: "数据中台示例目录"
domain: "app-client"
sub_domain: "data-center"
doc_type: "overview"
version: "v0.1.0"
status: "archived"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
coverage_state: "not-extracted-in-current-run"
tags:
  - "app-client"
  - "examples"
  - "data-center"
---

> 本次 run 未形成数据中台示例集，本目录仅保留历史占位说明。

# 数据中台示例目录

用于沉淀 HSDataCenterKit 数据访问、缓存策略和错误转换正例。

建议优先补充：

1. network first 正例。
2. cache first + background refresh 正例。
3. 配置项 cache first + version check 正例。
4. 统一错误模型转换正例。
5. UI 或 ViewModel 绕过数据中台直接请求网络的反例。

示例必须说明：

- 数据类型。
- 缓存策略。
- 错误处理方式。
- 对应代码路径。
- 为什么是正例或反例。
