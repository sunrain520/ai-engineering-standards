---
doc_id: "app-client-module-boundary-evidence-positive"
title: "APP Module Boundary Positive Examples"
domain: "app-client"
sub_domain: "module-boundary"
doc_type: "evidence-positive"
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
  - "positive-example"
---

# APP Module Boundary Positive Examples

## POS-APP-1: contract 模块不依赖 feature 实现模块

- source_facts:
  - `evidence/code-facts.md「EV-APP-1」`
  - `evidence/code-facts.md「EV-APP-2」`
  - `evidence/code-facts.md「EV-APP-3」`
  - `evidence/code-facts.md「EV-APP-4」`
- path_pattern:
  - `contract/{domain}/build.gradle.kts`
  - `contract/{domain}/src/main/AndroidManifest.xml`
  - `KAZ模块化架构设计规范.md`
- observed_positive_pattern: contract 模块以独立 library 存在，构建脚本未依赖 feature 实现模块；架构文档把 contract 明确为跨域稳定边界，并禁止 contract 反向依赖 feature。
- applicable_rule_candidate: `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」`
- evidence_tier: `single-project`

## POS-APP-2: App 壳按进程边界收敛启动初始化

- source_facts:
  - `evidence/code-facts.md「EV-APP-8」`
- path_pattern:
  - `app-kaz/src/main/java/**/GlobalApplication.kt`
- observed_positive_pattern: 子进程只执行基础配置并提前返回，宿主进程才执行 Router、RN runtime、Push、业务容器和生命周期服务初始化。
- applicable_rule_candidate: `standard-android.md「P1 App 壳初始化必须区分宿主进程与子进程」`
- evidence_tier: `single-project`

## POS-APP-3: Android 页面基类按状态复杂度分层

- source_facts:
  - `evidence/code-facts.md「EV-APP-9」`
  - `evidence/code-facts.md「EV-APP-10」`
- path_pattern:
  - `core/core-ui-kit/src/main/java/**/BaseFragment.kt`
  - `core/core-ui-kit/src/main/java/**/BaseLoadDataFragment.kt`
  - `core/core-ui-kit/src/main/java/**/BaseViewModel.kt`
- observed_positive_pattern: 基础 Fragment、加载态 Fragment 和 ViewModel 基类分别承载布局可见性、加载态管理和状态输出能力。
- applicable_rule_candidate: `standard-android.md「P1 页面基类选择必须匹配页面状态复杂度」`
- evidence_tier: `single-project`

## POS-APP-4: KMP trade-order 按 UseCase / Repository / Presenter 分层

- source_facts:
  - `evidence/code-facts.md「EV-APP-16」`
  - `evidence/code-facts.md「EV-APP-17」`
  - `evidence/code-facts.md「EV-APP-18」`
- path_pattern:
  - `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/**/domain/**`
  - `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/**/presentation/**`
- observed_positive_pattern: UseCase 依赖 Repository 接口，Presenter 通过 StateFlow 输出 UI 状态并处理分页与请求防重。
- applicable_rule_candidate: `standard-kmp-shared.md「P1 KMP 业务能力必须保持 UseCase -> Repository 的依赖方向」`
- evidence_tier: `single-project`

## POS-APP-5: 根 Gradle 集中治理本地替换和快速构建

- source_facts:
  - `evidence/code-facts.md「EV-APP-20」`
  - `evidence/code-facts.md「EV-APP-21」`
  - `evidence/code-facts.md「EV-APP-22」`
- path_pattern:
  - `settings.gradle`
  - `build.gradle`
  - `hszq-version/build.gradle`
- observed_positive_pattern: 本地 Maven 产物替换集中在根 settings，快速构建开关集中跳过校验任务，内部版本插件通过 included build 接入。
- applicable_rule_candidate: `standard-build-governance.md「P1 本地工程替换必须集中在根 settings 治理」`
- evidence_tier: `single-project`
