---
doc_id: "app-client-20260526-134644-extraction-map"
title: "Extraction Map — kaz-mvp"
domain: "app-client"
sub_domain: "common"
doc_type: "extraction-map"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260526-134644-app-client"
tags:
  - "app-client"
  - "extraction-map"
---

# Extraction Map — kaz-mvp

> 该映射只列出候选 evidence 的路径模式与抓取意图，未读取业务源码。下游 `facts-and-classification` 在选定 batch 后才进行实际 evidence 采集。

## 1. 映射矩阵

| domain | sub_domain | module | task_type | evidence_kind | candidate_signals (path patterns) | anti_signals |
| --- | --- | --- | --- | --- | --- | --- |
| app-client | android | app-kaz | app-bootstrap | positive | `app-kaz/build.gradle`、`app-kaz/src/main/AndroidManifest.xml`、`app-kaz/src/main/java/**/Application*.kt`、`app-kaz/src/main/java/**/MainActivity*.kt` | `app-kaz/build/`、`app-kaz/google-services.json` |
| app-client | android | app-core | app-bootstrap | positive | `app-core/src/main/java/**/MainActivity*.kt`、`app-core/src/main/java/**/MainTabViewModel*.kt`、`app-core/src/main/java/**/Loading*.kt`、`app-core/src/main/java/**/CheckUpdateTask*.kt` | `app-core/build/` |
| app-client | android | feature/trade/trade-execution | trade-order | positive | `feature/trade/trade-execution/src/main/java/**/*Activity*.kt`、`**/*ViewModel*.kt`、`**/*UseCase*.kt`、`**/*Repository*.kt` | `feature/trade/trade-execution/build/` |
| app-client | android | feature/trade/trade-execution | form-validation | positive | `**/Form*.kt`、`**/Validator*.kt`、`**/InputField*.kt`、`**/strings*.xml` | 测试桩 |
| app-client | android | feature/trade/trade-account | account-binding | positive | `feature/trade/trade-account/src/main/java/**/*BindActivity*.kt`、`**/*AuthRepository*.kt` | `**/test/**`（暂时排除测试代码） |
| app-client | android | feature/trade/trade-order | order-list | positive | `feature/trade/trade-order/src/main/java/**/*ListFragment*.kt`、`**/*Adapter*.kt`、`**/*PagingSource*.kt` | build artifacts |
| app-client | android | feature/trade/trade-core | trade-foundation | positive | `feature/trade/trade-core/src/main/java/**/Trade*Manager*.kt`、`**/*Service*.kt`、`**/*Constants*.kt` | build artifacts |
| app-client | android | feature/kaz-quotes/market | market-list | positive | `feature/kaz-quotes/market/src/main/java/**/*MarketFragment*.kt`、`**/*ListAdapter*.kt`、`**/*PushHandler*.kt` | build artifacts |
| app-client | android | feature/kaz-quotes/watchlist | watchlist-edit | positive | `feature/kaz-quotes/watchlist/src/main/java/**/*WatchlistViewModel*.kt`、`**/*Repository*.kt`、`**/*RoomDao*.kt` | build artifacts |
| app-client | android | feature/kaz-quotes/quotes-common | quotes-shared | positive | `feature/kaz-quotes/quotes-common/src/main/java/**/Quotes*Manager*.kt`、`**/*Subscription*.kt`、`**/*WebSocket*.kt` | build artifacts |
| app-client | android | feature/community_info/community | feed-list | positive | `feature/community_info/community/src/main/java/**/*Fragment*.kt`、`**/*Adapter*.kt`、`**/Webview*.kt` | build artifacts |
| app-client | android | feature/user_operations/kaz_me | me-page | positive | `feature/user_operations/kaz_me/src/main/java/**/*Fragment*.kt`、`**/*UseCase*.kt`、`feature/user_operations/AGENTS.md` | build artifacts |
| app-client | android | feature/user_operations/message_center | notification-list | positive | `feature/user_operations/message_center/src/main/java/**/*Fragment*.kt`、`**/*Adapter*.kt`、`**/*PushReceiver*.kt` | build artifacts |
| app-client | android | core/core-ui-kit | ui-component | positive | `core/core-ui-kit/src/main/java/**/Hs*View*.kt`、`**/Theme*.kt`、`core/core-ui-kit/src/main/res/values/**.xml` | `**/test/**` |
| app-client | android | core/core-utils | utility-lib | positive | `core/core-utils/src/main/java/**/Ext*.kt`、`**/Logger*.kt`、`**/DateUtil*.kt` | build artifacts |
| app-client | android | core/capability/kaz-pdp | ad-sdk | positive | `core/capability/kaz-pdp/src/main/java/**/Ad*Manager*.kt`、`**/*Tracking*.kt` | build artifacts |
| app-client | android | core/capability/share | social-share | positive | `core/capability/share/src/main/java/**/Share*Activity*.kt`、`**/*Provider*.kt` | build artifacts |
| app-client | android | core/capability/react-native | rn-bridge | positive | `core/capability/react-native/src/main/java/**/*RnBridge*.kt`、`**/*Module*.kt` | build artifacts |
| app-client | android | core/capability/web | webview-bridge | positive | `core/capability/web/src/main/java/**/*WebActivity*.kt`、`**/*JsBridge*.kt` | build artifacts |
| app-client | kmp-shared | contract/trade | module-contract | positive | `contract/trade/build.gradle.kts`、`contract/trade/src/main/**/*Contract*.kt`、`**/*Provider*.kt` | build artifacts |
| app-client | kmp-shared | contract/quotes | module-contract | positive | `contract/quotes/build.gradle.kts`、`contract/quotes/src/main/**/*Contract*.kt` | build artifacts |
| app-client | kmp-shared | contract/platform | module-contract | positive | `contract/platform/build.gradle.kts`、`contract/platform/src/main/**/*Contract*.kt` | build artifacts |
| app-client | kmp-shared | submodules/biz-common/contract | kmp-contract / expect-actual | positive | `submodules/biz-common/contract/src/commonMain/**/*Expect*.kt`、`submodules/biz-common/contract/src/{androidMain,iosMain}/**/*Actual*.kt` | `submodules/biz-common/**/build/` |
| app-client | kmp-shared | submodules/biz-common/bizcommon | kmp-bizcommon | positive | `submodules/biz-common/bizcommon/src/commonMain/**/*Repository*.kt`、`**/*Domain*.kt` | KMP build artifacts |
| app-client | kmp-shared | submodules/biz-common/common-provider | kmp-platform-bridge | positive | `submodules/biz-common/common-provider/src/commonMain/**/*Provider*.kt`、`**/expect.kt` | KMP build artifacts |
| app-client | kmp-shared | submodules/biz-common/biz-search | kmp-search | positive | `submodules/biz-common/biz-search/src/commonMain/**/*SearchRepository*.kt` | KMP build artifacts |
| app-client | kmp-shared | submodules/biz-common/modules/market | kmp-market | positive | `submodules/biz-common/modules/market/src/commonMain/**/*MarketUseCase*.kt` | KMP build artifacts |
| app-client | android | settings.gradle / build-logic | gradle-governance | positive | `settings.gradle`、`build.gradle`、`hszq-version/`、`gradle.properties` | `build/`、`/.gradle/` |

## 2. evidence_kind 说明

- `positive` — 团队认为符合期望写法的代表性候选
- `negative` — 反例（本阶段未列出，由 facts-and-classification 在 batch 内识别）
- `legacy` — 历史模式，待迁移
- `unknown` — 待确认

## 3. anti_signals（统一适用）

- 任何模块的 `build/`、`.gradle/`、`.idea/`、`.kotlin/` 目录
- `submodules/`（除 `biz-common` 外）— `.gitignore` 标注的本地非源
- `pager_reach/` 各处
- `app-kaz/google-services.json`、`local.properties`

## 4. 行业子领域

- `industry: securities` — 候选维度（quotes / trade / order / watchlist / community_info）；激活由下游 dimension-activator 判定，本 map 不直接判定 state。
