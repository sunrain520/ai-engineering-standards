---
doc_id: "app-client-evidence-code-facts"
title: "APP Code Facts"
domain: "app-client"
sub_domains:
  - "module-boundary"
  - "android"
  - "kmp-shared"
  - "build-governance"
doc_type: "evidence-code-facts"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260522-100947-app-client"
source_batches:
  - "app-client-module-boundary-contract-layer"
  - "app-client-android-app-shell-bootstrap"
  - "app-client-android-core-ui-state"
  - "app-client-android-trade-route-provider"
  - "app-client-android-trade-account-page-composition"
  - "app-client-kmp-shared-trade-order-clean-architecture"
  - "app-client-build-governance-gradle-versioning"
tags:
  - "app-client"
  - "evidence"
---

# APP Module Boundary Code Facts

## EV-APP-1: contract 模块构建脚本保持同构

- batch_id: `app-client-module-boundary-contract-layer`
- path:
  - `contract/trade/build.gradle.kts`
  - `contract/quotes/build.gradle.kts`
  - `contract/platform/build.gradle.kts`
- observed_pattern: 三个 contract 模块均声明为 Android library，并使用相同的 Kotlin Android 插件、`compileSdk = 35`、`minSdk = 24`、Java/Kotlin 11 配置、consumer proguard 配置和测试依赖结构。
- file_role: `gradle-module-config`
- evidence_kind: `positive`
- occurrences: 3
- boundary: `contract 模块集合`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-2: contract 模块未在构建脚本中依赖 feature 实现模块

- batch_id: `app-client-module-boundary-contract-layer`
- path:
  - `contract/trade/build.gradle.kts`
  - `contract/quotes/build.gradle.kts`
  - `contract/platform/build.gradle.kts`
- observed_pattern: 三个 contract 模块的 `dependencies` 块只包含 AndroidX、Material、JUnit 和 AndroidX Test 依赖，未出现 `project(":feature:...")`、`project(":app-...")` 或其他 feature 实现模块依赖。
- file_role: `gradle-dependency-config`
- evidence_kind: `positive`
- occurrences: 3
- boundary: `contract 模块集合`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-3: contract 模块当前没有业务实现源码

- batch_id: `app-client-module-boundary-contract-layer`
- path:
  - `contract/trade/src/main/AndroidManifest.xml`
  - `contract/quotes/src/main/AndroidManifest.xml`
  - `contract/platform/src/main/AndroidManifest.xml`
- observed_pattern: 三个 contract 模块的 `src/main` 下只观察到空 AndroidManifest；在本 batch 读取范围内未发现 Kotlin / Java 业务实现源码。
- file_role: `android-manifest`
- evidence_kind: `positive`
- occurrences: 3
- boundary: `contract 模块集合`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `find contract -maxdepth 5` 的文件清单与三个 manifest 内容

## EV-APP-4: 现有 owner-confirmed 文档定义 contract 为稳定跨域边界

- batch_id: `app-client-module-boundary-contract-layer`
- path: `KAZ模块化架构设计规范.md`
- observed_pattern: 模块化设计文档把原生 `contract` 定义为跨业务域协作的稳定边界，典型内容包括 Service 接口、轻量 DTO、必要常量和调用协议；并明确 `feature -> contract` 是允许依赖方向，`contract -> feature`、跨域调用绕过 `contract` 是禁止方向。
- file_role: `owner-confirmed-architecture-doc`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `owner-confirmed 文档`
- confidence: `medium`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-5: contract 模块仍引入 UI 相关外部依赖

- batch_id: `app-client-module-boundary-contract-layer`
- path:
  - `contract/trade/build.gradle.kts`
  - `contract/quotes/build.gradle.kts`
  - `contract/platform/build.gradle.kts`
- observed_pattern: 三个 contract 模块均引入 `androidx.appcompat:appcompat` 和 `com.google.android.material:material`。该事实与“轻量 contract”方向存在潜在治理问题，但当前 batch 未读取到具体源码使用点。
- file_role: `gradle-dependency-config`
- evidence_kind: `unknown`
- occurrences: 3
- boundary: `contract 模块集合`
- confidence: `medium`
- sensitive_handling: `none`
- inferred_from: `null`

## 本批次分类摘要

```yaml
classification:
  recommended:
    - facts:
        - EV-APP-1
        - EV-APP-2
        - EV-APP-3
        - EV-APP-4
      reason: "代码配置与 owner-confirmed 架构文档共同支持 contract 作为稳定跨域边界，且当前未依赖 feature 实现模块。"
  forbidden: []
  legacy_compatible: []
  pending_confirmation:
    - facts:
        - EV-APP-5
      reason: "contract 模块引入 UI 相关依赖是否应收敛，需要架构负责人确认；当前没有源码使用点，不能直接升级为禁止规则。"
  conflict: []
stop_conditions_hit: []
unread_candidates: []
```

## EV-APP-6: App 壳构建按构建类型显式控制高成本校验插件

- batch_id: `app-client-android-app-shell-bootstrap`
- path: `app-kaz/build.gradle`
- observed_pattern: App 壳根据 taskName 和 `hs.enableManifestExportedCheck` / `hs.enableAndroidAop` 属性决定是否启用 manifest exported 检查与 Android AOP；debug、install、connected、test 类任务默认跳过，非 debug-like 构建默认启用。
- file_role: `app-build-config`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `Android App Shell`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-7: App 壳 Manifest 使用 placeholder 注入渠道和网络配置

- batch_id: `app-client-android-app-shell-bootstrap`
- path: `app-kaz/src/main/AndroidManifest.xml`
- observed_pattern: App manifest 中 `networkSecurityConfig`、推送 appKey/appSecret、push host、Sensors scheme 等值通过 Gradle placeholder 注入，Service/Activity exported 明确声明，调试覆盖项使用 `tools:replace` 限定。
- file_role: `android-manifest`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `Android App Shell`
- confidence: `medium`
- sensitive_handling: `placeholder-only`
- inferred_from: `null`

## EV-APP-8: GlobalApplication 只在宿主进程执行完整业务初始化

- batch_id: `app-client-android-app-shell-bootstrap`
- path: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`
- observed_pattern: `onCreate` 先判断 `isHostProcess`，子进程只初始化 AndroidConfig、BuildConfigs 与子进程配置后返回；宿主进程才注册 EventBus、初始化 Router、RN runtime、Push、语言、网络、业务容器和生命周期服务。
- file_role: `application-bootstrap`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `Android App Shell`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-9: Core UI Kit 通过分层 Fragment 基类承载页面生命周期语义

- batch_id: `app-client-android-core-ui-state`
- path:
  - `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/base/BaseFragment.kt`
  - `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseLoadDataFragment.kt`
- observed_pattern: `BaseFragment -> BaseMvvmFragment -> BaseLoadDataFragment` 形成页面基类层级；基础层负责布局、视图缓存和精确可见性，加载层负责 loading/error/empty/content、首次可见自动加载、刷新和加载更多。
- file_role: `ui-base-class`
- evidence_kind: `positive`
- occurrences: 2
- boundary: `Android Core UI`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-10: BaseViewModel 集中暴露加载状态、错误、Toast 和 Rx 订阅管理

- batch_id: `app-client-android-core-ui-state`
- path: `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseViewModel.kt`
- observed_pattern: `BaseViewModel` 使用 `LiveData<LoadingState>`、`LiveData<String>` 表达加载状态、错误和 Toast，提供 `onLoadInitData`、`onRefresh`、`onLoadMore` 钩子，并在 `onCleared` 清理 `CompositeDisposable` 与 keyed disposable。
- file_role: `viewmodel-base-class`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `Android Core UI`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-11: Core UI Kit 构建脚本暴露基础 UI 能力但存在直接依赖聚合 KMP 入口的历史问题

- batch_id: `app-client-android-core-ui-state`
- path: `core/core-ui-kit/build.gradle`
- observed_pattern: 模块开启 viewBinding、使用 Java/Kotlin 17，`api` 暴露 `hscomponents`、`shimmer`、`resources:library` 等 UI 能力；同时源码注释标记“todo 不应该直接依赖整个 kmp 入口”，当前仍 `implementation Deps.Lib.biz_kaz_app`。
- file_role: `gradle-module-config`
- evidence_kind: `legacy`
- occurrences: 1
- boundary: `Android Core UI`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-12: 交易核心模块作为共享 UI/工具层向交易子模块开放基础依赖

- batch_id: `app-client-android-trade-route-provider`
- path:
  - `feature/trade/trade-core/build.gradle`
  - `feature/trade/trade-core/README.md`
- observed_pattern: `trade-core` README 定位为交易模块共享 UI 组件、工具类和数据模型；构建脚本 `api` 暴露 `core-ui-kit`、`core-utils` 和 `resources:library`，供交易子模块复用。
- file_role: `feature-core-module`
- evidence_kind: `positive`
- occurrences: 2
- boundary: `Android Trade Feature`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-13: 旧 TradeRouter 仍以 Deprecated 单例承载历史 H5 跳转

- batch_id: `app-client-android-trade-route-provider`
- path: `feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/TradeRouter.kt`
- observed_pattern: `TradeRouter` 被标记 `@Deprecated("")`，仍通过 `PageRouter` 拼接 H5 URL 并发起页面跳转；该模式属于历史兼容入口，不应作为新增路由模式扩散。
- file_role: `legacy-router`
- evidence_kind: `legacy`
- occurrences: 1
- boundary: `Android Trade Feature`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-14: 证券账户页以容器 Fragment 编排二级 Tab、ViewPager 与跨页导航

- batch_id: `app-client-android-trade-account-page-composition`
- path: `feature/trade/trade-account/src/main/java/com/hstong/trade/account/security/SecurityAccountFragment.kt`
- observed_pattern: `SecurityAccountFragment` 作为账户容器，持有 binding、`SecurityPagerAdapter`、`SecondTabFragment`、`FragmentUserVisibleDelegate` 和账户导航 ViewModel；它负责初始化二级 Tab、ViewPager、PDP 通知条、导航请求消费和可见性刷新。
- file_role: `account-container-fragment`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `Android Trade Account`
- confidence: `high`
- sensitive_handling: `account-identifier-structure-only`
- inferred_from: `null`

## EV-APP-15: 账户页直接注入 KMP UseCase 控制二级 Tab 排序，属于需收敛的跨层调用

- batch_id: `app-client-android-trade-account-page-composition`
- path: `feature/trade/trade-account/src/main/java/com/hstong/trade/account/security/SecurityAccountFragment.kt`
- observed_pattern: `SecurityAccountFragment` 中存在注释“TODO 待优化，直接调用了 usecase”，并直接 `inject<TabSortConfigUseCase>` 后用于 `getTabOrder` 与 `sortChangedFlow` 监听；该事实适合作为待确认/历史兼容，不足以直接禁止。
- file_role: `account-container-fragment`
- evidence_kind: `legacy`
- occurrences: 1
- boundary: `Android Trade Account`
- confidence: `medium`
- sensitive_handling: `account-identifier-structure-only`
- inferred_from: `null`

## EV-APP-16: KMP trade-order 使用 UseCase 包装 Repository 查询并隐藏给 ObjC

- batch_id: `app-client-kmp-shared-trade-order-clean-architecture`
- path: `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/usecase/GetAllOrdersUseCase.kt`
- observed_pattern: `GetAllOrdersUseCase` 注入 `OrderRepository` 与 `TradingMarket`，以 `suspend operator fun invoke` 返回 `Result<OrderPage, HsNetworkException>`；类标记 `@HiddenFromObjC`，说明该 UseCase 不是直接暴露给 iOS 的公共 ABI。
- file_role: `kmp-domain-usecase`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `KMP Shared Trade Order`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-17: KMP Repository 接口按业务语义声明订单、成交和费用数据访问能力

- batch_id: `app-client-kmp-shared-trade-order-clean-architecture`
- path: `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/repository/OrderRepository.kt`
- observed_pattern: `OrderRepository` 作为 domain repository 接口，集中声明最近订单、全部订单、费用明细、成交明细和订单详情查询，统一返回 `Result<*, HsNetworkException>`。
- file_role: `kmp-domain-repository`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `KMP Shared Trade Order`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-18: KMP Presenter 以 StateFlow 输出 UI 状态并通过 RequestGate 控制分页请求

- batch_id: `app-client-kmp-shared-trade-order-clean-architecture`
- path: `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/presentation/all/AllOrdersPresenter.kt`
- observed_pattern: `AllOrdersPresenter` 实现 `PagePresenter<AllOrdersUiState>`，内部维护 `MutableStateFlow`、分页游标和 `RequestGate`；通过 `executePageRequest` 组合 UseCase、空态判断、分页合并、失败重置和筛选状态更新。
- file_role: `kmp-presentation-presenter`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `KMP Shared Trade Order`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-19: KMP settings.gradle.kts 显式拆分 core、stock、trade、market、platform 与 apps 模块

- batch_id: `app-client-kmp-shared-trade-order-clean-architecture`
- path: `submodules/biz-common/settings.gradle.kts`
- observed_pattern: KMP 子项目启用 typesafe project accessors，include 了 `modules:core:*`、`modules:stock:*`、`modules:trade:*`、`modules:market`、`modules:platform:*` 以及 `apps:kaz-app` / `apps:test-app`。
- file_role: `kmp-module-matrix`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `KMP Shared`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-20: 根 settings.gradle 用本地工程替换关键 Maven 产物支持联调

- batch_id: `app-client-build-governance-gradle-versioning`
- path: `settings.gradle`
- observed_pattern: 根工程通过 `dependencySubstitution` 将 `hscomponents`、`kaz-pdp`、`hs-ads`、`foundation`、`core-ui-kit`、`core-utils` 等 Maven 坐标替换为本地 project，并用 `includeBuild 'hszq-version'` 接入版本治理插件。
- file_role: `gradle-settings`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `Build Governance`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-21: 根 build.gradle 提供本地快速构建开关跳过校验类任务

- batch_id: `app-client-build-governance-gradle-versioning`
- path: `build.gradle`
- observed_pattern: `hs.local.fast.build` / `localFastBuild` / `HS_LOCAL_FAST_BUILD` 为 true 时，根构建在 `projectsEvaluated` 后禁用 check、lint、test、androidTest、connected、jacoco、kover 等任务。
- file_role: `gradle-root-build`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `Build Governance`
- confidence: `high`
- sensitive_handling: `credential-values-not-read`
- inferred_from: `null`

## EV-APP-22: hszq-version 以 included build 方式提供内部版本插件

- batch_id: `app-client-build-governance-gradle-versioning`
- path: `hszq-version/build.gradle`
- observed_pattern: `hszq-version` 使用 `kotlin` 与 `java-gradle-plugin`，Java/Kotlin target 为 17，并注册 `com.hstong.base.hszq-version` 插件实现类 `VersionPlugin`。
- file_role: `included-build-plugin`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `Build Governance`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`
