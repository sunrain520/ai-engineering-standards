---
doc_id: "app-client-extracted-review-checklist"
title: "APP 萃取增量 Code Review Checklist"
domain: "app-client"
sub_domain: "common"
doc_type: "review-checklist"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "common"
  - "review-checklist"
---

# APP 萃取增量 Code Review Checklist

> 本文件由 `standard-{sub_domain}.md` 派生。`pending-confirmation` 项只作为提醒，不作为强制拦截。

## 1. 必检项

- [ ] `standard-build-governance.md「P1 依赖版本和强制依赖必须通过 hszq-version 集中治理」`：新增内部依赖来自 `Deps.Lib` 或 `Deps.Business`，临时替换集中在 `hszq-version`。
- [ ] `standard-build-governance.md「P1 本地模块激活必须只改 settings.gradle 的 include 边界」`：本地模块激活通过根 `settings.gradle` 管理，没有同名本地工程和 Maven 产物双来源。
- [ ] `standard-module-boundary.md「P1 交易共享能力必须先沉淀到 trade-core，再由交易子模块复用」`：交易共享能力位于 `trade2:trade-core` 或更底层公共模块，feature 之间没有为复用工具互相依赖。
- [ ] `standard-module-boundary.md「P1 跨模块页面创建必须通过 Provider 接口和强类型 Request」`：跨模块页面创建经 provider 接口完成，参数协议是强类型 request，不是 Bundle 透传。
- [ ] `standard-module-boundary.md「P1 账户子页面导航必须分阶段消费并记录 requestId」`：导航请求有唯一 `requestId`，二级 Tab 与叶子页消费阶段有明确标记。
- [ ] `standard-android.md「P1 新增类必须使用 Kotlin，存量 Java 只做兼容维护」`：新增 Android 类为 Kotlin，存量 Java 修改没有扩散新业务能力。
- [ ] `standard-android.md「P1 Fragment ViewBinding 必须使用 nullable backing field 并在 onDestroyView 清理」`：Fragment binding 在 `onDestroyView()` 中置空，异步回调没有越过 View 生命周期访问非空 binding。
- [ ] `standard-android.md「P1 Flow 订阅必须绑定 viewModelScope 或 viewLifecycleOwner 生命周期」`：ViewModel 订阅绑定 `viewModelScope`，Fragment UI 订阅绑定 View 生命周期。
- [ ] `standard-kmp-shared.md「P1 Android ViewModel 获取 KMP Presenter 必须注入生命周期 Scope」`：Presenter 获取路径经过 ViewModel 注入或工厂边界，使用的 Scope 与 ViewModel 生命周期对齐。
- [ ] `standard-kmp-shared.md「P1 KMP Flow 到 Android UI 的订阅必须由 Fragment 生命周期收口」`：KMP UI Flow 在 `repeatOnLifecycle` 或等价项目封装中收集，UI 更新没有越过 View 生命周期。

## 2. 推荐检查项

- [ ] `standard-build-governance.md「P2 应用级插件、渠道、签名和埋点只放在主应用模块」`：业务模块仍是 `com.android.library`，应用级插件和 release 语义没有被复制到 feature 模块。
- [ ] `standard-module-boundary.md「P2 core-ui-kit 只收纳跨业务 UI 基础能力」`：`core-ui-kit` 新增代码是 UI 基础能力，命名和包结构不夹带业务语义。
- [ ] `standard-android.md「P2 EventBus 注册注销必须成对，并声明 threadMode」`：EventBus 注册和注销成对，`@Subscribe` 声明了 `threadMode`。

## 3. 待确认检查项

- [ ] `standard-build-governance.md「P1 发布签名和生产配置只能通过变量注入，不能写入规范或源码正文」`：构建说明只出现变量名或脱敏事实，没有签名、证书、token 或生产配置原值。
- [ ] `standard-kmp-shared.md「P2 KMP Service 全局包装属于历史兼容，不作为新增模板」`：新增 KMP Service 调用没有复制 `globalScope` 模式，保留历史 bridge 时有负责人确认或迁移计划。
