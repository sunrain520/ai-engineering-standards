---
doc_id: "{domain}-{run_id}-project-specific-divergence"
title: "项目特有差异说明：{domain}/{sub_domain | run_id}"
domain: "{domain}"
sub_domain: "{sub_domain | -}"
doc_type: project-specific-divergence
schema_version: project-specific-divergence.v1
version: "v0.1.0"
status: draft
indexable: false
run_id: "{run_id}"
project_count: 0
projects:
  - index: 1
    name: ""
    path: ""
tags: ["{domain}", "cross-project", "divergence"]
---

# 项目特有差异说明

> 本文件由 `cross-project-aggregator` 在多项目运行（`len(project_paths) > 1`）时自动生成，仅记录 **`unified_state == partial_activated`** 的维度。
>
> 用途：让端规范作者在 `merge-coordinator` 写入 `standard-{domain}-{sub_domain}.md §3 子领域差异对比章节` 时，按本文档自动填充「统一要求」列与「各项目当前实现」列；同时为后续是否拉齐团队规范保留人工裁定入口。
>
> **铁律**：本文件**不**重新判定单项目 state；所有维度的单项目 state 来自各自 `activation-report-project-N.json`。

## 1. 多项目概览

| index | 项目名 | scope（脱敏） | 主要 dev_domain | 主要 sub_domain |
| --- | --- | --- | --- | --- |
| 1 | {project-a} | {/path/.../project-a} | {backend} | {java-spring} |
| 2 | {project-b} | {/path/.../project-b} | {backend} | {java-spring} |
| 3 | {project-c} | {/path/.../project-c} | {backend} | {java-job} |

## 2. partial_activated 维度清单

> 仅当 `unified_state == partial_activated` 才进入本节；其它 unified_state（unified_activated / unified_baseline / unified_candidate / unified_pending / unified_shallow）由 merge-coordinator 直接消费 `unified-activation-map.json`，不进入本文件。

### 2.1 维度 {dimension_id}：{dimension_name}

- **layer**：{baseline | end:app-client | end:frontend | end:backend | industry:securities | cross-cutting}
- **sub_domain**：{kmp-shared | android | ios | java-spring | java-job | securities | -}
- **激活项目**：
  - project-1（{project-a}）：state=activated, depth=deep
  - project-3（{project-c}）：state=activated, depth=shallow
- **未激活项目**：
  - project-2（{project-b}）：state=candidate, evidence_count=0
- **代表性 evidence（仅列激活项目，脱敏路径）**：
  - project-1：`{module}/risk/RiskLimitChecker.kt:42`（POS-{DOMAIN}-001）
  - project-3：`{module}/order/OrderRiskGuard.kt:58`（POS-{DOMAIN}-002）
- **差异说明**：
  - {project-2 未实现风控前置校验；其它两项目均已实现并落地代码}
- **差异列填充建议**（供 merge-coordinator 自动填充 §3 子领域差异对比章节）：
  | 列 | 取值建议 |
  | --- | --- |
  | 维度 | {dimension_id} - {dimension_name} |
  | 统一要求 | {必须做风控前置校验：交易类操作必须经过 RiskGuard} |
  | project-a 当前实现 | activated · 已实现（RiskLimitChecker） |
  | project-b 当前实现 | candidate · 未实现，需补齐 |
  | project-c 当前实现 | activated · 已实现（OrderRiskGuard） |
- **是否提升为团队统一要求**：⚠️ 待人工确认
  - 若提升 → 在 standard-{sub_domain}.md §3 该行写 "必须实现"，并在 ai-rules.md 增加规则
  - 若不提升 → 仅作差异记录，不写入 standard 主体；保留至下次跨项目 run 复审

### 2.2 维度 {dimension_id}：{dimension_name}

（按上格式重复每个 partial_activated 维度）

## 3. 横切维度子领域差异汇总（feeds standard-{domain}-{sub_domain}.md §3）

> 本节是 §2 的子领域视角聚合。横切维度（`layer ∈ end:*` 且 `sub_domain` 字段非空）按 sub_domain 切片，给端规范作者一个一眼看见全部子领域差异的视图。

| 维度 | sub_domain | project-a | project-b | project-c | 统一要求建议 |
| --- | --- | --- | --- | --- | --- |
| EA-Client-04 | kmp-shared | activated | candidate | activated | 数据访问统一收敛到 Repository + DataSource 两层 |
| EA-Client-04 | android | activated | activated | candidate | 同上，复用 KMP shared Repository |
| EA-Client-04 | ios | candidate | candidate | candidate | 暂不强制（无项目激活） |
| EA-Backend-06 | java-spring | activated | activated | candidate | 鉴权拦截器必须在 SecurityFilterChain 注册 |
| ... |

## 4. 团队规范裁定（人工填写）

| 维度 | 裁定结果 | 责任人 | 截止日期 | 备注 |
| --- | --- | --- | --- | --- |
| {dimension_id} | 提升为团队统一 / 保留差异 / 暂缓 | {name} | {YYYY-MM-DD} | |

## 5. 元信息与可追溯性

- 上游产物：
  - `evidence/per-project/dimension-activation-report-project-1.json`
  - `evidence/per-project/dimension-activation-report-project-2.json`
  - `evidence/per-project/dimension-activation-report-project-3.json`
- 合并产物：`temp/{run_id}-unified-activation-map.json`
- 合并策略：`{permissive | strict}`（默认 permissive）
- merge_coordinator 消费规则：见 `references/agents/merge-coordinator.md §维度激活态消费契约`
- 后续 run 增量比对：本文件作为 `cross_batch_aggregation.divergence_history` 输入，跨 run 跟踪团队规范拉齐进度
