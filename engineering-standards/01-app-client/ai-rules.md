---
doc_id: "app-client-extracted-ai-rules"
title: "APP 萃取增量 AI Coding Rules"
domain: "app-client"
sub_domain: "common"
doc_type: "ai-rules"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "common"
  - "ai-rules"
  - "ai-coding"
---

# APP 萃取增量 AI Coding Rules

> 本文件由 `standard-{sub_domain}.md` 派生，AI 默认只执行 `auto-active` 或 `owner-confirmed-active` 规则。`pending-confirmation` 项只作为警告，不得默认执行。

## 1. 全局约束

1. 新增 Android 代码时，先判断涉及的子领域：构建、模块边界、Android 页面生命周期、KMP Android 消费侧。
2. 命中 `pending-confirmation`、`conflict`、`legacy-compatible`、`stale-auto-active` 或 `owner-rejected` 的内容时，不得直接生成强制代码，应输出待确认项。
3. 任何签名、token、证书、生产配置只允许记录变量名或脱敏存在事实，不读取或输出原值。

## 2. 可执行规则列表

### build-governance

- `standard-build-governance.md「P1 依赖版本和强制依赖必须通过 hszq-version 集中治理」`
  - AI 新增内部依赖时，必须先检查 `hszq-version` 是否已有 `Deps.*` 常量。
  - AI 不得在业务模块中直接发明内部 Maven 坐标版本。
  - AI 修改 `forceList` 时，必须说明冲突来源和退出条件。

- `standard-build-governance.md「P1 本地模块激活必须只改 settings.gradle 的 include 边界」`
  - AI 需要启用本地模块时，必须修改根 `settings.gradle` 的 include 边界。
  - AI 不得在 feature `build.gradle` 中临时硬改同名业务模块来源。

- `standard-build-governance.md「P2 应用级插件、渠道、签名和埋点只放在主应用模块」`
  - AI 新增渠道、签名、埋点、AOP 或 manifest 全局配置时，必须落在主应用模块或公共构建脚本。
  - AI 不得把 `com.android.application` 当作业务模块的默认插件。

### module-boundary

- `standard-module-boundary.md「P1 交易共享能力必须先沉淀到 trade-core，再由交易子模块复用」`
  - AI 新增交易共享能力时，必须先检查 `trade2:trade-core` 是否已有对应边界。
  - AI 不得让 `trade-core` 依赖账户、订单或条件单 feature 实现。

- `standard-module-boundary.md「P1 跨模块页面创建必须通过 Provider 接口和强类型 Request」`
  - AI 新增跨模块页面入口时，必须定义 provider 接口和 request 对象。
  - AI 不得把 Bundle 作为 provider 公开接口。
  - AI 不得让调用方直接 new 目标模块 Fragment。

- `standard-module-boundary.md「P1 账户子页面导航必须分阶段消费并记录 requestId」`
  - AI 新增账户子页导航时，必须使用共享导航 VM 或等价的 requestId + stage 机制。
  - AI 不得在容器层直接调用尚未 ready 的叶子 Fragment 方法。

- `standard-module-boundary.md「P2 core-ui-kit 只收纳跨业务 UI 基础能力」`
  - AI 往 `core-ui-kit` 新增代码前，必须说明它的 UI 职责和复用场景。
  - AI 不得把业务模型、业务文案或页面专属逻辑放进 `core-ui-kit`。

### android

- `standard-android.md「P1 新增类必须使用 Kotlin，存量 Java 只做兼容维护」`
  - AI 新增 Android 类时，必须生成 `.kt` 文件。
  - AI 修改 Java 存量代码时，应保持兼容边界，不扩散 Java 新能力。

- `standard-android.md「P1 Fragment ViewBinding 必须使用 nullable backing field 并在 onDestroyView 清理」`
  - AI 新增 Fragment 时，必须使用 nullable backing field 管理 ViewBinding。
  - AI 在协程、Flow 或回调中更新 UI 时，必须考虑 `bindingOrNull`。

- `standard-android.md「P1 Flow 订阅必须绑定 viewModelScope 或 viewLifecycleOwner 生命周期」`
  - AI 新增 Flow 订阅时，必须明确绑定 `viewModelScope` 或 `viewLifecycleOwner`。
  - AI 不得为页面 UI 状态生成 `GlobalScope`。

- `standard-android.md「P2 EventBus 注册注销必须成对，并声明 threadMode」`
  - AI 新增 EventBus 订阅时，必须同时生成注销逻辑。
  - AI 必须为 `@Subscribe` 指定 `threadMode`。

### kmp-shared

- `standard-kmp-shared.md「P1 Android ViewModel 获取 KMP Presenter 必须注入生命周期 Scope」`
  - AI 新增 Android ViewModel 消费 KMP Presenter 时，必须通过注入或工厂边界获取。
  - AI 必须把协程作用域显式传入 Presenter。

- `standard-kmp-shared.md「P1 KMP Flow 到 Android UI 的订阅必须由 Fragment 生命周期收口」`
  - AI 新增 KMP Flow UI 订阅时，必须绑定 `viewLifecycleOwner`。
  - AI 不得在 UI 层使用 `GlobalScope` 收集 KMP Flow。

## 3. 高风险和待确认警告

- `standard-build-governance.md「P1 发布签名和生产配置只能通过变量注入，不能写入规范或源码正文」`
  - 状态：`pending-confirmation`。
  - AI 只能记录脱敏变量事实，不得输出签名、证书、token 或生产配置原值。
  - 需要发布/CI owner 确认变量来源和注入方式。

- `standard-kmp-shared.md「P2 KMP Service 全局包装属于历史兼容，不作为新增模板」`
  - 状态：`pending-confirmation`。
  - AI 不得复制 `globalScope` KMP Service 模式。
  - 需要 KMP owner 确认历史 bridge 的生命周期和收敛路径。
