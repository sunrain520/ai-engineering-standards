---
doc_id: "ev-app-client-g2-trade-code-facts"
title: "App-Client Android 交易模块 - 代码事实清单"
domain: "app-client"
sub_domain: "android"
industry: "securities"
doc_type: "evidence"
evidence_kind: "code-facts"
status: "draft"
indexable: true
source_batch: "app-client-android-trade-execution-order-p1, app-client-android-trade-account-binding-p1, app-client-android-trade-order-list-p1, app-client-android-trade-core-foundation-p1"
last_reviewed: "2026-05-26"
tags: ["evidence", "code-facts", "trade", "industry:securities"]
---

# App-Client Android 交易模块 - 代码事实清单

仅记录 selected-batch 范围内可观察到的代码事实，路径均为 kaz-mvp 项目根的相对路径。

## EV-APP-CLIENT-G2-001：模块结构

- 交易领域包含 4 个 Android library 模块，独立 namespace 与 build.gradle：
  - `feature/trade/trade-core/`（namespace `com.hstong.trade.core`）
  - `feature/trade/trade-execution/`（namespace `com.hstong.trade.condition`，下单条件单实体模块）
  - `feature/trade/trade-order/`（namespace `com.hstong.trade.order`）
  - `feature/trade/trade-account/`（namespace `com.hstong.trade.account`）
- 依赖方向：`trade-order` → `trade-execution`、`trade-core`；`trade-account` → `trade-core`；`trade-execution` → `trade-core`；`trade-core` 不依赖业务模块。引用路径见各模块 `build.gradle`。
- `trade-execution` 当前 `src/main/java` 内仅有 `.keep` 占位，未观察到 Kotlin/Java 实现；条件单 UI/VM 实际落在 `trade-order/condorder/`。

## EV-APP-CLIENT-G2-002：架构形态（KMP 桥接）

- Android 层 ViewModel 持有 KMP Presenter，通过工厂创建：`TradeOrderPresenterFactory.createRecentOrdersPresenter(TradingMarket.HK)`、`createAllOrdersPresenter(...)`、`createStockFilterPresenter()`。证据：`feature/trade/trade-order/src/main/java/com/hstong/trade/order/normalorder/recent/RecentOrderViewModel.kt`、`.../normalorder/all/AllOrderViewModel.kt`。
- ViewModel 在 `init { viewModelScope.launch { presenter.uiState.collect { ... } } }` 中订阅 KMP Flow，`withContext(Dispatchers.Main)` 切回主线程发布；本地仅做 UI 拼装态（`RecentPageUiState`）。
- 列表 ViewModel 继承 `BaseKmpListPageViewModel<UiModel, KmpUiState>`，对接 `extractListItems(state)` 与 `hasMoreData(state)`。证据：`AllOrderViewModel.kt`。
- 用户操作通过 `presenter.updateStatusFilter(...)`、`presenter.selectUnfinishedFilter(...)` 等方法回写 KMP；UI 不维护重复状态。证据：`AllOrderViewModel.kt:80-92`、`RecentOrderViewModel.kt:122-153`。

## EV-APP-CLIENT-G2-003：基类与 UI 框架

- 容器型页面继承 `HsLoadDataFragment` / `BaseLoadDataFragment`；列表型页面继承 `BaseHsListPageFragment<UiModel, ViewModel>`，使用 SmartRefreshLayout、HSList、HSNavigationBar。证据：`AllOrderFragment.kt`、`RecentOrderFragment.kt`、`AccountContainerFragment.kt`。
- ViewBinding 开启（`buildFeatures { viewBinding true }`，所有 trade-* 模块 `build.gradle`），生成 `*Binding`，Fragment 用 `_binding`/`binding`/`onDestroyView` 释放，对应代码：`TradePasswordBottomSheet.kt:36-37`、`AccountContainerFragment.kt:50-52, 109-112`。
- 列表 Adapter 直接继承 `RecyclerView.Adapter<...>` 并通过 `submitList(newItems) { items = newItems; notifyDataSetChanged() }` 暴露数据；使用 `ConcatAdapter` 拼接 Header/Footer/分区。证据：`AllOrderListAdapter.kt`、`RecentOrderFragment.kt:36-46, 119-...`。
- 路由跳转：模块内通过 `OrderNavigator.openOrderDetail(context, orderId, exchangeType)` 静态方法，参数走 `Bundle` 但仅在模块内部使用；公开跨模块入口为 provider 对象。证据：`feature/trade/trade-order/src/main/java/com/hstong/trade/order/normalorder/common/route/OrderNavigator.kt`。

## EV-APP-CLIENT-G2-004：跨模块协议（IOrderPageProvider）

- 跨模块创建 Fragment 通过 `IOrderPageProvider` 接口（`com.alibaba.android.arouter.facade.template.IProvider`），方法以强类型 request 入参：`getSecurityOrderFragment(request: OrderPageRequest)`、`getCondOrderFragment(request: CondOrderPageRequest)` 等。证据：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/provider/IOrderPageProvider.kt`。
- 该接口注释明文规定：模块 A 不直接依赖模块 B 的 Fragment 类；不直接组装 ARouter path + Bundle key；Bundle 是弱协议，跨模块场景禁止把 Bundle 当公开接口透出；参数全部收敛在 request 对象里。

## EV-APP-CLIENT-G2-005：交易登录引擎与 UiPort

- 交易密码登录由 KMP `TradeLoginFacade` 单例驱动；Android 端实现 `TradeLoginUiPort` 接口（5 个回调：`show / openInitPasswordSetup / clearSensitiveInput / dismiss / openPlatformLogin`）。证据：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/tradelogin/ui/KazTradeLoginUiPortImpl.kt`。
- `KazTradeLoginUiPortImpl` 持有 `WeakReference<FragmentManager>`，每个回调先 `fragmentManagerRef.get()` + `fm.isStateSaved` 校验失败即 `TradeLoginFacade.onUserCancelled(sessionId)`。
- `KazTradeApplication.onCreate` 注册 `Application.ActivityLifecycleCallbacks`：在 `onActivityCreated` / `onActivityResumed` 用最新 Activity 的 `supportFragmentManager` 重建 UiPort，避免引用失效。
- 平台登录回调使用 `@Volatile var pendingPlatformLoginSessionId: String?` 暂存，`onActivityResumed` 中检测并调用 `TradeLoginFacade.onPlatformLoginCompleted(sessionId, loggedIn)`。
- 启动时声明：`TradeLoginFacade.setEnterPagePostInitPasswordBehavior(REQUIRE_RETRY)`，首次设密后强制重新输入密码。

## EV-APP-CLIENT-G2-006：交易密码弹窗（TradePasswordBottomSheet）

- `TradePasswordBottomSheet` 继承 `BottomSheetDialogFragment`，`onCreateDialog` 强制 `STATE_EXPANDED`、`skipCollapsed = true`、`isDraggable = false`。证据：`TradePasswordBottomSheet.kt:39-54`。
- `binding.codeField.onComplete = { digits -> binding.codeField.isEnabled = false; lifecycleScope.launch { TradeLoginFacade.onUserInputSubmitted(...) } }`：满 6 位立即禁用输入，防重复提交（注释明示「§11.10」）。
- 失败场景按 `TradeLoginUiState.TransPwdNotMatch` / `TransPwdTimesOutnum` 区分弹错误对话框（`TradePasswordErrorDialog.showSafe`），系统返回键触发 `onCancel(dialog)` → `TradeLoginFacade.onUserCancelled(sessionId)`。
- 静态工厂 `showSafe(fragmentManager, sessionId)` 先判 `if (fragmentManager.isStateSaved) return null`。
- 密码原始值仅以局部 `digits: String` 直接传入 `UserInputData.forPassword(digits, null, null)`，不在 ViewModel/LiveData 中持有。

## EV-APP-CLIENT-G2-007：账户容器（AccountContainerFragment / VM）

- `AccountContainerVM` 通过 Koin `inject { parametersOf(viewModelScope) }` 创建 KMP `AccountContainerPresenter`；`viewModelScope` 作为 KMP 协程域注入。证据：`AccountContainerVM.kt`。
- `AccountContainerFragment` 用自定义 `getScopeViewModel(scopeName, clazz)` 从 `VMScope` 全局单例获取 ViewModel，跨 Fragment/Activity 共享。证据：`AccountContainerFragment.kt:54-62`、`feature/trade/trade-core/src/main/java/com/hstong/trade/core/vm/vmscope/VMScopeStoreOwner.kt`。
- VMScope：私有 `vMStores: HashMap<String, VMStoreOwner>` + 每次 `bindHost` 注册 `LifecycleEventObserver`，`ON_DESTROY` 时若 `bindTargets` 为空则 `viewModelStore.clear()` 并从 `vMStores` 移除。
- 状态订阅使用 `viewModel.presenter.uiState.map { it.switchMode }.distinctUntilChanged().collectWithLifecycle(viewLifecycleOwner) { ... }`。

## EV-APP-CLIENT-G2-008：分页加载与 KMP 列表对接

- `AllOrderViewModel` 中分页通过覆写 `onLoadInitData / onRefresh / onLoadMore` 转发到 KMP Presenter 或 mock 分支；`pendingFilterAction` 队列保证筛选切换串行化。证据：`AllOrderViewModel.kt:60-105, 196-...`。
- 条件单列表基类 `BaseCondOrderListPageViewModel` 显式区分 `RefreshReason`（INITIAL / PULL_TO_REFRESH / LOAD_MORE / FILTER_CHANGED / SEARCH_CHANGED / PUSH_EVENT / POLLING / ACTION_SUCCESS）；持有 `pollingJob: Job?`，提供 `pausePolling/resumePolling`、`onPageVisible/onPageInvisible/onModuleVisibleChanged` 控制可见性，默认 `pollingIntervalMs = 3_000L`。证据：`feature/trade/trade-order/src/main/java/com/hstong/trade/order/condorder/viewmodel/BaseCondOrderListPageViewModel.kt:13-130`。
- 加载更多互斥：`if (plan.loadType == LoadType.LOAD_MORE && activeRequestJob?.isActive == true) { return }`，已激活的请求 job 会被 `cancel`。

## EV-APP-CLIENT-G2-009：网络拦截器（TradeBaseParamInterceptor）

- `TradeBaseParamInterceptor : Interceptor`：根据 body 中的 `exchangeType` 自动追加 `fundAccount`（来自 `OpenStatusQueryFacade.getDefaultAccountNo(exchangeType)`）和 `businessType`，支持 `MultipartBody` 与 `FormBody`（`buzz` 字段是 JSON 串）。证据：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/interceptor/TradeBaseParamInterceptor.kt`。
- 资金账号字段为敏感数据，未观察到日志输出该字段。

## EV-APP-CLIENT-G2-010：弹窗工具与确认链路

- `OrderDialogUtil` 提供 `showOneBtnAndTitleDialog / showTwoBtnAndTitleDialog / showMessageNeedContinue / showEmphasisCancelDialog`，所有方法基于 `DialogWidget`，二次确认默认 `右=确定 / 左=取消`，`showEmphasisCancelDialog` 反向布局并突出取消（强提示场景）。证据：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/widget/dialog/OrderDialogUtil.kt`。
- 快捷改单二次确认走 `QuickEditConfirmDialogFragment`（`DialogFragment`），`onConfirm = { skipReminder -> viewModel.confirmQuickEdit(skipReminder) }`，并提供「不再提示」复选框。证据：`feature/trade/trade-order/src/main/java/com/hstong/trade/order/normalorder/common/dialog/QuickEditConfirmDialogFragment.kt`。

## EV-APP-CLIENT-G2-011：Debug/Mock 注入

- 列表 VM 在 init/refresh 入口检测 `OrderDebugMockSupport.isAllOrderMockEnabled(application)` / `isRecentMockEnabled(application)`，命中后切到 mock 分支，不调 KMP Presenter。证据：`AllOrderViewModel.kt:60-78`、`RecentOrderViewModel.kt:32, 73-104`。
- 交易登录提供 4 套 `TradeLoginPolicy`：`DefaultTradeLoginPolicy / DebugBypassPlatformLoginPolicy / DebugForceInitPasswordPolicy / DebugForceUserInputPolicy`，仅前者对外稳定，其余标 `internal object`。证据：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/tradelogin/debug/DebugBypassPlatformLoginPolicy.kt`。

## EV-APP-CLIENT-G2-012：被踢下线提示

- `KazTradeApplication.onCreate` 中 `CoroutineScope(Dispatchers.Main).launch { TradeLoginFacade.kickOffMessageFlow.collect { Toast.makeText(...).show() } }`，订阅生命周期未做手动取消（应用级单例 scope）。证据：`KazTradeApplication.kt:50-56`。

## EV-APP-CLIENT-G2-013：偏好设置与下单确认开关

- `PreferencesSettingViewModel`（@Deprecated）暴露 `TYPE_SUBMIT = 2 / TYPE_TRADE = 3 / TYPE_QUICK_TRADE = 4` 等下单/交易偏好分类；`setPre` 中明确：`PrefUtil.SUBMIT_ORDER_CONFIRM` 为「0」时清零 `KEY_SUBMIT_ORDER_TIP_IGNORE_TIMES`，即下单确认开关与忽略次数计数耦合。证据：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/preference/PreferencesSettingViewModel.kt:90-99`。
