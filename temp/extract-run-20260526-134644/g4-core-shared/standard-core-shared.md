---
doc_id: "app-client-android-core-shared-standard"
title: "App-Client Android 跨域共享层（core/capability）开发规范"
domain: "app-client"
sub_domain: "android"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "app-client-android-core-ui-kit-p1, app-client-android-capability-web-jsbridge-p1, app-client-android-rn-bridge-p1, app-client-android-share-capability-p1, app-client-android-ad-sdk-pdp-p1"
evidence_tier: "single-project"
last_reviewed: "2026-05-26"
generation_profile: "phase1-selected-batch"
tags: ["app-client", "android", "core", "capability"]
---

# App-Client Android 跨域共享层（core/capability）开发规范

> 本规范覆盖 `core/core-ui-kit`、`core/core-utils`、`core/capability/share`、`core/capability/web`、`core/capability/react-native`、`core/capability/kaz-pdp` 共 6 个跨域共享层 module。规则均带 `evidence_ref` 指向 `evidence/*.md` 中对应条目；evidence 不足的章节明确标注 `pending`。

## 1. 技术栈与工程约束

- 构建工具：Gradle，capability 模块按业务诉求采用 Groovy DSL（`build.gradle`）或 Kotlin DSL（`build.gradle.kts`）。
- compileSdk / targetSdk：业务 capability 取 `rootProject.compileSdkVersion`；占位 module（share）暂取 `compileSdk = 35`、`minSdk = 24`，详见 LEG-APP-CLIENT-G4-007。
- Java 目标：业务 capability 默认 Java 17（`react-native`、`web`、`kaz-pdp`）；share 占位 module 暂为 Java 11。
- 包名规则：`com.hstong.core.<scope>` 系列，如 `com.hstong.core.uikit`、`com.hstong.core.utils`、`com.hstong.core.reactnative`、`com.hstong.core.capability.web`、`com.hstong.core.capability.share`；广告 SDK 使用 `com.hstong.hs_ads`。
- 日志：统一使用 `com.hstong.log.VLog`；日志格式见 §4 与 §5；详见 EV-APP-CLIENT-G4-008、LEG-APP-CLIENT-G4-001。
- 资源换肤：通过 `skin.support.*` 与 `res-night/` 双目录承载，`build.gradle` 内显式声明 `res.srcDirs = ['src/main/res', 'src/main/res-night']`，详见 EV-APP-CLIENT-G4-015、LEG-APP-CLIENT-G4-006。

## 2. 跨域共享层全景图（core 三层）

```
core/
├── core-ui-kit/         # UI 控件、基础 Activity/Fragment、扩展函数、Theme/资源
├── core-utils/          # 纯工具与扩展（无 Android Context 强依赖）
└── capability/
    ├── share/           # 第三方分享能力（占位脚手架，详见 LEG-APP-CLIENT-G4-002）
    ├── web/             # WebView 路由桥（实际实现仍在 submodules/web，详见 LEG-APP-CLIENT-G4-003）
    ├── react-native/    # RN 0.84 New Architecture 容器与 Bridge
    ├── kaz-pdp/         # 广告/PDP/Banner/通知条 SDK
    ├── updata-apk/      # APK 更新（本组未采集）
    └── pager_reach/     # 全量页面触达（本组未采集，excluded）
```

依赖方向约束：业务模块依赖 capability，capability 依赖 core-utils / 三方 lib，**capability 禁止反向依赖业务 module**（详见 §10 NEG-APP-CLIENT-G4-007）。

## 3. core-ui-kit 规范

### 3.1 自定义 View 命名前缀【强制】

- **规则**：core-ui-kit 中"用户可见、可在业务 layout 复用"的自定义 View / 控件类必须使用 `Hs*` 前缀；抽象基类沿用 `Base*` / `Common*`。
- **背景**：`HsTabLayout` / `HsLoadingRefreshHeader` 等已成习惯（EV-APP-CLIENT-G4-002）；`BaseFragment` / `CommonDialogFragment` 等表示"模板/容器"语义。
- **rule_id**: G4-UIKIT-001
- **enforcement**: required
- **rationale**: 让 layout xml 中"项目自定义控件"与原生/三方控件可一眼区分。
- **evidence_ref**: EV-APP-CLIENT-G4-002, LEG-APP-CLIENT-G4-005

### 3.2 自定义 attr 与 declare-styleable【强制】

- **规则**：自定义 View 配套的 attr 必须以"模块缩写_"作为前缀（例如 `HsTabLayout` → `hstb_*`）；`declare-styleable` 名称必须与 View 类名一致；attr 必须在 `attrs.xml` 显式 `<attr name=... format=... />`。
- **rule_id**: G4-UIKIT-002
- **enforcement**: required
- **rationale**: 防止与 Android 原生 `tab*` 等属性冲突，便于 SkinCompat 在 `applySkin` 时按属性名扫描。
- **evidence_ref**: EV-APP-CLIENT-G4-003, POS-APP-CLIENT-G4-007

### 3.3 资源命名与日/夜双主题【强制】

- **规则**：颜色等资源采用"主名 + `_night` 后缀"双名定义；module `build.gradle` 显式声明 `res.srcDirs = ['src/main/res', 'src/main/res-night']`；日/夜模式切换走 `skin.support.*`，禁止自建 Theme 切换体系。
- **rule_id**: G4-UIKIT-003
- **enforcement**: required
- **rationale**: 与现有 `SkinCompatBackgroundHelper` / `SkinCompatResources` 适配；保持单一资源来源。
- **evidence_ref**: EV-APP-CLIENT-G4-004, EV-APP-CLIENT-G4-015, POS-APP-CLIENT-G4-008

### 3.4 通用 Dialog/Fragment 基类【建议】

- **规则**：业务方在 core-ui-kit 已有 `CommonDialogFragment<T>`、`BaseLoadDataFragment`、`BasePageFragment`、`BaseHsListPageFragment` 等基类时，**优先继承基类**，不要在业务 module 自实现等价容器。
- **rule_id**: G4-UIKIT-004
- **enforcement**: recommended
- **rationale**: 复用按钮样式、最大宽高、关闭策略、列表分页等既有能力。
- **evidence_ref**: EV-APP-CLIENT-G4-002

### 3.5 View 扩展函数边界【建议】

- **规则**：View 扩展放置于 `viewext/` 包（如 `ViewExt.kt`、`ClickExt.kt`、`UIExt.kt`、`ResourceToolExt.kt`），扩展接收者只能是 `View` / `TextView` / `AppBarLayout` 等 Android UI 类型；不要在 `viewext/` 中放业务模型扩展。
- **rule_id**: G4-UIKIT-005
- **enforcement**: recommended
- **rationale**: 维持 `core-ui-kit` 的"纯 UI 能力"边界，避免和业务耦合。
- **evidence_ref**: EV-APP-CLIENT-G4-002

## 4. core-utils 规范

### 4.1 工具边界与 Android 依赖【强制】

- **规则**：`core/core-utils/` 中只放"无 Android Context 依赖（或弱依赖）"的纯函数 / 扩展；强依赖 Activity/Fragment 生命周期或 View 体系的能力放到 `core-ui-kit` 或对应 capability。
- **rule_id**: G4-UTILS-001
- **enforcement**: required
- **rationale**: 当前 `core-utils` 仅含 `string/StringExt.kt` 与 `evenbus/EventBusWrapper.kt`，保持其作为"轻量底层"位置。
- **evidence_ref**: EV-APP-CLIENT-G4-005

### 4.2 日志统一使用 VLog【强制】

- **规则**：跨域共享层日志全部走 `com.hstong.log.VLog`，禁止直接使用 `android.util.Log` 写业务日志；TAG 使用模块级常量（`private const val TAG = "..."`），避免运行时构造。
- **rule_id**: G4-UTILS-002
- **enforcement**: required
- **rationale**: 统一日志开关与上报通道；模块级 TAG 让线上检索可对齐。
- **evidence_ref**: EV-APP-CLIENT-G4-008, EV-APP-CLIENT-G4-009, LEG-APP-CLIENT-G4-001

### 4.3 EventBus 使用扩展封装【建议】

- **规则**：组件需要 EventBus 注册/解注册时，使用 `core-utils` 的 `Any.registerBus()` / `Any.unregisterBus()`，不直接调 `EventBus.getDefault().register/unregister`。
- **rule_id**: G4-UTILS-003
- **enforcement**: recommended
- **rationale**: 内置 `isRegistered()` 防重；批量场景使用 `List<Any>.registerBus()`。
- **evidence_ref**: EV-APP-CLIENT-G4-005

## 5. capability:web 规范（WebView 安全 + JS Bridge）

### 5.1 WebView 入口集中管理【强制】

- **规则**：新建 WebView 入口必须接入 `PlatformRouterTable.PATH_WEB_PAGE` / `REDIRECTTYPE_WEB_PAGE` 路由协议；URL / params / `__usehttp` 三个对外字段不得扩展为任意 key 的 bag；不要在业务 module 直接 `new WebView(...)` 后绕过 `PretreatmentServiceImpl`。
- **rule_id**: G4-WEB-001
- **enforcement**: required
- **rationale**: 现有 `CommonWebViewReachContainer` 通过 `@Route` + `@Redirect` 把 WebView 路由协议固化为 PRD 字段。
- **evidence_ref**: EV-APP-CLIENT-G4-006

### 5.2 WebSettings 安全基线【FORBIDDEN】

- **规则**：WebView 容器（包括未来在 capability:web 落地的实现）**禁止**满足以下任一配置：

  ```kotlin
  webView.settings.allowFileAccess = true
  webView.settings.allowFileAccessFromFileURLs = true
  webView.settings.allowUniversalAccessFromFileURLs = true
  ```

  缺省值由 framework 决定；项目代码若需要文件域访问必须经过安全 review 并以 PRD 形式记录例外。
- **rule_id**: G4-WEB-002
- **enforcement**: forbidden
- **rationale**: 这三项历史上多次被披露用于 file:// XSS；公共 WebView 容器不需要打开。
- **evidence_ref**: NEG-APP-CLIENT-G4-004

### 5.3 混合内容 / 不安全 TLS【FORBIDDEN】

- **规则**：WebView 容器**禁止**：
  - `mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW`；
  - `WebViewClient.onReceivedSslError` 直接 `handler.proceed()` 而不上报；
  - 信任所有证书 / 自定义 TrustManager 跳过校验。

  默认应使用 `MIXED_CONTENT_NEVER_ALLOW` 或 `COMPATIBILITY_MODE`，并对 SSL 错误做日志 + 拒绝。
- **rule_id**: G4-WEB-003
- **enforcement**: forbidden
- **rationale**: 防止 https 页面静默加载 http 资源或被中间人截获。
- **evidence_ref**: NEG-APP-CLIENT-G4-004

### 5.4 JsBridge 注入与白名单【强制】

- **规则**：通过 `addJavascriptInterface` 暴露 Native 桥时，必须：
  1. 在 `WebViewClient.shouldOverrideUrlLoading` / `onPageStarted` 处校验 origin 在白名单；
  2. Bridge 方法集合显式枚举（不使用反射），与 RN 侧 `callNativeAbility` 同一原则；
  3. 不接受任意字符串触发 `startActivity`，跳转必须经 Router；
  4. 入参日志只记字段名，不记值。
- **rule_id**: G4-WEB-004
- **enforcement**: required
- **rationale**: 与 RN Bridge 对齐安全模型。
- **evidence_ref**: POS-APP-CLIENT-G4-001, POS-APP-CLIENT-G4-002, NEG-APP-CLIENT-G4-005

### 5.5 capability:web 当前生效范围【pending】

- **规则**：本章节硬约束在新建 WebView 入口时强制；存量 `submodules/web` 中已有实现需要按本规范做一次专项 review（详见 LEG-APP-CLIENT-G4-003）。
- **rule_id**: G4-WEB-005
- **enforcement**: pending
- **evidence_ref**: LEG-APP-CLIENT-G4-003

## 6. capability:react-native 规范

### 6.1 RN runtime 单例初始化【强制】

- **规则**：RN 0.84 的 `SoLoader.init` 与 `DefaultNewArchitectureEntryPoint.load` 必须经 `RnRuntimeInitializer.ensureInitialized(context)` 触发；禁止在 Application、Activity、Fragment、Service 中分散调用。
- **rule_id**: G4-RN-001
- **enforcement**: required
- **rationale**: 双检锁 + 单例化避免重复初始化引发 native crash 或 TurboModule 注册分叉。
- **evidence_ref**: EV-APP-CLIENT-G4-009, POS-APP-CLIENT-G4-005, NEG-APP-CLIENT-G4-008

### 6.2 RN bundle 路径协议化【强制】

- **规则**：所有 RN 容器入口只接受 `bundleName + componentName + pageProps`，bundle 路径由 `RnBundleConfig.androidBundlePath(bundleName)` 推导；`bundleName` 必须满足 `^[A-Za-z0-9_-]+$`；禁止接收外部传入的完整 path 或 `file://` / `http://` URL；非 debug 构建若 `assetExists` 失败必须直接 `errorView`，不得 fallback 到远程加载。
- **rule_id**: G4-RN-002
- **enforcement**: required
- **rationale**: 切断 path traversal 与远程动态代码加载入口。
- **evidence_ref**: EV-APP-CLIENT-G4-010, POS-APP-CLIENT-G4-004, NEG-APP-CLIENT-G4-003

### 6.3 RN Native Bridge 命名与白名单【强制】

- **规则**：
  - 模块名：`MODULE_NAME = "NativeHsBridge"`；新增 Bridge 模块以 `Native*` 前缀。
  - 文件命名 `Rn*` 前缀；Bridge 模块继承 `ReactContextBaseJavaModule`，方法用 `@ReactMethod` 注解。
  - 暴露给 JS 的能力（`callNativeAbility` 的 `ability` 参数）必须以 `const ABILITY_*` 显式枚举 + `when` 分发；新增能力修改 ability 常量集合并补 `else → VLog.e(reason=unknownAbility) → RnBridgeResult.failure()`。
  - 探测能力（`canIUse`）必须真实读取 `@ReactMethod` 注解，不允许仅基于静态白名单返回 success。
- **rule_id**: G4-RN-003
- **enforcement**: required
- **rationale**: 让 JS ↔ Native 暴露面对 reviewer 显式可见，灰度时可定位试探调用。
- **evidence_ref**: EV-APP-CLIENT-G4-007, EV-APP-CLIENT-G4-008, POS-APP-CLIENT-G4-001, NEG-APP-CLIENT-G4-001

### 6.4 RN 调用日志：只记 keys，不记 payload【强制】

- **规则**：所有 `@ReactMethod` 入口必须先经过统一的 `readParams(methodName, params)` 类工具读取入参，并以 `paramKeys=...` 而非 `params=...` 打日志；`handleBusinessJsError` 等场景日志字段长度必须做 `take(JS_ERROR_MAX_LENGTH)` 截断（默认 200）。
- **rule_id**: G4-RN-004
- **enforcement**: required
- **rationale**: 防止业务字段值（含 PII / token）流入日志后端。
- **evidence_ref**: EV-APP-CLIENT-G4-008, POS-APP-CLIENT-G4-002, POS-APP-CLIENT-G4-003, NEG-APP-CLIENT-G4-002

### 6.5 RN Bridge 跳转必须经 Router【强制】

- **规则**：`callNativeAbility` 中的 `page.open` 类能力只接受 `redirectType + redirectValue`，最终调用 `Router.startRedirect(...)`；禁止 Bridge 内部直接 `startActivity(Intent.ACTION_VIEW, Uri.parse(...))` 或自行 ARouter `Postcard` 跳转。
- **rule_id**: G4-RN-005
- **enforcement**: required
- **rationale**: 与广告 SDK / 全量页面触达共享同一 Router 链路。
- **evidence_ref**: EV-APP-CLIENT-G4-008, NEG-APP-CLIENT-G4-005

### 6.6 RN Container 错误兜底【强制】

- **规则**：`RnContainerFragment` 在以下三种情况下必须返回 `errorView("...")`，不得创建 RN 实例：
  - 配置不合法（`!config.isValid()`）；
  - 非 debug 构建且 bundle 不存在（`!bundleCheck.exists && !isDebugBuild`）；
  - RN runtime 创建失败（`createReactSurfaceView` 返回 null）。
  并通过 `VLog.e/i` 输出原因 / bundlePath / component 等关键字段。
- **rule_id**: G4-RN-006
- **enforcement**: required
- **rationale**: 防止白屏 + 失败定位困难。
- **evidence_ref**: EV-APP-CLIENT-G4-010, POS-APP-CLIENT-G4-006

### 6.7 ReactPackage 清单单一来源【建议】

- **规则**：RN 公共依赖 ReactPackage 集中维护在 `RnRuntimeInitializer.createReactPackageList()` 与 `RnBridgePackage`；容器和 host 不要在多处分散维护各自的 package 列表。
- **rule_id**: G4-RN-007
- **enforcement**: recommended
- **rationale**: 避免 TurboModule 注册不一致。
- **evidence_ref**: EV-APP-CLIENT-G4-009

## 7. capability:share 规范【pending】

### 7.1 当前模块为空脚手架【pending】

- **规则**：在 `core/capability/share` 引入第三方分享 SDK 之前，本章节为 `pending`。新代码若需要分享能力，需先评估在该模块内集中实现。
- **rule_id**: G4-SHARE-001
- **enforcement**: pending
- **evidence_ref**: EV-APP-CLIENT-G4-011, LEG-APP-CLIENT-G4-002

### 7.2 第三方 SDK 隔离【强制 / 占位】

- **规则**（启用前提：share 模块开始接入第三方 SDK）：
  - 微信 / Facebook / Twitter / Sina 等 SDK 必须以 `implementation` 形式收口在 `core/capability/share/build.gradle.kts`，不得让业务模块直接 `implementation` 这些 SDK；
  - 提供统一的 `ShareCenter`（或等价对外门面），业务侧只看到 `ShareTarget` 抽象；
  - SDK 凭据（AppKey/AppSecret）必须放在 `BuildConfig` 或 secrets 文件，禁止硬编码在 Kotlin 源码中。
- **rule_id**: G4-SHARE-002
- **enforcement**: pending
- **evidence_ref**: EV-APP-CLIENT-G4-011

## 8. capability:kaz-pdp 规范（广告 / PDP / 埋点）

### 8.1 广告展示统一入口【强制】

- **规则**：开屏广告通过 `PdpCenter.prepareSplash(intent, forwardType)`；弹窗广告通过 `PdpCenter.showPopupAd(adsType, ads, displayStyle, ...)`；Banner / 通知条通过 `PdpBannerFragment.attachTo(...)` / `PdpNotificationFragment.attachTo(...)`。业务侧不得绕过这些入口直接 `BizPopupStack.addPopupDialog(...)` 接入广告 Fragment。
- **rule_id**: G4-PDP-001
- **enforcement**: required
- **rationale**: 入口收口便于将来切换广告策略、做灰度。
- **evidence_ref**: EV-APP-CLIENT-G4-012, EV-APP-CLIENT-G4-013, POS-APP-CLIENT-G4-010

### 8.2 跳转必须经 RedirectDispatcher → Router【强制】

- **规则**：广告点击、Banner 点击、通知条点击的跳转动作必须经 `RedirectDispatcher.dispatch(context, redirect)`；该方法内部统一调用 `Router.startRedirect(context, redirectType, redirectValue)`。禁止在 `handleClick` 中直接 `startActivity(Intent.ACTION_VIEW, Uri.parse(...))`。
- **rule_id**: G4-PDP-002
- **enforcement**: required
- **rationale**: 与项目路由白名单 / deeplink / push tracking 共享同一链路。
- **evidence_ref**: EV-APP-CLIENT-G4-013, POS-APP-CLIENT-G4-009, NEG-APP-CLIENT-G4-005

### 8.3 Fragment attach 幂等 + 显式 positionCode【强制】

- **规则**：广告 Fragment 必须通过 `attachTo(fragmentManager, containerId, positionCode, ...)` 接入；宿主重复调用时基于 `positionCode + style + ratio` 做幂等比较，匹配时复用现有 Fragment，不触发 `replace`。`positionCode` 由宿主显式传入，禁止 SDK 内部硬编码。
- **rule_id**: G4-PDP-003
- **enforcement**: required
- **rationale**: 避免下拉刷新 / 配置变化导致 Banner 闪动；让广告位语义由业务侧掌控。
- **evidence_ref**: EV-APP-CLIENT-G4-013, POS-APP-CLIENT-G4-010

### 8.4 广告日志 / 埋点 PII 保护【FORBIDDEN】

- **规则**：广告 SDK 内部**禁止**：
  - 在 VLog 中输出完整 `imageUrl` / `videoUrl`；当前代码统一以 `takeLast(40)` 截断；
  - 在 SDK 内部自行向埋点系统写入 `userId` / `phone` / `email` 等 PII 字段；
  - 在 `recordView/recordClick` TODO 落地之前提前接入 `SensorsTool` 上报曝光/点击事件，避免与新埋点方案分叉。

  日志字段允许：`id` / `title` / `redirectType` / 截断 URL / `skipSeconds`。
- **rule_id**: G4-PDP-004
- **enforcement**: forbidden
- **rationale**: SDK 在新埋点方案落地前保持"只记调试日志"姿态；防止 PII 与完整资源 URL 进入日志后端。
- **evidence_ref**: EV-APP-CLIENT-G4-014, POS-APP-CLIENT-G4-011, NEG-APP-CLIENT-G4-006, LEG-APP-CLIENT-G4-004

### 8.5 数据来源仅 KMP LaunchAdService【建议】

- **规则**：SDK 内部广告数据仅从 `com.hs.kmp.biz.securities.pdp.service.LaunchAdService` / `AdService` 获取，并使用 `kotlinx.serialization.json.Json` 序列化进 Intent；不直接发起 HTTP 请求拉取广告。
- **rule_id**: G4-PDP-005
- **enforcement**: recommended
- **rationale**: 数据层频次过滤 / 缓存 / 资源就绪由 KMP 层负责；Android SDK 只做展示与跳转。
- **evidence_ref**: EV-APP-CLIENT-G4-013

## 9. AI 生成规则（汇总）

具体 AI Prompt 落点详见 `ai-rules.md`。本章节为高层指引：

- 生成 RN Bridge 方法时必须包含：`readParams(methodName, params)` 调用、`when(ability)` 显式分支、`else -> VLog.e(reason=...) → RnBridgeResult.failure()`；不得用反射或动态查表。
- 生成 RN 容器入口时必须包含 bundleName 校验、`assetExists` 兜底、三类 errorView 分支。
- 生成 WebView 配置时必须显式关闭 `allowFileAccessFromFileURLs` / `allowUniversalAccessFromFileURLs`，并设置 `mixedContentMode = MIXED_CONTENT_NEVER_ALLOW`（或 `COMPATIBILITY_MODE`）。
- 生成广告 Fragment 入口时必须使用 `attachTo + refresh` 双入口，并接受 `positionCode` 参数。
- 生成日志时必须使用 `VLog`，禁止使用 `android.util.Log` 输出业务日志；日志字段不携带完整 URL / payload / PII。
- 生成自定义 View 命名走 `Hs*` 前缀；自定义 attr 走"模块缩写_"前缀；颜色资源带 `_night` 双名。

## 10. Code Review 检查项（汇总）

详见 `review-checklist.md`。摘录关键项：

- [ ] RN Bridge 新增方法是否经 `readParams` 走统一日志，并显式 `when` 分发？
- [ ] RN 入口是否仅接受 `bundleName`，禁止外部传完整 path？
- [ ] WebView 新建容器是否显式关闭三项 file/universal access、并设置 `MIXED_CONTENT_NEVER_ALLOW`？
- [ ] 广告/RN/JS Bridge 跳转是否一律走 `Router.startRedirect` / `RedirectDispatcher`？
- [ ] 日志是否使用 `VLog` 且不含完整 payload / 完整 URL / PII？
- [ ] capability 模块依赖是否未反向 `implementation project(':app-*')`？
- [ ] 自定义 View / attr / 资源命名是否符合 `Hs*` / `hstb_*` / `_night` 约定？

## 11. Evidence 参考表

| Section | Evidence IDs |
| --- | --- |
| §1 技术栈 | EV-APP-CLIENT-G4-001, LEG-APP-CLIENT-G4-007 |
| §2 全景 | EV-APP-CLIENT-G4-001, LEG-APP-CLIENT-G4-002, LEG-APP-CLIENT-G4-003 |
| §3 core-ui-kit | EV-APP-CLIENT-G4-002 ~ -004, EV-APP-CLIENT-G4-015, POS-APP-CLIENT-G4-007/-008, LEG-APP-CLIENT-G4-005/-006 |
| §4 core-utils | EV-APP-CLIENT-G4-005, EV-APP-CLIENT-G4-008, EV-APP-CLIENT-G4-009, LEG-APP-CLIENT-G4-001 |
| §5 capability:web | EV-APP-CLIENT-G4-006, NEG-APP-CLIENT-G4-004, NEG-APP-CLIENT-G4-005, LEG-APP-CLIENT-G4-003 |
| §6 capability:react-native | EV-APP-CLIENT-G4-007 ~ -010, POS-APP-CLIENT-G4-001 ~ -006, NEG-APP-CLIENT-G4-001 ~ -003, NEG-APP-CLIENT-G4-008 |
| §7 capability:share | EV-APP-CLIENT-G4-011, LEG-APP-CLIENT-G4-002, LEG-APP-CLIENT-G4-007 |
| §8 capability:kaz-pdp | EV-APP-CLIENT-G4-012 ~ -014, POS-APP-CLIENT-G4-009 ~ -011, NEG-APP-CLIENT-G4-005, NEG-APP-CLIENT-G4-006, LEG-APP-CLIENT-G4-004 |
