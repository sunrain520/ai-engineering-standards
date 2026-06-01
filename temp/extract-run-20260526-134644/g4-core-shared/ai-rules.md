---
doc_id: "app-client-android-g4-core-shared-ai-rules"
title: "G4 跨域共享层 AI 生成规则"
domain: "app-client"
sub_domain: "android"
parent_standard: "app-client-android-core-shared-standard"
status: "draft"
last_reviewed: "2026-05-26"
generation_profile: "phase1-selected-batch"
---

# AI 生成规则（跨域共享层）

> 用于驱动 AI 在 `core/` 系列模块下生成代码时的 prompt-level guard。每条规则带 `rule_id` 与 `evidence_ref`。

## A. core-ui-kit

### AI-G4-UIKIT-001 — 自定义 View 命名

- 生成"业务可在 layout 复用"的自定义 View 时，类名必须 `Hs` 前缀（`HsXxxLayout` / `HsXxxView`）。
- 生成 base/abstract 容器（Fragment / Activity / ViewModel）时使用 `Base*` 或 `Common*`，不加 `Hs` 前缀。
- 不要为已有 `Base*` / `Common*` 类型重新生成等价"Hs 版"。
- evidence_ref: EV-APP-CLIENT-G4-002, LEG-APP-CLIENT-G4-005

### AI-G4-UIKIT-002 — 自定义 attr

- 生成自定义 View 配套 attr 时：
  - `<attr>` 名称必须以"模块缩写_"开头（`HsTabLayout` → `hstb_*`）。
  - 必须在 `attrs.xml` 显式声明 `format`。
  - 必须配套 `<declare-styleable name="<ClassName>">` 引用所有 attr。
- evidence_ref: EV-APP-CLIENT-G4-003, POS-APP-CLIENT-G4-007

### AI-G4-UIKIT-003 — 颜色 / 主题资源

- 生成 colors.xml 颜色项时，若该色需要换肤：必须同时定义 `<color name="xxx">` 和 `<color name="xxx_night">`。
- 不要生成 `values-night/` 单目录配色；按"主名 + `_night`"双名规范走。
- 生成新模块 `build.gradle` 时，若该模块需要换肤，写入：

  ```groovy
  sourceSets {
      main {
          res.srcDirs = ['src/main/res', 'src/main/res-night']
      }
  }
  ```
- evidence_ref: EV-APP-CLIENT-G4-004, EV-APP-CLIENT-G4-015

## B. core-utils

### AI-G4-UTILS-001 — 工具边界

- 生成放进 `core/core-utils/` 的扩展时：
  - 接收者只能是 Kotlin 内置类型 / `java.*` / 三方纯库（如 `EventBus`）。
  - 不能直接 import `androidx.fragment.app.*` / `android.view.*` / `android.app.Activity`。
- 涉及 View / Activity 的扩展放到 `core-ui-kit/viewext/`。
- evidence_ref: EV-APP-CLIENT-G4-005

### AI-G4-UTILS-002 — 日志使用

- 生成日志语句必须使用 `com.hstong.log.VLog`：

  ```kotlin
  import com.hstong.log.VLog
  private const val TAG = "<ModuleName>"
  VLog.i(TAG, "<action>, paramKeys=...")
  VLog.e(TAG, "<action> rejected, reason=...")
  ```
- 禁止 `import android.util.Log` 写业务日志。
- TAG 必须是 `private const val`，不允许运行时拼接。
- evidence_ref: EV-APP-CLIENT-G4-008, EV-APP-CLIENT-G4-009

## C. capability:web / JS Bridge

### AI-G4-WEB-001 — WebView 安全基线（FORBIDDEN）

- 生成 `WebSettings` 配置时**必须**满足：
  - 显式 `allowFileAccess = false` 或不设置，禁止 `= true`。
  - 显式 `allowFileAccessFromFileURLs = false`、`allowUniversalAccessFromFileURLs = false`，禁止 `= true`。
  - `mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW` 或 `COMPATIBILITY_MODE`，禁止 `MIXED_CONTENT_ALWAYS_ALLOW`。
- evidence_ref: NEG-APP-CLIENT-G4-004

### AI-G4-WEB-002 — 不要静默信任 SSL（FORBIDDEN）

- 不要生成 `WebViewClient.onReceivedSslError { handler.proceed() }` 类型代码。
- 不要生成"信任所有证书 / 跳过 hostname 校验"的 OkHttp / X509TrustManager 代码。
- evidence_ref: NEG-APP-CLIENT-G4-004

### AI-G4-WEB-003 — JS Bridge 暴露面

- 生成新 JS Bridge 方法时：
  - 类显式 `addJavascriptInterface(this, "<name>")` 后必须有 origin 白名单校验逻辑（在 `WebViewClient` 中检查 `request.url.host` 在白名单）。
  - 方法集合显式枚举（`when(name)` / `if-else`），不使用反射。
  - 方法入参日志只输出 `paramKeys=...`，不输出 `params=...`。
  - 跳转 / 打开页面必须 `Router.startRedirect(...)`，禁止直接 `startActivity(Intent.ACTION_VIEW, ...)`。
- evidence_ref: POS-APP-CLIENT-G4-001, POS-APP-CLIENT-G4-002, NEG-APP-CLIENT-G4-005

### AI-G4-WEB-004 — 路由桥协议字段

- 生成新 WebView 入口时复用 `PlatformRouterTable.PATH_WEB_PAGE` / `REDIRECTTYPE_WEB_PAGE`；对外只读 `url` / `params` / `__usehttp` 三个字段，不要扩展 freeform key。
- evidence_ref: EV-APP-CLIENT-G4-006

## D. capability:react-native

### AI-G4-RN-001 — runtime 单例

- 生成 RN 初始化代码时必须使用 `RnRuntimeInitializer.ensureInitialized(context)`，不要直接 `SoLoader.init(...)` 或 `DefaultNewArchitectureEntryPoint.load()`。
- 不要新增"分模块 RN runtime initializer"。
- evidence_ref: POS-APP-CLIENT-G4-005, NEG-APP-CLIENT-G4-008

### AI-G4-RN-002 — bundle 路径协议

- 生成 RN 容器入口时只接受 `bundleName / componentName / pageProps`；bundle 路径走 `RnBundleConfig.androidBundlePath(bundleName)`。
- 生成的代码必须先调用 `RnBundleConfig.isValidBundleName(bundleName)`；非法时返回 `errorView("RN start config invalid")`。
- 非 debug 构建 + `assetExists == false` → 返回 `errorView("RN bundle missing")`。
- 不要生成支持 `file://` / `http://` / `https://` 远程 bundle 的 fallback 代码。
- evidence_ref: POS-APP-CLIENT-G4-004, POS-APP-CLIENT-G4-006, NEG-APP-CLIENT-G4-003

### AI-G4-RN-003 — Bridge 模块模板

- 生成新 RN Bridge 模块时使用以下骨架：

  ```kotlin
  class NativeXxxBridgeModule(
      reactContext: ReactApplicationContext
  ) : ReactContextBaseJavaModule(reactContext) {

      override fun getName(): String = MODULE_NAME

      @ReactMethod
      fun someMethod(params: ReadableMap?, promise: Promise) {
          val plainParams = readParams(METHOD_SOME, params)
          // 1) 校验入参
          // 2) 执行（白名单分发，禁止反射）
          // 3) promise.resolve(RnReadableMapExt.resultToWritableMap(result))
      }

      private fun readParams(methodName: String, params: ReadableMap?): Map<String, Any?> {
          val plain = RnReadableMapExt.toPlainMap(params)
          VLog.i(TAG, "$MODULE_NAME#$methodName called, paramKeys=${plain.keys}")
          return plain
      }

      companion object {
          private const val TAG = "NativeXxxBridgeModule"
          const val MODULE_NAME = "NativeXxx"
          const val METHOD_SOME = "someMethod"
      }
  }
  ```
- 模块必须由对应 `RnXxxBridgePackage : ReactPackage` 注册到 `createNativeModules`；不在 `RnBridgePackage` 之外私自挂载 ViewManager。
- evidence_ref: EV-APP-CLIENT-G4-007, EV-APP-CLIENT-G4-008

### AI-G4-RN-004 — callNativeAbility 白名单

- 生成新增 `ability` 字符串支持时必须：
  1. 在 `companion object` 中新增 `const val ABILITY_<NAME> = "..."`。
  2. 在 `callNativeAbility` 的 `when (ability)` 中加分支。
  3. 保留 `else -> { VLog.e(TAG, "... rejected, reason=unknownAbility, ability=$ability"); RnBridgeResult.failure() }`。
- 不要用 `AbilityRegistry.find(ability)` / 反射 / Map 注册表替换显式 when。
- evidence_ref: POS-APP-CLIENT-G4-001, NEG-APP-CLIENT-G4-001

### AI-G4-RN-005 — 跳转

- RN Bridge 中 `page.open` 类能力必须最终调用 `Router.startRedirect(activity, redirectType, redirectValueJson)`；不要 `startActivity(Intent.ACTION_VIEW, Uri.parse(...))`。
- `redirectValue` 必须经 `redirectValueToJson(...)`（`FastJsonTool.toJSONString`）转 JSON 字符串后透传，不要传未 escape 字符串。
- evidence_ref: EV-APP-CLIENT-G4-008

### AI-G4-RN-006 — 错误日志限长

- 生成 JS 错误 / 业务错误日志摘要必须：
  - 仅取 `message` / `source` 字段。
  - 各字段 `take(JS_ERROR_MAX_LENGTH /* 200 */)` 截断。
  - 不输出完整 stack / payload。
- evidence_ref: POS-APP-CLIENT-G4-003

## E. capability:share

### AI-G4-SHARE-001 — 第三方分享 SDK 接入（pending）

- 在 `core/capability/share` 接入第三方 SDK 之前，AI 不得在其它模块自实现微信 / FB / Twitter 分享。
- 接入时必须：
  - SDK 凭据（AppKey/AppSecret）放 `BuildConfig` 或 secrets，不得硬编码源码。
  - 业务侧只看到 `ShareCenter.share(target: ShareTarget, payload: SharePayload)` 类抽象。
- evidence_ref: EV-APP-CLIENT-G4-011, LEG-APP-CLIENT-G4-002

## F. capability:kaz-pdp

### AI-G4-PDP-001 — 入口收口

- 生成广告展示代码时必须使用：
  - `PdpCenter.prepareSplash(intent, forwardType)` 处理开屏。
  - `PdpCenter.showPopupAd(...)` 处理弹窗广告。
  - `PdpBannerFragment.attachTo(fm, containerId, positionCode, ...)` 接入 Banner。
  - `PdpNotificationFragment.attachTo(fm, containerId, positionCode)` 接入通知条。
- 不要在业务模块直接 `BizPopupStack.addPopupDialog(BIZ_ADVERTISING, ...)` 接入广告 Fragment。
- evidence_ref: POS-APP-CLIENT-G4-010

### AI-G4-PDP-002 — Fragment attach 幂等

- 生成 `attachTo` 类方法必须包含：
  - `findFragmentById(containerId)` 与"复用判断"逻辑。
  - 比较关键参数（`positionCode` + `style` + `ratio` 等）；匹配时直接 `return`。
  - 不匹配时使用 `commitAllowingStateLoss()` replace。
- evidence_ref: POS-APP-CLIENT-G4-010

### AI-G4-PDP-003 — 跳转链路

- 广告 / Banner / 通知条点击逻辑必须调用 `RedirectDispatcher.dispatch(context, redirect, onDismiss)`。
- 不要生成 `Intent(Intent.ACTION_VIEW, Uri.parse(item.url))` 类直跳代码。
- evidence_ref: POS-APP-CLIENT-G4-009, NEG-APP-CLIENT-G4-005

### AI-G4-PDP-004 — 日志 / 埋点 PII

- 在 SDK 内部输出 URL 时使用 `imageUrl?.takeLast(40)` / `videoUrl?.takeLast(40)` 截断。
- 不要在 SDK 中生成 `userId / phone / email` 等 PII 字段写入埋点 / 日志。
- 在 `recordView/recordClick` 留 `// TODO: 接入新埋点方案`，不要私自 `SensorsTool.sensorsOnEventAttach(...)`。
- evidence_ref: POS-APP-CLIENT-G4-011, NEG-APP-CLIENT-G4-006, LEG-APP-CLIENT-G4-004

### AI-G4-PDP-005 — 数据来源

- 广告数据从 `LaunchAdService` / `AdService`（KMP）读取；不要在 SDK 内自发 HTTP。
- 序列化使用 `kotlinx.serialization.json.Json.encodeToString(...)`。
- evidence_ref: EV-APP-CLIENT-G4-013

## G. 共通

### AI-G4-COMMON-001 — capability 不反向依赖业务

- 生成 `core/capability/*/build.gradle` 依赖块时不得包含：
  - `implementation project(':app-*')`
  - `implementation project(':submodules:trade')` 等业务 module。
- 仅允许依赖 `Deps.Lib.* / Deps.Business.* / androidx / 三方 SDK`。
- evidence_ref: NEG-APP-CLIENT-G4-007
