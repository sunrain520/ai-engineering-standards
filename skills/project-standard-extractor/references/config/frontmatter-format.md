# Front Matter Format

所有由 `project-standard-extractor` 输出的 Markdown 产物，文件顶部必须包含 YAML Front Matter。该头部用于 AI 快速索引、规则过滤和最小上下文加载。

> 与 `docs/02-技术方案/AI快速索引最终方案.md` 对齐：Front Matter 只解决**文档级**识别和过滤；**规则级**过滤由 `rules-index.json` 负责。机器可校验枚举以 `references/config/output-artifact-contract.json` 为准，本文件提供人读语义。规则本身不使用 Rule ID，也不需要 HTML anchor，规则统一由 `source_doc + section_title` 二元组定位。

## 1. 最小格式

```yaml
---
doc_id: "{domain}-{doc_type}"
title: "{文档标题}"
domain: "{domain}"
sub_domain: "{sub_domain 或 common}"
doc_type: "{doc_type}"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
tags:
  - "{domain}"
  - "{sub_domain}"
---
```

## 2. 字段说明

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `doc_id` | 是 | 文档稳定 ID，用于索引和引用；同 domain/sub_domain 内必须唯一 |
| `title` | 是 | 文档标题 |
| `domain` | 是 | 研发域，例如 `app-client`、`frontend`、`backend`、`industry` |
| `sub_domain` | 是 | 子领域；通用文档使用 `common` |
| `doc_type` | 是 | 文档类型，取值见 §3 |
| `version` | 是 | 当前规范仓库里程碑版本 |
| `status` | 是 | 文档状态，取值见 §4.1 |
| `owner` | 是 | 负责人，未知时填 `TBD` |
| `index_format` | 是 | Markdown 索引格式版本，固定 `engineering-standards-md-v1` |
| `indexable` | 是 | 是否进入快速索引；评审报告 / 状态决策 / 临时清单类默认 `false` |
| `tags` | 是 | 用于按任务过滤的标签 |

## 3. doc_type 枚举

```text
overview
standard
ai-rules
review-checklist
evidence-code-facts
evidence-positive
evidence-forbidden
evidence-legacy
pending-confirmation
merge-suggestions
conflicts
project-profile
extraction-map
batch-plan
ai-context-pack
review-report
rule-state-decision
```

`project-profile`、`extraction-map`、`batch-plan` 和 `ai-context-pack` 是运行级 handoff / candidate artifacts，默认 `indexable: false`，避免项目路径和临时候选进入 AI 默认规则加载路径。它们仍必须带 Front Matter，以便按 `doc_id`、`run_id`、`domain` 和 `doc_type` 定位。

## 4. 字段枚举

### 4.1 文档级 `status`（Front Matter）

| 取值 | 含义 |
| --- | --- |
| `draft` | 文档为草稿，内容可能未完整或未审 |
| `active` | 经领域负责人确认，可作为团队级强制依据 |
| `pending` | 文档语义本身就是"待确认清单"（如 `pending-confirmation.md`） |
| `archived` | 已归档，不再作为有效输入 |

### 4.2 规则级 `status`（写在 standard.md 规则元数据 YAML）

| 取值 | 含义 |
| --- | --- |
| `auto-active` | 通过 BR-016/BR-017 高置信自动升级闸，进入 AI 默认执行路径；来源限本仓 evidence |
| `owner-confirmed-active` | 负责人手动确认，进入 AI 默认执行路径 |
| `draft` | 规则进入草案，可作为阅读/输入参考，不进入 AI 默认强制执行 |
| `pending-confirmation` | 等待负责人确认；AI 不得执行 |
| `stale-auto-active` | 曾为 auto-active，但最新复检不再满足闸；已移出 AI 默认执行路径 |
| `owner-rejected` | 负责人否决过的 auto-active；AI 不得执行，下次运行不得自动恢复 |
| `conflict` | 与其它规则或事实冲突；AI 不得执行 |
| `legacy-compatible` | 历史兼容写法；AI 不得复制扩散 |
| `rejected` | 已驳回；AI 不得执行 |

legacy `active` 仅表示历史文档中的人工确认状态，读取时应规范化为 `owner-confirmed-active`；新生成规则不得再写旧 active 状态。

#### 4.2.1 规则级必填字段

规则标题后第一行 inline 元数据必须包含以下字段；字段全集也写入 `output-artifact-contract.json.rule_required_fields`，两处不得漂移：

| 字段 | 含义 |
| --- | --- |
| `level` | P0 / P1 / P2 / FORBIDDEN |
| `status` | §4.2 规则级状态 |
| `source_kind` | §4.4 来源类型 |
| `evidence_tier` | §4.5 evidence 层级 |
| `risk_tag` | §4.6 风险标记 |
| `owner` | 当前负责人，未知填 TBD |
| `last_reviewed` | 最近评审日期 |
| `recommended_action` | §4.7 建议动作 |
| `confidence_tier` | high / normal / low；pending-confirmation batch 默认为 low |
| `authority_scope` | `this-repo` / `cross-project` / `none`；`auto-active` 必填 `this-repo` |
| `upgrade_mode` | `auto-active` / `owner-confirmed` / `none` |
| `deterministic_occurrence_count` | auto-active 闸使用的确定性 occurrence 计数；不得由 LLM 自填猜测 |
| `last_evidence_confirmed_run` | 最近一次 evidence 仍满足当前状态的 run_id |

### 4.3 `level`

```text
P0
P1
P2
FORBIDDEN
```

> 规则正文标题前缀必须使用上述 4 个值之一，详见 §5。

### 4.4 `source_kind`

| 取值 | 含义 |
| --- | --- |
| `extracted` | 由真实代码事实直接提炼 |
| `owner-confirmed` | 由领域负责人书面确认 |
| `industry-reference` | 来自行业规范 / 标准引用 |
| `template-placeholder` | 仅模板占位，不得作为强制规则 |

### 4.5 `evidence_tier`

| 取值 | 含义 |
| --- | --- |
| `direct-code` | 直接来源于代码事实 |
| `cross-project` | 多个真实项目共同体现 |
| `single-project` | 单一项目的事实 |
| `inferred` | 间接推导 |
| `none` | 无 evidence；AI 不得执行 |

### 4.6 `risk_tag`

```text
high
medium
low
none
```

> `high` / `FORBIDDEN` 必须在 AI 使用路径输出 warning，并出现在 `review-checklist.md` 强制段。

### 4.7 `recommended_action`

| 取值 | 含义 |
| --- | --- |
| `keep-draft` | 维持 draft，等待更多 evidence |
| `keep-draft-low-coverage` | 维持 draft，但标记低覆盖率，等待补充 evidence |
| `auto-activate` | 通过高置信闸，自动标记为 auto-active |
| `move-to-pending` | 移入待确认 |
| `mark-conflict` | 标记为冲突 |
| `mark-legacy` | 标记为历史兼容 |
| `mark-stale-auto-active` | 标记 auto-active 复检失效并移出默认执行路径 |
| `mark-owner-rejected` | 标记 owner 否决并移出默认执行路径 |
| `reject` | 驳回 |
| `defer` | 延期处理 |

## 5. 规则标题约定

**不使用 Rule ID，不使用 HTML anchor**。规则正文标题统一为：

```markdown
## P0 {规则标题}
## P1 {规则标题}
## P2 {规则标题}
## FORBIDDEN {规则标题}
```

要求：

1. 标题前缀必须严格匹配 `^(P0|P1|P2|FORBIDDEN) ` 之一（前缀与标题之间一个半角空格）。
2. 同一 `source_doc` 内 `section_title` 必须唯一，方便 `rules-index.json` 用 `(source_doc, section_title)` 二元组定位。
3. `rules-index.json` 中的 `section_title` 必须与规范正文 H2 字面一致，避免 AI 引用时出现同义改写。
4. 规则被 review / merge / conflict / decision 文档引用时，统一格式为：

   ```text
   {source_doc}「{section_title}」
   ```

## 6. 辅助条目编号

下列文件中的**条目级**编号（不是规则级）允许保留，仅用于跨文件回引：

| 文件 | 条目编号格式 |
| --- | --- |
| `evidence/code-facts.md` | `EV-{DOMAIN}-{NUMBER}` |
| `evidence/positive-examples.md` | `POS-{DOMAIN}-{NUMBER}` |
| `evidence/forbidden-examples.md` | `NEG-{DOMAIN}-{NUMBER}` |
| `evidence/legacy-compatible.md` | `LEG-{DOMAIN}-{NUMBER}` |
| `pending-confirmation.md` | `PENDING-{DOMAIN}-{NUMBER}` |
| `merge-suggestions.md` | `MERGE-{DOMAIN}-{NUMBER}` |
| `conflicts.md` | `CONFLICT-{DOMAIN}-{NUMBER}` |

`{NUMBER}` 在所属文件内单调递增，不复用，不重排。

## 7. 非 Markdown 候选产物

`rules-index-template.json` 和 `llms-template.txt` 不是 Markdown，不使用 YAML Front Matter。它们的输出位置、候选状态和人工合并边界由 `references/config/output-targets.md` 约束。
