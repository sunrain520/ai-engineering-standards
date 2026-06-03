---
doc_id: "app-client-android-standard"
title: "APP Android 团队规范"
domain: "app-client"
sub_domain: "android"
doc_type: "standard"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "android"
  - "standard"
  - "ai-coding"
---

# APP Android 团队规范

本文件从 `hszq-app` 的项目指令、Fragment / ViewModel 代码、EventBus 使用点和交易账户页面抽样萃取。规则覆盖 Android 新增代码语言、页面生命周期、ViewBinding、Flow 订阅与事件总线。

## P1 新增类必须使用 Kotlin，存量 Java 只做兼容维护

> level: P1 · status: auto-active · source_kind: owner-confirmed · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 3 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

项目根指令明确要求“新增类必须使用 Kotlin 语言编写”。目标仓库仍有大量 Java 存量代码，但近期交易账户、交易核心、搜索、行情等新代码大量使用 Kotlin 和协程/Flow。新增 Java 类会让新能力继续落在旧 MVP/Java 生态里，无法自然复用 Kotlin 扩展、协程、ViewModel scope 和空安全能力，也会增加后续迁移成本。

### 适用范围

- Android 新增 Activity、Fragment、ViewModel、Adapter、Provider、Helper、数据模型和测试类。

### 推荐做法

1. 新增类默认使用 Kotlin。
2. 修改存量 Java 类时，只在局部兼容范围内维护，不借机新增大块 Java 能力。
3. 与旧 Java API 交互时，用 Kotlin 封装边界承接空安全和生命周期约束。

### 禁止做法

1. 禁止为新页面、新 ViewModel 或新业务 helper 创建 Java 类。
2. 禁止因为调用方是 Java 就把新能力继续写成 Java。

### AI 生成代码要求

1. AI 新增 Android 类时，必须生成 `.kt` 文件。
2. AI 修改 Java 存量代码时，应优先保持兼容边界，不扩散 Java 新能力。

### Code Review 检查项

- [ ] 新增类为 Kotlin。
- [ ] 存量 Java 修改没有新增独立业务能力。

### Evidence

- `evidence/code-facts.md「EV-APP-18」`
- `evidence/code-facts.md「EV-APP-19」`

## P1 Fragment ViewBinding 必须使用 nullable backing field 并在 onDestroyView 清理

> level: P1 · status: auto-active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 6 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

交易账户页面、帖子评论页等 Kotlin Fragment 使用 `_binding: XxxBinding?`、`binding get() = _binding!!`、`bindingOrNull` 和 `onDestroyView { _binding = null }`。Fragment 的 View 生命周期短于 Fragment 实例生命周期，不清理 binding 会让 View、Context 和子 View 引用越过 `onDestroyView` 存活；异步回调如果直接访问已销毁 binding，也容易崩溃。nullable backing field 让销毁后的访问边界显式可见。

### 适用范围

- Android Fragment、ViewBinding、子 Fragment 容器、异步 UI 回调。

### 推荐做法

1. Fragment 中使用 `_binding: XxxBinding?` 保存 ViewBinding。
2. 对生命周期内必需访问使用 `binding`，对异步回调使用 `bindingOrNull` 或局部空检查。
3. `onDestroyView()` 中先释放外部 delegate / listener，再将 `_binding = null`。

### 禁止做法

1. 禁止把 Fragment binding 声明为生命周期外长期非空字段。
2. 禁止在 `onDestroyView()` 后继续直接访问 `binding`。

### 正例

```kotlin
private var _binding: TradeFragmentAccountOverviewBinding? = null
private val binding get() = _binding!!
private val bindingOrNull get() = _binding

override fun onDestroyView() {
    super.onDestroyView()
    _binding = null
}
```

### AI 生成代码要求

1. AI 新增 Fragment 时，必须使用 nullable backing field 管理 ViewBinding。
2. AI 在协程、Flow 或回调中更新 UI 时，必须考虑 `bindingOrNull`。

### Code Review 检查项

- [ ] Fragment binding 在 `onDestroyView()` 中置空。
- [ ] 异步回调没有越过 View 生命周期直接访问非空 binding。

### Evidence

- `evidence/code-facts.md「EV-APP-20」`
- `evidence/code-facts.md「EV-APP-21」`

## P1 Flow 订阅必须绑定 viewModelScope 或 viewLifecycleOwner 生命周期

> level: P1 · status: auto-active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 6 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

交易账户页面通过 `viewLifecycleOwner.lifecycleScope` + `repeatOnLifecycle(STARTED)` 收集 Presenter 的多个 Flow，ViewModel 通过 `viewModelScope` 注入 KMP Presenter 并监听请求状态。其他业务模块也大量使用 `viewModelScope.launch`。这些证据说明 Flow 订阅应跟随 View 或 ViewModel 生命周期，避免页面销毁后继续刷新 UI。历史 KMP service 的 `globalScope` 包装存在，但应作为兼容桥接边界，不作为新增页面订阅模板。

### 适用范围

- Kotlin Flow、StateFlow、SharedFlow、KMP Presenter、Android ViewModel、Fragment UI 订阅。

### 推荐做法

1. ViewModel 内部业务订阅使用 `viewModelScope`。
2. Fragment UI 订阅使用 `viewLifecycleOwner.lifecycleScope` 和 `repeatOnLifecycle` 或项目内等价 `collectWithLifecycle`。
3. 需要多路 Flow 时，在同一个 lifecycle block 中启动子 `launch`，统一生命周期边界。

### 禁止做法

1. 禁止在新增页面中使用 `GlobalScope` 收集 UI 状态。
2. 禁止在 Fragment 生命周期外长期持有 UI Flow 订阅。

### AI 生成代码要求

1. AI 新增 Flow 订阅时，必须明确绑定 `viewModelScope` 或 `viewLifecycleOwner`。
2. AI 不得为页面 UI 状态生成 `GlobalScope`。
3. AI 遇到历史 `globalScope` 桥接时，应保留兼容并提示负责人确认收敛。

### Code Review 检查项

- [ ] ViewModel 订阅绑定 `viewModelScope`。
- [ ] Fragment UI 订阅绑定 View 生命周期。
- [ ] 新增代码没有使用 `GlobalScope` 收集 UI 状态。

### Evidence

- `evidence/code-facts.md「EV-APP-22」`
- `evidence/code-facts.md「EV-APP-23」`
- `evidence/legacy-compatible.md「LEG-APP-1」`

## P2 EventBus 注册注销必须成对，并声明 threadMode

> level: P2 · status: auto-active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 8 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

项目中 EventBus 仍被广泛用于模块间通知。抽样显示多处在 attach/create 阶段注册，在 detach/destroy 阶段注销，并为订阅方法声明 `threadMode`。EventBus 属于全局事件通道，未注销会导致页面销毁后继续接收事件；未声明线程模式则会让 UI 更新线程边界不清晰。新增事件订阅必须把生命周期和线程语义写完整。

### 适用范围

- EventBus 订阅、全局通知、登录/行情/消息/关注状态等跨模块事件。

### 推荐做法

1. 在确定生命周期入口注册 EventBus，并在对称生命周期出口注销。
2. `@Subscribe` 必须显式声明 `threadMode`。
3. UI 更新类订阅默认使用主线程，耗时处理应放到异步线程或再分发到 ViewModel。

### 禁止做法

1. 禁止只注册不注销。
2. 禁止在订阅方法中省略线程模式。
3. 禁止把 EventBus 当作新增业务状态管理的默认方案。

### AI 生成代码要求

1. AI 新增 EventBus 订阅时，必须同时生成注销逻辑。
2. AI 必须为 `@Subscribe` 指定 `threadMode`。
3. AI 若能用 Flow/ViewModel/Provider 替代 EventBus，应优先使用生命周期可控方案。

### Code Review 检查项

- [ ] EventBus 注册和注销成对。
- [ ] `@Subscribe` 声明了 `threadMode`。
- [ ] 新增业务状态没有默认扩散为 EventBus 全局事件。

### Evidence

- `evidence/code-facts.md「EV-APP-24」`
- `evidence/code-facts.md「EV-APP-25」`
