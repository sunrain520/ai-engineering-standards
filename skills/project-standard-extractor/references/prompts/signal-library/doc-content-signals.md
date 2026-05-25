---
name: doc-content-signals
description: EA-Doc 维度组 doc-content 信号库——文件名 glob / heading regex / top-level field 三类匹配，与代码信号并行输入 dimension-activator
type: signal-library
signal_type: doc-content
version: "1.0.0"
---

# Doc-Content Signal Library

本文件定义 `type: doc-content` 信号集，供 dimension-activator 在扫描文档源时使用。
与代码信号（`type: ast` / `type: filename` / `type: keyword`）**并列**，不替代。

## 信号类型说明

| 信号类型 | 匹配目标 | 示例 |
| --- | --- | --- |
| `filename_glob` | 文档文件路径 glob | `**/glossary*.md` |
| `heading_regex` | 文档 H1/H2/H3 heading 内容 | `^# ADR-\d+` |
| `top_level_field_regex` | YAML/JSON 文档顶级字段 | `^openapi:` |
| `frontmatter_field` | markdown frontmatter 特定字段 | `source: wiki-export` |

## 信号集

```yaml
# ── EA-Doc-Glossary ──────────────────────────────────────────────────────────

- id: SIG-DOC-GLOSSARY-001
  type: doc-content
  description: 术语表 markdown 文件
  match:
    filename_glob:
      - "**/glossary*.md"
      - "**/terms*.md"
      - "**/ubiquitous-language*.md"
      - "**/业务术语*.md"
  activates: [EA-Doc-Glossary]
  weight: 2

- id: SIG-DOC-GLOSSARY-002
  type: doc-content
  description: 文档含"术语表"/ "glossary" 一级标题
  match:
    heading_regex:
      - "^#\\s*(术语表|Glossary|Ubiquitous Language|Business Terms|业务词汇)"
  activates: [EA-Doc-Glossary]
  weight: 1

- id: SIG-DOC-GLOSSARY-003
  type: doc-content
  description: Wiki/Confluence 导出含 glossary 文件
  match:
    source: ["wiki-export", "confluence-export"]
    filename_glob: ["**/glossary*.md", "**/术语*.md"]
  activates: [EA-Doc-Glossary]
  weight: 2

# ── EA-Doc-DomainModel ───────────────────────────────────────────────────────

- id: SIG-DOC-DOMAIN-001
  type: doc-content
  description: 领域模型 markdown 文件
  match:
    filename_glob:
      - "**/domain-model*.md"
      - "**/ddd*.md"
      - "**/bounded-context*.md"
  activates: [EA-Doc-DomainModel]
  weight: 2

- id: SIG-DOC-DOMAIN-002
  type: doc-content
  description: 架构文档（可能含领域模型）
  match:
    filename_glob:
      - "**/architecture*.md"
      - "**/arch*.md"
      - "**/system-design*.md"
  activates: [EA-Doc-DomainModel]
  weight: 1

- id: SIG-DOC-DOMAIN-003
  type: doc-content
  description: 文档含"领域模型"/ "Bounded Context" 一级标题
  match:
    heading_regex:
      - "^#\\s*(领域模型|Bounded Context|Domain Model|上下文映射|Context Map|聚合根)"
  activates: [EA-Doc-DomainModel]
  weight: 1

# ── EA-Doc-Standard ──────────────────────────────────────────────────────────

- id: SIG-DOC-STD-001
  type: doc-content
  description: CONTRIBUTING.md 贡献指南
  match:
    filename_glob:
      - "**/CONTRIBUTING.md"
      - "**/CONTRIBUTING.rst"
  activates: [EA-Doc-Standard]
  weight: 2

- id: SIG-DOC-STD-002
  type: doc-content
  description: Style Guide / 编码规范文件
  match:
    filename_glob:
      - "**/STYLE.md"
      - "**/STYLE_GUIDE.md"
      - "**/style-guide.md"
      - "**/coding-standards.md"
      - "**/code-style.md"
  activates: [EA-Doc-Standard]
  weight: 2

- id: SIG-DOC-STD-003
  type: doc-content
  description: docs/ 下的 standard / conventions / guidelines 目录文件
  match:
    filename_glob:
      - "**/docs/standard*.md"
      - "**/docs/conventions*.md"
      - "**/docs/guidelines*.md"
      - "**/docs/development*.md"
      - "**/docs/dev-process*.md"
  activates: [EA-Doc-Standard]
  weight: 1

# ── EA-Doc-API ───────────────────────────────────────────────────────────────

- id: SIG-DOC-API-001
  type: doc-content
  description: OpenAPI yaml/json 文件
  match:
    filename_glob:
      - "**/openapi*.yaml"
      - "**/openapi*.json"
      - "**/openapi.yml"
  activates: [EA-Doc-API]
  weight: 2

- id: SIG-DOC-API-002
  type: doc-content
  description: Swagger yaml/json 文件
  match:
    filename_glob:
      - "**/swagger*.yaml"
      - "**/swagger*.json"
      - "**/swagger.yml"
  activates: [EA-Doc-API]
  weight: 2

- id: SIG-DOC-API-003
  type: doc-content
  description: GraphQL schema 文件
  match:
    filename_glob:
      - "**/*.graphql"
      - "**/schema.graphql"
      - "**/graphql/schema.graphql"
  activates: [EA-Doc-API]
  weight: 2

- id: SIG-DOC-API-004
  type: doc-content
  description: YAML/JSON 文件顶级含 openapi/swagger/paths 字段
  match:
    top_level_field_regex:
      - "^openapi:"
      - "^swagger:"
      - "^paths:"
  activates: [EA-Doc-API]
  weight: 1

# ── EA-Doc-Decision ──────────────────────────────────────────────────────────

- id: SIG-DOC-ADR-001
  type: doc-content
  description: docs/adr/ 或 docs/decisions/ 目录含 ADR 文件
  match:
    filename_glob:
      - "**/docs/adr/*.md"
      - "**/docs/decisions/*.md"
      - "**/.adr/*.md"
      - "**/adr/*.md"
  activates: [EA-Doc-Decision]
  weight: 2

- id: SIG-DOC-ADR-002
  type: doc-content
  description: docs/rfc/ 目录含 RFC 文件
  match:
    filename_glob:
      - "**/docs/rfc/*.md"
      - "**/rfc/*.md"
  activates: [EA-Doc-Decision]
  weight: 2

- id: SIG-DOC-ADR-003
  type: doc-content
  description: 文档 H1 heading 含 ADR / RFC / Decision 前缀
  match:
    heading_regex:
      - "^# (ADR|RFC|Decision|DECISION)-\\d+"
      - "^# (决策|架构决策|技术决策)-\\d+"
  activates: [EA-Doc-Decision]
  weight: 1
```

## 注意事项

1. **不读取敏感文档内容**：继承 intake-and-scope Step 5 `sensitive_file_policy`；
   路径含 `secrets/` / `credentials/` / `.env` 的文件只记录路径类别，不读取内容。
2. **doc-content 信号仅补充 evidence**，不替代代码扫描信号；维度激活态以二者合并后的 weight 合计为准。
3. **Wiki/Confluence 离线注入**：用户通过 `doc_paths[]` 传入导出目录；
   导出文件 frontmatter 含 `source: wiki-export` 时触发 `SIG-DOC-*-003` 系列信号。
