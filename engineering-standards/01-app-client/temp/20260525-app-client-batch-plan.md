---
doc_id: "app-client-20260525-app-client-batch-plan"
title: "Batch Plan：kaz-mvp（含 09-industry）"
domain: "app-client"
sub_domain: "common"
doc_type: "batch-plan"
version: "v0.2.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260525-app-client"
tags:
  - "app-client"
  - "industry"
  - "batch-plan"
---

# Batch Plan：kaz-mvp（20260525，含 09-industry）

## 1. 来源

- run_id: `20260525-app-client`
- source_profile: `engineering-standards/01-app-client/temp/20260525-app-client-project-profile.md`
- reference_previous_run: `20260522-100947-app-client-batch-plan.md`（已执行 batch 继承）
- domains: `01-app-client` + `09-industry`

## 2. 继承自 20260522 的 ready batch（仍可执行）

> 以下 batch 在上次 run 中为 ready 但未执行，本次直接继承。

| batch_id | sub_domain | priority | 候选核心文件 |
|---|---|---|---|
| `app-client-android-core-ui-state` | android | high | `core/core-ui-kit/.../BaseFragment.kt`, `BaseLoadDataFragment.kt` |
| `app-client-kmp-shared-trade-order-clean-architecture` | kmp-shared | high | `submodules/biz-common/modules/trade/trade-order/...UseCase.kt`, `...Repository.kt` |
| `app-client-module-boundary-contract-layer` | module-boundary | high | `contract/trade/build.gradle.kts`, `KAZ模块化架构设计规范.md` |
| `app-client-build-governance-gradle-versioning` | build-governance | medium | `settings.gradle`, `build.gradle`, `hszq-version/build.gradle` |
| `app-client-android-trade-route-provider` | android | medium | `feature/trade/trade-core/.../TradeRouter.kt` |
| `app-client-kmp-shared-trade-account-assets` | kmp-shared | medium | `.serena/memories/assets-module-architecture.md`, `...SecurityAssetPresenter.kt` |

## 3. 本次新增 batch（09-industry）

```yaml
batches:
  - batch_id: "industry-securities-trading-order-domain"
    domain: "09-industry"
    sub_domain: "securities"
    module: "trade"
    task_type: "securities-order-constraints"
    priority: medium
    status: ready
    candidate_files:
      - path: "openspec/specs/trade-place-order/spec.md"
        reason: "交易下单 API 设计规格，owner-confirmed 候选"
        evidence_kind: positive
      - path: "submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/usecase/GetAllOrdersUseCase.kt"
        reason: "KMP 订单 UseCase，体现订单业务规则"
        evidence_kind: positive
      - path: "submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/repository/OrderRepository.kt"
        reason: "KMP 订单 Repository 接口，体现数据边界"
        evidence_kind: positive
      - path: "contract/trade/build.gradle.kts"
        reason: "交易域跨模块契约入口"
        evidence_kind: positive
    excluded_paths:
      - path: "**/*order*data*"
        reason: "可能含真实订单数据；sanitized-existence-only"
      - path: "gradle.properties"
        reason: "凭据字段"
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "owner confirmation missing for industry rules"
      - "sensitive files required to continue"
      - "evidence_limit reached"
      - "rule_limit reached"
    pending_reason: null

  - batch_id: "industry-securities-quotes-market-domain"
    domain: "09-industry"
    sub_domain: "securities"
    module: "quotes"
    task_type: "market-data-watchlist-constraints"
    priority: medium
    status: pending-confirmation
    candidate_files:
      - path: "contract/quotes/build.gradle.kts"
        reason: "行情域契约入口"
        evidence_kind: positive
      - path: "feature/kaz-quotes/watchlist/src/main/java/com/kaz/watchlist/WatchListFragment.kt"
        reason: "自选股 UI 入口"
        evidence_kind: positive
    excluded_paths:
      - path: "**/*market*data*"
        reason: "可能含行情实时数据"
    evidence_limit: 8
    rule_limit: 10
    stop_conditions:
      - "owner confirmation missing for market data rules"
      - "evidence_limit reached"
    pending_reason: "行情域规则涉及实时数据边界，需行业负责人确认萃取范围"
```

## 4. 全局优先级排序

| # | batch_id | domain | priority | status | 理由 |
|---|---|---|---|---|---|
| 1 | `app-client-kmp-shared-trade-order-clean-architecture` | 01-app-client | **high** | ready | KMP Clean Architecture 候选文件清晰，直接验证现有 kmp-shared 规范 |
| 2 | `app-client-android-core-ui-state` | 01-app-client | **high** | ready | BaseFragment/BaseVM 规范，候选集中，影响面大 |
| 3 | `app-client-module-boundary-contract-layer` | 01-app-client | **high** | ready | 有 owner-confirmed 文档对照，风险可控 |
| 4 | `industry-securities-trading-order-domain` | 09-industry | **medium** | ready | 有 openspec 设计文档 + KMP 实现，优先于 UI 层 |
| 5 | `app-client-build-governance-gradle-versioning` | 01-app-client | medium | ready | 构建治理，需严格排除凭据 |
| 6 | `app-client-android-trade-route-provider` | 01-app-client | medium | ready | 路由/Provider 模式 |
| 7 | `app-client-kmp-shared-trade-account-assets` | 01-app-client | medium | ready | Serena 辅助候选 |
| 8 | `industry-securities-quotes-market-domain` | 09-industry | medium | **pending** | 需行业负责人确认 |

## 5. 选择说明

- 一次正式萃取只选择 **一个** `batch_id`（`extraction_mode=batch-extraction` + `selected_batch.batch_id`）
- `ready` → 可直接进入 batch-extraction
- `pending-confirmation` → 需补充 evidence 或负责人确认后进入
- 建议从 **#1 或 #4** 开始，前者验证 KMP 规范，后者开启 industry 域
