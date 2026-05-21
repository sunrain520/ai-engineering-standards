# iOS 客户端开发规范

## 1. 技术栈

iOS 端新代码默认遵循以下技术栈和工程约束：

- ReactorKit。
- Action、Mutation、State 单向数据流。
- KMP Shared Layer。
- HSDataCenterKit。
- Ktor。
- SQLDelight。
- Napier。

## 2. 分层职责

```text
ViewController / View
    ↓
Reactor
    ↓
KMP UseCase / Repository
    ↓
HSDataCenterKit
    ↓
Network / Cache / Database
```

| 层级 | 职责 | 禁止事项 |
| --- | --- | --- |
| ViewController | UI 渲染、用户交互绑定 | 不写复杂业务逻辑 |
| Reactor | Action、Mutation、State 状态流转 | 不直接写底层数据访问 |
| State | 页面完整状态表达 | 不包含复杂副作用 |
| Mutation | 状态变化描述 | 不直接触发 UI 操作 |
| KMP Shared | 跨端业务逻辑复用 | 不依赖 UIKit |
| DataCenter | 数据访问和缓存调度 | 不处理 UI 展示逻辑 |

## 3. Reactor 状态流规范

标准结构：

```swift
enum Action {
    case viewDidLoad
    case refresh
    case retry
    case tapOrder(String)
}

enum Mutation {
    case setLoading(Bool)
    case setOrderDetail(OrderDetail?)
    case setError(String?)
    case setEmpty(Bool)
}

struct State {
    var isLoading: Bool = false
    var orderDetail: OrderDetail?
    var errorMessage: String?
    var isEmpty: Bool = false
}
```

## 4. ViewController 规则

强制规则：

1. 只负责 UI 绑定、用户交互转发和状态渲染。
2. 用户行为必须通过 Action 进入 Reactor。
3. 不得直接发起网络请求。
4. 不得直接访问数据库、缓存或底层数据源。
5. 不得直接依赖后端 DTO。
6. 不得绕过现有路由、埋点、多语言、主题体系。

推荐规则：

1. Closure 中必须注意 weak self，避免循环引用。
2. UI 状态绑定应尽量保持单向。
3. 页面展示逻辑应与业务规则区分。

## 5. Reactor 规则

强制规则：

1. Reactor 负责接收 Action、生成 Mutation、归并 State。
2. 所有页面状态必须通过 State 统一表达。
3. 所有状态变化必须通过 Mutation 描述。
4. 复杂业务逻辑必须放入 Reactor 或 KMP UseCase。
5. 可跨端复用的规则优先放入 KMP commonMain。
6. 网络请求必须通过 KMP Repository 或 HSDataCenterKit。
7. 不得复制 KMP 已有业务规则。

推荐规则：

1. 高频事件应考虑节流、去重和取消。
2. 交易、账户、订单页面应显式处理 retry 和异常兜底。
3. Reactor 中应避免混入 UI 组件细节。

## 6. State 规则

强制规则：

1. State 必须完整表达页面可渲染状态。
2. State 不得直接持有后端 DTO。
3. State 应包含 loading、error、empty、success 所需信息。
4. State 不应承载副作用或路由跳转动作。

推荐规则：

1. 状态字段命名应贴近页面展示语义。
2. 列表页应明确刷新、分页、加载更多、空态、错误态。
3. 详情页应明确骨架屏、失败重试和数据缺省展示。

## 7. iOS AI 生成规则

AI 生成 iOS 代码时必须遵守：

1. ViewController 只负责 UI 绑定和事件转发。
2. 复杂业务逻辑必须放入 Reactor 或 KMP UseCase。
3. 可跨端复用的规则优先放入 KMP commonMain。
4. 网络请求必须通过 KMP Repository 或 HSDataCenterKit，不允许散落在 ViewController。
5. 所有页面状态必须通过 State 统一表达。
6. 所有用户行为必须通过 Action 进入 Reactor。
7. 所有状态变化必须通过 Mutation 描述。
8. Closure 中必须注意 weak self，避免循环引用。
9. 涉及交易、账户、订单的页面必须处理 loading、error、empty、retry。
10. 不允许绕过现有路由、埋点、多语言、主题体系。

## 8. Review 检查项

- 是否遵守 ReactorKit Action、Mutation、State。
- ViewController 是否只做绑定和渲染。
- State 是否完整表达页面状态。
- 是否避免直接网络调用。
- 是否避免循环引用。
- UI 是否没有直接依赖 DTO。
- 是否复用 KMP 已有业务逻辑。
- 是否考虑高风险模块的重试、异常兜底和日志。
