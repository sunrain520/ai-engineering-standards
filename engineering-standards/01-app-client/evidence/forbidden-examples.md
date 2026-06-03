---
doc_id: "app-client-forbidden-examples"
title: "APP 客户端反向示例"
domain: "app-client"
sub_domain: "common"
doc_type: "evidence-forbidden"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "forbidden"
  - "evidence"
---

# APP 客户端反向示例

## NEG-APP-1 内部依赖坐标散落硬编码

- 对应规则：`standard-build-governance.md「P1 依赖版本和强制依赖必须通过 hszq-version 集中治理」`
- 反向模式：

```gradle
dependencies {
    implementation "com.hstong.temp:quotes-common:1.2.3-SNAPSHOT"
}
```

- 风险：同一内部依赖在多个模块出现不同版本，无法从 `hszq-version` 统一治理。

## NEG-APP-2 跨模块 Provider 公开 Bundle

- 对应规则：`standard-module-boundary.md「P1 跨模块页面创建必须通过 Provider 接口和强类型 Request」`
- 反向模式：

```kotlin
interface IOrderPageProvider : IProvider {
    fun getSecurityOrderFragment(args: Bundle): Fragment
}
```

- 风险：Bundle key 名变更时调用方编译不感知，跨模块协议变成弱约定。

## NEG-APP-3 Fragment 长期持有非空 binding

- 对应规则：`standard-android.md「P1 Fragment ViewBinding 必须使用 nullable backing field 并在 onDestroyView 清理」`
- 反向模式：

```kotlin
private lateinit var binding: FragmentPageBinding
```

- 风险：View 销毁后 Fragment 实例仍持有 View 树，导致泄漏或异步回调崩溃。

## NEG-APP-4 UI Flow 使用 GlobalScope 收集

- 对应规则：`standard-android.md「P1 Flow 订阅必须绑定 viewModelScope 或 viewLifecycleOwner 生命周期」`
- 反向模式：

```kotlin
GlobalScope.launch {
    presenter.stateFlow.collect { render(it) }
}
```

- 风险：订阅生命周期与页面脱钩，页面销毁后仍可能更新 UI。

## NEG-APP-5 EventBus 只注册不注销

- 对应规则：`standard-android.md「P2 EventBus 注册注销必须成对，并声明 threadMode」`
- 反向模式：

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    EventBus.getDefault().register(this)
}
```

- 风险：页面销毁后仍接收事件，产生重复响应或泄漏。
