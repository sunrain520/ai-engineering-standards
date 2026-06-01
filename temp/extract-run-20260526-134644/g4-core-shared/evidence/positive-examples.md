---
doc_id: "app-client-android-g4-core-shared-positive-examples"
title: "G4 跨域共享层 positive examples"
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

# Positive Examples（推荐做法）

## POS-APP-CLIENT-G4-001 — RN 能力白名单 + 显式 reject 日志

**模式**：RN Bridge 把"开放给 JS 的 Native 能力"集中维护成一组 `const ABILITY_*`，并在分发处使用 `when (ability)` 显式枚举，`else` 分支输出结构化日志后返回 `failure()`。

**示例**（`bridge/NativeHsBridgeModule.kt`）：

```kotlin
@ReactMethod
fun callNativeAbility(params: ReadableMap?, promise: Promise) {
    val plainParams = readParams(METHOD_CALL_NATIVE_ABILITY, params)
    val ability = plainParams["ability"]?.toString()
    val abilityParams = plainParams.getMapOrNull("params")
    val result = when (ability) {
        ABILITY_PAGE_OPEN -> openPageByRedirect(abilityParams)
        ABILITY_AUTH_GET_LOGIN_STATUS -> {
            RnBridgeResult.success(mapOf(DATA_IS_LOGGED_IN to HSLoginStatus.hasLogin()))
        }
        ABILITY_PAGE_CLOSE -> closeCurrentPage()
        else -> {
            VLog.e(
                TAG,
                "NativeHsBridge#$METHOD_CALL_NATIVE_ABILITY rejected, reason=unknownAbility, ability=$ability"
            )
            RnBridgeResult.failure()
        }
    }
    promise.resolve(RnReadableMapExt.resultToWritableMap(result))
}
```

**有效性**：
- 新增能力必须改 ability 常量 + when 分支，避免悄悄扩展暴露面。
- `reason=unknownAbility, ability=$ability` 让线上日志可直接定位试探调用。
- `RnBridgeResult.failure()` 统一返回结构，JS 侧不需要区分"未实现"和"调用失败"。

## POS-APP-CLIENT-G4-002 — Bridge 调用日志只记 keys，不记 payload

**模式**：所有 RN Bridge `@ReactMethod` 入口先经过 `readParams(methodName, params)`，统一打印调用动作和 `paramKeys`，避免业务字段值进入日志。

**示例**：

```kotlin
private fun readParams(methodName: String, params: ReadableMap?): Map<String, Any?> {
    val plainParams = RnReadableMapExt.toPlainMap(params)
    VLog.i(TAG, "NativeHsBridge#$methodName called, paramKeys=${plainParams.keys}")
    return plainParams
}
```

**有效性**：
- 调用链可追溯（方法名 + 时间戳）。
- `paramKeys` 只暴露字段名，不会把 PII / token / 业务 payload 写进日志。
- 任何新增 ReactMethod 只要遵循"先 `readParams` 再处理"模式即可继承该日志策略。

## POS-APP-CLIENT-G4-003 — JS 错误摘要长度限制

**模式**：RN 侧上抛业务 JS 错误时，Native 只取 `message` / `source` 两个低敏字段并 `take(JS_ERROR_MAX_LENGTH)` 截断，避免完整 stack 落库。

**示例**：

```kotlin
private const val JS_ERROR_MAX_LENGTH = 200

internal fun buildJsErrorSummary(params: Map<String, Any?>?): JsErrorSummary {
    val message = params?.get("message")?.toString()
        ?.takeIf { it.isNotBlank() }
        ?.take(JS_ERROR_MAX_LENGTH)
        ?: JS_ERROR_DEFAULT_MESSAGE
    val source = params?.get("source")?.toString()
        ?.takeIf { it.isNotBlank() }
        ?.take(JS_ERROR_MAX_LENGTH)
        .orEmpty()
    return JsErrorSummary(message = message, source = source)
}
```

**有效性**：
- 防止 JS payload 爆量写入 VLog。
- 仅暴露 message/source，能定位问题但不带业务上下文。

## POS-APP-CLIENT-G4-004 — RN bundleName 校验 + assets 路径协议化

**模式**：公共容器不接受外部传入完整 bundle 路径，仅接受 `bundleName`，由 `RnBundleConfig` 用正则限制集合，并统一推导 assets 相对路径。

**示例**（`config/RnBundleConfig.kt`）：

```kotlin
private const val ANDROID_ASSET_PREFIX = "rn"
private val bundleNamePattern = Regex("^[A-Za-z0-9_-]+$")

fun isValidBundleName(bundleName: String): Boolean =
    bundleName.isNotBlank() && bundleNamePattern.matches(bundleName)

fun androidBundlePath(bundleName: String): String {
    require(isValidBundleName(bundleName)) { "Illegal RN bundleName: $bundleName" }
    return "$ANDROID_ASSET_PREFIX/$bundleName/index.android.bundle"
}
```

**有效性**：
- 切断 path traversal：`../`、绝对路径、含特殊符号的名字直接 `require` 抛异常。
- 容器侧只关心存在性 (`assetExists`)，不读取 bundle 字节。

## POS-APP-CLIENT-G4-005 — RN runtime 双检锁初始化

**模式**：RN 0.84 New Architecture 在宿主进程内只初始化一次，使用 `@Volatile` + `synchronized` 双检锁，并在前后输出明确日志。

**示例**（`runtime/RnRuntimeInitializer.kt`）：

```kotlin
@Volatile
private var isInitialized = false

fun ensureInitialized(context: Context) {
    if (isInitialized) return
    synchronized(this) {
        if (isInitialized) return
        val appContext = context.applicationContext
        VLog.i(TAG, "ensureInitialized start")
        SoLoader.init(appContext, OpenSourceMergedSoMapping)
        DefaultNewArchitectureEntryPoint.load()
        isInitialized = true
        VLog.i(TAG, "ensureInitialized success")
    }
}
```

**有效性**：
- 多入口（Application、Container Fragment）同时调用时不重复初始化 SoLoader。
- 单测/线程并发不会进入二次初始化引发 native crash。

## POS-APP-CLIENT-G4-006 — RN Container 错误兜底视图

**模式**：容器在配置不合法、bundle 缺失、runtime 不可用三种情形下，分别返回 `errorView("...")`，不创建 RN 实例，避免空 surface 和后续 NPE。

**示例**（`container/RnContainerFragment.kt`）：

```kotlin
if (!config.isValid()) {
    VLog.e(TAG, "RN start config invalid: ...")
    return errorView("RN start config invalid")
}
if (!bundleCheck.exists && !isDebugBuild) {
    return errorView("RN bundle missing")
}
val rnView = createReactSurfaceView(...)
return rnView ?: errorView("RN runtime unavailable")
```

**有效性**：
- 失败路径都有可见 UI + 结构化日志，避免白屏定位困难。
- debug 构建仍允许进入，方便本地连 metro dev server。

## POS-APP-CLIENT-G4-007 — Hs 前缀 + hstb_ 自定义 attr

**模式**：core-ui-kit 自定义 View 类名统一 `Hs*` 前缀，配套自定义 attr 用模块缩写前缀（`HsTabLayout` → `hstb_*`），`declare-styleable` 名称与类名一致。

**示例**（`res/values/attrs.xml`）：

```xml
<attr name="hstb_tabSelectedTextColor" format="color" />
<attr name="hstb_tabSelectedBold" format="boolean" />

<declare-styleable name="HsTabLayout">
    <attr name="hstb_tabSpacing" />
    <attr name="hstb_tabSelectedTextSize" />
    ...
</declare-styleable>
```

**有效性**：
- Hs 前缀让 IDE 中"项目自定义 View"和原生/三方 View 易于区分。
- `hstb_` 前缀避免与 Android `app:tab*` 内置属性冲突，便于换肤时定位项目自有属性。

## POS-APP-CLIENT-G4-008 — 资源双主题：res + res-night

**模式**：colors 等资源采用"主名 + `_night` 后缀"命名 + 显式 `res.srcDirs = ['src/main/res', 'src/main/res-night']`，与 SkinCompat 框架对接。

**示例**：

```xml
<!-- core-ui-kit/src/main/res/values/colors.xml -->
<color name="ts_dialog_end_btn_text_color">#FF6600</color>
<color name="ts_dialog_end_btn_text_color_night">#FF6600</color>
```

```groovy
// core/capability/kaz-pdp/build.gradle 等
sourceSets {
    main {
        res.srcDirs = ['src/main/res', 'src/main/res-night']
    }
}
```

**有效性**：
- 一处主名定义即可触发 SkinCompat 的日/夜模式切换。
- 不必为每个资源单独维护 `values-night/`，目录拓扑保持单一来源。

## POS-APP-CLIENT-G4-009 — capability:kaz-pdp 通过 RedirectDispatcher 统一跳转

**模式**：广告点击跳转、Banner 跳转、通知条跳转都不直接 `startActivity`，而是经 `RedirectDispatcher.dispatch(...)` → `Router.startRedirect(...)`，使广告 SDK 与项目路由收口。

**示例**（`redirect/RedirectDispatcher.kt`）：

```kotlin
fun dispatch(
    context: Context,
    redirect: RedirectConfig?,
    onDismiss: (() -> Unit)? = null
): Boolean {
    if (redirect == null) {
        Log.w(TAG, "redirect 为 null，无法分发")
        return false
    }
    val redirectType = redirect.type
    val redirectValue = redirect.value
    return when {
        !redirectType.isNullOrBlank() -> {
            VLog.d(TAG, "dispatch: type=$redirectType, value=$redirectValue")
            Router.startRedirect(context, redirectType, redirectValue)
            onDismiss?.invoke()
            true
        }
        else -> {
            Log.w(TAG, "未知的落地页类型: redirect=$redirect")
            false
        }
    }
}
```

**有效性**：
- 广告 SDK 与业务 Activity 解耦，跳转规则由 Router 集中维护。
- 失败有日志，调用方拿到 boolean 可以决定是否继续 dismiss。

## POS-APP-CLIENT-G4-010 — kaz-pdp Fragment 幂等 attach + 显式 positionCode

**模式**：广告/通知/Banner Fragment 使用 `attachTo(fragmentManager, containerId, positionCode, ...)` + `refresh(...)` 双入口，`attachTo` 时根据 `positionCode + style + ratio` 幂等判断是否复用现有 Fragment。

**示例**（`banner/PdpBannerFragment.kt`）：

```kotlin
fun attachTo(
    fragmentManager: FragmentManager,
    containerId: Int,
    positionCode: String,
    bannerStyle: BannerStyle = BannerStyle.LARGE,
    ratio: Float? = null
) {
    val current = fragmentManager.findFragmentById(containerId)
    if (current is PdpBannerFragment &&
        current.arguments?.getString(ARG_POSITION_CODE) == positionCode &&
        current.arguments?.getString(ARG_BANNER_SIZE) == bannerStyle.name &&
        current.arguments?.getFloat(ARG_BANNER_RATIO, -1f) == (ratio ?: -1f)
    ) {
        return
    }
    fragmentManager.beginTransaction()
        .replace(containerId, newInstance(positionCode, bannerStyle, ratio))
        .commitAllowingStateLoss()
}
```

**有效性**：
- 宿主重复 `attachTo` 不会触发 replace 闪动。
- 广告位 `positionCode` 由宿主显式提供，使 SDK 与广告位语义解耦。

## POS-APP-CLIENT-G4-011 — 广告日志 URL 截断

**模式**：`PdpCenter.prepareSplash` 写日志时只取 URL 末尾片段（`takeLast(40)`），避免完整资源 URL 写入日志。

**示例**：

```kotlin
VLog.d(TAG, "prepareSplash() 广告命中：id=${adItem.id}, title=${adItem.title}" +
        ", imageUrl=${adItem.imageUrl?.takeLast(40)}" +
        ", videoUrl=${adItem.videoUrl?.takeLast(40)}" +
        ", skipSeconds=${adItem.skipSeconds}")
```

**有效性**：
- 在线日志能区分 URL，又不泄露完整 CDN 路径或 query 参数。
