---
doc_id: "app-client-android-g4-core-shared-forbidden-examples"
title: "G4 跨域共享层 forbidden examples"
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

# Forbidden Examples（禁止做法）

> 以下"禁止做法"由本组源码中现有的 positive 模式反推得出：现有代码已经采用更安全的做法，再写出反向写法即为本规范禁止。

## NEG-APP-CLIENT-G4-001 — 反对：JS 直接接受任意 Native 能力字符串

**禁止做法**：

```kotlin
@ReactMethod
fun callNativeAbility(params: ReadableMap?, promise: Promise) {
    val ability = params?.getString("ability") ?: return
    val handler = AbilityRegistry.find(ability)  // 反射或动态查表
    handler?.invoke(params, promise)
}
```

或：在 `when` 分支里加入 `else -> { /* 透传到反射调用 */ }`、未注册 ability 默认 `RnBridgeResult.success()`。

**为何禁止**：
- 反射/动态分发让"暴露给 JS 的 Native 能力面"对 reviewer 不可见。
- 缺少 `else -> failure()` 等价于把任意字符串视为可执行能力，等同于在 RN/Web ↔ Native 之间开放泛能力面。
- 无 `reason=unknownAbility` 日志时，灰度时无法发现 JS 探测未实现能力。

**对照** `bridge/NativeHsBridgeModule.kt` `callNativeAbility` 的 `when` 显式枚举 + `else → VLog.e(reason=unknownAbility) → failure()`。

## NEG-APP-CLIENT-G4-002 — 反对：将完整 RN/JS payload 写入日志

**禁止做法**：

```kotlin
@ReactMethod
fun sensorsTrack(params: ReadableMap?, promise: Promise) {
    val plain = params?.toHashMap()
    VLog.i(TAG, "sensorsTrack params=$plain")  // 完整 payload 入日志
    SensorsTool.sensorsOnEventAttach(eventName, "", plain)
    promise.resolve(...)
}
```

或：将 `handleBusinessJsError` 的完整 stack/payload 直接 `VLog.e` 输出，不做 `take(JS_ERROR_MAX_LENGTH)` 截断。

**为何禁止**：
- 业务字段值常含 token、userId、订单号、symbol 等敏感字段。
- VLog 在线开启时易把整页 JSON 灌入日志后端。

**对照** `readParams` 只输出 `paramKeys`、`buildJsErrorSummary` 仅截 200 字符。

## NEG-APP-CLIENT-G4-003 — 反对：RN 容器接受外部传入完整 bundle 路径

**禁止做法**：

```kotlin
fun newInstance(bundlePath: String, componentName: String): RnContainerFragment {
    return RnContainerFragment().apply {
        arguments = bundleOf(
            "bundlePath" to bundlePath,         // 调用方任意传入
            "componentName" to componentName
        )
    }
}
// 或：assetExists 失败时 fallback 到 file://、http:// 加载远程 bundle
```

**为何禁止**：
- 任意路径让攻击者可以构造 `../../../sdcard/...` 触发 path traversal。
- 远程 bundle 加载属于动态代码执行入口，超出公共容器允许范围。

**对照** `RnBundleConfig`：仅接受 `bundleName`，正则 `^[A-Za-z0-9_-]+$`，统一推导 `rn/{bundleName}/index.android.bundle`，仅 assets 校验存在性。

## NEG-APP-CLIENT-G4-004 — 反对：WebView 容器开启文件域访问 / 跨源 JS 注入

**禁止做法**（在新增 WebView 实现时）：

```kotlin
webView.settings.apply {
    javaScriptEnabled = true
    allowFileAccess = true                  // [FORBIDDEN]
    allowFileAccessFromFileURLs = true      // [FORBIDDEN]
    allowUniversalAccessFromFileURLs = true // [FORBIDDEN]
    mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW // [FORBIDDEN]
}
webView.addJavascriptInterface(JsBridge(), "kazNative") // 未做来源域校验 [FORBIDDEN]
```

**为何禁止**：
- `allowFileAccessFromFileURLs` / `allowUniversalAccessFromFileURLs` 自 Android 4.1 起即被多次披露用于 file:// XSS。
- `MIXED_CONTENT_ALWAYS_ALLOW` 让 https 页面可加载 http 子资源，破坏传输完整性。
- 通过 `addJavascriptInterface` 注入 Bridge 时若不做 origin/url 白名单，第三方页面可调用 Native 能力。
- 现 capability:web 仅承载路由壳，未来真实实现位于 `submodules/web` 时仍须遵守此红线。

**对照** `CommonWebViewReachContainer.kt` 类体仅作为路由桥；`PretreatmentServiceImpl` 拦截后才打开 WebView，因此规则应在落地点强制执行。

## NEG-APP-CLIENT-G4-005 — 反对：广告/JS Bridge 直接 startActivity 跳过 Router

**禁止做法**：

```kotlin
private fun handleClick(item: AdItem) {
    val url = item.redirect?.value
    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
    requireContext().startActivity(intent)  // 跳过 Router 与跳转白名单
}
```

或：JS Bridge 在 `callNativeAbility` 中接受任意 url 直接 `startActivity`。

**为何禁止**：
- Router 内置类型分发与跳转白名单；绕过后 deep link、auth check、push tracking 都失效。
- 广告 SDK / RN 都必须共用同一跳转链路，便于灰度切换跳转策略。

**对照** `RedirectDispatcher.dispatch` 始终 `Router.startRedirect(...)`；`NativeHsBridgeModule.openPageByRedirect` 也只接 `redirectType + redirectValue` 经 `Router.startRedirect`。

## NEG-APP-CLIENT-G4-006 — 反对：在 capability:kaz-pdp 内自建埋点字段

**禁止做法**：

```kotlin
private fun recordView(item: AdItem) {
    val map = mutableMapOf<String, Any?>(
        "imageUrl" to item.imageUrl,
        "videoUrl" to item.videoUrl,
        "userId" to UserCenter.userId,        // 私自带入 PII
        "redirectValue" to item.redirect?.value
    )
    SensorsTool.sensorsOnEventAttach("ad_view", "", map)
}
```

**为何禁止**：
- 当前 `recordView/recordClick` 是 `// TODO: 接入新埋点方案`，新方案未定型；私自接入会让埋点字段在 SDK 与新埋点方案之间产生分叉。
- 直接把 imageUrl/videoUrl 上报会复制完整 CDN 路径，造成 PII 风险（参考 `prepareSplash` 的 `takeLast(40)` 截断习惯）。
- 用户身份字段应由统一埋点中台注入，SDK 不应私写 `userId`。

**对照** `PdpCenterPopupFragment.recordView/recordClick` 显式留 TODO 等待新方案；`PdpCenter.prepareSplash` 日志只 `takeLast(40)`。

## NEG-APP-CLIENT-G4-007 — 反对：capability 模块直接依赖业务 module

**禁止做法**：在 `core/capability/*` 任意子模块的 `build.gradle` 中：

```groovy
dependencies {
    implementation project(':app-quote')         // [FORBIDDEN]
    implementation project(':submodules:trade')  // [FORBIDDEN]
}
```

**为何禁止**：
- capability 是供业务侧依赖的下游通用层；反向依赖业务 module 会导致循环依赖、构建顺序错乱、AAR 公开发布失败。
- 现有 `kaz-pdp` 仅依赖 `Deps.Lib.common / router / hs_library / hscomponents / biz_kaz_app / kaz_resources`；`react-native` 仅依赖 RN 与共享 lib；`share` 仅依赖 androidx 基础库。

**对照** `core/capability/kaz-pdp/build.gradle`、`core/capability/share/build.gradle.kts`：依赖均为 lib/SDK，未引入业务 module。

## NEG-APP-CLIENT-G4-008 — 反对：在 RN runtime 单例外部直接调用 SoLoader.init

**禁止做法**：

```kotlin
class SomeContainer : Fragment() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        SoLoader.init(requireContext().applicationContext, /* ... */)  // [FORBIDDEN]
        DefaultNewArchitectureEntryPoint.load()
    }
}
```

**为何禁止**：
- `SoLoader.init` 重复执行可能导致 native crash 或 prefab so 重复加载。
- RN runtime 必须单一来源；分散调用使初始化顺序与依赖清单（`createReactPackageList`）出现分叉。

**对照** `RnRuntimeInitializer.ensureInitialized` 双检锁单例。
