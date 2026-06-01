---
doc_id: "app-client-g5-evidence-positive-examples"
domain: "app-client"
sub_domain: "kmp-shared"
doc_type: "evidence-positive-examples"
source_batch: "app-client-kmp-shared-biz-common-contract-p1, app-client-kmp-shared-biz-common-bizcommon-p1"
generation_profile: "phase1-selected-batch"
last_reviewed: "2026-05-26"
status: "draft"
---

# Positive Examples — KMP shared

每条样本来自实际代码片段，演示规范层希望的"理想形态"。

## POS-APP-CLIENT-G5-001 — 极简 `expect/actual` 探针函数

文件：
- commonMain：`submodules/biz-common/contract/src/commonMain/kotlin/com/hs/kmp/common/provider/Platform.kt`
- androidMain：`submodules/biz-common/contract/src/androidMain/kotlin/com/hs/kmp/common/provider/Platform.android.kt`
- iosMain：`submodules/biz-common/contract/src/iosMain/kotlin/com/hs/kmp/common/provider/Platform.ios.kt`

```kotlin
// commonMain
package com.hs.kmp.common.provider

expect fun platform(): String

// androidMain
package com.hs.kmp.common.provider

actual fun platform() = "Android"

// iosMain
package com.hs.kmp.common.provider

actual fun platform() = "iOS"
```

要点：
1. 同包路径（`com.hs.kmp.common.provider`）。
2. 文件命名 `Platform.kt` / `Platform.android.kt` / `Platform.ios.kt` 三段对齐。
3. 返回基础类型 `String`，跨端无需任何平台类型，最低契约。

## POS-APP-CLIENT-G5-002 — `internal expect fun` + 平台细节聚合到一处

文件：`submodules/biz-common/bizcommon/src/commonMain/kotlin/com/hs/kmp/biz/remoteConfig/API.kt`

```kotlin
package com.hs.kmp.biz.remoteConfig

import com.hs.kmp.baselib.net.request.HSRequestType
import com.hs.kmp.datacenter.HsSuspendRequest
import kotlin.experimental.ExperimentalObjCRefinement
import kotlin.native.HiddenFromObjC
import com.hs.kmp.biz.net.HSAppUrl
import com.hs.kmp.biz.securities.apis.AppUrl

internal expect fun getQueryRemoteConfigsParams(): Map<String, Any>?

@OptIn(ExperimentalObjCRefinement::class)
@HiddenFromObjC
object API {
    suspend fun queryRemoteConfigs(): RemoteConfigResponse? { /* ... */ }
}
```

androidMain：

```kotlin
package com.hs.kmp.biz.remoteConfig

import android.os.Build

actual fun getQueryRemoteConfigsParams(): Map<String, Any>? = mapOf(
    "withPatch" to true,
    "androidApiVersion" to Build.VERSION.SDK_INT,
    "additionalConfigType" to "12",
)
```

iosMain：

```kotlin
package com.hs.kmp.biz.remoteConfig

import com.hs.kmp.baselib.utils.getDevice
import platform.UIKit.UIDevice

actual fun getQueryRemoteConfigsParams(): Map<String, Any>? = mapOf(
    "withPatch" to "true",
    "iosSystemVersion" to UIDevice.currentDevice.systemVersion,
    "additionalConfigType" to "12",
)
```

要点：
1. `expect` 用 `internal`，避免对外泄漏；只暴露 `object API` 的 suspend 业务方法。
2. 所有平台依赖（`Build.VERSION.SDK_INT`、`platform.UIKit.UIDevice`）只出现在 actual 文件中，commonMain 完全不引用任何 `android.*` / `platform.*` 包。
3. `expect` 函数返回最低公共类型 `Map<String, Any>?`，把平台差异打平为业务参数。
4. 对 ObjC 暴露用 `@HiddenFromObjC` 屏蔽内部 API，保留对外 `object API`。

## POS-APP-CLIENT-G5-003 — Contract 模块的零透传依赖配置

文件：`submodules/biz-common/contract/build.gradle.kts`（`:55-86`）

```kotlin
sourceSets {
    commonMain {
        dependencies {
            implementation(project(":bizcommon"))
        }
    }
    androidMain {
        dependsOn(commonMain.get())
        dependencies { }
    }
    iosMain {
        dependsOn(commonMain.get())
        iosX64Main.dependsOn(this)
        iosArm64Main.dependsOn(this)
        iosSimulatorArm64Main.dependsOn(this)
        dependencies { }
    }
}
```

要点：
1. contract 仅声明 `implementation(project(":bizcommon"))`，不向下游暴露任何第三方依赖。
2. iosMain 中间 sourceSet 的三件套 `iosX64Main / iosArm64Main / iosSimulatorArm64Main` 通过 `dependsOn(this)` 显式建图，Kotlin 1.9+ Hierarchy Template 之外的兜底写法。

## POS-APP-CLIENT-G5-004 — commonMain 通过可空 lambda 反向接入平台能力

文件：`submodules/biz-common/bizcommon/src/androidMain/kotlin/com/hs/kmp/biz/config/HSUser.kt`

```kotlin
package com.hs.kmp.biz.config

import kotlin.jvm.JvmStatic

class HSUser {
    companion object {
        @JvmStatic
        var getValueOrDefault: ((key: String?, default: Any?) -> Any?)? = null
        @JvmStatic
        var remove: ((key: String?) -> Unit)? = null
    }
}
```

要点：
1. 为 KMP 层提供"可注入的平台桥"：`((...) -> ...)?` lambda 形式，不引入任何 platform / android 类型；如果未来要把 `HSUser` 提到 commonMain，`@JvmStatic` 可移除即可。
2. 配合 iosMain 侧 `NativeDataSyncHelper.registrySync(callback: (key: String?) -> String?)` 形成对称能力，宿主侧分别在 Android / iOS app 启动时注入。

## POS-APP-CLIENT-G5-005 — commonMain 纯 Kotlin 业务对象（无平台 API）

文件：`submodules/biz-common/bizcommon/src/commonMain/kotlin/com/hs/kmp/biz/userscope/UserScopeStore.kt`

```kotlin
package com.hs.kmp.biz.userscope

import kotlinx.atomicfu.locks.reentrantLock
import kotlinx.atomicfu.locks.withLock
import kotlin.concurrent.Volatile

class UserScopeStore<S : UserScopedComponent>(
    private val currentUserScopeKeyProvider: () -> String,
    private val scopeFactory: (String) -> S,
) { /* ... */ }
```

要点：
1. 跨平台并发原语统一走 `kotlinx.atomicfu.locks`（不是 `java.util.concurrent.locks`）。
2. `@Volatile` 来自 `kotlin.concurrent.Volatile`，KMP 友好。
3. 业务模型抽象只依赖 `kotlin.*` / `kotlinx.*`，可被 androidMain 与 iosMain 复用。

## POS-APP-CLIENT-G5-006 — Contract 层"小接口"原则

文件：
- `submodules/biz-common/contract/src/commonMain/kotlin/com/hs/kmp/common/provider/quotes/IQuotesProvider.kt`
- `submodules/biz-common/contract/src/commonMain/kotlin/com/hs/kmp/common/provider/trade/IOrderProvider.kt`
- `submodules/biz-common/contract/src/commonMain/kotlin/com/hs/kmp/common/provider/trade/IAccountProvider.kt`

```kotlin
interface IQuotesProvider { }
interface IOrderProvider { }
interface IAccountProvider { }
```

要点：
1. contract 层接口刻意保持极小（甚至当前为空 marker interface），明确"契约只声明能力归属，不堆叠方法签名"。
2. 命名规范：`I + 业务名 + Provider`；按业务域 `provider.quotes` / `provider.trade` 子包归类。

## POS-APP-CLIENT-G5-007 — commonMain 全量使用跨平台库

文件：`submodules/biz-common/bizcommon/src/commonMain/kotlin/com/hs/kmp/biz/event/EventDispatcher.kt`

```kotlin
package com.hs.kmp.biz.event

import co.touchlab.skie.configuration.annotations.FlowInterop
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

object EventDispatcher {
    internal val _eventFlow = MutableSharedFlow<Events>(replay = 1)
    @FlowInterop.Disabled
    val eventFlow = _eventFlow.asSharedFlow()
    suspend fun emit(events: Events) { _eventFlow.emit(events) }
}
```

要点：
1. commonMain 内的事件分发只依赖 `kotlinx.coroutines.flow` + skie 注解，无任何 androidx / platform 包。
2. 关键 SharedFlow 上叠 `@FlowInterop.Disabled` 显式控制 Swift interop 行为，避免在 ObjC / Swift 端意外暴露内部 SharedFlow。
