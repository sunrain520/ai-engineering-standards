---
doc_id: "ev-app-client-g6-userops-community-code-facts"
title: "App-Client Android 用户运营与社区模块 - 代码事实清单"
domain: "app-client"
sub_domain: "android"
industry: "securities"
doc_type: "evidence"
evidence_kind: "code-facts"
status: "draft"
indexable: true
source_batch: "app-client-android-message-center-p1, app-client-android-community-feed-p1"
last_reviewed: "2026-05-26"
tags: ["evidence", "code-facts", "user-ops", "community", "message-center", "industry:securities"]
---

# App-Client Android 用户运营与社区模块 - 代码事实清单

仅记录 selected-batch 范围内可观察到的代码事实，路径均为 kaz-mvp 项目根的相对路径。`kaz_me` 模块本批次未直接归属，但作为消息中心 Badge / 个人中心入口宿主多处出现，相关事实在文末标注 evidence_tier=inferred。

## EV-APP-CLIENT-G6-001：模块结构

- 用户运营领域包含 3 个 Android library 模块（来源：`feature/user_operations/`）：
  - `feature/user_operations/kaz_me/`（namespace `com.kaz.kaz_me`，artifactId `kaz-me`）
  - `feature/user_operations/message_center/`（namespace `com.kaz.message`，artifactId `msg-center`）
  - `feature/user_operations/pager_reach/`（excluded by run config，未读取）
- 社区领域包含 1 个 Android library 模块（来源：`feature/community_info/`）：
  - `feature/community_info/community/`（namespace `com.kaz.community`，artifactId `kaz-community`）
- 团队 AGENTS.md（`feature/user_operations/AGENTS.md`）声明：「kaz_me 包括我的、设置、账号安全等用户相关页面」「message_center 是消息中心模块」。

## EV-APP-CLIENT-G6-002：构建配置

- 三个用户运营/社区模块均启用 `apply plugin: 'com.android.library'` 和 `apply plugin: 'hs-maven-publish'`，`buildFeatures { viewBinding true }` 一致开启。证据：`feature/user_operations/kaz_me/build.gradle:3-13`、`feature/user_operations/message_center/build.gradle:3-13`、`feature/community_info/community/build.gradle:3-12`。
- 公共依赖：`Deps.Lib.common`、`project(":core:core-ui-kit")`、`project(':core:capability:kaz-pdp')`（kaz_me / message_center），`Deps.Lib.userinfo`（kaz_me / message_center），`project(':app-core')`（kaz_me / message_center）。
- 社区模块只引入 `Deps.Lib.common`、`project(":core:core-ui-kit")`、`project(":core:capability:react-native")`，未引入 webview/userinfo 依赖。证据：`feature/community_info/community/build.gradle:14-19`。
- kaz_me 注释中标注 `// TODO 不应该直接依赖交易模块` + `implementation project(':feature:trade:trade-core')`，已标记需治理的反向依赖（位于 `kaz_me/build.gradle:22-24`）。

## EV-APP-CLIENT-G6-003：架构形态（KMP Presenter 桥接）

- message_center Fragment 通过工厂方法获取 KMP Presenter：`MessageCenterPresenterFactory.createNotificationsPresenter(refreshCenter)`、`createMessageAggregatePresenter()`、`createAlertListPresenter()`、`createSettingsHomePresenter()`、`createMessageTypeListPresenter(refreshCenter)`、`createEntryBadgePresenter()`。证据：`feature/user_operations/message_center/src/main/java/com/kaz/message/center/ui/MessageCenterNotificationsFragment.kt:70-72`、`MessageCenterMessageAggregateFragment.kt:23-26`、`MessageCenterAlertListFragment.kt:25-31`、`MessageCenterSettingsHomeFragment.kt:43`。
- Android 壳层只持有 binding、Adapter、`refreshCenter`、`presenter`，列表数据 / 分页 / 已读标记 / 跨页刷新事件全部来自 KMP Presenter 的 `uiState` Flow 与 `effectFlow`/`events` Flow。证据：`MessageCenterAlertListFragment.kt:114-138`。
- 进入页面以 `presenter.request(...)`/`presenter.refresh(...)`/`presenter.loadMore(MESSAGE_CENTER_PAGE_SIZE)` 驱动 KMP；用户点击通过 `presenter.openMessage(item.id)` / `presenter.selectTab(tabState.context)` 回写。证据：`MessageCenterAlertListFragment.kt:27-31, 70-82`、`MessageCenterNotificationsFragment.kt:80-87`。
- 入口 Badge：`MeFragment` 持有 `messageEntryBadgePresenter = MessageCenterPresenterFactory.createEntryBadgePresenter()`，并订阅 `messageCenterRefreshCenter.events`，仅当 `MessageCenterRefreshEvent.TotalUnreadChanged` 时调用 `refreshMessageCenterBadge()`。证据：`feature/user_operations/kaz_me/src/main/java/com/kaz/kaz_me/MeFragment.kt:40-130`（kaz_me 为 inferred 来源）。

## EV-APP-CLIENT-G6-004：Fragment 基类与生命周期

- message_center 所有页面继承 `MessageCenterBaseFragment`（`com.hstong.core.uikit.basefragment.base.BaseFragment` 子类），公共能力仅两项：
  - `collectWhenStarted(flow) { ... }` 在 `STARTED` 状态用 `repeatOnLifecycle(Lifecycle.State.STARTED) { flow.collect ... }` 收集 Flow；
  - `toast(message)` 通过 `HSToast.show(requireContext(), message)`。
  证据：`MessageCenterBaseFragment.kt:13-40`。
- kaz_me 页面继承 `KazMeBaseFragment<VM>`（`BaseMvvmFragment<VM>` 子类），`toast()` 通过 `App.getCurrentActivity()` 获取 Activity。证据：`KazMeBaseFragment.kt:8-15`。
- 视觉初始化模板：`initView()` 顺序固定为 `setupWindowInsets() -> setupNavigationBar() -> 容器/列表/状态监听`；`onFirstVisible()` 触发首屏请求；`onResume()` 仅做权限/状态相关刷新，不再次请求业务数据。证据：`MessageCenterNotificationsFragment.kt:98-119`、`MessageCenterMessageAggregateFragment.kt:38-85`、`MessageCenterSettingsHomeFragment.kt:48-69`。
- ViewBinding 释放：`var _binding: FragmentXxxBinding? = null` + `private val binding get() = _binding!!` + `onDestroyView { super.onDestroyView(); _binding = null }`。证据：`MeFragment.kt:37-38, 247-250`、`MessageCenterNotificationsFragment.kt:67-69`、`AccountProfileFragment.kt:34-35`。

## EV-APP-CLIENT-G6-005：导航栏统一模板

- 顶层 Tab（首页类）使用 `HSNavigationBar.Type.PRIMARY`，配 `RightIconCount.THREE`，右图标通过 `findViewById(com.hstong.hscomponents.R.id.right_icon_container)` 等绑定点击。证据：`MeFragment.kt:73-96`。
- 二级页统一使用 `HSNavigationBar.Type.SECONDARY`，左图标 `setLeftIcon("dt_back")`，左侧返回固定 `findViewById(...left_icon)?.setOnClickListener { requireActivity().finish() }`。证据：`SettingFragment.kt:78-86`、`AboutUsFragment.kt:71-79`、`AccountProfileFragment.kt:77-85`、`MessageCenterSettingsHomeFragment.kt:79-87`。
- 状态栏内边距统一通过 `applyStatusBarInsets { statusBarHeight -> ... topMargin = statusBarHeight ... }`。证据：`MeFragment.kt:64-71`、`MessageCenterNotificationsFragment.kt:138-144`、`SettingFragment.kt:70-76`。

## EV-APP-CLIENT-G6-006：路由与 Provider 协议

- 消息中心通过 `IMessageCenterProvider`（`com.hstong.router.provider.IMessageCenterProvider`）对外暴露能力：`startUserCenterUI(context, from)`、`gotoMessagePage(activity, routerPath, bundle)`、`trackInAppMsgClick(...)`、`getWebToNative(...)`。证据：`feature/user_operations/message_center/src/main/java/com/kaz/message/center/global/MsgProvider.kt:21-65`。
- ARouter 路径常量集中在 `com.hstong.router.redirect.arouter.routertable.PlatformRouterTable`：`PATH_NEW_MESSAGE_CENTER`、`PATH_MESSAGE_CENTER_SETTINGS`、`PATH_MESSAGE_COMMENTLIST`，`@Route(path = ...)` 用于 Fragment 注册。证据：`MessageCenterNotificationsFragment.kt:42`、`MessageCenterMessageTypeListFragment.kt:29`、`MessageCenterSettingsHomeFragment.kt:28`、`MsgProvider.kt:20`。
- `gotoMessagePage` 通过 `routerPath` 分支 + 仅取 `bundle?.getString("from")` / `bundle?.getString("initialPage")` / `bundle?.getString("menuType")`，所有 KMP 业务上下文不放入 Bundle。证据：`MsgProvider.kt:43-64`。
- `MessageCenterNavigator` 是 internal 对象，统一封装 Bundle 的 12 个 ARG_ 常量与 `startNotifications` / `startSettingsHome` / `startMessageTypeList(context, listContext)` / `startMessageTypeListByMenuType(context, menuType)` / `startTypeSettings(context, settingsContext)`，对外只暴露强类型上下文入参（`MessageTypeListContext` / `MessageTypeSettingsContext` / `NotificationsTabContext`）。证据：`MessageCenterNavigator.kt:36-215`。
- OpenAPI 入参规整：`normalizeInitialPage(initialPage)` 仅接受 `alert` / `message`，缺省落到 `message`；`normalizeMenuType(menuType)` 仅在 trim 后非空时返回。证据：`MessageCenterNavigator.kt:154-156, 193-198`。

## EV-APP-CLIENT-G6-007：分页与刷新模板（消息中心）

- 列表页统一使用 `HsListRefreshPaginationHelper(refreshLayout, recyclerView, log)` 装配下拉刷新 + 上拉加载更多，`bind(onRefresh, onLoadMore)` 内部转发到 `presenter.refresh(MESSAGE_CENTER_PAGE_SIZE)` / `presenter.loadMore(MESSAGE_CENTER_PAGE_SIZE)`。证据：`MessageCenterAlertListFragment.kt:59-85`、`MessageCenterMessageTypeListFragment.kt:95-120`。
- 聚合页（无分页）使用 `HsLoadingRefreshHeader`，显式 `setEnableLoadMore(false)` + `setEnableOverScrollBounce(false)`。证据：`MessageCenterMessageAggregateFragment.kt:53-65`。
- 子页刷新会先 `notifyMessageCenterChildRefresh()` 通知宿主重拉 tabs，再触发 Presenter `refresh`，避免顶层未读数和列表数据脱节。证据：`MessageCenterAlertListFragment.kt:66-72`、`MessageCenterMessageAggregateFragment.kt:58-63`。
- 分页常量：`MESSAGE_CENTER_PAGE_SIZE = 20`，集中在 `MessageCenterNavigator.kt:24`，供所有列表页统一引用。
- `IFooterView` 协议：`MessageCenterMessageListAdapter` 实现 `IFooterView`，把外部容器注入的 footer 通过 `addFooterView(view)` / `removeFooterView()` 收口；`onCreateViewHolder` 中先 `(footer.parent as? ViewGroup)?.removeView(footer)` 防 `already has a parent` 崩溃。证据：`MessageCenterMessageListAdapter.kt:20-71`。

## EV-APP-CLIENT-G6-008：消息中心未读与 Badge

- 入口 Badge 通过 `messageEntryBadgePresenter.uiState.collect { state -> binding.navigationBar.setRightIconBadge(state.unreadCount) }`，UI 不计算未读数。证据：`MeFragment.kt:103-119`。
- 未登录场景显式短路：`refreshMessageCenterBadge()` 中 `if (!HSLoginStatus.hasLogin()) { binding.navigationBar.setRightIconBadge(0); return }`，避免对未登录用户请求未读数。证据：`MeFragment.kt:122-130`。
- Tab 数字 Badge 在 `HSTabLayout.renderMessageCenterTabBadges(unreadCounts)` 中按 `unreadCount <= 0` 隐藏，`> 99` 走 `formatMessageCenterUnread` 显示 `99+`。证据：`MessageCenterPageRendering.kt:68-105`、`MessageCenterUiSupport.kt:48-50`。
- 跨页刷新事件：`MessageCenterPresenterFactory.createRefreshCenter()` 提供 `events: Flow<MessageCenterRefreshEvent>`，已观察到的事件名：`TotalUnreadChanged`、`TabUnreadChanged`、`AggregateChanged`、`MenuOrderChanged`。证据：`MeFragment.kt:111-117`、`MessageCenterMessageAggregateFragment.kt:113-120`。

## EV-APP-CLIENT-G6-009：系统通知权限收口

- 权限读取统一通过扩展函数 `Context.isMessageCenterSystemPushAuthorized()` = `NotificationManagerCompat.from(this).areNotificationsEnabled()`。证据：`MessageCenterUiSupport.kt:26-28`。
- 跳系统设置统一通过扩展函数 `Context.openMessageCenterNotificationSettings()`，使用 `Settings.ACTION_APP_NOTIFICATION_SETTINGS` + `EXTRA_APP_PACKAGE` + `EXTRA_CHANNEL_ID`（O 及以上），追加 `FLAG_ACTIVITY_NEW_TASK`。证据：`MessageCenterUiSupport.kt:30-39`。
- 状态镜像：`MessageCenterSystemPushStateStore.readCurrentAndMirror(context)` 读取当前权限并写入 `UserCache.getGuestCache()` 中 `message_center_system_push_authorization` Boolean key。`MessageCenterSystemPushStateTracker` 通过构造注入 `permissionReader: () -> Boolean` 与 `cache: MessageCenterBooleanStore?`，便于 unit test 覆盖。证据：`MessageCenterSystemPushStateStore.kt:7-65`、`feature/user_operations/message_center/src/test/java/com/kaz/message/center/ui/MessageCenterSystemPushStateStoreTest.kt`。
- UI 状态：`MessageCenterRuntimeState.notificationsGuideDismissedInProcess: Boolean` 仅在进程内允许手动关闭一次权限引导，进程重启后重新判断。证据：`MessageCenterUiSupport.kt:18-24`。

## EV-APP-CLIENT-G6-010：列表样式分发与文本高亮

- `appStyleCode` 显式分发：`resolveMessageCenterListStyle(appStyleCode)` 按 5 类（PRICE_ALERTS / ORDER_NOTICE / HOT_NEWS / SYSTEM_NOTICE / ALERT_NOTICE）+ UNKNOWN 兜底，未命中时不做推断。证据：`MessageCenterUiSupport.kt:77-96`。
- `Alert` 顶层列表页：`isAlertListStyleSupported(appStyleCode)` 仅放行 `ALERT_NOTICE`，其余样式被空列表过滤。证据：`MessageCenterUiSupport.kt:98-103`、`MessageCenterAlertListFragment.kt:114-119`。
- 文案高亮：`buildMessageCenterHighlightedContent(text, linkColor)` 用 `MESSAGE_CENTER_URL_REGEX = Regex("""https?://\S+""")` 匹配 URL 渲染高亮，整行点击仍由外层卡片承接（不挂 ClickableSpan）。证据：`MessageCenterUiSupport.kt:105-132, 165`。
- `Order Notice` 中 `$XXX$` 包裹的代码块通过 `MESSAGE_CENTER_DOLLAR_REGEX = Regex("""\$[^$]+\$""")` 高亮。证据：`MessageCenterUiSupport.kt:137-167`。

## EV-APP-CLIENT-G6-011：社区模块当前形态

- `community` 模块仅 3 个 Kotlin 文件：`KazCommunityApplication.kt`（模块启动）、`CommunityFragment.kt`（占位）、`NewsFragment.kt`（资讯 Tab，RN 容器）。证据：`feature/community_info/community/src/main/java/com/kaz/community/`。
- 启动注册：`KazCommunityApplication : IApplicationLifecycleService`，`getPriority() = Int.MAX_VALUE`，`onCreate(context)` 中 `ModuleHelper.get().addLauncher(MainTab.NEWS, IModuleLauncher { NewsFragment::class.java })`，`@AutoService(IApplicationLifecycleService::class)`。证据：`KazCommunityApplication.kt:11-30`。
- 社区主页 `CommunityFragment` 当前为占位 TextView（紫色背景 `#9C27B0` + 文案“社区”），未接入 Feed 业务；`override fun observeLiveData()` 显式空实现。证据：`CommunityFragment.kt:14-38`。
- 资讯 `NewsFragment` 通过 `RnContainerLauncher.start(bundleName = "hs-kaz-rn-news", componentName = "NewsHomePage")` 挂载 RN 容器，`commitNowAllowingStateLoss()` 提交，重复进入时通过 `childFragmentManager.findFragmentByTag(TAG_RN_NEWS_FRAGMENT)` 复用既有容器。证据：`NewsFragment.kt:22-39`。
- bundle / component 名为 const private 常量集中在 `companion object`：`TAG_RN_NEWS_FRAGMENT = "rn_news_container"`、`RN_NEWS_BUNDLE_NAME = "hs-kaz-rn-news"`、`RN_NEWS_COMPONENT_NAME = "NewsHomePage"`。证据：`NewsFragment.kt:46-51`。
- 模块未引入 WebView 依赖，build.gradle 仅声明 `core:capability:react-native`；社区模块代码内未发现 `WebView` / `loadUrl` / `setJavaScriptEnabled` 等调用（grep 结果为空）。证据：`feature/community_info/community/build.gradle:14-19`、search 结果。

## EV-APP-CLIENT-G6-012：WebView 网页跳转策略（用户中心场景）

- 用户中心相关 web 跳转统一走 `Router.startWeb(context, url)`，URL 由 `RemoteConfigUrlPresenter` 提供：`helpCenterUrl`、`appFeedbackUrl`、`whatsNewEntryUrl`、`aboutUsIntroduceEntryUrl`、`changeTradingPassportUrl`。证据：`MeFragment.kt:158-169`、`AboutUsFragment.kt:118-120`、`AccountProfileFragment.kt:101-105`。
- 设置页隐私协议入口存在硬编码 URL（标记为待治理）：`Router.startWeb(requireContext(), "http://feature.kazonline.com/universal/auth/agreement?agreementId=123123123")`，对应位置带有 `// TODO 与文档不相同，待确认修改：协议查看当前写死固定 URL`。证据：`SettingFragment.kt:120-124`。
- 模块代码内未见直接 `WebView.loadUrl` / `setAllowUniversalAccessFromFileURLs` / `setAllowFileAccess` / `addJavascriptInterface` 调用；具体 WebView 安全策略由 `Router.startWeb` 后接的 web 容器负责（不在本批次）。

## EV-APP-CLIENT-G6-013：日志与 Toast

- 日志统一使用 `com.hstong.log.VLog`，约定 `private const val TAG`（位于 `companion object` 或顶层 const）作为 tag。证据：`MessageCenterAlertListFragment.kt:12, 63, 76`、`AboutUsFragment.kt:36-38, 103, 127, 148`、`NewsFragment.kt:46-47`。
- Toast 统一使用 `HSToast.show(context, message)`，并通过基类 `toast(message)` 收口；空白文案 `isNullOrBlank` 时不弹出。证据：`MessageCenterBaseFragment.kt:21-25`、`KazMeBaseFragment.kt:10-14`。

## EV-APP-CLIENT-G6-014：登录态门禁与点击防抖

- 进入需登录的二级页前统一调用 `GuestStatesUtils.isneedlogin()`（如 ProfileFragment 入口）或 `HSLoginFlow.isNeedLaunchLoginPage()`（msg-center / feedback 入口），返回 true 时由这些工具触发登录流程，UI 直接 `return`。证据：`MeFragment.kt:49-56, 83-87, 163-169`。
- AccountProfile 在 `onResume` 中再次校验登录态：`if (!HSLoginStatus.hasLogin() && isAdded) { requireActivity().finish(); return }`。证据：`AccountProfileFragment.kt:54-65`。
- 点击防抖：用户运营页面统一使用扩展 `View.onMultiClick { ... }`（来源 `com.hstong.common.utils.onMultiClick`），常用于 navigation bar、引导文案、guide close。证据：`MeFragment.kt:54-55, 81-95`、`MessageCenterNotificationsFragment.kt:126-132, 154-156`、`AboutUsFragment.kt:89-90`。

## 已知 inferred / 未覆盖范围

- kaz_me 不在本批次显式 selected_batches 中，相关引用（Badge 入口、登录路由）以 inferred 写入；写入 `pending-confirmation.md` 的 PENDING-APP-CLIENT-G6-1 标记。
- `pager_reach`、`feature/user_operations/AndroidManifest.xml`（仅文档目录占位，模块根没有 AndroidManifest）按 run config 排除或未发现。
- 社区 Feed 列表 / WebView 嵌入 / 内容安全 / 反馈机制：本批次代码内未见相关 production 实现，社区主页仍是占位 TextView，统一在 `pending-confirmation.md` 标 PENDING。
