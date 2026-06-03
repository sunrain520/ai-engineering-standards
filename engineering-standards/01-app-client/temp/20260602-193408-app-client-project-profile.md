---
doc_id: "app-client-20260602-193408-project-profile"
title: "hszq-app 项目画像"
domain: "app-client"
sub_domain: "common"
doc_type: "project-profile"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "project-profile"
  - "hszq-app"
---

# hszq-app 项目画像

| 字段 | 结果 |
| --- | --- |
| run_id | 20260602-193408-app-client |
| target commit | feb6f82ae442bdf3444624270dc24ca15d437e55 |
| run_mode | auto |
| domain | app-client |
| 覆盖领域 | build-governance、module-boundary、android、kmp-shared Android 消费侧 |
| blind spot | 授权路径下未包含 `submodules/biz-common`，不强制声明 KMP shared 源码内部规范 |

## 画像结论

目标项目是 Android 多模块 App 工程，Gradle 构建和业务模块边界清晰，Kotlin 新代码、Fragment 生命周期、Flow 生命周期、ARouter Provider、KMP Presenter 消费方式具有足够重复 evidence，可萃取为单项目 auto-active 规则。发布签名和 KMP 全局 Service 生命周期属于高风险或证据不足项，保持 pending-confirmation。
