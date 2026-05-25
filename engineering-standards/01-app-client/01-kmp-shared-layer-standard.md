---
doc_id: "app-client-kmp-shared-layer-standard-archived"
title: "KMP 共享层开发规范（已归档）"
domain: "app-client"
sub_domain: "kmp-shared"
doc_type: "standard"
version: "v0.1.0"
status: "archived"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
superseded_by: "standard-kmp-shared.md"
tags:
  - "app-client"
  - "kmp-shared"
  - "archived"
---

> ⚠️ **本文件已归档**：内容由 `standard-kmp-shared.md` 取代（采用 inline 元数据 + Developer Guide 风格）。本文件保留只为历史回溯，AI 不应将其作为现行规范引用。

---
doc_id: "app-client-kmp-shared-layer-standard-archived"
title: "KMP 共享层开发规范（已归档）"
domain: "app-client"
sub_domain: "kmp-shared"
doc_type: "standard"
version: "v0.1.0"
status: "archived"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
superseded_by: "standard-kmp-shared.md"
tags:
  - "app-client"
  - "kmp-shared"
  - "archived"
---

> ⚠️ **本文件已归档**：内容由 `standard-kmp-shared.md` 取代（采用 inline 元数据 + Developer Guide 风格）。本文件保留只为历史回溯，AI 不应将其作为现行规范引用。

# KMP 共享层开发规范

## 1. 规范定位

KMP 是 APP 客户端架构的共享业务底座。凡是 Android 和 iOS 都需要遵守的业务规则、领域模型、Repository 抽象、UseCase、错误模型、缓存策略和数据编排，应优先沉淀到 KMP commonMain。

## 2. KMP 共享层职责

KMP 共享层应承载：

- 交易、行情、用户、账户等核心业务逻辑。
- 跨端一致的数据模型。
- Repository 抽象。
- UseCase 或 Interactor。
- DTO 到 Domain Model 的转换。
- 缓存策略封装。
- 网络请求编排。
- 业务规则校验。
- 错误模型统一。
- 可单测的核心逻辑。

KMP 共享层不应承载：

- Android Activity 或 Fragment 逻辑。
- iOS ViewController 或 UIView 逻辑。
- 平台 UI 组件。
- 平台权限弹窗。
- 平台路由跳转。
- 强依赖 Android Context 的业务逻辑。
- 强依赖 iOS UIKit 的业务逻辑。

## 3. 推荐目录结构

```text
shared/
├── commonMain/
│   ├── domain/
│   │   ├── model/
│   │   ├── usecase/
│   │   ├── repository/
│   │   └── error/
│   ├── data/
│   │   ├── dto/
│   │   ├── mapper/
│   │   ├── repository/
│   │   ├── datasource/
│   │   └── cache/
│   ├── infra/
│   │   ├── network/
│   │   ├── database/
│   │   ├── config/
│   │   └── log/
│   └── module/
│       ├── trade/
│       ├── quote/
│       ├── account/
│       ├── user/
│       └── search/
├── androidMain/
│   └── platform/
├── iosMain/
│   └── platform/
└── commonTest/
```

## 4. 分层规则

| 层级 | 职责 | 规则等级 |
| --- | --- | --- |
| domain/model | 领域模型，表达稳定业务语义 | 强制 |
| domain/usecase | 业务用例，编排 Repository 和业务规则 | 强制 |
| domain/repository | Repository 接口定义 | 强制 |
| domain/error | 统一业务错误模型 | 强制 |
| data/dto | 后端接口数据结构 | 强制 |
| data/mapper | DTO 到 Domain Model 转换 | 强制 |
| data/repository | Repository 实现 | 强制 |
| data/datasource | 远程、本地、数据中台数据源适配 | 推荐 |
| data/cache | 缓存策略封装 | 推荐 |
| infra | 网络、数据库、配置、日志等基础适配 | 推荐 |

## 5. 命名规范

| 类型 | 命名建议 |
| --- | --- |
| UseCase | `GetOrderDetailUseCase` |
| Repository 接口 | `OrderRepository` |
| Repository 实现 | `OrderRepositoryImpl` |
| DTO | `OrderDetailDTO` |
| Domain Model | `OrderDetail` |
| Mapper | `OrderDetailMapper` |
| Error | `OrderError` 或 `TradeError` |
| DataSource | `OrderRemoteDataSource` 或 `OrderLocalDataSource` |

## 6. Repository 规则

强制规则：

1. Repository 接口必须定义在 domain 层。
2. Repository 实现必须定义在 data 层。
3. Repository 不得向 UI 层暴露 DTO。
4. Repository 应返回 Domain Model 或统一 Result 类型。
5. Repository 应通过 HSDataCenterKit 或受控 datasource 获取数据。

推荐规则：

1. 网络优先、缓存优先、降级读取等策略应封装在 data 层。
2. 涉及多展业地差异的数据结构，应通过 mapper 或 strategy 隔离。
3. 多接口聚合逻辑应优先放在 UseCase，而不是平台 ViewModel 或 Reactor。

## 7. DTO 与 Domain Model 转换

推荐链路：

```text
Backend DTO
    ↓
DTO Mapper
    ↓
Domain Model
    ↓
UI State / State
    ↓
View Render
```

禁止链路：

```text
Backend DTO
    ↓
View 直接使用
```

强制规则：

1. DTO 不得直接传递到 Android 或 iOS UI 层。
2. 接口字段兼容逻辑必须在 mapper 中消化。
3. Domain Model 应保持业务语义稳定，不随接口字段频繁变化。
4. UI State 只表达页面展示所需字段。

## 8. 平台差异处理

平台差异优先级：

1. commonMain 纯业务实现。
2. expect/actual 隔离平台能力。
3. platform adapter 注入平台实现。
4. DI 替换实现。

禁止事项：

- 在 commonMain 中引用 Android UI API。
- 在 commonMain 中引用 UIKit。
- 在 commonMain 中直接依赖平台页面生命周期。
- 为单端需求复制一套 KMP 已有业务规则。

## 9. 错误模型规范

KMP 应定义统一错误模型，至少覆盖：

- 网络错误。
- 业务错误。
- 鉴权错误。
- 风控错误。
- 数据解析错误。
- 缓存读取错误。
- 多展业地配置错误。
- 未知错误。

错误模型应满足：

1. 平台层可展示用户友好的错误文案。
2. 日志和埋点可获取稳定错误码。
3. 交易、账户、订单等高风险模块可做兜底和重试。

## 10. 单元测试规范

强制规则：

1. 核心业务规则必须有 commonTest。
2. DTO Mapper 必须覆盖字段缺失、类型异常、兼容值、空值场景。
3. 涉及交易、账户、订单、行情的 UseCase 必须覆盖成功、失败、重试和异常路径。

推荐规则：

1. Repository 测试使用 fake datasource。
2. 多展业地策略测试至少覆盖默认展业地和一个差异展业地。
3. 错误模型测试覆盖后端错误码转换。

## 11. AI 生成规则

AI 生成 KMP 代码时必须遵守：

1. 跨端可复用的业务逻辑必须优先放入 commonMain。
2. 不允许在 commonMain 中引用 Android 或 iOS 平台 UI API。
3. DTO 不得直接传递到 UI 层，必须转换为 Domain Model 或 UI State。
4. Repository 接口应定义在 domain 层，具体实现放在 data 层。
5. 网络、缓存、数据库访问不得散落在 UseCase 中。
6. 所有接口变动必须优先通过 mapper 隔离，避免污染业务逻辑。
7. 核心业务逻辑必须补充 commonTest 单元测试。
8. 平台差异必须通过 expect/actual、adapter 或 DI 解决。

## 12. Review 检查项

- commonMain 是否没有平台 UI 依赖。
- Repository 接口和实现是否分层清晰。
- DTO 是否完成 mapper 转换。
- Domain Model 是否稳定。
- 核心逻辑是否有 commonTest。
- 是否存在 Android 和 iOS 重复实现同一业务规则。
- 是否绕过 HSDataCenterKit 或既有 datasource。
- 是否明确处理错误、缓存和多展业地差异。
