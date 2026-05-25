---
doc_id: "app-client-code-review-checklist-archived"
title: "APP Code Review Checklist（已归档）"
domain: "app-client"
sub_domain: "common"
doc_type: "review-checklist"
version: "v0.1.0"
status: "archived"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
superseded_by: "review-checklist.md"
tags:
  - "app-client"
  - "common"
  - "review-checklist"
  - "archived"
---

> ⚠️ **本文件已归档**：内容由 `review-checklist.md` 取代（standard-{sub_domain}.md 派生汇总视图）。本文件保留只为历史回溯，reviewer 应使用 `review-checklist.md`。

# APP Code Review Checklist

## 1. 架构合规

- 是否遵循 KMP + Clean Architecture。
- 可跨端复用逻辑是否下沉 KMP。
- Android 和 iOS 是否存在重复业务规则。
- UI 层是否保持轻量。
- 是否绕过了 HSDataCenterKit。
- 是否绕过现有网络、缓存、日志、配置、多语言、主题体系。

## 2. KMP 合规

- commonMain 是否没有平台 UI 依赖。
- Repository 接口和实现是否分层清晰。
- DTO 是否完成 mapper 转换。
- Domain Model 是否稳定。
- 核心逻辑是否有 commonTest。
- 平台差异是否通过 expect/actual、adapter 或 DI 解决。

## 3. Android 合规

- Activity / Fragment 是否只做 UI 渲染。
- ViewModel 是否统一管理状态。
- 是否完整处理 loading、error、empty、success。
- 是否复用 BaseVM 和 HSLoadData。
- 是否避免直接网络调用。
- 是否避免在页面层拼装复杂业务参数。

## 4. iOS 合规

- 是否遵守 ReactorKit Action、Mutation、State。
- ViewController 是否只做绑定。
- State 是否完整表达页面状态。
- 是否避免直接网络调用。
- 是否避免循环引用。
- 是否避免把复杂业务规则写入 ViewController。

## 5. 数据访问合规

- 是否通过 Repository 或 HSDataCenterKit 访问数据。
- 缓存策略是否明确。
- 错误是否统一转换。
- DTO 是否没有直接进入 UI。
- 高频数据是否有刷新、订阅、取消和降频策略。
- 配置类数据是否有本地兜底和版本检查。

## 6. 多展业地合规

- 差异是否配置化。
- 是否存在硬编码展业地判断。
- 是否支持语言、主题、域名、功能开关配置。
- 是否影响已有展业地。
- 接口差异是否通过 DTO Mapper 隔离。
- 业务差异是否通过策略或 DI 隔离。
- UI 风格差异是否通过主题或组件契约隔离。

## 7. UI 组件合规

- UI 是否只负责渲染和交互转发。
- 是否完整处理 loading、error、empty、success。
- 是否存在硬编码文案。
- 是否存在硬编码主题、颜色或资源。
- 是否重复创建已有组件。
- 组件是否直接依赖具体业务模块。

## 8. 测试合规

- 核心逻辑是否有 commonTest。
- DTO Mapper 是否覆盖异常字段。
- ViewModel 或 Reactor 是否覆盖状态流。
- 数据中台策略是否有测试。
- 多展业地差异是否有测试。
- 交易、账户、订单是否覆盖失败和重试。

## 9. 状态与错误处理

- 页面状态是否统一表达 loading、error、empty、success。
- UI 层是否没有直接解析底层网络异常。
- empty 与 error 是否明确区分。
- 分页、刷新和首屏加载状态是否分开处理。
- 高风险页面是否提供失败兜底和重试入口。

## 10. 路由与页面协作

- 跨业务域跳转是否通过 router、provider 或 contract。
- 是否没有新增 feature-to-feature 实现依赖。
- 路由参数是否集中定义并校验。
- DeepLink 是否校验登录态、权限、展业地和参数。
- 路由失败是否有兜底。

## 11. 构建与依赖治理

- 构建治理是否集中在根工程、约定插件或统一版本治理位置。
- 新增依赖是否说明影响范围、初始化时机和包体/启动影响。
- `contract` 是否保持轻量，未引入 UI 或 feature 实现依赖。
- KMP commonMain 是否没有新增平台 UI 或平台 SDK 依赖。
- 本地调试替换是否不会影响 CI 和发布。

## 12. 安全、合规与可观测性

- token、账号、交易、资金、持仓、订单、隐私字段是否没有进入日志/埋点/Crash 原文。
- 高风险入口是否有登录态、权限、展业地和业务状态校验。
- 本地敏感数据是否说明加密、隔离和清理策略。
- 埋点事件是否有稳定命名、触发时机和参数边界。
- 高风险流程是否有可诊断但脱敏的日志和 Crash breadcrumb。

## 13. 性能与稳定性

- 是否增加启动耗时。
- 页面首屏策略是否明确。
- 是否存在 UI 层大数据转换。
- 是否存在重复请求。
- 高频刷新是否有节流和取消。
- 数据库读写是否避开主线程。
- 高风险模块是否有日志和异常兜底。

## 14. AI 生成代码专项检查

- AI 是否先输出需求归属判断。
- AI 是否判断 KMP 下沉边界。
- AI 是否复用已有模块、Repository、UseCase、组件。
- AI 是否新增重复代码。
- AI 是否说明状态、路由、构建、安全和可观测性影响。
- AI 是否输出测试方案。
- AI 是否输出自检清单。
- AI 是否违反禁止生成项。
