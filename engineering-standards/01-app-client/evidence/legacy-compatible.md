---
doc_id: "app-client-evidence-legacy"
title: "APP Legacy Compatible Examples"
domain: "app-client"
sub_domains:
  - "android"
doc_type: "evidence-legacy"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260522-100947-app-client"
source_batches:
  - "app-client-android-core-ui-state"
  - "app-client-android-trade-route-provider"
  - "app-client-android-trade-account-page-composition"
tags:
  - "app-client"
  - "evidence"
  - "legacy-compatible"
---

# APP Legacy Compatible Examples

下列条目记录跨多个 batch 的历史兼容写法，AI 不应复制扩散，但兼容期内允许保留。

## LEG-APP-1: core-ui-kit 直接依赖聚合 KMP 入口

- source_facts:
  - `evidence/code-facts.md「EV-APP-11」`
- path: `core/core-ui-kit/build.gradle`
- observed_legacy_pattern: `core-ui-kit` 当前仍 `implementation Deps.Lib.biz_kaz_app`，并有注释说明不应直接依赖整个 KMP 入口，应改为直接依赖所需 KMP core utils 模块。
- compatible_reason: 当前构建仍依赖该配置，不能在规范萃取阶段自动删除。
- suggested_rule_candidate: `standard-android.md「P1 页面基类选择必须匹配页面状态复杂度」` 的 Review 风险项。
- evidence_tier: `single-project`

## LEG-APP-2: deprecated TradeRouter 历史 H5 跳转入口

- source_facts:
  - `evidence/code-facts.md「EV-APP-13」`
- path: `feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/TradeRouter.kt`
- observed_legacy_pattern: `TradeRouter` 被标记 `@Deprecated("")`，但仍以单例方式拼接 H5 URL 并通过 PageRouter 跳转。
- compatible_reason: 旧业务入口仍可能被调用，新增代码不应复制该模式。
- suggested_rule_candidate: `standard-android.md「P2 交易共享能力应收敛到 trade-core 等 feature-core 模块」`
- evidence_tier: `single-project`

## LEG-APP-3: 账户容器直接注入 KMP UseCase

- source_facts:
  - `evidence/code-facts.md「EV-APP-15」`
- path: `feature/trade/trade-account/src/main/java/com/hstong/trade/account/security/SecurityAccountFragment.kt`
- observed_legacy_pattern: 账户容器 Fragment 直接注入 `TabSortConfigUseCase`，源码注释标明“待优化，直接调用了 usecase”。
- compatible_reason: 现有账户页 tab 排序依赖该调用，需负责人确认迁移边界后再收敛。
- suggested_rule_candidate: `standard-android.md「P2 账户容器页应只编排页面结构和导航消费」`
- evidence_tier: `single-project`
