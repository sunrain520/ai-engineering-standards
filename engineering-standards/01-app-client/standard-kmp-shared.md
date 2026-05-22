---
doc_id: "app-client-kmp-shared-standard"
title: "APP KMP Shared 团队规范"
domain: "app-client"
sub_domain: "kmp-shared"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "kmp-shared"
  - "standard"
  - "ai-coding"
---

# APP KMP Shared 团队规范

本文件从 `kaz-mvp` 的 `trade-order` KMP batch 萃取，当前为单项目 evidence-backed `draft`。跨项目推广或升级为 `active` 前，需要 APP/KMP 负责人确认。

## 技术栈

- Kotlin Multiplatform 子项目，使用 `settings.gradle.kts` 显式拆分 `modules:core:*`、`modules:trade:*`、`modules:platform:*`、`apps:*`。
- Domain 层通过 UseCase 与 Repository 接口表达业务语义，网络结果统一使用 `Result<*, HsNetworkException>`。
- Presentation 层通过 Presenter、`StateFlow`、分页工具和 RequestGate 输出页面状态。

## 分层图

```text
apps:kaz-app / 原生宿主
  -> presentation Presenter / UiState / Mapper
  -> domain UseCase
  -> domain Repository interface
  -> data / network implementation
  -> modules:core:* shared types and utilities
```

## P1 KMP 业务能力必须保持 UseCase -> Repository 的依赖方向

```yaml
status: draft
level: P1
source_kind: extracted
evidence_tier: single-project
risk_tag: medium
owner: TBD
last_reviewed: "2026-05-22"
recommended_action: keep-draft
conflicts_with: []
superseded_by: null
```

### 适用范围

- KMP trade/order/account 等共享业务模块。

### 推荐做法

1. UseCase 表达单一业务动作，依赖 domain Repository 接口和必要上下文。
2. Repository 接口按业务语义声明数据访问能力，不把网络实现细节暴露给 Presentation。
3. UseCase 返回统一的结果类型，调用方通过成功 / 失败分支处理页面状态。
4. 不直接暴露给 iOS 的内部 UseCase 可使用 ObjC refinement 注解隐藏 ABI。

### AI 生成代码要求

1. AI 新增 KMP 业务能力时，必须先定义 domain 语义，再补 Repository 接口和实现。
2. AI 不得让 Presenter 直接依赖网络实现或 DTO 细节。
3. AI 修改 ObjC 暴露边界时必须显式说明是否影响 iOS ABI。

### Code Review 检查项

- [ ] UseCase 依赖 Repository 接口而非具体实现。
- [ ] Repository 方法名和参数按业务语义命名。
- [ ] iOS 暴露边界变更有明确说明。

### Evidence

- `evidence/code-facts.md「EV-APP-16」`
- `evidence/code-facts.md「EV-APP-17」`

## P1 KMP Presenter 应以状态流驱动页面而不是直接操作原生 UI

```yaml
status: draft
level: P1
source_kind: extracted
evidence_tier: single-project
risk_tag: medium
owner: TBD
last_reviewed: "2026-05-22"
recommended_action: keep-draft
conflicts_with: []
superseded_by: null
```

### 适用范围

- KMP Presentation、分页列表、筛选状态、请求去重。

### 推荐做法

1. Presenter 输出不可变 `StateFlow<UiState>`，内部通过 `MutableStateFlow` 更新状态。
2. 分页列表应显式维护首屏、刷新、加载更多、空态、失败和下一页游标。
3. 并发请求需要通过 RequestGate 或等价机制防重。
4. 成功结果应先映射为 UI model，再合并到 UiState。

### AI 生成代码要求

1. AI 新增 KMP Presenter 时，应输出状态流，不直接引用 Android View。
2. AI 新增分页能力时，必须处理首屏、刷新、加载更多和失败重置。
3. AI 不得把接口分页游标散落在 UI 层。

### Code Review 检查项

- [ ] Presenter 不直接操作 Android View 或 Fragment。
- [ ] 分页状态、筛选状态和请求防重逻辑集中在 Presenter。
- [ ] DTO 到 UI model 的转换在进入 UiState 前完成。

### Evidence

- `evidence/code-facts.md「EV-APP-18」`

## P2 KMP 模块矩阵应按 core / business / app 分层维护

```yaml
status: draft
level: P2
source_kind: extracted
evidence_tier: single-project
risk_tag: low
owner: TBD
last_reviewed: "2026-05-22"
recommended_action: keep-draft
conflicts_with: []
superseded_by: null
```

### 适用范围

- KMP settings、模块新增、跨域依赖调整。

### 推荐做法

1. 新增共享能力时应先判断归属 `modules:core`、具体业务域还是 `apps`。
2. 业务模块之间需要通过稳定类型和 contract 协作，避免让 app 层反向沉淀公共逻辑。
3. settings 变更应同步说明新增模块服务的业务域和依赖方向。

### AI 生成代码要求

1. AI 新增 KMP module include 时，必须说明模块归属层级。
2. AI 不得把跨业务共享能力直接放入 app 模块。

### Code Review 检查项

- [ ] 新增 KMP 模块归属层级清晰。
- [ ] settings 变更没有引入跨层反向依赖。

### Evidence

- `evidence/code-facts.md「EV-APP-19」`

## P2 KMP 桥接 object 统一封装 Service 访问，Android 侧不直接持有 Service 实例

```yaml
status: draft
level: P2
source_kind: extracted
evidence_tier: single-project
risk_tag: medium
owner: TBD
last_reviewed: "2026-05-22"
recommended_action: keep-draft
conflicts_with: []
superseded_by: null
```

### 适用范围

- Android 侧调用 KMP Service（如 WatchlistService、ApplicationLogic）的所有入口。

### 推荐做法

1. 用 Kotlin `object`（如 `WatchListKmp`）封装 KMP Service 的生命周期和访问入口，Android 侧只调用 object 方法。
2. object 内部持有 Service 实例，负责初始化（`doInitWithCombination()`）和状态管理。
3. 旧的直接调用 Service 方法的代码应注释保留（用 `//` 注释掉旧实现），新实现通过 object 桥接，便于回滚和对比。
4. 桥接 object 的方法签名应与 Android 侧调用习惯对齐，隐藏 KMP 内部参数细节。

### 正例

```kotlin
object WatchListKmp {
    private var watchlistService: WatchlistService = WatchlistService(globalScope)
    init { watchlistService.doInitWithCombination() }

    suspend fun groupAddStocks(groupId: String?, isSystem: Int?, stocks: List<SecurityItem>?, isManual: String?): HSResult<Boolean> {
        val groups = groupId?.let { listOf(it to isSystem?.toString()) }
        return watchlistService.groupAddStocks(groups, stocks, isManual)
    }
}
```

### AI 生成代码要求

1. AI 新增 KMP Service 调用时，必须通过桥接 object，不直接在 ViewModel 或 Manager 中持有 Service 实例。
2. AI 替换旧实现时，应注释保留旧代码，不直接删除。

### Code Review 检查项

- [ ] Android 侧没有直接持有 KMP Service 实例。
- [ ] 桥接 object 负责 Service 初始化和生命周期。

---

## P2 KMP Presenter 的 EffectFlow 用于一次性副作用，不用于持久状态

```yaml
status: draft
level: P2
source_kind: extracted
evidence_tier: single-project
risk_tag: low
owner: TBD
last_reviewed: "2026-05-22"
recommended_action: keep-draft
conflicts_with: []
superseded_by: null
```

### 适用范围

- 所有使用 KMP Presenter 的 ViewModel，特别是有弹窗、导航、Toast 等副作用的场景。

### 推荐做法

1. 一次性副作用（Toast、导航跳转、弹窗触发）通过 `effectFlow` 发送，不写入 `stateFlow`。
2. Android ViewModel 在 `init` 中用 `viewModelScope.launch` 收集 `effectFlow`，映射为 Android 侧 LiveData 事件。
3. `stateFlow` 只承载可重放的页面状态，`effectFlow` 只承载消费一次的事件。

### 正例

```kotlin
init {
    viewModelScope.launch {
        presenter.effectFlow.collect(::handlePresenterEffect)
    }
}

private fun handlePresenterEffect(effect: AccountCondOrderEffect) {
    when (effect) {
        is AccountCondOrderEffect.ShowToast -> showToast(effect.message)
        is AccountCondOrderEffect.OpenModify -> mutableUiEvent.postValue(AccountCondOrderUiEvent.ModifyOrder(effect.preparation))
        AccountCondOrderEffect.RefreshCurrentList -> onActionSuccessRefresh()
    }
}
```

### AI 生成代码要求

1. AI 新增 KMP Presenter 副作用时，必须通过 `effectFlow` 而非 `stateFlow`。
2. AI 在 ViewModel 中收集 `effectFlow` 时，必须在 `init` 中启动，不在 `onResume` 等生命周期方法中重复订阅。

### Code Review 检查项

- [ ] 一次性副作用通过 `effectFlow`，不写入 `stateFlow`。
- [ ] `effectFlow` 在 `init` 中订阅，不重复订阅。

---

## AI 规则

- KMP 业务逻辑先写 UseCase 与 Repository 接口，再连接实现。
- Presenter 只输出状态流，不直接操作 Android View。
- 新增 KMP 模块必须说明 core / business / app 归属。
- Android 侧通过桥接 object 访问 KMP Service，不直接持有 Service 实例。
- 一次性副作用通过 `effectFlow`，持久状态通过 `stateFlow`。

## Review 检查项

- [ ] UseCase、Repository、Presenter 依赖方向清晰。
- [ ] 分页 Presenter 处理请求防重、失败重置和游标更新。
- [ ] ObjC/iOS 暴露边界变更被显式说明。
- [ ] Android 侧没有直接持有 KMP Service 实例。
- [ ] 一次性副作用通过 `effectFlow`，不写入 `stateFlow`。
