# ai-engineering-standards

部门级研发工程规范仓库，用于沉淀各端开发规范、架构约束、AI 辅助编码规则、Code Review Checklist 和工程最佳实践。

## 快速入口

### 按使用场景阅读

| 你要做什么 | 推荐入口 |
| --- | --- |
| 第一次了解这个仓库 | `docs/03-用户手册/AI辅助研发工程规范用户手册.md` |
| 查团队规范资产 | `engineering-standards/README.md` |
| 从真实项目萃取新规范 | `skills/project-standard-extractor/usage-guide.md` |
| 让 AI 按团队规范写代码 | `engineering-standards/08-ai-coding/README.md` 和对应研发域的 `ai-rules.md` |
| 做代码评审 | 对应研发域的 `review-checklist.md` 和 `standard-{sub_domain}.md` |
| 维护 Skill 或输出模板 | `skills/project-standard-extractor/README.md` |

### 规范资产

| 入口 | 说明 |
| --- | --- |
| `engineering-standards/README.md` | 规范资产总入口 |
| `engineering-standards/00-global/` | 全局规则生命周期、模板、证据策略和质量门禁 |
| `engineering-standards/01-app-client/` | APP 客户端规范（KMP / Android / iOS / 数据中台 / 多展业地） |
| `engineering-standards/02-pc-client/` | PC 客户端规范（待萃取） |
| `engineering-standards/03-frontend/` | 前端规范（待萃取） |
| `engineering-standards/04-backend/` | 后端规范（待萃取） |
| `engineering-standards/05-testing/` | 测试规范（预留） |
| `engineering-standards/06-release/` | 发布规范（预留） |
| `engineering-standards/07-security/` | 安全规范（预留） |
| `engineering-standards/08-ai-coding/` | AI 开发输入、自检和评审规则 |
| `engineering-standards/09-industry/` | 证券、信贷、银行等跨研发域行业规范 |
| `engineering-standards/prompts/` | 可复制给 AI 的标准 Prompt |

### Skill 与工具

| 入口 | 说明 |
| --- | --- |
| `skills/README.md` | Skill 包总入口和最小结构约定 |
| `skills/project-standard-extractor/` | 从真实代码萃取团队规范的 Skill 源包 |
| `skills/project-standard-extractor/SKILL.md` | Skill 对外契约（唯一入口） |
| `skills/project-standard-extractor/usage-guide.md` | 用户使用指南（首次使用读这里） |
| `skills/project-standard-extractor/workflow.md` | 完整阶段流程 |
| `skills/project-standard-extractor/examples/` | golden sample / thin dogfood / 一致性检查 |

### 文档

| 入口 | 说明 |
| --- | --- |
| `docs/01-版本路线/` | 背景、目标、产品定位和同类产品调研 |
| `docs/02-技术方案/README.md` | 技术方案总入口 |
| `docs/02-技术方案/AI快速索引最终方案.md` | V1 快速索引方案：Front Matter + `rules-index.json` + section_title 引用 |
| `docs/02-技术方案/第一阶段技术方案.md` | 第一阶段交付边界与里程碑 |
| `docs/02-技术方案/skill建设.md` | Skill 单入口多 agent 评审建设方案 |
| `docs/02-技术方案/高质量萃取.md` | 高质量萃取要求 |
| `docs/02-技术方案/一期方案.md` | 一期总体方案 |
| `docs/03-用户手册/README.md` | 面向使用者的手册入口：首次使用、规范萃取、产物消费和发布边界 |
| `docs/plans/` | spec-first 计划文档（按日期编号） |
| `docs/brainstorms/` | 早期头脑风暴与决策记录 |

### 治理与协作

| 入口 | 说明 |
| --- | --- |
| `CHANGELOG.md` | 全部用户可见变更（每次 source 变更必须同步） |
| `CLAUDE.md` | Claude Code 项目指令（语言、Changelog、workflow 入口治理、编码执行准则） |
| `AGENTS.md` | spec-first agent 协议与 workflow 入口路由 |

## 当前第一阶段重点

当前仓库聚焦建设 `project-standard-extractor`：

```text
真实项目代码
  -> 代码事实
  -> 团队级规范
  -> AI Coding Rules
  -> Review Checklist
  -> evidence / pending / merge / conflict
```

第一阶段不建设 Web 平台、完整 CLI、自动 CI、向量索引，也不自动把 `draft` 发布为 `active`。

## V1 关键约定

- **文件级索引**：所有规范 Markdown 顶部带 YAML Front Matter（`doc_id` / `domain` / `sub_domain` / `doc_type` / `tags` / `index_format: engineering-standards-md-v1`），详见 `skills/project-standard-extractor/config/frontmatter-format.md`。
- **规则标题级过滤**：通过 `rules-index.json` 索引规则标题、来源文档和级别；不使用 Rule ID 或 HTML anchor。
- **规则引用统一为二元组**：`{source_doc}「{section_title}」`；规则 H2 标题以 `P0 / P1 / P2 / FORBIDDEN ` 前缀开头，与索引字面一致。
- **状态门禁**：所有萃取产物默认 `draft`，`active` 必须由领域负责人确认；不覆盖已有 `active` 或 `draft`，相近 → `merge-suggestions.md`，冲突 → `conflicts.md`，无证据 → `pending-confirmation.md`。
- **Changelog 强制**：任何 source 变更必须同步 `CHANGELOG.md`，用户可见变更追加 `(user-visible)`。

## Workflow 入口

本仓库使用 spec-first workflow 治理（详见 `CLAUDE.md` / `AGENTS.md`）。常见入口：

- 项目规范与胶水产物 → `/spec:standards`
- 需求 / 计划 / 任务 / 执行 → `/spec:brainstorm` → `/spec:plan` → `spec-write-tasks` → `/spec:work`
- 代码 / 文档评审 → `/spec:code-review` / `/spec:doc-review`
- bug 与失败 → `/spec:debug`
- 环境与 MCP → `/spec:mcp-setup`
