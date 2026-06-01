---
doc_id: "app-client-kmp-shared-standard"
title: "App-Client KMP Shared 开发规范"
domain: "app-client"
sub_domain: "kmp-shared"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "app-client-kmp-shared-biz-common-contract-p1, app-client-kmp-shared-biz-common-bizcommon-p1"
evidence_tier: "single-project"
last_reviewed: "2026-05-26"
generation_profile: "phase1-selected-batch"
tags: ["app-client", "kmp-shared", "kotlin-multiplatform"]
---

# App-Client KMP Shared 开发规范

适用范围：基于 `submodules/biz-common/{contract, bizcommon}` 抽取的 Kotlin Multiplatform shared 层规范。本规范覆盖契约接口模块（contract）与业务通用模块（bizcommon）两类 KMP shared module 的命名、分层、`expect/actual`、构建与 ObjC interop 行为。

`status: draft` —— 仅在仓库内单项目证据上得出，需在更多 KMP 模块（如 `submodules/biz-search`、`modules/core/*`、`hscomponents`）确认后再升级。

## 1. 技术栈

- 语言：Kotlin Multiplatform，Kotlin 版本统一由 `gradle/libs.versions.toml` 管理，AndroidTarget JVM target = 17。
- 构建插件：`kotlinMultiplatform`、`kotlinCocoapods`、`androidLibrary`、`kotlinSerialization`、`maven-publish`；按需追加 `mokoResources`、`kmpRetrofit`、`atomicfu`、`ksp`、`co.touchlab.skie`、`com.hs.kmp.gradle.i18n.plugin`。
- 协程 / 反应式：`kotlinx.coroutines` + `kotlinx.coroutines.flow`；并发原语用 `kotlinx.atomicfu.locks`。
- 网络：内部 `com.hs.kmp.datacenter.HsSuspendRequest`、`com.hs.kmp.baselib.net.*`、ktor 客户端（仅 commonMain `api(...)` 透传）。
- 序列化：`kotlinx.serialization.json` + 内部 `JsonUtils`。
- iOS interop：`co.touchlab.skie` + `kotlin.experimental.ExperimentalObjCRefinement` + `kotlin.native.HiddenFromObjC`。
- 测试：`kotlin.test`（commonTest）/ `junit`（android）/ `mockk-android`、`mockk-agent`。

## 2. KMP 模块分层

```
contract  ──depends-on──►  bizcommon  ──depends-on──►  modules/* / 平台 actual
   ▲                                                       ▲
   │                                                       │
   只暴露空 / 极简接口                              核心业务能力
   不透传第三方依赖                                  通过 api() 主动透传
```

- contract 模块（`com.hs.kmp.common.provider`）：定义对外契约接口（如 `IQuotesProvider` / `IAccountProvider` / `IOrderProvider`），不放具体实现。commonMain dependencies 仅 `implementation(project(":bizcommon"))`，不 `api(...)` 透传任何第三方依赖。【evidence: EV-APP-CLIENT-G5-001 / EV-APP-CLIENT-G5-010 / POS-APP-CLIENT-G5-003 / POS-APP-CLIENT-G5-006】
- bizcommon 模块（`com.hs.kmp.biz.*`）：放置事件分发、远程配置、用户作用域、工具扩展、通用业务模型；通过 `api(libs.xxx)` 把 ktor / kotlinx-serialization / moko-resources 等基础设施透传给业务调用方。【evidence: EV-APP-CLIENT-G5-001 / EV-APP-CLIENT-G5-010】
- 平台 actual：放在对应 sourceSet（`androidMain`、`iosMain`），同包路径，文件以 `.android.kt` / `.ios.kt` 后缀。【evidence: EV-APP-CLIENT-G5-003 / EV-APP-CLIENT-G5-007】

### 2.1 模块定位规则

【rule-id: KMP-LAYER-001】【severity: 强制】【evidence: EV-APP-CLIENT-G5-001, POS-APP-CLIENT-G5-006】
contract 模块只允许包含：
- 对外契约接口（命名 `I + 业务名 + Provider` / `I + 业务名 + Service`）。
- 跨模块共享的纯 Kotlin 数据类型（仅当其他业务模块也需要时；优先放 `:modules:core:types`）。
不允许放置：业务实现、网络调用、平台依赖。

【rule-id: KMP-LAYER-002】【severity: 强制】【evidence: EV-APP-CLIENT-G5-010, POS-APP-CLIENT-G5-003】
contract 模块的 `commonMain.dependencies` 不允许使用 `api(...)`，避免向下游透传任何依赖。基础设施统一从 bizcommon 暴露。

## 3. `expect/actual` 规范

【rule-id: KMP-EXPECT-001】【severity: 强制】【evidence: EV-APP-CLIENT-G5-003 / EV-APP-CLIENT-G5-007 / POS-APP-CLIENT-G5-001】
`expect` 与所有 `actual` 必须使用同一包路径。文件命名规范：
- commonMain：`<Name>.kt`
- androidMain：`<Name>.android.kt`
- iosMain：`<Name>.ios.kt`

【rule-id: KMP-EXPECT-002】【severity: 强制】【evidence: NEG-APP-CLIENT-G5-004 / POS-APP-CLIENT-G5-002】
`expect` 函数 / 类的签名只允许使用：
- `kotlin.*` 标准类型（含 `String` / `Map` / `List` / `Result` / 基本数值类型）。
- `kotlinx.*` 跨平台库类型。
- 仓库内自定义跨平台类型（commonMain 中已声明）。

禁止在 `expect` 签名出现 `android.*` / `androidx.*` / `platform.*` / `java.*` / `apple framework` 类型。

【rule-id: KMP-EXPECT-003】【severity: 强制】【evidence: EV-APP-CLIENT-G5-003 / POS-APP-CLIENT-G5-002】
`expect` 优先使用 `internal` 可见性，仅当确需对模块外暴露时才用 `public`；`actual` 的可见性 / 返回类型 / 可空性必须严格匹配 `expect`。

【rule-id: KMP-EXPECT-004】【severity: 推荐】【evidence: EV-APP-CLIENT-G5-003 / POS-APP-CLIENT-G5-001】
对极简平台探针（如 `platform()` / `getDeviceId()`），优先选 `expect fun` 而非 `expect class`，便于内联到现有 object / 工具类。

## 4. commonMain 编码约束

【rule-id: KMP-COMMON-001】【severity: 强制 / FORBIDDEN】【evidence: EV-APP-CLIENT-G5-009 / NEG-APP-CLIENT-G5-001 / NEG-APP-CLIENT-G5-002 / NEG-APP-CLIENT-G5-003】
**FORBIDDEN：** commonMain 文件中禁止 import 以下包前缀：
- `android.*`
- `androidx.*`
- `java.util.concurrent.*` 及其它 `java.*` 专属包
- `platform.*`（iOS-only）
- 任何 Apple framework 直接引用

唯一允许跨平台之外的 import：`kotlin.*` / `kotlinx.*` / 内部 `com.hs.kmp.*` / 经评估通过的第三方 KMP 库（如 `co.touchlab.skie`、`com.github.kittinunf.result`、`com.hs.kmp.baselib.*`）。

【rule-id: KMP-COMMON-002】【severity: 强制】【evidence: EV-APP-CLIENT-G5-005 / POS-APP-CLIENT-G5-005】
并发原语：commonMain 中需要锁 / volatile 时，使用：
- `kotlinx.atomicfu.locks.reentrantLock` + `withLock`。
- `kotlin.concurrent.Volatile`。
- `kotlinx.coroutines.sync.Mutex`（异步场景）。

不允许使用 `java.util.concurrent.locks.*` / `synchronized(...)` 在 commonMain 出现。

【rule-id: KMP-COMMON-003】【severity: 推荐】【evidence: EV-APP-CLIENT-G5-006 / POS-APP-CLIENT-G5-004】
当 commonMain 业务逻辑确需"宿主侧能力"（用户态读写、原生缓存、设备信息）时，通过"可空 lambda 注入"模式实现：

```kotlin
// commonMain
class HSUser {
    companion object {
        var getValueOrDefault: ((key: String?, default: Any?) -> Any?)? = null
        var remove: ((key: String?) -> Unit)? = null
    }
}
```

宿主侧（Android Application / iOS AppDelegate）启动时注入实现。优点：避免 commonMain 引入平台类型，且不需要为每个能力都写一对 `expect/actual`。

## 5. androidMain / iosMain actual 规范

【rule-id: KMP-PLATFORM-001】【severity: 强制】【evidence: EV-APP-CLIENT-G5-007 / POS-APP-CLIENT-G5-001】
平台 actual 文件使用 `<Name>.android.kt` / `<Name>.ios.kt` 命名，与 commonMain `<Name>.kt` 同包路径。`actual class` 形态可不带后缀（如 `TradeLoginUIContextImpl.kt`），但需在 `androidMain/.../uiContext/` 与 `iosMain/.../uiContext/` 各放一份。【evidence: EV-APP-CLIENT-G5-004】

【rule-id: KMP-PLATFORM-002】【severity: 推荐】【evidence: EV-APP-CLIENT-G5-004】
平台 actual 实现允许引入大量 platform API（`android.content.Context` / `androidx.lifecycle.*` / `platform.UIKit.*`），但必须满足两个约束：
- 实现签名严格匹配 commonMain 的 `expect`；新增字段 / 方法应尽量限制为平台内私有。
- iOS actual 不允许直接调用 Android 类型，反之亦然（同一个 sourceSet 内不可能引入对端 SDK，编译保证）。

【rule-id: KMP-PLATFORM-003】【severity: 推荐】【evidence: EV-APP-CLIENT-G5-005 / LEG-APP-CLIENT-G5-008】
iOS / Android 在生命周期感知（`Lifecycle`）、UI Context 等"两端实现差异较大"的能力上：commonMain 只提供"骨架接口"（参考 `EventDispatcher`）；具体的 `observe(LifecycleOwner)` / `repeatOnLifecycle` 类扩展放在 androidMain；iOS 端使用 `MainScope()` / Combine bridge 自行实现。

## 6. KMP 构建配置规范

【rule-id: KMP-BUILD-001】【severity: 强制】【evidence: EV-APP-CLIENT-G5-002】
KMP shared module 必须按以下基线声明 target：

```kotlin
kotlin {
    androidTarget {
        compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
        publishLibraryVariants("release")
        withSourcesJar(publish = true)
    }
    iosX64()
    iosArm64()
    iosSimulatorArm64()
    cocoapods { /* baseName / pod name 与模块语义对齐 */ }
}
```

【rule-id: KMP-BUILD-002】【severity: 推荐】【evidence: LEG-APP-CLIENT-G5-001 / LEG-APP-CLIENT-G5-002】
新增模块优先依赖 Kotlin 1.9+ Default Hierarchy Template，**不要**写 `iosMain { dependsOn(commonMain.get()); iosX64Main.dependsOn(this); ... }`。已有模块的 legacy 写法保留，不强制重写。

【rule-id: KMP-BUILD-003】【severity: 强制】【evidence: EV-APP-CLIENT-G5-002 / EV-APP-CLIENT-G5-008】
iOS framework 配置规范：
- `framework { baseName = "<HSXxxKit>"; isStatic = true }`。
- `cocoapods { name = "HSXxxKit"; ios.deploymentTarget = "13.0"; ... }`。
- 新模块 `name` 与 `baseName` 保持一致；contract / bizcommon 等历史不一致情况见 LEG-APP-CLIENT-G5-004，不做批量调整。
- 必须配置 `binaryOptions["bundleId"]`，命名采用 `com.hs.kmp.<KitName>` 形式（参考 `submodules/biz-common/bizcommon/build.gradle.kts:168-170`）。

【rule-id: KMP-BUILD-004】【severity: 强制】【evidence: LEG-APP-CLIENT-G5-005】
maven publish 的凭据**禁止**明文写在 `build.gradle.kts`。必须使用 `credentials(PasswordCredentials::class.java)`，账号密码通过 `gradle.properties` 或环境变量注入。

【rule-id: KMP-BUILD-005】【severity: 推荐】【evidence: EV-APP-CLIENT-G5-002 / EV-APP-CLIENT-G5-010】
依赖暴露策略：
- contract `commonMain` 仅 `implementation(project(":bizcommon"))`，不 `api(...)`。
- bizcommon `commonMain` 必要的基础设施使用 `api(libs.xxx)` 透传（ktor、kotlinx-serialization、moko-resources、内部 baselib / datacenter / protos）。
- bizcommon `commonMain` 内部 helper 类、测试 mock 等使用 `implementation(...)`。

## 7. ObjC / Swift Interop 规范

【rule-id: KMP-IOSINTEROP-001】【severity: 推荐】【evidence: EV-APP-CLIENT-G5-008 / POS-APP-CLIENT-G5-007】
不希望对外暴露的 KMP 内部 API（如 `object API` 中的 suspend 网络方法），统一使用：

```kotlin
@OptIn(kotlin.experimental.ExperimentalObjCRefinement::class)
@kotlin.native.HiddenFromObjC
object API { /* ... */ }
```

【rule-id: KMP-IOSINTEROP-002】【severity: 推荐】【evidence: POS-APP-CLIENT-G5-007】
跨端 SharedFlow / StateFlow 暴露给 Swift 时，决定是否走 skie FlowInterop 默认转换：
- 想由 Swift 端用 `AsyncSequence` / Combine：保留默认。
- 想阻止 Swift 端直接消费内部 SharedFlow：标 `@FlowInterop.Disabled`，并提供 wrapper 方法。

## 8. AI 生成规则（汇总）

> 详见 `ai-rules.md`，本节仅列出关键 ID。

- AI-RULE-KMP-COMMON-001：commonMain 不允许 import `android.*` / `androidx.*` / `platform.*` / `java.util.concurrent.*`。
- AI-RULE-KMP-EXPECT-001：`expect` 签名禁用平台类型；`actual` 严格匹配可见性 / 类型 / 可空性。
- AI-RULE-KMP-FILE-001：`<Name>.kt` / `<Name>.android.kt` / `<Name>.ios.kt` 三段对齐，包路径相同。
- AI-RULE-KMP-CONTRACT-001：contract 模块 commonMain 不允许 `api(...)`，不允许放业务实现。
- AI-RULE-KMP-BUILD-001：新模块 androidTarget JVM=17、`iosX64/iosArm64/iosSimulatorArm64` 三件套、`isStatic = true`、cocoapods deploymentTarget 13.0。
- AI-RULE-KMP-LOCKS-001：commonMain 用 `kotlinx.atomicfu.locks` / `kotlin.concurrent.Volatile` / `kotlinx.coroutines.sync.Mutex`，禁止 `java.util.concurrent.locks.*`。
- AI-RULE-KMP-INJECT-001：commonMain 反向接入宿主能力时，使用可空 lambda（`((...) -> ...)?`）注入；不直接 import 平台类型。
- AI-RULE-KMP-INTEROP-001：不对 ObjC 暴露的内部 KMP API 加 `@HiddenFromObjC`。
- AI-RULE-KMP-PUBLISH-001：禁止明文凭据，使用 `PasswordCredentials`。

## 9. Code Review 检查项（汇总）

> 详见 `review-checklist.md`。重点：commonMain import 检查、`expect/actual` 三段对齐、contract 模块依赖纯净度、locks / 并发原语跨平台、HiddenFromObjC、publish credentials。

## 10. Evidence 参考表

| 章节 | 关键 evidence id |
| --- | --- |
| 模块分层 | EV-APP-CLIENT-G5-001、EV-APP-CLIENT-G5-010、POS-APP-CLIENT-G5-003、POS-APP-CLIENT-G5-006、NEG-APP-CLIENT-G5-006 |
| `expect/actual` | EV-APP-CLIENT-G5-003、EV-APP-CLIENT-G5-004、EV-APP-CLIENT-G5-007、POS-APP-CLIENT-G5-001、POS-APP-CLIENT-G5-002、NEG-APP-CLIENT-G5-004、NEG-APP-CLIENT-G5-005、NEG-APP-CLIENT-G5-007 |
| commonMain 约束 | EV-APP-CLIENT-G5-005、EV-APP-CLIENT-G5-006、EV-APP-CLIENT-G5-009、POS-APP-CLIENT-G5-004、POS-APP-CLIENT-G5-005、POS-APP-CLIENT-G5-007、NEG-APP-CLIENT-G5-001、NEG-APP-CLIENT-G5-002、NEG-APP-CLIENT-G5-003、NEG-APP-CLIENT-G5-008 |
| 平台 actual | EV-APP-CLIENT-G5-004、EV-APP-CLIENT-G5-005、LEG-APP-CLIENT-G5-008 |
| 构建配置 | EV-APP-CLIENT-G5-002、EV-APP-CLIENT-G5-008、EV-APP-CLIENT-G5-010、LEG-APP-CLIENT-G5-001、LEG-APP-CLIENT-G5-002、LEG-APP-CLIENT-G5-003、LEG-APP-CLIENT-G5-004、LEG-APP-CLIENT-G5-005 |
| ObjC interop | EV-APP-CLIENT-G5-008、POS-APP-CLIENT-G5-002、POS-APP-CLIENT-G5-007 |
