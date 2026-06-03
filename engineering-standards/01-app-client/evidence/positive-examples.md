---
doc_id: "app-client-positive-examples"
title: "APP 客户端正向示例"
domain: "app-client"
sub_domain: "common"
doc_type: "evidence-positive"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "positive"
  - "evidence"
---

# APP 客户端正向示例

## POS-APP-1 集中依赖版本治理

- 来源：`hszq-version/src/main/java/hszq/version/Deps.kt`
- 对应规则：`standard-build-governance.md「P1 依赖版本和强制依赖必须通过 hszq-version 集中治理」`
- 摘要：内部依赖版本、SNAPSHOT 替换和 force 依赖统一由 `Deps` 插件承载。

## POS-APP-2 业务模块引用 Deps 常量

- 来源：`app-core/build.gradle`、`huasheng-stock/build.gradle`、多个业务模块 `build.gradle`
- 对应规则：`standard-build-governance.md「P1 依赖版本和强制依赖必须通过 hszq-version 集中治理」`
- 摘要：模块通过 `Deps.Business.*` 和 `Deps.Lib.*` 表达依赖来源，避免重复硬编码坐标。

## POS-APP-3 settings.gradle 控制本地模块激活

- 来源：`settings.gradle`
- 对应规则：`standard-build-governance.md「P1 本地模块激活必须只改 settings.gradle 的 include 边界」`
- 摘要：默认仅启用主应用与版本插件，其他业务模块以注释 include 保留。

## POS-APP-4 主应用模块集中应用级构建语义

- 来源：`huasheng-stock/build.gradle`
- 对应规则：`standard-build-governance.md「P2 应用级插件、渠道、签名和埋点只放在主应用模块」`
- 摘要：应用插件、buildTypes、签名、渠道和埋点配置集中在主应用模块。

## POS-APP-5 trade-core 作为交易共享边界

- 来源：`trade2/trade-core/README.md`、`trade2/*/build.gradle`
- 对应规则：`standard-module-boundary.md「P1 交易共享能力必须先沉淀到 trade-core，再由交易子模块复用」`
- 摘要：交易账户、订单、条件单和交易分析复用 `trade2:trade-core`。

## POS-APP-6 provider + request 表达跨模块页面协议

- 来源：`IOrderPageProvider.kt`、`OrderPageRequests.kt`
- 对应规则：`standard-module-boundary.md「P1 跨模块页面创建必须通过 Provider 接口和强类型 Request」`
- 摘要：跨模块页面创建不透传 Bundle，由强类型 request 承载参数。

## POS-APP-7 账户导航使用 requestId + stage

- 来源：`AccountContainerNavigationVM.kt`
- 对应规则：`standard-module-boundary.md「P1 账户子页面导航必须分阶段消费并记录 requestId」`
- 摘要：导航请求用 `requestId` 区分新请求，用 `handledStages` 避免重复副作用。

## POS-APP-8 core-ui-kit README 明确通用 UI 准入

- 来源：`core/core-ui-kit/README.md`
- 对应规则：`standard-module-boundary.md「P2 core-ui-kit 只收纳跨业务 UI 基础能力」`
- 摘要：模块明确禁止业务逻辑、业务模型和页面临时代码进入 UI 基础层。

## POS-APP-9 新交易账户代码使用 Kotlin

- 来源：`trade2/trade-account/src/main/java/**/*.kt`
- 对应规则：`standard-android.md「P1 新增类必须使用 Kotlin，存量 Java 只做兼容维护」`
- 摘要：新交易账户能力主要由 Kotlin Fragment / VM / Adapter 组成。

## POS-APP-10 Fragment binding 生命周期清晰

- 来源：`AccountOverviewFragment.kt`、`AllSecuritiesFragment.kt`、`TransferBizFragment.kt`
- 对应规则：`standard-android.md「P1 Fragment ViewBinding 必须使用 nullable backing field 并在 onDestroyView 清理」`
- 摘要：ViewBinding 使用 nullable backing field，并在 `onDestroyView()` 置空。

## POS-APP-11 Flow 订阅绑定生命周期

- 来源：`AccountOverviewFragment.kt`、`AccountOverviewVM.kt`
- 对应规则：`standard-android.md「P1 Flow 订阅必须绑定 viewModelScope 或 viewLifecycleOwner 生命周期」`
- 摘要：ViewModel 使用 `viewModelScope`，Fragment 使用 `repeatOnLifecycle` 收集 UI Flow。

## POS-APP-12 EventBus 订阅声明线程模式

- 来源：`CalendarFragment.java`、`StockSearchFragment.java`、`BroadcastWindow.java`
- 对应规则：`standard-android.md「P2 EventBus 注册注销必须成对，并声明 threadMode」`
- 摘要：抽样订阅均声明了 `threadMode`，注册与注销在生命周期中成对出现。

## POS-APP-13 KMP Presenter 由 ViewModel 注入

- 来源：`AccountOverviewVM.kt`
- 对应规则：`standard-kmp-shared.md「P1 Android ViewModel 获取 KMP Presenter 必须注入生命周期 Scope」`
- 摘要：KMP Presenter 通过 Koin 注入并接收 `viewModelScope`。

## POS-APP-14 KMP Flow 由 Fragment 生命周期消费

- 来源：`AccountOverviewFragment.kt`
- 对应规则：`standard-kmp-shared.md「P1 KMP Flow 到 Android UI 的订阅必须由 Fragment 生命周期收口」`
- 摘要：Presenter Flow 在 `repeatOnLifecycle(STARTED)` 中收集。
