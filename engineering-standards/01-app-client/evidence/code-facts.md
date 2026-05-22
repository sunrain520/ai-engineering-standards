---
doc_id: "app-client-module-boundary-evidence-code-facts"
title: "APP Module Boundary Code Facts"
domain: "app-client"
sub_domain: "module-boundary"
doc_type: "evidence-code-facts"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260522-100947-app-client"
source_batch: "app-client-module-boundary-contract-layer"
tags:
  - "app-client"
  - "module-boundary"
  - "evidence"
---

# APP Module Boundary Code Facts

## EV-APP-1: contract 模块构建脚本保持同构

- batch_id: `app-client-module-boundary-contract-layer`
- path:
  - `contract/trade/build.gradle.kts`
  - `contract/quotes/build.gradle.kts`
  - `contract/platform/build.gradle.kts`
- observed_pattern: 三个 contract 模块均声明为 Android library，并使用相同的 Kotlin Android 插件、`compileSdk = 35`、`minSdk = 24`、Java/Kotlin 11 配置、consumer proguard 配置和测试依赖结构。
- file_role: `gradle-module-config`
- evidence_kind: `positive`
- occurrences: 3
- boundary: `contract 模块集合`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-2: contract 模块未在构建脚本中依赖 feature 实现模块

- batch_id: `app-client-module-boundary-contract-layer`
- path:
  - `contract/trade/build.gradle.kts`
  - `contract/quotes/build.gradle.kts`
  - `contract/platform/build.gradle.kts`
- observed_pattern: 三个 contract 模块的 `dependencies` 块只包含 AndroidX、Material、JUnit 和 AndroidX Test 依赖，未出现 `project(":feature:...")`、`project(":app-...")` 或其他 feature 实现模块依赖。
- file_role: `gradle-dependency-config`
- evidence_kind: `positive`
- occurrences: 3
- boundary: `contract 模块集合`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-3: contract 模块当前没有业务实现源码

- batch_id: `app-client-module-boundary-contract-layer`
- path:
  - `contract/trade/src/main/AndroidManifest.xml`
  - `contract/quotes/src/main/AndroidManifest.xml`
  - `contract/platform/src/main/AndroidManifest.xml`
- observed_pattern: 三个 contract 模块的 `src/main` 下只观察到空 AndroidManifest；在本 batch 读取范围内未发现 Kotlin / Java 业务实现源码。
- file_role: `android-manifest`
- evidence_kind: `positive`
- occurrences: 3
- boundary: `contract 模块集合`
- confidence: `high`
- sensitive_handling: `none`
- inferred_from: `find contract -maxdepth 5` 的文件清单与三个 manifest 内容

## EV-APP-4: 现有 owner-confirmed 文档定义 contract 为稳定跨域边界

- batch_id: `app-client-module-boundary-contract-layer`
- path: `KAZ模块化架构设计规范.md`
- observed_pattern: 模块化设计文档把原生 `contract` 定义为跨业务域协作的稳定边界，典型内容包括 Service 接口、轻量 DTO、必要常量和调用协议；并明确 `feature -> contract` 是允许依赖方向，`contract -> feature`、跨域调用绕过 `contract` 是禁止方向。
- file_role: `owner-confirmed-architecture-doc`
- evidence_kind: `positive`
- occurrences: 1
- boundary: `owner-confirmed 文档`
- confidence: `medium`
- sensitive_handling: `none`
- inferred_from: `null`

## EV-APP-5: contract 模块仍引入 UI 相关外部依赖

- batch_id: `app-client-module-boundary-contract-layer`
- path:
  - `contract/trade/build.gradle.kts`
  - `contract/quotes/build.gradle.kts`
  - `contract/platform/build.gradle.kts`
- observed_pattern: 三个 contract 模块均引入 `androidx.appcompat:appcompat` 和 `com.google.android.material:material`。该事实与“轻量 contract”方向存在潜在治理问题，但当前 batch 未读取到具体源码使用点。
- file_role: `gradle-dependency-config`
- evidence_kind: `unknown`
- occurrences: 3
- boundary: `contract 模块集合`
- confidence: `medium`
- sensitive_handling: `none`
- inferred_from: `null`

## 本批次分类摘要

```yaml
classification:
  recommended:
    - facts:
        - EV-APP-1
        - EV-APP-2
        - EV-APP-3
        - EV-APP-4
      reason: "代码配置与 owner-confirmed 架构文档共同支持 contract 作为稳定跨域边界，且当前未依赖 feature 实现模块。"
  forbidden: []
  legacy_compatible: []
  pending_confirmation:
    - facts:
        - EV-APP-5
      reason: "contract 模块引入 UI 相关依赖是否应收敛，需要架构负责人确认；当前没有源码使用点，不能直接升级为禁止规则。"
  conflict: []
stop_conditions_hit: []
unread_candidates: []
```
