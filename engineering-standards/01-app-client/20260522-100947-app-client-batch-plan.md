---
doc_id: "app-client-20260522-100947-app-client-batch-plan"
title: "App Client Batch Plan：kaz-mvp"
domain: "app-client"
sub_domain: "common"
doc_type: "batch-plan"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "batch-plan"
  - "context-governance"
---

# App Client Batch Plan：kaz-mvp

## 1. 来源

- run_id: `20260522-100947-app-client`
- source_profile: `engineering-standards/01-app-client/20260522-100947-app-client-project-profile.md`
- source_extraction_map: `engineering-standards/01-app-client/20260522-100947-app-client-extraction-map.md`
- extraction_mode: `profile-first`
- project_path: `/Users/kuang/xiaobu/kaz-mvp`

## 2. 可执行 batch

```yaml
batches:
  - batch_id: "app-client-android-app-shell-bootstrap"
    domain: "app-client"
    sub_domain: "android"
    module: "app-shell"
    task_type: "app-bootstrap"
    candidate_files:
      - path: "app-kaz/build.gradle"
        reason: "App 壳构建、插件和依赖装配入口"
        evidence_kind: positive
      - path: "app-kaz/src/main/AndroidManifest.xml"
        reason: "App 壳 Android 入口声明"
        evidence_kind: positive
      - path: "app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt"
        reason: "全局 Application 装配入口"
        evidence_kind: positive
    excluded_paths:
      - path: "app-kaz/libs/"
        reason: "dependency / binary artifacts"
      - path: "gradle.properties"
        reason: "secret / credential fields"
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: ready

  - batch_id: "app-client-android-core-ui-state"
    domain: "app-client"
    sub_domain: "android"
    module: "core-ui-kit"
    task_type: "base-fragment-ui-state"
    candidate_files:
      - path: "core/core-ui-kit/build.gradle"
        reason: "基础 UI kit 模块构建入口"
        evidence_kind: positive
      - path: "core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/base/BaseFragment.kt"
        reason: "Fragment 基类候选"
        evidence_kind: positive
      - path: "core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseLoadDataFragment.kt"
        reason: "加载态页面基类候选"
        evidence_kind: positive
      - path: "core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseViewModel.kt"
        reason: "加载态 ViewModel 基类候选"
        evidence_kind: positive
    excluded_paths:
      - path: "core/core-ui-kit/build/"
        reason: "generated build output"
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: ready

  - batch_id: "app-client-module-boundary-contract-layer"
    domain: "app-client"
    sub_domain: "module-boundary"
    module: "contract"
    task_type: "cross-module-contract"
    candidate_files:
      - path: "contract/trade/build.gradle.kts"
        reason: "交易契约模块构建入口"
        evidence_kind: positive
      - path: "contract/quotes/build.gradle.kts"
        reason: "行情契约模块构建入口"
        evidence_kind: positive
      - path: "contract/platform/build.gradle.kts"
        reason: "平台契约模块构建入口"
        evidence_kind: positive
      - path: "KAZ模块化架构设计规范.md"
        reason: "模块化 owner-confirmed 候选规范"
        evidence_kind: positive
    excluded_paths:
      - path: "feature/**"
        reason: "implementation modules outside this contract batch"
      - path: "gradle.properties"
        reason: "secret / credential fields"
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: ready

  - batch_id: "app-client-android-trade-route-provider"
    domain: "app-client"
    sub_domain: "android"
    module: "trade-core"
    task_type: "route-provider-and-login-entry"
    candidate_files:
      - path: "feature/trade/trade-core/build.gradle"
        reason: "交易核心模块构建入口"
        evidence_kind: positive
      - path: "feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/TradeRouter.kt"
        reason: "交易路由入口候选"
        evidence_kind: positive
      - path: "feature/trade/trade-core/README.md"
        reason: "交易核心模块说明"
        evidence_kind: positive
    excluded_paths:
      - path: "gradle.properties"
        reason: "secret / credential fields"
      - path: "feature/trade/**/bug*"
        reason: "out-of-scope screenshots or issue media"
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: ready

  - batch_id: "app-client-android-trade-account-page-composition"
    domain: "app-client"
    sub_domain: "android"
    module: "trade-account"
    task_type: "account-page-composition"
    candidate_files:
      - path: "feature/trade/trade-account/build.gradle"
        reason: "交易账户模块构建入口"
        evidence_kind: positive
      - path: "feature/trade/trade-account/src/main/java/com/hstong/trade/account/security/SecurityAccountFragment.kt"
        reason: "证券账户页面组合入口候选"
        evidence_kind: positive
      - path: ".serena/memories/security-account/fragment-hierarchy.md"
        reason: "Serena 记忆中的页面层级摘要，用于定位源码 evidence"
        evidence_kind: positive
    excluded_paths:
      - path: "gradle.properties"
        reason: "secret / credential fields"
      - path: "**/*account*data*"
        reason: "possible user/account data; confirm before reading"
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: ready

  - batch_id: "app-client-kmp-shared-trade-order-clean-architecture"
    domain: "app-client"
    sub_domain: "kmp-shared"
    module: "submodules/biz-common/modules/trade/trade-order"
    task_type: "clean-architecture-usecase-repository"
    candidate_files:
      - path: "submodules/biz-common/settings.gradle.kts"
        reason: "KMP 子项目模块矩阵入口"
        evidence_kind: positive
      - path: "submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/usecase/GetAllOrdersUseCase.kt"
        reason: "KMP 订单 UseCase 候选"
        evidence_kind: positive
      - path: "submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/repository/OrderRepository.kt"
        reason: "KMP 订单 Repository 接口候选"
        evidence_kind: positive
      - path: "submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/presentation/all/AllOrdersPresenter.kt"
        reason: "KMP 订单 Presenter 状态输出候选"
        evidence_kind: positive
    excluded_paths:
      - path: "submodules/biz-common/.git/"
        reason: "vcs internals"
      - path: "submodules/biz-common/**/build/"
        reason: "generated build output"
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: ready

  - batch_id: "app-client-kmp-shared-trade-account-assets"
    domain: "app-client"
    sub_domain: "kmp-shared"
    module: "submodules/biz-common/modules/trade/trade-account"
    task_type: "account-assets-clean-architecture"
    candidate_files:
      - path: ".serena/memories/assets-module-architecture.md"
        reason: "Serena 记忆中的 Assets 模块 Clean Architecture 摘要"
        evidence_kind: positive
      - path: ".serena/memories/securityaccount-architecture.md"
        reason: "Serena 记忆中的 SecurityAccount 模块分层摘要"
        evidence_kind: positive
      - path: "submodules/biz-common/modules/trade/trade-account/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/account/securityaccount/presentation/asset/SecurityAssetPresenter.kt"
        reason: "KMP 账户资产 Presenter 候选"
        evidence_kind: positive
    excluded_paths:
      - path: "submodules/biz-common/.git/"
        reason: "vcs internals"
      - path: "**/*account*data*"
        reason: "possible account data; confirm before reading"
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: ready

  - batch_id: "app-client-build-governance-gradle-versioning"
    domain: "app-client"
    sub_domain: "build-governance"
    module: "gradle-root"
    task_type: "dependency-version-local-fast-build"
    candidate_files:
      - path: "settings.gradle"
        reason: "根模块矩阵和 includeBuild 入口"
        evidence_kind: positive
      - path: "build.gradle"
        reason: "插件、依赖仓库和本地极速构建策略入口"
        evidence_kind: positive
      - path: "hszq-version/build.gradle"
        reason: "版本治理插件候选"
        evidence_kind: positive
    excluded_paths:
      - path: "gradle.properties"
        reason: "secret / credential fields"
      - path: "local.properties"
        reason: "local environment"
      - path: "hsconfig/"
        reason: "signing or environment config"
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: ready

  - batch_id: "app-client-ui-component-hscomponents-consumption"
    domain: "app-client"
    sub_domain: "ui-component"
    module: "hscomponents"
    task_type: "design-system-consumption"
    candidate_files:
      - path: "submodules/hscomponents/hscomponents"
        reason: "本地 UI 组件库路径，仅作为候选目录"
        evidence_kind: unknown
      - path: "KAZ模块化架构设计规范.md"
        reason: "已有规范声明 XML 优先使用组件库"
        evidence_kind: positive
    excluded_paths:
      - path: "submodules/hscomponents/.git/"
        reason: "vcs internals"
      - path: "submodules/hscomponents/**/build/"
        reason: "generated build output"
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: pending-confirmation
    pending_reason: "当前只有目录级候选和 owner-confirmed 文档候选，缺少已筛选的组件源码文件"

  - batch_id: "app-client-industry-trading-order-account-risk"
    domain: "app-client"
    sub_domain: "industry-trading"
    module: "trade"
    task_type: "securities-account-order-constraints"
    candidate_files:
      - path: "openspec/specs/trade-place-order/spec.md"
        reason: "交易下单规格候选"
        evidence_kind: positive
      - path: "feature/trade/"
        reason: "交易原生模块目录候选"
        evidence_kind: unknown
      - path: "submodules/biz-common/modules/trade/"
        reason: "交易 KMP 模块目录候选"
        evidence_kind: unknown
    excluded_paths:
      - path: "**/*account*data*"
        reason: "possible account data; confirm before reading"
      - path: "**/*order*data*"
        reason: "possible order data; confirm before reading"
      - path: "gradle.properties"
        reason: "secret / credential fields"
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "no representative files"
      - "only inferred evidence"
      - "sensitive files are required to continue"
      - "owner confirmation missing"
      - "evidence_limit reached"
      - "rule_limit reached"
    status: pending-confirmation
    pending_reason: "行业交易规则不能仅由路径推断，需要负责人确认适用边界"
```

## 3. 推荐优先级

| priority | batch_id | 理由 |
| --- | --- | --- |
| high | `app-client-module-boundary-contract-layer` | 直接对应既有 APP 模块化规范，风险较低，适合先补真实 evidence |
| high | `app-client-kmp-shared-trade-order-clean-architecture` | KMP 分层候选清晰，能验证现有 `01-kmp-shared-layer-standard.md` |
| high | `app-client-android-core-ui-state` | 对应 Android BaseFragment/BaseVM 规范，候选文件集中 |
| medium | `app-client-build-governance-gradle-versioning` | 可沉淀构建治理，但需严格排除凭据 |
| medium | `app-client-android-trade-route-provider` | 能验证跨模块路由/Provider，但交易域风险更高 |
| medium | `app-client-android-trade-account-page-composition` | 页面组合模式代表性强，但涉及账户域需谨慎 |
| low | `app-client-ui-component-hscomponents-consumption` | 目前缺少具体组件源码候选 |
| low | `app-client-industry-trading-order-account-risk` | 需要负责人确认，不适合直接生成 AI 可执行规则 |

## 4. 选择说明

- 一次正式萃取只选择一个 `batch_id`。
- `ready` batch 可以进入 `batch-extraction`。
- `pending-confirmation` batch 需要用户补充 evidence 或负责人确认。
- `skipped` / `blocked` batch 不生成规则。
- 后续 `batch-extraction` 应优先读取本文件、project profile、extraction map 和选定 batch 的 `candidate_files`，不得跨 batch 扩大读取。

## 5. 用户确认

```yaml
selected_batch:
  batch_id: "app-client-module-boundary-contract-layer"
  source_batch_plan: "engineering-standards/01-app-client/20260522-100947-app-client-batch-plan.md"
```
