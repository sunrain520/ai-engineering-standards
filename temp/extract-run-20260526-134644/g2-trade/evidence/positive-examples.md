---
doc_id: "ev-app-client-g2-trade-positive-examples"
title: "App-Client Android 交易模块 - 正例片段"
domain: "app-client"
sub_domain: "android"
industry: "securities"
doc_type: "evidence"
evidence_kind: "positive-examples"
status: "draft"
indexable: true
source_batch: "app-client-android-trade-execution-order-p1, app-client-android-trade-account-binding-p1, app-client-android-trade-order-list-p1, app-client-android-trade-core-foundation-p1"
last_reviewed: "2026-05-26"
tags: ["evidence", "positive", "trade", "industry:securities"]
---

# App-Client Android 交易模块 - 正例片段

## POS-APP-CLIENT-G2-001：交易密码弹窗满 6 位即锁定输入并经 Facade 提交

来源：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/tradelogin/ui/TradePasswordBottomSheet.kt`

```kotlin
binding.codeField.onComplete = { digits ->
    binding.codeField.isEnabled = false
    lifecycleScope.launch {
        val result = TradeLoginFacade.onUserInputSubmitted(
            sessionId = sessionId,
            userInputData = UserInputData.forPassword(digits, null, null),
        )
        result.fold(
            success = { uiState ->
                when (uiState) {
                    is TradeLoginUiState.Success -> dismissAllowingStateLoss()
                    is TradeLoginUiState.TransPwdNotMatch -> {
                        clearInput()
                        TradePasswordErrorDialog.showSafe(
                            childFragmentManager, sessionId, uiState.message, isLocked = false,
                        )
                    }
                    is TradeLoginUiState.TransPwdTimesOutnum -> {
                        clearInput()
                        TradePasswordErrorDialog.showSafe(
                            childFragmentManager, sessionId, uiState.message, isLocked = true,
                        )
                    }
                }
            },
            failure = { error -> clearInput(); TradePasswordErrorDialog.showSafe(...) }
        )
    }
}
```

要点：满位即锁，密码原值仅在局部变量与 KMP `UserInputData` 中流转，错误后立即 `clearInput()` 重置。

## POS-APP-CLIENT-G2-002：UiPort 弱引用 + isStateSaved 双闸

来源：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/tradelogin/ui/KazTradeLoginUiPortImpl.kt`

```kotlin
override fun show(sessionId: String, presentation: TradeLoginPresentation) {
    if (presentation != TradeLoginPresentation.POPUP) return
    val fm = fragmentManagerRef.get()
    if (fm == null) {
        MainScope().launch { TradeLoginFacade.onUserCancelled(sessionId) }
        return
    }
    val sheet = TradePasswordBottomSheet.showSafe(fm, sessionId)
    if (sheet == null) {
        MainScope().launch { TradeLoginFacade.onUserCancelled(sessionId) }
        return
    }
    activeBottomSheet = sheet
}
```

```kotlin
fun showSafe(fragmentManager: FragmentManager, sessionId: String): TradePasswordBottomSheet? {
    if (fragmentManager.isStateSaved) return null
    return newInstance(sessionId).also { it.show(fragmentManager, TAG) }
}
```

要点：所有 show 路径均检测 `isStateSaved`，失败时主线程回 `onUserCancelled`，避免会话悬挂。

## POS-APP-CLIENT-G2-003：Activity 生命周期重绑 UiPort

来源：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/entry/KazTradeApplication.kt`

```kotlin
private class TradeLoginUiPortRegistrar : Application.ActivityLifecycleCallbacks {
    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        if (activity !is FragmentActivity) return
        TradeLoginFacade.registerUiPort(KazTradeLoginUiPortImpl(activity.supportFragmentManager))
    }
    override fun onActivityResumed(activity: Activity) {
        if (activity !is FragmentActivity) return
        TradeLoginFacade.registerUiPort(KazTradeLoginUiPortImpl(activity.supportFragmentManager))
        val sessionId = KazTradeLoginUiPortImpl.pendingPlatformLoginSessionId ?: return
        KazTradeLoginUiPortImpl.pendingPlatformLoginSessionId = null
        val loggedIn = HSLoginStatus.hasLogin()
        CoroutineScope(Dispatchers.Main).launch {
            TradeLoginFacade.onPlatformLoginCompleted(sessionId, loggedIn)
        }
    }
}
```

要点：每次 Activity create/resume 重新注入 UiPort，登录页跳转返回也能拿到当前 FragmentManager；平台登录回调在 onActivityResumed 中通知 KMP。

## POS-APP-CLIENT-G2-004：跨模块 Provider 用强类型 Request

来源：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/provider/IOrderPageProvider.kt`

```kotlin
interface IOrderPageProvider : IProvider {
    fun getSecurityOrderFragment(request: OrderPageRequest): Fragment
    fun getFuturesOrderFragment(request: OrderPageRequest): Fragment
    fun getCryptoOrderFragment(request: OrderPageRequest): Fragment
    fun getCondOrderFragment(request: CondOrderPageRequest): Fragment
}
```

要点：跨模块创建 Fragment 走 IProvider；参数全部封装在 Request 对象，避免 Bundle key 扩散。

## POS-APP-CLIENT-G2-005：列表 ViewModel 订阅 KMP Flow + 主线程发布

来源：`feature/trade/trade-order/src/main/java/com/hstong/trade/order/normalorder/recent/RecentOrderViewModel.kt`

```kotlin
init {
    if (mockEnabled) {
        publishMockState()
    } else {
        viewModelScope.launch {
            presenter.uiState.collect { state ->
                withContext(Dispatchers.Main) {
                    latestState = state
                    syncFilterFromKmpState(state)
                    publishState()
                }
            }
        }
    }
}
```

要点：单订阅入口、统一在主线程发布 UI 状态；Mock 通道与生产通道明确隔离。

## POS-APP-CLIENT-G2-006：分页 + 筛选切换串行化

来源：`feature/trade/trade-order/src/main/java/com/hstong/trade/order/normalorder/all/AllOrderViewModel.kt`

```kotlin
override fun onRefresh() {
    if (OrderDebugMockSupport.isAllOrderMockEnabled(getApplication())) { ...; return }
    viewModelScope.launch {
        when (val action = pendingFilterAction) {
            is PendingFilterAction.UpdateStatus -> presenter.updateStatusFilter(action.statusFilter)
            is PendingFilterAction.UpdateDate -> presenter.updateDateRangeFilter(action.datePreset)
            is PendingFilterAction.UpdateStock -> presenter.updateStockFilter(action.stock)
            PendingFilterAction.None -> super.onRefresh()
        }
        pendingFilterAction = PendingFilterAction.None
        _filterSummary.postValue(buildFilterSummary())
    }
}
```

要点：用 `sealed PendingFilterAction` 把筛选请求合并到 `onRefresh` 统一执行，避免并发抖动。

## POS-APP-CLIENT-G2-007：条件单列表轮询与可见性联动

来源：`feature/trade/trade-order/src/main/java/com/hstong/trade/order/condorder/viewmodel/BaseCondOrderListPageViewModel.kt`

```kotlin
fun onPageVisible() { isPageVisible = true; syncPollingState() }
fun onPageInvisible() { isPageVisible = false; syncPollingState() }
fun onModuleVisibleChanged(visible: Boolean) { isModuleVisible = visible; syncPollingState() }
fun pausePolling() { isPollingPaused = true; syncPollingState() }
fun resumePolling() { isPollingPaused = false; syncPollingState() }
```

要点：轮询基于 Page/Module 可见性 + 显式暂停三态；默认 3s 周期。

## POS-APP-CLIENT-G2-008：跨 Fragment 的作用域 ViewModel

来源：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/vm/vmscope/VMScopeStoreOwner.kt`

```kotlin
fun <T : ViewModel> LifecycleOwner.getScopeViewModel(scopeName: String, modelClass: Class<T>): T {
    val vmStoreOwner = vMStores[scopeName] ?: VMStoreOwner().also { vMStores[scopeName] = it }
    vmStoreOwner.bindHost(this)
    return ViewModelProvider(vmStoreOwner, ViewModelProvider.AndroidViewModelFactory(...))[modelClass]
}
```

```kotlin
host.lifecycle.addObserver(LifecycleEventObserver { _, event ->
    if (event == Lifecycle.Event.ON_DESTROY) {
        bindTargets.remove(host)
        if (bindTargets.isEmpty()) {
            viewModelStore.clear()
            vMStores.remove(/* this scope */)
        }
    }
})
```

要点：作用域 ViewModel 显式生命周期托管，最后一个 host 销毁即清理，避免 KMP Presenter 残留。

## POS-APP-CLIENT-G2-009：快捷改单二次确认 + 不再提示

来源：`feature/trade/trade-order/src/main/java/com/hstong/trade/order/normalorder/common/dialog/QuickEditConfirmDialogFragment.kt` 与 `RecentOrderFragment.kt`

```kotlin
viewModel.quickEditDraft.observe(viewLifecycleOwner) { draft ->
    draft ?: return@observe
    QuickEditConfirmDialogFragment.newInstance(draft).apply {
        onConfirm = { skipReminder -> viewModel.confirmQuickEdit(skipReminder) }
        onDialogDismiss = { viewModel.consumeQuickEditDraft() }
    }.show(childFragmentManager, "quick_edit_confirm")
}
```

要点：UI 仅消费一次性事件；ViewModel 仅在用户确认后才执行，且支持记忆「不再提示」开关。

## POS-APP-CLIENT-G2-010：网络拦截器统一注入交易必要参数

来源：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/interceptor/TradeBaseParamInterceptor.kt`

```kotlin
class TradeBaseParamInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        // 根据请求体里的 exchangeType 自动补 fundAccount / businessType
    }
}
```

要点：资金账号、业务类型由拦截器统一注入，避免业务代码逐处手填、降低泄漏面。
