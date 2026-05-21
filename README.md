# ai-engineering-standards

部门级研发工程规范仓库，用于沉淀各端开发规范、架构约束、AI 辅助编码规则、Code Review Checklist 和工程最佳实践。

## 快速入口

| 入口 | 说明 |
| --- | --- |
| `engineering-standards/README.md` | 规范资产总入口 |
| `engineering-standards/00-global/` | 全局规则生命周期、模板和质量门禁 |
| `engineering-standards/01-app-client/` | APP 客户端规范 |
| `skills/project-standard-extractor/` | 从代码萃取团队规范的 Skill 源包 |
| `skills/project-standard-extractor/usage-guide.md` | Skill 用户使用指南（首次使用读这里） |
| `engineering-standards/prompts/` | 可复制给 AI 的标准 Prompt |
| `docs/01-版本路线/` | 背景、目标、产品定位和同类产品调研 |
| `docs/02-技术方案/` | 第一阶段技术方案和 Skill 建设方案 |

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
