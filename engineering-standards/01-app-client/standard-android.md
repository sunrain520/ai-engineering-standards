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

本文件从 `kaz-mvp` 的 Android app shell、core UI、trade route、account page composition batch 萃取，当前为 `draft`，等待 APP 负责人审查。

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

```yaml
status: draft
level: P1
source_kind: extracted
evidence_tier: single-project
risk_tag: high
owner: TBD
last_reviewed: "2026-05-22"
recommended_action: keep-draft
conflicts_with: []
superseded_by: null
```

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

## AI 规则

- 新增 Application 初始化时先判断宿主进程边界。
- 新增 Fragment 时按静态 / MVVM / 加载态复杂度选择最低足够基类。
- 新增交易共享能力优先收敛到 feature-core，避免复制 deprecated 路由单例。
- 修改账户容器时只做结构编排与导航消费，不写叶子业务计算。

## Review 检查项

- [ ] App 启动逻辑未把宿主进程初始化扩散到子进程。
- [ ] Fragment 基类选择与页面状态复杂度一致。
- [ ] 交易共享能力没有散落到具体业务页。
- [ ] 账户容器没有新增叶子业务计算或未经确认的跨层 UseCase 调用。
