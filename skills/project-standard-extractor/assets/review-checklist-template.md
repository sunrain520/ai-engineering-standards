---
doc_id: "{domain}-{sub_domain}-review-checklist"
title: "{Domain} Code Review Checklist"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "review-checklist"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
tags:
  - "{domain}"
  - "{sub_domain}"
  - "review-checklist"
---

# {Domain} Code Review Checklist

> 检查项与 `standard.md` 规则一一对应。引用规则统一为 `{source_doc}「{section_title}」`，**不使用 Rule ID**。
>
> **Single source 约定**: §1 / §2 的规则聚合清单是 `standard.md` 的派生视图,由 generation 阶段从 `standard.md` 「Code Review 检查项」段同步生成。手工增删会被下次萃取覆盖;要修改规则级检查请改 `standard.md`,要修改通用流程检查请改本文件 §3-§7。

## 1. P0 / FORBIDDEN 强制段（必查）

每条 `level: P0` 或 `level: FORBIDDEN` 的规则在此聚合一项检查；缺一项即视为 review fail。

### P0

- [ ] `{source_doc}「P0 {规则标题}」`
  - 检查点：
  - 触发反例：`evidence/forbidden-examples.md「NEG-{DOMAIN}-{NUMBER}」`

### FORBIDDEN

- [ ] `{source_doc}「FORBIDDEN {规则标题}」`
  - 检查点：
  - 触发反例：`evidence/forbidden-examples.md「NEG-{DOMAIN}-{NUMBER}」`

## 2. P1 / P2 推荐段（按需）

### P1

- [ ] `{source_doc}「P1 {规则标题}」`
  - 检查点：

### P2

- [ ] `{source_doc}「P2 {规则标题}」`
  - 检查点：

## 3. 架构合规

- [ ] 是否遵守本研发域分层？
- [ ] 是否复用已有能力？
- [ ] 是否没有重复实现核心业务规则？

## 4. 规则状态合规

- [ ] 是否只按 `status: active` 或 evidence-backed `status: draft` 检查？
- [ ] 是否没有把 `pending-confirmation` 当作强制规则执行？
- [ ] 是否没有扩散 `legacy-compatible` 历史写法到新代码？
- [ ] 是否没有引用 `conflict` / `rejected` 规则？

## 5. AI 生成质量

- [ ] 是否引用了适用规则的 `{source_doc}「{section_title}」` 二元组？
- [ ] 是否输出 draft / `risk_tag: high` warning？
- [ ] 是否完成 `ai-rules.md §6` 自检？

## 6. Evidence

- [ ] P0 / FORBIDDEN 是否都有真实 evidence（`evidence_tier ≠ none`）？
- [ ] 规则正文是否没有具体项目路径与单项目命名？
- [ ] evidence 是否无敏感信息原值？

## 7. 子领域 / 业务模块差异检查

按子领域追加额外检查项：

### {sub_domain_a}

- [ ] {差异检查项}

### {business_module_a}

- [ ] {差异检查项}
