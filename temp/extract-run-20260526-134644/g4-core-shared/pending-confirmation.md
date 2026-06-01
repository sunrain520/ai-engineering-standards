---
doc_id: "app-client-android-g4-core-shared-pending"
title: "G4 跨域共享层 pending confirmation"
domain: "app-client"
sub_domain: "android"
parent_standard: "app-client-android-core-shared-standard"
status: "draft"
last_reviewed: "2026-05-26"
generation_profile: "phase1-selected-batch"
---

# Pending Confirmation（待确认）

> 单项目 evidence 不足以拍板的条目；需要 owner 确认后将 status 推进为 `accepted` 或 `rejected`。

## PENDING-APP-CLIENT-G4-1 — capability:web 安全基线生效边界

**问题**：本组采集范围内 `core/capability/web/` 仅有 `CommonWebViewReachContainer`（空 Fragment + ARouter 路由桥）。实际 WebView/JsBridge 实现位于 `submodules/web/web/...`（不在本组采集范围）。

**已写入规范的强约束**：
- G4-WEB-002 [FORBIDDEN]：禁止 `allowFileAccess(FromFileURLs)` / `allowUniversalAccessFromFileURLs`。
- G4-WEB-003 [FORBIDDEN]：禁止 `MIXED_CONTENT_ALWAYS_ALLOW` / `handler.proceed()` / 信任所有证书。
- G4-WEB-004：JsBridge 必须 origin 白名单 + 显式枚举 + 仅记 keys + Router 跳转。

**待确认**：
- 上述 [FORBIDDEN] 是否同时强制覆盖 `submodules/web/`？
- 现存 `submodules/web/web/src/main/java/com/hstong/web/bridge/WebViewConfigHandler.kt` 等实现是否已经满足这些约束？是否需要专项 code-facts 采集 + 独立 standard？
- 是否需要在本规范中显式声明"capability:web 章节生效范围 = capability:web + submodules:web"？

**evidence_ref**: EV-APP-CLIENT-G4-006, LEG-APP-CLIENT-G4-003, NEG-APP-CLIENT-G4-004

## PENDING-APP-CLIENT-G4-2 — capability:share 接入策略

**问题**：`core/capability/share/` 当前仅是空脚手架（namespace + 空 Manifest + 占位测试类）。

**待确认**：
- share 模块的承接计划：哪些第三方 SDK（微信 / FB / Twitter / 微博 / 系统分享）将集中收口到此模块？
- 凭据管理策略：是 `BuildConfig` + secrets 文件，还是引入新的 secret manager？
- 现存业务模块是否已有零散分享实现？是否需要一次性收编？

**evidence_ref**: EV-APP-CLIENT-G4-011, LEG-APP-CLIENT-G4-002

## PENDING-APP-CLIENT-G4-3 — kaz-pdp 新埋点方案

**问题**：`PdpCenterPopupFragment` / `PdpBannerFragment` / `PdpNotificationFragment` 的 `recordView/recordClick` 均为 `// TODO: 接入新埋点方案`。

**待确认**：
- 新埋点方案的字段约定（id / position / scene / display_style …）是否已定型？
- 是否需要在 SDK 层提供 `AdTracker` 接口，由业务侧注入实现，而非 SDK 直接依赖具体埋点工具？
- 在新方案上线前，G4-PDP-004 中"recordView/recordClick 不私自 SensorsTool"的 forbidden 是否需要降级为 recommended？

**evidence_ref**: EV-APP-CLIENT-G4-014, NEG-APP-CLIENT-G4-006, LEG-APP-CLIENT-G4-004

## PENDING-APP-CLIENT-G4-4 — share 模块编译目标对齐

**问题**：`core/capability/share/build.gradle.kts` 使用 `compileSdk = 35` / `minSdk = 24` / Java 11，与其它 capability（`rootProject.compileSdkVersion` / Java 17）不一致。

**待确认**：
- 是否在接入分享 SDK 时统一对齐到 `rootProject.compileSdkVersion` + Java 17 + Groovy DSL？
- 还是保持 KTS 风格作为新模块模板，反过来推动其它 capability 迁移？

**evidence_ref**: LEG-APP-CLIENT-G4-007

## PENDING-APP-CLIENT-G4-5 — core-utils 是否需要扩展 logger / date 工具

**问题**：当前 `core-utils` 仅有 `string/StringExt.kt` 与 `evenbus/EventBusWrapper.kt`，没有 logger 包装、date 工具、网络/IO 扩展等常见底层工具。

**待确认**：
- 项目中分散在各业务 module 的日期 / 数字格式化工具是否需要收编进 `core-utils`？
- 还是保持 `core-utils` 极简，仅承接确定无 Android 依赖的纯函数？

**evidence_ref**: EV-APP-CLIENT-G4-005

## PENDING-APP-CLIENT-G4-6 — RN ReactPackage 列表治理

**问题**：`RnRuntimeInitializer.createReactPackageList()` 列举了一组三方 RN 库（AsyncStorage / Reanimated / Worklets / SafeArea / RNScreens / Svg / RNCWebView）；`RnBridgePackage` 单独注册业务 Bridge。

**待确认**：
- 三方 RN 库的依赖清单是否需要由 `Deps.*` 在 gradle 层统一锁定版本？
- 业务侧若需新增三方 RN 库，是否走 PR review + `RnRuntimeInitializer` 修改流程，还是允许在容器外单独注册？

**evidence_ref**: EV-APP-CLIENT-G4-009
