---
doc_id: "app-client-android-architecture-standard"
title: "APP Android 架构规范（trade batch 萃取）"
domain: "app-client"
sub_domain: "android"
doc_type: "standard"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260526-212711-app-client"
tags:
  - "app-client"
  - "android"
  - "standard"
  - "architecture"
  - "hszq-app"
  - "batch-001-trade-architecture"
---

# APP Android 架构规范（trade batch 萃取）

本文件从 hszq-app trade 模块 batch-001-trade-architecture 萃取。APP 负责人已确认，status: **active**。

## P1 新增业务功能必须使用 Clean Architecture 三层分离

> level: P1 · status: active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-26 · recommended_action: promoted-to-active · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 适用范围

- trade 模块及后续新功能模块的全新业务 feature 开发。
- 不适用于既有 MVVM 或 MVP 模块的维护性修改。

### 推荐做法

1. 新功能按 `data/` → `domain/` → `presentation/` 三层组织包结构。
2. `domain` 层包含：Model（纯数据类）、Repository 接口、UseCase（封装单一业务操作）。
3. `data` 层包含：DTO、Mapper（DTO → Domain Model）、RepositoryImpl（实现 domain 接口）。
4. `presentation` 层包含：ViewModel（持有 UiState）、Mapper（Domain → UiModel）、UiModel、Activity/Fragment。
5. 依赖方向严格单向：`presentation` → `domain` ← `data`，presentation 和 data 不互相依赖。

### AI 生成代码要求

1. AI 新建 trade 模块 feature 时，必须先生成 `domain/` 层接口和 UseCase，再生成 `data/` 和 `presentation/`。
2. AI 不得在 ViewModel 中直接调用网络 API 或 DAO；必须经过 UseCase。
3. AI 不得在 UseCase 中引用 Android framework 类型（Context、LiveData 等）。

### Code Review 检查项

- [ ] 新功能是否按 data/domain/presentation 三层组织？
- [ ] ViewModel 是否仅通过 UseCase 获取数据？
- [ ] domain 层是否与 Android framework 解耦？
- [ ] 依赖方向是否符合 presentation → domain ← data？

### Evidence

- EV-APP-CLIENT-001（evidence/code-facts-batch-001.md）— Clean Architecture pilot 完整 10 文件结构
- EV-APP-CLIENT-002 — GetDemoTextUseCase 调用链
- EV-APP-CLIENT-003 — DemoTextViewModel impact 分析证明 pilot 隔离良好

---

## P1 ViewModel 必须按职责分类使用，不得混合多种关注点

> level: P1 · status: active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-26 · recommended_action: promoted-to-active · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 适用范围

- 所有使用 ViewModel 的 Android 模块。

### 推荐做法

trade 模块中 ViewModel 按职责分为三类，新代码应明确归类：

| 类型 | 职责 | 典型示例 |
| --- | --- | --- |
| 业务 ViewModel | 持有 UiState，通过 UseCase 获取和转换数据 | DemoTextViewModel |
| 事件协调 ViewModel | 跨 Fragment 事件总线，只持有事件 LiveData，不含业务逻辑 | TradeTabEventVM |
| Scope 共享 ViewModel | 跨子 Fragment 共享状态属性，不做网络请求 | StockDetailTradeHomeVM |

1. 一个 ViewModel 只能属于一种类型；不得在事件协调型 ViewModel 中塞入业务数据请求。
2. 业务 ViewModel 优先通过 UseCase 获取数据；scope 共享型可直接持有状态属性。
3. ViewModel 行数上限建议 400 行；超过时应拆分职责或引入 UseCase/Mapper。

### AI 生成代码要求

1. AI 新建 ViewModel 前必须先判断属于哪种类型，在类注释或命名中体现。
2. AI 不得在事件协调型 ViewModel（`*EventVM`）中添加网络请求或数据转换逻辑。
3. AI 不得让单个 ViewModel 超过 400 行而不提出拆分建议。

### Code Review 检查项

- [ ] ViewModel 是否明确属于业务/事件协调/scope 共享之一？
- [ ] 事件协调型 ViewModel 是否只包含事件 LiveData？
- [ ] ViewModel 行数是否在 400 行以内？
- [ ] 超过 400 行时是否有拆分计划？

### Evidence

- EV-APP-CLIENT-004 — trade 模块 ViewModel 清单
- EV-APP-CLIENT-005 — TradeTabEventVM 事件总线型
- EV-APP-CLIENT-006 — PreferencesSettingViewModel 多 Fragment 共享
- EV-APP-CLIENT-010 — SecuritiesViewModel 超大类（反例）
- EV-APP-CLIENT-013 — StockDetailTradeHomeVM scope 共享型

---

## FORBIDDEN 新代码不得引入 MVP Presenter 模式

> level: FORBIDDEN · status: active · source_kind: extracted · evidence_tier: single-project · risk_tag: high · owner: TBD · last_reviewed: 2026-05-26 · recommended_action: promoted-to-active · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 适用范围

- 所有新增代码。不影响既有 MVP 代码的维护性修改。

### 禁止做法

1. 不得新建继承或实现 Presenter 接口的类。
2. 不得在新 Fragment/Activity 中实现 `onInitPresenter` 生命周期钩子。
3. 不得新建 MVP Contract 接口。

### 替代方案

使用 ViewModel + UseCase（Clean Architecture）或至少 ViewModel + 直接 API 调用（MVVM）。

### AI 生成代码要求

1. AI 不得生成任何包含 `Presenter`、`onInitPresenter`、`Contract` 的新 MVP 代码。
2. AI 如被要求在 MVP 模块中修改，必须在修改结论中建议迁移到 MVVM。

### Code Review 检查项

- [ ] 新增文件是否包含 Presenter 类定义？
- [ ] 新增文件是否实现 onInitPresenter？
- [ ] 如果是维护性修改既有 MVP 代码，是否标注了迁移建议？

### Evidence

- EV-APP-CLIENT-008 — MVP 遗留 onInitPresenter（trade 内 3 处）
- EV-APP-CLIENT-011 — trade 模块仅 demo 为 Clean Architecture，其余为混合

---

## P2 ViewModel 不得直接持有 DAO 或 Database 引用

> level: P2 · status: active · source_kind: extracted · evidence_tier: single-project · risk_tag: low · owner: TBD · last_reviewed: 2026-05-26 · recommended_action: promoted-to-active · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 适用范围

- 新增 ViewModel 代码。既有 Repository 直连 DAO 模式为历史兼容。

### 推荐做法

1. ViewModel 通过 UseCase 或 Repository 接口获取数据。
2. DAO / Database 引用只能出现在 Repository 实现层（`data/` 包）。
3. 既有 `StockPositionRepository` 直连 DAO 的模式作为历史兼容维护，新代码不扩大。

### AI 生成代码要求

1. AI 不得在 ViewModel 中直接 import Room DAO 或 Database 类。
2. AI 在数据层新建 Repository 时，必须先定义 domain 层接口。

### Code Review 检查项

- [ ] 新 ViewModel 是否直接 import 了 DAO/Database？
- [ ] 新 Repository 是否有对应 domain 层接口？

### Evidence

- EV-APP-CLIENT-007 — StockPositionRepository 无 UseCase 直连 DAO（历史兼容反例）
- EV-APP-CLIENT-001 — DemoTextRepository 接口 + Impl 分离（正例）

---

## P2 非标 ViewModel 封装（BaseVMDataHelper 模式）不得扩散

> level: P2 · status: active · source_kind: extracted · evidence_tier: single-project · risk_tag: low · owner: TBD · last_reviewed: 2026-05-26 · recommended_action: promoted-to-active · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 适用范围

- 新增需要 ViewModel 集成的模块。

### 禁止扩散

1. `BaseVMDataHelper` 通过泛型反射桥接 ViewModel 的方式仅限 order 子模块历史兼容使用。
2. 新模块不得继承 `BaseVMDataHelper` 或复制其反射获取 ViewModel 的 pattern。
3. 新模块使用标准 `ViewModelProvider` / `by viewModels()` / `by activityViewModels()`。

### AI 生成代码要求

1. AI 不得生成继承 BaseVMDataHelper 的新类。
2. AI 在 order 子模块修改时不主动迁移 BaseVMDataHelper，但须标注非标。

### Code Review 检查项

- [ ] 新文件是否继承了 BaseVMDataHelper？
- [ ] 新 ViewModel 获取方式是否使用标准 API？

### Evidence

- EV-APP-CLIENT-009 — BaseVMDataHelper 非标封装（order 子模块）
