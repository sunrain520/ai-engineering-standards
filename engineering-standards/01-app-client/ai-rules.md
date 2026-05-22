---
doc_id: "app-client-extracted-ai-rules"
title: "APP 萃取增量 AI Coding Rules"
domain: "app-client"
sub_domain: "common"
doc_type: "ai-rules"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "common"
  - "ai-rules"
  - "ai-coding"
---

# APP 萃取增量 AI Coding Rules

> 本文件是 `standard-{sub_domain}.md`（各 sub_domain 规范文件）的汇总派生视图，由 generation 阶段自动生成，不接受手工修改。
> 如需修改规则，请更新对应 `standard-{sub_domain}.md` 后重新运行 generation 阶段。

## 1. 全局约束

AI 默认必须执行 `status: active` 的 P0 / P1 / P2 / FORBIDDEN 规则。对 `pending-confirmation`、`conflict`、`legacy-compatible`、`rejected` 或 `evidence_tier: none` 的规则不得直接执行。

本文件中的 module-boundary 规则已由 APP 架构负责人确认；Android、KMP Shared、Build Governance 规则来自 `kaz-mvp` 单项目 evidence，当前只能作为 `draft` 规则使用，跨项目推广或升级为 `active` 前需要负责人确认。

## 2. 可执行规则列表

### module-boundary

- `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」`
  - AI 新增跨业务域调用前，必须先检查目标业务域是否已有可复用的 `contract`。
  - AI 修改 `contract` 模块时，必须保持 `contract` 不依赖 `feature` 实现模块。
  - AI 不得在 `contract` 中生成页面实现、复杂业务流程或内部状态管理代码。
  - AI 发现需要跨域复用但当前没有契约时，应输出待确认项，而不是直接依赖对方 feature 实现。

- `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」`
  - AI 新增或修改 `contract` 模块依赖前，必须说明该依赖服务的契约角色。
  - AI 不得在 `contract` 中默认加入 UI 组件、页面框架或业务实现依赖。
  - AI 发现现有 `contract` 中存在 UI 相关依赖时，应保留兼容现状并提示负责人确认收敛，不得擅自删除。

## 3. 高风险警告

- `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」` 和 `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」` 已确认 active，但 evidence 仍来自单项目 batch。跨项目推广前建议补充第二项目 evidence。

## 4. kaz-mvp draft 萃取规则

> 以下规则来自单项目 evidence。AI 命中时必须提示 `draft` 状态和 evidence 来源，不得把它们当作已负责人确认的强制规则。

### android

- `standard-android.md「P1 App 壳初始化必须区分宿主进程与子进程」`
  - AI 在 `Application` 中新增初始化逻辑前，必须先判断宿主进程边界。
  - AI 不得把宿主进程的业务初始化默认复制到子进程分支。

- `standard-android.md「P1 页面基类选择必须匹配页面状态复杂度」`
  - AI 新增 Fragment 时，必须根据页面状态复杂度选择最低足够的基类。
  - AI 新增异步加载页面时，应接入统一 loading/error/empty 状态。

- `standard-android.md「P2 交易共享能力应收敛到 trade-core 等 feature-core 模块」`
  - AI 新增交易共享能力时，应优先检查 `trade-core` 是否已有合适位置。
  - AI 不得基于 deprecated 路由单例复制新增跳转模式。

- `standard-android.md「P2 账户容器页应只编排页面结构和导航消费」`
  - AI 修改账户容器时，应保持容器职责为结构编排与导航消费。
  - AI 不得把叶子页业务计算新增到容器 Fragment。

- `standard-android.md「P1 KMP 桥接层必须通过 Presenter/UseCase 工厂方法获取」`
  - AI 新增 ViewModel 时，必须通过工厂方法获取 KMP Presenter，不直接构造 KMP Service。
  - AI 必须在 `onCleared()` 中调用 `presenter.close()`。
  - AI 在 ViewModel 中收集 KMP Flow 时，必须绑定 `viewModelScope`，不使用 `GlobalScope`。

- `standard-android.md「P1 宿主 Fragment 只做结构编排，子页状态不上浮到宿主」`
  - AI 新增宿主 Fragment 时，子页传参通过 `arguments`，不通过宿主 ViewModel 的 LiveData。
  - AI 子页触发宿主行为通过 `internal fun` 或接口，不直接访问宿主 ViewModel。

- `standard-android.md「P2 StateMapper 负责 KMP UiState → Android Vo 的单向映射」`
  - AI 新增 KMP 状态消费时，必须通过独立 Mapper object 转换，不在 ViewModel 内散落。
  - AI 写枚举映射时必须穷举 `when` 分支，不用 `else`。

- `standard-android.md「P2 ViewBinding 使用 nullable backing field 模式」`
  - AI 新增 Fragment 时，ViewBinding 必须使用 `_binding` nullable backing field。
  - AI 必须在 `onDestroyView()` 中置 `_binding = null`。

- `standard-android.md「P2 EventBus 注册/注销必须成对」`
  - AI 新增 EventBus 订阅时，必须在 `onAttach/onDetach` 成对注册/注销。
  - AI 必须为 `@Subscribe` 指定 `threadMode`。

### kmp-shared

- `standard-kmp-shared.md「P1 KMP 业务能力必须保持 UseCase -> Repository 的依赖方向」`
  - AI 新增 KMP 业务能力时，必须先定义 domain 语义，再补 Repository 接口和实现。
  - AI 不得让 Presenter 直接依赖网络实现或 DTO 细节。

- `standard-kmp-shared.md「P1 KMP Presenter 应以状态流驱动页面而不是直接操作原生 UI」`
  - AI 新增 KMP Presenter 时，应输出状态流，不直接引用 Android View。
  - AI 新增分页能力时，必须处理首屏、刷新、加载更多和失败重置。

- `standard-kmp-shared.md「P2 KMP 模块矩阵应按 core / business / app 分层维护」`
  - AI 新增 KMP module include 时，必须说明模块归属层级。
  - AI 不得把跨业务共享能力直接放入 app 模块。

- `standard-kmp-shared.md「P2 KMP 桥接 object 统一封装 Service 访问」`
  - AI 新增 KMP Service 调用时，必须通过桥接 object，不直接在 ViewModel 或 Manager 中持有 Service 实例。
  - AI 替换旧实现时，应注释保留旧代码，不直接删除。

- `standard-kmp-shared.md「P2 KMP Presenter 的 EffectFlow 用于一次性副作用」`
  - AI 新增 KMP Presenter 副作用时，必须通过 `effectFlow` 而非 `stateFlow`。
  - AI 在 ViewModel 中收集 `effectFlow` 时，必须在 `init` 中启动，不重复订阅。

### build-governance

- `standard-build-governance.md「P1 本地工程替换必须集中在根 settings 治理」`
  - AI 新增本地替换规则时，必须放在根 settings 的统一治理区域。
  - AI 不得在业务模块 build.gradle 中临时硬编码 Maven 坐标替换。

- `standard-build-governance.md「P2 快速构建开关只能跳过校验任务，不能改变产物语义」`
  - AI 新增构建提速能力时，必须说明影响的任务类型。
  - AI 不得把快速构建开关用于跳过打包必需任务或改变 release 行为。

> 以上规则是 `draft` 增量规则；负责人确认前不得升级为默认强制规则。
