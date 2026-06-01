---
doc_id: "app-client-20260526-134644-project-profile"
title: "App-Client 项目画像 — kaz-mvp"
domain: "app-client"
sub_domain: "common"
doc_type: "project-profile"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260526-134644-app-client"
tags:
  - "app-client"
  - "project-profile"
  - "context-governance"
---

# App-Client 项目画像 — kaz-mvp

## 1. 本次输入

- run_id: `20260526-134644-app-client`
- run_mode: `auto`
- extraction_mode: `profile-first`（broad_input → 强制）
- project_paths:
  - `/Users/kuang/xiaobu/kaz-mvp`
- output_target: `engineering-standards/01-app-client/`（已存在基线，仅作为冲突检测，不写入）
- sensitive_file_policy: `sanitized-existence-only`
- broad_input: `true`
- broad_input_reason: 路径包含 `.git`（worktree 指针），并存在 ≥ 2 个独立 manifest

## 2. 推断结果

| 项 | 推断 | 置信度 | 需要确认 |
| --- | --- | --- | --- |
| primary domain | `app-client` | high | 否 |
| sub_domain（主） | `android` | high | 否 |
| sub_domain（次） | `kmp-shared` | high | 否（biz-common 子树） |
| sub_domain（潜在） | `ios` | medium | 是（iosMain 仅存在于 biz-common shared） |
| industry | `securities`（行情 / 交易 / 自选 / 社区资讯） | high | 否 |
| project_shape | `monorepo`（单仓多模块 + git submodule） | high | 否 |
| dev_domains | `[app-client]` | high | 否 |
| industry_domains | `[securities]` | high | 否 |

inferred_decisions：
- `extraction_mode = profile-first`：因 `broad_input = true`，强制降级（条件：`.git` 存在 + 多 manifest）
- `domain = app-client`：`build.gradle` ×8 + `build.gradle.kts` ×4 + `settings.gradle` 含 `:app-kaz` / `:feature:trade:**` / `:feature:kaz-quotes:**`，命中 `app-client` 信号集
- `sub_domain = kmp-shared`：`submodules/biz-common/**/src/{commonMain,androidMain,iosMain}/` 完整三套 source set
- `industry = securities`：模块命名 `feature/trade/**`、`feature/kaz-quotes/**`、`feature/community_info/**`、`condition_order` 文档

## 3. 结构信号

| 信号 | 路径或证据 | 说明 |
| --- | --- | --- |
| Gradle 多模块根 | `settings.gradle` | 显式 include `:app-kaz` / `:app-core` / `:core/**` / `:contract/**` / `:feature/**` / `:resources/library` |
| KMP shared layer | `submodules/biz-common/{contract, bizcommon, common-provider, biz-search, modules/market}/src/{commonMain,androidMain,iosMain}/` | git submodule，KMP 三套 source set |
| 主 App | `app-kaz/build.gradle`（applicationId 通过 architecture.md 描述：`com.huasheng.kaz`） | 引入 ARouter / SensorsData / AndroidAOP / Huawei HMS / KSP |
| 启动核心容器 | `app-core/build.gradle` | namespace `com.hstong.app_core`，`MainActivity` / `MainTabViewModel` |
| 跨域共享层 | `core/core-ui-kit/`、`core/core-utils/`、`core/capability/{share, kaz-pdp, updata-apk, react-native, web}` | UI kit / 工具 / 能力封装 |
| 跨域通信契约 | `contract/{trade, quotes, platform}/build.gradle.kts` | 模块间通信契约层（KTS） |
| Feature 子域 | `feature/trade/{trade-core, trade-account, trade-order, trade-execution}` 等 | 业务域分层：交易 / 行情 / 用户与运营 / 社区资讯 |
| 自定义构建插件 | `settings.gradle` 引入 `gradle-repo` / `module-repo`，并在 `dependencySubstitution` 中替换 Maven → 本地工程 | 团队自研构建治理（Maven ↔ project 切换） |
| 现有内部规范 | `KAZ模块化架构设计规范.md`、`architecture.md`、`AGENTS.md`、`feature/user_operations/AGENTS.md` | 仓内已有架构 & 协作规范文档 |
| Spec / Plan | `specs/FSREQ-20260317-TABOPT-001`、`docs/{brainstorms, first, plans, superpowers}` | 团队 spec-first / brainstorm 沉淀 |

## 4. 候选模块

| module | domain | sub_domain | task_type 候选 | 代表性路径候选 | 风险 |
| --- | --- | --- | --- | --- | --- |
| `app-kaz` | app-client | android | `app-bootstrap`、`launch-flow` | `app-kaz/src/main/**`、`app-kaz/build.gradle` | 多 SDK 集成（HMS / SensorsData / ARouter / AOP）信号 |
| `app-core` | app-client | android | `app-bootstrap`、`tab-navigation` | `app-core/src/main/**` | 启动容器，主 Tab 装配 |
| `feature/trade/trade-execution` | app-client | android | `trade-order`、`form-validation` | `feature/trade/trade-execution/src/main/java/**` | 行业 P0：下单链路 |
| `feature/trade/trade-account` | app-client | android | `account-binding`、`auth` | `feature/trade/trade-account/src/main/**` | 交易账户绑定 |
| `feature/trade/trade-order` | app-client | android | `order-list`、`pagination` | `feature/trade/trade-order/src/main/**` | 订单列表查询 |
| `feature/trade/trade-core` | app-client | android | `trade-foundation`、`shared-state` | `feature/trade/trade-core/src/main/**` | 交易公共 |
| `feature/kaz-quotes/market` | app-client | android | `market-list`、`real-time-push` | `feature/kaz-quotes/market/src/main/**` | 行情推送/刷新策略 |
| `feature/kaz-quotes/watchlist` | app-client | android | `watchlist-edit`、`local-cache` | `feature/kaz-quotes/watchlist/src/main/**` | 自选 |
| `feature/kaz-quotes/quotes-common` | app-client | android | `quotes-shared`、`subscription-mgmt` | `feature/kaz-quotes/quotes-common/src/main/**` | 行情 SDK 封装 |
| `feature/community_info/community` | app-client | android | `feed-list`、`webview` | `feature/community_info/community/src/main/**` | 社区资讯 |
| `feature/user_operations/kaz_me` | app-client | android | `me-page`、`profile-edit` | `feature/user_operations/kaz_me/src/main/**` | 已有 `AGENTS.md` 协作规范 |
| `feature/user_operations/message_center` | app-client | android | `notification-list`、`badge` | `feature/user_operations/message_center/src/main/**` | 消息中心 |
| `core/core-ui-kit` | app-client | android | `ui-component`、`theme` | `core/core-ui-kit/src/main/**` | UI 基础组件库 |
| `core/core-utils` | app-client | android | `utility-lib`、`extension` | `core/core-utils/src/main/**` | 通用工具 |
| `core/capability/kaz-pdp` | app-client | android | `ad-sdk`、`tracking` | `core/capability/kaz-pdp/src/main/**` | 广告/PDP 封装 |
| `core/capability/share` | app-client | android | `social-share` | `core/capability/share/src/main/**` |  |
| `core/capability/react-native` | app-client | android | `rn-bridge` | `core/capability/react-native/src/main/**` | RN 容器 |
| `core/capability/web` | app-client | android | `webview-bridge`、`jsbridge` | `core/capability/web/src/main/**` |  |
| `contract/trade` | app-client | kmp-shared | `module-contract`、`api-design` | `contract/trade/src/**`、`contract/trade/build.gradle.kts` | KTS + 跨模块通信契约 |
| `contract/quotes` | app-client | kmp-shared | `module-contract` | `contract/quotes/src/**` | 行情契约 |
| `contract/platform` | app-client | kmp-shared | `module-contract` | `contract/platform/src/**` | 平台契约 |
| `submodules/biz-common/contract` | app-client | kmp-shared | `kmp-contract`、`expect-actual` | `submodules/biz-common/contract/src/{commonMain,androidMain,iosMain}/**` | KMP 契约层（git submodule） |
| `submodules/biz-common/bizcommon` | app-client | kmp-shared | `kmp-bizcommon`、`shared-business` | `submodules/biz-common/bizcommon/src/{commonMain,androidMain,iosMain}/**` | KMP 业务公共 |
| `submodules/biz-common/common-provider` | app-client | kmp-shared | `kmp-platform-bridge` | `submodules/biz-common/common-provider/src/{commonMain,androidMain,iosMain}/**` | 平台能力提供方 |
| `submodules/biz-common/biz-search` | app-client | kmp-shared | `kmp-search` | `submodules/biz-common/biz-search/src/{commonMain,androidMain,iosMain}/**` | KMP 搜索 |
| `submodules/biz-common/modules/market` | app-client | kmp-shared | `kmp-market` | `submodules/biz-common/modules/market/src/commonMain/**` | KMP 行情模块 |

## 5. 敏感与排除范围

| path | reason | handling |
| --- | --- | --- |
| `app-kaz/google-services.json` | SDK 配置（Google/Firebase）— 命中 `google-services*.json` 规则 | sanitized-existence-only（仅记录存在事实，不读取内容） |
| `local.properties` | Gradle 本地属性，可能含 keystore 路径 | sanitized-existence-only |
| `build/`、各模块 `build/`、`/.gradle`、`/.idea` | 构建产物 / IDE 工程 | excluded（不扫描，不计 evidence） |
| `pager_reach/`（多处） | `.gitignore` 标注本地临时目录 | excluded |
| `tmpmob/` | `.gitignore` 标注临时 | excluded |
| `submodules/`（除 `biz-common`） | `.gitignore` 标注 | excluded（biz-common 例外，作为 KMP shared 候选） |
| `resources/` 顶层 | `.gitignore` 标注（与子模块 `resources/library` 区分） | 顶层 excluded，`resources/library` 候选 |
| `feature/trade/bug图文/` | 非源代码资产（图片/截图） | excluded |
| `2026-04-24-092201-rn-084x.txt` | 临时根级文件 | excluded |

未触发任何 `*.key` / `*.pem` / `id_rsa*` / `*credentials*` / `*token*` 命中。

## 6. 候选技术栈

- 语言：Kotlin（含 Kotlin Multiplatform `commonMain/androidMain/iosMain`）、Java、少量 Swift（仅 KMP iosMain）
- 构建：Gradle（部分模块为 KTS），自定义插件 `gradle-repo` / `module-repo`，本地 dependencySubstitution
- DI / 路由 / AOP：ARouter、AndroidAOP、KSP（按 architecture.md 描述）
- 三方 SDK：Huawei HMS、SensorsData
- 跨平台：KMP（biz-common 子树），React Native（`core/capability/react-native`），WebView（`core/capability/web`）

## 7. 已有规范文档（仓库内）

- `architecture.md` — 模块全景图（最后更新 2026-03-17）
- `KAZ模块化架构设计规范.md`
- `AGENTS.md`（根） / `feature/user_operations/AGENTS.md`
- `CLAUDE.md`（根 / `doc/CLAUDE.md`）
- `doc/` 目录下 24 篇专题文档（KMP / 交易登录 / 条件单 / 订单重构 / 依赖关系等）
- `specs/FSREQ-*` 团队需求规格沉淀

> 已有团队文档将作为 Phase 1 evidence 的"对照源"，规则正文不引用其原文路径，只在 evidence 文件里留链接。

## 8. 已有规范基线（本仓 — engineering-standards/）

- `engineering-standards/01-app-client/` 已存在（active 基线，本次萃取仅作为冲突检测，不覆盖）
- 其它 domain 目录（`02-pc-client` / `03-frontend` / `04-backend` 等）本次不涉及

## 9. 待确认问题

- [ ] kmp-shared 子领域是否在本次萃取范围内？（biz-common 是 git submodule，是否纳入第一批 batch）
- [ ] iOS 端规范是否需要独立 batch？（iosMain 仅出现在 biz-common shared，纯 native iOS 工程未在仓内）
- [ ] industry-securities 维度是否启用？（涉及行情/交易，激活后会触发额外行业 review checklist）
- [ ] 现有 `engineering-standards/01-app-client/` 中已 active 的规则范围与本次预期 sub_domain 是否冲突？需要负责人 review

## 10. 禁止事项

- 本文件不是团队规范规则。
- 不得把本文件的推断直接升级为 `standard.md` 规则。
- 后续正式萃取必须选择一个 batch。
