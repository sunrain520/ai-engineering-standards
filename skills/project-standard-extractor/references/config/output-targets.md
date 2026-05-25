# Output Targets

## 1. 统一输出文件

每个 domain 目录应提供：

- `overview.md`
- `temp/{run_id}-project-profile.md`
- `temp/{run_id}-extraction-map.md`
- `temp/{run_id}-batch-plan.md`
- `temp/{run_id}-review-report.md`
- `temp/{run_id}-review-summary.md`
- `standard-{sub_domain}.md`       ← 每个 sub_domain 一份；跨 sub_domain 共性使用 `standard-common.md`
- `ai-rules.md`                    ← 汇总所有 sub_domain 的派生视图，每个 domain 一份
- `review-checklist.md`            ← 汇总所有 sub_domain 的派生视图，每个 domain 一份
- `pending-confirmation.md`
- `merge-suggestions.md`
- `conflicts.md`
- `examples/README.md`
- `evidence/README.md`
- `evidence/code-facts.md`
- `evidence/positive-examples.md`
- `evidence/forbidden-examples.md`
- `evidence/legacy-compatible.md`
- `temp/{run_id}-rules-index-candidate.json`
- `temp/{run_id}-llms-candidate.txt`
- `temp/{run_id}-ai-context-pack.md`

### 1.1 sub_domain 拆分规则

| 条件 | 操作 |
| --- | --- |
| 首次生成该 sub_domain 的规则 | 新建 `standard-{sub_domain}.md`，写入 Front Matter + 规则 |
| 该 sub_domain 已有 `standard-{sub_domain}.md` | append-only 追加新规则到文件末尾 |
| 跨多个 sub_domain 均适用的共性规则 | 写入 `standard-common.md`（sub_domain: common） |
| 单个 `standard-{sub_domain}.md` 超过 **1500 行** | 在 merge_summary 输出 ⚠️ 拆分建议（按 task_type 进一步拆分） |

## 2. 写入规则

| 结果类型 | 目标文件 | doc_type |
| --- | --- | --- |
| evidence-backed 规则 | `standard-{sub_domain}.md` | `standard` |
| 项目画像 handoff | `temp/{run_id}-project-profile.md` | `project-profile` |
| extraction map handoff | `temp/{run_id}-extraction-map.md` | `extraction-map` |
| batch plan handoff | `temp/{run_id}-batch-plan.md` | `batch-plan` |
| 质量评审报告 | `temp/{run_id}-review-report.md` | `review-report` |
| 运行审查摘要 | `temp/{run_id}-review-summary.md` | `review-report` |
| AI 执行规则 | `ai-rules.md` | `ai-rules` |
| Review 检查项 | `review-checklist.md` | `review-checklist` |
| 无证据或需确认规则 | `pending-confirmation.md` | `pending-confirmation` |
| 相近规则合并建议 | `merge-suggestions.md` | `merge-suggestions` |
| 规则冲突 | `conflicts.md` | `conflicts` |
| 代码事实 | `evidence/code-facts.md` | `evidence-code-facts` |
| 正例 | `evidence/positive-examples.md` | `evidence-positive` |
| 反例 | `evidence/forbidden-examples.md` | `evidence-forbidden` |
| 历史兼容 | `evidence/legacy-compatible.md` | `evidence-legacy` |
| AI Context Pack 候选 | `temp/{run_id}-ai-context-pack.md` | `ai-context-pack` |
| rules-index 候选 | `temp/{run_id}-rules-index-candidate.json` | 不适用 |
| llms 入口候选 | `temp/{run_id}-llms-candidate.txt` | 不适用 |

## 3. doc_id 命名

| 文件 | doc_id |
| --- | --- |
| `overview.md` | `{domain}-overview` |
| `{domain}/temp/{run_id}-project-profile.md` | `{domain}-{run_id}-project-profile` |
| `{domain}/temp/{run_id}-extraction-map.md` | `{domain}-{run_id}-extraction-map` |
| `{domain}/temp/{run_id}-batch-plan.md` | `{domain}-{run_id}-batch-plan` |
| `standard-{sub_domain}.md` | `{domain}-{sub_domain}-standard` |
| `ai-rules.md` | `{domain}-{sub_domain}-ai-rules` |
| `review-checklist.md` | `{domain}-{sub_domain}-review-checklist` |
| `pending-confirmation.md` | `{domain}-pending-confirmation` |
| `merge-suggestions.md` | `{domain}-merge-suggestions` |
| `conflicts.md` | `{domain}-conflicts` |
| `evidence/code-facts.md` | `{domain}-evidence-code-facts` |
| `evidence/positive-examples.md` | `{domain}-evidence-positive` |
| `evidence/forbidden-examples.md` | `{domain}-evidence-forbidden` |
| `evidence/legacy-compatible.md` | `{domain}-evidence-legacy` |
| `evidence/README.md` | `{domain}-evidence-readme` |
| `examples/README.md` | `{domain}-examples-readme` |
| `{domain}/temp/{run_id}-ai-context-pack.md` | `{domain}-{run_id}-ai-context-pack` |
| `{domain}/temp/{run_id}-review-report.md` | `{domain}-{run_id}-review-report` |
| `{domain}/temp/{run_id}-review-summary.md` | `{domain}-{run_id}-review-summary` |
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

## 6. Handoff 与候选索引产物

1. `project-profile`、`extraction-map`、`batch-plan`、`review-summary`、`review-report` 和 `ai-context-pack` 是运行级 Markdown artifact，必须写入 `temp/`，必须有 Front Matter，默认 `indexable: false`。
2. `rules-index-candidate.json` 必须是候选文件，字段使用 `title`、`domain`、`sub_domain`、`level`、`source_doc`、`section_title`、`evidence_doc`、`tags`，不得包含 `rule_id` 或 `anchor`。
3. `llms-candidate.txt` 是候选入口地图，不得默认覆盖根 `llms.txt`。
4. 发布正式 `.index/rules-index.json` 或根 `llms.txt` 需要用户显式确认；本 Skill 第一阶段只输出候选和合并建议。
