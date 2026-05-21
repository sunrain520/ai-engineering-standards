# APP 客户端测试规范

## 1. 测试目标

APP 测试规范用于保障 KMP 共享逻辑、Android 平台层、iOS 平台层、数据中台、多展业地配置和高风险业务模块的质量稳定。

测试优先级：

1. KMP 核心业务逻辑。
2. DTO Mapper。
3. Repository 和 HSDataCenterKit 数据访问。
4. ViewModel 和 Reactor 状态流。
5. 多展业地配置和策略。
6. 高风险模块端到端主链路。

## 2. KMP 测试规范

强制测试：

1. 核心 UseCase。
2. Repository 实现。
3. DTO Mapper。
4. 统一错误模型转换。
5. 多展业地策略。

必须覆盖：

- 成功路径。
- 后端业务错误。
- 网络错误。
- DTO 字段缺失。
- DTO 枚举异常。
- 缓存命中。
- 缓存降级。
- 多展业地差异。

## 3. Android 测试规范

ViewModel 测试必须覆盖：

1. 首次加载。
2. 下拉刷新。
3. 重试。
4. 空态。
5. 错误态。
6. 成功态。
7. 高频刷新取消或节流。

页面测试推荐覆盖：

1. UI State 到页面展示的映射。
2. 用户点击到 UiEvent 的转发。
3. 路由跳转参数。
4. 多语言文案 key。
5. 主题和资源引用。

## 4. iOS 测试规范

Reactor 测试必须覆盖：

1. Action 输入。
2. Mutation 输出。
3. State 归并结果。
4. loading、error、empty、success。
5. retry。
6. 异常路径。
7. weak self 相关风险检查。

页面测试推荐覆盖：

1. State 到 UI 的绑定。
2. 用户交互到 Action 的转发。
3. 路由跳转和回调。
4. 多语言、主题、资源引用。

## 5. 数据中台测试规范

HSDataCenterKit 相关测试必须覆盖：

1. network first。
2. cache first。
3. background refresh。
4. version check。
5. retry。
6. error fallback。
7. 数据解析失败。
8. 缓存读取失败。

高风险数据必须覆盖：

- 交易。
- 订单。
- 账户。
- 资产。
- 行情。

## 6. 多展业地测试规范

新增或修改多展业地能力时必须覆盖：

1. 默认展业地。
2. 目标展业地。
3. 功能开关开启和关闭。
4. 域名配置。
5. 语言配置。
6. 主题配置。
7. DTO Mapper 差异。
8. 业务策略差异。
9. 合规配置差异。

## 7. AI 生成测试规则

AI 生成 APP 代码时必须同步输出测试方案，至少说明：

1. 需要新增或修改哪些测试。
2. KMP commonTest 覆盖哪些逻辑。
3. Android ViewModel 测试覆盖哪些状态。
4. iOS Reactor 测试覆盖哪些 Action、Mutation、State。
5. DTO Mapper 覆盖哪些接口兼容场景。
6. 多展业地配置覆盖哪些差异。
7. 高风险模块是否需要回归测试。

## 8. Review 检查项

- 核心逻辑是否有 commonTest。
- DTO Mapper 是否覆盖异常字段。
- ViewModel 或 Reactor 是否覆盖状态流。
- 数据中台策略是否有测试。
- 多展业地差异是否有测试。
- 交易、账户、订单是否覆盖失败和重试。
- 是否存在只改代码不补测试的高风险变更。
