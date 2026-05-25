---
doc_id: "app-client-20260525-app-client-project-profile"
title: "项目画像：kaz-mvp"
domain: "app-client"
sub_domain: "common"
doc_type: "project-profile"
version: "v0.2.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260525-app-client"
tags:
  - "app-client"
  - "industry"
  - "project-profile"
---

# 项目画像：kaz-mvp（20260525 增量更新）

> 本 profile 基于 `20260522-100947-app-client-project-profile.md` 继承，增量记录 20260525 run 的新发现和 industry 域补充。

## 1. 本次输入

- run_id: `20260525-app-client`
- extraction_mode: `profile-first`
- project_paths: `/Users/kuang/xiaobu/kaz-mvp`
- domains: `app-client` + `09-industry`（本次新增 industry 萃取范围）
- output_targets:
  - `engineering-standards/01-app-client/`
  - `engineering-standards/09-industry/`
- sensitive_file_policy: `sanitized-existence-only`

## 2. 技术栈快照

| 层级 | 技术 | 信号 |
|---|---|---|
| 语言 | Kotlin (2624 files) + Java | `.kt` 扫描 |
| 构建 | Gradle（根 `build.gradle` + 多模块 `build.gradle.kts`）| `settings.gradle`, `gradlew` |
| 架构 | Android 原生 + KMP 双层 | `submodules/biz-common/commonMain/` |
| 模块化 | APP + core + contract + feature 4 类 | `KAZ模块化架构设计规范.md` |
| 行业 | 证券/交易（Securities & Trading）| `feature/trade`, `feature/kaz-quotes`, `contract/trade`, `contract/quotes` |

## 3. 模块地图（继承 20260522 + 行业补充）

### 原生层
```
app-kaz          (App 壳)
app-core         (启动核心 + 首页容器)
common/          (原生公共库 + widget-kit)
core/            (uikit / utils / capability/*)
contract/        (trade / quotes / platform)   ← 行业边界定义
feature/
  trade/         (trade-core / trade-account / trade-order / trade-execution)  ← 交易业务
  kaz-quotes/    (quotes-common / market / watchlist)                          ← 行情业务
  user_operations/ (kaz_me / message_center)
  community_info/
resources/library
```

### KMP 层
```
submodules/biz-common/
  modules/trade/        (trade-order / trade-account / ...)  ← 交易 Clean Architecture
  modules/market/       (行情 KMP 核心)
  modules/platform/     (平台/用户 KMP 核心)
submodules/hscomponents/ (本地 UI 组件库)
```

## 4. 行业维度信号（09-industry 新增）

| 信号类别 | 具体路径 / 文件 | 说明 |
|---|---|---|
| 下单规格 | `openspec/specs/trade-place-order/spec.md` | 交易下单 API 设计规格 |
| 订单域 KMP | `submodules/biz-common/modules/trade/trade-order/` | UseCase / Repository / Presenter 完整 Clean Architecture |
| 账户域 KMP | `submodules/biz-common/modules/trade/trade-account/` | 证券账户/资产 KMP 层 |
| 交易契约 | `contract/trade/build.gradle.kts` | 跨模块交易接口 |
| 行情契约 | `contract/quotes/build.gradle.kts` | 行情接口定义 |
| 行情 UI | `feature/kaz-quotes/watchlist/` | 自选股功能（含 WatchListFragment）|
| 架构规范文档 | `KAZ模块化架构设计规范.md` | owner-confirmed 候选，可用于规则对照 |
| 交易登录 | `specs/FSREQ-20260328-TRADELOGIN-001/` | 交易登录 Spec-First 记录 |

## 5. 既有规范冲突基线（append-only 保护）

| 文件 | status | 保护级别 |
|---|---|---|
| `standard-android.md` | draft | 可追加新章节，不覆盖 |
| `standard-kmp-shared.md` | draft | 可追加新章节，不覆盖 |
| `standard-build-governance.md` | draft | 可追加新章节，不覆盖 |
| `standard-module-boundary.md` | **active** | **铁律：任何写入均禁止** |
| `ai-rules.md` | **active** | **铁律：任何写入均禁止** |
| `pending-confirmation.md` | **active** | **铁律：任何写入均禁止** |
