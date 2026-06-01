---
doc_id: "ev-app-client-g6-userops-community-forbidden-examples"
title: "App-Client Android 用户运营与社区模块 - 禁止样本"
domain: "app-client"
sub_domain: "android"
industry: "securities"
doc_type: "evidence"
evidence_kind: "forbidden-examples"
status: "draft"
indexable: true
source_batch: "app-client-android-message-center-p1, app-client-android-community-feed-p1"
last_reviewed: "2026-05-26"
tags: ["evidence", "forbidden-examples", "user-ops", "community", "industry:securities"]
---

# App-Client Android 用户运营与社区模块 - 禁止样本

本文件记录在本批次内观察到的“反例”片段：要么已经被代码内 `// TODO 与文档不相同` 显式标记为待治理，要么属于规范 explicitly 禁止的写法，必须被新代码避免。

## NEG-APP-CLIENT-G6-001：硬编码协议 URL（标记治理中）

来源：`feature/user_operations/kaz_me/src/main/java/com/kaz/kaz_me/setting/SettingFragment.kt:120-124`

```kotlin
// TODO 与文档不相同，待确认修改：协议查看当前写死固定 URL，未对接 PRD 要求的协议管理服务与后台动态配置。
"privacy_policy" -> Router.startWeb(
    requireContext(),
    "http://feature.kazonline.com/universal/auth/agreement?agreementId=123123123"
)
```

为什么禁止：
- 协议 / 帮助 / 反馈等 URL 必须从 `RemoteConfigUrlPresenter` 提供的字段读取（参考 POS-APP-CLIENT-G6-007）。
- 直接硬编码 URL 还会 bypass 协议的环境切换、版本灰度、灰名单。

新代码必须：声明并消费 `RemoteConfigUrlPresenter.<新增 URL 字段>`，由 KMP 侧统一治理，不在 Android 视图层硬编码。

## NEG-APP-CLIENT-G6-002：跨模块直接依赖业务 module（标记治理中）

来源：`feature/user_operations/kaz_me/build.gradle:22-25`

```groovy
//    implementation project(':trade_assets:order')
// TODO 不应该直接依赖交易模块
implementation project(':feature:trade:trade-core')
```

为什么禁止：
- 用户中心模块属于“用户运营”领域，不应反向依赖交易模块；本依赖只为 `TradeLoginDebugEntryFragment` 测试入口存在。
- 该入口在 release 不应暴露，依赖也应清理。

新代码必须：通过 `Router` provider 协议（`getMessageCenterProvider()`、`IOrderPageProvider` 等）跨模块跳转，不直接 `implementation project(':feature:trade:...')`。

## NEG-APP-CLIENT-G6-003：测试广告挂在用户中心菜单（标记治理中）

来源：`feature/user_operations/kaz_me/src/main/java/com/kaz/kaz_me/MeFragment.kt:152-176`

```kotlin
private fun setupMenuList() {
    menuAdapter = MenuListAdapter { item ->
        when (item.id) {
            // TODO 与文档不相同，待确认修改：当前菜单仍保留测试广告入口，不是个人中心正式能力。
            "customer_service" -> showTestAd(PdpDisplayStyle.CENTER)
            // TODO 与文档不相同，待确认修改：当前菜单仍保留测试广告入口，不是个人中心正式能力。
            "help_center" -> Router.startWeb(...)
            ...
        }
    }
}
```

为什么禁止：
- “客户服务”菜单走测试广告 `showTestAd(...)` 不是正式业务，与 PRD 不一致。
- production 代码不允许使用 `seed/ad_*/600/800` 之类的占位资源去渲染线上 UI。

新代码必须：菜单点击只能跳到该业务的正式实现（`AccountProfileFragment` / `RemoteConfigUrlPresenter` 提供的 url / 未登录拉起登录），不允许放测试广告。

## NEG-APP-CLIENT-G6-004：Fragment 用 Bundle 当跨模块公开协议

来源：反例（不写真实业务字段进 Bundle，由 `MessageCenterNavigator.kt` 反推）

```kotlin
// 禁止：组装 ARouter path + Bundle key 跨模块传 KMP 业务上下文
val bundle = Bundle().apply {
    putString("menuType", item.menuType)
    putString("menuCode", item.menuCode)
    putString("appTabTypeCode", item.appTabTypeCode)
    putString("displayTitle", item.displayTitle)
}
ARouter.getInstance().build(PlatformRouterTable.PATH_MESSAGE_COMMENTLIST)
    .with(bundle)
    .navigation(context)
```

为什么禁止：
- `MessageCenterNavigator` 已经把这些字段封装为 `MessageTypeListContext` / `NotificationsTabContext` / `MessageTypeSettingsContext` 强类型，跨模块入口必须按 `IMessageCenterProvider.gotoMessagePage(...)` + 已声明的 OpenAPI 字段（仅 `from` / `initialPage` / `menuType` / `menuCode`）。
- Bundle key 命名是私有协议，散落在调用方会导致路由 schema 漂移。

新代码必须：把跨模块路径调用收敛到 provider 接口或同模块 `Navigator`；调用方不感知 Bundle key。

## NEG-APP-CLIENT-G6-005：WebView 危险 setter（公司级 FORBIDDEN，本批次未发现违规但需在 review 中持续 enforce）

来源：警示样本，本批次内代码未发现，但 community / web 容器仍要明确禁用以下写法：

```kotlin
// 禁止：开启 universal access from file
webView.settings.allowUniversalAccessFromFileURLs = true
webView.settings.allowFileAccessFromFileURLs = true

// 禁止：直接 loadUrl file:// 协议
webView.loadUrl("file:///android_asset/x.html")

// 禁止：在没有白名单校验的情况下接受外部传入 url
fun openWeb(externalUrl: String) {
    webView.loadUrl(externalUrl)
}
```

为什么禁止：
- `setAllowUniversalAccessFromFileURLs(true)` 会让 file:// 文档跨域访问任意 origin，曾是 Android WebView 经典安全漏洞。
- file:// 协议会让 WebView 绕过线上协议白名单。
- 直接 loadUrl 任意外部 URL 会被钓鱼 / XSS 利用。

新代码必须：
- 用户中心、社区、消息中心等领域的所有 web 跳转走 `Router.startWeb(context, url)`；URL 必须来自 `RemoteConfigUrlPresenter` 或经过 host 白名单校验。
- 禁止在业务 Fragment 中直接 `new WebView(...)` 或修改 `WebSettings`。

## NEG-APP-CLIENT-G6-006：UI 自行计算 / 缓存未读数

来源：反例（与 POS-APP-CLIENT-G6-001 对照）

```kotlin
// 禁止：在 Android 侧本地维护未读数
class MeFragment {
    private var localUnreadCount = 0

    private fun onMessageRead(id: String) {
        localUnreadCount = (localUnreadCount - 1).coerceAtLeast(0)
        binding.navigationBar.setRightIconBadge(localUnreadCount)
    }
}
```

为什么禁止：
- 未读数只能由 KMP `EntryBadgePresenter.uiState` 提供，本地缓存会与 push / 多端 / 跨页跳变脱节。
- 跨页刷新统一通过 `MessageCenterRefreshEvent.TotalUnreadChanged` 事件驱动 `presenter.request()`。

新代码必须：参考 `MeFragment.observeMessageCenterBadge()`，订阅 `presenter.uiState` + `refreshCenter.events`，UI 只 setRightIconBadge。

## NEG-APP-CLIENT-G6-007：在 onResume 中重新触发业务请求

来源：反例（与 `MessageCenterNotificationsFragment.onResume` 对照）

```kotlin
// 禁止：onResume 全量重新请求 tab 数据
override fun onResume() {
    super.onResume()
    presenter.requestTabs()           // 与 onFirstVisible 重复
    presenter.refresh(pageSize)       // 不必要的 IO
}
```

为什么禁止：
- 现有规范是 `onFirstVisible()` 触发首屏请求，`onResume()` 仅做权限/UI 状态镜像（`updatePermissionGuide()` / `updateSystemPushAuthorization(...)` / `setupUserInfo()`）。
- 全量请求会浪费 IO，并冲突跨页刷新事件总线的语义。

新代码必须：业务数据请求只在 `onFirstVisible` 与 `RefreshEvent` 触发；`onResume` 只更新权限镜像、本地引导态。
