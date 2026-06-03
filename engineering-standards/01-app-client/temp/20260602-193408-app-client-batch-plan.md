---
doc_id: "app-client-20260602-193408-batch-plan"
title: "hszq-app Batch Plan"
domain: "app-client"
sub_domain: "common"
doc_type: "batch-plan"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "batch-plan"
  - "hszq-app"
---

# hszq-app Batch Plan

## ordered_batch_queue

1. batch-build-governance -> 验证 hszq-version、settings.gradle、主应用构建语义。
2. batch-module-boundary -> 验证 trade-core、provider/request、账户导航、core-ui-kit。
3. batch-android -> 验证 Kotlin 新增类、ViewBinding、Flow 生命周期、EventBus。
4. batch-kmp-shared -> 验证 Android 侧 KMP Presenter / Flow / Service 消费方式。

## stop conditions

- 需要读取签名、证书、token、生产配置原值时停止，只记录脱敏存在事实。
- 需要 `submodules/biz-common` 才能确认 KMP shared 内部架构时停止并写 blind spot。
