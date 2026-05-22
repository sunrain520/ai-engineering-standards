---
doc_id: "app-client-20260522-100947-app-client-project-profile"
title: "项目画像：kaz-mvp"
domain: "app-client"
sub_domain: "common"
doc_type: "project-profile"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "project-profile"
  - "context-governance"
---

# App Client 项目画像：kaz-mvp

## 1. 本次输入

- run_id: `20260522-100947-app-client`
- extraction_mode: `profile-first`
- project_paths:
  - `/Users/kuang/xiaobu/kaz-mvp`
- output_target: `engineering-standards/01-app-client/`
- sensitive_file_policy: `sanitized-existence-only`
- index_support:
  - Serena project: `kaz-mvp`
  - Serena languages: `kotlin`, `java`
  - Serena index status: `ready`
  - GitNexus project note: `kaz-app`，来自目标项目 `AGENTS.md` 自动上下文

## 2. 推断结果

| 项 | 推断 | 置信度 | 需要确认 |
| --- | --- | --- | --- |
| domain | `app-client` | high | 否 |
| sub_domain | `android`, `kmp-shared`, `module-boundary`, `ui-component`, `testing`, `performance`, `industry-trading` | high | 需要确认本次正式萃取优先 batch |
| industry | `securities-trading` / `brokerage-app` | medium | 需要负责人确认行业规则边界 |
| project_shape | Gradle 多模块 Android App + KMP 子模块 + 本地组件库 + 多业务 feature | high | 否 |

推断依据：

- 根目录存在 `settings.gradle`、`build.gradle`、`gradle.properties`、`gradlew`。
- `settings.gradle` 声明 `app-kaz`、`app-core`、`core`、`contract`、`feature`、`resources`、`submodules:hscomponents`、`submodules/biz-common` 等模块。
- `submodules/biz-common` 存在 `settings.gradle.kts`、`build.gradle.kts`、`commonMain` 路径和 KMP 模块目录。
- `.serena/project.yml` 声明 Kotlin / Java LSP 语言；`.serena/index-ready.json` 标记索引 ready。
- 目标仓库已有 `KAZ模块化架构设计规范.md`、`architecture.md`、`AGENTS.md` 等架构说明。

## 3. 结构信号

| 信号 | 路径或证据 | 说明 |
| --- | --- | --- |
| Android 主 App 壳 | `app-kaz/` | App 入口、applicationId、GlobalApplication、渠道和构建脚本 |
| 启动核心容器 | `app-core/` | 启动、首页容器、推送、更新、主 Tab 等宿主能力 |
| 原生基础能力层 | `core/` | UI kit、utils、share、web、PDP、RN、App 更新等跨域能力 |
| 跨业务契约层 | `contract/` | trade、quotes、platform 契约模块 |
| 原生业务模块层 | `feature/` | trade、quotes、user_operations、community_info 等业务 UI/平台适配 |
| KMP 业务核心层 | `submodules/biz-common/` | commonMain、apps、modules/core、modules/trade、modules/market、modules/platform |
| 本地 UI 组件库 | `submodules/hscomponents/` | 目标项目说明中要求 XML 优先使用该组件库 |
| 共享资源库 | `resources/library/` | 跨模块资源发布与复用 |
| 版本管理插件 | `hszq-version/` | `includeBuild` 方式提供依赖版本常量 |
| 规范与设计材料 | `KAZ模块化架构设计规范.md`、`architecture.md`、`openspec/`、`specs/` | 可作为后续负责人确认或 owner-confirmed 对照材料 |

## 4. 候选模块

| module | domain | sub_domain | task_type 候选 | 代表性路径候选 | 风险 |
| --- | --- | --- | --- | --- | --- |
| App Shell | app-client | android | app-bootstrap / module-assembly | `app-kaz/build.gradle`, `app-kaz/src/main/AndroidManifest.xml`, `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt` | 启动链路高影响，需限制读取范围 |
| App Core | app-client | android | startup-container / main-tabs | `app-core/build.gradle`, `app-core/src/main/AndroidManifest.xml`, `app-core/src/main/java/com/hstong/app_core/main/mvvm/MainTabViewModel.kt` | 启动、首页、全局状态耦合 |
| Native Core UI | app-client | android | base-fragment / ui-state | `core/core-ui-kit/build.gradle`, `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/base/BaseFragment.kt`, `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseLoadDataFragment.kt` | 基类规范影响面大 |
| Contract Layer | app-client | module-boundary | cross-module-contract | `contract/trade/build.gradle.kts`, `contract/quotes/build.gradle.kts`, `contract/platform/build.gradle.kts` | 只应萃取契约边界，不读取实现细节 |
| Trade Feature | app-client | android | feature-module / route-provider | `feature/trade/trade-core/build.gradle`, `feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/TradeRouter.kt`, `feature/trade/trade-order/src/main/java/com/hstong/trade/order/provider/OrderPageProvider.kt` | 交易域高风险，行业规则需负责人确认 |
| Account Feature | app-client | android | page-composition / account-state | `feature/trade/trade-account/build.gradle`, `feature/trade/trade-account/src/main/java/com/hstong/trade/account/security/SecurityAccountFragment.kt`, `.serena/memories/security-account/fragment-hierarchy.md` | 涉及账户资产视图，避免复制业务数据 |
| Quotes / Watchlist Feature | app-client | android | feature-module / market-ui | `feature/kaz-quotes/market/build.gradle`, `feature/kaz-quotes/watchlist/build.gradle`, `feature/kaz-quotes/watchlist/src/main/java/com/kaz/watchlist/WatchListFragment.kt` | 行情展示和自选配置需区分平台 UI 与 KMP 逻辑 |
| User Operations | app-client | android | feature-module / settings-profile | `feature/user_operations/kaz_me/build.gradle`, `feature/user_operations/message_center/build.gradle`, `feature/user_operations/message_center/AGENTS.md` | 子目录存在局部治理说明，需作为 batch 输入 |
| KMP Shared Core | app-client | kmp-shared | clean-architecture / usecase-repository | `submodules/biz-common/settings.gradle.kts`, `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/usecase/GetAllOrdersUseCase.kt`, `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/repository/OrderRepository.kt` | KMP 子模块是单独 Git 工作区，需独立确认边界 |
| KMP Account / Assets | app-client | kmp-shared | domain-model / presenter-flow | `.serena/memories/assets-module-architecture.md`, `.serena/memories/securityaccount-architecture.md`, `submodules/biz-common/modules/trade/trade-account/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/account/securityaccount/presentation/asset/SecurityAssetPresenter.kt` | 可用 Serena memory 做候选摘要，但正式 evidence 仍需读选定文件 |
| Build Governance | app-client | build-governance | dependency-version / local-fast-build | `settings.gradle`, `build.gradle`, `gradle.properties`, `hszq-version/` | `gradle.properties` 含凭据字段，仅记录脱敏存在事实 |
| Existing Standards | app-client | module-boundary | owner-confirmed-comparison | `KAZ模块化架构设计规范.md`, `architecture.md`, `AGENTS.md` | 可用于冲突检测，不得自动升级为 active |

## 5. 敏感与排除范围

| path | reason | handling |
| --- | --- | --- |
| `gradle.properties` | 包含 release keystore、Nexus/repo 凭据字段 | sanitized-existence-only；不得复制原值 |
| `local.properties` | 本地环境配置 | sanitized-existence-only |
| `hsconfig/` | 签名、渠道或环境配置候选 | sanitized-existence-only |
| `AGENTS.md` 中自动上下文敏感片段 | 包含 Figma token 字段 | sanitized-existence-only；不得复制原值 |
| `.claude/`, `.codex/`, `.agents/` | 运行时/代理生成资产，不是业务规范 evidence | excluded-runtime |
| `.gradle/`, `.kotlin/`, `build/` | 构建产物或缓存 | excluded-generated |
| `.git`, `.gitnexus`, `.code-review-graph`, `.serena/cache` | 索引或 VCS 内部状态 | excluded-tooling；可记录索引状态，不读缓存内容 |
| `submodules/*/.git` | 子模块 Git 内部状态 | excluded-vcs |
| `repo/`, `*.jar`, `*.aar`, `libs/` | 依赖产物或二进制 | excluded-dependency |

## 6. 已有规范文档

| path | 用途 | 后续处理 |
| --- | --- | --- |
| `KAZ模块化架构设计规范.md` | 模块边界、双层架构、依赖方向 | 正式萃取时作为 owner-confirmed 候选对照 |
| `architecture.md` | KAZ Android App 架构概览 | 可辅助 batch 选择和冲突检测 |
| `AGENTS.md` | 当前仓库开发治理与自动上下文 | 只摘取非敏感治理事实 |
| `feature/trade/*/README.md` | 交易子模块说明 | 适合 trade batch 使用 |
| `feature/user_operations/**/AGENTS.md` | 用户运营局部治理说明 | 适合 user-operations batch 使用 |
| `openspec/specs/*/spec.md` | 功能规格 | 仅作为需求背景，不直接生成编码规则 |
| `specs/*/design.md` | 设计材料 | 可用于 focused-module 对照 |
| `.serena/memories/*.md` | Serena 记忆摘要 | 可作为候选路径索引，不替代真实 evidence |

## 7. 需要用户确认

- [ ] 本次正式萃取优先选择哪个 `batch_id`。
- [ ] 是否允许把 `KAZ模块化架构设计规范.md` 作为 owner-confirmed 对照材料。
- [ ] KMP 子模块 `submodules/biz-common` 是否作为同一轮 app-client 萃取的一部分，还是后续单独按子项目处理。
- [ ] 行业域 `securities-trading` 规则是否需要指定负责人确认。
- [ ] 是否存在除本文件列出的敏感路径外必须排除的路径。

## 8. 禁止事项

- 本文件不是团队规范规则。
- 不得把本文件的推断直接升级为 `standard-*.md` 规则。
- 后续正式萃取必须选择一个 batch。
- 后续正式萃取不得读取或复制密钥、token、生产凭据、用户隐私或交易数据原文。
