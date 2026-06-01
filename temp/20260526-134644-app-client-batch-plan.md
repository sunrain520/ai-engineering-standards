---
doc_id: "app-client-20260526-134644-batch-plan"
title: "App-Client Batch Plan — kaz-mvp"
domain: "app-client"
sub_domain: "common"
doc_type: "batch-plan"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260526-134644-app-client"
tags:
  - "app-client"
  - "batch-plan"
  - "context-governance"
---

# App-Client Batch Plan — kaz-mvp

## 1. 来源

- run_id: `20260526-134644-app-client`
- source_profile: `temp/20260526-134644-app-client-project-profile.md`
- source_extraction_map: `temp/20260526-134644-app-client-extraction-map.md`
- run_mode: `auto`
- broad_input: `true`（强制 `profile-first`，下一步只能选单 batch）

## 2. 可执行 batch

> 一次萃取只允许选择 1 个 `status: ready` 的 batch。优先级排序见 §4。

```yaml
batches:
  # ===================== HIGH PRIORITY =====================
  - batch_id: "app-client-android-app-bootstrap-app-kaz-p1"
    priority: high
    domain: app-client
    sub_domain: android
    module: app-kaz
    task_type: app-bootstrap
    candidate_files:
      - path: "app-kaz/build.gradle"
        reason: "applicationId / SDK 集成清单(HMS / SensorsData / ARouter / KSP / AOP)"
        evidence_kind: positive
      - path: "app-kaz/src/main/AndroidManifest.xml"
        reason: "Application 入口 / 权限 / 主进程组件声明"
        evidence_kind: positive
      - path: "app-kaz/src/main/java/**/*Application*.kt"
        reason: "Application 初始化顺序 / SDK 注册"
        evidence_kind: positive
      - path: "architecture.md"
        reason: "团队已沉淀的应用启动链路文档,作为对照源"
        evidence_kind: positive
    excluded_paths:
      - { path: "app-kaz/google-services.json", reason: "secret-class config" }
      - { path: "app-kaz/build/", reason: "generated" }
      - { path: "local.properties", reason: "secret-class config" }
    evidence_limit: 8
    rule_limit: 10
    candidate_dimension_ids: ["baseline-*", "end:app-client:bootstrap", "end:app-client:sdk-init", "end:app-client:permissions"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-android-trade-execution-order-p1"
    priority: high
    domain: app-client
    sub_domain: android
    module: feature/trade/trade-execution
    task_type: trade-order
    candidate_files:
      - path: "feature/trade/trade-execution/src/main/java/**/*Activity*.kt"
        reason: "下单页 UI 入口"
        evidence_kind: positive
      - path: "feature/trade/trade-execution/src/main/java/**/*ViewModel*.kt"
        reason: "下单状态管理 / form binding"
        evidence_kind: positive
      - path: "feature/trade/trade-execution/src/main/java/**/*UseCase*.kt"
        reason: "下单业务用例(行业 P0 链路)"
        evidence_kind: positive
      - path: "feature/trade/trade-execution/src/main/java/**/*Repository*.kt"
        reason: "下单网络/缓存边界"
        evidence_kind: positive
      - path: "doc/订单KMP原生重构与模块迁移技术方案.md"
        reason: "团队沉淀的订单链路重构方案,作为对照源"
        evidence_kind: positive
    excluded_paths:
      - { path: "feature/trade/trade-execution/build/", reason: "generated" }
      - { path: "feature/trade/bug图文/", reason: "non-source asset" }
    evidence_limit: 8
    rule_limit: 10
    candidate_dimension_ids: ["baseline-*", "end:app-client:trade-execution", "industry:securities:order-flow", "industry:securities:risk-disclosure"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-kmp-shared-biz-common-contract-p1"
    priority: high
    domain: app-client
    sub_domain: kmp-shared
    module: submodules/biz-common/contract
    task_type: kmp-contract
    candidate_files:
      - path: "submodules/biz-common/contract/build.gradle.kts"
        reason: "KMP target 配置(android / ios)"
        evidence_kind: positive
      - path: "submodules/biz-common/contract/src/commonMain/**/*.kt"
        reason: "expect 声明 / 跨平台契约"
        evidence_kind: positive
      - path: "submodules/biz-common/contract/src/androidMain/**/*.kt"
        reason: "android actual 实现"
        evidence_kind: positive
      - path: "submodules/biz-common/contract/src/iosMain/**/*.kt"
        reason: "ios actual 实现"
        evidence_kind: positive
      - path: "doc/kmp-biz-common-architecture.md"
        reason: "团队沉淀的 KMP 架构说明,作为对照源"
        evidence_kind: positive
    excluded_paths:
      - { path: "submodules/biz-common/**/build/", reason: "generated" }
      - { path: "submodules/biz-common/**/kotlinTransformedMetadataLibraries/", reason: "generated" }
    evidence_limit: 8
    rule_limit: 10
    candidate_dimension_ids: ["baseline-*", "end:app-client:kmp-contract", "end:app-client:expect-actual"]
    expected_skeleton_section: "assets/skeletons/app-client/kmp-shared-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-android-quotes-market-realtime-p1"
    priority: high
    domain: app-client
    sub_domain: android
    module: feature/kaz-quotes/market
    task_type: real-time-push
    candidate_files:
      - path: "feature/kaz-quotes/market/src/main/java/**/*MarketFragment*.kt"
        reason: "市场行情列表 UI"
        evidence_kind: positive
      - path: "feature/kaz-quotes/quotes-common/src/main/java/**/*Subscription*.kt"
        reason: "订阅/退订生命周期管理"
        evidence_kind: positive
      - path: "feature/kaz-quotes/quotes-common/src/main/java/**/*WebSocket*.kt"
        reason: "实时推送通道封装"
        evidence_kind: positive
      - path: "feature/kaz-quotes/quotes-common/src/main/java/**/Quotes*Manager*.kt"
        reason: "行情订阅管理器(共享态)"
        evidence_kind: positive
      - path: "doc/quotes-detail-architecture-analysis.md"
        reason: "团队沉淀行情详情架构分析"
        evidence_kind: positive
    excluded_paths:
      - { path: "feature/kaz-quotes/**/build/", reason: "generated" }
    evidence_limit: 8
    rule_limit: 10
    candidate_dimension_ids: ["baseline-*", "end:app-client:realtime-push", "end:app-client:subscription-lifecycle", "industry:securities:market-data"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  # ===================== MEDIUM PRIORITY =====================
  - batch_id: "app-client-android-trade-account-binding-p1"
    priority: medium
    domain: app-client
    sub_domain: android
    module: feature/trade/trade-account
    task_type: account-binding
    candidate_files:
      - path: "feature/trade/trade-account/src/main/java/**/*BindActivity*.kt"
        reason: "账户绑定 UI / 流程"
      - path: "feature/trade/trade-account/src/main/java/**/*AuthRepository*.kt"
        reason: "鉴权数据源"
      - path: "doc/trade-login-native-call-guide.md"
        reason: "团队登录调用指南"
    excluded_paths: [{ path: "feature/trade/trade-account/build/", reason: "generated" }]
    evidence_limit: 6
    rule_limit: 8
    candidate_dimension_ids: ["baseline-*", "end:app-client:auth-flow", "industry:securities:account-binding"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-android-trade-order-list-p1"
    priority: medium
    domain: app-client
    sub_domain: android
    module: feature/trade/trade-order
    task_type: order-list
    candidate_files:
      - path: "feature/trade/trade-order/src/main/java/**/*ListFragment*.kt"
        reason: "订单列表 UI"
      - path: "feature/trade/trade-order/src/main/java/**/*PagingSource*.kt"
        reason: "分页加载"
      - path: "feature/trade/trade-order/src/main/java/**/*Adapter*.kt"
        reason: "列表渲染"
    excluded_paths: [{ path: "feature/trade/trade-order/build/", reason: "generated" }]
    evidence_limit: 6
    rule_limit: 8
    candidate_dimension_ids: ["baseline-*", "end:app-client:list-pagination", "end:app-client:adapter-pattern"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-android-watchlist-edit-p1"
    priority: medium
    domain: app-client
    sub_domain: android
    module: feature/kaz-quotes/watchlist
    task_type: watchlist-edit
    candidate_files:
      - path: "feature/kaz-quotes/watchlist/src/main/java/**/*ViewModel*.kt"
        reason: "自选列表状态管理"
      - path: "feature/kaz-quotes/watchlist/src/main/java/**/*Repository*.kt"
        reason: "自选数据源(本地+远端)"
      - path: "feature/kaz-quotes/watchlist/src/main/java/**/*RoomDao*.kt"
        reason: "本地缓存层"
    excluded_paths: [{ path: "feature/kaz-quotes/watchlist/build/", reason: "generated" }]
    evidence_limit: 6
    rule_limit: 8
    candidate_dimension_ids: ["baseline-*", "end:app-client:local-cache", "end:app-client:room-dao", "industry:securities:watchlist"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-android-core-ui-kit-p1"
    priority: medium
    domain: app-client
    sub_domain: android
    module: core/core-ui-kit
    task_type: ui-component
    candidate_files:
      - path: "core/core-ui-kit/src/main/java/**/Hs*View*.kt"
        reason: "团队自定义 UI 组件命名规范"
      - path: "core/core-ui-kit/src/main/java/**/Theme*.kt"
        reason: "主题封装"
      - path: "core/core-ui-kit/src/main/res/values/**.xml"
        reason: "通用样式资源"
    excluded_paths: [{ path: "core/core-ui-kit/build/", reason: "generated" }]
    evidence_limit: 6
    rule_limit: 8
    candidate_dimension_ids: ["baseline-*", "end:app-client:ui-component", "end:app-client:design-token"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-android-capability-web-jsbridge-p1"
    priority: medium
    domain: app-client
    sub_domain: android
    module: core/capability/web
    task_type: webview-bridge
    candidate_files:
      - path: "core/capability/web/src/main/java/**/*WebActivity*.kt"
        reason: "WebView 容器"
      - path: "core/capability/web/src/main/java/**/*JsBridge*.kt"
        reason: "JS 桥接"
    excluded_paths: [{ path: "core/capability/web/build/", reason: "generated" }]
    evidence_limit: 6
    rule_limit: 8
    candidate_dimension_ids: ["baseline-*", "end:app-client:webview", "end:app-client:jsbridge", "baseline:security:web-permission"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-android-gradle-governance-p1"
    priority: medium
    domain: app-client
    sub_domain: android
    module: gradle-build-logic
    task_type: gradle-governance
    candidate_files:
      - path: "settings.gradle"
        reason: "模块装配 / dependencySubstitution / 自研插件 gradle-repo / module-repo"
      - path: "build.gradle"
        reason: "根级 Gradle 配置"
      - path: "hszq-version/"
        reason: "版本控制本地 includeBuild"
      - path: "gradle.properties"
        reason: "全局编译配置"
      - path: "KAZ模块化架构设计规范.md"
        reason: "团队已沉淀的模块化架构规范"
    excluded_paths:
      - { path: "build/", reason: "generated" }
      - { path: ".gradle/", reason: "generated" }
    evidence_limit: 8
    rule_limit: 10
    candidate_dimension_ids: ["baseline-*", "end:app-client:gradle-governance", "end:app-client:module-substitution"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  # ===================== LOW PRIORITY =====================
  - batch_id: "app-client-android-rn-bridge-p1"
    priority: low
    domain: app-client
    sub_domain: android
    module: core/capability/react-native
    task_type: rn-bridge
    candidate_files:
      - path: "core/capability/react-native/src/main/java/**/*RnBridge*.kt"
        reason: "RN 模块桥接"
    excluded_paths: [{ path: "core/capability/react-native/build/", reason: "generated" }]
    evidence_limit: 5
    rule_limit: 6
    candidate_dimension_ids: ["baseline-*", "end:app-client:rn-bridge"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-android-share-capability-p1"
    priority: low
    domain: app-client
    sub_domain: android
    module: core/capability/share
    task_type: social-share
    candidate_files:
      - path: "core/capability/share/src/main/java/**/Share*Activity*.kt"
      - path: "core/capability/share/src/main/java/**/*Provider*.kt"
    excluded_paths: [{ path: "core/capability/share/build/", reason: "generated" }]
    evidence_limit: 5
    rule_limit: 6
    candidate_dimension_ids: ["baseline-*", "end:app-client:social-share"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-android-ad-sdk-pdp-p1"
    priority: low
    domain: app-client
    sub_domain: android
    module: core/capability/kaz-pdp
    task_type: ad-sdk
    candidate_files:
      - path: "core/capability/kaz-pdp/src/main/java/**/Ad*Manager*.kt"
      - path: "core/capability/kaz-pdp/src/main/java/**/*Tracking*.kt"
    excluded_paths: [{ path: "core/capability/kaz-pdp/build/", reason: "generated" }]
    evidence_limit: 5
    rule_limit: 6
    candidate_dimension_ids: ["baseline-*", "end:app-client:tracking"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-android-message-center-p1"
    priority: low
    domain: app-client
    sub_domain: android
    module: feature/user_operations/message_center
    task_type: notification-list
    candidate_files:
      - path: "feature/user_operations/message_center/src/main/java/**/*Fragment*.kt"
      - path: "feature/user_operations/message_center/src/main/java/**/*PushReceiver*.kt"
    excluded_paths: [{ path: "feature/user_operations/message_center/build/", reason: "generated" }]
    evidence_limit: 5
    rule_limit: 6
    candidate_dimension_ids: ["baseline-*", "end:app-client:push-notification"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-android-community-feed-p1"
    priority: low
    domain: app-client
    sub_domain: android
    module: feature/community_info/community
    task_type: feed-list
    candidate_files:
      - path: "feature/community_info/community/src/main/java/**/*Fragment*.kt"
      - path: "feature/community_info/community/src/main/java/**/*Adapter*.kt"
    excluded_paths: [{ path: "feature/community_info/community/build/", reason: "generated" }]
    evidence_limit: 5
    rule_limit: 6
    candidate_dimension_ids: ["baseline-*", "end:app-client:feed-list", "end:app-client:webview"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  - batch_id: "app-client-kmp-shared-biz-common-bizcommon-p1"
    priority: low
    domain: app-client
    sub_domain: kmp-shared
    module: submodules/biz-common/bizcommon
    task_type: kmp-bizcommon
    candidate_files:
      - path: "submodules/biz-common/bizcommon/src/commonMain/**/*.kt"
        reason: "KMP 业务公共层"
    excluded_paths:
      - { path: "submodules/biz-common/**/build/", reason: "generated" }
      - { path: "submodules/biz-common/**/kotlinTransformedMetadataLibraries/", reason: "generated" }
    evidence_limit: 6
    rule_limit: 8
    candidate_dimension_ids: ["baseline-*", "end:app-client:kmp-bizcommon"]
    expected_skeleton_section: "assets/skeletons/app-client/kmp-shared-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: ready

  # ===================== PENDING-CONFIRMATION =====================
  - batch_id: "app-client-android-app-core-bootstrap-p1"
    priority: high
    domain: app-client
    sub_domain: android
    module: app-core
    task_type: app-bootstrap
    candidate_files:
      - path: "app-core/src/main/java/**/MainActivity*.kt"
        reason: "启动核心 MainActivity(architecture.md 描述)"
        evidence_kind: positive
      - path: "app-core/src/main/java/**/MainTabViewModel*.kt"
        reason: "主 Tab 装配"
        evidence_kind: positive
      - path: "app-core/src/main/java/**/Loading*.kt"
        reason: "闪屏"
        evidence_kind: positive
      - path: "app-core/src/main/java/**/CheckUpdateTask*.kt"
        reason: "应用更新检查"
        evidence_kind: positive
    excluded_paths: [{ path: "app-core/build/", reason: "generated" }]
    evidence_limit: 8
    rule_limit: 10
    candidate_dimension_ids: ["baseline-*", "end:app-client:bootstrap", "end:app-client:tab-navigation"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: pending-confirmation
    pending_reason: "candidate_files 全部为路径模式,profile-first 阶段未读源码,实际文件存在性未验证;且与 app-kaz batch 在启动链路语义上重叠,需要负责人确认两者是合并还是拆分"

  - batch_id: "app-client-android-trade-core-foundation-p1"
    priority: low
    domain: app-client
    sub_domain: android
    module: feature/trade/trade-core
    task_type: trade-foundation
    candidate_files:
      - path: "feature/trade/trade-core/src/main/java/**/*Manager*.kt"
      - path: "feature/trade/trade-core/src/main/java/**/*Constants*.kt"
    excluded_paths: [{ path: "feature/trade/trade-core/build/", reason: "generated" }]
    evidence_limit: 5
    rule_limit: 6
    candidate_dimension_ids: ["baseline-*", "end:app-client:shared-state"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"
    stop_conditions: [no representative files, only inferred evidence, sensitive files required to continue, evidence_limit reached, rule_limit reached]
    status: pending-confirmation
    pending_reason: "trade-core 与 trade-execution / trade-account / trade-order 共享公共层语义重叠,建议先做高优先级 batch 后再决定是否独立成 batch"

  # ===================== SKIPPED =====================
  - batch_id: "app-client-android-feature-pager-reach"
    domain: app-client
    sub_domain: android
    module: feature/**/pager_reach
    status: skipped
    skip_reason: ".gitignore 标注的本地非源目录,整个模块在 excluded_paths 范围内"
```

## 3. 排除路径(全 batch 适用)

- `**/build/`、`**/.gradle/`、`**/.idea/`、`**/.kotlin/` — 构建产物
- `submodules/`(除 `biz-common`)— `.gitignore` 本地非源
- `pager_reach/`、`tmpmob/`、`/resources/`(顶层)、`feature/trade/bug图文/`
- `app-kaz/google-services.json`、`local.properties`、任何 `*.key` / `*.pem` / `id_rsa*`

## 4. ordered_batch_queue(auto 模式)

```yaml
ordered_batch_queue:
  - batch_id: app-client-android-app-bootstrap-app-kaz-p1
    priority: high
    estimated_doc: standard-android.md
    sub_domain: android
    status: ready
  - batch_id: app-client-android-trade-execution-order-p1
    priority: high
    estimated_doc: standard-android.md(industry:securities slot)
    sub_domain: android
    status: ready
  - batch_id: app-client-kmp-shared-biz-common-contract-p1
    priority: high
    estimated_doc: standard-kmp-shared.md
    sub_domain: kmp-shared
    status: ready
  - batch_id: app-client-android-quotes-market-realtime-p1
    priority: high
    estimated_doc: standard-android.md(realtime slot)
    sub_domain: android
    status: ready
  - batch_id: app-client-android-trade-account-binding-p1
    priority: medium
    estimated_doc: standard-android.md
    sub_domain: android
    status: ready
  - batch_id: app-client-android-trade-order-list-p1
    priority: medium
    estimated_doc: standard-android.md
    sub_domain: android
    status: ready
  - batch_id: app-client-android-watchlist-edit-p1
    priority: medium
    estimated_doc: standard-android.md
    sub_domain: android
    status: ready
  - batch_id: app-client-android-core-ui-kit-p1
    priority: medium
    estimated_doc: standard-android.md(ui-kit slot)
    sub_domain: android
    status: ready
  - batch_id: app-client-android-capability-web-jsbridge-p1
    priority: medium
    estimated_doc: standard-android.md(webview slot)
    sub_domain: android
    status: ready
  - batch_id: app-client-android-gradle-governance-p1
    priority: medium
    estimated_doc: standard-android.md(build-governance slot)
    sub_domain: android
    status: ready
  - batch_id: app-client-android-rn-bridge-p1
    priority: low
    estimated_doc: standard-android.md(rn slot)
    sub_domain: android
    status: ready
  - batch_id: app-client-android-share-capability-p1
    priority: low
    estimated_doc: standard-android.md
    sub_domain: android
    status: ready
  - batch_id: app-client-android-ad-sdk-pdp-p1
    priority: low
    estimated_doc: standard-android.md
    sub_domain: android
    status: ready
  - batch_id: app-client-android-message-center-p1
    priority: low
    estimated_doc: standard-android.md
    sub_domain: android
    status: ready
  - batch_id: app-client-android-community-feed-p1
    priority: low
    estimated_doc: standard-android.md
    sub_domain: android
    status: ready
  - batch_id: app-client-kmp-shared-biz-common-bizcommon-p1
    priority: low
    estimated_doc: standard-kmp-shared.md
    sub_domain: kmp-shared
    status: ready
```

## 5. 选择说明

- 一次正式萃取**只选择一个** `batch_id`,且必须 `status: ready`。
- `pending-confirmation` 的 batch 需要负责人补充 evidence / 决策合并方向后才能进入下一阶段。
- `skipped` batch 不生成规则。
- 推荐先跑 **`app-client-android-app-bootstrap-app-kaz-p1`**(应用启动 / SDK 集成是后续 batch 的上游约束)。

## 6. 用户确认(下一步触发模板)

```yaml
# 复制下面这段重新触发 skill,选择你想要的 batch:
project_paths:
  - /Users/kuang/xiaobu/kaz-mvp
extraction_mode: batch-extraction
selected_batch:
  batch_id: app-client-android-app-bootstrap-app-kaz-p1
  source_batch_plan: temp/20260526-134644-app-client-batch-plan.md
run_mode: auto
```
