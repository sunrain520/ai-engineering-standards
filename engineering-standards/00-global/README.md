# 全局规范契约

本目录定义所有研发域共用的规则生命周期、模板、证据格式和质量门禁。APP、PC、前端、后端、行业规范以及 AI Coding Rules 都必须引用这里的统一口径。

## 文件索引

| 文件 | 说明 |
| --- | --- |
| `rule-lifecycle.md` | 规则状态、规则等级、证据等级、AI 使用边界 |
| `standard-template.md` | 团队级规范条目模板 |
| `ai-rules-template.md` | AI Coding Rules 模板 |
| `review-checklist-template.md` | Code Review Checklist 模板 |
| `evidence-template.md` | 代码事实、正反例和历史兼容证据模板 |
| `quality-gate.md` | 规范进入 `draft`、`active`、`pending-confirmation` 的质量门禁 |

## 使用原则

1. 规则正文写团队级标准，不写项目代码说明书。
2. 真实代码路径、正例、反例和历史包袱只放入 `evidence/`。
3. 没有真实 evidence 或负责人确认的内容不得进入 AI 可执行 `draft`。
4. `active` 只能由对应领域负责人确认，不能由 AI 自动发布。
5. P0 和 FORBIDDEN 规则必须可被 Code Review 检查。
