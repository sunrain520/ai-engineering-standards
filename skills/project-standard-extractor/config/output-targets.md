# Output Targets

## 1. 统一输出文件

每个 domain 目录应提供：

- `overview.md`
- `standard.md`
- `ai-rules.md`
- `review-checklist.md`
- `pending-confirmation.md`
- `merge-suggestions.md`
- `conflicts.md`
- `examples/README.md`
- `evidence/README.md`
- `evidence/code-facts.md`
- `evidence/positive-examples.md`
- `evidence/forbidden-examples.md`
- `evidence/legacy-compatible.md`

## 2. 写入规则

| 结果类型 | 目标文件 |
| --- | --- |
| evidence-backed 规则 | `standard.md` |
| AI 执行规则 | `ai-rules.md` |
| Review 检查项 | `review-checklist.md` |
| 无证据或需确认规则 | `pending-confirmation.md` |
| 相近规则合并建议 | `merge-suggestions.md` |
| 规则冲突 | `conflicts.md` |
| 代码事实 | `evidence/code-facts.md` |
| 正例 | `evidence/positive-examples.md` |
| 反例 | `evidence/forbidden-examples.md` |
| 历史兼容 | `evidence/legacy-compatible.md` |

## 3. Append-only 策略

1. 新运行不得覆盖已有文件内容。
2. 对同一 Rule ID 追加新 evidence，不重写旧 evidence。
3. 发现相似规则时写入 `merge-suggestions.md`。
4. 发现冲突时写入 `conflicts.md`。
5. 人工确认后再由负责人把 `draft` 改为 `active`。
