---
doc_id: "ev-app-client-g6-userops-community-legacy-compatible"
title: "App-Client Android 用户运营与社区模块 - 兼容性写法"
domain: "app-client"
sub_domain: "android"
industry: "securities"
doc_type: "evidence"
evidence_kind: "legacy-compatible"
status: "draft"
indexable: true
source_batch: "app-client-android-message-center-p1, app-client-android-community-feed-p1"
last_reviewed: "2026-05-26"
tags: ["evidence", "legacy-compatible", "user-ops", "community", "industry:securities"]
---

# App-Client Android 用户运营与社区模块 - 兼容性写法

记录在迁移期间被显式保留的“过渡写法”：仍然存在于 production，需要在新代码中按规范替换，但不要求一次性清除。

## LEG-APP-CLIENT-G6-001：旧 LoadMoreRecyclerContainer 的 IFooterView 协议

来源：`MessageCenterMessageListAdapter.kt:14-22, 63-71`、`MessageCenterAlertListFragment.kt:55-85`

```kotlin
internal class MessageCenterMessageListAdapter(
    private val onItemClick: (MessageCenterMessageRowUIState) -> Unit,
) : RecyclerView.Adapter<RecyclerView.ViewHolder>(), IFooterView {
    ...
    override fun addFooterView(view: View) { footerView = view; notifyDataSetChanged() }
    override fun removeFooterView() { footerView = null; notifyDataSetChanged() }
}
```

兼容原因：
- 旧 `LoadMoreRecyclerContainer` 只会给实现 `IFooterView` 的 adapter 注入页尾，不实现就拿不到 “没有更多了” 文案。
- 现仅在迁移到 `HsListRefreshPaginationHelper` 期间保留，等公共 footer 全部由新 helper 接管后可摘除。

迁移建议：新写的列表页直接使用 `HsListRefreshPaginationHelper.bind(onRefresh, onLoadMore)`，不要重新引入 `IFooterView`。

## LEG-APP-CLIENT-G6-002：PtrClassicFrameLayout 默认 header 替换为 HsLoadingRefreshHeader

来源：`MessageCenterAlertListFragment.kt:54-85`、`MessageCenterMessageAggregateFragment.kt:48-65`

```kotlin
binding.refreshLayout.apply {
    setRefreshHeader(HsLoadingRefreshHeader(context))
    setEnableLoadMore(false)
    setEnableOverScrollBounce(false)
    setOnRefreshListener { ... }
}
```

兼容原因：
- 旧 `PtrClassicFrameLayout` 默认 Header 会带“下拉刷新”中文文案，不符合视觉规范。
- 现统一切到 SmartRefreshLayout + `HsLoadingRefreshHeader`；列表页通过 helper 装配。

迁移建议：新页面直接使用 `HsListRefreshPaginationHelper`（带分页）或 `binding.refreshLayout.setRefreshHeader(HsLoadingRefreshHeader(context))`（无分页）。

## LEG-APP-CLIENT-G6-003：Provider 中 trackInAppMsgClick 仍保留空实现

来源：`feature/user_operations/message_center/src/main/java/com/kaz/message/center/global/MsgProvider.kt:32-34`

```kotlin
override fun trackInAppMsgClick(msgId: String?, inAppMsgChannel: String?) {
    // 新消息中心当前仅做 Provider 兼容，不额外扩展旧模块埋点实现。
}
```

兼容原因：
- 旧 `IMessageCenterProvider` 接口签名要求实现 `trackInAppMsgClick`；新消息中心直接置空，避免误埋点旧 schema。

迁移建议：等旧入口完全下线后，把接口方法移除或迁移到新埋点链路；现在保留空实现而非抛错，是显式契约“接口存在但本实现暂不参与”。

## LEG-APP-CLIENT-G6-004：commitNowAllowingStateLoss 提交 RN 容器

来源：`feature/community_info/community/src/main/java/com/kaz/community/NewsFragment.kt:30-39`

```kotlin
childFragmentManager.beginTransaction()
    .replace(R.id.rnContainer, RnContainerLauncher.start(...), TAG_RN_NEWS_FRAGMENT)
    .commitNowAllowingStateLoss()
```

兼容原因：
- 资讯 Tab 是首屏立即可见的 RN 容器，需要在 `initView` 阶段直接 commit；为了避免 Fragment 状态保存阶段触发 `IllegalStateException`，使用 `commitNowAllowingStateLoss()`。
- 该写法在公共 RN 容器迁移完成前保留。

迁移建议：等公共 RN 容器支持延迟挂载与 lifecycle-safe commit 后，切到 `commitNow()` 或 `commit()` + lifecycle 调度。

## LEG-APP-CLIENT-G6-005：CommunityFragment 占位 TextView

来源：`feature/community_info/community/src/main/java/com/kaz/community/CommunityFragment.kt:14-38`

```kotlin
class CommunityFragment : BaseMvvmFragment<CommunityViewModel>() {
    override fun initView() {
        val textView = TextView(requireContext()).apply {
            text = "社区"
            ...
        }
        (rootView as? FrameLayout)?.addView(textView)
    }
}
```

兼容原因：
- 当前社区 Tab 处于占位阶段，业务 Feed 尚未接入；直接动态加 TextView 而不是 layout 文件，是临时占位写法。

迁移建议：业务接入时迁移到 `getLayoutId()` + ViewBinding + Adapter + Presenter 模板（参考消息中心列表页），并删除占位 TextView。

## LEG-APP-CLIENT-G6-006：MeFragment 的 NavigationBar 三右图标布局

来源：`MeFragment.kt:73-96`

```kotlin
binding.navigationBar.apply {
    setType(HSNavigationBar.Type.PRIMARY)
    setTitle(" ")
    setRightIconAmount(HSNavigationBar.RightIconCount.THREE)
    setRightIcon("icon_common_msg")
    setRightIconSecond("icon_common_settings")
    setRightIconThird("ic_me_search")
    findViewById<android.view.View>(com.hstong.hscomponents.R.id.right_icon_container)
        ?.setOnClickListener { ... }
    ...
}
```

兼容原因：
- `HSNavigationBar` 暴露的右图标点击只能通过 `findViewById` 查内部容器；目前规范期内可用，但拉低封装。
- 第三个 “debug” 图标接的是 `TradeLoginDebugEntryFragment`，依赖 trade-core；属于 NEG-APP-CLIENT-G6-002 的依附点。

迁移建议：等 `HSNavigationBar` 暴露 `setRightIconClickListener` / `setRightIconSecondClickListener` API 后切换；并清掉不应在用户中心出现的 debug 入口。

## LEG-APP-CLIENT-G6-007：appStyleCode 显式枚举 + 多 alias

来源：`MessageCenterUiSupport.kt:77-96`

```kotlin
internal fun resolveMessageCenterListStyle(appStyleCode: String?): MessageCenterListStyle {
    return when (normalizeMessageCenterStyleCode(appStyleCode)) {
        "pricealerts", "appstyle1pricealerts" -> MessageCenterListStyle.PRICE_ALERTS
        "ordernotice", "appstyle2ordernotice" -> MessageCenterListStyle.ORDER_NOTICE
        ...
    }
}
```

兼容原因：
- 新旧后端字段共存：服务端可能返回 `pricealerts`、也可能返回 `appstyle1pricealerts`。
- 显式列表 + UNKNOWN 兜底，比正则推断更可靠，是过渡期安全做法。

迁移建议：等服务端 schema 收敛到单一 alias 后，移除 `appstyle*` 兼容；保留 UNKNOWN 兜底。
