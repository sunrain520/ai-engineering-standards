---
doc_id: "app-client-numbered-overview-archived"
title: "APP 客户端统一开发规范 V1（编号入口，已归档）"
domain: "app-client"
sub_domain: "common"
doc_type: "overview"
version: "v0.1.0"
status: "archived"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
superseded_by: "overview.md"
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "overview"
  - "archived"
---

> 本编号入口已归档。现行 evidence-backed 总览使用 `overview.md`；AI 默认执行规则只来自 `ai-rules.md` 中的 auto-active 条目。

# APP 客户端统一开发规范 V1

## 1. 适用范围

本规范适用于华盛通 APP、KAZ APP 以及后续多展业地 APP 的客户端需求开发、缺陷修复、功能扩展、架构复用和 AI 辅助编码。

覆盖范围包括：

- KMP 共享业务层。
- Android 客户端。
- iOS 客户端。
- 数据中台 HSDataCenterKit。
- 网络、缓存、数据库、日志、配置、多语言、主题等基础组件。
- 多展业地配置化适配。
- 交易、行情、用户、账户、搜索、推送、配置更新等核心业务模块。

## 2. 架构目标

APP 客户端架构遵循以下目标：

1. UI 薄，逻辑厚。
2. 业务逻辑优先下沉 KMP 共享层。
3. Android 和 iOS 只保留平台差异、页面状态组织和 UI 渲染逻辑。
4. 数据访问统一走 Repository 和 HSDataCenterKit。
5. 网络、缓存、数据库、日志等基础能力统一封装。
6. 多展业地能力通过配置、依赖注入、策略和模块化组合实现。
7. AI 生成代码不得破坏既有分层、复用边界和数据访问链路。

核心原则：

> 共享逻辑放 KMP，平台逻辑放 ViewModel 或 Reactor，页面只负责渲染，数据访问统一走数据中台。

## 3. 总体架构分层

```text
App Shell / 主应用
    ↓
启动核心容器 / App Bootstrap Container
    ↓
业务模块层 / Feature Modules
    ↓
平台 ViewModel / Reactor 层
    ↓
KMP Shared Domain Layer
    ↓
Repository / HSDataCenterKit
    ↓
Network / Cache / Database / Config / Log
```

## 4. 分层职责

| 层级 | 职责 | 禁止事项 |
| --- | --- | --- |
| App Shell | 应用启动、路由、模块装配、展业地配置注入 | 不写具体业务逻辑 |
| 启动核心容器 | 初始化配置、依赖注入、基础 SDK、账号态、环境切换 | 不承载页面逻辑 |
| Feature Module | 承载交易、行情、用户、账户、搜索、推送等业务模块 | 不直接访问底层网络 |
| Android ViewModel | 平台状态管理、UI State 转换、事件分发 | 不写可跨端复用的核心业务规则 |
| iOS Reactor | Action、Mutation、State 状态流转 | 不写可跨端复用的核心业务规则 |
| KMP Shared | 跨端业务逻辑、领域模型、Repository、UseCase | 不依赖 Android 或 iOS UI API |
| HSDataCenterKit | 统一数据访问、缓存策略、数据调度 | 不处理 UI 逻辑 |
| Infrastructure | 网络、缓存、数据库、日志、配置、多语言 | 不直接暴露给 UI 层随意调用 |

## 5. APP 端规范文件索引

| 文件 | 说明 |
| --- | --- |
| `00-app-client-overview.md` | APP 客户端统一架构、适用范围和第一版强制规则 |
| `01-kmp-shared-layer-standard.md` | KMP 共享层职责、目录、命名、AI 生成规则 |
| `02-android-standard.md` | Android Jetpack MVVM、BaseVM、HSLoadData 规范 |
| `03-ios-standard.md` | iOS ReactorKit 单向数据流规范 |
| `04-data-center-standard.md` | HSDataCenterKit 数据访问、缓存、模型转换规范 |
| `05-module-standard.md` | APP 模块化、模块模板和模块边界规范 |
| `06-multi-market-standard.md` | 多展业地配置化、策略化、DI 适配规范 |
| `07-ui-component-standard.md` | UI 组件、状态展示、多语言、主题和复用规范 |
| `08-testing-standard.md` | KMP、Android、iOS、数据中台和多展业地测试规范 |
| `09-performance-standard.md` | 启动、页面、网络、缓存、行情和稳定性性能规范 |
| `10-app-ai-rules.md` | APP 端 AI Coding Rules |
| `11-code-review-checklist.md` | APP 端 Code Review Checklist |
| `12-state-error-standard.md` | 页面状态、错误处理、重试和降级规范 |
| `13-navigation-routing-standard.md` | 路由、DeepLink、页面协作和跨模块调用规范 |
| `14-build-dependency-standard.md` | 构建、依赖、版本和 contract 轻量化治理规范 |
| `15-security-compliance-standard.md` | 账号、权限、隐私、交易和合规安全规范 |
| `16-observability-standard.md` | 日志、埋点、Crash、性能指标和诊断上下文规范 |
| `17-app-standard-extraction-process.md` | APP 代码开发规范萃取流程和维度矩阵 |

## 6. 第一版强制规则

### 架构规则

1. 可跨端复用逻辑优先进入 KMP。
2. UI 层不得直接访问网络。
3. UI 层不得直接使用后端 DTO。
4. View 层只负责渲染和交互。
5. 数据访问统一走 Repository 和 HSDataCenterKit。
6. Android 和 iOS 不得重复实现核心业务规则。
7. 平台差异通过 adapter、expect/actual 或 DI 解决。
8. 新增模块必须说明 KMP 共享边界。

### Android 规则

9. 新页面必须使用 ViewModel 或 BaseVM。
10. 页面状态必须通过 UiState 收敛。
11. 必须处理 loading、error、empty、success。
12. 不允许 Activity 或 Fragment 拼装复杂业务参数。
13. 不允许绕过 HSLoadData。

### iOS 规则

14. 新页面必须遵守 ReactorKit。
15. 用户行为必须进入 Action。
16. 状态变化必须通过 Mutation。
17. ViewController 不写复杂业务逻辑。
18. Closure 注意 weak self，避免循环引用。

### KMP 规则

19. Repository 接口放 domain。
20. Repository 实现放 data。
21. DTO 必须 mapper 到 Domain Model。
22. commonMain 不依赖平台 UI。
23. 核心逻辑必须可单测。

### 多展业地规则

24. 域名、语言、主题、功能开关必须配置化。
25. 不允许在页面层硬编码 KAZ 等展业地逻辑。
26. 接口差异通过 DTO Mapper 隔离。
27. 业务差异通过策略或 DI 隔离。
28. UI 风格差异通过主题和组件契约隔离。

### 质量规则

29. 涉及交易、账户、订单的逻辑必须有异常兜底和日志。
30. AI 生成代码必须输出自检清单。

## 7. 规则等级定义

- 强制规则：新代码必须遵守，Code Review 必须拦截违反项。
- 推荐规则：新代码应优先遵守，历史代码迁移时可分阶段落地。
- 历史兼容规则：允许历史页面暂时保留，但新增逻辑不得继续扩大技术债。

## 8. 落地要求

每个 APP 端需求进入开发前，应先完成以下判断：

1. 需求属于哪个业务模块。
2. 是否已有相同或类似能力。
3. 哪些逻辑可以下沉 KMP。
4. 哪些逻辑必须留在 Android 或 iOS 平台层。
5. 是否需要新增 DTO Mapper。
6. 是否影响多展业地配置。
7. 是否涉及交易、账户、订单、行情等高风险模块。
8. 是否需要新增错误处理、日志、埋点、单测。

一句话总结：

> APP 端第一版规范的核心，不是统一 Android 和 iOS 的写法，而是统一业务逻辑下沉 KMP、平台层只做状态与 UI、数据访问走中台、多展业地差异配置化的架构契约。
