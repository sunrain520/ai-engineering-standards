---
doc_id: "{domain}-{sub_domain}-ai-rules"
title: "{Domain} AI Coding Rules"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "ai-rules"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
tags:
  - "{domain}"
  - "{sub_domain}"
  - "ai-rules"
  - "ai-coding"
---

# {Domain} AI Coding Rules

> 本文件配合 `standard.md` 使用。规则不使用 Rule ID，外部引用统一为 `{source_doc}「{section_title}」`。
>
> **Single source 约定**: §2 / §3 的规则清单是 `standard.md` 的派生视图,由 generation 阶段从 `standard.md` 同步生成。手工修改本文件清单会被下次萃取覆盖;要修改规则正文请改 `standard.md`,要修改 AI 执行边界请改本文件 §1 / §4-§7。

## 1. 规则使用边界

AI 默认必须执行：

- 规则元数据 `status` 为 `auto-active` 或 `owner-confirmed-active`。
- `auto-active` 规则必须带 `authority_scope: this-repo`、`upgrade_mode: auto-active`、`deterministic_occurrence_count >= 2` 和 lineage 闸判据快照。

AI 默认可参考但不强制：

- `status: draft` 且 `source_kind ∈ {extracted, owner-confirmed}`、`evidence_tier ≠ none` 的规则。

AI 不得执行（即使在 standard.md 中出现）：

- `status` 为 `pending-confirmation` / `stale-auto-active` / `owner-rejected` / `conflict` / `legacy-compatible` / `rejected`。
- `source_kind` 为 `template-placeholder`。
- `evidence_tier` 为 `none`。
- 命中 `references/config/anti-pattern-blocklist.yaml` 或高风险域但未 owner 确认的规则。

## 2. 必须执行规则清单

按规则定位填入；若该规则在 `standard.md` 中已存在,则只在此重复 H2 标题与定位串便于 AI 检索。

### P0

- `{source_doc}「P0 {规则标题}」`
  - 关键约束：
  - AI 自检必查项：

### FORBIDDEN

- `{source_doc}「FORBIDDEN {规则标题}」`
  - 关键约束：
  - AI 自检必查项：

## 3. 默认参考规则清单

### P1

- `{source_doc}「P1 {规则标题}」`

### P2

- `{source_doc}「P2 {规则标题}」`

## 4. 生成前必须检查

1. 当前需求属于哪个研发域 / 子领域 / 业务模块？
2. 是否已有 `auto-active` / `owner-confirmed-active` 规则？
3. 是否有待合并 (`merge-suggestions.md`) 或冲突 (`conflicts.md`) 规则？
4. 是否涉及 `risk_tag: high` 模块？
5. 是否需要补充 evidence？

## 5. 生成时必须遵守

1. 引用规则统一使用 `{source_doc}「{section_title}」` 二元组。
2. 复用已有模块、组件、服务和数据访问入口。
3. 不把 DTO / Entity / 底层 API 暴露到不该暴露的层。
4. 不把单项目路径或单项目命名当成团队标准。

## 6. 生成后自检

```markdown
- 适用规则（二元组列表）：
- 命中规则的 evidence_tier：
- 是否包含 draft / high-risk warning：
- 是否存在 pending / stale-auto-active / owner-rejected / conflict / legacy 规则需要规避：
- 是否需要负责人确认：
```

## 7. Fail-safe

AI 在以下情况必须**停下并向用户/负责人请求确认**，不得擅自生成代码：

1. 命中规则中存在 `status: conflict` 或 `status: pending-confirmation`。
2. 命中规则的 `evidence_tier` 为 `none` 或 `inferred`，且 `level` 为 `P0` / `FORBIDDEN`。
3. 需求涉及 `risk_tag: high` 但未命中任何 evidence-backed 规则。
4. 出现两条或以上规则在 `conflicts_with` 字段相互引用。
