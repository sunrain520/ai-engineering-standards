---
doc_id: "app-client-20260526-144058-app-client-batch-plan"
title: "App Client Batch Plan：kaz-mvp"
domain: "app-client"
sub_domain: "common"
doc_type: "batch-plan"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260526-144058-app-client"
tags:
  - "app-client"
  - "batch-plan"
  - "context-governance"
---

# App Client Batch Plan：kaz-mvp

## 1. 来源

- run_id: `20260526-144058-app-client`
- run_mode: `auto`
- extraction_mode: `profile-first`
- source_profile: `engineering-standards/01-app-client/temp/20260526-144058-app-client-project-profile.md`
- source_extraction_map: `engineering-standards/01-app-client/temp/20260526-144058-app-client-extraction-map.md`
- project_path: `/Users/kuang/xiaobu/kaz-mvp`
- previous_related_runs:
  - `engineering-standards/01-app-client/temp/20260522-100947-app-client-batch-plan.md`
  - `engineering-standards/01-app-client/temp/20260525-app-client-batch-plan.md`

## 2. ordered_batch_queue

```yaml
ordered_batch_queue:
  - batch_id: "app-client-kmp-shared-trade-order-clean-architecture"
    priority: "high"
    estimated_doc: "standard-kmp-shared.md"
    sub_domain: "kmp-shared"
    status: "ready"
    skip_reason: null
  - batch_id: "app-client-android-core-ui-state"
    priority: "high"
    estimated_doc: "standard-android.md"
    sub_domain: "android"
    status: "ready"
    skip_reason: null
  - batch_id: "app-client-module-boundary-contract-layer"
    priority: "high"
    estimated_doc: "standard-module-boundary.md"
    sub_domain: "module-boundary"
    status: "ready"
    skip_reason: null
  - batch_id: "app-client-build-governance-gradle-versioning"
    priority: "medium"
    estimated_doc: "standard-build-governance.md"
    sub_domain: "build-governance"
    status: "ready"
    skip_reason: null
  - batch_id: "app-client-android-trade-route-provider"
    priority: "medium"
    estimated_doc: "standard-android.md"
    sub_domain: "android"
    status: "ready"
    skip_reason: null
  - batch_id: "app-client-android-trade-order-page-provider"
    priority: "medium"
    estimated_doc: "standard-android.md"
    sub_domain: "android"
    status: "ready"
    skip_reason: null
  - batch_id: "app-client-kmp-shared-trade-account-assets"
    priority: "medium"
    estimated_doc: "standard-kmp-shared.md"
    sub_domain: "kmp-shared"
    status: "ready"
    skip_reason: null
```

## 3. 可执行 batch

```yaml
batches:
  - batch_id: "app-client-kmp-shared-trade-order-clean-architecture"
    domain: "app-client"
    sub_domain: "kmp-shared"
    module: "submodules/biz-common/modules/trade/trade-order"
    task_type: "clean-architecture-usecase-repository"
    priority: "high"
    candidate_files:
      - path: "submodules/biz-common/settings.gradle.kts"
        reason: "KMP 子工程模块矩阵入口"
        evidence_kind: "positive"
      - path: "submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/usecase/GetAllOrdersUseCase.kt"
        reason: "订单域 UseCase，覆盖 domain 层业务入口"
        evidence_kind: "positive"
      - path: "submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/repository/OrderRepository.kt"
        reason: "订单域 Repository 接口，覆盖数据访问边界"
        evidence_kind: "positive"
      - path: "submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/presentation/all/AllOrdersPresenter.kt"
        reason: "Presenter 状态流输出，覆盖 presentation 层"
        evidence_kind: "positive"
      - path: "submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/presentation/mapper/OrderUIMapper.kt"
        reason: "UI mapper，覆盖 domain/presentation 数据转换"
        evidence_kind: "positive"
    excluded_paths:
      - path: "submodules/biz-common/**/build/"
        reason: "generated build output"
      - path: "submodules/biz-common/.git/"
        reason: "vcs internals"
      - path: "submodules/biz-common/gradle.properties"
        reason: "secret / credential fields"
    evidence_limit: 25
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: "ready"
    candidate_dimension_ids: ["D01", "D02", "D03", "D05", "D08", "D09", "D11", "D12", "D13", "EA-Client-01", "EA-Client-06"]
    expected_skeleton_section: "assets/skeletons/app-client/kmp-shared-skeleton.md"

  - batch_id: "app-client-android-core-ui-state"
    domain: "app-client"
    sub_domain: "android"
    module: "core/core-ui-kit"
    task_type: "base-fragment-ui-state"
    priority: "high"
    candidate_files:
      - path: "core/core-ui-kit/build.gradle"
        reason: "基础 UI kit 构建入口"
        evidence_kind: "positive"
      - path: "core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/base/BaseFragment.kt"
        reason: "Fragment 基类，覆盖通用生命周期与页面入口"
        evidence_kind: "positive"
      - path: "core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseLoadDataFragment.kt"
        reason: "加载态页面基类，覆盖页面状态处理"
        evidence_kind: "positive"
      - path: "core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseViewModel.kt"
        reason: "加载态 ViewModel 基类，覆盖状态层"
        evidence_kind: "positive"
      - path: "core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/basepage/BasePageFragment.kt"
        reason: "普通页面基类，作为基类选择对照"
        evidence_kind: "positive"
    excluded_paths:
      - path: "core/core-ui-kit/build/"
        reason: "generated build output"
    evidence_limit: 25
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: "ready"
    candidate_dimension_ids: ["D01", "D02", "D08", "D09", "D10", "D11", "D12", "EA-Client-03", "EA-Client-07"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"

  - batch_id: "app-client-module-boundary-contract-layer"
    domain: "app-client"
    sub_domain: "module-boundary"
    module: "contract"
    task_type: "cross-module-contract"
    priority: "high"
    candidate_files:
      - path: "contract/trade/build.gradle.kts"
        reason: "交易契约模块构建入口"
        evidence_kind: "positive"
      - path: "contract/quotes/build.gradle.kts"
        reason: "行情契约模块构建入口"
        evidence_kind: "positive"
      - path: "contract/platform/build.gradle.kts"
        reason: "平台契约模块构建入口"
        evidence_kind: "positive"
      - path: "KAZ模块化架构设计规范.md"
        reason: "模块边界 owner-confirmed 候选对照材料"
        evidence_kind: "positive"
    excluded_paths:
      - path: "feature/**"
        reason: "implementation modules outside this contract batch"
      - path: "gradle.properties"
        reason: "secret / credential fields"
    evidence_limit: 25
    rule_limit: 10
    stop_conditions:
      - "existing active rule conflict requires merge-suggestions or conflicts"
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: "ready"
    candidate_dimension_ids: ["D01", "D02", "D03", "D04", "D11", "D13"]
    expected_skeleton_section: "assets/skeletons/cross-cutting-skeleton.md"
    existing_rule_baseline:
      - "standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」"
      - "standard-module-boundary.md「P2 contract 模块应保持依赖轻量」"

  - batch_id: "app-client-build-governance-gradle-versioning"
    domain: "app-client"
    sub_domain: "build-governance"
    module: "gradle-root"
    task_type: "dependency-version-local-fast-build"
    priority: "medium"
    candidate_files:
      - path: "settings.gradle"
        reason: "根模块矩阵、includeBuild 和本地 module include"
        evidence_kind: "positive"
      - path: "build.gradle"
        reason: "插件版本、仓库、dependencySubstitution 和 local fast build 开关"
        evidence_kind: "positive"
      - path: "hszq-version/build.gradle"
        reason: "版本治理插件模块构建入口"
        evidence_kind: "positive"
      - path: "repo_child_git.json"
        reason: "源码依赖模块清单和本地替换关系"
        evidence_kind: "positive"
    excluded_paths:
      - path: "gradle.properties"
        reason: "secret / credential fields"
      - path: "local.properties"
        reason: "local environment"
      - path: "hsconfig/"
        reason: "signing or environment config"
      - path: "repo/"
        reason: "binary dependency repository"
    evidence_limit: 25
    rule_limit: 10
    stop_conditions:
      - "sensitive files are required to continue"
      - "existing build-governance rules already cover candidate"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: "ready"
    candidate_dimension_ids: ["D01", "D02", "D11", "D13", "EA-Client-07"]
    expected_skeleton_section: "assets/skeletons/cross-cutting-skeleton.md"

  - batch_id: "app-client-android-trade-route-provider"
    domain: "app-client"
    sub_domain: "android"
    module: "feature/trade/trade-core"
    task_type: "route-provider-and-login-entry"
    priority: "medium"
    candidate_files:
      - path: "feature/trade/trade-core/build.gradle"
        reason: "交易 core feature 模块构建入口"
        evidence_kind: "positive"
      - path: "feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/TradeRouter.kt"
        reason: "交易路由入口候选"
        evidence_kind: "positive"
      - path: "feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/provider/IOrderPageProvider.kt"
        reason: "订单页 provider 契约候选"
        evidence_kind: "positive"
      - path: "specs/FSREQ-20260328-TRADELOGIN-001/design.md"
        reason: "交易登录重构设计材料，可作为背景对照，不直接出规则"
        evidence_kind: "positive"
    excluded_paths:
      - path: "gradle.properties"
        reason: "secret / credential fields"
      - path: "feature/trade/**/bug*"
        reason: "out-of-scope screenshots or issue media"
    evidence_limit: 25
    rule_limit: 10
    stop_conditions:
      - "needs cross-module batch to establish rule"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: "ready"
    candidate_dimension_ids: ["D01", "D03", "D04", "D08", "D11", "D12", "EA-Client-03"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"

  - batch_id: "app-client-android-trade-order-page-provider"
    domain: "app-client"
    sub_domain: "android"
    module: "feature/trade/trade-order"
    task_type: "normal-conditional-order-page-provider"
    priority: "medium"
    candidate_files:
      - path: "feature/trade/trade-order/build.gradle"
        reason: "订单模块构建入口"
        evidence_kind: "positive"
      - path: "feature/trade/trade-order/src/main/java/com/hstong/trade/order/provider/OrderPageProvider.kt"
        reason: "订单页 Provider 实现候选"
        evidence_kind: "positive"
      - path: "feature/trade/trade-order/src/main/java/com/hstong/trade/order/normalorder/all/AllOrderFragment.kt"
        reason: "普通订单列表页面入口"
        evidence_kind: "positive"
      - path: "feature/trade/trade-order/src/main/java/com/hstong/trade/order/normalorder/all/AllOrderViewModel.kt"
        reason: "普通订单列表 ViewModel"
        evidence_kind: "positive"
      - path: "feature/trade/trade-order/src/main/java/com/hstong/trade/order/condorder/ui/all/AllCondOrderListFragment.kt"
        reason: "条件单列表页面入口"
        evidence_kind: "positive"
      - path: "feature/trade/trade-order/src/main/java/com/hstong/trade/order/condorder/viewmodel/AllCondOrderViewModel.kt"
        reason: "条件单列表 ViewModel"
        evidence_kind: "positive"
    excluded_paths:
      - path: "**/*order*data*"
        reason: "possible order data; sanitized-existence-only"
      - path: "feature/trade/**/bug*"
        reason: "out-of-scope issue media"
    evidence_limit: 25
    rule_limit: 10
    stop_conditions:
      - "industry rule requires owner confirmation"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: "ready"
    candidate_dimension_ids: ["D03", "D04", "D06", "D08", "D11", "D12", "EA-Client-03", "SEC-02", "SEC-10"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"

  - batch_id: "app-client-kmp-shared-trade-account-assets"
    domain: "app-client"
    sub_domain: "kmp-shared"
    module: "submodules/biz-common/modules/trade/trade-account"
    task_type: "account-assets-clean-architecture"
    priority: "medium"
    candidate_files:
      - path: "submodules/biz-common/modules/trade/trade-account/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/account/securityaccount/domain/asset/usecase/SecurityAccountAssetUseCase.kt"
        reason: "证券账户资产 UseCase"
        evidence_kind: "positive"
      - path: "submodules/biz-common/modules/trade/trade-account/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/account/securityaccount/domain/repository/SecurityAccountRepository.kt"
        reason: "证券账户 Repository 接口"
        evidence_kind: "positive"
      - path: "submodules/biz-common/modules/trade/trade-account/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/account/securityaccount/presentation/asset/SecurityAssetPresenter.kt"
        reason: "证券账户资产 Presenter"
        evidence_kind: "positive"
      - path: "submodules/biz-common/modules/trade/trade-account/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/account/securityaccount/data/remote/dto/mapper/SecurityAssetDtoMapper.kt"
        reason: "账户资产 DTO mapper，覆盖 data 到 presentation 转换候选"
        evidence_kind: "positive"
    excluded_paths:
      - path: "**/*account*data*"
        reason: "possible account data; sanitized-existence-only"
      - path: "submodules/biz-common/**/build/"
        reason: "generated build output"
      - path: "submodules/biz-common/gradle.properties"
        reason: "secret / credential fields"
    evidence_limit: 25
    rule_limit: 10
    stop_conditions:
      - "account/asset business data required to continue"
      - "industry compliance rule requires owner confirmation"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: "ready"
    candidate_dimension_ids: ["D03", "D05", "D06", "D08", "D11", "D12", "EA-Client-01", "EA-Client-08", "SEC-05"]
    expected_skeleton_section: "assets/skeletons/app-client/kmp-shared-skeleton.md"

  - batch_id: "app-client-android-quotes-watchlist-market-ui"
    domain: "app-client"
    sub_domain: "android"
    module: "feature/kaz-quotes"
    task_type: "market-watchlist-ui-state"
    priority: "medium"
    candidate_files:
      - path: "feature/kaz-quotes/market/build.gradle"
        reason: "市场模块构建入口"
        evidence_kind: "positive"
      - path: "feature/kaz-quotes/market/src/main/java/com/kaz/market/MarketFragment.kt"
        reason: "市场页入口"
        evidence_kind: "positive"
      - path: "feature/kaz-quotes/market/src/main/java/com/kaz/market/MarketViewModel.kt"
        reason: "市场页 ViewModel"
        evidence_kind: "positive"
      - path: "feature/kaz-quotes/watchlist/src/main/java/com/kaz/watchlist/WatchListFragment.kt"
        reason: "自选股页入口"
        evidence_kind: "positive"
      - path: "feature/kaz-quotes/watchlist/src/main/java/com/kaz/watchlist/viewmodel/WatchListViewModel.kt"
        reason: "自选股 ViewModel"
        evidence_kind: "positive"
    excluded_paths:
      - path: "**/*market*data*"
        reason: "possible market data dump; sanitized-existence-only"
      - path: "feature/kaz-quotes/**/build/"
        reason: "generated build output"
    evidence_limit: 25
    rule_limit: 10
    stop_conditions:
      - "market data rule requires owner confirmation"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: "pending-confirmation"
    pending_reason: "行情实时数据、订阅授权和延迟披露属于行业/合规边界；缺少负责人确认前不得生成强制规则"
    candidate_dimension_ids: ["D08", "D10", "D11", "D12", "EA-Client-06", "SEC-01"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"

  - batch_id: "app-client-ui-component-hscomponents-consumption"
    domain: "app-client"
    sub_domain: "ui-component"
    module: "submodules/hscomponents"
    task_type: "design-system-consumption"
    priority: "low"
    candidate_files:
      - path: "submodules/hscomponents/hscomponents/build.gradle.kts"
        reason: "组件库模块构建入口"
        evidence_kind: "positive"
      - path: "submodules/hscomponents/README.md"
        reason: "组件库说明候选"
        evidence_kind: "positive"
      - path: "KAZ模块化架构设计规范.md"
        reason: "XML 优先使用组件库的 owner-confirmed 候选声明"
        evidence_kind: "positive"
    excluded_paths:
      - path: "submodules/hscomponents/**/build/"
        reason: "generated build output"
      - path: "submodules/hscomponents/.git/"
        reason: "vcs internals"
    evidence_limit: 25
    rule_limit: 10
    stop_conditions:
      - "only inferred evidence"
      - "component source sample missing"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: "pending-confirmation"
    pending_reason: "当前 profile 只确认组件库存在和构建入口；缺少已筛选组件源码文件"
    candidate_dimension_ids: ["D02", "D08", "D09", "EA-Client-03"]
    expected_skeleton_section: "assets/skeletons/app-client/android-skeleton.md"

  - batch_id: "app-client-industry-trading-place-order"
    domain: "app-client"
    sub_domain: "industry-trading"
    module: "trade-place-order"
    task_type: "securities-order-constraints"
    priority: "low"
    candidate_files:
      - path: "openspec/specs/trade-place-order/spec.md"
        reason: "交易下单规格，owner-confirmed 候选"
        evidence_kind: "positive"
      - path: "submodules/biz-common/modules/trade/trade-core/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/core/tradelogin/domain/usecase/CheckBeforePlaceOrderUseCase.kt"
        reason: "下单前检查 UseCase 候选"
        evidence_kind: "positive"
      - path: "contract/trade/build.gradle.kts"
        reason: "交易契约入口"
        evidence_kind: "positive"
      - path: "feature/trade/trade-order/src/main/java/com/hstong/trade/order/provider/OrderPageProvider.kt"
        reason: "订单页 Provider 候选"
        evidence_kind: "positive"
    excluded_paths:
      - path: "**/*order*data*"
        reason: "possible order data; sanitized-existence-only"
      - path: "**/*account*data*"
        reason: "possible account data; sanitized-existence-only"
      - path: "gradle.properties"
        reason: "secret / credential fields"
    evidence_limit: 25
    rule_limit: 10
    stop_conditions:
      - "owner confirmation missing for industry rules"
      - "should move to 09-industry if scope is not app-client-specific"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: "pending-confirmation"
    pending_reason: "证券交易约束可能属于行业规范；需要用户确认本 batch 是否留在 APP 客户端域"
    candidate_dimension_ids: ["D04", "D06", "D11", "D12", "SEC-02", "SEC-03", "SEC-05", "SEC-10"]
    expected_skeleton_section: "assets/skeletons/industry/securities-skeleton.md"
```

## 4. 选择说明

- 一次正式萃取只选择一个 `batch_id`。
- `ready` batch 可进入 `batch-extraction`。
- `pending-confirmation` batch 需要补充 evidence、负责人确认或调整输出 domain。
- `app-client-module-boundary-contract-layer` 命中已有 active 规则，后续若执行必须优先产出 `merge-suggestions.md` 或 `conflicts.md`，不得覆盖 `standard-module-boundary.md`。
- `industry-trading` 候选当前不进入 `ordered_batch_queue`，除非用户确认它属于 APP 客户端局部规范。

建议优先级：

1. `app-client-kmp-shared-trade-order-clean-architecture`：候选文件横跨 settings、UseCase、Repository、Presenter、Mapper，覆盖层级完整。
2. `app-client-android-core-ui-state`：核心 UI 基类影响面大，适合校准 Android 页面规范。
3. `app-client-build-governance-gradle-versioning`：构建治理证据集中，但必须继续排除凭据文件。

## 5. 用户确认

```yaml
selected_batch:
  batch_id:
  source_batch_plan: "engineering-standards/01-app-client/temp/20260526-144058-app-client-batch-plan.md"
```

## 6. profile-first stop condition

本次 auto 运行到 `profile-first` 结束。按当前 `project-standard-extractor` 稳定公开路径，完整仓库输入不得直接生成 `standard-*`、`ai-rules.md` 或 `review-checklist.md`；后续需要用户选择一个 `selected_batch.batch_id` 后再执行 `batch-extraction`。
