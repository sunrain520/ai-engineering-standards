---
doc_id: "app-client-code-facts"
title: "APP 客户端萃取代码事实"
domain: "app-client"
sub_domain: "common"
doc_type: "evidence-code-facts"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "evidence"
---

# APP 客户端萃取代码事实

> 来源项目：`hszq-app`
> Source revision：`feb6f82ae442bdf3444624270dc24ca15d437e55`
> 说明：路径均为项目根相对路径；敏感配置只记录变量名和存在事实。

## EV-APP-1 hszq-version 提供依赖版本治理入口

- 路径：`hszq-version/src/main/java/hszq/version/Deps.kt:21-63`
- 观察：`Deps` 插件暴露 `Deps.modify(project)`、`Lib`、`Business` 和 `forceList`，用于集中修改内部库版本和强制依赖。
- 分类：recommended
- confidence：high
- boundary：build-governance

## EV-APP-2 业务模块通过 Deps.Business / Deps.Lib 引用内部依赖

- 路径：`app-core/build.gradle:18-51`、`huasheng-stock/build.gradle:388-503`、多个 feature `build.gradle`
- 观察：主包和聚合模块大量使用 `Deps.Business.*`、`Deps.Lib.*` 引入内部业务和基础库。
- 分类：recommended
- confidence：high
- boundary：build-governance

## EV-APP-3 强制依赖通过 forceList 集中追加

- 路径：`hszq-version/src/main/java/hszq/version/Deps.kt:56-63`
- 观察：`Deps.modify()` 对 `network`、`k_chart`、`keyboard`、`web`、`report`、`common`、`hs_config` 等依赖调用 `forceList.add(...)`。
- 分类：recommended
- confidence：high
- boundary：build-governance

## EV-APP-4 settings.gradle 只激活主应用和 hszq-version

- 路径：`settings.gradle:19-92`
- 观察：`includeBuild 'hszq-version'` 和 `include ':huasheng-stock'` 为当前启用项，大量业务模块 include 保持注释。
- 分类：recommended
- confidence：high
- boundary：build-governance

## EV-APP-5 主包和 app-core 默认通过 Maven 业务依赖集成模块

- 路径：`huasheng-stock/build.gradle:388-503`、`app-core/build.gradle:18-51`
- 观察：主包和 `app-core` 使用 `Deps.Business.*` 聚合业务能力，说明默认构建路径以发布产物为主。
- 分类：recommended
- confidence：high
- boundary：build-governance

## EV-APP-6 主应用模块集中配置应用级插件

- 路径：`huasheng-stock/build.gradle:1-80`
- 观察：主应用模块应用 `com.android.application`、Kotlin、KAPT、AGConnect、Sensors、Bonree、Android AOP、manifest exported check 等插件。
- 分类：recommended
- confidence：high
- boundary：build-governance

## EV-APP-7 主应用模块集中配置 buildTypes 和签名引用

- 路径：`huasheng-stock/build.gradle:116-180`
- 观察：`signingConfigs`、`release`、`beta`、`feature`、`debug` 均在主应用模块集中配置。
- 分类：recommended
- confidence：high
- boundary：build-governance

## EV-APP-8 业务模块默认使用 Android library 插件和公共构建脚本

- 路径：`trade2/trade-account/build.gradle:1-14`、`trade2/trade-order/build.gradle:1-13`、`core/core-ui-kit/build.gradle:1-8`
- 观察：业务模块使用 `com.android.library` 和公共 `app-common.gradle` / `app_bad_common_dependencies.gradle`。
- 分类：recommended
- confidence：high
- boundary：build-governance

## EV-APP-9 发布签名以变量形式引用

- 路径：`huasheng-stock/build.gradle:116-123`
- 观察：签名配置引用 `RELEASE_KEY_ALIAS`、`RELEASE_KEY_PASSWORD`、`RELEASE_STORE_FILE`、`RELEASE_STORE_PASSWORD` 变量；未读取或输出变量原值。
- 分类：pending_confirmation
- confidence：low
- sensitive_handling：sanitized
- boundary：build-governance

## EV-APP-10 trade-core README 定义交易共享能力边界

- 路径：`trade2/trade-core/README.md:1-4`
- 观察：`trade-core` 用于存放交易模块共享 UI 组件、工具类、数据模型，各交易模块依赖此模块。
- 分类：recommended
- confidence：high
- boundary：module-boundary

## EV-APP-11 多个交易子模块依赖 trade2:trade-core

- 路径：`trade2/trade-account/build.gradle:31`、`trade2/trade-order/build.gradle:17`、`trade2/trade-condition/build.gradle:17`、`trade-analysis/build.gradle:41`
- 观察：交易账户、订单、条件单、交易分析均依赖 `project(":trade2:trade-core")`。
- 分类：recommended
- confidence：high
- boundary：module-boundary

## EV-APP-12 trade-core 依赖 core-ui-kit 而不依赖交易 feature

- 路径：`trade2/trade-core/build.gradle:16-19`
- 观察：`trade-core` 依赖 `Deps.Lib.common` 和 `api(project(":core:core-ui-kit"))`，未出现对交易 feature 的反向依赖。
- 分类：recommended
- confidence：high
- boundary：module-boundary

## EV-APP-13 IOrderPageProvider 收敛跨模块页面创建

- 路径：`trade2/trade-core/src/main/java/com/hstong/trade/core/router/provider/IOrderPageProvider.kt:1-24`
- 观察：订单相关页面通过 `IOrderPageProvider` 暴露跨模块 Fragment 创建能力。
- 分类：recommended
- confidence：high
- boundary：module-boundary

## EV-APP-14 OrderPageRequest 使用强类型参数协议

- 路径：`trade2/trade-core/src/main/java/com/hstong/trade/core/router/provider/OrderPageRequests.kt:1-19`
- 观察：订单页和条件单页参数由 `OrderPageRequest` / `CondOrderPageRequest` 表达，注释明确禁止退化为 Bundle 透传。
- 分类：recommended
- confidence：high
- boundary：module-boundary

## EV-APP-15 AccountSubPageNavigationVM 使用 requestId 和 handledStages

- 路径：`trade2/trade-core/src/main/java/com/hstong/trade/core/accountpagenavigation/AccountContainerNavigationVM.kt:1-107`
- 观察：账户子页面导航使用 `MutableStateFlow`、单调递增 `requestId` 和 `handledStages` 分阶段处理请求。
- 分类：recommended
- confidence：high
- boundary：module-boundary

## EV-APP-16 AccountContainerNavigable 拆分请求方和消费方接口

- 路径：`trade2/trade-core/src/main/java/com/hstong/trade/core/accountpagenavigation/AccountContainerNavigable.kt:1-31`
- 观察：导航发起和消费拆成 `AccountContainerNavigationRequester` 与 `AccountContainerNavigationConsumer`，消费方返回处理结果。
- 分类：recommended
- confidence：high
- boundary：module-boundary

## EV-APP-17 core-ui-kit README 明确准入和禁止边界

- 路径：`core/core-ui-kit/README.md:1-120`
- 观察：`core-ui-kit` 只收纳跨业务 UI 能力，禁止业务逻辑、业务模型、页面专属实现和非 UI 工具代码。
- 分类：recommended
- confidence：high
- boundary：module-boundary

## EV-APP-18 项目指令要求新增类使用 Kotlin

- 路径：`CLAUDE.md:45-48`
- 观察：项目说明写明开发语言为 Kotlin、Java，新增类必须使用 Kotlin。
- 分类：recommended
- confidence：high
- boundary：android

## EV-APP-19 新交易账户模块以 Kotlin 新代码为主

- 路径：`trade2/trade-account/src/main/java/com/hstong/trade/account/**/*.kt`
- 观察：交易账户容器、账户总览、证券账户、期货账户、加密货币账户等新代码均为 Kotlin 文件。
- 分类：recommended
- confidence：high
- boundary：android

## EV-APP-20 AccountOverviewFragment 使用 nullable ViewBinding

- 路径：`trade2/trade-account/src/main/java/com/hstong/trade/account/overview/AccountOverviewFragment.kt:49-123`
- 观察：Fragment 使用 `_binding`、`binding`、`bindingOrNull`，并在 `onDestroyView()` 中置空。
- 分类：recommended
- confidence：high
- boundary：android

## EV-APP-21 多个 Fragment 使用同样的 ViewBinding 清理模式

- 路径：`trade2/trade-account/src/main/java/com/hstong/trade/account/securitiesbiz/allbiz/AllSecuritiesFragment.kt`、`trade2/trade-account/src/main/java/com/hstong/trade/account/securitiesbiz/transfer/TransferBizFragment.kt`、`post/src/main/java/com/hstong/post/comment/PostCommentFragment.kt`
- 观察：多个 Fragment 使用 nullable `_binding` 并在 `onDestroyView()` 置空。
- 分类：recommended
- confidence：high
- boundary：android

## EV-APP-22 AccountOverviewVM 通过 viewModelScope 驱动 Presenter

- 路径：`trade2/trade-account/src/main/java/com/hstong/trade/account/overview/AccountOverviewVM.kt:1-39`
- 观察：ViewModel 通过 Koin 获取 Presenter 时传入 `viewModelScope`，并在 `viewModelScope.launch` 中收集请求状态。
- 分类：recommended
- confidence：high
- boundary：android

## EV-APP-23 AccountOverviewFragment 使用 repeatOnLifecycle 收集多路 Flow

- 路径：`trade2/trade-account/src/main/java/com/hstong/trade/account/overview/AccountOverviewFragment.kt:190-236`
- 观察：Fragment 在 `viewLifecycleOwner.repeatOnLifecycle(STARTED)` 中并行收集多个 Presenter / Manager Flow。
- 分类：recommended
- confidence：high
- boundary：android

## EV-APP-24 EventBus 注册注销成对出现

- 路径：`calendar/src/main/java/com/hstong/calendar/CalendarFragment.java:215,861`、`searchbase/src/main/java/com/hstong/search/base/StockSearchFragment.java:185,488`、`trade/src/main/java/com/hstong/trade/openaccount/OpenAccountFragment.java:64,70`
- 观察：多个页面在创建/附着阶段注册 EventBus，并在销毁/解绑阶段注销。
- 分类：recommended
- confidence：high
- boundary：android

## EV-APP-25 EventBus 订阅显式声明 threadMode

- 路径：`calendar/src/main/java/com/hstong/calendar/CalendarFragment.java:980-986`、`searchbase/src/main/java/com/hstong/search/base/StockSearchFragment.java:494`、`platformcomm/src/main/java/com/hstong/platformcomm/broadcast/BroadcastWindow.java:490-534`
- 观察：`@Subscribe` 注解显式声明 `ThreadMode.MAIN` 或其他线程模式。
- 分类：recommended
- confidence：high
- boundary：android

## EV-APP-26 AccountOverviewVM 注入 KMP Presenter

- 路径：`trade2/trade-account/src/main/java/com/hstong/trade/account/overview/AccountOverviewVM.kt:4-24`
- 观察：ViewModel 持有 `OverallAccountOverviewPresenter`，并通过 Koin `get { parametersOf(viewModelScope) }` 获取。
- 分类：recommended
- confidence：high
- boundary：kmp-shared

## EV-APP-27 Fragment 通过 ViewModel 访问 Presenter

- 路径：`trade2/trade-account/src/main/java/com/hstong/trade/account/overview/AccountOverviewFragment.kt:107-236`
- 观察：Fragment 通过 `viewModel.presenter` 触发刷新、切换脱敏状态、收集 Presenter Flow。
- 分类：recommended
- confidence：high
- boundary：kmp-shared

## EV-APP-28 KMP Presenter Flow 在 View 生命周期内收集

- 路径：`trade2/trade-account/src/main/java/com/hstong/trade/account/overview/AccountOverviewFragment.kt:190-236`
- 观察：Presenter 的 `requestState`、`assetCardFlow`、`accountListFlow`、`isDesensitized`、`selectedCurrencyFlow` 均在 `repeatOnLifecycle(STARTED)` 内收集。
- 分类：recommended
- confidence：high
- boundary：kmp-shared

## EV-APP-29 UI 更新通过当前 binding 或 bindingOrNull

- 路径：`trade2/trade-account/src/main/java/com/hstong/trade/account/overview/AccountOverviewFragment.kt:49-236`
- 观察：异步刷新与 Flow 收集场景中使用 `bindingOrNull` 或当前 View 生命周期内 binding。
- 分类：recommended
- confidence：high
- boundary：kmp-shared

## EV-APP-30 WatchListKmp 包装 KMP Service 访问

- 路径：`watchlist-core/src/main/java/com/hstong/stock/core/WatchListKmp.kt:6-22`
- 观察：Android 侧通过 `WatchListKmp` object 包装 `WatchlistService`，调用方可通过 `getService()` 访问。
- 分类：legacy_compatible
- confidence：medium
- boundary：kmp-shared
