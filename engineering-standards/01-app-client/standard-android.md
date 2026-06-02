---
doc_id: "app-client-android-standard"
title: "APP Android 团队规范"
domain: "app-client"
sub_domain: "android"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "android"
  - "standard"
  - "ai-coding"
---

# APP Android 团队规范

本文件从 `kaz-mvp` 的 Android app shell、core UI、trade route、account page composition batch 萃取，当前为单项目 evidence-backed `draft`。跨项目推广或升级为 `active` 前，需要 APP 负责人确认。

## 技术栈

- Gradle 多模块 Android App，App 壳使用 `com.android.application`、Kotlin、KAPT、KSP、AGConnect、Sensors、Android AOP 等插件。
- Android UI 基础层使用 Fragment / ViewModel / LiveData / ViewBinding，并通过 `core-ui-kit` 提供 BaseFragment、BaseLoadDataFragment 和 BaseViewModel。
- 交易原生 feature 通过 `trade-core` 复用核心 UI、utils 和资源库；账户页以容器 Fragment 编排二级 Tab、ViewPager 和 KMP 能力。
- 构建脚本中存在 debug-like 构建跳过高成本校验的本地提速策略。

## 分层图

```text
app-kaz
  -> app-core / core capability
  -> feature:trade:* / feature:kaz-quotes:* / feature:user_operations:*
  -> core:core-ui-kit / core:core-utils / resources:library
  -> contract:* / KMP biz-common
```

## P1 App 壳初始化必须区分宿主进程与子进程

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: high · owner: TBD · last_reviewed: 2026-05-22 · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 说明

- Android 中 Push、RN runtime 等组件会在独立的子进程拉起 `Application.onCreate`，若不区分进程，子进程会重复执行宿主的全套业务初始化，导致启动变慢、内存翻倍，甚至因子进程缺少宿主上下文而崩溃。把业务容器、全局事件注册无差别复制到子进程，还会造成事件被多进程重复消费、状态错乱等难以排查的问题，因此必须以进程判断收口完整初始化。

### 适用范围

- `Application`、启动初始化、Push、RN runtime、全局生命周期、业务容器初始化。

### 推荐做法

1. `Application.onCreate` 中应先判断当前进程，只在宿主进程执行完整业务初始化。
2. 子进程只保留必要基础配置，避免注册全局事件、启动 RN runtime、Push、业务容器或生命周期服务。
3. 新增全局初始化能力时，应说明它是否必须在子进程运行。

### AI 生成代码要求

1. AI 在 `Application` 中新增初始化逻辑前，必须先判断该逻辑是否属于宿主进程专属能力。
2. AI 不得把宿主进程的业务初始化默认复制到子进程分支。

### Code Review 检查项

- [ ] 新增初始化逻辑有明确的进程边界。
- [ ] 子进程分支没有启动全局业务容器、Push、RN runtime 或事件注册。

### Evidence

- `evidence/code-facts.md「EV-APP-8」`

## P1 页面基类选择必须匹配页面状态复杂度

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-22 · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 说明

- 基类承载了 loading/error/empty 状态机和订阅清理能力，给简单静态页强行套用加载态基类会引入用不到的状态分支和生命周期回调，徒增理解和维护成本；反过来给异步页用过轻的基类，则会逼开发者在 Fragment 里手写散落的 `isLoading`、`hasError` 等标志位，状态切换容易遗漏、互相覆盖，并且 Rx 订阅无法随 ViewModel 统一释放而泄漏。按状态复杂度选最低足够基类，才能让状态表达和资源回收都收口在统一路径上。

### 适用范围

- Android Fragment 页面、MVVM 页面、需要 loading/error/empty/content 的页面。

### 推荐做法

1. 静态页面使用 `BaseFragment`，只接入布局、初始化和可见性回调。
2. 有 ViewModel 但不需要统一加载态的页面使用 MVVM 基类。
3. 需要首次加载、刷新、加载更多、错误重试或空态的页面使用 `BaseLoadDataFragment`。
4. ViewModel 应通过统一的加载状态、错误、Toast 与订阅清理能力表达页面状态。

### AI 生成代码要求

1. AI 新增 Fragment 时，必须根据页面状态复杂度选择最低足够的基类。
2. AI 不得为简单静态页面默认套用加载态基类。
3. AI 新增异步加载页面时，应接入统一 loading/error/empty 状态，而不是自行散落多个状态变量。

### Code Review 检查项

- [ ] Fragment 基类选择与页面状态复杂度一致。
- [ ] 加载态、错误、空态和刷新行为通过基类或 ViewModel 统一表达。
- [ ] Rx 订阅或 keyed disposable 能在 ViewModel 清理阶段释放。

### Evidence

- `evidence/code-facts.md「EV-APP-9」`
- `evidence/code-facts.md「EV-APP-10」`

## P2 交易共享能力应收敛到 trade-core 等 feature-core 模块

> level: P2 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-22 · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 说明

- 交易由多个子模块组成，共享的 UI、utils 和数据模型如果各自复制一份，会随时间漂移成多个不一致的版本，修一个 bug 要改多处且容易漏改。把这些能力收敛到 `trade-core` 这类 feature-core 模块，可以让子模块共享同一份实现、保持单一来源；但 feature-core 一旦塞进具体业务页面流程，又会反过来变成谁都依赖的"大泥球"。同理，deprecated 的 `TradeRouter` 入口只是为存量保留的兼容壳，若被当作新页面跳转模板复制，会让已计划下线的代码继续扩散、迁移成本越滚越大。

### 适用范围

- 交易模块共享 UI 组件、工具类、数据模型、路由兼容入口。

### 推荐做法

1. 交易子模块共享的原生能力应先沉淀到 `trade-core` 一类 feature-core 模块。
2. feature-core 可以暴露基础 UI、utils 和资源能力，但不应承载具体业务页面流程。
3. 已标记 deprecated 的旧路由入口只能作为兼容路径维护，不应作为新增页面跳转的默认模板。

### AI 生成代码要求

1. AI 新增交易共享能力时，应优先检查 `trade-core` 是否已有合适位置。
2. AI 不得基于 deprecated 路由单例复制新增跳转模式。

### Code Review 检查项

- [ ] 共享能力位于 feature-core 或更底层公共模块，而不是散落在具体业务页面。
- [ ] 新增页面跳转没有复制 deprecated `TradeRouter` 模式。

### Evidence

- `evidence/code-facts.md「EV-APP-12」`
- `evidence/code-facts.md「EV-APP-13」`

## P2 账户容器页应只编排页面结构和导航消费

> level: P2 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-22 · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 说明

- 账户容器页天然处在导航中枢位置，如果让它直接承载资产、订单、盈亏等叶子业务计算，容器就会越长越臃肿、与各叶子页紧耦合，叶子页拆分或复用时被容器逻辑拖住。把容器职责限定在结构编排和导航消费、让深链按"容器定位 Tab → 叶子继续下钻"分阶段处理，可以保持各层职责清晰、叶子页可独立演进。直接在容器层注入 KMP UseCase 属于绕过分层的历史写法，扩散后会让跨层依赖蔓延，因此只保留兼容并标记待确认，不作为新增模式。

### 适用范围

- 账户容器页、二级 Tab、ViewPager、账户子页导航、可见性刷新。

### 推荐做法

1. 容器 Fragment 负责绑定 layout、初始化二级 Tab、ViewPager、通知条和跨页导航消费。
2. 账户子页深链应先在容器层定位二级 Tab，再由叶子页继续消费需要下钻的请求。
3. 容器层不应直接承载账户资产、订单、盈亏等叶子业务计算。
4. 直接调用 KMP UseCase 的历史写法应保留兼容并进入待确认，不应扩散为新增模式。

### AI 生成代码要求

1. AI 修改账户容器时，应保持容器职责为结构编排与导航消费。
2. AI 不得把叶子页业务计算新增到容器 Fragment。
3. AI 发现需要直接注入 UseCase 到容器时，应输出待确认项。

### Code Review 检查项

- [ ] 容器 Fragment 没有新增叶子业务计算。
- [ ] 深链导航请求按容器层与叶子层分阶段消费。
- [ ] 新增 UseCase 注入到容器层时有负责人确认或迁移计划。

### Evidence

- `evidence/code-facts.md「EV-APP-14」`
- `evidence/code-facts.md「EV-APP-15」`

## P1 KMP 桥接层必须通过 Presenter/UseCase 工厂方法获取，不直接构造 Service

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: high · owner: TBD · last_reviewed: 2026-05-22 · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 说明

- KMP Presenter/Service 的构造往往要求注入特定的 CoroutineScope、依赖装配和生命周期约定，直接 `new XxxPresenter()` 或 `new WatchlistService(GlobalScope)` 会绕过工厂封装，拿到一个生命周期与 Android 侧脱钩的实例，难以统一替换实现或做测试桩。用 `GlobalScope` 收集 `StateFlow` 会让协程随进程而非随页面存活，页面销毁后仍在更新 UI，造成内存泄漏甚至空指针；而漏掉 `onCleared()` 里的 `presenter.close()` 则会让 KMP 侧的订阅和资源一直挂着。通过工厂方法获取、绑定 `viewModelScope`/`repeatOnLifecycle` 并在销毁时 close，才能让桥接对象的生命周期与 Android 组件对齐。

### 适用范围

- 所有 Android 侧调用 KMP 业务层的 ViewModel、Manager、桥接对象。

### 推荐做法

1. 通过 `XxxPresenterFactory.createXxxPresenter()` 或 `XxxModule.createXxxPresenter()` 获取 Presenter 实例，不直接 `new XxxPresenter()`。
2. ViewModel 持有 Presenter 生命周期，在 `onCleared()` 中调用 `presenter.close()`。
3. KMP `StateFlow` 在 `viewModelScope` 或 `lifecycleScope` 内用 `repeatOnLifecycle(STARTED)` 收集，不在 `GlobalScope` 直接 collect UI 状态。
4. Android 侧不直接持有 KMP `Service` 单例（如 `WatchlistService`），通过 `WatchListKmp` 等 object 桥接层统一访问。

### 正例

```kotlin
// ViewModel 通过工厂方法获取 Presenter
class MarketViewModel(application: Application) : BaseKmpPageViewModel<MarketUiState>(application) {
    override val presenter: MarketPresenter = MarketPresenter()
    init { startObservingPresenter() }
}

// 复杂模块通过 Module 工厂
val presenter: AccountCondOrderPresenter = TradeCondModule.createAccountCondOrderPresenter()
```

### 反例

```kotlin
// 直接构造 KMP Service，绕过桥接层
private val watchlistService = WatchlistService(GlobalScope) // 禁止
```

### AI 生成代码要求

1. AI 新增 ViewModel 时，必须通过工厂方法获取 Presenter，不直接构造 KMP Service。
2. AI 在 ViewModel 中收集 KMP Flow 时，必须绑定 `viewModelScope`，不使用 `GlobalScope`。
3. AI 必须在 `onCleared()` 中调用 `presenter.close()`。

### Code Review 检查项

- [ ] Presenter 通过工厂方法获取，没有直接 `new` KMP Service。
- [ ] KMP Flow 收集绑定了正确的 CoroutineScope。
- [ ] `onCleared()` 中有 `presenter.close()`。

---

## P1 宿主 Fragment 只做结构编排，子页状态不上浮到宿主

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-22 · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 说明

- ViewPager 下的宿主与子页生命周期并不同步，子页可能尚未创建或已被回收。如果把子页业务状态上浮到宿主 ViewModel，宿主就要替所有子页持有和切换状态，宿主膨胀的同时还会因为读到尚未就绪的子页状态而出错。通过宿主 ViewModel 的 LiveData 直接给子页喂数据，会让子页隐式依赖宿主、无法独立复用和测试；而子页反向直接访问宿主 ViewModel 则会形成双向耦合。用 `arguments` 单向传参、用 `internal fun`/接口回调收口子页触发的宿主行为，能保持宿主只管结构编排、子页自管业务状态的清晰边界。

### 适用范围

- 含 ViewPager + Tab 的宿主 Fragment（如 WatchListFragment、账户容器页）。

### 推荐做法

1. 宿主 Fragment 负责：Tab/ViewPager 初始化、Banner/Notification 挂载、分组切换、指数条显隐等宿主级渲染控制。
2. 子页（分组页、账户子页）的业务状态不上浮到宿主 ViewModel；宿主只通过接口（如 `OnGroupInfoChangedListener`）向子页派发事件。
3. 宿主向子页传递数据通过 `Fragment.arguments` 注入，不通过宿主 ViewModel 的 LiveData 直接暴露给子页。
4. 子页需要触发宿主行为时，通过 `internal fun` 或接口回调，不直接访问宿主 ViewModel。

### 正例

```kotlin
// 宿主通过 internal fun 收口子页触发的宿主行为
internal fun cycleDynamicBlockModeFromPage() {
    mainViewModel.cycleDynamicBlockMode()
}

// 子页通过 arguments 接收分组 id，不依赖宿主 ViewModel
return WatchListPageFragment().apply {
    arguments = Bundle().apply {
        putString(Config.STOCK_GROUP_ID, groupId)
    }
}
```

### AI 生成代码要求

1. AI 新增宿主 Fragment 时，子页状态不得直接写入宿主 ViewModel。
2. AI 向子页传参必须通过 `arguments`，不通过宿主 ViewModel 的 LiveData。

### Code Review 检查项

- [ ] 子页业务状态没有上浮到宿主 ViewModel。
- [ ] 宿主向子页传参通过 `arguments`，不通过共享 ViewModel 直接暴露。
- [ ] 子页触发宿主行为通过 `internal fun` 或接口，不直接访问宿主 ViewModel。

---

## P2 StateMapper 负责 KMP UiState → Android Vo 的单向映射

> level: P2 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: low · owner: TBD · last_reviewed: 2026-05-22 · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 说明

- KMP UiState 和 Android Vo 是两套数据模型，转换逻辑如果散落在 ViewModel 里，会和页面逻辑、订阅逻辑搅在一起，难以复用和测试，且同一份映射在多个 ViewModel 里各写一遍容易不一致。抽成无状态、不碰 Android API 的 `XxxStateMapper` object，能让转换成为可独立测试的纯函数。枚举映射用 `when` 穷举而非 `else` 兜底，是为了在 KMP 侧新增枚举值时让编译器直接报"缺分支"，把遗漏挡在编译期而不是等到运行时落进兜底分支造成静默错误；用 sealed 类型表达列表项多态，则能在 `when` 消费时同样获得穷尽性检查，避免 `Any` 带来的类型不安全和强转。

### 适用范围

- 所有需要把 KMP Presenter UiState 转换为 Android 侧 ViewObject 的模块（trade-order、watchlist 等）。

### 推荐做法

1. 用独立的 `XxxStateMapper` object 承载 KMP UiState → Android Vo 的转换，不在 ViewModel 内散落转换逻辑。
2. Mapper 只做数据结构转换，不持有任何状态，不调用 Android API。
3. KMP 枚举到 Android Vo 枚举的映射用 `when` 穷举，不用 `else` 兜底（保证编译期覆盖检查）。
4. Vo 类型用 sealed interface/class 表达列表项多态，不用 Any 或 Object。

### 正例

```kotlin
object CondOrderStateMapper {
    fun toAccountPageState(state: AccountCondOrderUiState, ...): AccountCondPageState { ... }

    private fun CondStatusFilter.toVo(): CondStatusFilterVo = when (this) {
        CondStatusFilter.ALL -> CondStatusFilterVo.ALL
        CondStatusFilter.PENDING -> CondStatusFilterVo.PENDING
        // 穷举，无 else
    }
}
```

### 反例

```kotlin
// 在 ViewModel 内散落转换逻辑
fun onResult(state: AccountCondOrderUiState) {
    val items = state.orders.map { CondOrderCardVo(it.id, ...) } // 禁止直接在 VM 内转换
}
```

### AI 生成代码要求

1. AI 新增 KMP 状态消费时，必须通过独立 Mapper object 转换，不在 ViewModel 内散落。
2. AI 写枚举映射时必须穷举 `when` 分支，不用 `else`。

### Code Review 检查项

- [ ] KMP UiState → Vo 转换集中在 Mapper object，不散落在 ViewModel。
- [ ] 枚举映射 `when` 穷举，无 `else` 兜底。
- [ ] Vo 列表项多态用 sealed interface/class 表达。

---

## P2 ViewBinding 使用 nullable backing field 模式，onDestroyView 中置 null

> level: P2 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-22 · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 说明

- Fragment 的视图生命周期比 Fragment 本身短：`onDestroyView` 之后视图已销毁但 Fragment 实例可能仍存活（如被加入回退栈）。如果用非空 `val binding` 长期持有 ViewBinding，被销毁的 View 树就会被 Fragment 一直引用而无法回收，造成内存泄漏；销毁后若再访问该 binding，操作的还是过期视图。用 nullable backing field 加 `onDestroyView` 置 null，既能在视图销毁时切断引用让 View 被回收，又能让销毁后误访问以明确的空指针快速暴露，而不是悄悄操作失效视图。

### 适用范围

- 所有使用 ViewBinding 的 Fragment。

### 推荐做法

1. 声明 `private var _binding: XxxBinding? = null`，通过 `private val binding get() = _binding!!` 访问。
2. 在 `onDestroyView()` 中将 `_binding = null`，防止 Fragment 视图销毁后持有 View 引用导致内存泄漏。
3. 不在 `onDestroyView()` 之后访问 `binding`。

### 正例

```kotlin
private var _binding: FragmentMeBinding? = null
private val binding get() = _binding!!

override fun initView() {
    _binding = FragmentMeBinding.bind(requireView())
}

override fun onDestroyView() {
    super.onDestroyView()
    _binding = null
}
```

### AI 生成代码要求

1. AI 新增 Fragment 时，ViewBinding 必须使用 nullable backing field 模式。
2. AI 必须在 `onDestroyView()` 中置 `_binding = null`。

### Code Review 检查项

- [ ] ViewBinding 使用 `_binding` nullable backing field。
- [ ] `onDestroyView()` 中有 `_binding = null`。

---

## P2 EventBus 注册/注销必须成对，在 onAttach/onDetach 或 onCreate/onDestroy 中完成

> level: P2 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-22 · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 说明

- EventBus 注册后会持有订阅者引用，注册不注销会让已销毁的 Fragment 被 EventBus 一直引用而泄漏，并在事件到来时回调到失效页面引发崩溃。把注册/注销放到 `onResume/onPause` 看似对称，但 ViewPager 切页会频繁触发这两个回调，导致订阅被反复注销、相邻页收不到事件；放在 `onAttach/onDetach`（Application 用 `onCreate/onTerminate`）才与"订阅者是否存活"对齐。`@Subscribe` 不指定 `threadMode` 时回调线程由发布线程决定，UI 操作可能落到非主线程而抛异常，因此 UI 处理必须显式声明 `ThreadMode.MAIN`。

### 适用范围

- 所有使用 EventBus（GreenRobot）的 Fragment 和 Application。

### 推荐做法

1. Fragment 在 `onAttach` 注册、`onDetach` 注销；Application 在 `onCreate` 注册、`onTerminate` 注销。
2. 不在 `onResume/onPause` 注册/注销（会导致 ViewPager 切换时频繁注销）。
3. `@Subscribe` 方法必须指定 `threadMode`，UI 操作使用 `ThreadMode.MAIN`。

### 正例

```kotlin
override fun onAttach(context: Context) {
    super.onAttach(context)
    EventBus.getDefault().register(this)
}
override fun onDetach() {
    super.onDetach()
    EventBus.getDefault().unregister(this)
}

@Subscribe(threadMode = ThreadMode.MAIN)
fun onBusGroupCheckChanged(event: BusGroupCheckChanged) { ... }
```

### AI 生成代码要求

1. AI 新增 EventBus 订阅时，必须在对应生命周期方法中成对注册/注销。
2. AI 必须为 `@Subscribe` 指定 `threadMode`。

### Code Review 检查项

- [ ] EventBus 注册/注销成对，生命周期对称。
- [ ] `@Subscribe` 有明确 `threadMode`。

---

## AI 规则

- 新增 Application 初始化时先判断宿主进程边界。
- 新增 Fragment 时按静态 / MVVM / 加载态复杂度选择最低足够基类。
- 新增交易共享能力优先收敛到 feature-core，避免复制 deprecated 路由单例。
- 修改账户容器时只做结构编排与导航消费，不写叶子业务计算。
- 新增 ViewModel 时通过工厂方法获取 KMP Presenter，在 `onCleared()` 中 `close()`。
- KMP UiState → Vo 转换集中在独立 Mapper object，枚举映射 `when` 穷举无 `else`。
- Fragment ViewBinding 使用 nullable backing field，`onDestroyView` 中置 null。
- EventBus 注册/注销在 `onAttach/onDetach` 成对，`@Subscribe` 必须指定 `threadMode`。
- 宿主 Fragment 子页传参通过 `arguments`，子页触发宿主行为通过 `internal fun` 或接口。

## Review 检查项

- [ ] App 启动逻辑未把宿主进程初始化扩散到子进程。
- [ ] Fragment 基类选择与页面状态复杂度一致。
- [ ] 交易共享能力没有散落到具体业务页。
- [ ] 账户容器没有新增叶子业务计算或未经确认的跨层 UseCase 调用。
- [ ] KMP Presenter 通过工厂方法获取，`onCleared()` 中有 `close()`。
- [ ] KMP UiState → Vo 转换在 Mapper object，枚举映射穷举无 `else`。
- [ ] ViewBinding 使用 nullable backing field，`onDestroyView` 中置 null。
- [ ] EventBus 注册/注销成对，`@Subscribe` 有 `threadMode`。
- [ ] 宿主 Fragment 子页传参通过 `arguments`，子页触发宿主行为通过接口。
