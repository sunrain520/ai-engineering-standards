# engineering-standards

本目录是部门级研发工程规范资产的主入口，包含全局规范契约、各研发域规范、AI Coding Rules、Prompt 模板、Review Checklist 和规范萃取 Skill。

## 目录索引

| 目录 | 内容 |
| --- | --- |
| `00-global/` | 规则生命周期、模板、证据和质量门禁 |
| `01-app-client/` | APP 客户端统一规范，含 KMP、Android、iOS、数据中台、多展业地 |
| `02-pc-client/` | PC 客户端规范预留目录 |
| `03-frontend/` | 前端规范入口，等待真实项目萃取 |
| `04-backend/` | 后端规范入口，等待真实项目萃取 |
| `05-testing/` | 测试规范预留目录 |
| `06-release/` | 发布规范预留目录 |
| `07-security/` | 安全规范预留目录 |
| `08-ai-coding/` | AI 开发输入、自检和评审规则 |
| `09-industry/` | 证券、信贷、银行等跨研发域行业规范入口 |
| `prompts/` | 可复制给 AI 的标准输入 prompt |

## 推荐使用路径

1. 新增规范前，先看 `00-global/rule-lifecycle.md`。
2. 从真实代码萃取规范时，使用 `../skills/project-standard-extractor/SKILL.md`。
3. APP 端开发直接查看 `01-app-client/README.md` 和现有专题规范。
4. 前端、后端、行业目录当前只提供结构和 evidence policy，真实规则必须由后续萃取产生。

## 关键原则

- 规则正文保持团队级抽象。
- 真实路径和正反例写入 `evidence/`。
- 无 evidence 或负责人确认的内容不得进入 AI 可执行 `draft`。
- `active` 只能由领域负责人确认。
- 所有用户可见变更必须更新仓库根目录 `CHANGELOG.md`。
