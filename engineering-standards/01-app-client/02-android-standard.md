---
doc_id: "app-client-android-standard-archived"
title: "Android 客户端开发规范（已归档）"
domain: "app-client"
sub_domain: "android"
doc_type: "standard"
version: "v0.1.0"
status: "archived"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
superseded_by: "standard-android.md"
tags:
  - "app-client"
  - "android"
  - "archived"
---

> ⚠️ **本文件已归档**：内容由 `standard-android.md` 取代（采用 inline 元数据 + Developer Guide 风格，覆盖 9 条规则节）。本文件保留只为历史回溯，AI 不应将其作为现行规范引用。

# Android 客户端开发规范

## 1. 技术栈

Android 端新代码默认遵循以下技术栈和工程约束：

- Jetpack MVVM。
- HSLoadData。
- BaseVM。
- LiveData 或 Flow。
- KMP Shared Layer。
- HSDataCenterKit。
- Ktor。
- LruCache。
- SQLDelight。
- Napier。

## 2. 分层职责

```text
Activity / Fragment
    ↓
ViewModel / BaseVM
    ↓
UseCase / Repository from KMP
    ↓
HSDataCenterKit
    ↓
Network / Cache / Database
```

| 层级 | 职责 | 禁止事项 |
| --- | --- | --- |
| Activity / Fragment | UI 渲染、监听用户操作、订阅状态 | 不直接调用网络，不写业务规则 |
| ViewModel / BaseVM | 处理页面事件、组织 UI State、调用 UseCase | 不直接访问底层网络 |
| HSLoadData | 管理 loading、error、empty、success 状态 | 不承载复杂业务规则 |
| Repository / UseCase | 业务逻辑和数据访问 | 不依赖 Android UI |
| KMP Shared | 跨端逻辑复用 | 不使用 Android Context 承载业务 |

## 3. 页面开发目录模板

新增页面建议统一包含：

```text
feature/
└── xxx/
    ├── XxxActivity.kt / XxxFragment.kt
    ├── XxxViewModel.kt
    ├── XxxUiState.kt
    ├── XxxUiEvent.kt
    ├── XxxAdapter.kt
    └── components/
```

命名规则：

- 页面类使用业务名加 Activity 或 Fragment。
- ViewModel 使用业务名加 ViewModel。
- UI 状态使用业务名加 UiState。
- UI 事件使用业务名加 UiEvent。
- 列表适配器使用业务名加 Adapter。

## 4. UI State 规范

推荐方式：

```kotlin
data class OrderDetailUiState(
    val loading: Boolean = false,
    val orderDetail: OrderDetail? = null,
    val errorMessage: String? = null,
    val empty: Boolean = false
)
```

禁止方式：

```kotlin
val loading = MutableLiveData<Boolean>()
val error = MutableLiveData<String>()
val data = MutableLiveData<OrderDetail>()
val empty = MutableLiveData<Boolean>()
```

除非历史页面已有强约束，否则新页面应优先使用统一 UI State，而不是多个零散状态。

## 5. Activity / Fragment 规则

强制规则：

1. 只负责 UI 渲染、用户交互监听和状态订阅。
2. 不得直接发起网络请求。
3. 不得直接访问数据库、缓存或底层数据源。
4. 不得拼装复杂业务参数。
5. 不得处理交易、账户、订单、行情等核心业务规则。
6. 不得直接依赖后端 DTO。

推荐规则：

1. 页面跳转和结果回传应走现有路由体系。
2. UI 文案应走多语言资源。
3. 颜色、字号、间距应走现有主题和组件规范。
4. 事件埋点应放在统一入口或既有模式中。

## 6. ViewModel / BaseVM 规则

强制规则：

1. ViewModel 负责页面事件收敛、状态管理和调用 UseCase。
2. 新页面必须复用既有 BaseVM 体系。
3. Loading、Error、Empty、Success 状态必须完整处理。
4. 数据请求优先通过 KMP UseCase、Repository 或 HSDataCenterKit。
5. ViewModel 不得直接调用底层网络 SDK。
6. ViewModel 不得复制 KMP 已有业务规则。

推荐规则：

1. 复杂页面应定义 UiEvent，统一描述用户行为。
2. 高频刷新页面应明确刷新节流和取消策略。
3. 涉及账号态、交易态、权限态的页面应明确异常兜底。

## 7. HSLoadData 使用规则

强制规则：

1. 新增页面必须复用 HSLoadData 管理加载态。
2. 加载失败必须提供错误展示和重试入口。
3. 无数据场景必须有 empty 态。
4. 成功态必须明确数据刷新后的 UI 处理。

禁止事项：

- 自行发明一套 loading/error/empty 状态管理。
- 只处理 success，不处理 error 和 empty。
- 在 View 层手写复杂状态切换逻辑。

## 8. Android AI 生成规则

AI 生成 Android 代码时必须遵守：

1. 不允许在 Activity 或 Fragment 中直接发起网络请求。
2. 不允许在 Activity 或 Fragment 中拼装复杂业务参数。
3. 页面状态必须通过 ViewModel 收敛。
4. 复杂页面必须定义 UiState。
5. 数据请求必须优先通过 KMP UseCase、Repository 或 HSDataCenterKit。
6. Loading、Error、Empty、Success 状态必须完整处理。
7. 涉及交易、账户、订单的页面必须考虑刷新、重试、异常兜底。
8. 不允许复制已有 Repository 或 DataCenter 调用逻辑。
9. 新增页面必须复用既有 BaseVM 和 HSLoadData 体系。
10. 新增代码必须遵守现有资源命名、路由、埋点规范。

## 9. Review 检查项

- Activity / Fragment 是否只做 UI 渲染。
- ViewModel 是否统一管理状态。
- 是否完整处理 loading、error、empty、success。
- 是否复用 BaseVM 和 HSLoadData。
- 是否避免直接网络调用。
- UI 是否没有直接依赖 DTO。
- 是否复用 KMP 已有业务逻辑。
- 是否考虑高风险模块的刷新、重试、异常兜底。
