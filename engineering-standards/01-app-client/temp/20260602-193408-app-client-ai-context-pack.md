---
doc_id: "app-client-20260602-193408-ai-context-pack"
title: "APP Client AI Context Pack"
domain: "app-client"
sub_domain: "common"
doc_type: "ai-context-pack"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "ai-context-pack"
  - "hszq-app"
---

# APP Client AI Context Pack

## 可执行规则摘要

- 构建依赖通过 `hszq-version` 和根 `settings.gradle` 集中治理；应用级插件、渠道、签名、埋点留在主应用模块。
- 交易共享能力先进 `trade2:trade-core`，跨模块页面创建通过 Provider + 强类型 Request，账户子页导航使用 requestId + stage 消费。
- 新增 Android 类使用 Kotlin；Fragment ViewBinding 用 nullable backing field 并在 `onDestroyView` 清理；Flow 绑定 ViewModel 或 View 生命周期；EventBus 注册注销成对并声明 threadMode。
- Android ViewModel 消费 KMP Presenter 时注入生命周期 Scope；KMP Flow 到 UI 的订阅由 Fragment View 生命周期收口。

## 非执行警告

- 发布签名和生产配置只记录变量名或脱敏事实，等待发布/CI owner 确认。
- KMP Service 全局包装属于历史兼容，新增能力不得复制 `globalScope` 模式。
