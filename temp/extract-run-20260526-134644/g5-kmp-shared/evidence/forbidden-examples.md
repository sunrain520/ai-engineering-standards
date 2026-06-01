---
doc_id: "app-client-g5-evidence-forbidden-examples"
domain: "app-client"
sub_domain: "kmp-shared"
doc_type: "evidence-forbidden-examples"
source_batch: "app-client-kmp-shared-biz-common-contract-p1, app-client-kmp-shared-biz-common-bizcommon-p1"
generation_profile: "phase1-selected-batch"
last_reviewed: "2026-05-26"
status: "draft"
---

# Forbidden Examples — KMP shared

记录"如果出现 X 则违反规范"的反例。本批次抽样未在仓库内发现违例，反例为根据本仓 evidence 推导出的等价禁止形态，用于规范层 FORBIDDEN 章节引用。

## NEG-APP-CLIENT-G5-001 — commonMain 直接 import `android.*` 或 `androidx.*`

```kotlin
// 错误：commonMain
package com.hs.kmp.biz.uiContext

import android.content.Context // FORBIDDEN
import androidx.fragment.app.FragmentActivity // FORBIDDEN

interface TradeLoginUIContext {
    val context: Context
}
```

为何禁止：
- 直接污染 commonMain，iOS / iosTest 立刻编译失败。
- 违反 EV-APP-CLIENT-G5-005、EV-APP-CLIENT-G5-009 中"commonMain 抽样未出现 android.* 包"的事实基线。

正确做法：把 Android 平台依赖留在 `androidMain`，commonMain 只声明 `interface TradeLoginUIContext`（参见 POS-APP-CLIENT-G5-006 / `submodules/biz-common/bizcommon/src/commonMain/kotlin/com/hs/kmp/biz/uiContext/TradeLoginUIContext.kt`）。

## NEG-APP-CLIENT-G5-002 — commonMain 直接 import `platform.*` 或 Apple framework

```kotlin
// 错误：commonMain
package com.hs.kmp.biz.remoteConfig

import platform.UIKit.UIDevice // FORBIDDEN

expect fun getQueryRemoteConfigsParams(): Map<String, Any>?
```

为何禁止：
- iOS-only 命名空间放进 commonMain 会让 androidMain 编译失败，违反 EV-APP-CLIENT-G5-003 中观察到的 `expect/actual` 形态——`platform.UIKit.UIDevice` 仅出现在 `iosMain/.../API.ios.kt`。

正确做法：commonMain 仅 `internal expect fun ...`，`UIDevice` 引用只允许出现在 `iosMain`。

## NEG-APP-CLIENT-G5-003 — commonMain 引用 `java.util.concurrent.*`

```kotlin
// 错误：commonMain
package com.hs.kmp.biz.userscope

import java.util.concurrent.locks.ReentrantLock // FORBIDDEN

class UserScopeStore { private val lock = ReentrantLock() }
```

为何禁止：
- 在 iOS / iosSimulator 等 Native target 上不存在 `java.*`，会导致 commonMain 编译失败。
- 违反 EV-APP-CLIENT-G5-002 / POS-APP-CLIENT-G5-005：仓库内 commonMain 一律使用 `kotlinx.atomicfu.locks.reentrantLock`。

正确做法：使用 `kotlinx.atomicfu.locks.reentrantLock` + `withLock`，或 `kotlinx.coroutines.sync.Mutex`。

## NEG-APP-CLIENT-G5-004 — `expect` 暴露平台类型

```kotlin
// 错误
package com.hs.kmp.biz.remoteConfig

expect fun getDevicePayload(): android.os.Bundle // FORBIDDEN
```

为何禁止：
- `expect` 签名上的平台类型在 iosMain 没有等价类型，必然编译失败。
- 违反 EV-APP-CLIENT-G5-003 中 `expect fun getQueryRemoteConfigsParams(): Map<String, Any>?` 形成的"返回值打平为基础 / Kotlin 标准类型"原则。

正确做法：`expect fun getQueryRemoteConfigsParams(): Map<String, Any>?` —— 跨端通用类型 + 由 actual 内部转化。

## NEG-APP-CLIENT-G5-005 — `actual` 函数与 `expect` 签名不一致

```kotlin
// commonMain
internal expect fun getQueryRemoteConfigsParams(): Map<String, Any>?

// androidMain  ❌ 修改了可见性 / 返回类型
public actual fun getQueryRemoteConfigsParams(): Map<String, Any> = mapOf(/* ... */) // FORBIDDEN
```

为何禁止：
- Kotlin 编译器对 `expect/actual` 签名严格匹配，可见性 / 可空性 / 类型必须一致；任何漂移都会让对端 actual 找不到对应 expect。
- 违反 EV-APP-CLIENT-G5-003 中"androidMain / iosMain 两端 actual 签名一致"事实。

## NEG-APP-CLIENT-G5-006 — Contract 层堆放业务实现 / 第三方依赖透传

```kotlin
// 错误：contract/build.gradle.kts
sourceSets {
    commonMain {
        dependencies {
            api(libs.ktor.client.core) // FORBIDDEN
            api(libs.kotlinx.serialization.json)
            implementation("io.mockk:mockk:1.13.17") // FORBIDDEN
        }
    }
}
```

为何禁止：
- Contract 层定位是"对外契约 + 极小接口"。当前仓库 `submodules/biz-common/contract/build.gradle.kts:55-86` 只声明 `implementation(project(":bizcommon"))`。
- 一旦在 contract `api(...)` 透传 ktor / mockk 等基础设施，下游 module 直接依赖 contract 时会被迫继承大量传递依赖，破坏分层。

正确做法：基础设施依赖统一放 `bizcommon` 的 commonMain（参见 POS-APP-CLIENT-G5-003 与 EV-APP-CLIENT-G5-010）。

## NEG-APP-CLIENT-G5-007 — actual 与 expect 包路径不一致

```kotlin
// commonMain
package com.hs.kmp.common.provider
expect fun platform(): String

// androidMain  ❌ 包名错位
package com.hs.kmp.android.provider
actual fun platform() = "Android" // FORBIDDEN
```

为何禁止：
- `expect/actual` 必须同包路径。仓库实际形态见 EV-APP-CLIENT-G5-007：commonMain / androidMain / iosMain 三处包路径完全相同，文件名只在后缀加 `.android` / `.ios`。

## NEG-APP-CLIENT-G5-008 — 直接在 commonMain 使用 `androidx.lifecycle`

```kotlin
// 错误：commonMain
package com.hs.kmp.biz.flow

import androidx.lifecycle.LifecycleOwner // FORBIDDEN

fun <T> SharedFlow<T>.observe(owner: LifecycleOwner, block: (T) -> Unit) { /* ... */ }
```

为何禁止：
- `androidx.lifecycle.*` 仅在 androidMain 提供。仓库实际形态：`flow/FlowUtils.kt` / `util/lifecycle.kt` 都放在 `submodules/biz-common/bizcommon/src/androidMain/...`，commonMain 没有此扩展（参见 EV-APP-CLIENT-G5-005）。

正确做法：commonMain 暴露 `kotlinx.coroutines.flow.SharedFlow`；生命周期感知的 `observe` 扩展只放 androidMain；iosMain 如需可用 `MainScope()` / Combine bridge。
