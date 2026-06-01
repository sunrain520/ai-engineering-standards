---
doc_id: "app-client-g5-evidence-legacy-compatible"
domain: "app-client"
sub_domain: "kmp-shared"
doc_type: "evidence-legacy-compatible"
source_batch: "app-client-kmp-shared-biz-common-contract-p1, app-client-kmp-shared-biz-common-bizcommon-p1"
generation_profile: "phase1-selected-batch"
last_reviewed: "2026-05-26"
status: "draft"
---

# Legacy-Compatible Patterns — KMP shared

记录"虽然不是首选写法，但当前仓库出于历史原因或宿主集成仍需保留"的形态。规范层不鼓励新模块沿用，但也不要求批量重写。

## LEG-APP-CLIENT-G5-001 — `iosMain { dependsOn(commonMain.get()); iosX64Main.dependsOn(this); ... }` 显式建图

文件：
- `submodules/biz-common/contract/build.gradle.kts:74-85`
- `submodules/biz-common/bizcommon/build.gradle.kts:131-142`

```kotlin
val iosX64Main by getting
val iosArm64Main by getting
val iosSimulatorArm64Main by getting
val iosMain by creating {
    dependsOn(commonMain)
    iosX64Main.dependsOn(this)
    iosArm64Main.dependsOn(this)
    iosSimulatorArm64Main.dependsOn(this)
}
```

说明：
- Kotlin 1.9+ 已默认开启 Default Hierarchy Template，`iosMain` 会被自动创建并自动 `dependsOn(commonMain)`。
- 仓库现状采用显式 `dependsOn`，是 1.9 之前的兼容写法，仍能工作但属于冗余。
- 规范层处理：在新增模块章节中推荐"使用默认层级模板"，但保留对现状的兼容描述，不强制改写已有模块。

## LEG-APP-CLIENT-G5-002 — Android sourceSet 层 `dependsOn(commonMain.get())` 显式声明

文件：`submodules/biz-common/contract/build.gradle.kts:68-72` 与 `submodules/biz-common/bizcommon/build.gradle.kts:121-122`

```kotlin
androidMain {
    dependsOn(commonMain.get())
    dependencies { /* ... */ }
}
```

说明：
- 同样属于 Hierarchy Template 引入前的兼容写法。
- 规范层处理：保留兼容；新增模块直接省略 `dependsOn(commonMain.get())`。

## LEG-APP-CLIENT-G5-003 — `instrumentedTestVariant.sourceSetTree.set(KotlinSourceSetTree.test)` 让 androidTest 复用 commonTest

文件：
- `submodules/biz-common/contract/build.gradle.kts:28-30`
- `submodules/biz-common/bizcommon/build.gradle.kts:35-37`

```kotlin
@OptIn(ExperimentalKotlinGradlePluginApi::class)
instrumentedTestVariant.sourceSetTree.set(KotlinSourceSetTree.test)
```

说明：
- 配合注释 `//为了让androidTest能commonTest访问中的类`。
- 该 API 仍带 `@ExperimentalKotlinGradlePluginApi`，未来可能更名 / 改路径。
- 规范层处理：作为现有惯例记录；新模块沿用同样写法直至 KGP 提供稳定替代品。

## LEG-APP-CLIENT-G5-004 — Cocoapods baseName 与 pod name 不完全对齐

文件：`submodules/biz-common/contract/build.gradle.kts:40-51`

```kotlin
cocoapods {
    name = "HSBizSearchKit"
    ...
    framework {
        baseName = "HSSearchKit"
        isStatic = true
    }
}
```

说明：
- Pod 名 `HSBizSearchKit` 和 framework `baseName = "HSSearchKit"` 故意不一致，疑似为兼容旧的 iOS 工程（旧工程引用 `HSSearchKit`，新 pod spec 用 `HSBizSearchKit`）。
- 规范层处理：标注"新模块默认 pod name 与 framework baseName 保持一致"，但对 contract 模块保留现状。

## LEG-APP-CLIENT-G5-005 — bizcommon publish 凭据明文写在 build.gradle.kts

文件：`submodules/biz-common/bizcommon/build.gradle.kts:259-263`

```kotlin
credentials {
    username = "android-deployment"
    password = "[REDACTED_PASSWORD]"
}
```

而 contract 模块走 `credentials(PasswordCredentials::class.java)` 由 Gradle 属性注入：

```kotlin
// contract/build.gradle.kts:135
credentials(PasswordCredentials::class.java)
```

说明：
- bizcommon 当前是明文写法（历史遗留）；contract 已切换到 `PasswordCredentials` 形式。
- 规范层处理：新模块禁止明文写凭据；针对 bizcommon 现状，在 pending-confirmation 中提出"是否计划迁移到 `PasswordCredentials`"。

## LEG-APP-CLIENT-G5-006 — `iosBaseLocalizationRegion = "zh-CN"`

文件：`submodules/biz-common/bizcommon/build.gradle.kts:228-231`

```kotlin
multiplatformResources {
    resourcesPackage = "com.hs.kmp.biz.common.library"
    iosBaseLocalizationRegion = "zh-CN"
}
```

说明：
- moko-resources 在 iOS 端将 base 本地化区域绑定为 `zh-CN`；与 commonMain `moko-resources/base/`（默认）+ `en/` + `zh-HK/` 的目录布局对应。
- 规范层处理：作为既有 i18n 决策记录，规范层不强制改动。

## LEG-APP-CLIENT-G5-007 — `EventUtils` 标 `@Deprecated("禁止外部调用.请使用EventFlow")` 但仍保留

文件：`submodules/biz-common/bizcommon/src/androidMain/kotlin/com/hs/kmp/biz/event/EventUtils.kt:18-19`

```kotlin
@Deprecated("禁止外部调用.请使用EventFlow")
class EventUtils { /* ... */ }
```

说明：
- 类已标 deprecated 但 `EventFlow.kt` 仍依赖它的 `Companion` 静态方法。
- 这是一种"对外 deprecate / 对内保留"的过渡形态，规范层处理：在 review-checklist 中强调"业务调用方代码不允许引用 EventUtils，应使用 EventFlow"。

## LEG-APP-CLIENT-G5-008 — Android-only 的 `EventFlow` / lifecycle 扩展未 expect 到 commonMain

文件：`submodules/biz-common/bizcommon/src/androidMain/kotlin/com/hs/kmp/biz/event/EventFlow.kt`、`submodules/biz-common/bizcommon/src/androidMain/kotlin/com/hs/kmp/biz/util/lifecycle.kt`

说明：
- `EventFlow.collect(any, dispatcher, isSticky, success)` 这套订阅 API 只存在于 androidMain，iosMain 没有对应实现，意味着 iOS 端目前仅能直接 collect `EventDispatcher.eventFlow`，而无法享受 lifecycle 自动取消的便利。
- 这是当前实际形态，而非未来期望（理想形态：commonMain 提供 lifecycle-agnostic 的订阅器；android / ios 各自补 lifecycle 桥）。
- 规范层处理：在 pending-confirmation 中标注"是否计划下沉 EventFlow 主体到 commonMain"。
