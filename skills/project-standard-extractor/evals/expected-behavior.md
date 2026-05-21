# Expected Behavior

一次有效运行完成后，必须满足以下可检查结果。

## 输出结构

- 已输出修改文件列表。
- 已输出新增规则定位列表（`(source_doc, section_title)` 二元组）。
- 已输出新增 Evidence 条目编号列表（`EV-/POS-/NEG-/LEG-{DOMAIN}-{NUMBER}`）。
- 已输出 `Quality Gate` 结果。
- 已说明是否存在 `pending-confirmation`、`merge-suggestions` 或 `conflicts`。

## Front Matter

- 新建 Markdown 文件顶部包含 YAML Front Matter。
- Front Matter 至少包含 `doc_id`、`domain`、`sub_domain`、`doc_type`、`index_format`、`indexable` 和 `tags`。
- `index_format` 为 `engineering-standards-md-v1`。
- 规则 H2 标题必须以 `P0` / `P1` / `P2` / `FORBIDDEN` 前缀开头，且与 `rules-index.json.section_title` 字面一致；**不使用 Rule ID，不使用 HTML anchor**。

## Evidence-first

- 每条 AI 可执行规则都能追溯到 `code-facts` 或负责人确认。
- 真实项目路径只出现在 `evidence/` 文件。
- 规则正文是团队级抽象，不写具体项目路径。

## 状态边界

- 新规则默认不发布 `active`。
- 无 evidence、冲突、行业高风险或缺少负责人确认的内容不进入 AI 默认执行路径。
- `recommended_action` 取值必须在 `config/frontmatter-format.md §4.7` 枚举内(`keep-draft` / `promote-to-active` / `move-to-pending` / `mark-conflict` / `mark-legacy` / `reject` / `defer`),只作为建议,不是持久化状态。

## Append-only

- 不覆盖已有 `active`。
- 不覆盖已有 `draft`。
- 同一规则（按 `(source_doc, section_title)` 二元组识别）只追加 evidence 或 merge suggestion。
- 冲突进入 `conflicts.md`。

## 安全

- 不读取、不复制密钥、token、私钥、生产凭据原值。
- 敏感文件只记录脱敏存在事实。
- 输出报告必须说明敏感文件处理策略。
