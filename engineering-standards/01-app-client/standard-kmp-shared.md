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

本文件从 `kaz-mvp` 的 `trade-order` KMP batch 萃取，当前为 `draft`，等待 KMP / APP 负责人审查。

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

## AI 规则

- KMP 业务逻辑先写 UseCase 与 Repository 接口，再连接实现。
- Presenter 只输出状态流，不直接操作 Android View。
- 新增 KMP 模块必须说明 core / business / app 归属。

## Review 检查项

- [ ] UseCase、Repository、Presenter 依赖方向清晰。
- [ ] 分页 Presenter 处理请求防重、失败重置和游标更新。
- [ ] ObjC/iOS 暴露边界变更被显式说明。
