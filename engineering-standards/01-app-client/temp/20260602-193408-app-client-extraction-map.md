---
doc_id: "app-client-20260602-193408-extraction-map"
title: "hszq-app 萃取映射"
domain: "app-client"
sub_domain: "common"
doc_type: "extraction-map"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "extraction-map"
  - "hszq-app"
---

# hszq-app 萃取映射

| batch | 子领域 | 代表 evidence | 输出文档 | 状态 |
| --- | --- | --- | --- | --- |
| batch-build-governance | build-governance | EV-APP-1..9 | standard-build-governance.md | completed |
| batch-module-boundary | module-boundary | EV-APP-10..17 | standard-module-boundary.md | completed |
| batch-android | android | EV-APP-18..25 | standard-android.md | completed |
| batch-kmp-shared | kmp-shared | EV-APP-26..30, LEG-APP-2 | standard-kmp-shared.md | completed-with-pending |

## 排除与盲区

- 敏感发布配置只记录变量名和存在事实，不读取原值。
- iOS、测试、性能、数据中台、多展业地、安全合规、可观测性未在本次 run 中形成高置信规则，编号文档保持归档/待 evidence 状态。
