---
doc_id: "app-client-kmp-shared-pending-confirmation"
title: "App-Client KMP Shared 待确认事项"
domain: "app-client"
sub_domain: "kmp-shared"
doc_type: "pending-confirmation"
status: "draft"
source_batch: "app-client-kmp-shared-biz-common-contract-p1, app-client-kmp-shared-biz-common-bizcommon-p1"
generation_profile: "phase1-selected-batch"
last_reviewed: "2026-05-26"
---

# Pending Confirmation — KMP Shared

本批次仅 single-project 抽样，以下事项需在更多 KMP 模块（`submodules/biz-search`、`hscomponents`、`modules/core/*`、`modules/platform/*`）确认后再决定是否升级到正式规范。

## PENDING-APP-CLIENT-G5-1 — commonMain 平台 import 全量校验

**情况：** EV-APP-CLIENT-G5-009 仅在抽样的 commonMain 文件上验证"无 `android.*` / `androidx.*` / `platform.*` / `java.*`"。bizcommon `commonMain/kotlin` 下文件总数较多，未做全量扫描。

**待确认：**
1. 是否对 contract / bizcommon 的 commonMain 做一次全量 grep，把潜在违例文件登记进 forbidden 引用？
2. 是否在 CI 中增加 detekt / ktlint custom rule，强制阻止 commonMain 中出现禁止 import？

**评估默认值：** 是（建议补全量扫描和 CI 检测）。

## PENDING-APP-CLIENT-G5-2 — `EventFlow` 是否下沉到 commonMain

**情况：** LEG-APP-CLIENT-G5-008 记录：lifecycle 感知的 `EventFlow.collect(any, ...)` 仅在 androidMain，iOS 端缺少同等便利能力。

**待确认：**
1. 是否计划提取 commonMain 版本 `EventFlow`（lifecycle-agnostic），让 androidMain / iosMain 各自补 lifecycle bridge？
2. 短期是否需要在 iOS 端补一个 `EventFlow.ios.kt`，让 Swift 端也能享受订阅 / 取消？

**评估默认值：** 计划下沉，但本批次不收口。

## PENDING-APP-CLIENT-G5-3 — `HSUser` / `NativeDataSyncHelper` 模式的合规边界

**情况：** EV-APP-CLIENT-G5-006 + POS-APP-CLIENT-G5-004 描述用 `((...) -> ...)?` 把宿主用户态能力反向注入。`HSUser` 当前位于 `androidMain`，未来若提到 commonMain，需要平台合规 review（用户数据跨进程 / 跨端访问）。

**待确认：**
1. 该模式是否存在用户数据 / 隐私合规风险？需要 platform / userinfo / 安全团队确认是否允许默认在 commonMain 暴露此模式。
2. 是否需要在规范中规定"宿主反向注入"必须列入对应业务模块的 `用户数据访问清单`？

**评估默认值：** 不在 commonMain 上提；保留 androidMain / iosMain 各自 actual 形态。

## PENDING-APP-CLIENT-G5-4 — `co.touchlab.skie` 与 `kmpRetrofit` 等插件是否成为基线

**情况：** bizcommon 启用了 `co.touchlab.skie`、`kmpRetrofit`、`atomicfu`、`mokoResources`、`com.hs.kmp.gradle.i18n.plugin`；contract 仅启用最小一组。AI-RULE-KMP-BUILD-001 当前只把"最小基线"列为强制，没把 skie / 资源插件列入。

**待确认：**
1. skie 是否应作为所有 KMP shared module 的基线插件（涉及 Swift 端 idiomatic interop）？
2. moko-resources 是否仅业务模块需要，contract 不需要？

**评估默认值：** skie 列为推荐而非强制；moko-resources 按需启用。

## PENDING-APP-CLIENT-G5-5 — Cocoapods name 与 framework baseName 不一致

**情况：** LEG-APP-CLIENT-G5-004 记录 contract pod name `HSBizSearchKit` / framework baseName `HSSearchKit` 不一致；bizcommon 一致 `HSBizCommonKit`。

**待确认：**
1. contract 的不一致是否仅历史遗留？是否计划在下一个大版本对齐？
2. 是否在规范层把"name 与 baseName 必须一致"列为强制规则，而不是推荐？

**评估默认值：** 推荐对齐；强制等待 iOS 团队确认。

## PENDING-APP-CLIENT-G5-6 — bizcommon publish 凭据明文

**情况：** LEG-APP-CLIENT-G5-005 + AI-RULE-KMP-PUBLISH-001。当前 bizcommon `build.gradle.kts:259-263` 仍是明文 `password = "..."`，违反规则。

**待确认：**
1. 该明文凭据是否仍有效？是否需要立即轮换？
2. 是否安排迁移到 `PasswordCredentials::class.java` + gradle.properties 注入方案？

**评估默认值：** 立即立 issue 跟进；规范层标红，规则保持强制。

## PENDING-APP-CLIENT-G5-7 — Default Hierarchy Template vs 显式 dependsOn

**情况：** LEG-APP-CLIENT-G5-001 / LEG-APP-CLIENT-G5-002。当前两个模块都还是显式写法，新模块按规范不再这么写。

**待确认：**
1. 是否在 KMP 升级 / Kotlin 版本对齐时，统一把现有模块也改为 Default Hierarchy Template？
2. 升级期间是否需要加一段过渡说明？

**评估默认值：** 升级时统一改写；本批次不动。

## PENDING-APP-CLIENT-G5-8 — `instrumentedTestVariant.sourceSetTree.set(...)` 实验 API

**情况：** LEG-APP-CLIENT-G5-003。`@ExperimentalKotlinGradlePluginApi` 接口在未来版本可能变化。

**待确认：**
1. 当前是否锁定 KGP 某版本以避免该 API 漂移？
2. 是否在规范中显式标注"如 KGP 升级，此处需要回归测试 androidTest 是否能引用 commonTest 类"？

**评估默认值：** 在规范层加 reminder；不阻止使用。

## PENDING-APP-CLIENT-G5-9 — Contract 模块 marker interface 形态

**情况：** EV-APP-CLIENT-G5-001 + POS-APP-CLIENT-G5-006。`IQuotesProvider` / `IAccountProvider` / `IOrderProvider` 当前是空 marker interface。

**待确认：**
1. 这是临时占位，还是 contract 模块的目标形态？是否计划补充关键方法签名？
2. 若空 interface 长期保留，规范是否需要在"contract 接口必须包含至少一个方法"上做出妥协？

**评估默认值：** 视后续业务进展决定；规范层暂不强制要求 interface 必须有方法。
