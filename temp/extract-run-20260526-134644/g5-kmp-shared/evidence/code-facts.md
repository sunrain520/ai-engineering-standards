---
doc_id: "app-client-g5-evidence-code-facts"
domain: "app-client"
sub_domain: "kmp-shared"
doc_type: "evidence-code-facts"
source_batch: "app-client-kmp-shared-biz-common-contract-p1, app-client-kmp-shared-biz-common-bizcommon-p1"
generation_profile: "phase1-selected-batch"
last_reviewed: "2026-05-26"
status: "draft"
---

# Code Facts — KMP shared (biz-common contract / bizcommon)

仅记录 candidate_files 范围内的客观事实。每条事实附 evidence id 和文件相对路径（相对仓库根 `kaz-mvp/`），便于规范节引用。

## EV-APP-CLIENT-G5-001 — 模块分层（contract → bizcommon → 平台 actual）

- `submodules/biz-common/contract/build.gradle.kts:13` 声明 `kmpNameSpace = "com.hs.kmp.common.provider"`，定位为对外契约层；其 `commonMain` 仅依赖 `:bizcommon`（见同文件 `:58`），这意味着 contract 与 bizcommon 是同一 Gradle 子项目集合下的两个独立 module。
- `submodules/biz-common/bizcommon/build.gradle.kts:21` 声明 `kmpNameSpace = "com.hs.kmp.biz.common"`，作为业务通用层；commonMain 通过 `api(...)` 大量暴露下游模块（`:modules:core:apis` / `:core:types` / `:core:i18n` / `:platform:userinfo` / `:platform:preference` 等）。
- contract 模块自身不再向上依赖任何 `:modules:*`，仅暴露 `IQuotesProvider` / `IAccountProvider` / `IOrderProvider`（`submodules/biz-common/contract/src/commonMain/kotlin/com/hs/kmp/common/provider/...`）这类“最小契约接口”，与 bizcommon 形成分层。

## EV-APP-CLIENT-G5-002 — KMP target 与 sourceSet 配置形态

contract / bizcommon 两个模块的 `build.gradle.kts` 均使用同一组 target 与 sourceSet 形态：

- 插件：`kotlinMultiplatform`、`kotlinCocoapods`、`androidLibrary`、`kotlinSerialization`、`maven-publish`（contract 见 `submodules/biz-common/contract/build.gradle.kts:4-10`，bizcommon 见 `submodules/biz-common/bizcommon/build.gradle.kts:5-17`，bizcommon 额外启用 `mokoResources`、`kmpRetrofit`、`atomicfu`、`ksp`、`hsI18N` plugin、`co.touchlab.skie`）。
- `androidTarget { compilerOptions { jvmTarget.set(JVM_17) }; publishLibraryVariants("release"); withSourcesJar(publish = true); ... }` 在两个模块完全一致（contract `:21-30`，bizcommon `:28-37`）。
- iOS target 三件套统一为 `iosX64()` / `iosArm64()` / `iosSimulatorArm64()`（contract `:35-37`，bizcommon `:39-41`）。
- `cocoapods { ... framework { baseName = "..."; isStatic = true } }`：contract baseName `HSSearchKit`、bizcommon baseName `HSBizCommonKit`，pod 名称为 `HSBizSearchKit` / `HSBizCommonKit`，部署目标 `ios.deploymentTarget = "13.0"`。
- iOS 中间 sourceSet 通过 `iosMain { dependsOn(commonMain.get()); iosX64Main.dependsOn(this); iosArm64Main.dependsOn(this); iosSimulatorArm64Main.dependsOn(this) }` 显式建立（contract `:74-85`，bizcommon `:131-142`）。

## EV-APP-CLIENT-G5-003 — `expect/actual` 形态：契约最小、放置位置固定

`expect/actual` 在仓库内出现两种典型用法：

1. 公共契约 / 探针：`com.hs.kmp.common.provider`
   - `expect fun platform(): String` 在 `submodules/biz-common/contract/src/commonMain/kotlin/com/hs/kmp/common/provider/Platform.kt`。
   - `actual fun platform() = "Android"` 在 `submodules/biz-common/contract/src/androidMain/kotlin/com/hs/kmp/common/provider/Platform.android.kt`。
   - `actual fun platform() = "iOS"` 在 `submodules/biz-common/contract/src/iosMain/kotlin/com/hs/kmp/common/provider/Platform.ios.kt`。
   - 文件命名规则：`<Name>.kt`（commonMain expect） / `<Name>.android.kt`（androidMain actual） / `<Name>.ios.kt`（iosMain actual）。包路径在三方完全一致。

2. 业务平台差异函数：`com.hs.kmp.biz.remoteConfig`
   - `internal expect fun getQueryRemoteConfigsParams(): Map<String, Any>?` 位于 `submodules/biz-common/bizcommon/src/commonMain/kotlin/com/hs/kmp/biz/remoteConfig/API.kt:10`，`internal` 可见性、最小返回类型，便于跨平台对齐。
   - androidMain `API.android.kt` 用 `android.os.Build.VERSION.SDK_INT`，iosMain `API.ios.kt` 用 `platform.UIKit.UIDevice.currentDevice.systemVersion`。两端命名、参数 / 返回均一致。

## EV-APP-CLIENT-G5-004 — `expect class` + 平台 `actual class` 协议落地

`com.hs.kmp.biz.uiContext.TradeLoginUIContext`（`commonMain/.../TradeLoginUIContext.kt:1-8`）是空声明 `interface TradeLoginUIContext`，两端各有自己的 `TradeLoginUIContextImpl`：

- iosMain（`submodules/biz-common/bizcommon/src/iosMain/kotlin/com/hs/kmp/biz/uiContext/TradeLoginUIContextImpl.kt:3-22`）只用通用 `mutableMapOf<String, Any>()` 存配置项，没有任何 iOS API 引用，平台依赖足迹近似 0。
- androidMain（`submodules/biz-common/bizcommon/src/androidMain/kotlin/com/hs/kmp/biz/uiContext/TradeLoginUIContextImpl.kt:3-92`）耦合 `android.content.Context` / `Intent` / `androidx.fragment.app.FragmentActivity` / `androidx.lifecycle.Lifecycle`，并定义 `IAndroidLoginCallback` / `ITransLoginCallback` 等 Android 专属回调。这种“两端实现差异巨大”是 KMP shared 中常见但需要刻意管控的形态。

## EV-APP-CLIENT-G5-005 — 协程 / Flow / 生命周期工具仅放在 androidMain

`androidMain` 中 `event/EventFlow.kt` / `event/EventUtils.kt` / `flow/FlowUtils.kt` / `flow/SharedFlowImpl.kt` / `util/lifecycle.kt` 均依赖 androidx：

- `EventFlow.kt:3-11` 引入 `androidx.lifecycle.{Lifecycle, LifecycleEventObserver, LifecycleOwner}` 和 `kotlin.reflect.KClass`，使用 `ConcurrentHashMap` / `CopyOnWriteArrayList` 管理订阅者。
- `FlowUtils.kt:3-9` 引入 `androidx.lifecycle.{Lifecycle, LifecycleOwner, lifecycleScope, repeatOnLifecycle}`。
- `lifecycle.kt:3-5` 引入 `androidx.lifecycle.*`。

而 commonMain 对应的事件分发器 `EventDispatcher.kt:1-22` 只依赖 `kotlinx.coroutines.flow.MutableSharedFlow` 和 `co.touchlab.skie.configuration.annotations.FlowInterop`，没有任何 androidx 依赖。这说明 commonMain 与 androidMain 之间存在“事件骨架在 common，订阅 / 生命周期能力在 android”的分层。

## EV-APP-CLIENT-G5-006 — commonMain 通过 `((... ) -> ...)?` 把平台能力反向注入回 KMP

- `submodules/biz-common/bizcommon/src/androidMain/kotlin/com/hs/kmp/biz/config/HSUser.kt:10-25` 定义 `HSUser` 持有两个可空 lambda：`getValueOrDefault: ((key: String?, default: Any?) -> Any?)?` 和 `remove: ((key: String?) -> Unit)?`。
- 这两个 lambda 在 `submodules/biz-common/bizcommon/src/androidMain/kotlin/com/hs/kmp/biz/login_vb/cache/UserCache.android.kt` 中被 `actual fun getUserCache` 直接调用。

iOS 侧采用 `NativeDataSyncHelper`（`submodules/biz-common/bizcommon/src/iosMain/kotlin/com/hs/kmp/biz/login_vb/cache/NativeDataSyncHelper.kt:1-17`）走 `((key: String?) -> String?)?` 的 callback 注册模式。两端共同特征：actual 实现里面通过 KMP 层提供的可空 lambda 与原生宿主交换数据，避免在 commonMain 层耦合任何 platform 类型。

## EV-APP-CLIENT-G5-007 — 包命名与目录结构

- contract 模块：根包 `com.hs.kmp.common.provider`，子包按业务域分：`provider.quotes`、`provider.trade`，分别放 `IQuotesProvider`、`IAccountProvider` / `IOrderProvider`（`submodules/biz-common/contract/src/commonMain/kotlin/com/hs/kmp/common/provider/...`）。
- bizcommon 模块：根包 `com.hs.kmp.biz`，按业务关注点划分大量子包：`gray` / `userscope` / `net` / `util` / `quote` / `trade` / `uiContext` / `platform` / `ext` / `remoteConfig` / `common` / `pref` / `calculation` / `constant` / `stockconnect` / `cryptocurrency` / `application` / `monitoring` / `quickaccess` / `exception` / `event` / `socket`。
- platform 实现保持同一包路径：commonMain 包 `com.hs.kmp.biz.uiContext` → androidMain / iosMain 都使用同一包，文件名保持业务名一致或加 `.android.kt` / `.ios.kt` 后缀。

## EV-APP-CLIENT-G5-008 — 跨平台序列化与 ObjC interop

- `commonMain` 中 `API.kt:12-14` 标注 `@OptIn(ExperimentalObjCRefinement::class)` + `@HiddenFromObjC` 来对 ObjC 隐藏 KMP 内部 API；`object API` 仅暴露 suspend 网络方法。
- bizcommon `build.gradle.kts:164-171` 在 `targets.withType<KotlinNativeTarget>` 中开启 `-Xexport-kdoc`、设置 `binaryOptions["bundleId"] = "com.hs.kmp.HSBizCommonKit"`。
- bizcommon plugin 列表中包含 `co.touchlab.skie` 用于 Kotlin 到 Swift 的 idiomatic 转换；`EventDispatcher.kt:4` 使用 `co.touchlab.skie.configuration.annotations.FlowInterop` 对 SharedFlow 关闭默认 interop。

## EV-APP-CLIENT-G5-009 — commonMain 不直接 import 平台包（contract 全样本 + bizcommon 抽样）

抽样核对 commonMain 文件 `import` 行：

- contract `Platform.kt`、`IQuotesProvider.kt`、`IAccountProvider.kt`、`IOrderProvider.kt`：均无 import。
- bizcommon commonMain 抽样：`event/EventDispatcher.kt`、`uiContext/TradeLoginUIContext.kt`、`exception/HSException.kt`、`userscope/UserScopeStore.kt`、`userscope/UserScopedComponent.kt`、`remoteConfig/API.kt`、`remoteConfig/RemoteConfigService.kt`：所有 `import` 行只出现 `com.hs.kmp.*`、`kotlinx.*`、`kotlin.*`、`co.touchlab.skie.*`、`com.github.kittinunf.result.*`，无 `android.*` / `androidx.*` / `platform.*` / `java.*` 包名出现在 commonMain。

注：这只是抽样事实，并非全量保证。pending-confirmation 中已记录后续需要全量校验。

## EV-APP-CLIENT-G5-010 — 构建 / 出包配置事实

- contract `build.gradle.kts:127-138` 与 bizcommon `:251-265` 都通过 `publishing { repositories { maven { ... } } }` 发布到 `nexus.hszq8.com/content/repositories/android(-snapshots)`。
- bizcommon 在 commonMain 大量使用 `api(libs.xxx)` 而不是 `implementation(libs.xxx)`，向下游传递 ktor / kotlinx-serialization / moko-resources / 内部 baselib 等依赖。contract 则在 commonMain 仅 `implementation(project(":bizcommon"))`，没有透传第三方库 → 体现“契约层零依赖暴露 / 业务层主动透传基础设施”分层意图。
- bizcommon `commonTest` 依赖 `kotlin.test` / `junit` / `moko.resources.test` / `kotlinx.coroutines.test` / `ktor.client.mock` / `kotlin.reflect`（`:111-119`），跨平台测试统一走 commonTest。
