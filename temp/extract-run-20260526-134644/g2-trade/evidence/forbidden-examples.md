---
doc_id: "ev-app-client-g2-trade-forbidden-examples"
title: "App-Client Android 交易模块 - 禁止/反例片段"
domain: "app-client"
sub_domain: "android"
industry: "securities"
doc_type: "evidence"
evidence_kind: "forbidden-examples"
status: "draft"
indexable: true
source_batch: "app-client-android-trade-execution-order-p1, app-client-android-trade-account-binding-p1, app-client-android-trade-order-list-p1, app-client-android-trade-core-foundation-p1"
last_reviewed: "2026-05-26"
tags: ["evidence", "forbidden", "trade", "industry:securities"]
---

# App-Client Android 交易模块 - 禁止/反例片段

本文件展示「**不要这样写**」的反例。所有反例均按规范改写，原始 selected-batch 中暂未观察到完整反例落地实现，故反例多为「与正例对照的虚构错误代码」，标注禁止理由与对应正例。

## NEG-APP-CLIENT-G2-001：跨模块直接 import 另一个 trade 子模块的 Fragment 类

```kotlin
// 反例：trade-account 直接依赖 trade-order 的 Fragment 类
import com.hstong.trade.order.normalorder.all.AllOrderFragment // 禁止

class SomeAccountFragment : Fragment() {
    fun openAllOrders(context: Context) {
        CommonActivity.start(context, AllOrderFragment::class.java) // 禁止
    }
}
```

禁止理由：违反 `IOrderPageProvider` 注释中「模块 A 不要直接依赖模块 B 的 Fragment 类」；编译期耦合，Fragment 类签名变更将级联破坏。
正例对照：POS-APP-CLIENT-G2-004，使用 `Router.getXxxProvider().getSecurityOrderFragment(request)`。

## NEG-APP-CLIENT-G2-002：Bundle key 跨模块拼装作为公开协议

```kotlin
// 反例：跨模块拼参
val bundle = Bundle().apply {
    putString("orderId", id)               // 弱协议
    putString("exchange", "HK")            // key 改名编译期无感
    putString("buy_or_sell", "BUY")
}
ARouter.getInstance().build("/trade/order/security").with(bundle).navigation()
```

禁止理由：`IOrderPageProvider` 明文禁止把 Bundle 当公开接口；Key 名变更编译期无法感知。
正例对照：POS-APP-CLIENT-G2-004，参数封装在 `OrderPageRequest` 强类型对象。

## NEG-APP-CLIENT-G2-003：交易密码原值进入 LiveData / ViewModel 长生命周期

```kotlin
// 反例：将密码暴露为 LiveData，跨生命周期可读
class SomeViewModel : ViewModel() {
    val tradePassword = MutableLiveData<String>()  // 禁止：内存中长期持有原始 6 位密码
    fun submit() { repo.login(tradePassword.value!!) }
}
```

禁止理由：交易密码属高敏感凭据，必须随用随消、避免长生命周期持有；`TradePasswordBottomSheet` 的实现仅用局部 `digits: String` 直接交给 KMP `UserInputData.forPassword`。
正例对照：POS-APP-CLIENT-G2-001。

## NEG-APP-CLIENT-G2-004：满 6 位后未禁用键盘导致重复提交

```kotlin
// 反例：onComplete 只发请求，不锁键盘
binding.codeField.onComplete = { digits ->
    lifecycleScope.launch {
        TradeLoginFacade.onUserInputSubmitted(sessionId, UserInputData.forPassword(digits, null, null))
    }
}
```

禁止理由：网络抖动时用户多次抖动可触发重复登录请求，可能命中「密码错误次数过多」从而被锁仓。
正例对照：POS-APP-CLIENT-G2-001 中 `binding.codeField.isEnabled = false`。

## NEG-APP-CLIENT-G2-005：show 弹窗未判 isStateSaved

```kotlin
// 反例：直接 show，应用切后台/横竖屏切换时崩溃
override fun show(sessionId: String, presentation: TradeLoginPresentation) {
    val fm = fragmentManagerRef.get() ?: return
    TradePasswordBottomSheet.newInstance(sessionId).show(fm, "trade_password")  // 可能 IllegalStateException
}
```

禁止理由：`FragmentManager.isStateSaved=true` 时 `show()` 抛 IllegalStateException；登录会话还会悬挂等待用户输入。
正例对照：POS-APP-CLIENT-G2-002 + `showSafe`。

## NEG-APP-CLIENT-G2-006：UiPort 用强引用持有 FragmentManager / Activity

```kotlin
// 反例：强引用 Activity，登录页跳转回来后泄漏
class KazTradeLoginUiPortImpl(private val fragmentManager: FragmentManager) : TradeLoginUiPort {
    // 没有 WeakReference，没有 Activity 切换重绑机制
}
```

禁止理由：交易登录可能拉起平台登录页/H5，原 Activity 销毁后强引用导致泄漏；返回时也无法刷新到当前 Activity 的 FragmentManager。
正例对照：POS-APP-CLIENT-G2-002 + POS-APP-CLIENT-G2-003。

## NEG-APP-CLIENT-G2-007：下单二次确认走 showToast / 默认确认按钮

```kotlin
// 反例：用 Toast 替代二次确认，或默认右键确认
fun onPlaceOrder() {
    "Are you sure?".showToast()
    api.submitOrder(...)
}

// 反例：直接默认聚焦确认按钮
OrderDialogUtil.showTwoBtnAndTitleDialog(
    context, title = "Confirm", msg = "你将买入 1000 股 9988.HK",
    confirmText = "OK", onConfirm = { api.submitOrder(...) }
)
```

禁止理由：securities 行业要求下单类高风险操作必须经过显式二次确认，并对「取消」给予视觉强调（防误触）；`showEmphasisCancelDialog` 即为此设计（左继续/右取消，突出取消）。
正例对照：`OrderDialogUtil.showEmphasisCancelDialog` + `QuickEditConfirmDialogFragment`（POS-APP-CLIENT-G2-009）。

## NEG-APP-CLIENT-G2-008：下单关键参数靠业务代码逐处手填

```kotlin
// 反例：每个下单调用都手动塞 fundAccount/businessType
api.submitOrder(
    fundAccount = userRepo.getCurrentFundAccount(),  // 散落，易遗漏
    businessType = "11",                              // 魔法数字
    exchangeType = "HK",
    ...
)
```

禁止理由：资金账号、业务类型属敏感数据，散落业务代码会扩大泄漏面；魔法数字与映射重复维护；与 `TradeBaseParamInterceptor` 注入路径冲突。
正例对照：POS-APP-CLIENT-G2-010 拦截器统一注入。

## NEG-APP-CLIENT-G2-009：在 Fragment / Activity 直接 collect KMP Flow

```kotlin
// 反例：UI 层直接订阅 KMP Presenter Flow
class AllOrderFragment : Fragment() {
    private val presenter = TradeOrderPresenterFactory.createAllOrdersPresenter(TradingMarket.HK) // 错地方
    override fun onViewCreated(...) {
        lifecycleScope.launch { presenter.uiState.collect { ... } }
    }
}
```

禁止理由：Presenter 与生命周期耦合应在 ViewModel 层（`viewModelScope`），UI 重建时不应重建 Presenter；本仓库所有交易页都按 ViewModel 拥有 Presenter 实施。
正例对照：POS-APP-CLIENT-G2-005。

## NEG-APP-CLIENT-G2-010：使用 ARouter path 字符串 + Bundle 跨模块替代 Provider

```kotlin
// 反例
ARouter.getInstance()
    .build("/trade/order/security")        // path 字符串
    .withString("orderId", id)              // bundle key
    .navigation()
```

禁止理由：与 `IOrderPageProvider` 治理目标冲突；path 改名编译期无感、参数协议无强类型校验。
正例对照：POS-APP-CLIENT-G2-004。
