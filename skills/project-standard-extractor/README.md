# project-standard-extractor

`project-standard-extractor` 是规范萃取 workflow 的源资产包。它面向用户只暴露一个 Skill，但内部通过阶段角色完成输入引导、代码事实萃取、规则生成、证据写入、质量门禁和合并协调。

## 目录

| 路径 | 说明 |
| --- | --- |
| `SKILL.md` | 对外入口 |
| `usage-guide.md` | 用户使用指南：三种安装路径 / 输入 / 产物 / 边界 |
| `workflow.md` | 完整执行流程 |
| `input-guide.md` | 交互式输入顺序 |
| `installation-or-consumption.md` | 第一阶段使用和安装边界 |
| `config/` | 研发域、子领域、Front Matter formatter 和输出目录映射 |
| `agents/` | 阶段 agent / role contracts |
| `templates/` | 输出文件模板 |
| `prompts/` | 阶段 prompt |
| `quality-gate.md` | Skill 侧质量门禁适配 |
| `examples/` | golden sample、thin dogfood、一致性检查 |
| `evals/` | 触发、边界、失败模式和期望行为回归用例 |

## 核心原则

1. 先输出代码事实，再输出规范结论。
2. 规则正文保持团队级抽象。
3. evidence 独立存放真实路径、正反例和历史兼容事实。
4. 无证据内容不得进入 AI 默认执行路径。
5. 每次运行只追加，不覆盖已有 `active` 或 `draft`。
6. 输出文档顶部必须带 YAML Front Matter，支持 AI 快速索引。

## 第一阶段交付边界

第一阶段交付的是可复制、可引用、可人工执行的 Skill source package，不自动安装到 Codex、Claude Code 或其他宿主 runtime。当前 canonical path 是 `skills/project-standard-extractor/`。真正的可运行性通过 `examples/golden-sample-run.md` 和 `examples/thin-dogfood-run.md` 证明。
