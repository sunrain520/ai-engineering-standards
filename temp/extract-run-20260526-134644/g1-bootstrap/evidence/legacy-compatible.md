---
doc_id: "app-client-android-bootstrap-evidence-legacy"
title: "App-Client Android 启动与 SDK 装配 — 遗留兼容证据"
domain: "app-client"
sub_domain: "android"
doc_type: "evidence"
evidence_kind: "legacy-compatible"
status: "draft"
indexable: true
source_batch: "app-client-android-app-bootstrap-app-kaz-p1, app-client-android-app-core-bootstrap-p1"
last_reviewed: "2026-05-26"
sanitized: true
---

# 遗留兼容证据（G1 Bootstrap）

> 编号空间：`LEG-APP-CLIENT-G1-*`。这些写法当前仍在主线上运行，但与"理想规范"存在差距，规范文档中以"允许 / 计划替换"形式承接。

## LEG-APP-CLIENT-G1-1
- observed_pattern: `GlobalApplication.onCreate` 末尾仍直接调用 `KeyboardHelper.setKeyboardInitializer { ... }`，并在源码内标注 `// TODO 李佺 common 初始化的东西，暂时放在这里`
- file_role: app-host-application
- boundary: 宿主 Application；理想方案是把键盘初始化迁入 `AppInitializer` 或 `CommBizManager`
- confidence: high
- occurrences: 1
- evidence_kind: legacy-compatible
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`
- migration_hint: 后续把 `KeyboardHelper` 注入 `AppInitializer` 的 delay-task，避免 onCreate 链过长。

## LEG-APP-CLIENT-G1-2
- observed_pattern: `onHostCreate()` 中通过 `Info_R.id.ll_main_root = R.id.ll_main_root` 等三行将 R.id 静态注入 `Info_R`，并标注 `// TODO 李佺，临时抽取，原 RouterInjection 里面的，看起来还在使用，会处理掉`
- file_role: legacy-router-injection
- boundary: 宿主初始化
- confidence: high
- occurrences: 1
- evidence_kind: legacy-compatible
- sanitized: true
- 路径模式: `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`
- migration_hint: 由 Router/UI 层提供受控接入点，移除对宿主 R.id 的强耦合。

## LEG-APP-CLIENT-G1-3
- observed_pattern: `Loading.kt` `TreatyDialog` 当前展示 `测试信息, 等待产品文案替换`，正式协议文案以注释形式保留，未与产品文案对齐
- file_role: privacy-gate
- boundary: 闪屏；仅文案层面
- confidence: high
- occurrences: 1
- evidence_kind: legacy-compatible
- sanitized: true
- 路径模式: `app-core/src/main/**/loading/Loading.kt`
- migration_hint: 上线前必须以产品确认文案替换，并恢复隐私协议链接的可点击富文本。

## LEG-APP-CLIENT-G1-4
- observed_pattern: `Loading.kt` 与 `MainActivity.kt` 仍直接调用 `VLog`、`Log.d`、`HSKLog` 三套日志接口，未在启动链路收敛到单一接口
- file_role: launch-logging
- boundary: 闪屏与主页面入口
- confidence: medium
- occurrences: 多处
- evidence_kind: legacy-compatible
- sanitized: true
- 路径模式: `app-core/src/main/**/loading/Loading.kt`、`app-core/src/main/**/main/MainActivity.kt`
- migration_hint: 在 review 阶段决定启动链路统一日志通道（建议 HSKLog + AppLaunch tag）。

## LEG-APP-CLIENT-G1-5
- observed_pattern: AndroidManifest 中 `<uses-library android:name="com.google.android.maps" .../>` 与 `<uses-library android:name="android.test.runner" />` 仍存在，但当前模块未明显使用 Google Maps 或 test runner
- file_role: manifest-uses-library
- boundary: AndroidManifest
- confidence: medium
- occurrences: 2
- evidence_kind: legacy-compatible
- sanitized: true
- 路径模式: `app-kaz/src/main/AndroidManifest.xml`
- migration_hint: 评估是否可移除 `com.google.android.maps` 与 `android.test.runner` 引用，减少包体与 manifest 表面积。

## LEG-APP-CLIENT-G1-6
- observed_pattern: build.gradle 中存在大段被注释的 `Deps.Business.*`（如 `community/quotes/wealth` 等），表明本模块正在收敛业务依赖，注释代码尚未清理
- file_role: build-dependencies
- boundary: 构建期
- confidence: medium
- occurrences: 多处
- evidence_kind: legacy-compatible
- sanitized: true
- 路径模式: `app-kaz/build.gradle`
- migration_hint: 待业务收敛稳定后清理注释依赖，保持 build.gradle 可读性。
