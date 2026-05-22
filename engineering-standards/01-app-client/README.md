# APP 客户端规范入口

APP 端已有较完整的专题规范，本目录不强制把内容压平成单个 `standard.md`。统一结构通过本 README 和 `evidence/` 目录对齐。

## 编号文档体系

| 文件 | 规范维度 | 状态 |
| --- | --- |
| `00-app-client-overview.md` | 总览、架构目标、入口导航 | owner-confirmed |
| `01-kmp-shared-layer-standard.md` | KMP 共享层 | owner-confirmed + 待补 evidence |
| `02-android-standard.md` | Android 平台层 | owner-confirmed + 待补 evidence |
| `03-ios-standard.md` | iOS 平台层 | owner-confirmed + 待补 evidence |
| `04-data-center-standard.md` | 数据访问与缓存 | owner-confirmed + 待补 evidence |
| `05-module-standard.md` | 模块化与模块边界 | owner-confirmed + active evidence-backed 增量 |
| `06-multi-market-standard.md` | 多展业地 | owner-confirmed + 待补 evidence |
| `07-ui-component-standard.md` | UI 与组件 | owner-confirmed + 待补 evidence |
| `08-testing-standard.md` | 测试 | owner-confirmed + 待补 evidence |
| `09-performance-standard.md` | 性能与稳定性 | owner-confirmed + 待补 evidence |
| `10-app-ai-rules.md` | AI Coding Rules 派生视图 | owner-confirmed |
| `11-code-review-checklist.md` | Code Review Checklist 派生视图 | owner-confirmed |
| `12-state-error-standard.md` | 状态与错误处理 | structure-ready |
| `13-navigation-routing-standard.md` | 路由与页面协作 | structure-ready |
| `14-build-dependency-standard.md` | 构建与依赖治理 | structure-ready + draft evidence-backed 增量 |
| `15-security-compliance-standard.md` | 安全与合规 | structure-ready |
| `16-observability-standard.md` | 日志、埋点与可观测性 | structure-ready |
| `17-app-standard-extraction-process.md` | APP 代码规范萃取流程 | active process doc |

## 子领域覆盖矩阵

| 子领域 | 状态 | 说明 |
| --- | --- | --- |
| KMP Shared Layer | owner-confirmed | 已有专题规范，待补真实代码 evidence |
| Android MVVM / BaseVM / HSLoadData | owner-confirmed | 已有专题规范，待补真实代码 evidence |
| iOS ReactorKit | owner-confirmed | 已有专题规范，待补真实代码 evidence |
| HSDataCenterKit | owner-confirmed | 已有专题规范，待补真实代码 evidence |
| 多展业地 | owner-confirmed | 已有专题规范，待补真实代码 evidence |
| UI Component | owner-confirmed | 已有专题规范，待补真实代码 evidence |
| Testing | owner-confirmed | 已有专题规范，待补真实代码 evidence |
| Performance | owner-confirmed | 已有专题规范，待补真实代码 evidence |
| State & Error | structure-ready | 已定义萃取维度，待真实代码 evidence |
| Navigation & Routing | structure-ready | 已定义萃取维度，待真实代码 evidence |
| Build & Dependency | draft evidence-backed | 已有 `standard-build-governance.md` 单项目增量萃取，待负责人确认并收敛到编号文档 |
| Security & Compliance | structure-ready | 已定义萃取维度，待真实代码 evidence / 负责人确认 |
| Observability | structure-ready | 已定义萃取维度，待真实代码 evidence |

## 使用规则

1. APP 新需求优先读取 `10-app-ai-rules.md`。
2. 涉及 KMP、Android、iOS、数据中台、多展业地时，必须读取对应专题规范。
3. P0 / FORBIDDEN 规则后续必须补充真实代码路径 evidence。
4. 与现有 APP 规范冲突的新结论写入 `conflicts.md`，不得直接覆盖专题文件。

## 结构说明

当前 APP 目录同时保留两类产物：

- 编号化稳定入口：`00-*.md` 到 `17-*.md`，作为 APP 开发规范和萃取维度主入口。
- `project-standard-extractor` 生成的 evidence-backed 增量产物：`standard-{sub_domain}.md`、`ai-rules.md`、`review-checklist.md`、`evidence/` 和候选索引。

短期通过本 README 维护映射关系，不强行删除已萃取的 `standard-*` 文件。后续新增萃取产物应先判断所属 `00-xx` 维度，稳定规则逐步收敛进编号文档。

## 已萃取增量产物映射

| 萃取产物 | 对应编号文档 | 说明 |
| --- | --- | --- |
| `standard-kmp-shared.md` | `01-kmp-shared-layer-standard.md` | KMP Shared 单项目 draft 增量 |
| `standard-android.md` | `02-android-standard.md` | Android app shell / 页面状态 / 账户页组合单项目 draft 增量 |
| `standard-module-boundary.md` | `05-module-standard.md` | contract / module-boundary active 规则 |
| `standard-build-governance.md` | `14-build-dependency-standard.md` | Gradle / local fast build / dependency substitution 单项目 draft 增量 |
