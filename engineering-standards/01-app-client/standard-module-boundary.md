---
doc_id: "app-client-module-boundary-standard"
title: "APP Module Boundary 团队规范"
domain: "app-client"
sub_domain: "module-boundary"
doc_type: "standard"
version: "v0.1.0"
status: "active"
owner: "APP 架构负责人"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "module-boundary"
  - "standard"
  - "ai-coding"
---

# APP Module Boundary 团队规范

本文件承载从 `kaz-mvp` 的 `app-client-module-boundary-contract-layer` batch 萃取出的模块边界规则。当前规则已由 APP 架构负责人确认，状态为 `active`。

## P1 跨域协作必须通过 contract 稳定边界

> level: P1 · status: active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: APP 架构负责人 · last_reviewed: 2026-06-02 · recommended_action: promote-to-active · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 说明

- 跨业务域如果直接依赖对方的 `feature` 实现模块，任意一方内部重构都会编译期击穿到调用方，模块边界形同虚设，最终退化为大泥球。通过 `contract` 暴露稳定协议，把「调用方需要什么」与「实现方怎么做」解耦，使实现可独立演进、依赖图保持单向。这条规则要防止的就是「跨域调用绕过契约直连实现」导致的隐式强耦合。

### 适用范围

- 研发域：`app-client`
- 子领域：`module-boundary`
- 业务模块：Android 原生多模块、跨业务域调用、契约模块治理
- 适用场景：新增跨业务域能力、拆分业务模块、调整模块依赖、为 feature 暴露稳定调用协议

### 推荐做法

1. 跨业务域协作应优先通过 `contract` 暴露稳定接口、轻量 DTO、必要常量和调用协议。
2. `contract` 模块应保持独立边界，不能依赖 `feature` 实现模块。
3. 业务实现应保留在 `feature` 或共享业务层，`contract` 只表达调用方需要依赖的稳定协议。
4. 新增或调整跨域调用时，应先确认是否已有对应 contract 能力，再决定是否扩展契约。

### 禁止做法

1. 禁止让 `contract` 反向依赖 `feature` 实现模块。
2. 禁止跨业务域调用绕过 `contract` 直接连接其他业务域实现。
3. 禁止把页面实现、复杂业务流程或内部状态管理沉淀到 `contract`。

### 正例

```kotlin
// 正例：order 域通过 quotes 域的 contract 暴露的稳定接口协作，不依赖其 feature 实现
// quotes-contract 模块（只含接口 + 轻量 DTO）
interface QuotesContract {
    fun getLatestPrice(symbol: String): PriceDto
}

// order-feature 模块 build.gradle.kts：只依赖 contract，不依赖 quotes-feature
dependencies {
    implementation(project(":quotes-contract"))
}

class OrderViewModel(private val quotes: QuotesContract) {
    fun refresh(symbol: String) {
        val price = quotes.getLatestPrice(symbol) // 经契约调用，跨域解耦
    }
}
```

### 反例

```kotlin
// 反例：order-feature 直接依赖 quotes-feature 实现 → 跨域强耦合，quotes 重构即击穿 order
dependencies {
    implementation(project(":quotes-feature")) // ⛔ 绕过 contract 直连实现模块
}

class OrderViewModel(private val quotesRepo: QuotesFeatureRepositoryImpl) { // ⛔ 依赖对方实现细节
    fun refresh(symbol: String) {
        val price = quotesRepo.fetchPriceFromDb(symbol) // 改法：改依赖 QuotesContract 接口
    }
}
```

### AI 生成代码要求

1. AI 新增跨业务域调用前，必须先检查目标业务域是否已有可复用的 `contract`。
2. AI 修改 `contract` 模块时，必须保持 `contract` 不依赖 `feature` 实现模块。
3. AI 不得在 `contract` 中生成页面实现、复杂业务流程或内部状态管理代码。
4. AI 发现需要跨域复用但当前没有契约时，应输出待确认项，而不是直接依赖对方 feature 实现。

### Code Review 检查项

- [ ] 跨业务域调用通过 `contract`、路由契约或稳定接口完成，没有直接依赖对方 feature 实现。
- [ ] `contract` 模块的构建脚本没有新增 `feature` 实现模块依赖。
- [ ] `contract` 中没有页面实现、复杂业务流程或内部状态管理代码。
- [ ] 新增契约只暴露调用方需要依赖的稳定协议，没有把实现细节扩散给外部模块。

### Evidence

- `evidence/code-facts.md「EV-APP-1」`
- `evidence/code-facts.md「EV-APP-2」`
- `evidence/code-facts.md「EV-APP-3」`
- `evidence/code-facts.md「EV-APP-4」`
- `evidence/positive-examples.md「POS-APP-1」`

## P2 contract 模块应保持依赖轻量

> level: P2 · status: active · source_kind: owner-confirmed · evidence_tier: single-project · risk_tag: low · owner: APP 架构负责人 · last_reviewed: 2026-06-02 · recommended_action: promote-to-active · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

### 说明

- `contract` 的价值在于「轻」——它只表达调用协议。一旦 `contract` 引入 UI 组件、页面框架或业务实现依赖，这些依赖会通过依赖传递泄漏给所有调用方，调用方为了用一个接口被迫拖入一整套 UI 栈，编译变慢、依赖图膨胀，契约层的解耦作用被反噬。这条规则防止 `contract` 因「顺手加依赖」逐渐变重而失去边界意义。

### 适用范围

- 研发域：`app-client`
- 子领域：`module-boundary`
- 业务模块：Android 原生 contract 模块
- 适用场景：新增或维护跨业务域 contract 模块的依赖配置

### 推荐做法

1. `contract` 模块应只保留表达稳定协议所需的最小依赖。
2. 新增 `contract` 依赖前，应确认该依赖是否属于接口、轻量 DTO、常量或调用协议所必需。
3. UI、页面实现、组件库和业务实现依赖应留在 `feature` 或 UI 层模块，不应默认进入 `contract`。
4. 现有历史依赖如需保留，应在变更说明中写明兼容原因和后续收敛条件。

### 禁止做法

1. 禁止在没有使用点和负责人确认的情况下，为 `contract` 默认新增 UI 组件、页面框架或业务实现依赖。
2. 禁止用 `contract` 依赖传递来让调用方间接获得 feature 或 UI 能力。

### 正例

```kotlin
// 正例：contract 模块只保留表达协议所需的最小依赖
// quotes-contract build.gradle.kts
dependencies {
    implementation(project(":core-model")) // 仅轻量 DTO/常量所需
    // 无 UI、无 compose、无 feature 实现依赖
}
```

### 反例

```kotlin
// 反例：contract 引入 UI 依赖 → 通过依赖传递泄漏给所有调用方
// quotes-contract build.gradle.kts
dependencies {
    implementation(project(":core-model"))
    implementation("androidx.compose.ui:ui") // ⛔ UI 栈进契约层
    implementation(project(":quotes-feature")) // ⛔ 业务实现进契约层
    // 改法：UI/实现依赖留在 feature 层，contract 只留接口与轻量 DTO
}
```

### AI 生成代码要求

1. AI 新增或修改 `contract` 模块依赖前，必须说明该依赖服务的契约角色。
2. AI 不得在 `contract` 中默认加入 UI 组件、页面框架或业务实现依赖。
3. AI 发现现有 `contract` 中存在 UI 相关依赖时，应保留兼容现状并提示负责人确认收敛，不得擅自删除。

### Code Review 检查项

- [ ] `contract` 新增依赖有明确契约角色，不是页面实现、UI 组件或业务实现依赖。
- [ ] `contract` 没有通过依赖传递向调用方暴露 feature 或 UI 能力。
- [ ] 保留历史 UI 相关依赖时，变更说明写明兼容原因和后续收敛条件。

### Evidence

- `evidence/code-facts.md「EV-APP-5」`
