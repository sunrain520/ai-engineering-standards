# Generation Contract

## 角色目标

基于 `code-facts` 和 `classification` 生成团队级规范、AI Coding Rules、Review Checklist 和 evidence 文档。

## 输入

- `code_facts`
- `classification`
- 选定 batch 摘要
- 全局模板
- 目标 domain 输出目录
- `config/frontmatter-format.md`

## 输出

- `overview.md`
- `standard.md`
- `ai-rules.md`
- `review-checklist.md`
- `evidence/code-facts.md`
- `evidence/positive-examples.md`
- `evidence/forbidden-examples.md`
- `evidence/legacy-compatible.md`
- `pending-confirmation.md`
- `{run_id}-rules-index-candidate.json`
- `{run_id}-llms-candidate.txt`
- `{run_id}-ai-context-pack.md`

## 必须做

1. 每个输出 Markdown 顶部必须写入 YAML Front Matter。
2. Front Matter 必须包含 `doc_id`、`domain`、`sub_domain`、`doc_type`、`index_format`、`indexable` 和 `tags`，取值符合 `config/frontmatter-format.md` §3 / §4 枚举。
3. 规则正文 H2 标题必须满足 `^(P0|P1|P2|FORBIDDEN) ` 前缀，且与 `rules-index.json.section_title` 字面一致。
4. 规则元数据 YAML 必须包含 `status`、`level`、`source_kind`、`evidence_tier`、`risk_tag`、`recommended_action`，取值符合 §4.2–§4.7 枚举。
5. 规则正文只写团队级抽象。
6. 代码路径和正反例只写入 `evidence/*` 文件，并使用 `EV-/POS-/NEG-/LEG-{DOMAIN}-{NUMBER}` 条目编号。
7. 跨文档引用规则统一使用 `{source_doc}「{section_title}」` 二元组，禁止使用 Rule ID 或 HTML anchor。
8. 对 `draft`、P0、FORBIDDEN、`risk_tag: high`、行业高风险规则在 AI 使用路径输出 warning。
9. 写入实际产物时**剥离**模板内的解释性内联注释(如 standard-template 规则 YAML 后跟的 `# draft / active / ...` 等枚举说明);保留有意义的业务注释。
10. `ai-rules.md` §2/§3 与 `review-checklist.md` §1/§2 的规则清单是 `standard.md` 的派生视图,每次萃取由本阶段重新生成,**不**接受手工修改回流。
11. 候选 `rules-index` 必须使用 `title`、`domain`、`sub_domain`、`level`、`source_doc`、`section_title`、`evidence_doc`、`tags`，不得包含 `rule_id` 或 `anchor`。
12. `ai-context-pack` 必须引用命中规则的 `{source_doc}「{section_title}」`，并标注来源 batch。

## 禁止做

1. 不得把无证据模板内容写成强制规则。
2. 不得在 AI Rules 里强制执行 `pending-confirmation` / `conflict` / `rejected` / `legacy-compatible` 状态规则。
3. 不得绕过 mapper、公共组件、公共服务等既有团队能力。
4. 不得为规则生成 Rule ID 或 `<a id>` 锚点；不得在规范正文写具体项目路径。
5. 不得把候选索引产物默认发布为正式根 `llms.txt` 或 `.index/rules-index.json`。
