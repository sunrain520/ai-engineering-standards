# 用户使用指南

面向第一次使用 `project-standard-extractor` 的用户。Skill 边界说明见 `installation-or-consumption.md`；AI 入口契约见 `SKILL.md`；阶段执行细节见 `workflow.md`。本文只解决"我现在该怎么用"。

## 1. 前置条件

- 一个支持 Skill 或可注入系统上下文的 AI 宿主（Claude Code / Codex / 其他对话工具均可）。
- 至少一个想萃取规范的真实项目代码路径。
- 知道萃取的研发域（APP / 前端 / 后端）和行业场景；不确定时由 Skill 先推断再让你确认。
- 目标规范仓库的写入权限（默认就是本仓库 `engineering-standards/`）。

## 2. 三种使用路径

第一阶段不自动安装到任何宿主 runtime，按"立即可用度"提供三条路径，任选其一。

### A. 本仓库直接用（零安装，最快）

在本仓库的 AI 会话里直接发：

```
读取 skills/project-standard-extractor/SKILL.md，按 workflow.md 执行萃取。
project_paths:
  - <项目1的本地路径>
  - <项目2的本地路径>
```

剩余输入由 Skill 按 `input-guide.md` 顺序追问。

### B. 装到 Claude Code（个人全局或某个目标项目）

`SKILL.md` 已带合规 frontmatter（`name` + `description`），Claude Code 直接识别。

```bash
# 个人全局：所有 Claude Code 会话可用
cp -r skills/project-standard-extractor ~/.claude/skills/

# 项目级：仅在目标项目会话内可用
cp -r skills/project-standard-extractor /path/to/target-repo/.claude/skills/
```

复制后在对应会话里说"用 project-standard-extractor 萃取规范"即可。

### C. 装到 Codex 或其他宿主

```bash
cp -r skills/project-standard-extractor ~/.codex/skills/
```

其他宿主把整个目录复制到该宿主加载 Skill 的位置即可。**保持 `config/`、`agents/`、`templates/`、`prompts/`、`examples/` 内部相对路径不变**，否则 SKILL.md 的相对引用会断。

## 3. 提供输入

最小启动只需 `project_paths`。Skill 会按以下顺序追问其他项（已提供过的不会重复问，可由代码结构推断的会先给推断结果让你确认）：

1. `project_paths`
2. 研发域
3. 行业场景
4. 输出范围
5. 子领域 / 技术栈
6. 业务模块
7. 正例候选
8. 反例 / 历史兼容候选
9. 已有规范或文档
10. 质量关注点
11. 输出目标
12. 确认声明

每项含义详见 `input-guide.md`。

## 4. 产物落点

按 `config/output-targets.md` 默认写入：

| 产物 | 位置 |
| --- | --- |
| `overview.md` / `standard.md` / `ai-rules.md` / `review-checklist.md` | `engineering-standards/<域>/` |
| `evidence/code-facts.md` / `positive-examples.md` / `forbidden-examples.md` / `legacy-compatible.md` | `engineering-standards/<域>/evidence/` |
| `pending-confirmation.md` / `merge-suggestions.md` / `conflicts.md` | `engineering-standards/<域>/` |

新规则初始状态都是 `draft`；端 / 行业负责人确认后才能升级 `active`。状态机详见 `engineering-standards/00-global/rule-lifecycle.md`。

## 5. 想先 dry run

真实运行前可以让 AI 用样例文档解释一遍流程：

```
读取 skills/project-standard-extractor/examples/golden-sample-run.md
和 examples/thin-dogfood-run.md，
向我说明 intake → facts → classification → generation → review → merge
各阶段产生什么产物，以及真实运行时我需要补哪些输入。
```

样例不是真实运行 evidence，但能证明入口可驱动闭环。

## 6. 边界

- **不会自动发布 `active`**：所有产出默认 `draft`，需要领域负责人手动确认升级。
- **不会覆盖已有 `active` 或 `draft`**：相近 → `merge-suggestions.md`；冲突 → `conflicts.md`；无证据 → `pending-confirmation.md`。
- **不会读取或复制密钥、token、私钥、生产凭据原值**：敏感文件只记录脱敏存在事实。
- **规则正文不写真实路径**：路径只存在于 `evidence/` 下。
- **每次 source 变更必须同步根 `CHANGELOG.md`**：见根 `AGENTS.md` / `CLAUDE.md`。

## 7. 相关文档索引

| 想知道 | 看这里 |
| --- | --- |
| Skill 对外入口契约 | `SKILL.md` |
| 第一阶段使用与安装边界 | `installation-or-consumption.md` |
| 输入项含义和顺序 | `input-guide.md` |
| 完整阶段执行流程 | `workflow.md` |
| 各阶段角色合约（含 R13 角色映射） | `agents/README.md` |
| 输出文件模板 | `templates/` |
| 阶段 prompt | `prompts/` |
| Skill 侧质量门禁适配 | `quality-gate.md` |
| 全局 canonical 质量门禁 | `engineering-standards/00-global/quality-gate.md` |
| 规则状态机 | `engineering-standards/00-global/rule-lifecycle.md` |
| 运行样例 | `examples/golden-sample-run.md` / `examples/thin-dogfood-run.md` / `examples/consistency-checklist.md` |
| 回归用例 | `evals/trigger-cases.md` / `evals/boundary-cases.md` / `evals/failure-cases.md` / `evals/expected-behavior.md` |
