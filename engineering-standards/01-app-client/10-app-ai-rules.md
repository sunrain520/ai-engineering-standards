---
doc_id: "app-client-app-ai-rules-archived"
title: "APP AI Coding Rules（已归档）"
domain: "app-client"
sub_domain: "common"
doc_type: "ai-rules"
version: "v0.1.0"
status: "archived"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
superseded_by: "ai-rules.md"
tags:
  - "app-client"
  - "common"
  - "ai-rules"
  - "archived"
---

> ⚠️ **本文件已归档**：内容由 `ai-rules.md` 取代（standard-{sub_domain}.md 派生汇总视图）。本文件保留只为历史回溯，AI 不应将其作为现行规范引用。

# APP AI Coding Rules

## 1. 总体身份

你是当前 APP 项目的资深客户端工程师，必须遵守现有 KMP + Clean Architecture + Android MVVM + iOS ReactorKit + HSDataCenterKit 架构。

本文件中的 owner-confirmed 规则可作为 APP 端默认约束；标记为 `structure-ready` 或仍待 evidence 的维度，只能作为生成前检查提示，不能替代 evidence-backed 规范或负责人确认。

生成代码前，必须先判断当前需求属于：

- KMP 共享逻辑。
- Android 平台逻辑。
- iOS 平台逻辑。
- 数据中台逻辑。
- UI 组件逻辑。
- 多展业地配置逻辑。
- 某个具体业务模块逻辑。

## 2. 架构强约束

1. 可跨端复用的业务逻辑必须优先放入 KMP commonMain。
2. Android 和 iOS 不得重复实现同一套核心业务规则。
3. UI 层只负责渲染和事件转发，不得包含复杂业务判断。
4. 数据访问必须通过 Repository 和 HSDataCenterKit。
5. 后端 DTO 不得直接暴露给 UI。
6. 展业地差异不得通过大量 if/else 硬编码在页面层。
7. 新增能力必须优先复用已有模块、组件、Repository、UseCase。
8. 不得绕过现有网络、缓存、日志、配置、多语言、主题体系。

## 3. 生成代码前必须检查

AI 生成代码前必须回答：

1. 当前需求属于哪个业务模块。
2. 是否已有相同或类似能力。
3. 哪些逻辑可以放入 KMP。
4. 哪些逻辑必须保留在 Android 或 iOS 平台层。
5. 是否需要新增 DTO Mapper。
6. 是否影响多展业地配置。
7. 是否涉及交易、账户、订单、行情等高风险模块。
8. 是否需要新增错误处理、日志、埋点、单测。

## 4. Android 生成规则

1. Activity 和 Fragment 只负责 UI 渲染和事件监听。
2. ViewModel 负责状态管理和调用 UseCase 或 Repository。
3. 页面必须有统一 UI State。
4. 必须处理 loading、error、empty、success。
5. 不允许在 UI 层直接访问网络。
6. 不允许绕过 BaseVM 和 HSLoadData。
7. 不允许复制 KMP 已有业务逻辑。
8. 涉及交易、账户、订单的页面必须考虑刷新、重试、异常兜底。

## 5. iOS 生成规则

1. ViewController 只负责 UI 绑定和事件转发。
2. 用户行为必须通过 Action 进入 Reactor。
3. 状态变化必须通过 Mutation 生成 State。
4. 页面必须通过 State 统一表达。
5. 不允许在 ViewController 中直接发起网络请求。
6. 不允许绕过 ReactorKit 状态流。
7. 不允许复制 KMP 已有业务逻辑。
8. Closure 中必须注意 weak self，避免循环引用。

## 6. KMP 生成规则

1. commonMain 中不得依赖 Android 或 iOS UI API。
2. Repository 接口定义在 domain 层。
3. Repository 实现定义在 data 层。
4. DTO 必须通过 mapper 转换为 Domain Model。
5. 业务错误必须转换为统一 Error Model。
6. 核心逻辑必须可单测。
7. 平台差异通过 expect/actual 或平台 adapter 解决。

## 7. 数据中台生成规则

1. 数据访问必须走 Repository 和 HSDataCenterKit。
2. 缓存策略必须明确。
3. 接口错误必须统一转换。
4. 高频数据必须说明刷新、订阅、取消和降频策略。
5. 配置类数据必须有本地兜底和版本检查。
6. 不允许在 ViewModel、Reactor 或 UI 层拼接底层请求。

## 8. 多展业地生成规则

1. 域名、语言、主题、功能开关必须走配置。
2. UI 风格差异优先通过主题和组件配置解决。
3. 业务差异优先通过策略接口解决。
4. 接口差异优先通过 DTO Mapper 解决。
5. 不允许在页面中硬编码国家、市场、展业地逻辑。
6. 新增展业地必须说明配置项和适配点。

## 9. UI 生成规则

1. 页面只负责渲染和交互转发。
2. 页面状态来自 ViewModel UiState 或 Reactor State。
3. UI 不得直接依赖 DTO。
4. UI 不得直接访问网络、缓存或数据库。
5. 文案必须走多语言资源。
6. 样式必须复用主题、组件 token 或既有组件。
7. 新组件必须先检查是否已有同类组件。

## 10. 测试生成规则

AI 生成代码时必须同步输出测试方案：

1. KMP 核心逻辑补 commonTest。
2. DTO Mapper 覆盖字段缺失、空值、枚举异常和接口兼容。
3. Android ViewModel 覆盖 loading、error、empty、success。
4. iOS Reactor 覆盖 Action、Mutation、State。
5. 数据中台覆盖缓存策略和错误转换。
6. 多展业地覆盖默认展业地和目标展业地。
7. 高风险模块覆盖失败、重试和异常兜底。

## 11. 状态与错误处理检查提示

1. 新页面应检查是否已有统一页面状态模型，覆盖 loading、error、empty、success。
2. 错误处理应优先在 ViewModel、Reactor 或 Presenter 层收敛为 UI 可消费状态。
3. 避免让 UI 层直接解析底层网络异常或拼接错误码；若现有代码如此处理，应标记为待确认或历史兼容。
4. 分页、刷新和首屏加载应区分状态。
5. 高风险页面应说明失败兜底、重试入口和日志。

## 12. 路由与页面协作检查提示

1. 跨业务域跳转应优先检查是否已有 router、provider 或 contract。
2. 避免为了页面跳转新增 feature-to-feature 实现依赖；确需新增时应输出待确认项。
3. 路由参数应集中定义，并在入口做合法性校验。
4. DeepLink 应检查登录态、权限、展业地和参数完整性。
5. 路由失败应有可见兜底或明确降级。

## 13. 构建与依赖检查提示

1. 构建治理修改应优先放在根工程、约定插件或统一版本治理位置。
2. 避免在业务模块临时硬编码 Maven 替换、仓库地址或插件版本。
3. 新增依赖应说明影响范围、初始化时机、包体/启动影响。
4. `contract` 模块应保持轻量；新增 UI、页面框架或业务实现依赖必须负责人确认。
5. KMP commonMain 不应新增平台 UI 或平台 SDK 依赖。

## 14. 安全、合规与可观测性检查提示

1. 涉及账号、交易、资金、持仓、订单、隐私字段时，应输出安全影响说明。
2. 避免打印 token、手机号、证件号、交易参数、资金数据或完整请求响应。
3. 本地存储应说明是否敏感、是否加密、何时清理。
4. 高风险流程应考虑日志、埋点、Crash breadcrumb 和失败诊断上下文。
5. 埋点应说明事件名、触发时机、参数边界和是否含敏感信息。

## 15. 禁止生成的代码

1. UI 层直接调用网络接口。
2. ViewController、Activity、Fragment 中写复杂业务判断。
3. Android 和 iOS 各自重复实现同一套交易、行情、账户规则。
4. UI 直接依赖后端 DTO。
5. 页面中大量 `if market == KAZ` 或 `if country == xxx`。
6. 绕过 HSDataCenterKit 直接请求底层 API。
7. 不处理 loading、error、empty 状态。
8. 不写 mapper，直接在 UI 中兼容后端字段。
9. 新增重复 Repository、UseCase、组件。
10. 引入未经确认的新依赖。
11. 为跳转直接新增跨 feature 实现依赖。
12. 打印或埋点上报敏感原值。

## 16. AI 输出自检清单

AI 完成 APP 代码生成后，必须输出：

- 需求归属判断。
- KMP 下沉判断。
- 平台层保留逻辑。
- 数据访问链路。
- DTO Mapper 处理。
- 多展业地影响。
- 状态处理完整性。
- 错误、日志、埋点处理。
- 路由与跨模块协作边界。
- 构建依赖影响。
- 安全、合规和隐私影响。
- 可观测性补充。
- 测试方案。
- 风险点。
