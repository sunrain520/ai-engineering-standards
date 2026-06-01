---
doc_id: "app-client-android-bootstrap-evidence-forbidden"
title: "App-Client Android 启动与 SDK 装配 — 反例证据"
domain: "app-client"
sub_domain: "android"
doc_type: "evidence"
evidence_kind: "forbidden-example"
status: "draft"
indexable: true
source_batch: "app-client-android-app-bootstrap-app-kaz-p1, app-client-android-app-core-bootstrap-p1"
last_reviewed: "2026-05-26"
sanitized: true
---

# 反例证据（G1 Bootstrap）

> 编号空间：`NEG-APP-CLIENT-G1-*`。

## 说明

本批次（app-kaz `GlobalApplication.kt` + AndroidManifest + build.gradle，app-core `MainActivity.kt` / `Loading.kt` / `MainTabViewModel.kt`）扫描范围内**未发现显式反例代码**：当前实现已统一通过 `HsConfiguration` / `BuildMainTabsUseCase` / `MainPopupViewModel` / 反射桥接等机制收敛了风险点。

存在的"潜在退化模式"以注释形式给出，不分配 NEG 编号；待 review 阶段决定是否升级为正式反例：

- 注释形式的潜在退化（仅观察，无编号）
  - `GlobalApplication.kt` 中 `// TODO 李佺 common 初始化的东西，暂时放在这里` 与 `KeyboardHelper.setKeyboardInitializer { ... }` 暂留在 `onCreate` 末尾，长期看应迁出宿主 Application；当前作为遗留兼容暂记录于 `legacy-compatible.md`，不计为反例。
  - `Loading.kt` 中 `TreatyDialog` 内大段被注释的 `SpanUtils` 富文本协议条款，是产品文案重构期间的临时占位；只要"同意前不上报"主流程未破坏，不视为反例。

如需在后续 review 中补充明确的 NEG 用例（例如直接在源码硬编码 push appKey、attachBaseContext 中初始化网络 SDK 等），请在此文件中追加 `NEG-APP-CLIENT-G1-1..N`。
