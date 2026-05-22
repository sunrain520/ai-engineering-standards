# APP 状态与错误处理规范

> 当前文档是 APP 状态与错误处理的萃取维度说明，状态为 structure-ready。具体强制规则必须由后续真实 evidence 或负责人确认补齐。

## 1. 适用范围

本规范覆盖 APP 页面状态、加载态、空态、错误态、重试、降级和错误传播链路。适用于 Android ViewModel/BaseVM/HSLoadData、iOS ReactorKit State、KMP Presenter/StateFlow，以及跨端共享的 Error Model。

## 2. 萃取时应关注的 evidence

| 维度 | 候选代码信号 |
| --- | --- |
| 页面状态模型 | `UiState`、`State`、`LoadState`、`ViewState`、`sealed class`、`enum state` |
| 加载态框架 | `HSLoadData`、`BaseLoadDataFragment`、`BaseVM`、loading/refresh/retry 方法 |
| 错误传播 | `Result`、`Exception`、`HsNetworkException`、ErrorModel、toast/dialog/error page |
| 空态处理 | empty view、empty data branch、placeholder、skeleton |
| 重试与降级 | retry、fallback、cache fallback、local default、offline branch |

## 3. 应沉淀的规则内容

1. 页面必须用统一状态模型表达 loading、error、empty、success，不能让 UI 分散维护多个布尔变量。
2. 错误应在 ViewModel/Reactor/Presenter 层收敛为页面可消费状态，UI 不直接解析底层异常。
3. 高频刷新、分页和下拉刷新必须区分首屏 loading、增量 loading 和局部错误。
4. 交易、账户、订单、行情等高风险页面必须有失败兜底、重试入口和必要日志。
5. 无数据、无权限、网络异常、服务异常应区分文案和交互，不得统一吞成空列表。

## 4. AI 生成代码要求

1. AI 新增页面时必须先声明页面状态模型，并覆盖 loading、error、empty、success。
2. AI 不得在 View/Fragment/ViewController 中直接捕获底层网络异常后拼 UI。
3. AI 修改错误处理时必须说明错误来源、转换位置、用户可见反馈和重试策略。

## 5. Code Review 检查项

- [ ] 页面状态是否由单一状态模型表达。
- [ ] 错误是否在状态层收敛，而不是散落在 UI 回调里。
- [ ] empty 与 error 是否区分。
- [ ] 高风险页面是否有兜底、重试和日志。
- [ ] 分页/刷新是否区分首屏、增量和局部错误。
