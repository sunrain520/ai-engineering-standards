# APP 客户端规范入口

APP 端已有较完整的专题规范，本目录不强制把内容压平成单个 `standard.md`。统一结构通过本 README 和 `evidence/` 目录对齐。

## 统一结构映射

| 统一结构 | APP 现有文件 |
| --- | --- |
| `overview` | `00-app-client-overview.md` |
| `standard` | `01-kmp-shared-layer-standard.md`、`02-android-standard.md`、`03-ios-standard.md`、`04-data-center-standard.md`、`05-module-standard.md`、`06-multi-market-standard.md`、`07-ui-component-standard.md`、`08-testing-standard.md`、`09-performance-standard.md` |
| `ai-rules` | `10-app-ai-rules.md` |
| `review-checklist` | `11-code-review-checklist.md` |
| `examples` | 后续由真实代码萃取补充 |
| `evidence` | `evidence/` |

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

## 使用规则

1. APP 新需求优先读取 `10-app-ai-rules.md`。
2. 涉及 KMP、Android、iOS、数据中台、多展业地时，必须读取对应专题规范。
3. P0 / FORBIDDEN 规则后续必须补充真实代码路径 evidence。
4. 与现有 APP 规范冲突的新结论写入 `conflicts.md`，不得直接覆盖专题文件。
