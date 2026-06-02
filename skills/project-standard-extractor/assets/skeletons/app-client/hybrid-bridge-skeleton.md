---
doc_id: "app-client-hybrid-bridge-standard"
title: "App 跨端 Hybrid 桥接规范（H5 / RN × 原生壳）"
domain: "app-client"
sub_domain: "hybrid-bridge"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags:
  - "app-client"
  - "hybrid-bridge"
  - "h5"
  - "react-native"
  - "turbomodule"
  - "native-bridge"
---

# App 跨端 Hybrid 桥接规范（H5 / RN × 原生壳）

<!-- 写作说明（生成时删除）
- 本骨架适用于"部分项目对接了 H5 / React Native 跨端"的场景，与 KMP × Clean 主架构并列存在
- 三个核心抽象必须出现且职责单一：
  1. 完整 bundle 多入口   —— 负责页面加载（H5 URL / RN bundle entry）
  2. TurboModule         —— 负责 JS ↔ Native 通信（RN 侧）
  3. NativeBridge        —— 负责 JS 侧调用收口（H5 / RN 共用统一 facade）
- §3 推荐目录必须按这三个抽象切分，不得混入业务模块
- §6 必须出现 P0 / FORBIDDEN 至少各一条，覆盖"私自暴露 native API"、"bundle 入口被业务硬编码"
-->

## 1. 规范定位 [{{activation_state_section_1}}]

{{positioning_text}}

- 子领域：`hybrid-bridge`
- 适用场景：原生 App 嵌入 H5 容器（WKWebView / WebView）或 React Native 容器（RCTRootView / ReactRootView），通过统一桥接层与 JS 侧互通
- 与 KMP × Clean 主架构关系：Hybrid Bridge 作为 **Presentation 层的另一种壳实现**，依赖同一套 KMP shared Domain / Data 能力；JS 侧业务最终还是经 NativeBridge → 原生 ViewModel/UseCase → KMP shared
- 激活态：`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**

- **完整 bundle 多入口**：H5 多页应用的 URL 路由表 / RN 多 bundle 入口注册（main / mini-app-A / mini-app-B 等）、bundle 加载策略（远端拉取、本地预置、热更新）
- **TurboModule**：RN 侧 JSI 同步 / 异步 Native 能力暴露，Codegen spec、模块注册、参数序列化、错误码映射
- **NativeBridge**：JS 侧调用原生能力的统一收口（H5 端基于 `window.NativeBridge` / RN 端基于 NativeModules + TurboModules 包一层），鉴权 / 限流 / 审计
- 容器生命周期治理（WebView / RootView 创建、销毁、内存回收）
- JS Bundle 完整性校验 / 签名 / 增量更新策略

**不应承载**

- 业务逻辑实现（Domain / Data 层下沉到 KMP `commonMain`，Bridge 只做协议转换）
- UI 渲染细节（H5 由 Web 端渲染、RN 由 RN 渲染器渲染，原生壳只持容器）
- 与具体业务页面强耦合的桥方法（必须按能力分类聚合，不允许 `*PageBridge`）

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
hybrid/                              — 跨端 Hybrid 桥接模块（Android / iOS 各一份镜像目录）
├── bundle/                          — 完整 bundle 多入口（页面加载）
│   ├── registry/                    — Bundle 入口注册表（id ↔ entry / version / signer）
│   ├── loader/                      — Bundle 加载器（远端 / 本地 / 缓存）
│   ├── updater/                     — 增量 / 全量更新策略
│   └── verifier/                    — 签名与完整性校验
├── turbomodule/                     — RN TurboModule 实现
│   ├── spec/                        — Codegen .ts / Flow spec
│   ├── modules/                     — 各 TurboModule 实现（按能力分包）
│   └── registry/                    — TurboModulePackage / Provider
├── nativebridge/                    — JS 侧调用收口（H5 / RN 共用 facade）
│   ├── api/                         — 按能力分类的 Bridge API 接口（DeviceApi / AuthApi / TrackApi）
│   ├── dispatcher/                  — 调用分发 + 鉴权 + 审计
│   ├── error/                       — 统一错误码与 ErrorEnvelope
│   └── webview/                     — H5 端 WebView 注入（Android JsInterface / iOS WKScriptMessageHandler）
└── lifecycle/                       — 容器与 RootView 生命周期管理
```

## 4. 分层规则 [{{activation_state_section_4}}]

**三抽象职责矩阵**

| 抽象 | 单一职责 | 输入 | 输出 | 禁止承担 |
| --- | --- | --- | --- | --- |
| Bundle 多入口 | 页面加载（H5 URL / RN bundle entry） | bundle_id / entry_name | 加载完成的容器（WebView / RCTRootView） | JS ↔ Native 通信、业务逻辑 |
| TurboModule | RN 侧 JS ↔ Native 通信 | RN spec 调用参数 | spec 定义的返回类型 / Promise | H5 调用、bundle 加载、业务逻辑 |
| NativeBridge | JS 侧调用收口（H5 + RN 统一 facade） | { api, method, params, callbackId } | { code, data, message } | bundle 加载、UI 渲染、业务逻辑 |

**调用链**

```text
JS 侧调用                              原生壳侧
─────────────────────                ─────────────────────
H5: window.NativeBridge.call(...)
RN: NativeModules.XxxModule.call(...)
                       │
                       ▼
                NativeBridge Dispatcher（鉴权 / 审计 / 限流）
                       │
                       ▼
              ┌────────┴────────┐
              ▼                 ▼
         TurboModule           WebView Handler
          实现                  实现（Android JsInterface /
              │                  iOS WKScriptMessageHandler）
              └────────┬────────┘
                       ▼
              KMP shared UseCase / Repository（Clean Domain 层）
```

**调用方向铁律**

- JS → Native：必须经 `NativeBridge.dispatcher`，**禁止** JS 直接调用 TurboModule 或 WebView Handler 的具体方法（必须经 facade）。
- Native → JS：通过 `NativeBridge.emit(event, payload)` 派发；**禁止** 在 TurboModule / WebView Handler 内部直接 `webView.evaluateJavascript("...")`。
- Bundle Loader 与 NativeBridge 解耦：Loader 不感知 Bridge API，Bridge 不感知具体 bundle 来源。

## 5. 命名规范 [{{activation_state_section_5}}]

- TurboModule 类名后缀 `*TurboModule`，spec 文件 `Native*Spec.ts` / `Native*Spec.flow.js`
- NativeBridge API 接口后缀 `*Api`（按能力，不按页面）：`DeviceApi` / `AuthApi` / `TrackApi`，**禁止** `OrderListPageApi` 这类按页面命名
- Bundle 入口 id：`<businessLine>.<feature>@<version>`（如 `billing.topup@1.4.2`）
- 错误码：`BRIDGE_<CATEGORY>_<CODE>`，如 `BRIDGE_AUTH_TOKEN_EXPIRED` / `BRIDGE_BUNDLE_VERIFY_FAILED`
- WebView JsInterface 名 `NativeBridge`（统一），iOS WKScriptMessageHandler `name = "nativeBridge"`

## 6. 核心规则 [{{activation_state_section_6}}]

### P0 JS 侧调用必须经 NativeBridge 唯一收口

> level: P0 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**适用范围**

- `hybrid/turbomodule/**`、`hybrid/nativebridge/**`、H5 容器内 JS 注入

**强制规则**

1. JS 侧（H5 / RN）所有原生能力调用必须通过 `NativeBridge.call({ api, method, params })`，由 `NativeBridge.dispatcher` 鉴权 / 审计 / 限流后再分发到 TurboModule 或 WebView Handler。
2. TurboModule 与 WebView Handler 实现必须**不直接对外暴露** public 方法被业务调用——它们是 Dispatcher 的下游。
3. 所有跨端调用必须有 `traceId` 透传，落入审计日志。

**禁止事项**

- 禁止 RN JS 侧直接 `NativeModules.XxxModule.foo(...)` 跳过 Bridge facade（必须包裹一层 `NativeBridge.call({ api: 'xxx', method: 'foo' })`）。
- 禁止 H5 端通过 JsInterface / WKScriptMessageHandler 暴露除 `nativeBridge` 之外的全局对象。
- 禁止 TurboModule 内部直接发起业务逻辑（必须委托 KMP shared UseCase）。

**反例**

```typescript
// 反例（RN）：JS 直接调 NativeModules，绕过 NativeBridge
import { NativeModules } from 'react-native';
NativeModules.BillingModule.topup(100); // ❌ 应 NativeBridge.call({ api: 'billing', method: 'topup', params: { amount: 100 } })
```

```kotlin
// 反例（Android WebView）：暴露多个 JsInterface
webView.addJavascriptInterface(BillingJsBridge(), "Billing")   // ❌ 仅允许 "NativeBridge"
webView.addJavascriptInterface(TrackJsBridge(), "Track")        // ❌ 应统一收口
```

**正例**

```typescript
// 正例：JS 侧统一 facade
NativeBridge.call({ api: 'billing', method: 'topup', params: { amount: 100 } })
  .then(({ code, data }) => { /* ... */ });
```

**AI 生成代码要求**

1. AI 生成新 Bridge 能力时，必须新增 `*Api` 接口 + Dispatcher 注册项；TurboModule / WebView Handler 仅作为内部实现。
2. AI 生成 JS 调用代码必须使用 `NativeBridge.call(...)`，**禁止** 直接 `NativeModules.*` / `window.*JsInterface`。

**Code Review 检查项**

- [ ] WebView JsInterface 仅注册 `NativeBridge` 一个
- [ ] TurboModule 未暴露给 JS 业务直接调用
- [ ] 所有 Bridge 调用含 traceId

**Evidence**

- `evidence/code-facts.md「EV-CLIENT-{{N}}」`

### P1 完整 bundle 多入口必须经注册表加载

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**适用范围**

- `hybrid/bundle/**`

**强制规则**

1. 所有 bundle 入口必须登记到 `bundle/registry/`，含 `bundleId` / `entry` / `version` / `signer` / `loadStrategy`。
2. Bundle 加载必须经 `bundle/loader/` 统一入口，**禁止** 业务页面硬编码 `WKWebView.load(URLRequest(...))` / `ReactRootView(bridge: bridge, moduleName: "...")`。
3. Bundle 加载前必须经 `bundle/verifier/` 签名校验；校验失败必须 fail-fast，不得降级到不校验。

**禁止事项**

- 禁止跳过 registry 直接拼接 URL / bundle path 加载。
- 禁止把"是否校验签名"作为 release build 的可选项；release build **必须** 校验。

**反例**

```kotlin
// 反例：Activity 内直接硬编码 H5 URL
class BillingActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        webView.loadUrl("https://cdn.example.com/billing/index.html?ts=$ts") // ❌ 应走 BundleLoader.load("billing.topup@1.4.2")
    }
}
```

### P1 TurboModule spec 必须 Codegen 派生

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**适用范围**

- `hybrid/turbomodule/spec/**`、`hybrid/turbomodule/modules/**`

**强制规则**

1. 所有 TurboModule 必须有对应的 `Native*Spec.ts` / `Native*Spec.flow.js` 并通过 RN Codegen 生成 Android（`*Spec.java`）/ iOS（`*Spec.h`）契约头。
2. Native 实现类必须 `extends`/`implements` Codegen 产出的 Spec 接口，**禁止** 手写 `@ReactMethod` / `RCT_EXPORT_METHOD` 不走 spec。
3. spec 字段类型必须使用 RN Codegen 支持的子集（`Int32` / `Double` / `String` / `Boolean` / `Object` / `Promise<T>`）。

### FORBIDDEN JS 侧获得任意 native 反射能力

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ **FORBIDDEN**：任何 Bridge API 不得提供"按字符串调用任意类 / 方法"的反射能力（如 `invokeNativeMethod(className, method, args)`），即便仅用于调试。

**反例**

```kotlin
// 反例：通用反射 Bridge，攻击面极大
class DebugBridge {
    @ReactMethod
    fun invoke(className: String, method: String, args: ReadableArray) {
        Class.forName(className).getMethod(method, ...).invoke(...)  // ❌
    }
}
```

### FORBIDDEN Bundle 加载跳过签名校验

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ **FORBIDDEN**：`release` build 中 bundle 加载流程包含 `if (BuildConfig.DEBUG || skipVerify) { ... }` 类型分支跳过 `bundle/verifier/`。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
H5 / RN JS 侧
    NativeBridge.call({ api, method, params, traceId })
        ↓
原生壳 NativeBridge.dispatcher（鉴权 / 限流 / 审计）
        ↓
    ┌───┴────────────────────┐
    ▼                        ▼
TurboModule（RN）        WebView Handler（H5）
    ↓                        ↓
KMP shared UseCase（commonMain/domain/）
    ↓
KMP shared Repository（commonMain/data/）
    ↓
DataSource expect ↔ androidMain/iosMain actual

Bundle 加载链路：
业务请求 → BundleLoader.load(bundleId) → BundleRegistry 解析 entry/version
        → BundleVerifier 校验签名 → 容器（WebView / RCTRootView）渲染
```

## 8. 平台差异 [{{activation_state_section_8}}]

| 维度 | Android | iOS |
| --- | --- | --- |
| H5 容器 | WebView / WebViewClient | WKWebView / WKNavigationDelegate |
| H5 注入 | `addJavascriptInterface(NativeBridge, "NativeBridge")` | `WKUserContentController.add(handler, name: "nativeBridge")` |
| RN 容器 | `ReactRootView` / `ReactNativeHost` | `RCTRootView` / `RCTBridge` |
| TurboModule 注册 | `TurboReactPackage.getModule(name, ctx)` | `RCTAppDelegate` `TurboModule provider` |
| Bundle 存储 | App 私有目录 + EncryptedFile（敏感场景） | App Sandbox + DataProtection |

## 9. 错误模型 [{{activation_state_section_9}}]

- 统一错误结构：`{ code: "BRIDGE_<CATEGORY>_<NAME>", message, data?, traceId }`
- 类别枚举：
  - `BRIDGE_AUTH_*`（鉴权 / 限流）
  - `BRIDGE_PARAM_*`（参数校验）
  - `BRIDGE_BUNDLE_*`（bundle 加载 / 校验）
  - `BRIDGE_NATIVE_*`（原生能力执行）
- TurboModule 必须以 `Promise.reject(new Error(JSON.stringify({ code, message }))) ` 返回结构化错误，**禁止** 直接抛 native exception 字符串

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 新增 JS ↔ Native 能力时，必须同时产出：① `Native*Spec`（RN）或 H5 注入 spec；② `*Api` 接口 + Dispatcher 注册；③ TurboModule / WebView Handler 实现；④ KMP shared UseCase 委托；④ 错误码定义
- AI 生成 RN JS 调用代码必须使用 `NativeBridge.call(...)`，**禁止** 直接 `NativeModules.*`
- AI 生成 H5 注入代码必须使用统一 `nativeBridge` 名称，不得新增 JsInterface / ScriptMessageHandler
- Bundle 加载代码必须经 `BundleLoader.load(bundleId)`，**禁止** 直接 `loadUrl` / `RCTRootView(...moduleName:)`

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] WebView JsInterface 仅 `NativeBridge` 一个；WKScriptMessageHandler 仅 `nativeBridge` 一个
- [ ] 所有 TurboModule 都有 Codegen spec，无手写 `@ReactMethod` / `RCT_EXPORT_METHOD` 越过 spec
- [ ] 所有 bundle 入口都登记于 `bundle/registry/`，业务无硬编码 URL / bundle path
- [ ] release build bundle 加载链路中存在 verifier 调用，无 `skipVerify` 分支
- [ ] 所有 Bridge 调用含 traceId 并落审计日志
- [ ] Bridge API 按能力（`*Api`）切分，无按页面命名（`*PageApi`）

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-CLIENT-{{N}}` | `hybrid/bundle/**` | {{core_observation}} | {{confidence}} |
| `EV-CLIENT-{{N}}` | `hybrid/turbomodule/**` | {{core_observation}} | {{confidence}} |
| `EV-CLIENT-{{N}}` | `hybrid/nativebridge/**` | {{core_observation}} | {{confidence}} |
