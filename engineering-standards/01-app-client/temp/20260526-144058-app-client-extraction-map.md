---
doc_id: "app-client-20260526-144058-app-client-extraction-map"
title: "App Client Extraction Map：kaz-mvp"
domain: "app-client"
sub_domain: "common"
doc_type: "extraction-map"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260526-144058-app-client"
tags:
  - "app-client"
  - "extraction-map"
  - "context-governance"
---

# App Client Extraction Map：kaz-mvp

## 1. 来源

- run_id: `20260526-144058-app-client`
- source_profile: `engineering-standards/01-app-client/temp/20260526-144058-app-client-project-profile.md`
- extraction_mode: `profile-first`
- run_mode: `auto`
- GitNexus: `degraded`，本 map 的 `candidate_signals` 来源为目录/manifest/路径采样与目标仓库说明文档。

## 2. 映射矩阵

| domain | sub_domain | module | task_type | evidence_kind | candidate_paths | excluded_paths |
| --- | --- | --- | --- | --- | --- | --- |
| app-client | android | app-shell | app-bootstrap | positive | `app-kaz/build.gradle`; `app-kaz/src/main/AndroidManifest.xml`; `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt` | `app-kaz/libs/`; `gradle.properties` |
| app-client | android | app-core | host-container-main-tab | positive | `app-core/build.gradle`; `app-core/src/main/AndroidManifest.xml`; `app-core/src/main/java/com/hstong/app_core/main/MainActivity.kt`; `app-core/src/main/java/com/hstong/app_core/main/mvvm/MainTabViewModel.kt` | `app-core/libs/`; `build/` |
| app-client | android | core-ui-kit | base-fragment-ui-state | positive | `core/core-ui-kit/build.gradle`; `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/base/BaseFragment.kt`; `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseLoadDataFragment.kt`; `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseViewModel.kt` | `core/core-ui-kit/build/` |
| app-client | module-boundary | contract | cross-module-contract | positive | `contract/trade/build.gradle.kts`; `contract/quotes/build.gradle.kts`; `contract/platform/build.gradle.kts`; `KAZ模块化架构设计规范.md` | `feature/**` for this batch; `gradle.properties` |
| app-client | android | trade-core | route-provider-and-login-entry | positive | `feature/trade/trade-core/build.gradle`; `feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/TradeRouter.kt`; `feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/provider/IOrderPageProvider.kt`; `specs/FSREQ-20260328-TRADELOGIN-001/design.md` | `feature/trade/**/bug*`; account/order data dumps |
| app-client | android | trade-account | account-page-composition | positive | `feature/trade/trade-account/build.gradle`; `feature/trade/trade-account/src/main/java/com/hstong/trade/account/accountcontainer/AccountContainerFragment.kt`; `feature/trade/trade-account/src/main/java/com/hstong/trade/account/security/SecurityAccountFragment.kt`; `feature/trade/trade-account/src/main/java/com/hstong/trade/account/security/SecurityAccountVM.kt` | `**/*account*data*`; screenshots / attachments |
| app-client | android | trade-order | normal-and-conditional-order-pages | positive | `feature/trade/trade-order/build.gradle`; `feature/trade/trade-order/src/main/java/com/hstong/trade/order/provider/OrderPageProvider.kt`; `feature/trade/trade-order/src/main/java/com/hstong/trade/order/normalorder/all/AllOrderFragment.kt`; `feature/trade/trade-order/src/main/java/com/hstong/trade/order/condorder/ui/all/AllCondOrderListFragment.kt` | `**/*order*data*`; trade account private dumps |
| app-client | android | quotes-watchlist | market-and-watchlist-ui | positive | `feature/kaz-quotes/market/build.gradle`; `feature/kaz-quotes/market/src/main/java/com/kaz/market/MarketFragment.kt`; `feature/kaz-quotes/watchlist/src/main/java/com/kaz/watchlist/WatchListFragment.kt`; `feature/kaz-quotes/watchlist/src/main/java/com/kaz/watchlist/viewmodel/WatchListViewModel.kt` | `**/*market*data*`; generated cache |
| app-client | android | user-operations | profile-message-center | positive | `feature/user_operations/kaz_me/build.gradle`; `feature/user_operations/message_center/build.gradle`; `feature/user_operations/AGENTS.md` | PII exports; account profile dumps |
| app-client | kmp-shared | biz-common-trade-order | clean-architecture-usecase-repository | positive | `submodules/biz-common/settings.gradle.kts`; `submodules/biz-common/modules/trade/trade-order/.../GetAllOrdersUseCase.kt`; `.../OrderRepository.kt`; `.../AllOrdersPresenter.kt`; `.../OrderUIMapper.kt` | `submodules/biz-common/**/build/`; `.git/` |
| app-client | kmp-shared | biz-common-trade-account | account-assets-clean-architecture | positive | `submodules/biz-common/modules/trade/trade-account/.../SecurityAccountAssetUseCase.kt`; `.../SecurityAccountRepository.kt`; `.../SecurityAssetPresenter.kt`; `.../SecurityAssetDtoMapper.kt` | account data dumps; `gradle.properties` |
| app-client | build-governance | gradle-root | dependency-version-local-fast-build | positive | `settings.gradle`; `build.gradle`; `hszq-version/build.gradle`; `repo_child_git.json` | `gradle.properties`; `local.properties`; `hsconfig/` |
| app-client | ui-component | hscomponents | design-system-consumption | unknown / pending | `submodules/hscomponents/hscomponents/build.gradle.kts`; `submodules/hscomponents/README.md`; `KAZ模块化架构设计规范.md` | `submodules/hscomponents/**/build/`; `.git/` |
| app-client | industry-trading | trade-place-order | securities-order-constraints | positive / pending | `openspec/specs/trade-place-order/spec.md`; `submodules/biz-common/modules/trade/trade-core/.../CheckBeforePlaceOrderUseCase.kt`; `contract/trade/build.gradle.kts`; `feature/trade/trade-order/.../OrderPageProvider.kt` | order/account real data; production configs |

## 3. 代表性 evidence 候选

| candidate_id | path | reason | expected_fact | read_priority |
| --- | --- | --- | --- | --- |
| CAND-001 | `settings.gradle` | 根模块矩阵和 includeBuild 声明 | APP 壳、core、contract、feature、resources、hscomponents 的装配边界 | high |
| CAND-002 | `build.gradle` | 根构建脚本、插件版本、仓库、dependencySubstitution、local fast build | 构建治理与本地替换策略 | high |
| CAND-003 | `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt` | App 全局初始化入口 | App 壳初始化职责边界 | high |
| CAND-004 | `app-core/src/main/java/com/hstong/app_core/main/mvvm/MainTabViewModel.kt` | 首页 Tab ViewModel | 宿主容器状态与导航编排候选 | medium |
| CAND-005 | `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseLoadDataFragment.kt` | 加载态页面基类 | 页面基类选择和加载状态框架 | high |
| CAND-006 | `contract/trade/build.gradle.kts` | 交易 contract 构建入口 | contract 依赖轻量性 | high |
| CAND-007 | `feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/TradeRouter.kt` | 交易路由入口 | 跨模块路由/Provider 模式 | medium |
| CAND-008 | `feature/trade/trade-account/src/main/java/com/hstong/trade/account/security/SecurityAccountFragment.kt` | 证券账户页入口 | Android 页面组合和 KMP 接入 | medium |
| CAND-009 | `feature/trade/trade-order/src/main/java/com/hstong/trade/order/provider/OrderPageProvider.kt` | 订单页 Provider | trade-core 与 trade-order 的边界协作 | medium |
| CAND-010 | `feature/kaz-quotes/watchlist/src/main/java/com/kaz/watchlist/WatchListFragment.kt` | 自选股 UI 入口 | 行情/自选展示层组织 | medium |
| CAND-011 | `submodules/biz-common/settings.gradle.kts` | KMP 模块矩阵入口 | KMP core/business/app 分层 | high |
| CAND-012 | `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/usecase/GetAllOrdersUseCase.kt` | KMP 订单 UseCase | Clean Architecture domain 层 | high |
| CAND-013 | `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/repository/OrderRepository.kt` | KMP 订单 Repository 接口 | Repository 边界 | high |
| CAND-014 | `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/presentation/all/AllOrdersPresenter.kt` | KMP 订单 Presenter | Presentation 状态流 | high |
| CAND-015 | `submodules/biz-common/modules/trade/trade-account/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/account/securityaccount/presentation/asset/SecurityAssetPresenter.kt` | KMP 账户资产 Presenter | 账户资产状态输出 | medium |
| CAND-016 | `submodules/hscomponents/hscomponents/build.gradle.kts` | 本地组件库模块构建入口 | 组件库接入边界 | low |
| CAND-017 | `openspec/specs/trade-place-order/spec.md` | 下单规格文档 | 交易行业约束候选，不直接变成强制规则 | medium |
| CAND-018 | `KAZ模块化架构设计规范.md` | 模块化架构说明 | owner-confirmed 候选对照，需要用户确认 | medium |

## 4. 排除范围

| path | reason |
| --- | --- |
| `gradle.properties` | secret / credential fields |
| `local.properties` | local environment |
| `hsconfig/` | signing or environment config |
| `.mcp.json` | local tool config |
| `.claude/`, `.codex/`, `.agents/skills/` | runtime generated mirrors |
| `.gradle/`, `.kotlin/`, `build/`, `.cxx/` | generated / cache |
| `.git`, `.gitnexus/`, `.code-review-graph/`, `.serena/` | vcs / graph / index internals |
| `repo/`, `libs/`, `*.jar`, `*.aar` | dependency / binary artifacts |
| `**/*account*data*`, `**/*order*data*`, `**/*market*data*` | possible business or user data; confirm before reading |

## 5. batch 生成提示

- `profile-first` 到此只产生候选，不生成规则。
- 后续 `batch-extraction` 必须从 `batch-plan` 中选择一个 `ready` batch。
- 任何涉及 `industry-trading` 的结论应优先写入 `pending-confirmation` 或拆到 `09-industry`，直到负责人确认行业规则边界。
- `standard-module-boundary.md` 已是 active 基线，contract batch 后续只可做冲突检测或 merge suggestion，不得覆盖已有 active 规则。
