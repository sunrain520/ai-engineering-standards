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

| 结果类型 | 目标文件 | doc_type |
| --- | --- | --- |
| evidence-backed 规则 | `standard.md` | `standard` |
| AI 执行规则 | `ai-rules.md` | `ai-rules` |
| Review 检查项 | `review-checklist.md` | `review-checklist` |
| 无证据或需确认规则 | `pending-confirmation.md` | `pending-confirmation` |
| 相近规则合并建议 | `merge-suggestions.md` | `merge-suggestions` |
| 规则冲突 | `conflicts.md` | `conflicts` |
| 代码事实 | `evidence/code-facts.md` | `evidence-code-facts` |
| 正例 | `evidence/positive-examples.md` | `evidence-positive` |
| 反例 | `evidence/forbidden-examples.md` | `evidence-forbidden` |
| 历史兼容 | `evidence/legacy-compatible.md` | `evidence-legacy` |

## 3. doc_id 命名

| 文件 | doc_id |
| --- | --- |
| `overview.md` | `{domain}-overview` |
| `standard.md` | `{domain}-{sub_domain}-standard` |
| `ai-rules.md` | `{domain}-{sub_domain}-ai-rules` |
| `review-checklist.md` | `{domain}-{sub_domain}-review-checklist` |
| `pending-confirmation.md` | `{domain}-pending-confirmation` |
| `merge-suggestions.md` | `{domain}-merge-suggestions` |
| `conflicts.md` | `{domain}-conflicts` |
| `evidence/code-facts.md` | `{domain}-{sub_domain}-evidence-code-facts` |
| `evidence/positive-examples.md` | `{domain}-{sub_domain}-evidence-positive` |
| `evidence/forbidden-examples.md` | `{domain}-{sub_domain}-evidence-forbidden` |
| `evidence/legacy-compatible.md` | `{domain}-{sub_domain}-evidence-legacy` |
| `evidence/README.md` | `{domain}-evidence-readme` |
| `examples/README.md` | `{domain}-examples-readme` |
| `{domain}/{run_id}-review-report.md` | `{domain}-{run_id}-review-report` |
| `{domain}/rule-state-decision/{slug}.md` | `{domain}-{sub_domain}-{slug}-state-decision` |

`{run_id}` 与 `{slug}` 生成规则:

- `run_id`: `YYYYMMDD-HHMMSS-{domain}`,在阶段 1 (Intake and Scope) 生成,贯穿一次萃取。
- `slug`: 由规则 `section_title` 派生 — 去掉 `P0/P1/P2/FORBIDDEN ` 前缀,转 kebab-case,去除非 `[a-z0-9-]` 字符,末段截断到 60 字符。

## 4. Append-only 策略

1. 新运行不得覆盖已有文件内容。
2. 同一规则（按 `{source_doc}「{section_title}」` 二元组识别）追加新 evidence，不重写旧 evidence。
3. 发现相似规则时写入 `merge-suggestions.md`。
4. 发现冲突时写入 `conflicts.md`。
5. 人工确认后再由负责人把规则元数据 `status` 从 `draft` 改为 `active`。

## 5. Front Matter 要求

1. 新建 Markdown 文件顶部必须符合 `frontmatter-format.md`。
2. `doc_id` 必须稳定，不能因为重复运行而变化。
3. `doc_type` 必须使用 `frontmatter-format.md` §3 的枚举值。
4. `indexable: true` 的文件会进入 AI 快速索引；评审报告与规则状态决策记录默认 `indexable: false`。
5. **不为规则生成 Rule ID 或 HTML anchor**；规则的 H2 标题必须满足 `^(P0|P1|P2|FORBIDDEN) ` 前缀，并保持与 `rules-index.json.section_title` 字面一致。
