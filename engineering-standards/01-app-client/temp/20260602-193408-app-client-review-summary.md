---
doc_id: "app-client-20260602-193408-review-summary"
title: "hszq-app Review Summary"
domain: "app-client"
sub_domain: "common"
doc_type: "review-report"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "review-summary"
  - "hszq-app"
---

# hszq-app Review Summary

| 项 | 结果 |
| --- | --- |
| auto-active rules | 13 |
| pending-confirmation rules | 2 |
| conflicts | 0 |
| formal standards | standard-build-governance.md、standard-module-boundary.md、standard-android.md、standard-kmp-shared.md |

## 结论

内容门禁通过：auto-active 规则均有重复 deterministic evidence、authority_scope 为 this-repo、未命中反范式黑名单。发布签名和 KMP 全局 Service 生命周期保持 pending，不进入 AI 默认执行路径。
