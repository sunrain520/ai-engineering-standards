---
doc_id: "app-client-android-g4-core-shared-group-summary"
title: "G4 跨域共享层 group summary"
domain: "app-client"
sub_domain: "android"
run_id: "20260526-134644-app-client"
group: "g4-core-shared"
status: "draft"
last_reviewed: "2026-05-26"
generation_profile: "phase1-selected-batch"
---

# Group Summary（G4 跨域共享层）

## 0. 元信息

- run_id: 20260526-134644-app-client
- domain / sub_domain: app-client / android
- 输出根：`temp/extract-run-20260526-134644/g4-core-shared/`
- 合并的 batch（5 个）：
  - `app-client-android-core-ui-kit-p1`
  - `app-client-android-capability-web-jsbridge-p1`
  - `app-client-android-rn-bridge-p1`
  - `app-client-android-share-capability-p1`
  - `app-client-android-ad-sdk-pdp-p1`
- evidence_tier: single-project
- generation_profile: phase1-selected-batch

## 1. 采集范围

| 模块 | 路径 | 实际样本量 |
| --- | --- | --- |
| core-ui-kit | `core/core-ui-kit/src/main/...` | ~40 个 .kt + values/* xml |
| core-utils | `core/core-utils/src/main/...` | 2 个 .kt |
| capability:share | `core/capability/share/...` | 0 main src（占位脚手架） |
| capability:web | `core/capability/web/src/main/...` | 1 个 .kt |
| capability:react-native | `core/capability/react-native/src/main/...` | 13 个 .kt |
| capability:kaz-pdp | `core/capability/kaz-pdp/src/main/...` | 13 个 .kt |

实际深读样本（≤200 行 / 文件）：
- core-ui-kit：`HsTabLayout`、`HsLoadingRefreshHeader`、`CommonDialogFragment`、`viewext/ViewExt.kt`、`viewext/ClickExt.kt`、`res/values/colors.xml`、`res/values/attrs.xml`、`res/values/strings.xml`。
- core-utils：`string/StringExt.kt`、`evenbus/EventBusWrapper.kt`。
- capability:web：`CommonWebViewReachContainer.kt` + `AndroidManifest.xml`。
- capability:react-native：`bridge/NativeHsBridgeModule.kt`、`bridge/RnBridgePackage.kt`、`config/RnBundleConfig.kt`、`runtime/RnRuntimeInitializer.kt`、`container/RnContainerFragment.kt`（首 150 行）、`build.gradle`（首 60 行）。
- capability:share：`build.gradle.kts`、`AndroidManifest.xml`、目录结构枚举。
- capability:kaz-pdp：`PdpCenter.kt`、`redirect/RedirectDispatcher.kt`、`PdpCenterPopupFragment.kt`、`notification/PdpNotificationFragment.kt`（首 120 行）、`banner/PdpBannerFragment.kt`（首 120 行）、`build.gradle`。

## 2. 产物清单

```
g4-core-shared/
├── evidence/
│   ├── code-facts.md          (15 条 EV-APP-CLIENT-G4-*)
│   ├── positive-examples.md   (11 条 POS-APP-CLIENT-G4-*)
│   ├── forbidden-examples.md  (8 条 NEG-APP-CLIENT-G4-*)
│   └── legacy-compatible.md   (7 条 LEG-APP-CLIENT-G4-*)
├── standard-core-shared.md    (主规范，11 章)
├── ai-rules.md                (7 个分类，~22 条 AI-G4-*)
├── review-checklist.md        (7 章，~25 项)
├── pending-confirmation.md    (6 条 PENDING-APP-CLIENT-G4-*)
└── group-summary.md           (本文件)
```

## 3. 规则统计

主规范 `standard-core-shared.md` 中规则节统计：

| 类别 | 数量 | 包含规则 |
| --- | --- | --- |
| required（强制） | 12 | G4-UIKIT-001/-002/-003、G4-UTILS-001/-002、G4-WEB-001/-004、G4-RN-001/-002/-003/-004/-005/-006、G4-PDP-001/-002/-003 |
| forbidden（禁止） | 3 | G4-WEB-002、G4-WEB-003、G4-PDP-004 |
| recommended（建议） | 4 | G4-UIKIT-004/-005、G4-UTILS-003、G4-RN-007、G4-PDP-005 |
| pending | 3 | G4-WEB-005、G4-SHARE-001、G4-SHARE-002 |

满足要求："至少 3 条强制规则 + 2 条 FORBIDDEN（重点放在 web/jsbridge 安全）"——已超出（强制 12，FORBIDDEN 3，其中 2 条针对 WebView 安全）。

## 4. 与 batch PRD 的对齐情况

| Batch | 主要落点章节 | 状态 |
| --- | --- | --- |
| core-ui-kit-p1 | §3.1 ~ §3.5 | 已完成 |
| capability-web-jsbridge-p1 | §5.1 ~ §5.5 | 部分完成（实际实现位于 submodule，详见 PENDING-1） |
| rn-bridge-p1 | §6.1 ~ §6.7 | 已完成（覆盖 runtime / bundle / Bridge / 跳转 / 错误兜底） |
| share-capability-p1 | §7 | pending（模块为空脚手架，详见 PENDING-2） |
| ad-sdk-pdp-p1 | §8.1 ~ §8.5 | 已完成（埋点章节为 forbidden，详见 PENDING-3） |

## 5. 采集偏差与降级说明

- **share 模块降级**：源码缺失，整章标记 pending，AI 规则同步标 pending，review checklist 中也标记 pending。
- **web 模块部分降级**：capability:web 内仅有路由桥；WebView 安全 [FORBIDDEN] 规则按 PRD 要求保留，并在 §5.5 PENDING-G4-1 中说明生效范围依赖 `submodules/web` 的协同。
- **kaz-pdp 埋点 placeholder**：`recordView/recordClick` 为 TODO，规则用 forbidden 兜底"未上线前不私自接入"，同时在 PENDING-G4-3 中开放讨论。

## 6. 后续动作

1. 在用户 / owner 确认 PENDING-G4-1 ~ PENDING-G4-6 后，把 status 推进为 v0.2.0。
2. 与 `g1-bootstrap` / `g2-trade` / `g3-quotes` 三组规范交叉对齐：
   - Router 入口（`Router.startRedirect`）应在 g1 中已定义；本组 §5.4 / §6.5 / §8.2 引用之。
   - VLog / 日志策略与 g1 共享。
3. submodules/web 实际 WebView 实现的 evidence 采集需要新建 batch（如 `app-client-android-submodules-web-p1`），随后将 §5 中的 [FORBIDDEN] 规则与具体源码对齐。
4. share / 新埋点方案接入后回看本组规范，将 `pending` 节升级为 `accepted`。
