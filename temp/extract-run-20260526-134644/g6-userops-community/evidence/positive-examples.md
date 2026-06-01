---
doc_id: "ev-app-client-g6-userops-community-positive-examples"
title: "App-Client Android 用户运营与社区模块 - 正向样本"
domain: "app-client"
sub_domain: "android"
industry: "securities"
doc_type: "evidence"
evidence_kind: "positive-examples"
status: "draft"
indexable: true
source_batch: "app-client-android-message-center-p1, app-client-android-community-feed-p1"
last_reviewed: "2026-05-26"
tags: ["evidence", "positive-examples", "user-ops", "community", "industry:securities"]
---

# App-Client Android 用户运营与社区模块 - 正向样本

## POS-APP-CLIENT-G6-001：消息中心入口 Badge 仅消费 KMP 状态

来源：`feature/user_operations/kaz_me/src/main/java/com/kaz/kaz_me/MeFragment.kt:40-130`

- Fragment 字段直接持有 `messageEntryBadgePresenter = MessageCenterPresenterFactory.createEntryBadgePresenter()` 与 `messageCenterRefreshCenter = MessageCenterPresenterFactory.createRefreshCenter()`。
- `observeMessageCenterBadge()` 中两个独立 `launch`：一个 collect `messageEntryBadgePresenter.uiState` 把 `state.unreadCount` 写到 `binding.navigationBar.setRightIconBadge`；一个 collect `messageCenterRefreshCenter.events`，仅在 `MessageCenterRefreshEvent.TotalUnreadChanged` 时调用 `refreshMessageCenterBadge()`。
- `refreshMessageCenterBadge()` 短路未登录态：`if (!HSLoginStatus.hasLogin()) { binding.navigationBar.setRightIconBadge(0); return }`，不发起未读数请求。

> 这是“UI 不计算未读、KMP 单一来源 + 跨页事件总线”的清晰样本。

## POS-APP-CLIENT-G6-002：列表页 Presenter / RefreshHelper 模板

来源：`feature/user_operations/message_center/src/main/java/com/kaz/message/center/ui/MessageCenterAlertListFragment.kt:25-138`

- 字段固定四件套：`presenter`、`refreshCenter`、`adapter = MessageCenterMessageListAdapter { item -> presenter.openMessage(item.id) }`、`refreshPaginationHelper`。
- `initView` 顺序：`bind binding -> recyclerView.layoutManager + adapter -> initRefreshLayout() -> observePresenter() -> observeRefreshEvents()`。
- `initRefreshLayout()` 中 `HsListRefreshPaginationHelper(...).bind(onRefresh = { notifyMessageCenterChildRefresh(); presenter.refresh(MESSAGE_CENTER_PAGE_SIZE) }, onLoadMore = { presenter.loadMore(MESSAGE_CENTER_PAGE_SIZE) })`。
- `observePresenter` 把 `state.contentState` 转交 `renderMessageCenterPageState(...)`，把 `state.items` 转交 adapter；`effectFlow` 中只处理 `OpenDynamicRoute` 一类“边界副作用”。

## POS-APP-CLIENT-G6-003：MessageCenterNavigator 强类型路由门面

来源：`feature/user_operations/message_center/src/main/java/com/kaz/message/center/ui/MessageCenterNavigator.kt`

- 所有 Bundle key 集中为 file 顶部 `private const val ARG_*`；分页 / 来源等业务常量集中为 `internal const val MESSAGE_CENTER_*`。
- 跨模块入口 `startMessageTypeList(context, listContext: MessageTypeListContext)` 接受强类型 KMP 上下文对象，再编码到 Bundle；反向通过 `listContext(args: Bundle?): MessageTypeListContext?` 解码。
- OpenAPI 入参规整：`normalizeInitialPage(initialPage)` 把不在白名单内的值兜底成 `MESSAGE_CENTER_INITIAL_PAGE_MESSAGE`；`normalizeMenuType(menuType)` 在 trim 后非空才返回。

> 这是“Bundle 不当公开协议、KMP 上下文显式编解码”的执行模板，社区/其他领域可对照。

## POS-APP-CLIENT-G6-004：系统通知权限统一收口

来源：`MessageCenterUiSupport.kt:18-39`、`MessageCenterSystemPushStateStore.kt:7-65`、`MessageCenterSettingsHomeFragment.kt:62-102`

- 权限读取统一为扩展函数 `Context.isMessageCenterSystemPushAuthorized() = NotificationManagerCompat.from(this).areNotificationsEnabled()`。
- 跳系统设置统一为扩展函数 `Context.openMessageCenterNotificationSettings()`，`Settings.ACTION_APP_NOTIFICATION_SETTINGS` + `EXTRA_APP_PACKAGE` + （O+）`EXTRA_CHANNEL_ID` + `FLAG_ACTIVITY_NEW_TASK`。
- `MessageCenterSystemPushStateTracker(permissionReader, cache)` 通过构造注入实现可测试，cache 写入 `UserCache.getGuestCache()` 的 `message_center_system_push_authorization` Boolean key。
- `MessageCenterSettingsHomeFragment` 在 `onResume` 中只刷新权限镜像（`presenter.updateSystemPushAuthorization(readCurrentSystemPushAuthorization())`），不重新请求业务数据。

## POS-APP-CLIENT-G6-005：Adapter 实现 IFooterView 防 footer 复挂

来源：`feature/user_operations/message_center/src/main/java/com/kaz/message/center/ui/adapter/MessageCenterMessageListAdapter.kt:20-71`

- Adapter 实现 `IFooterView`，把外部容器注入的 footer 通过 `addFooterView(view)` / `removeFooterView()` 收口。
- `onCreateViewHolder` 中先 `(footer.parent as? ViewGroup)?.removeView(footer)`，再 `return FooterViewHolder(footer)`，避免 `already has a parent` 崩溃。

## POS-APP-CLIENT-G6-006：appStyleCode 显式分发，未命中走 UNKNOWN

来源：`MessageCenterUiSupport.kt:63-103`

- `MessageCenterListStyle` 枚举显式声明 5 类样式 + UNKNOWN 兜底；`resolveMessageCenterListStyle` 只 lower-case + 去分隔符后做精确匹配。
- `Alert` 顶层列表 `isAlertListStyleSupported(appStyleCode)` 仅放行 `ALERT_NOTICE`，其余被空列表过滤；`MessageCenterAlertListFragment.observePresenter` 中显式：`val visibleItems = if (isAlertListStyleSupported(state.appStyleCode)) state.items else emptyList()`。

## POS-APP-CLIENT-G6-007：通过 RemoteConfig 提供 Web 跳转 URL

来源：`MeFragment.kt:158-169`、`AboutUsFragment.kt:118-120`、`AccountProfileFragment.kt:101-105`

- 帮助中心、反馈、关于条款、修改交易密码等所有用户中心场景均经 `Router.startWeb(context, RemoteConfigUrlPresenter.<urlField>)`。
- URL 字段（`helpCenterUrl` / `appFeedbackUrl` / `whatsNewEntryUrl` / `aboutUsIntroduceEntryUrl` / `changeTradingPassportUrl`）通过 KMP 远程配置获取，UI 不重新拼接。

## POS-APP-CLIENT-G6-008：社区主页占位 + RN 资讯 Tab 模板

来源：`feature/community_info/community/src/main/java/com/kaz/community/NewsFragment.kt`、`KazCommunityApplication.kt`

- 社区资讯 Tab 通过 `RnContainerLauncher.start(bundleName = RN_NEWS_BUNDLE_NAME, componentName = RN_NEWS_COMPONENT_NAME)` 挂载 RN 公共容器，社区模块自身不持有业务网络层。
- 重复进入复用：`val existed = childFragmentManager.findFragmentByTag(TAG_RN_NEWS_FRAGMENT); if (existed != null) { VLog.d(...); return }`。
- 模块启动通过 `IApplicationLifecycleService` + `@AutoService(IApplicationLifecycleService::class)` 把 `NewsFragment` 注册到 `MainTab.NEWS`，`getPriority() = Int.MAX_VALUE` 保证最后执行。

## POS-APP-CLIENT-G6-009：viewBinding + 释放模板

来源：`MeFragment.kt:37-38, 247-250`、`MessageCenterNotificationsFragment.kt:67-69`、`MessageCenterAlertListFragment.kt:22-23`

- 全部 Fragment 字段：`private var _binding: FragmentXxxBinding? = null` + `private val binding get() = _binding!!`。
- `initView()` 中 `_binding = FragmentXxxBinding.bind(requireView())`，`onDestroyView()` 中 `_binding = null`。
- 各模块 `build.gradle` 显式 `buildFeatures { viewBinding true }`。

## POS-APP-CLIENT-G6-010：登录态门禁的统一入口

来源：`MeFragment.kt:49-56, 83-87, 163-169`、`AccountProfileFragment.kt:54-65`

- 顶层入口跳转前调用 `GuestStatesUtils.isneedlogin()` 或 `HSLoginFlow.isNeedLaunchLoginPage()`，工具类统一处理“拉起登录”副作用。
- 已登录页二次校验：`onResume()` 中 `if (!HSLoginStatus.hasLogin() && isAdded) { requireActivity().finish(); return }`，避免会话失效后停留在敏感页面。
