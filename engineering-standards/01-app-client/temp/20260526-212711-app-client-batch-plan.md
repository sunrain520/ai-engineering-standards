---
doc_id: "app-client-20260526-212711-hszq-app-batch-plan"
title: "hszq-app Batch Plan"
domain: "app-client"
sub_domain: "android"
doc_type: "batch-plan"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260526-212711-app-client"
tags:
  - "app-client"
  - "android"
  - "batch-plan"
  - "hszq-app"
---

# hszq-app Batch Plan

> run_id: 20260526-212711-app-client
> 目标仓库: hszq-app
> evidence 来源: GitNexus 深度索引 + 目录扫描

## Batch 列表

### batch-001: trade 模块架构 pattern

| 字段 | 值 |
| --- | --- |
| batch_id | batch-001-trade-architecture |
| status | **ready** |
| sub_domain | android |
| task_type | 架构分层 + 数据层 |
| 优先级 | P1（高）|
| evidence_kind | code-facts, positive-examples |
| 预期产物 | standard-android.md（MVVM/Clean Architecture 规范补充）|

**candidate_files:**
- `trade/demo/domain/usecase/GetDemoTextUseCase.kt`
- `trade/demo/presentation/viewmodel/DemoTextViewModel.kt`
- `trade/common/dao/StockPositionRepository.kt`
- `trade/common/dao/GridBackTestResultRepository.kt`
- `trade/**/ViewModel*.kt`（trade 内所有 ViewModel）
- `trade/**/Presenter*.kt`（trade 内 MVP 遗留对比）

**excluded_paths:**
- `trade/build/**`
- `trade/**/test/**`（首轮不含测试文件）

**理由:** trade 模块内聚度最高，同时包含当前推荐架构（MVVM + Clean Architecture pilot）和历史遗留（MVP），能在一个 batch 内同时产出 positive-examples 和 legacy-compatible evidence。

**stop_conditions:**
- candidate_files 全部无法读取
- 找不到 2 个以上 ViewModel 或 UseCase 实现

---

### batch-002: feed + community 基类治理

| 字段 | 值 |
| --- | --- |
| batch_id | batch-002-base-class-governance |
| status | **ready** |
| sub_domain | android |
| task_type | 基类治理 + 模块边界 |
| 优先级 | P1（高）|
| evidence_kind | code-facts, forbidden-examples, legacy-compatible |
| 预期产物 | standard-android.md（基类行数/职责/跨模块约束）|

**candidate_files:**
- `feed/src/main/java/com/hstong/feed/base/BaseFeedFragment.kt`
- `community/src/**/*Fragment*.kt`（13 个直接子类）
- `feed/src/**/IBaseFeedAdapterOwner*`
- `feed/src/**/IDataProvider*`
- `platformcomm/src/**` 中被 BaseFeedFragment import 的 bean/interface

**excluded_paths:**
- `community/build/**`
- `feed/build/**`

**理由:** BaseFeedFragment 是全仓 CRITICAL 级高风险基类（943 行，82 个下游影响，13 个直接子类跨 community 模块）。这个 batch 能产出基类职责边界、行数上限、跨模块继承约束等高价值规范 evidence。

**stop_conditions:**
- BaseFeedFragment.kt 无法读取
- 找不到 3 个以上直接子类

---

### batch-003: platformcomm 共享底座

| 字段 | 值 |
| --- | --- |
| batch_id | batch-003-platformcomm-shared-api |
| status | **ready** |
| sub_domain | module-boundary |
| task_type | 共享模块 API 契约 |
| 优先级 | P2（中）|
| evidence_kind | code-facts, positive-examples |
| 预期产物 | standard-module-boundary.md（共享模块 API 暴露规范）|

**candidate_files:**
- `platformcomm/src/**/*.kt`
- `platformcomm/src/**/*.java`
- 被其他模块 import 的 platformcomm public class/interface（通过 GitNexus impact 获取）

**excluded_paths:**
- `platformcomm/build/**`

**理由:** platformcomm 是全仓共享底座（118 文件），被 feed、community、quotes 等多模块直接 import，是模块边界治理的核心节点。

**stop_conditions:**
- platformcomm/src 下 public class 不足 10 个

---

### batch-004: quotes 模块分层

| 字段 | 值 |
| --- | --- |
| batch_id | batch-004-quotes-module-layering |
| status | **needs-confirmation** |
| sub_domain | android |
| task_type | 架构分层 + 模块粒度 |
| 优先级 | P2（中）|
| evidence_kind | code-facts |
| 预期产物 | standard-android.md（大模块拆分策略、行情模块分层）|

**candidate_files:**
- `quotes/src/**/*Activity*.kt`
- `quotes/src/**/*Fragment*.kt`
- `quotes/src/**/*Presenter*.kt`（MVP 遗留）
- `quotes/src/**/*Api*.kt`

**excluded_paths:**
- `quotes/build/**`
- `quotes/src/**/test/**`

**理由:** quotes 是全仓体量最大的模块（1356 文件，占 24%），但内部 pattern 可能混杂（MVP 遗留 + 传统 Fragment）。需要确认是否当前仍在维护、是否适合作为代表性 evidence。

**needs-confirmation 原因:**
- quotes 模块是否仍是团队活跃维护区域？
- quotes 内部是否已有计划迁移到 MVVM/Clean Architecture？
- 如果处于迁移中，萃取出来的规则会很快过期。

**stop_conditions:**
- 无法确认 quotes 的维护状态和迁移计划

---

### batch-005: 数据层统一治理

| 字段 | 值 |
| --- | --- |
| batch_id | batch-005-data-layer-unification |
| status | **blocked** |
| sub_domain | android |
| task_type | 数据层组织 |
| 优先级 | P3（低）|
| evidence_kind | code-facts, pending-confirmation |
| 预期产物 | pending-confirmation.md（数据层统一策略待确认）|

**blocked 原因:**
- Repository pattern 仅在 trade/dao 零星出现
- UseCase 仅 trade/demo 一个示例
- Api 直调是绝大多数模块现状（177 个 Api 符号）
- 如果团队还没定「数据层应该统一成什么」，萃取出来的只能是 pending-confirmation

**解除条件:**
- 团队确认 trade/demo 的 Clean Architecture 三层（UseCase + Repository + ViewModel）为推荐 pattern
- 或者团队确认「维持 Api 直调也是可接受的现状」

---

## Batch 排序建议

```text
优先执行                                                等待确认 / blocked
┌──────────┐    ┌──────────────────────┐    ┌────────────────────────┐    ┌──────────────────────┐
│ batch-001│ -> │ batch-002            │ -> │ batch-003              │    │ batch-004 (confirm)  │
│ trade    │    │ feed+community       │    │ platformcomm           │    │ batch-005 (blocked)  │
│ 架构     │    │ 基类治理             │    │ 共享底座               │    │                      │
└──────────┘    └──────────────────────┘    └────────────────────────┘    └──────────────────────┘
   ready             ready                        ready                       needs-confirmation / blocked
```

## 下一步

选择一个 `status: ready` 的 batch（batch-001 / batch-002 / batch-003），提供 `selected_batch.batch_id` 进入 `batch-extraction`。

推荐从 **batch-001-trade-architecture** 开始：trade 模块内聚度高、已有新旧 pattern 对比、evidence 边界清晰。
