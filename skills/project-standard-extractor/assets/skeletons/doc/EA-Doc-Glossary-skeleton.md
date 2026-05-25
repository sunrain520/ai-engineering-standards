---
doc_id: "{{domain}}-ea-doc-glossary"
dimension_id: EA-Doc-Glossary
status: "{{status}}"
evidence_tier: "{{evidence_tier}}"
domain: "{{domain}}"
generated_by: phase-2-extractor
---

# §EA-Doc-Glossary 业务术语表 [{{activation_state}}]

> ```yaml
> dimension_id: EA-Doc-Glossary
> activation_state: {{activation_state}}
> layer: doc
> evidence_count: {{evidence_count}}
> depth_score: {{depth_score}}
> signal_hits: {{signal_hits}}
> ```

## 背景

统一的业务术语是跨团队协作的基础。本节记录项目中核心业务术语，供 AI 编码、代码 Review 和技术文档写作时参考。

## 术语表（从 `evidence/knowledge/glossary.md` 提炼）

| 术语 | 定义 | 来源 |
| --- | --- | --- |
| {{term_1}} | {{definition_1}} | {{source_1}} |
| （更多术语见 `evidence/knowledge/glossary.md`） | | |

## 命名一致性规则

- AI 生成代码时，类名 / 方法名 / API 参数名 **应采用本术语表中的术语**，不得使用同义替换词。
- Pull Request 中新增的业务标识符，Reviewer 应核查是否与术语表一致。
- 发现术语表缺失项时，在 PR 中同步更新 `docs/glossary.md`。

## 升级条件（当前 state 为 {{activation_state}}）

{{#if (eq activation_state "candidate")}}
- 提供 `docs/glossary.md` 或等价文件，且含 ≥ 5 条业务术语
- 或通过 `doc_paths[]` 注入 Wiki/Confluence 导出含术语表文件
{{/if}}
{{#if (eq activation_state "baseline")}}
- 补充代码中实际使用的核心实体名称对照（ClassName ↔ 术语）
- 术语表术语数 ≥ 5 且与 evidence/knowledge/glossary.md 一致
{{/if}}
