---
doc_id: "ev-app-client-g2-trade-legacy-compatible"
title: "App-Client Android 交易模块 - 历史代码兼容观察"
domain: "app-client"
sub_domain: "android"
industry: "securities"
doc_type: "evidence"
evidence_kind: "legacy-compatible"
status: "draft"
indexable: true
source_batch: "app-client-android-trade-execution-order-p1, app-client-android-trade-account-binding-p1, app-client-android-trade-order-list-p1, app-client-android-trade-core-foundation-p1"
last_reviewed: "2026-05-26"
tags: ["evidence", "legacy", "trade", "industry:securities"]
---

# App-Client Android 交易模块 - 历史代码兼容观察

仓库内仍存在的历史/过渡形态，给出「现状 → 目标」与短期可允许的妥协边界。

## LEG-APP-CLIENT-G2-001：trade-execution 模块仍是空壳

- 现状：`feature/trade/trade-execution/` 已经声明独立 module、namespace `com.hstong.trade.condition`，但 `src/main/java/com/hstong/trade/condition/` 只有 `.keep`。条件单 UI/VM 实际落在 `feature/trade/trade-order/condorder/`。
- 目标：条件单业务逐步迁入 `trade-execution`，与 `trade-order` 解耦；规则中标识 `condorder/` 为「过渡位置」，禁止新增非条件单功能继续放进去。
- 兼容窗口：在 condorder 移出之前，新增条件单代码继续遵循 `BaseCondOrderListPageViewModel` 等基类约束。

## LEG-APP-CLIENT-G2-002：`@Deprecated TradeRouter`

- 现状：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/TradeRouter.kt` 标 `@Deprecated("")`，仍承载 H5 页面跳转：`startWithTitleAndUrl / startCorporate(...)`。
- 目标：新增跨模块跳转一律走 `IOrderPageProvider` 等 IProvider；H5 跳转走 `Router.startWeb(context, url)`（已在 `TradePasswordBottomSheet.kt:131` 出现）。
- 兼容窗口：仅维护既有调用方，禁止新增 `TradeRouter.startXxx` 调用入口。

## LEG-APP-CLIENT-G2-003：`@Deprecated PreferencesSettingViewModel`

- 现状：`PreferencesSettingViewModel` 标 `@Deprecated("Deprecated")`，但仍持有下单/交易偏好的关键开关（`SUBMIT_ORDER_CONFIRM`、`KEY_SUBMIT_ORDER_TIP_IGNORE_TIMES` 与 `TYPE_SUBMIT/QUICK_TRADE/...`）。
- 目标：新增偏好查询/设置应迁到 KMP 偏好/Function Config 通道（参考 `FunctionConfigManagerPool.getManager(...)`，已在 `SecurityAccountVM.kt` 使用）；本类不应再被新功能 import。
- 兼容窗口：现有「下单确认 / 不再提示次数」逻辑在替换前保留，新代码不要复用 `setPre/queeryPre`。

## LEG-APP-CLIENT-G2-004：FastJson + 老 OkHttp 工具

- 现状：`TradeBaseParamInterceptor` 使用 `com.alibaba.fastjson.JSONObject` 与 `com.huasheng.network.http.HttpUtils`、`OkHttpHelper.buildFormBody(...)`，未走 Kotlinx Serialization；FormBody 解析依赖 `buzz` JSON 字段约定。
- 目标：拦截器内部协议保持稳定，业务侧统一改用 KMP DTO + Kotlinx Serialization；新增请求结构尽量在 KMP Repository 层组装。
- 兼容窗口：拦截器实现可保留 FastJson，但禁止业务层新代码直接依赖 `com.alibaba.fastjson`。

## LEG-APP-CLIENT-G2-005：`PagePath` 空对象与 ARouter 残留

- 现状：`feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/PagePath.kt` 是空 `object PagePath { }`，但 `IOrderPageProvider` 仍继承 ARouter 的 `IProvider`。
- 目标：跨模块跳转完全经 `Router.getXxxProvider()`；ARouter path 仅作为 IProvider 的注册识别码，不再向业务层暴露字符串路径。
- 兼容窗口：保留 `IProvider` 注解扫描机制，业务侧禁止再写 `ARouter.getInstance().build(path)` 直接跳转。

## LEG-APP-CLIENT-G2-006：`startObservingPresenter` 类基类初始化期订阅

- 现状：`AllOrderViewModel.init { startObservingPresenter() }` 在构造时即开启 KMP Flow 订阅，回调里直接 `_filterSummary.value =`/`postValue(...)` 混用。
- 目标：发布到 LiveData 优先 `postValue` 或在 `withContext(Dispatchers.Main)` 下 `value=`，与 `RecentOrderViewModel` 保持一致风格。
- 兼容窗口：当前混用未触发问题，但新增 VM 必须按 `RecentOrderViewModel.init` 模式（`withContext(Dispatchers.Main)`）。

## LEG-APP-CLIENT-G2-007：被踢下线提示 `CoroutineScope(Dispatchers.Main)` 全局未取消

- 现状：`KazTradeApplication.onCreate` 中 `CoroutineScope(Dispatchers.Main).launch { TradeLoginFacade.kickOffMessageFlow.collect { ... } }`，没有显式取消（应用级 scope）。
- 目标：维持当前实现即可（应用生命周期跟进程一致）；规范层面要求其它业务模块订阅 KMP Flow 时使用 `viewModelScope` 或 `lifecycleScope`，禁止在 ViewModel 内重复构建 `CoroutineScope(Dispatchers.Main)`。
- 兼容窗口：仅 Application 级允许；代码评审需识别误用扩散。

## LEG-APP-CLIENT-G2-008：`TradePasswordBottomSheet` 内置 `Router.startWeb("https://baidu.com")`

- 现状：「Forgot password」点击跳到 `https://baidu.com`，明显占位地址。
- 目标：替换为正式忘记密码 H5；规范层面要求所有占位 URL 必须由 `AppConfigBean` 或 `MR.strings` 等远端配置返回。
- 兼容窗口：TODO 待 batch trade-core-foundation-p1 owner 确认后修复（落入 pending）。

## LEG-APP-CLIENT-G2-009：notifyDataSetChanged 全量刷新

- 现状：`AllOrderListAdapter.submitList(newItems)` 内部直接 `notifyDataSetChanged()`。
- 目标：迁移到 `ListAdapter` + DiffUtil 或 AsyncListDiffer，避免列表抖动与无效 rebind。
- 兼容窗口：当前 KMP 已经做过一层数据合并，业务可暂保留；规则中只做「推荐」级别提醒，未列入 P0 强制。
