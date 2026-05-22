---
doc_id: "app-client-module-boundary-evidence-positive"
title: "APP Module Boundary Positive Examples"
domain: "app-client"
sub_domain: "module-boundary"
doc_type: "evidence-positive"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260522-100947-app-client"
source_batch: "app-client-module-boundary-contract-layer"
tags:
  - "app-client"
  - "module-boundary"
  - "positive-example"
---

# APP Module Boundary Positive Examples

## POS-APP-1: contract 模块不依赖 feature 实现模块

- source_facts:
  - `evidence/code-facts.md「EV-APP-1」`
  - `evidence/code-facts.md「EV-APP-2」`
  - `evidence/code-facts.md「EV-APP-3」`
  - `evidence/code-facts.md「EV-APP-4」`
- path_pattern:
  - `contract/{domain}/build.gradle.kts`
  - `contract/{domain}/src/main/AndroidManifest.xml`
  - `KAZ模块化架构设计规范.md`
- observed_positive_pattern: contract 模块以独立 library 存在，构建脚本未依赖 feature 实现模块；架构文档把 contract 明确为跨域稳定边界，并禁止 contract 反向依赖 feature。
- applicable_rule_candidate: `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」`
- evidence_tier: `single-project`
