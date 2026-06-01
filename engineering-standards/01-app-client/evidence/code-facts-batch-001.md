---
doc_id: "app-client-evidence-code-facts"
title: "APP 客户端代码事实"
domain: "app-client"
sub_domain: "android"
doc_type: "evidence-code-facts"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260526-212711-app-client"
tags:
  - "app-client"
  - "android"
  - "evidence"
  - "hszq-app"
  - "batch-001-trade-architecture"
---

# APP 客户端代码事实

> batch: batch-001-trade-architecture
> run_id: 20260526-212711-app-client
> evidence 来源: GitNexus 深度索引（hszq-app, 158K nodes）

## EV-APP-CLIENT-001 Clean Architecture pilot 完整分层结构

- evidence_tier: direct-code
- 来源: `trade/src/main/java/com/hstong/trade/demo/`（10 个文件）

trade/demo 包实现了完整的 Clean Architecture 三层分离：
- **data 层**: `DemoTextDTO.kt`、`DemoTextDtoToDomainMapper.kt`、`DemoTextRepositoryImpl.kt`
- **domain 层**: `DemoText.kt`（model）、`DemoTextRepository.kt`（接口）、`GetDemoTextUseCase.kt`
- **presentation 层**: `DemoTextDomainToUiMapper.kt`、`DemoTextUiModel.kt`、`DemoTextActivity.kt`、`DemoTextViewModel.kt`

依赖方向：`DemoTextViewModel` → `GetDemoTextUseCase` → `DemoTextRepository`（接口）→ `DemoTextRepositoryImpl`。

## EV-APP-CLIENT-002 GetDemoTextUseCase 调用链

- evidence_tier: direct-code
- 来源: `trade/src/main/java/com/hstong/trade/demo/domain/usecase/GetDemoTextUseCase.kt`（L12-24）

持有 `repository` 属性，对外暴露 `invoke` 方法；唯一 incoming 调用来自 `DemoTextViewModel.create`。

## EV-APP-CLIENT-003 DemoTextViewModel upstream/downstream impact

- evidence_tier: direct-code
- 来源: GitNexus impact 分析

upstream impactedCount=2, risk=LOW，仅被 `DemoTextActivity.kt` 消费。downstream impactedCount=12, risk=MEDIUM，拉通 data/domain/presentation 三层。Clean Architecture pilot 对外暴露面极窄。

## EV-APP-CLIENT-004 trade 模块 ViewModel 清单

- evidence_tier: direct-code
- 来源: GitNexus query + context

| ViewModel | 路径 | 子模块 |
| --- | --- | --- |
| DemoTextViewModel | trade/.../demo/presentation/viewmodel/ | demo |
| TradeTabEventVM | trade/.../tradetab/ | tradetab |
| PreferencesSettingViewModel | trade/.../setting/ | setting |
| StockDetailTradeHomeVM | trade/.../stockdetail/ | stockdetail |
| SecuritiesViewModel | trade/.../account/function/more/ | account |
| BaseVMDataHelper | trade/.../order/ | order |

## EV-APP-CLIENT-005 TradeTabEventVM 事件总线型 ViewModel

- evidence_tier: direct-code
- 来源: `trade/src/main/java/com/hstong/trade/tradetab/TradeTabEventVM.kt`（L17-165）

通过 `getGlobal()` 获取跨 Fragment 共享实例，持有 `jumpLiveData` / `statisticsLiveData`，被 `MainActivity`、`BondAccountFragment`、`FundAccountFragment` 等多处 import。纯事件协调，不含业务逻辑。

## EV-APP-CLIENT-006 PreferencesSettingViewModel 多 Fragment 共享

- evidence_tier: direct-code
- 来源: `trade/src/main/java/com/hstong/trade/setting/PreferencesSettingViewModel.kt`（L29-396）

被 5 个 Fragment 共享（`TradeSettingFragment`、`SubmitSettingFragment`、`PositionSettingFragment`、`MeTradeSettingFragment`、`QuickTradeSettingFragment`），直接调用网络 API，无 UseCase 层。标准 MVVM 无 Clean Architecture 模式。

## EV-APP-CLIENT-007 StockPositionRepository 无 UseCase 直连 DAO

- evidence_tier: direct-code
- 来源: `trade/src/main/java/com/hstong/trade/common/dao/StockPositionRepository.kt`（L24-197）

持有 `stockPositionDao` / `database`，返回 LiveData，被 `HoldManagerUtil.kt` 直接调用。无 domain 层隔离。

## EV-APP-CLIENT-008 MVP 遗留 onInitPresenter

- evidence_tier: direct-code
- 来源: `MeTradeSettingFragment.kt`（L68-70）、`TradeUnlockSettingFragment.kt`（L92-94）、`BondTransFragment.java`（L280-283）

trade 模块内至少 3 处 `onInitPresenter` 调用，为基类 MVP 框架的生命周期钩子。setting、bond 子模块仍在使用 MVP。

## EV-APP-CLIENT-009 BaseVMDataHelper 非标 ViewModel 封装

- evidence_tier: direct-code
- 来源: `trade/src/main/java/com/hstong/trade/order/BaseVMDataHelper.kt`（L15-78）

通过泛型反射获取 ViewModel 类型，`TradeDealHelper` 和 `TradeEntrustHelper` 继承。order 子模块的定制化 ViewModel 集成方案。

## EV-APP-CLIENT-010 SecuritiesViewModel 超大类

- evidence_tier: direct-code
- 来源: `trade/src/main/java/com/hstong/trade/account/function/more/SecuritiesViewModel.kt`（L43-870）

约 830 行，功能堆积型超大 ViewModel。

## EV-APP-CLIENT-011 trade 模块分层目录实况

- evidence_tier: direct-code
- 来源: GitNexus cypher 扫描

以功能子模块切分为主（`placeorder/`、`positions/`、`stockdetail/`、`setting/`、`condorder/`、`order/`、`bond/`、`fund/`、`tradetab/`、`account/`、`openaccount/`、`tradelogin/`），仅 `demo/` 按 Clean Architecture 三层组织，其余为扁平 MVVM 或 MVP 混合。

## EV-APP-CLIENT-012 PlaceOrderFragment 超大文件

- evidence_tier: direct-code
- 来源: GitNexus cypher 扫描

`PlaceOrderFragment.kt`（L262-2364），超过 2100 行。待进一步确认内部架构模式。

## EV-APP-CLIENT-013 StockDetailTradeHomeVM 跨子 Fragment 共享

- evidence_tier: direct-code
- 来源: `trade/src/main/java/com/hstong/trade/stockdetail/StockDetailTradeHomeVM.kt`（L24-64）

持有 `stockCode`、`exchangeType`、`stockType` 等状态，被 `StockDetailCondOrderFragment`、`TodayPartOrderListFragment`、`StockDetailPositionVM` 等共享。scope 共享型 ViewModel。
