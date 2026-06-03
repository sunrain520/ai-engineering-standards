---
doc_id: "app-client-module-boundary-standard"
title: "APP Module Boundary 团队规范"
domain: "app-client"
sub_domain: "module-boundary"
doc_type: "standard"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "module-boundary"
  - "standard"
  - "ai-coding"
---

# APP Module Boundary 团队规范

本文件从 `hszq-app` 的 `app-core`、`core-ui-kit`、`trade2:*` 模块、ARouter provider 和业务模块依赖图萃取。规则用于保护 Android 多模块边界、共享能力沉淀和跨模块页面创建协议。

## 分层图

```text
huasheng-stock
  -> app-core / published business modules / trade2 local modules

app-core
  -> main integration boundary
  -> aggregates business capabilities

core:core-ui-kit
  -> cross-business UI foundation only

trade2:trade-core
  -> trade shared UI / tools / models / navigation contracts

trade2:trade-account / trade-order / trade-condition
  -> feature implementation modules
  -> depend on trade2:trade-core
```

## P1 交易共享能力必须先沉淀到 trade-core，再由交易子模块复用

> level: P1 · status: auto-active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 5 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

`trade2:trade-core` 的 README 明确它存放交易模块共享 UI 组件、工具类和数据模型，`trade-account`、`trade-order`、`trade-condition` 和旧 `trade` 模块都依赖它。共享能力如果直接落在某个交易 feature 中，其他交易子模块只能反向依赖该 feature 或复制实现；反过来，如果 `trade-core` 引入具体页面流程，它又会变成新的聚合泥球。当前证据支持把 `trade-core` 作为交易共享能力的稳定下沉点，同时保持它不承载具体业务页面。

### 适用范围

- 交易账户、订单、条件单、交易分析等交易子模块。
- 跨交易子模块复用的 UI、工具、模型、导航协议。

### 推荐做法

1. 交易域共享 UI、工具、数据模型或导航协议应优先放入 `trade2:trade-core`。
2. 交易 feature 依赖 `trade-core` 使用共享能力，不反向让 `trade-core` 依赖 feature。
3. 具体账户、订单、条件单页面实现应留在各自 feature 模块。

### 禁止做法

1. 禁止把跨交易子模块复用能力散落在某个 feature 页面里。
2. 禁止在 `trade-core` 中沉淀具体业务页面流程或强依赖 feature 实现。

### 正例

```gradle
dependencies {
    implementation(project(":trade2:trade-core"))
}
```

### 反例

```gradle
dependencies {
    implementation(project(":trade2:trade-account")) // 禁止为了复用工具而依赖页面 feature
}
```

### AI 生成代码要求

1. AI 新增交易共享能力时，必须先检查 `trade2:trade-core` 是否已有对应边界。
2. AI 不得让 `trade-core` 依赖账户、订单或条件单 feature 实现。
3. AI 无法判断能力是否跨模块复用时，应输出待确认项。

### Code Review 检查项

- [ ] 交易共享能力位于 `trade2:trade-core` 或更底层公共模块。
- [ ] `trade-core` 没有新增具体 feature 页面依赖。
- [ ] feature 之间没有为了复用工具而互相依赖。

### Evidence

- `evidence/code-facts.md「EV-APP-10」`
- `evidence/code-facts.md「EV-APP-11」`
- `evidence/code-facts.md「EV-APP-12」`

## P1 跨模块页面创建必须通过 Provider 接口和强类型 Request

> level: P1 · status: auto-active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 3 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

`IOrderPageProvider` 把订单相关页面的跨模块创建入口统一为 provider 接口，并要求调用方传入 `OrderPageRequest` 或 `CondOrderPageRequest`。文件注释明确禁止模块 A 直接依赖模块 B 的 Fragment 类、直接拼 ARouter path 和 Bundle key、或把 Bundle 作为公开接口透出。这个模式用编译期可见的 request 对象替代弱协议 Bundle，能防止 key 名变更后跨模块调用静默失效。

### 适用范围

- ARouter Provider、跨模块 Fragment 创建、订单页/条件单页跳转、跨模块参数协议。

### 推荐做法

1. 跨模块创建页面时，应通过 provider 接口暴露能力。
2. 页面参数应收敛为强类型 request 对象，由被调用模块负责转换成 Fragment arguments。
3. 新增入参时扩展 request，不在 provider 方法签名上不断追加零散参数。

### 禁止做法

1. 禁止调用方直接依赖目标模块 Fragment 实现类。
2. 禁止公开透传 Bundle 作为跨模块协议。
3. 禁止在调用方散落 ARouter path 和 Bundle key 拼装逻辑。

### 正例

```kotlin
interface IOrderPageProvider : IProvider {
    fun getSecurityOrderFragment(request: OrderPageRequest): Fragment
}
```

### 反例

```kotlin
// 禁止调用方直接依赖目标 Fragment 或拼 Bundle key
val fragment = SecurityOrderFragment().apply { arguments = bundle }
```

### AI 生成代码要求

1. AI 新增跨模块页面入口时，必须定义 provider 接口和 request 对象。
2. AI 不得把 Bundle 作为 provider 公开接口。
3. AI 不得让调用方直接 new 目标模块 Fragment。

### Code Review 检查项

- [ ] 跨模块页面创建经 provider 接口完成。
- [ ] 参数协议是强类型 request，而不是 Bundle 透传。
- [ ] 调用方没有直接依赖目标 feature Fragment 类。

### Evidence

- `evidence/code-facts.md「EV-APP-13」`
- `evidence/code-facts.md「EV-APP-14」`

## P1 账户子页面导航必须分阶段消费并记录 requestId

> level: P1 · status: auto-active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 4 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

账户容器和子页生命周期不同步，目标子页可能尚未创建或已被回收。`AccountSubPageNavigationVM` 用 `MutableStateFlow` 保存最后一次导航请求，通过单调递增 `requestId` 区分相同目标的连续请求，并用 `handledStages` 标记二级 Tab 和叶子页的分阶段消费状态。这个设计避免容器同步递归调用子 Fragment，也避免 lifecycle 重放时重复切回上层 Tab。

### 适用范围

- 账户容器、二级 Tab、资产/订单/盈亏等子页导航、跨层页面跳转。

### 推荐做法

1. 容器只发布目标账户和子页面请求，不直接递归调用尚未 ready 的子 Fragment。
2. 导航请求必须带单调递增 `requestId`，同一目标的重复点击也视为新请求。
3. 各层消费后应标记处理阶段，最终叶子页处理完成后清空请求。

### 禁止做法

1. 禁止容器直接持有并操作叶子页业务状态。
2. 禁止用普通 nullable 字段保存跨生命周期导航副作用。
3. 禁止忽略已处理阶段导致 lifecycle 重放重复执行副作用。

### AI 生成代码要求

1. AI 新增账户子页导航时，必须使用共享导航 VM 或等价的 requestId + stage 机制。
2. AI 不得在容器层直接调用尚未 ready 的叶子 Fragment 方法。
3. AI 增加新 `pageKey` 时，应同步说明由哪一层消费。

### Code Review 检查项

- [ ] 导航请求有唯一 `requestId`。
- [ ] 二级 Tab 与叶子页消费阶段有明确标记。
- [ ] 容器层没有新增叶子业务计算或直接操作叶子 Fragment。

### Evidence

- `evidence/code-facts.md「EV-APP-15」`
- `evidence/code-facts.md「EV-APP-16」`

## P2 core-ui-kit 只收纳跨业务 UI 基础能力

> level: P2 · status: auto-active · source_kind: extracted · evidence_tier: single-project · risk_tag: low · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 3 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

`core-ui-kit` README 明确它不是业务聚合或杂项工具箱，只收纳跨业务复用的 UI 组件、UI 控制器、渲染能力、UI 数据模型和基础资源。它同时禁止业务逻辑、业务数据模型、页面专属实现、非 UI 工具类和“先放着”的临时代码。该模块当前源码内容很少，更需要用准入规则防止它在扩张时变成新的公共垃圾桶。

### 适用范围

- `core:core-ui-kit`、跨业务 UI 组件、UI 控制器、UI 资源和模型。

### 推荐做法

1. 只有 UI 层能力且具备跨业务复用价值的代码才进入 `core-ui-kit`。
2. 命名去掉业务词后仍然成立，包结构按 UI 能力分层。
3. 新增能力前应能说明至少两个复用方向，或说明为什么放在业务模块会阻碍复用。

### 禁止做法

1. 禁止放入证券、基金、债券、订单、行情、账户等业务逻辑和业务模型。
2. 禁止放入页面临时 helper 或非 UI 工具类。
3. 禁止依赖具体业务模块、业务资源、业务路由或业务埋点。

### AI 生成代码要求

1. AI 往 `core-ui-kit` 新增代码前，必须说明它的 UI 职责和复用场景。
2. AI 不得把业务模型、业务文案或页面专属逻辑放进 `core-ui-kit`。

### Code Review 检查项

- [ ] 新增代码是 UI 基础能力而非业务代码。
- [ ] 命名和包结构不夹带业务语义。
- [ ] 没有新增业务模块依赖。

### Evidence

- `evidence/code-facts.md「EV-APP-17」`
