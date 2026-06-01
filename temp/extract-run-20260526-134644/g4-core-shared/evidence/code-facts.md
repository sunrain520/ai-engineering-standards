---
doc_id: "app-client-android-g4-core-shared-code-facts"
title: "G4 跨域共享层 code-facts"
domain: "app-client"
sub_domain: "android"
batch_ids:
  - "app-client-android-core-ui-kit-p1"
  - "app-client-android-capability-web-jsbridge-p1"
  - "app-client-android-rn-bridge-p1"
  - "app-client-android-share-capability-p1"
  - "app-client-android-ad-sdk-pdp-p1"
run_id: "20260526-134644-app-client"
generation_profile: "phase1-selected-batch"
status: "draft"
last_reviewed: "2026-05-26"
---

# Code Facts（结构性事实）

> 项目根：`<project-root>/core`（只读）。下文所有路径以 `core/` 为根的相对路径标识，不含绝对路径。
> 本文档只记录可在源码中直接验证的"是什么"事实，不做规范化判断。

## EV-APP-CLIENT-G4-001 — 跨域共享层模块切分

`core/` 一级目录包含 3 类共享层 module：

- `core/core-ui-kit/`：通用 UI 控件、Dialog、Tab、刷新组件、扩展函数。
- `core/core-utils/`：纯工具类与扩展函数（EventBus 包装、字符串扩展）。
- `core/capability/`：分场景能力 module，包含 `share/`、`web/`、`react-native/`、`kaz-pdp/`、`updata-apk/`、`pager_reach/`。

各 module 通过独立 `build.gradle` 或 `build.gradle.kts` 声明依赖，App 和业务模块以 `implementation`/`api` 依赖这些 capability。

## EV-APP-CLIENT-G4-002 — core-ui-kit Hs 前缀命名规则

`core/core-ui-kit/src/main/java/com/hstong/core/uikit/` 下自定义复用控件统一使用 `Hs*` 前缀，例如：

- `tab/HsTabLayout.kt`
- `headerAndfoot/HsLoadingRefreshHeader.kt`、`HsStateRefreshFooter.kt`、`HsTextRefreshFooter.kt`
- `headerAndfoot/HsListRefreshPaginationHelper.kt`、`HsFooterAdapterWrapper.kt`

非 Hs 前缀的类型多为 base/abstract 基类（`BaseFragment`、`BaseLoadDataFragment`、`BasePageFragment`、`BasePageViewModel`、`CommonActivity`、`CommonDialogFragment`）或纯 utility/extension 文件（`ViewExt.kt`、`ClickExt.kt`、`UIExt.kt`、`StatusBarUtil.kt`、`NavigationBarUtil.kt`）。

## EV-APP-CLIENT-G4-003 — core-ui-kit 自定义 attr 命名前缀

`core/core-ui-kit/src/main/res/values/attrs.xml` 中 `HsTabLayout` 自定义属性统一使用 `hstb_` 前缀：

```
hstb_tabSpacing / hstb_tabViewLayout / hstb_tabTextViewId
hstb_tabHorizontalPadding / hstb_tabTextSize / hstb_tabSelectedTextSize
hstb_tabTextColor / hstb_tabSelectedTextColor / hstb_tabSelectedBold
```

`declare-styleable` 名称与 View 类名一致（`HsTabLayout`），属性名带模块缩写前缀以避免与 Android 原生属性冲突。

## EV-APP-CLIENT-G4-004 — core-ui-kit 资源切片与 Theme

`core/core-ui-kit/src/main/res/values/` 中 `colors.xml` 仅含 dialog 按钮基础色（`ts_dialog_*`），并按"主名 + `_night` 后缀"声明双主题色值：

```
ts_dialog_start_btn_text_color / ts_dialog_start_btn_text_color_night
ts_dialog_end_btn_text_color   / ts_dialog_end_btn_text_color_night
```

模块同时提供 `src/main/res-night/`，并在 `core/capability/react-native/build.gradle`、`core/capability/kaz-pdp/build.gradle`、`core/capability/web/build.gradle` 内显式合并：

```
res.srcDirs = ['src/main/res', 'src/main/res-night']
```

实际换肤实现引用 `skin.support.*`（见 `tab/HsTabLayout.kt`），表明 ui-kit 与第三方 SkinCompat 框架对接，不自建换肤主题。

## EV-APP-CLIENT-G4-005 — core-utils 边界

`core/core-utils/src/main/java/com/hstong/core/utils/` 当前仅包含 2 个扩展集合：

- `string/StringExt.kt`：`removeComma()`、`removeCommaAndPercentSign()`，纯字符串处理，无 Android Context 依赖。
- `evenbus/EventBusWrapper.kt`：基于 `org.greenrobot.eventbus` 的 `Any.registerBus()` / `Any.unregisterBus()` / `List<Any>.registerBus()` 等扩展。

模块只声明 `core-utils`，没有 logger、date 等自建工具，日志通过 `com.hstong.log.VLog`（外部 lib）使用。

## EV-APP-CLIENT-G4-006 — capability:web 模块当前只承接 ARouter 路由桥

`core/capability/web/src/main/java/com/hstong/core/capability/web/ui/CommonWebViewReachContainer.kt` 是当前 capability:web 唯一一个 Kotlin 文件，类型为：

- `class CommonWebViewReachContainer : Fragment()`，类体为空（`{}`）。
- 上方 `@Route(path = PlatformRouterTable.PATH_WEB_PAGE)` 与 `@Redirect(...)` 双重注解，`Redirect` 内嵌 JSON DSL 声明 `WebView` 重定向类型，并枚举 `url` / `params` / `__usehttp` 三个对外参数。
- 文档块明确 "实际打开 WebView 的动作在 PretreatmentServiceImpl 中拦截后完成"。

实际 WebView 实现位于 `submodules/web/web/src/main/java/com/hstong/web/bridge/WebViewConfigHandler.kt` 等 submodule（不在本组采集范围）。

## EV-APP-CLIENT-G4-007 — capability:react-native 包结构与桥接命名

`core/capability/react-native/src/main/java/com/hstong/core/reactnative/` 按职责分目录：

- `bridge/`：`NativeHsBridgeModule.kt`（`ReactContextBaseJavaModule`，`MODULE_NAME = "NativeHsBridge"`）、`RnBridgePackage.kt`（`ReactPackage`）、`RnBridgeResult.kt`、`RnReadableMapExt.kt`。
- `runtime/`：`RnRuntimeInitializer.kt`（`object`，`SoLoader.init` 与 `DefaultNewArchitectureEntryPoint.load()` 单例化）。
- `container/`：`RnContainerFragment.kt`、`RnContainerLauncher.kt`。
- `config/`：`RnBundleConfig.kt`（bundleName 正则 `^[A-Za-z0-9_-]+$`，统一推导 assets 路径 `rn/{bundleName}/index.android.bundle`）。
- `props/`、`event/`、`debug/`：分别承担初始化属性、事件通道、调试入口。

文件命名统一 `Rn*` 前缀；类名如 `RnContainerFragment`、`RnBridgePackage`。Bridge 模块名 `NativeHsBridge` 在 `companion object MODULE_NAME` 中常量化。

## EV-APP-CLIENT-G4-008 — RN Bridge 白名单 + 日志策略

`bridge/NativeHsBridgeModule.kt` 暴露 4 个 `@ReactMethod`：`canIUse`、`sensorsTrack`、`handleBusinessJsError`、`callNativeAbility`。`callNativeAbility` 使用 `when (ability)` 显式枚举支持的能力字符串：

```
ABILITY_PAGE_OPEN = "page.open"
ABILITY_AUTH_GET_LOGIN_STATUS = "auth.getLoginStatus"
ABILITY_PAGE_CLOSE = "page.close"
```

`else` 分支显式 `VLog.e(TAG, "... rejected, reason=unknownAbility, ability=$ability")` 并返回 `RnBridgeResult.failure()`。`readParams()` 仅记录 `paramKeys` 而非 `payload`：

```kotlin
VLog.i(TAG, "NativeHsBridge#$methodName called, paramKeys=${plainParams.keys}")
```

`buildJsErrorSummary()` 对 `message` 与 `source` 调用 `.take(JS_ERROR_MAX_LENGTH /* 200 */)`，限制日志长度。

## EV-APP-CLIENT-G4-009 — RN runtime 单次初始化

`runtime/RnRuntimeInitializer.kt`：

- `@Volatile private var isInitialized = false` + `synchronized(this)` 双检锁模式。
- 静态依赖清单 `createReactPackageList()` 列举 `AsyncStoragePackage / RNGestureHandlerPackage / ReanimatedPackage / WorkletsPackage / SafeAreaContextPackage / RNScreensPackage / SvgPackage / RNCWebViewPackage`。
- `ensureInitialized()` 调用 `SoLoader.init(appContext, OpenSourceMergedSoMapping)` 与 `DefaultNewArchitectureEntryPoint.load()`，并在前后输出 `VLog.i(TAG, "ensureInitialized start/success")`。

## EV-APP-CLIENT-G4-010 — RN Container Fragment 错误兜底

`container/RnContainerFragment.kt#onCreateView` 流程：

1. 校验 `RnBundleConfig.isValidBundleName(...)` 与 `componentName.isBlank()` 不通过 → 返回 `errorView("RN start config invalid")`。
2. `bundleCheck.exists` 为 false 且非 debug → 返回 `errorView("RN bundle missing")`。
3. RN runtime 创建失败 → 返回 `errorView("RN runtime unavailable")`。

`onDestroyView()` 清理顺序：`unregisterStateObservers → eventChannel.markDestroyed → reactSurface.stop/clear/detach → reactHost.onHostDestroy`。生命周期与 `onResume/onPause` 对齐 RN host：`reactHost?.onHostResume(requireActivity(), defaultBackHandler)`、`reactHost?.onHostPause(requireActivity())`。

## EV-APP-CLIENT-G4-011 — capability:share 模块当前为空脚手架

`core/capability/share/`：

- `build.gradle.kts` 声明 `namespace = "com.hstong.core.capability.share"`、`compileSdk = 35`、`minSdk = 24`、Java 11，仅依赖 `androidx.core:core-ktx / appcompat / material`。
- `src/main/AndroidManifest.xml` 仅含空 `<manifest>` 节点。
- `src/main/java/com/hstong/core/share/` 目录存在但无 `.kt` 源码；`androidTest/` 与 `test/` 各保留默认 `ExampleInstrumentedTest.kt` / `ExampleUnitTest.kt`。

模块只完成 namespace + 最小依赖骨架，尚无第三方分享 SDK 接入或对外 API。

## EV-APP-CLIENT-G4-012 — capability:kaz-pdp 模块结构

`core/capability/kaz-pdp/src/main/java/com/hstong/hs_ads/`：

- 顶层入口 `PdpCenter.kt`（`object`），方法 `prepareSplash(intent: Intent, forwardType: Int): Int`、`showPopupAd(adsType, ads, displayStyle, ...)`。
- `bean/AdDisplayStyle.kt`（枚举 `CENTER` / `BOTTOM`）；`AdsType.kt` 同级。
- `redirect/RedirectDispatcher.kt`（`object`，`dispatch(context, redirect, onDismiss)`）。
- `notification/PdpNotificationFragment.kt` + `PdpNotificationViewModel.kt`。
- `banner/PdpBannerFragment.kt` + `PdpBannerViewModel.kt` + `BannerStyle.kt`。
- `cache/ImageDownloader.kt`、`openaccount/AdviserServiceDialog.kt`、`PdpCenterPopupFragment.kt`、`PdpBottomPopupFragment.kt`。

依赖在 `build.gradle` 中：`Deps.Lib.common / router / hs_library / hscomponents / biz_kaz_app / kaz_resources`，并通过 `hs-maven-publish` 发布为 `com.kaz.pdp:kaz-pdp`。

## EV-APP-CLIENT-G4-013 — kaz-pdp 数据来源与跳转路径

`PdpCenter.prepareSplash` 通过 `LaunchAdService().getLaunchAd()`（KMP `com.hs.kmp.biz.securities.pdp.service.LaunchAdService`）获取 `KmpAdItem`，并使用 `kotlinx.serialization.json.Json.encodeToString(adItem)` 序列化到 Intent。

`RedirectDispatcher.dispatch` 仅在 `redirectType` 非空时调用 `Router.startRedirect(context, redirectType, redirectValue)`；否则 `Log.w` 并返回 `false`，统一通过项目 `Router` 入口分发。

`PdpCenterPopupFragment` 与 `PdpBannerFragment`：

- 通过 `BizPopupStack`（`PdpCenter#showPopupAd`）排队展示，避免覆盖业务弹窗。
- 点击通过 `RedirectDispatcher.dispatch` 而非自行启动 Activity。
- 提供 `attachTo(fragmentManager, containerId, positionCode, ...)` + `refresh(...)` 双入口，复用 Fragment 实例时基于 `positionCode / bannerStyle / ratio` 做幂等比较。

## EV-APP-CLIENT-G4-014 — kaz-pdp 埋点 placeholder

`PdpCenterPopupFragment.kt`：

```kotlin
private fun recordView(item: AdItem) {
    // TODO: 接入新埋点方案
}

private fun recordClick(item: AdItem) {
    // TODO: 接入新埋点方案
}
```

`PdpBannerFragment.kt` 的 `recordView/recordClick` 同样为 `// TODO`。`PdpCenter.prepareSplash` 仅通过 `VLog.d(TAG, ...)` 记录命中信息，使用 `imageUrl?.takeLast(40)` / `videoUrl?.takeLast(40)` 截断 URL 防止泄露完整资源路径。

## EV-APP-CLIENT-G4-015 — core-ui-kit 资源 res-night 双主题与 SkinCompat

`core/capability/react-native/build.gradle` 等多个 capability 模块均声明：

```
sourceSets {
    main {
        res.srcDirs = ['src/main/res', 'src/main/res-night']
    }
}
```

UI 控件代码通过 `skin.support.content.res.SkinCompatResources`、`skin.support.widget.SkinCompatBackgroundHelper`、`SkinCompatSupportable` 适配（见 `tab/HsTabLayout.kt`）。
