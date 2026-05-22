---
doc_id: "app-client-extracted-review-checklist"
title: "APP 萃取增量 Code Review Checklist"
domain: "app-client"
sub_domain: "common"
doc_type: "review-checklist"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "common"
  - "review-checklist"
---

# APP 萃取增量 Code Review Checklist

> 本文件是 `standard-{sub_domain}.md`（各 sub_domain 规范文件）的汇总派生视图，由 generation 阶段自动生成，不接受手工修改。
> 如需修改规则，请更新对应 `standard-{sub_domain}.md` 后重新运行 generation 阶段。

## 1. 必检项

本 batch 未生成 P0 / FORBIDDEN 规则。

## 2. 推荐检查项

### module-boundary

- [ ] `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」`：跨业务域调用通过 `contract`、路由契约或稳定接口完成，没有直接依赖对方 feature 实现。
- [ ] `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」`：`contract` 模块的构建脚本没有新增 `feature` 实现模块依赖。
- [ ] `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」`：`contract` 中没有页面实现、复杂业务流程或内部状态管理代码。
- [ ] `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」`：新增契约只暴露调用方需要依赖的稳定协议，没有把实现细节扩散给外部模块。
- [ ] `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」`：`contract` 新增依赖有明确契约角色，不是页面实现、UI 组件或业务实现依赖。
- [ ] `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」`：`contract` 没有通过依赖传递向调用方暴露 feature 或 UI 能力。
- [ ] `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」`：保留历史 UI 相关依赖时，变更说明写明兼容原因和后续收敛条件。

## 3. 历史兼容说明

本 batch 未生成历史兼容条目。`pending-confirmation.md「PENDING-APP-1: contract 模块 UI 依赖是否应收敛」` 已由负责人确认并升级为 `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」`。

## 4. kaz-mvp 萃取检查项

> 以下检查项来自单项目 evidence-backed `draft` 规则；作为 Review 提醒使用，升级为强制拦截前需要负责人确认。

### android

- [ ] `standard-android.md「P1 App 壳初始化必须区分宿主进程与子进程」`：新增初始化逻辑有明确的进程边界。
- [ ] `standard-android.md「P1 页面基类选择必须匹配页面状态复杂度」`：Fragment 基类选择与页面状态复杂度一致。
- [ ] `standard-android.md「P2 交易共享能力应收敛到 trade-core 等 feature-core 模块」`：新增页面跳转没有复制 deprecated `TradeRouter` 模式。
- [ ] `standard-android.md「P2 账户容器页应只编排页面结构和导航消费」`：账户容器没有新增叶子业务计算。
- [ ] `standard-android.md「P1 KMP 桥接层必须通过 Presenter/UseCase 工厂方法获取」`：Presenter 通过工厂方法获取，`onCleared()` 中有 `close()`，KMP Flow 绑定正确 scope。
- [ ] `standard-android.md「P1 宿主 Fragment 只做结构编排，子页状态不上浮到宿主」`：子页传参通过 `arguments`，子页触发宿主行为通过接口。
- [ ] `standard-android.md「P2 StateMapper 负责 KMP UiState → Android Vo 的单向映射」`：KMP UiState → Vo 转换在 Mapper object，枚举映射穷举无 `else`。
- [ ] `standard-android.md「P2 ViewBinding 使用 nullable backing field 模式」`：ViewBinding 使用 `_binding` nullable backing field，`onDestroyView` 中置 null。
- [ ] `standard-android.md「P2 EventBus 注册/注销必须成对」`：EventBus 注册/注销在 `onAttach/onDetach` 成对，`@Subscribe` 有 `threadMode`。

### kmp-shared

- [ ] `standard-kmp-shared.md「P1 KMP 业务能力必须保持 UseCase -> Repository 的依赖方向」`：UseCase 依赖 Repository 接口而非具体实现。
- [ ] `standard-kmp-shared.md「P1 KMP Presenter 应以状态流驱动页面而不是直接操作原生 UI」`：Presenter 不直接操作 Android View 或 Fragment。
- [ ] `standard-kmp-shared.md「P2 KMP 模块矩阵应按 core / business / app 分层维护」`：新增 KMP 模块归属层级清晰。
- [ ] `standard-kmp-shared.md「P2 KMP 桥接 object 统一封装 Service 访问」`：Android 侧没有直接持有 KMP Service 实例。
- [ ] `standard-kmp-shared.md「P2 KMP Presenter 的 EffectFlow 用于一次性副作用」`：一次性副作用通过 `effectFlow`，不写入 `stateFlow`。

### build-governance

- [ ] `standard-build-governance.md「P1 本地工程替换必须集中在根 settings 治理」`：本地替换规则集中、可关闭，并带存在性判断。
- [ ] `standard-build-governance.md「P2 快速构建开关只能跳过校验任务，不能改变产物语义」`：快速构建开关默认关闭且不影响 release 产物语义。

### pending / legacy

- [ ] `pending-confirmation.md「PENDING-APP-2: core-ui-kit 是否应拆除对聚合 KMP 入口的直接依赖」`：新增 UI 基础层依赖是否避免直接依赖聚合 KMP App 入口。
- [ ] `pending-confirmation.md「PENDING-APP-3: 账户容器是否允许直接注入 KMP UseCase」`：新增账户容器逻辑是否避免直接注入 KMP UseCase。
