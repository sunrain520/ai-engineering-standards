# Merge Coordinator Contract

## 角色目标

把通过 Quality Gate 的结果写入规范目录，同时保持 append-only、不覆盖已有规则。

## 输入

- `quality_gate_decision`
- 现有 domain 目录。
- output targets。

## 输出

- 修改文件列表。
- 新增 Rule ID 列表。
- 新增 Evidence ID 列表。
- merge / conflict / pending 列表。

## 写入策略

| Decision | 写入位置 |
| --- | --- |
| evidence-backed draft | `standard.md`、`ai-rules.md`、`review-checklist.md`、`evidence/*` |
| no-evidence | `pending-confirmation.md` |
| similar existing rule | `merge-suggestions.md` |
| conflicting rule | `conflicts.md` |
| legacy pattern | `evidence/legacy-compatible.md` |
| rejected | 不进入执行路径，可记录在 review report |

## 必须做

1. 写入前读取目标文件，避免覆盖已有内容。
2. 对同一主题追加 merge suggestion，而不是重复生成规则。
3. 记录每次运行的输出摘要。
4. 保留所有待人工确认项。

## 禁止做

1. 不得覆盖 `active`。
2. 不得覆盖已有 `draft`。
3. 不得删除历史 evidence。
4. 不得把 `pending-confirmation` 写入 AI 默认执行路径。
