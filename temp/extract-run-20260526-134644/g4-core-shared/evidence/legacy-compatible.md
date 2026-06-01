---
doc_id: "app-client-android-g4-core-shared-legacy-compatible"
title: "G4 跨域共享层 legacy compatible"
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

# Legacy Compatible（兼容存量约定）

> 仓库中已经存在的"非理想但稳定"的写法。新代码不应主动复制；存量改造前需确认替代路径就绪。

## LEG-APP-CLIENT-G4-001 — 字符串日志而非结构化日志

**现状**：本组源码统一使用 `com.hstong.log.VLog` 写字符串日志，例如：

```kotlin
VLog.i(TAG, "NativeHsBridge#$methodName called, paramKeys=${plainParams.keys}")
VLog.d(TAG, "prepareSplash() 广告命中：id=${adItem.id}, title=${adItem.title} ...")
```

**与"理想做法"差距**：缺少结构化 fields（`logger.info {"event":"rn_bridge_call","method":...}`），导致日志后端解析依赖正则。

**建议**：
- 新增日志保持 VLog 风格，但建议遵循"动作短语 + key=value"模板，便于将来切结构化日志时低成本迁移。
- 不为单点重构 VLog → 结构化日志库；待全 app 统一日志中台再批量改造。

## LEG-APP-CLIENT-G4-002 — capability:share 模块仅有空脚手架

**现状**：`core/capability/share/`：

- `build.gradle.kts` 已声明 namespace、minSdk、androidx 基础依赖。
- `src/main/AndroidManifest.xml` 为空 `<manifest>`。
- `src/main/java/com/hstong/core/share/` 目录无 `.kt` 文件。

**与"理想做法"差距**：模块尚未承载分享能力，但被列入 `core/capability/*` 标准位。

**建议**：
- 当前阶段视作"占位 module"。新代码不要在其他位置重复实现分享，待该模块实现到位后统一接入。
- 在该模块未引入第三方分享 SDK 之前，本规范的 share 章节保持 `pending`。

## LEG-APP-CLIENT-G4-003 — capability:web 实际实现仍在 submodules/web

**现状**：`core/capability/web/` 仅有 `CommonWebViewReachContainer`（空 Fragment + ARouter/Redirect 注解）。完整 WebView/JS Bridge 实现位于 `submodules/web/web/...`，未纳入本组采集范围。

**与"理想做法"差距**：capability:web 未集中 WebView 容器；规范章节里的 WebView 安全规则需要在 `submodules/web` 落地点检查。

**建议**：
- 新建 WebView 入口时优先迁入 `core/capability/web`。
- 当前阶段 WebView 安全章节按 FORBIDDEN 写硬约束，但生效边界包括 `submodules/web`，依赖人工 review 协同。

## LEG-APP-CLIENT-G4-004 — kaz-pdp 埋点 placeholder

**现状**：`PdpCenterPopupFragment` / `PdpBannerFragment` / `PdpNotificationFragment` 的 `recordView/recordClick` 多处显式标记 `// TODO: 接入新埋点方案`。

**与"理想做法"差距**：广告曝光/点击埋点缺位，依赖未来统一埋点中台。

**建议**：
- 新代码不要单独直接调 `SensorsTool` 上报曝光/点击事件，避免与新中台冲突（详见 NEG-APP-CLIENT-G4-006）。
- 在 TODO 落地前，仅保留 VLog 调试日志（且 URL 已 `takeLast(40)` 截断）。

## LEG-APP-CLIENT-G4-005 — core-ui-kit 双轨命名：Hs 前缀 + Common/Base

**现状**：core-ui-kit 中存在两类命名：

- 自定义可复用 View / 控件类：`HsTabLayout`、`HsLoadingRefreshHeader`、`HsListRefreshPaginationHelper` 等使用 `Hs*` 前缀。
- 抽象基类与通用容器：`BaseFragment`、`BaseLoadDataFragment`、`BasePageFragment`、`BasePageViewModel`、`CommonActivity`、`CommonDialogFragment` 不带 `Hs` 前缀。

**与"理想做法"差距**：未能用单一前缀完全统一。

**建议**：
- 新增"用户可见自定义控件" → 按现行约定使用 `Hs*` 前缀。
- 新增"基类/抽象容器" → 沿用 `Base*` / `Common*` 命名，不追加前缀。
- 不为命名一致性单点重命名既有类，避免破坏外部依赖。

## LEG-APP-CLIENT-G4-006 — 多 capability 各自维护 res-night

**现状**：`core/capability/react-native/build.gradle`、`core/capability/web/build.gradle`、`core/capability/kaz-pdp/build.gradle` 等多处独立声明 `res.srcDirs = ['src/main/res', 'src/main/res-night']`。

**与"理想做法"差距**：缺少集中的 gradle plugin 注入；新增 capability 模块需要逐个抄写 sourceSets。

**建议**：
- 新增 capability 模块继续在 `build.gradle` 中显式声明 `res.srcDirs`，与现行风格一致。
- 不为该项发起单点 plugin 抽取；待项目级 gradle 收口时再统一。

## LEG-APP-CLIENT-G4-007 — share 模块 build script 与其它 capability 风格不一致

**现状**：

- `core/capability/share/build.gradle.kts`：Kotlin DSL，`compileSdk = 35`，`minSdk = 24`，Java 11，仅有 androidx 基础依赖。
- 其它 capability（react-native / web / kaz-pdp）：Groovy DSL，使用 `rootProject.compileSdkVersion / minSdkVersion / targetSdkVersion`，Java 17。

**与"理想做法"差距**：编译目标版本（compileSdk、Java 11/17）与依赖管理风格不一致。

**建议**：
- share 模块未承载实际能力，可暂留 KTS。
- 接入第三方分享 SDK 时，需对齐 `rootProject.compileSdkVersion`、Java 17、`Deps.*` 依赖管理风格，并补充 `kapt` 等通用配置。
