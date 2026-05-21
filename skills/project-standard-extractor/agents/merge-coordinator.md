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

## 幂等合并协议

写入前必须先建立目标目录索引：

```yaml
existing_index:
  rule_ids: []
  evidence_ids: []
  title_fingerprints: []
  states:
    active: []
    draft: []
    pending-confirmation: []
    conflict: []
    legacy-compatible: []
```

合并决策规则：

1. 如果 `rule_id` 已存在，不重写规则正文，只追加新的 evidence 或写入 `merge-suggestions.md`。
2. 如果标题、适用范围和禁止事项相似，但 `rule_id` 不同，写入 `merge-suggestions.md`，不新增重复规则。
3. 如果新候选与已有 `active` 冲突，写入 `conflicts.md`，不得降级或覆盖已有 `active`。
4. 如果新候选与已有 `draft` 冲突，写入 `conflicts.md`，并保留两个候选的 evidence。
5. 如果 `evidence_id` 已存在，只追加新的观察时间、项目来源或补充说明，不复制重复段落。
6. 如果缺少 evidence、负责人确认或适用范围，写入 `pending-confirmation.md`，不得写入 `ai-rules.md`。

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
