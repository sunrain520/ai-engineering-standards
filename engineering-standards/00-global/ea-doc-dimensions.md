---
doc_id: global-ea-doc-dimensions
domain: 00-global
status: draft
last_updated: 2026-05-25
owner: leokuang
generated_by: phase-2-extractor
---

# EA-Doc 维度组全局说明

## 1. 什么是 EA-Doc 维度组

EA-Doc（Engineering Artifact – Document）维度组是 Phase 2 新增的**文档源萃取能力**，从项目内已有的代码文档萃取业务知识、领域模型、开发规范和 API 契约。

| 维度 ID | 内容 | 主要信号 |
| --- | --- | --- |
| EA-Doc-Glossary | 业务术语表 / Ubiquitous Language | `docs/glossary*.md` / heading"术语表"/"glossary" |
| EA-Doc-DomainModel | 领域模型 / 实体关系 / Bounded Context | `docs/domain-model*.md` / `docs/architecture*.md` |
| EA-Doc-Standard | 团队开发规范 / Convention / Style Guide | `CONTRIBUTING.md` / `STYLE.md` / `docs/conventions*` |
| EA-Doc-API | API 契约 / OpenAPI / Swagger / GraphQL Schema | `openapi*.yaml` / `swagger*.yaml` / `*.graphql` |
| EA-Doc-Decision | ADR / RFC / 设计决策 | `docs/adr/*.md` / `docs/decisions/*.md` / `docs/rfc/*.md` |

EA-Doc 与代码维度**并行参与** dimension-activator 判定，不替代代码 evidence，二者互补。

## 2. 触发方式

### 2.1 代码库内文档（自动触发）

无需额外配置——只要 `project_paths` 内存在上述信号文件，doc-source-scanner agent 自动扫描并产出 `evidence/knowledge/doc-inventory.json`。

### 2.2 Wiki/Confluence 离线注入流程

当团队有 Wiki 或 Confluence 文档，通过以下步骤注入：

**Step 1 — 导出**

从 Wiki/Confluence 后台导出目标空间为 markdown 包（保留每页 frontmatter）：

```yaml
# 每个导出文件的 frontmatter 格式（Wiki 导出时自动生成，可手工补全）
---
source: wiki-export       # 或 confluence-export
original_url: "https://wiki.example.com/pages/12345"
space: "eng-knowledge"
page_title: "业务术语表"
exported_at: "2026-05-25T10:00:00Z"
---
```

**Step 2 — 放置目录**

建议放到项目根下的隔离目录，不要混入源码：

```
<project_root>/.local-docs/
└── wiki-export-20260525/
    ├── glossary.md
    ├── domain-model.md
    ├── adr/
    │   ├── 0001-use-kmp.md
    │   └── 0002-chose-kafka.md
    └── team-conventions.md
```

> **注意**：`.local-docs/` 建议加入 `.gitignore`（Wiki 导出可能含较大二进制或内部信息）。

**Step 3 — 传入 doc_paths**

调用 skill 时通过 `doc_paths[]` 字段指定：

```yaml
project_paths:
  - /local/my-project
doc_paths:
  - /local/my-project/.local-docs/wiki-export-20260525
extraction_mode: full
domain: 01-app-client
```

**Step 4 — 萃取结果**

doc-source-scanner 扫描 `doc_paths` 与 `project_paths/docs/` 并集：

- 产出 `evidence/knowledge/doc-inventory.json`
- 导出文件 frontmatter `source: wiki-export` 触发对应维度信号权重加成
- 最终注入产物：`evidence/knowledge/wiki-snapshot-YYYYMMDD.md`（留痕）

## 3. 产物结构

```
engineering-standards/<domain>/
├── standard.md           # EA-Doc 维度章节追加到主规范末尾
└── evidence/
    └── knowledge/        # EA-Doc 独立副产物目录
        ├── doc-inventory.json       # 文档源索引（schema: doc-inventory.v1）
        ├── glossary.md              # 业务术语表（从 docs/glossary 提炼）
        ├── domain-model.md          # 领域模型摘要（实体 + BC）
        ├── decisions-summary.md     # ADR/RFC 决策摘要（不重写原文）
        ├── api-contract.md          # API 端点清单（从 OpenAPI 提炼）
        └── wiki-snapshot-YYYYMMDD.md  # Wiki 离线注入留痕（如有）
```

## 4. 敏感文档处理

继承 intake-and-scope Step 5 `sensitive_file_policy`：

- 路径含 `secrets/` / `credentials/` / `.env` → 不读取内容，只记录路径类别
- heading 内出现疑似密钥段（长度 > 20 字符 + 大写字母 + 数字混合）→ 跳过该 heading，写 `{redacted: true}`
- Wiki/Confluence 导出文件中含 API Token / 密码的段落 → 不读取，只记录文件元数据

## 5. 三态激活边界

| 维度 | 默认态 | 升级为 activated 的条件 |
| --- | --- | --- |
| EA-Doc-Glossary | candidate | `docs/glossary.md` 存在 + ≥ 5 条术语，或 Wiki 导出含术语表 |
| EA-Doc-DomainModel | candidate | `docs/domain-model.md` 或 `docs/architecture.md` 存在 |
| EA-Doc-Standard | candidate | `CONTRIBUTING.md` 或 `docs/conventions*.md` 存在 |
| EA-Doc-API | candidate | `openapi.yaml` / `swagger.yaml` / `*.graphql` 存在 |
| EA-Doc-Decision | **baseline**（高风险兜底） | `docs/adr/*.md` 存在 + ≥ 1 条 ADR |

EA-Doc-Decision 使用 `high_risk_fallback: baseline`——即使无 ADR 文件，也会在规范中保留"应有 ADR"的入口章节。

## 6. 与代码维度的协同

EA-Doc 维度的规则**不与代码维度规则重叠**：

- EA-Doc-API activated + EA-Backend-02（API 契约代码维度）activated：
  → EA-Doc-API 章节记录已有文档化端点清单；EA-Backend-02 章节约束代码层 API 设计规范
  → 二者通过 `cross_dimensions` 互引，在 `merge-suggestions.md` 中说明关联关系

- 所有 EA-Doc 规则是**advisory hint**（因 evidence_tier 源自文档，不如代码 evidence 确定性强）
- 领域负责人确认后，EA-Doc 规则可升级为代码维度规则的输入来源（不自动升级）

## 7. 相关文档

| 想知道 | 看这里 |
| --- | --- |
| EA-Doc 维度池定义 | `skills/project-standard-extractor/config/dimension-framework/dimensions-doc.yaml` |
| EA-Doc 激活规则 | `skills/project-standard-extractor/config/dimension-framework/activation-rules-doc.yaml` |
| doc-content 信号库 | `skills/project-standard-extractor/prompts/signal-library/doc-content-signals.md` |
| doc-source-scanner agent | `skills/project-standard-extractor/agents/doc-source-scanner.md` |
| 骨架模板 | `skills/project-standard-extractor/templates/skeletons/doc/` |
| EA-Doc evals | `skills/project-standard-extractor/evals/dimension-framework/doc-source-cases.md` |
| 使用 walkthrough | `skills/project-standard-extractor/examples/phase-2/doc-source-walkthrough.md` |
