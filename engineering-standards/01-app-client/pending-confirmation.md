---
doc_id: "app-client-pending-confirmation"
title: "APP 待确认规则"
domain: "app-client"
sub_domain: "common"
doc_type: "pending-confirmation"
version: "v0.1.0"
status: "pending"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "common"
  - "pending-confirmation"
---

# APP 待确认规则

本文件用于记录 APP 规范萃取中证据不足、需要端负责人确认或需要多端对齐的规则候选。这里的内容不得被 AI 当作强制规范执行。

## PENDING-APP-1: contract 模块 UI 依赖是否应收敛

- 状态：已确认并升级
- 处理结果：已升级为 `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」`
- 确认人：APP 架构负责人
- 确认日期：2026-05-22
- 拟定规则正文标题：`P2 contract 模块应保持依赖轻量`
- 拟定 source_doc：`standard-module-boundary.md`
- 来源（事实 / 行业 / 用户提议）：`evidence/code-facts.md「EV-APP-5」`
- 关联 evidence：
  - `evidence/code-facts.md「EV-APP-5」`
- 缺失 evidence:
  - 是否有 contract 源码实际使用 AppCompat 或 Material 类型。
  - 是否存在历史兼容或 Gradle 模板原因导致统一引入。
  - 架构负责人是否要求 contract 模块从 Android library 收敛为更轻量形态。
- 需要确认的问题:
  - 新增 contract 模块是否允许默认引入 UI 依赖。
  - 现有 `contract/trade`、`contract/quotes`、`contract/platform` 的 UI 依赖是否应删除或迁移到 feature。
- 建议负责人角色：APP 架构负责人
- 建议负责人：TBD
- 截止日期 (SLA)：TBD
- 下一步：选择该 pending 项作为 focused-module batch，读取具体源码使用点或由负责人确认。
- 状态迁移意向：
  - [x] 升级到 `standard-module-boundary.md` 的 `status: active`
  - [ ] 标记为 `legacy-compatible`
  - [ ] `rejected`
  - [ ] 继续 `pending`，新截止日期：TBD

## PENDING-APP-2: core-ui-kit 是否应拆除对聚合 KMP 入口的直接依赖

- 状态：待确认
- 拟定规则正文标题：`P2 Android UI 基础层不得默认依赖聚合 KMP App 入口`
- 拟定 source_doc：`standard-android.md`
- 来源（事实 / 行业 / 用户提议）：`evidence/code-facts.md「EV-APP-11」`
- 关联 evidence：
  - `evidence/code-facts.md「EV-APP-11」`
  - `evidence/legacy-compatible.md「LEG-APP-1」`
- 缺失 evidence:
  - 当前 `core-ui-kit` 实际使用 `biz_kaz_app` 的类型清单。
  - 可替换的更小 KMP core utils 模块。
  - 迁移后对现有页面编译和运行的影响。
- 需要确认的问题:
  - 新增 UI 基础层依赖是否禁止直接依赖聚合 KMP App 入口。
  - 现有依赖是否按模块拆分迁移，还是保留历史兼容。
- 建议负责人角色：APP 架构负责人 / KMP 负责人
- 建议负责人：TBD
- 截止日期 (SLA)：TBD
- 下一步：单独选择 focused-module batch 读取 `core-ui-kit` 对 KMP 类型的具体使用点。
- 状态迁移意向：
  - [ ] 升级到 `standard-android.md`
  - [x] 标记为 `legacy-compatible`
  - [ ] `rejected`
  - [ ] 继续 `pending`，新截止日期：TBD

## PENDING-APP-3: 账户容器是否允许直接注入 KMP UseCase

- 状态：待确认
- 拟定规则正文标题：`P2 账户容器不得直接承载 KMP UseCase 调用`
- 拟定 source_doc：`standard-android.md`
- 来源（事实 / 行业 / 用户提议）：`evidence/code-facts.md「EV-APP-15」`
- 关联 evidence：
  - `evidence/code-facts.md「EV-APP-15」`
  - `evidence/legacy-compatible.md「LEG-APP-3」`
- 缺失 evidence:
  - 账户页 ViewModel / Presenter 可承接 tab 排序逻辑的替代路径。
  - 负责人对容器层和 KMP Presentation 层职责边界的确认。
- 需要确认的问题:
  - 容器 Fragment 是否仅允许编排页面结构和导航消费。
  - 现有 UseCase 注入是否作为历史兼容保留，还是迁移到 ViewModel / Presenter。
- 建议负责人角色：交易 APP 负责人 / KMP 负责人
- 建议负责人：TBD
- 截止日期 (SLA)：TBD
- 下一步：按账户页架构选择 focused-module batch，读取 ViewModel、Presenter 和 tab 排序实现链路。
- 状态迁移意向：
  - [ ] 升级到 `standard-android.md`
  - [x] 标记为 `legacy-compatible`
  - [ ] `rejected`
  - [ ] 继续 `pending`，新截止日期：TBD
