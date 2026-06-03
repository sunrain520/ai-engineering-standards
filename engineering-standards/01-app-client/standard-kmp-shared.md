---
doc_id: "app-client-kmp-shared-standard"
title: "APP KMP Shared 团队规范"
domain: "app-client"
sub_domain: "kmp-shared"
doc_type: "standard"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "kmp-shared"
  - "standard"
  - "ai-coding"
---

# APP KMP Shared 团队规范

本文件从 `hszq-app` Android 侧使用 KMP Presenter / Service / StateFlow 的桥接代码萃取。由于当前授权路径未包含 `submodules/biz-common` 源码，本文只约束 Android 侧 KMP 消费方式，不对 KMP shared 源码内部架构作强制结论。

## P1 Android ViewModel 获取 KMP Presenter 必须注入生命周期 Scope

> level: P1 · status: auto-active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 3 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

交易账户总览 ViewModel 通过 Koin 获取 `OverallAccountOverviewPresenter`，并把 `viewModelScope` 作为参数注入 Presenter。页面通过 Presenter 暴露的 Flow 更新 UI，ViewModel 负责触发刷新和监听请求状态。这个模式说明 Android 侧不应直接 new KMP Presenter 或 Service，而应把生命周期 Scope 显式交给依赖注入或工厂边界，让 KMP 侧协程和 Android ViewModel 生命周期对齐。

### 适用范围

- Android ViewModel 调用 KMP Presenter、Koin 注入、Presenter 生命周期、KMP Flow 消费。

### 推荐做法

1. Android ViewModel 获取 KMP Presenter 时，应通过 Koin、Module 或工厂方法注入。
2. Presenter 构造需要协程作用域时，应传入 `viewModelScope` 或明确的业务 Scope。
3. Fragment 不直接创建 Presenter，不绕过 ViewModel 持有业务状态。

### 禁止做法

1. 禁止在 Fragment 中直接构造 KMP Presenter 或 Service。
2. 禁止让 KMP Presenter 使用与页面生命周期无关的临时 Scope。

### 正例

```kotlin
class AccountOverviewVM(application: Application) : LoadDataVM(application), KoinComponent {
    val presenter: OverallAccountOverviewPresenter = get { parametersOf(viewModelScope) }
}
```

### AI 生成代码要求

1. AI 新增 Android ViewModel 消费 KMP Presenter 时，必须通过注入或工厂边界获取。
2. AI 必须把协程作用域显式传入 Presenter，而不是让 Presenter 自行创建全局作用域。

### Code Review 检查项

- [ ] Presenter 获取路径经过 ViewModel 注入或工厂边界。
- [ ] Presenter 使用的 Scope 与 ViewModel 生命周期对齐。
- [ ] Fragment 没有直接构造 KMP 业务对象。

### Evidence

- `evidence/code-facts.md「EV-APP-26」`
- `evidence/code-facts.md「EV-APP-27」`

## P1 KMP Flow 到 Android UI 的订阅必须由 Fragment 生命周期收口

> level: P1 · status: auto-active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 6 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

账户总览 Fragment 在 `repeatOnLifecycle(STARTED)` 中并行收集 `requestState`、`assetCardFlow`、`accountListFlow`、`isDesensitized` 和 `selectedCurrencyFlow`。这些 Flow 都来自 KMP Presenter 或其相关管理器。把订阅收口到 `viewLifecycleOwner` 能保证 View 销毁后订阅停止，避免 Presenter 后续状态继续写入已经释放的 binding。

### 适用范围

- KMP StateFlow / SharedFlow、Android Fragment UI 渲染、Presenter 状态订阅。

### 推荐做法

1. Fragment 只在 View 生命周期内收集 KMP Flow。
2. 多路 Flow 可在同一个 `repeatOnLifecycle` block 内通过子 `launch` 并行收集。
3. UI 更新使用当前 View 的 binding 或 `bindingOrNull`，避免销毁后写 UI。

### 禁止做法

1. 禁止在 Fragment 字段初始化或 `onCreate` 中长期收集 UI Flow。
2. 禁止用全局 Scope 直接 collect KMP UI 状态。

### AI 生成代码要求

1. AI 新增 KMP Flow UI 订阅时，必须绑定 `viewLifecycleOwner`。
2. AI 不得在 UI 层使用 `GlobalScope` 收集 KMP Flow。

### Code Review 检查项

- [ ] KMP UI Flow 在 `repeatOnLifecycle` 或等价项目封装中收集。
- [ ] UI 更新没有越过 View 生命周期。
- [ ] 多路订阅的生命周期边界一致。

### Evidence

- `evidence/code-facts.md「EV-APP-28」`
- `evidence/code-facts.md「EV-APP-29」`

## P2 KMP Service 全局包装属于历史兼容，不作为新增模板

> level: P2 · status: pending-confirmation · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: move-to-pending · confidence_tier: low · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: 1 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

`watchlist-core` 中存在 `WatchListKmp` object 包装 KMP `WatchlistService(globalScope)` 的历史实现。它把 Service 访问集中到一个 Android 侧 object，避免调用方到处直接构造 Service；但 `globalScope` 与页面生命周期无关，不能作为新页面或新 KMP 能力的默认模板。由于当前未读取 KMP shared 源码和该全局 Scope 的完整生命周期治理，本条只进入待确认。

### 适用范围

- Watchlist KMP bridge、KMP Service 访问、全局 object 兼容层。

### 推荐做法

1. 已有全局 bridge 可保留兼容，但新增能力应优先使用 ViewModel scope / owner scope 注入。
2. Android 调用方不应绕过 bridge 直接持有 KMP Service。
3. 如需保留全局 Scope，应由负责人确认生命周期、释放和测试边界。

### 禁止做法

1. 禁止把 `WatchlistService(globalScope)` 模式复制到新 KMP 能力。
2. 禁止在 Fragment 或 ViewModel 中散落直接构造 KMP Service。

### AI 生成代码要求

1. AI 遇到全局 KMP Service bridge 时，应标记为历史兼容。
2. AI 新增 KMP Service 调用时，不得默认使用全局 Scope。

### Code Review 检查项

- [ ] 新增 KMP Service 调用没有复制 `globalScope` 模式。
- [ ] 调用方没有绕过已有 bridge 直接构造 Service。
- [ ] 继续保留全局 bridge 时有负责人确认或迁移计划。

### Evidence

- `evidence/legacy-compatible.md「LEG-APP-2」`
- `evidence/code-facts.md「EV-APP-30」`
