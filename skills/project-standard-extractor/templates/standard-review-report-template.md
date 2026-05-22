---
doc_id: "{domain}-{run_id}-review-report"
title: "规范萃取评审报告"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "review-report"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
tags:
  - "{domain}"
  - "{sub_domain}"
  - "review-report"
---

# 规范萃取评审报告

## 1. 本次运行

- run_id：{run_id 由 Skill 在阶段 1 生成，格式 `YYYYMMDD-HHMMSS-{domain}` }
- 输入项目：
- 输出研发域：
- 子领域：
- 运行日期：

## 2. 输出文件清单

新建 / 追加文件：

- [ ] `standard.md`
- [ ] `temp/{run_id}-project-profile.md`
- [ ] `temp/{run_id}-extraction-map.md`
- [ ] `temp/{run_id}-batch-plan.md`
- [ ] `ai-rules.md`
- [ ] `review-checklist.md`
- [ ] `overview.md`
- [ ] `evidence/code-facts.md`
- [ ] `evidence/positive-examples.md`
- [ ] `evidence/forbidden-examples.md`
- [ ] `evidence/legacy-compatible.md`
- [ ] `pending-confirmation.md`
- [ ] `merge-suggestions.md`
- [ ] `conflicts.md`
- [ ] `temp/{run_id}-rules-index-candidate.json`
- [ ] `temp/{run_id}-llms-candidate.txt`
- [ ] `temp/{run_id}-ai-context-pack.md`

## 3. 规则评审

引用规则使用 `{source_doc}「{section_title}」` 二元组。

| source_doc | section_title | level | 状态建议 | evidence_tier | 主要问题 | recommended_action |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |

## 4. 分面结论

每个分面必须给出 `verdict / findings / suggestions` 三段。`verdict` 取值：`pass` / `fail` / `blocked`。

### 4.1 Evidence Auditor

- verdict:
- findings:
- suggestions:

### 4.2 Team Standard Reviewer

- verdict:
- findings:
- suggestions:

### 4.3 AI Executability Reviewer

- verdict:
- findings:
- suggestions:

### 4.4 Review Checklist Reviewer

- verdict:
- findings:
- suggestions:

### 4.5 Conflict Reviewer

- verdict:
- findings:
- suggestions:

### 4.6 Industry Risk Reviewer

- verdict:
- findings:
- suggestions:

### 4.7 Context Governance Reviewer

- verdict:
- findings:
- suggestions:

## 5. Quality Gate 决策

- quality_gate_decision: `pass` / `fail` / `block-on-confirmation`
- 整体 recommended_action:
- 阻塞原因（如适用）:

## 6. 人工确认项

- 端负责人：
- 架构负责人：
- 安全 / 合规 / 行业负责人：

## 7. 不得执行项

列出 `pending-confirmation`、`conflict`、`rejected` 规则（用 `{source_doc}「{section_title}」` 引用）。
