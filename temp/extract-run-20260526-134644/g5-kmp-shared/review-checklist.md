---
doc_id: "app-client-kmp-shared-review-checklist"
title: "App-Client KMP Shared Code Review Checklist"
domain: "app-client"
sub_domain: "kmp-shared"
doc_type: "review-checklist"
version: "v0.1.0"
status: "draft"
source_batch: "app-client-kmp-shared-biz-common-contract-p1, app-client-kmp-shared-biz-common-bizcommon-p1"
generation_profile: "phase1-selected-batch"
last_reviewed: "2026-05-26"
---

# Code Review Checklist — KMP Shared

每条对应规范中至少一条规则；reviewer 在评审涉及 `submodules/biz-common/{contract, bizcommon}` 或新增 KMP shared module 时按表过一遍。

## 1. commonMain 平台依赖

- [ ] commonMain 文件 import 行不含 `android.*` / `androidx.*`。【ai-rule: AI-RULE-KMP-COMMON-001】
- [ ] commonMain 文件 import 行不含 `platform.*` / `apple.*` / `UIKit.*`。【ai-rule: AI-RULE-KMP-COMMON-001】
- [ ] commonMain 文件 import 行不含 `java.*`（特别是 `java.util.concurrent.*`、`java.io.File`）。【ai-rule: AI-RULE-KMP-COMMON-001】
- [ ] commonMain 不出现 `synchronized {}` 块；锁 / volatile 使用 `kotlinx.atomicfu.locks` / `kotlin.concurrent.Volatile`。【ai-rule: AI-RULE-KMP-COMMON-002】

## 2. `expect/actual` 形态

- [ ] `expect` 与所有 `actual` 同包路径（粘贴一对查看 package 行）。【ai-rule: AI-RULE-KMP-EXPECT-001】
- [ ] 文件命名遵守 `<Name>.kt` / `<Name>.android.kt` / `<Name>.ios.kt`；`actual class` 类型可省后缀但每端各一份。【ai-rule: AI-RULE-KMP-FILE-001】
- [ ] `expect` 签名只用跨平台类型；可见性默认 `internal`，确需对外才 `public`。【ai-rule: AI-RULE-KMP-EXPECT-001】
- [ ] `actual` 的可见性、参数、返回类型、可空性与 `expect` 严格一致。【ai-rule: AI-RULE-KMP-EXPECT-001】

## 3. 模块分层

- [ ] contract `commonMain.dependencies` 不出现 `api(...)`。【ai-rule: AI-RULE-KMP-CONTRACT-001】
- [ ] contract commonMain 文件不含网络 / IO / 平台调用，仅 `interface I*Provider` 或纯数据类。【ai-rule: AI-RULE-KMP-CONTRACT-001】
- [ ] 新增 contract 接口命名为 `I + 业务名 + Provider/Service`，按业务域子包归类（`provider.quotes` / `provider.trade` 等）。【ai-rule: AI-RULE-KMP-PACKAGE-001】
- [ ] bizcommon `commonMain` 通过 `api(libs.xxx)` 透传必要基础设施，内部 helper 用 `implementation(...)`。【standard: KMP-BUILD-005】

## 4. 平台 actual 实现

- [ ] androidMain actual 中所有 androidx / Android API 引用都局限在该 sourceSet。【standard: KMP-PLATFORM-001 / KMP-PLATFORM-002】
- [ ] iosMain actual 中所有 `platform.*` / Apple API 引用都局限在该 sourceSet。【standard: KMP-PLATFORM-001 / KMP-PLATFORM-002】
- [ ] commonMain 反向接入宿主能力时，使用 `((...) -> ...)?` 可空 lambda（`HSUser` / `NativeDataSyncHelper` 模式），而不是把平台类型升到 commonMain。【ai-rule: AI-RULE-KMP-INJECT-001】

## 5. 构建配置

- [ ] `androidTarget { compilerOptions { jvmTarget.set(JvmTarget.JVM_17) } }` 正确设置；`publishLibraryVariants("release")` + `withSourcesJar(publish = true)`。【ai-rule: AI-RULE-KMP-BUILD-001】
- [ ] iOS target 三件套：`iosX64() / iosArm64() / iosSimulatorArm64()` 全部声明。【ai-rule: AI-RULE-KMP-BUILD-001】
- [ ] `cocoapods { ios.deploymentTarget = "13.0"; framework { isStatic = true } }`；`binaryOptions["bundleId"] = "com.hs.kmp.<KitName>"`。【ai-rule: AI-RULE-KMP-BUILD-001】
- [ ] 新模块未使用 legacy 形态 `iosMain { dependsOn(commonMain.get()); iosXxxMain.dependsOn(this) }`；已有模块保留即可。【standard: KMP-BUILD-002】
- [ ] maven publish 使用 `credentials(PasswordCredentials::class.java)`，未在源代码明文写凭据。【ai-rule: AI-RULE-KMP-PUBLISH-001】

## 6. iOS Interop

- [ ] commonMain 中不希望对外暴露的 `object` / 顶层函数加 `@HiddenFromObjC` + `@OptIn(ExperimentalObjCRefinement::class)`。【ai-rule: AI-RULE-KMP-INTEROP-001】
- [ ] commonMain 暴露的 SharedFlow / StateFlow 已显式决定 skie interop 策略（默认转换 / `@FlowInterop.Disabled` + wrapper）。【ai-rule: AI-RULE-KMP-INTEROP-002】
- [ ] 跨端事件 / 分发：`EventDispatcher` 类放 commonMain，订阅 + lifecycle 工具放 androidMain；新增订阅入口不再使用 `@Deprecated` 标注的 `EventUtils`。【ai-rule: AI-RULE-KMP-EVENT-001】

## 7. 包结构与命名

- [ ] 文件路径与 `package` 声明一致；`androidMain` / `iosMain` 与 commonMain 同包路径。【ai-rule: AI-RULE-KMP-PACKAGE-001】
- [ ] 业务关注点收敛到现有子包（`gray` / `userscope` / `remoteConfig` / `event` / `socket` / `pref` 等），不在 `biz` 根目录新建散类。【ai-rule: AI-RULE-KMP-PACKAGE-001】

## 8. 测试

- [ ] commonTest 使用 `kotlin.test` + `kotlinx-coroutines-test` + `ktor-client-mock`，不直接 `import org.junit.*`。【standard: §1 / EV-APP-CLIENT-G5-010】
- [ ] android 平台测试需要复用 commonTest 类时，模块已配置 `instrumentedTestVariant.sourceSetTree.set(KotlinSourceSetTree.test)`。【standard: §6 / LEG-APP-CLIENT-G5-003】

## 9. 安全 / 凭据

- [ ] `build.gradle.kts` / 资源 / 配置文件中无明文 username / password / token。【ai-rule: AI-RULE-KMP-PUBLISH-001】
- [ ] 新增 actual 实现中如包含网络 / 设备 ID 采集，已在 review 中确认合规边界（与 platform / userinfo 团队对齐）。【pending: PENDING-APP-CLIENT-G5-3】
