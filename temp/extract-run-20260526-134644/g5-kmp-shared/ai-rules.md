---
doc_id: "app-client-kmp-shared-ai-rules"
title: "App-Client KMP Shared AI 生成规则"
domain: "app-client"
sub_domain: "kmp-shared"
doc_type: "ai-rules"
version: "v0.1.0"
status: "draft"
source_batch: "app-client-kmp-shared-biz-common-contract-p1, app-client-kmp-shared-biz-common-bizcommon-p1"
generation_profile: "phase1-selected-batch"
last_reviewed: "2026-05-26"
---

# AI 生成规则 — KMP Shared

供 AI（Cursor / Claude Code / Copilot）在 KMP shared module 自动生成 / 改造代码时遵守。每条规则附 evidence 引用。所有规则的"violation 处置"为：拒绝生成 / 在 PR 中标红，并提示修正方向。

## AI-RULE-KMP-COMMON-001 — commonMain 平台 import 禁止清单

**when:** 生成 / 修改 `**/src/commonMain/**/*.kt` 文件。
**must not:** import 任何以下前缀：`android.*`、`androidx.*`、`platform.*`、`java.*`、`apple.*`、`UIKit.*`、`objc.*`。
**alternative:** 把平台类型留在 `androidMain` / `iosMain` actual；commonMain 用基础类型 / lambda 反向桥接。
**evidence:** EV-APP-CLIENT-G5-009、NEG-APP-CLIENT-G5-001、NEG-APP-CLIENT-G5-002、NEG-APP-CLIENT-G5-003、NEG-APP-CLIENT-G5-008。

## AI-RULE-KMP-COMMON-002 — commonMain 并发原语

**when:** commonMain 需要锁、volatile、原子变量。
**must:** 使用 `kotlinx.atomicfu.locks.reentrantLock` + `withLock`，`kotlin.concurrent.Volatile`，`kotlinx.coroutines.sync.Mutex`，`kotlinx.atomicfu.atomic`。
**must not:** `java.util.concurrent.locks.*`、`synchronized {}` 块（KMP common 不允许）、`@kotlin.jvm.Volatile`（仅 JVM）。
**evidence:** EV-APP-CLIENT-G5-005、POS-APP-CLIENT-G5-005、NEG-APP-CLIENT-G5-003。

## AI-RULE-KMP-EXPECT-001 — `expect/actual` 签名匹配

**when:** 生成 `expect fun` / `expect class` 与对应 `actual`。
**must:**
- 包路径完全相同。
- 可见性、参数列表、返回类型、可空性、泛型签名严格匹配。
- 优先使用 `internal` 可见性。
- 返回类型仅使用跨平台基础类型（`String` / `Map<String, Any>?` / 内部跨平台类型）。
**must not:** 在 `expect` 签名出现平台类型（`android.os.Bundle`、`platform.UIKit.UIDevice` 等）。
**evidence:** EV-APP-CLIENT-G5-003、POS-APP-CLIENT-G5-001、POS-APP-CLIENT-G5-002、NEG-APP-CLIENT-G5-004、NEG-APP-CLIENT-G5-005、NEG-APP-CLIENT-G5-007。

## AI-RULE-KMP-FILE-001 — 平台文件命名

**when:** 创建 `expect/actual` 文件。
**must:**
- commonMain 文件命名 `<Name>.kt`。
- androidMain 文件命名 `<Name>.android.kt`。
- iosMain 文件命名 `<Name>.ios.kt`。
- 三方包路径完全一致。
- `actual class` 形态可省略 `.android` / `.ios` 后缀，但仍同包路径，每端各一份（参考 `TradeLoginUIContextImpl.kt`）。
**evidence:** EV-APP-CLIENT-G5-004、EV-APP-CLIENT-G5-007、POS-APP-CLIENT-G5-001。

## AI-RULE-KMP-CONTRACT-001 — Contract 模块依赖洁净度

**when:** 生成 / 修改 contract 模块（`com.hs.kmp.common.provider` 命名空间下的 build.gradle.kts 与源文件）。
**must:**
- contract `commonMain.dependencies` 只能 `implementation(project(":bizcommon"))` 或 `implementation(project(":modules:..."))`，不允许 `api(...)`。
- contract commonMain 文件只能放 `interface I + 业务名 + Provider` / `Service`，或纯数据类。
**must not:** 在 contract commonMain 写网络调用、平台依赖、复杂业务逻辑。
**evidence:** EV-APP-CLIENT-G5-001、EV-APP-CLIENT-G5-010、POS-APP-CLIENT-G5-003、POS-APP-CLIENT-G5-006、NEG-APP-CLIENT-G5-006。

## AI-RULE-KMP-BUILD-001 — 新增 KMP module 构建基线

**when:** 创建新的 KMP shared module。
**must:**
- 插件链至少：`kotlinMultiplatform`、`kotlinCocoapods`、`androidLibrary`、`kotlinSerialization`、`maven-publish`。
- `androidTarget { compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }; publishLibraryVariants("release"); withSourcesJar(publish = true) }`。
- iOS target 三件套：`iosX64()`、`iosArm64()`、`iosSimulatorArm64()`。
- `cocoapods { ios.deploymentTarget = "13.0"; framework { isStatic = true } }`。
- 必须配置 `binaryOptions["bundleId"] = "com.hs.kmp.<KitName>"`。
**must not:** 写 `iosMain { dependsOn(commonMain.get()); iosX64Main.dependsOn(this); ... }`（Kotlin 1.9+ Hierarchy Template 已自动生成）。
**evidence:** EV-APP-CLIENT-G5-002、EV-APP-CLIENT-G5-008、LEG-APP-CLIENT-G5-001、LEG-APP-CLIENT-G5-002。

## AI-RULE-KMP-INJECT-001 — 宿主能力反向注入模式

**when:** commonMain 业务需要"宿主才能提供的数据 / 行为"（如用户态读写、原生缓存、原生加解密）。
**must:** 在 commonMain 定义带 `((...) -> ...)?` 的可空 lambda 配置点（典型样例 `HSUser.getValueOrDefault` / `NativeDataSyncHelper.registrySync`），由 androidMain / iosMain 或宿主 app 启动时注入。
**must not:** 为单个能力盲目铺一对 `expect/actual`，特别是返回 / 入参带平台类型时。
**evidence:** EV-APP-CLIENT-G5-006、POS-APP-CLIENT-G5-004。

## AI-RULE-KMP-INTEROP-001 — 不对 ObjC 暴露内部 API

**when:** 在 commonMain 创建 `object` / `class` / 顶层函数，但不希望 Swift / ObjC 端直接调用。
**must:** 在声明上添加：

```kotlin
@OptIn(kotlin.experimental.ExperimentalObjCRefinement::class)
@kotlin.native.HiddenFromObjC
```

**evidence:** EV-APP-CLIENT-G5-008、POS-APP-CLIENT-G5-002、POS-APP-CLIENT-G5-007。

## AI-RULE-KMP-INTEROP-002 — SharedFlow / StateFlow 显式 interop 决策

**when:** 在 commonMain 暴露 `MutableSharedFlow` / `MutableStateFlow` / `SharedFlow` / `StateFlow`。
**must:** 显式选择 skie FlowInterop 行为之一：
- 默认：依赖 skie 自动生成 Swift 端 AsyncSequence / Publisher。
- 关闭：在字段上加 `@FlowInterop.Disabled`，并配套在 androidMain / iosMain 暴露 wrapper 方法。
**must not:** 把 `MutableSharedFlow` 直接 public 暴露而不评估 Swift 侧使用方式。
**evidence:** POS-APP-CLIENT-G5-007（`EventDispatcher`）。

## AI-RULE-KMP-PUBLISH-001 — Maven publish 凭据

**when:** 配置 KMP module 的 `publishing.repositories.maven`。
**must:** `credentials(PasswordCredentials::class.java)`，账号密码通过 `gradle.properties` / 环境变量注入。
**must not:** 在 `build.gradle.kts` 明文写 `username = "..."; password = "..."`。
**evidence:** LEG-APP-CLIENT-G5-005。

## AI-RULE-KMP-EVENT-001 — 事件分发分层

**when:** 新增跨平台事件 / 全局通信。
**must:**
- 事件类型 / 分发器 (`EventDispatcher` 类) 放 commonMain，依赖 `kotlinx.coroutines.flow.MutableSharedFlow`。
- lifecycle 感知的订阅 API 放对应平台 sourceSet（android 用 `androidx.lifecycle`，iOS 用 `MainScope` / Combine bridge）。
**must not:** 在 commonMain 引入 `androidx.lifecycle.*`；不要用 `@Deprecated` 标注的 `EventUtils`，请使用 `EventFlow`。
**evidence:** EV-APP-CLIENT-G5-005、LEG-APP-CLIENT-G5-007、LEG-APP-CLIENT-G5-008、POS-APP-CLIENT-G5-007。

## AI-RULE-KMP-PACKAGE-001 — 包结构

**when:** 在 bizcommon / contract 中新增类。
**must:**
- contract：包前缀 `com.hs.kmp.common.provider`，子包按业务域 `provider.<domain>`。
- bizcommon：包前缀 `com.hs.kmp.biz`，按业务关注点分子包（参考现有 `gray` / `userscope` / `remoteConfig` / `event` / `socket` / `pref` 等结构，同类业务收敛到同一子包）。
- 命名空间不允许在 `kotlin/com/...` 路径外散乱（不要直接放在 `kotlin/` 根）。
**evidence:** EV-APP-CLIENT-G5-007。
