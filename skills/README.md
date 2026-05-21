# Skills

本目录保存可被 AI 宿主引用或安装的 Skill source package。它和 `engineering-standards/` 分工不同：

- `skills/`：工具 / workflow，用来生成、萃取、评审或维护规范。
- `engineering-standards/`：规范结果文档，用来给研发、AI 和 Reviewer 使用。

## 当前 Skill

| Skill | 说明 |
| --- | --- |
| `project-standard-extractor/` | 从真实项目代码和团队上下文中萃取团队级研发规范 |

## 标准最小结构

```text
skill-name/
└── SKILL.md
```

## 复杂 workflow 推荐结构

```text
skill-name/
├── SKILL.md
├── README.md
├── workflow.md
├── config/
├── agents/
├── templates/
├── prompts/
├── examples/
└── quality-gate.md
```

`agents/` 默认是某个 Skill 的内部阶段合约。只有当多个 Skill 复用同一批 agent contract 时，才考虑新增一级公共 `agents/`。
