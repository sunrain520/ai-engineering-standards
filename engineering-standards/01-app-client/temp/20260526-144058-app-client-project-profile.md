---
doc_id: "app-client-20260526-144058-app-client-project-profile"
title: "项目画像：kaz-mvp"
domain: "app-client"
sub_domain: "common"
doc_type: "project-profile"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260526-144058-app-client"
tags:
  - "app-client"
  - "project-profile"
  - "context-governance"
---

# App Client 项目画像：kaz-mvp

## 1. 本次输入

- run_id: `20260526-144058-app-client`
- run_mode: `auto`
- extraction_mode: `profile-first`
- project_paths:
  - `/Users/kuang/xiaobu/kaz-mvp`
- output_target: `engineering-standards/01-app-client/`
- sensitive_file_policy: `sanitized-existence-only`
- output_action: `append`
- maintainer_context: `false`
- operator: `leokuang`

## 2. scope_summary

```yaml
scope_summary:
  run_id: "20260526-144058-app-client"
  run_mode: "auto"
  project_paths:
    - "/Users/kuang/xiaobu/kaz-mvp"
  extraction_mode: "profile-first"
  output_action: "append"
  maintainer_context: false
  domain: "01-app-client"
  dev_domains:
    - "app-client"
  industry_domains:
    - "securities"
  output_scope: "single-domain"
  sub_domains:
    - "android"
    - "kmp-shared"
    - "module-boundary"
    - "build-governance"
    - "ui-component"
    - "industry-trading"
  broad_input: true
  sensitive_file_policy: "sanitized-existence-only"
  inferred_decisions:
    - decision: "完整 Gradle 多模块仓库，强制 profile-first"
      confidence: "high"
      basis: "根目录含 settings.gradle/build.gradle，settings.gradle include 多个 app/core/contract/feature/submodules 模块"
    - decision: "主要研发域为 app-client"
      confidence: "high"
      basis: "Android Gradle App + KMP 子工程 + 本地 UI 组件库信号同时命中"
    - decision: "GitNexus 不作为本次 evidence provider"
      confidence: "high"
      basis: "target graph facts 显示 query_global_graph=false 且 gitnexus degraded"
  open_questions:
    - "industry-trading 是留在 01-app-client，还是后续转入 09-industry 独立萃取？"
    - "是否允许把 KAZ模块化架构设计规范.md 作为 owner-confirmed 对照材料？"
  scope_conflicts: []
```

## 3. GitNexus Readiness

| 项 | 结果 |
| --- | --- |
| target graph facts | `/Users/kuang/xiaobu/kaz-mvp/.spec-first/graph/graph-facts.json` |
| `capabilities.query_global_graph` | `false` |
| ready primary providers | `code-review-graph` |
| degraded providers | `gitnexus` |
| 处理 | 按 skill 降级策略使用目录、manifest、现有文档和文件路径采样，不把 GitNexus 结果写作 evidence 来源 |

## 4. 推断结果

| 项 | 推断 | 置信度 | 需要确认 |
| --- | --- | --- | --- |
| domain | `app-client` | high | 否 |
| sub_domain | `android`, `kmp-shared`, `module-boundary`, `build-governance`, `ui-component`, `industry-trading` | high | 需要选择单个正式萃取 batch |
| industry | `securities` / `brokerage-trading` | medium | 需要确认是否并入 APP 规范或转入 `09-industry` |
| project_shape | Gradle 多模块 Android App + KMP 业务核心 + 本地组件库 + 多业务 feature | high | 否 |

推断依据：

- 根目录存在 `settings.gradle`、`build.gradle`、`gradlew` 和多处模块级 `build.gradle` / `build.gradle.kts`。
- `settings.gradle` 声明 `app-kaz`、`app-core`、`core:*`、`contract:*`、`feature:*`、`resources:library`、`common:widget-kit`、`submodules:hscomponents:hscomponents`。
- `submodules/biz-common/settings.gradle.kts` 声明 KMP 子工程 `bizcommon`、`modules:core:*`、`modules:trade:*`、`modules:market`、`modules:platform:*`、`apps:kaz-app`。
- `AGENTS.md` / `CLAUDE.md` 明示 Kotlin/Java Android App、KMP 共享业务核心、`app-kaz` 主入口、`app-core` 启动核心、`contract` 跨业务契约、`feature` 原生业务层、`hscomponents` 组件库。
- `submodules/biz-common/CLAUDE.md` 明示 KMP Clean Architecture、UseCase/Repository/Presenter、Moko Resources、Ktor、MMKV、SKIE 等技术栈。

## 5. 目录结构摘要

| 路径 | 角色 | 说明 |
| --- | --- | --- |
| `app-kaz/` | App 壳 | App 入口、`GlobalApplication`、渠道与构建装配 |
| `app-core/` | 宿主核心 | Loading/首页容器/Tab/推送/扫码/PDF/更新检查等宿主能力 |
| `common/common/` | Android 通用基础库 | 公共资源、网络/配置/工具/通用 UI 能力 |
| `common/widget-kit/` | 轻量控件库 | KAZ 通用 View 候选 |
| `core/` | 跨业务基础能力 | `core-ui-kit`、`core-utils`、share、PDP、RN、web、App 更新 |
| `contract/` | 跨业务契约层 | `trade`、`quotes`、`platform` 稳定接口和轻量 DTO |
| `feature/trade/` | 交易原生业务层 | trade-core/account/order/execution |
| `feature/kaz-quotes/` | 行情原生业务层 | market、quotes-common、watchlist |
| `feature/user_operations/` | 用户运营层 | kaz_me、message_center |
| `feature/community_info/` | 社区资讯层 | community |
| `resources/library/` | 共享资源库 | 跨模块资源发布与复用 |
| `submodules/biz-common/` | KMP 业务核心 | commonMain/androidMain/iosMain，trade/market/platform/core 等共享模块 |
| `submodules/hscomponents/` | 本地 UI 组件库 | XML 布局优先复用的设计系统/组件库 |
| `hszq-version/` | 版本治理插件 | `includeBuild` 方式统一依赖版本 |

## 6. 候选技术栈

| 类别 | 信号 | 说明 |
| --- | --- | --- |
| Android | AGP `8.11.0`、compileSdk `35`、minSdk `21` | 来自根 `build.gradle` 与目标项目 `CLAUDE.md` |
| Kotlin / Java | Kotlin Gradle Plugin `2.2.0`，目标项目说明 Java 17 | 根工程与业务代码混合 Kotlin/Java |
| KMP | `submodules/biz-common/settings.gradle.kts`、`commonMain` / `androidMain` / `iosMain` | 跨端共享业务逻辑 |
| 资源与多语言 | Moko Resources、`MR.strings.*.toLocal()`、`toResStr()` | 来自目标 `CLAUDE.md` / `submodules/biz-common/CLAUDE.md` |
| 网络与序列化 | Ktor、Kotlin Serialization、FastJsonTool、JsonUtils | 原生层和 KMP 层分工具 |
| 组件与 UI | `core/core-ui-kit`、`submodules/hscomponents`、BaseQuickAdapter、ConstraintLayout | 页面基类和组件复用规则已有明确项目约束 |
| 构建治理 | `includeBuild 'hszq-version'`、dependencySubstitution、本地 fast build 开关 | 适合 build-governance batch |

## 7. 代表性模块候选

| module | domain | sub_domain | task_type 候选 | 代表性路径候选 | 风险 |
| --- | --- | --- | --- | --- | --- |
| App Shell | app-client | android | app-bootstrap / process-init | `app-kaz/build.gradle`, `app-kaz/src/main/AndroidManifest.xml`, `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt` | 启动链路影响面大 |
| App Core | app-client | android | host-container / main-tab | `app-core/build.gradle`, `app-core/src/main/AndroidManifest.xml`, `app-core/src/main/java/com/hstong/app_core/main/mvvm/MainTabViewModel.kt` | 首页容器与全局能力耦合 |
| Core UI Kit | app-client | android | base-fragment / ui-state | `core/core-ui-kit/.../BaseFragment.kt`, `BaseLoadDataFragment.kt`, `BaseViewModel.kt` | 基类规范影响所有页面 |
| Contract Layer | app-client | module-boundary | cross-module-contract | `contract/trade/build.gradle.kts`, `contract/quotes/build.gradle.kts`, `contract/platform/build.gradle.kts` | 已有 active 规范，后续不得覆盖 |
| Trade Feature | app-client | android | route-provider / order-page | `feature/trade/trade-core/.../TradeRouter.kt`, `feature/trade/trade-order/.../OrderPageProvider.kt` | 交易域高风险，需避免行业规则泛化 |
| Account Feature | app-client | android | page-composition / account-state | `feature/trade/trade-account/.../SecurityAccountFragment.kt`, `SecurityAccountVM.kt` | 涉及账户资产展示，禁止读取用户数据 |
| Quotes / Watchlist | app-client | android | market-ui / watchlist-state | `feature/kaz-quotes/market/.../MarketFragment.kt`, `feature/kaz-quotes/watchlist/.../WatchListFragment.kt` | 行情实时数据边界需确认 |
| KMP Trade Order | app-client | kmp-shared | clean-architecture-usecase-repository | `submodules/biz-common/modules/trade/trade-order/.../GetAllOrdersUseCase.kt`, `OrderRepository.kt`, `AllOrdersPresenter.kt`, `OrderUIMapper.kt` | KMP 子工程可单独成批 |
| KMP Account Assets | app-client | kmp-shared | account-assets-clean-architecture | `SecurityAccountAssetUseCase.kt`, `SecurityAccountRepository.kt`, `SecurityAssetPresenter.kt`, `SecurityAssetDtoMapper.kt` | 账户/资产语义需脱敏审查 |
| Build Governance | app-client | build-governance | dependency-version-local-fast-build | `settings.gradle`, `build.gradle`, `hszq-version/build.gradle` | `gradle.properties` 只能记录存在事实 |
| UI Components | app-client | ui-component | design-system-consumption | `submodules/hscomponents/hscomponents/build.gradle.kts`, `KAZ模块化架构设计规范.md` | 需补组件源码样本后再成规则 |

## 8. 敏感文件存在事实与排除范围

| path | reason | handling |
| --- | --- | --- |
| `gradle.properties` | 凭据/签名/私有仓库变量候选 | sanitized-existence-only，不读取原值 |
| `local.properties` | 本地环境配置 | sanitized-existence-only |
| `hsconfig/` | 签名、渠道或环境配置候选 | sanitized-existence-only |
| `.mcp.json` | 本地工具配置候选 | sanitized-existence-only |
| `AGENTS.md` 中 token 字段 | 自动上下文包含 token 字段 | 只记录脱敏存在事实，不复制原值 |
| `.claude/`, `.codex/`, `.agents/skills/` | host/runtime generated mirrors | excluded-runtime |
| `.gradle/`, `.kotlin/`, `build/`, `.cxx/` | 构建缓存或产物 | excluded-generated |
| `.git`, `.gitnexus/`, `.code-review-graph/`, `.serena/` | VCS / 图谱 / 索引运行资产 | excluded-tooling；只读取 graph-facts 摘要 |
| `repo/`, `libs/`, `*.jar`, `*.aar` | 二进制依赖或本地仓库 | excluded-dependency |
| `feature/trade/**/bug*`, `*.jpeg` | 问题附件或截图 | out-of-scope |

## 9. 已有规范文档

| path | 当前状态 | 后续处理 |
| --- | --- | --- |
| `engineering-standards/01-app-client/standard-android.md` | draft | 可在 selected batch 后 append-only 追加，不覆盖 |
| `engineering-standards/01-app-client/standard-kmp-shared.md` | draft | 可在 selected batch 后 append-only 追加，不覆盖 |
| `engineering-standards/01-app-client/standard-build-governance.md` | draft | 可在 selected batch 后 append-only 追加，不覆盖 |
| `engineering-standards/01-app-client/standard-module-boundary.md` | active | 只做冲突基线，禁止自动覆盖 |
| `engineering-standards/01-app-client/ai-rules.md` | draft | selected batch 后只从 standard 派生 |
| `engineering-standards/01-app-client/review-checklist.md` | draft | selected batch 后只从 standard 派生 |
| `engineering-standards/01-app-client/pending-confirmation.md` | pending | 需要确认项追加前应去重 |

已有规则标题基线：

- `standard-android.md`: 页面基类选择、App 壳初始化、feature-core、宿主 Fragment、StateMapper、ViewBinding、EventBus。
- `standard-kmp-shared.md`: UseCase -> Repository、Presenter 状态流、模块矩阵、桥接 object、EffectFlow。
- `standard-module-boundary.md`: contract 稳定边界、contract 轻量依赖。
- `standard-build-governance.md`: 本地工程替换、快速构建开关。

## 10. 待确认问题

- [ ] 本次正式萃取优先选择哪个 `batch_id`。
- [ ] `industry-trading` 是继续留在 `01-app-client` 中作为 APP 证券交易批次，还是拆到 `09-industry` 单独跑。
- [ ] 是否允许把 `KAZ模块化架构设计规范.md` 作为 owner-confirmed 对照材料。
- [ ] `submodules/biz-common` 是否继续纳入同一轮 APP 客户端萃取，还是作为 KMP 子项目独立运行。
- [ ] 除本文件列出的敏感路径外，是否还有必须排除的业务数据目录。

## 11. 禁止事项

- 本文件不是团队规范规则。
- 不得把本文件的推断直接升级为 `standard-*.md`、`ai-rules.md` 或 `review-checklist.md`。
- 后续正式萃取必须选择一个 `ready` batch，且一次只处理一个 batch。
- 任何阶段都不得读取、复制或改写密钥、token、生产凭据、用户隐私、账户数据、订单数据原文。
