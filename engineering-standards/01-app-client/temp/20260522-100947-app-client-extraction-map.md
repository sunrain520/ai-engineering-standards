---
doc_id: "app-client-20260522-100947-app-client-extraction-map"
title: "App Client Extraction Map：kaz-mvp"
domain: "app-client"
sub_domain: "common"
doc_type: "extraction-map"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "extraction-map"
  - "context-governance"
---

# App Client Extraction Map：kaz-mvp

## 1. 来源

- run_id: `20260522-100947-app-client`
- source_profile: `engineering-standards/01-app-client/temp/20260522-100947-app-client-project-profile.md`
- extraction_mode: `profile-first`
- project_path: `/Users/kuang/xiaobu/kaz-mvp`

## 2. 映射矩阵

| domain | sub_domain | module | task_type | evidence_kind | candidate_paths | excluded_paths |
| --- | --- | --- | --- | --- | --- | --- |
| app-client | android | app-shell | app-bootstrap | positive | `app-kaz/build.gradle`; `app-kaz/src/main/AndroidManifest.xml`; `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt` | `app-kaz/libs/`; `gradle.properties` |
| app-client | android | app-core | startup-container | positive | `app-core/build.gradle`; `app-core/src/main/AndroidManifest.xml`; `app-core/src/main/java/com/hstong/app_core/main/mvvm/MainTabViewModel.kt` | `app-core/libs/`; generated build outputs |
| app-client | android | core-ui-kit | base-fragment-ui-state | positive | `core/core-ui-kit/build.gradle`; `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/base/BaseFragment.kt`; `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseLoadDataFragment.kt` | generated build outputs |
| app-client | module-boundary | contract | cross-module-contract | positive | `contract/trade/build.gradle.kts`; `contract/quotes/build.gradle.kts`; `contract/platform/build.gradle.kts` | implementation modules outside selected batch |
| app-client | android | trade-core | route-provider-and-login-entry | positive | `feature/trade/trade-core/build.gradle`; `feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/TradeRouter.kt`; `feature/trade/trade-core/README.md` | credential files; unrelated trade submodules |
| app-client | android | trade-order | order-page-provider | positive | `feature/trade/trade-order/build.gradle`; `feature/trade/trade-order/src/main/java/com/hstong/trade/order/provider/OrderPageProvider.kt`; `feature/trade/trade-order/README.md` | production order data; screenshots |
| app-client | android | trade-account | account-page-composition | positive | `feature/trade/trade-account/build.gradle`; `feature/trade/trade-account/src/main/java/com/hstong/trade/account/security/SecurityAccountFragment.kt`; `.serena/memories/security-account/fragment-hierarchy.md` | account data fixtures; sensitive configs |
| app-client | android | quotes-watchlist | market-watchlist-ui | positive | `feature/kaz-quotes/market/build.gradle`; `feature/kaz-quotes/watchlist/build.gradle`; `feature/kaz-quotes/watchlist/src/main/java/com/kaz/watchlist/WatchListFragment.kt` | screenshots; build outputs |
| app-client | android | user-operations | settings-message-center | positive | `feature/user_operations/kaz_me/build.gradle`; `feature/user_operations/message_center/build.gradle`; `feature/user_operations/message_center/AGENTS.md` | local runtime agent outputs |
| app-client | kmp-shared | biz-common-core | kmp-app-assembly | positive | `submodules/biz-common/settings.gradle.kts`; `submodules/biz-common/apps/kaz-app/build.gradle.kts`; `submodules/biz-common/apps/kaz-app/src/commonMain/kotlin/com/hs/kmp/app/ApplicationLogic.kt` | `submodules/biz-common/.git/`; generated outputs |
| app-client | kmp-shared | trade-order-kmp | clean-architecture-usecase-repository | positive | `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/usecase/GetAllOrdersUseCase.kt`; `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/repository/OrderRepository.kt`; `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/presentation/all/AllOrdersPresenter.kt` | `submodules/biz-common/.git/`; generated outputs |
| app-client | kmp-shared | trade-account-kmp | account-assets-clean-architecture | positive | `.serena/memories/assets-module-architecture.md`; `.serena/memories/securityaccount-architecture.md`; `submodules/biz-common/modules/trade/trade-account/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/account/securityaccount/presentation/asset/SecurityAssetPresenter.kt` | account data snapshots; sensitive configs |
| app-client | ui-component | hscomponents | design-system-consumption | pending | `submodules/hscomponents/hscomponents`; `KAZ模块化架构设计规范.md`; `AGENTS.md` | `submodules/hscomponents/.git/`; binary artifacts |
| app-client | build-governance | gradle-root | dependency-version-local-fast-build | positive | `settings.gradle`; `build.gradle`; `hszq-version/build.gradle` | `gradle.properties`; `local.properties`; `hsconfig/` |
| app-client | testing | test-surface | local-test-and-skip-policy | pending | `app-core/src/test`; `jacocoreport/`; root `build.gradle` local fast build task skip policy | credentials and generated coverage outputs |
| app-client | performance | startup-and-page | startup-main-tab-performance | pending | `app-core/`; `core/capability/updata-apk/`; `app-core/src/main/java/com/hstong/app_core/main/mvvm/MainTabViewModel.kt` | runtime telemetry raw data |
| app-client | industry-trading | trading-domain | securities-account-order-constraints | pending | `feature/trade/`; `submodules/biz-common/modules/trade/`; `openspec/specs/trade-place-order/spec.md` | user/account/order data; requires owner confirmation |

## 3. 代表性 evidence 候选

| candidate_id | path | reason | expected_fact | read_priority |
| --- | --- | --- | --- | --- |
| CAND-001 | `settings.gradle` | 根模块声明和 includeBuild 是全局架构入口 | 多模块边界与本地替换关系 | high |
| CAND-002 | `KAZ模块化架构设计规范.md` | 已有模块化规范，适合做冲突和 owner-confirmed 对照 | 模块分层、依赖方向、KMP/Native 边界 | high |
| CAND-003 | `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt` | App 壳启动和全局装配入口 | App Shell 职责边界 | high |
| CAND-004 | `app-core/src/main/java/com/hstong/app_core/main/mvvm/MainTabViewModel.kt` | 首页 Tab 和启动容器候选 | 宿主容器状态与首页编排 | high |
| CAND-005 | `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseLoadDataFragment.kt` | 原生 UI 状态基类候选 | loading/error/empty/success 处理模式 | high |
| CAND-006 | `contract/trade/build.gradle.kts` | 契约层模块候选 | contract 是否保持轻量稳定 | medium |
| CAND-007 | `feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/TradeRouter.kt` | 交易路由入口候选 | 跨模块路由/Provider 交互模式 | high |
| CAND-008 | `feature/trade/trade-order/src/main/java/com/hstong/trade/order/provider/OrderPageProvider.kt` | 订单页面 Provider 候选 | feature 对外暴露边界 | high |
| CAND-009 | `feature/trade/trade-account/src/main/java/com/hstong/trade/account/security/SecurityAccountFragment.kt` | 账户页组合入口候选 | Fragment 层级与页面编排模式 | high |
| CAND-010 | `.serena/memories/security-account/fragment-hierarchy.md` | Serena 记忆已归纳页面层级 | 用于选择正式 evidence 文件，不替代源码 evidence | medium |
| CAND-011 | `submodules/biz-common/settings.gradle.kts` | KMP 子项目模块入口 | KMP 模块矩阵 | high |
| CAND-012 | `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/usecase/GetAllOrdersUseCase.kt` | KMP UseCase 候选 | Clean Architecture 业务用例模式 | high |
| CAND-013 | `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/repository/OrderRepository.kt` | KMP Repository 接口候选 | domain repository 边界 | high |
| CAND-014 | `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/presentation/all/AllOrdersPresenter.kt` | KMP Presenter 候选 | commonMain 表现层状态输出模式 | high |
| CAND-015 | `hszq-version/build.gradle` | 版本管理插件候选 | 依赖版本治理方式 | medium |

## 4. 排除范围

| path | reason |
| --- | --- |
| `gradle.properties` | secret / credential fields |
| `local.properties` | local environment |
| `hsconfig/` | signing or environment config |
| `AGENTS.md` sensitive token lines | secret token field; only sanitized governance facts allowed |
| `.claude/`, `.codex/`, `.agents/` | runtime generated assets |
| `.gradle/`, `.kotlin/`, `build/` | generated / cache |
| `.git`, `.gitnexus`, `.code-review-graph`, `.serena/cache` | VCS or indexing internals |
| `repo/`, `libs/`, `*.jar`, `*.aar` | dependency / binary artifacts |
| screenshots and image folders | not needed for code standard extraction unless user selects UI visual batch |

## 5. batch 生成提示

- 同一 batch 只能覆盖一个主要 `domain + sub_domain + module/task_type`。
- `trade-*` 和 `industry-trading` batch 涉及交易/账户/订单，正式规则需要负责人确认高风险边界。
- `submodules/biz-common` 是子模块/子工作区，正式萃取前建议确认是否允许作为同一 project scope 读取。
- Serena memory 可用于定位候选文件，但不能替代 `code-facts` 的源码 evidence。
- 本轮 `profile-first` 不生成 `standard-*.md`、`ai-rules.md` 或正式 review checklist。
