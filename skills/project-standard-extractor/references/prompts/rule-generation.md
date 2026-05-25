# Rule Generation Prompt

你是团队规范生成角色。

请基于 `code-facts` 和 `classification` 综合编写**开发者工作手册**风格的团队规范，写入 `standard-{sub_domain}.md`。**不是规则注册表**：每个规则节由可读 prose + numbered list + 代码示例组成，元数据用 inline 行表达，不写整块 yaml。

## 规则定位

- **不使用 Rule ID，不使用 HTML anchor**。
- 规则 H2 标题必须以 `P0` / `P1` / `P2` / `FORBIDDEN ` 之一为前缀，与正文一一对应。
- 跨文档引用规则统一使用 `{source_doc}「{section_title}」` 二元组。

## 每条规则必须包含

1. H2 标题（`## P0|P1|P2|FORBIDDEN {规则标题}`）。
2. **inline 元数据行**（紧跟 H2，blockquote 单行，使用 ` · ` 分隔）：

   ```markdown
   > level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-22 · recommended_action: keep-draft
   ```

   字段全集（顺序固定）：
   - `level`（P0 / P1 / P2 / FORBIDDEN）
   - `status`（取值见 `references/config/frontmatter-format.md §4.2`，自动运行默认 `draft`，**不得**默认 `active`）
   - `source_kind`（extracted / owner-confirmed / industry-reference / template-placeholder）
   - `evidence_tier`（direct-code / cross-project / single-project / inferred / none）
   - `risk_tag`（high / medium / low / none）
   - `owner`、`last_reviewed`
   - `recommended_action`（取值见 §4.7）
   - `conflicts_with: ["..."]`、`superseded_by: ...`（仅在非空时追加，元素之间用逗号；空值整字段省略）

   不允许把 inline 行改成多行 yaml 块。grep 用 `^> level: ` 即可定位每条规则。

3. `### 适用范围`（说明在哪类文件、哪种场景下生效）。
4. `### 强制规则` 或 `### 推荐规则`（**numbered list**，每条说明**怎么做**，不只是"应该"）。
5. `### 禁止事项`（**bullet list**；FORBIDDEN 条目用 `> ⛔ FORBIDDEN：...` 格式并引用 NEG- evidence）。
6. `### 正例` / `### 反例`（fenced code block，路径脱敏，注释说明正确/错误原因）。FORBIDDEN 与 P0 必须有反例；P1/P2 至少正例。
7. `### AI 生成代码要求`（正向约束句式，"必须 / 禁止 / 应在 ..."）。
8. `### Code Review 检查项`（reviewer 看代码即可二值判断 pass/fail）。
9. `### Evidence`（列出 `evidence/{kind}.md「{条目编号}」`）。

## 文档级章节顺序

- `# {Sub-domain} 开发规范`
- `## 1. 技术栈与工程约束`
- `## 2. 分层职责`（ASCII 依赖图 + 责任矩阵表格）
- `## 3—N. {角色/层级} 规范` 每节包含若干规则节（按上面 9 项结构写）
- `## {N+1}. 目录与命名规范`（仅在 evidence 中有命名模式时写）
- `## {N+2}. AI 生成规则`（汇总段，从各规则节的 `AI 生成代码要求` 提取，不新创内容）
- `## {N+3}. Code Review 检查项`（汇总段，从各规则节的 `Code Review 检查项` 提取）
- `## Evidence 参考`（表格，列出本文档主要规则依据的 evidence 编号）

## 禁止

- 不得为每条规则写整块 yaml 元数据块（catalog 风格）。元数据只能用 inline blockquote 行。
- 不得把项目路径写进规则正文。
- 不得把无证据内容写成 AI 可执行 draft。
- 不得自动发布 active。
- 不得为规则生成 Rule ID 或 HTML anchor。
- 不得在规则节同时写"AI 生成代码要求"小节和文档末尾另一份 AI 规则汇总段重复内容；汇总段只摘要、不重写。
