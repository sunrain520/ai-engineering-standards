---
doc_id: "app-client-android-g4-core-shared-review-checklist"
title: "G4 跨域共享层 Code Review checklist"
domain: "app-client"
sub_domain: "android"
parent_standard: "app-client-android-core-shared-standard"
status: "draft"
last_reviewed: "2026-05-26"
generation_profile: "phase1-selected-batch"
---

# Code Review Checklist（跨域共享层）

> 用于 PR review，复制以下 checklist，逐项打勾。每项注明 `rule_id` 与对应 evidence。

## 1. core-ui-kit

- [ ] **G4-UIKIT-001** 新增"业务 layout 可复用 View"是否使用 `Hs*` 前缀；新增 base/abstract 容器是否使用 `Base*` / `Common*`？
  - evidence_ref: EV-APP-CLIENT-G4-002
- [ ] **G4-UIKIT-002** 自定义 attr 是否带"模块缩写_"前缀，并在 `attrs.xml` 显式声明 + `declare-styleable` 引用？
  - evidence_ref: EV-APP-CLIENT-G4-003
- [ ] **G4-UIKIT-003** 新增颜色 / 资源是否提供 `_night` 双名；module `build.gradle` 是否显式声明 `res.srcDirs = ['src/main/res', 'src/main/res-night']`？
  - evidence_ref: EV-APP-CLIENT-G4-004, EV-APP-CLIENT-G4-015
- [ ] **G4-UIKIT-004** 新增 Dialog/Fragment 是否优先继承 `CommonDialogFragment` / `BaseLoadDataFragment` / `BasePageFragment` 等基类，未在业务模块自实现等价容器？
  - evidence_ref: EV-APP-CLIENT-G4-002

## 2. core-utils

- [ ] **G4-UTILS-001** `core-utils/` 中新增扩展是否未引入 `androidx.fragment.app.*` / `android.view.*` / `android.app.Activity` 等 UI 依赖？
  - evidence_ref: EV-APP-CLIENT-G4-005
- [ ] **G4-UTILS-002** 日志是否使用 `com.hstong.log.VLog`，TAG 为 `private const val`，未 `import android.util.Log` 写业务日志？
  - evidence_ref: EV-APP-CLIENT-G4-008
- [ ] **G4-UTILS-003** EventBus 注册 / 解注册是否经 `Any.registerBus()` / `Any.unregisterBus()` 扩展，而非直接 `EventBus.getDefault().register(...)`？
  - evidence_ref: EV-APP-CLIENT-G4-005

## 3. capability:web / WebView 安全

- [ ] **G4-WEB-001** 新建 WebView 入口是否复用 `PlatformRouterTable.PATH_WEB_PAGE` 路由协议，对外字段限定 `url` / `params` / `__usehttp`？
  - evidence_ref: EV-APP-CLIENT-G4-006
- [ ] **G4-WEB-002 [FORBIDDEN]** WebView 是否**未**出现以下任一配置：
  - `allowFileAccess = true`
  - `allowFileAccessFromFileURLs = true`
  - `allowUniversalAccessFromFileURLs = true`
  - evidence_ref: NEG-APP-CLIENT-G4-004
- [ ] **G4-WEB-003 [FORBIDDEN]** 是否**未**出现 `mixedContentMode = MIXED_CONTENT_ALWAYS_ALLOW`、`onReceivedSslError { handler.proceed() }`、自定义"信任所有证书" TrustManager？
  - evidence_ref: NEG-APP-CLIENT-G4-004
- [ ] **G4-WEB-004** JS Bridge 暴露面是否：
  - origin 白名单校验已在 `WebViewClient` 中实现；
  - 方法集合通过显式 `when` / `if-else` 分发；
  - 入参日志只记 `paramKeys`；
  - 跳转走 `Router.startRedirect`？
  - evidence_ref: POS-APP-CLIENT-G4-001, POS-APP-CLIENT-G4-002, NEG-APP-CLIENT-G4-005

## 4. capability:react-native

- [ ] **G4-RN-001** 是否仅经 `RnRuntimeInitializer.ensureInitialized(...)` 触发初始化，未在其它位置调用 `SoLoader.init` / `DefaultNewArchitectureEntryPoint.load`？
  - evidence_ref: POS-APP-CLIENT-G4-005, NEG-APP-CLIENT-G4-008
- [ ] **G4-RN-002** RN 容器入口是否仅接受 `bundleName / componentName / pageProps`，bundle 路径由 `RnBundleConfig` 推导，正则 `^[A-Za-z0-9_-]+$`，未支持外部完整路径或远程 bundle？
  - evidence_ref: POS-APP-CLIENT-G4-004, NEG-APP-CLIENT-G4-003
- [ ] **G4-RN-003** 新增 `@ReactMethod` 是否经统一 `readParams(methodName, params)`，TAG 与 `MODULE_NAME` 在 `companion object` 中常量化？
  - evidence_ref: EV-APP-CLIENT-G4-007, POS-APP-CLIENT-G4-002
- [ ] **G4-RN-004** `callNativeAbility` 中新增 ability 是否：
  - 在 `companion object` 增加 `const val ABILITY_<NAME>`；
  - 在 `when (ability)` 显式分支；
  - 保留 `else -> { VLog.e(...); RnBridgeResult.failure() }`？
  - evidence_ref: EV-APP-CLIENT-G4-008, POS-APP-CLIENT-G4-001
- [ ] **G4-RN-005** Bridge 内跳转是否走 `Router.startRedirect(...)`，redirectValue 经 `FastJsonTool.toJSONString` 转 JSON？
  - evidence_ref: EV-APP-CLIENT-G4-008
- [ ] **G4-RN-006** Container Fragment 是否在 (1) 配置不合法、(2) 非 debug 且 bundle 不存在、(3) runtime 失败 三种场景返回 `errorView("...")` 并打 VLog？
  - evidence_ref: EV-APP-CLIENT-G4-010, POS-APP-CLIENT-G4-006
- [ ] **G4-RN-007** 业务错误 / JS 错误日志是否仅取 `message`/`source` 并 `take(200)` 截断？
  - evidence_ref: POS-APP-CLIENT-G4-003

## 5. capability:share

- [ ] **G4-SHARE-001 [pending]** 在 share 模块未承接第三方 SDK 之前，PR 是否未在其它位置自实现微信 / FB / Twitter 分享？
  - evidence_ref: EV-APP-CLIENT-G4-011
- [ ] **G4-SHARE-002 [pending]** 接入分享 SDK 时：SDK 凭据是否未硬编码、对外是否提供 `ShareCenter` 类门面？
  - evidence_ref: LEG-APP-CLIENT-G4-002

## 6. capability:kaz-pdp

- [ ] **G4-PDP-001** 广告 / Banner / 通知条接入是否走 `PdpCenter.*` / `PdpBannerFragment.attachTo` / `PdpNotificationFragment.attachTo`，未在业务模块直接 `BizPopupStack.addPopupDialog(BIZ_ADVERTISING, ...)`？
  - evidence_ref: POS-APP-CLIENT-G4-010
- [ ] **G4-PDP-002** 跳转是否走 `RedirectDispatcher.dispatch(...)` → `Router.startRedirect(...)`，未直接 `startActivity(Intent.ACTION_VIEW, ...)`？
  - evidence_ref: POS-APP-CLIENT-G4-009, NEG-APP-CLIENT-G4-005
- [ ] **G4-PDP-003** Fragment `attachTo` 是否实现幂等比较（`positionCode + style + ratio`），重复调用不触发 replace？
  - evidence_ref: POS-APP-CLIENT-G4-010
- [ ] **G4-PDP-004 [FORBIDDEN]** 日志输出 URL 是否使用 `takeLast(40)` 截断；是否**未**写入 `userId / phone / email` 等 PII；`recordView/recordClick` 是否仍为 TODO，未私自接入 `SensorsTool`？
  - evidence_ref: POS-APP-CLIENT-G4-011, NEG-APP-CLIENT-G4-006
- [ ] **G4-PDP-005** 广告数据是否仅来源于 `LaunchAdService` / `AdService`（KMP），SDK 内部未发起独立 HTTP？
  - evidence_ref: EV-APP-CLIENT-G4-013

## 7. 共通

- [ ] **G4-COMMON-001** `core/capability/*/build.gradle` 是否未出现 `implementation project(':app-*')` 类反向依赖业务 module？
  - evidence_ref: NEG-APP-CLIENT-G4-007
- [ ] **G4-COMMON-002** 新增 capability 模块是否对齐 `rootProject.compileSdkVersion / minSdkVersion / targetSdkVersion`、Java 17、`Deps.Lib.*` 依赖管理（share 模块例外，详见 LEG-APP-CLIENT-G4-007）？
  - evidence_ref: LEG-APP-CLIENT-G4-007
