# HSDataCenterKit 数据中台规范

## 1. 数据中台定位

HSDataCenterKit 是 APP 端统一数据访问入口，负责网络请求封装、缓存策略管理、数据调度、本地缓存读取、错误收敛以及与 KMP Repository 的协同。

数据访问原则：

> UI 层不得直接访问底层网络，平台状态层不得拼接底层请求，Repository 通过 HSDataCenterKit 获取数据并转换为稳定 Domain Model。

## 2. 职责范围

HSDataCenterKit 负责：

- 网络请求统一封装。
- 缓存策略统一管理。
- 数据调度。
- 本地缓存读取。
- 网络优先、缓存优先、缓存降级策略。
- 数据刷新策略。
- 错误收敛。
- 与 KMP Repository 协同。

HSDataCenterKit 不负责：

- UI 渲染。
- 页面状态展示。
- ViewModel 或 Reactor 状态流。
- 平台页面路由。
- 业务页面组件装配。

## 3. 数据访问规则

强制规则：

1. UI 层不得直接访问底层网络。
2. ViewModel 和 Reactor 不得直接拼接底层请求。
3. Repository 应通过 HSDataCenterKit 获取数据。
4. 缓存策略必须显式声明。
5. 接口错误必须转换为统一业务错误。
6. 数据模型必须经过 DTO、Domain Model、UI State 或 State 的转换链路。

推荐规则：

1. 高频行情数据应定义独立刷新策略。
2. 配置类数据应支持版本检查和本地兜底。
3. 交易、订单、账户类数据应优先保证实时性和错误可追踪。
4. 用户资料可使用 cache first 加后台刷新。

## 4. 请求策略规范

| 场景 | 推荐策略 |
| --- | --- |
| 首屏强实时数据 | network first |
| 行情类高频数据 | stream / refresh policy |
| 用户资料 | cache first + background refresh |
| 配置项 | cache first + version check |
| 交易 / 订单 | network first + retry + error fallback |
| 多语言 / 主题 | local config first + remote update |

## 5. 数据模型转换规范

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

AI 生成代码时必须遵守：

1. 不得让 UI 直接依赖后端 DTO。
2. 接口字段变化必须通过 mapper 消化。
3. Domain Model 应保持业务语义稳定。
4. UI State 只表达页面展示需要。
5. 不得在 View 中处理 DTO 字段兼容逻辑。

## 6. 缓存规范

强制规则：

1. 使用缓存前必须明确缓存有效期。
2. 交易、账户、订单等强实时数据不得无约束使用陈旧缓存。
3. 配置、语言、主题等数据必须有本地兜底。
4. 缓存降级必须有日志和错误标记。

推荐规则：

1. 首页、配置、用户资料可使用 cache first。
2. 订单、交易确认、资金账户应使用 network first。
3. 行情高频流应有订阅、取消订阅和后台降频策略。

## 7. 错误收敛规范

HSDataCenterKit 或 Repository 应将底层错误转换为统一业务错误：

- 网络不可用。
- 请求超时。
- 后端业务错误。
- 鉴权失效。
- 风控拒绝。
- 数据解析失败。
- 缓存读取失败。
- 配置缺失。
- 未知错误。

错误处理必须满足：

1. UI 可展示用户可理解的错误文案。
2. 日志可记录稳定错误码和上下文。
3. 高风险模块可识别是否允许重试。
4. 多展业地差异错误码可通过 mapper 或策略隔离。

## 8. Review 检查项

- 是否通过 Repository 或 HSDataCenterKit 访问数据。
- 缓存策略是否明确。
- 错误是否统一转换。
- DTO 是否没有直接进入 UI。
- 高频数据是否有刷新、取消、降频策略。
- 配置类数据是否有版本检查和本地兜底。
- 高风险数据是否避免使用过期缓存。
