---
doc_id: "app-client-20260522-100947-app-client-review-summary"
title: "project-standard-extractor Review Summary：kaz-mvp"
domain: "app-client"
sub_domain: "common"
doc_type: "review-report"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "review-summary"
  - "project-standard-extractor"
---

# project-standard-extractor Review Summary：kaz-mvp

## 1. 本次运行

- run_id: `20260522-100947-app-client`
- project_paths:
  - `/Users/kuang/xiaobu/kaz-mvp`
- output_dir: `engineering-standards/01-app-client/`
- domain: `app-client`
- run_mode: `auto`
- 完成时间：`2026-05-22 13:11:31`

## 2. Batch 执行状态

| batch_id | sub_domain | 状态 | 产物 |
| --- | --- | --- | --- |
| `app-client-module-boundary-contract-layer` | `module-boundary` | completed | `standard-module-boundary.md`，2 条 active 规则 |
| `app-client-android-app-shell-bootstrap` | `android` | completed | `standard-android.md「P1 App 壳初始化必须区分宿主进程与子进程」` |
| `app-client-android-core-ui-state` | `android` | completed | `standard-android.md「P1 页面基类选择必须匹配页面状态复杂度」`，`PENDING-APP-2` |
| `app-client-android-trade-route-provider` | `android` | completed | `standard-android.md「P2 交易共享能力应收敛到 trade-core 等 feature-core 模块」`，`LEG-APP-2` |
| `app-client-android-trade-account-page-composition` | `android` | completed | `standard-android.md「P2 账户容器页应只编排页面结构和导航消费」`，`PENDING-APP-3` |
| `app-client-kmp-shared-trade-order-clean-architecture` | `kmp-shared` | completed | `standard-kmp-shared.md`，3 条 draft 规则 |
| `app-client-kmp-shared-trade-account-assets` | skipped | insufficient evidence | 原 batch 仅有 memory 摘要和单一 Presenter 候选，未覆盖 UseCase / Repository / Model / Mapper |
| `app-client-build-governance-gradle-versioning` | `build-governance` | completed | `standard-build-governance.md`，2 条 draft 规则 |
| `app-client-ui-component-hscomponents-consumption` | `ui-component` | pending-confirmation | batch-plan 已标记缺少具体组件源码候选 |
| `app-client-industry-trading-order-account-risk` | `industry-trading` | pending-confirmation | 行业交易规则缺少负责人确认 |

## 3. 新增或更新文件

- `standard-android.md`
- `standard-kmp-shared.md`
- `standard-build-governance.md`
- `standard-module-boundary.md`
- `ai-rules.md`
- `review-checklist.md`
- `pending-confirmation.md`
- `evidence/code-facts.md`
- `evidence/positive-examples.md`
- `evidence/legacy-compatible.md`
- `20260522-100947-app-client-rules-index-candidate.json`
- `20260522-100947-app-client-llms-candidate.txt`
- `20260522-100947-app-client-ai-context-pack.md`
- `20260522-100947-app-client-review-summary.md`

## 4. 规则状态

| 状态 | 数量 | 说明 |
| --- | ---: | --- |
| active | 2 | 既有 module-boundary 规则，已按仓库历史由 APP 架构负责人确认 |
| draft | 9 | 本轮新萃取的 Android、KMP Shared、Build Governance 规则 |
| pending-confirmation | 2 | `PENDING-APP-2`、`PENDING-APP-3` |
| legacy-compatible | 3 | `LEG-APP-1`、`LEG-APP-2`、`LEG-APP-3` |
| conflict | 0 | 未发现与现有 active 规则冲突 |

## 5. 需要用户审查

- 是否认可 `standard-android.md` 的 4 条 draft 规则。
- 是否认可 `standard-kmp-shared.md` 的 3 条 draft 规则。
- 是否认可 `standard-build-governance.md` 的 2 条 draft 规则。
- 是否将 `PENDING-APP-2` 升级为规则，或继续保留为历史兼容。
- 是否将 `PENDING-APP-3` 升级为规则，或继续保留为历史兼容。
- 是否补充 `app-client-kmp-shared-trade-account-assets` 的 UseCase / Repository / Mapper / Model 候选文件后重新萃取。

## 6. 敏感信息处理

- 未读取 `gradle.properties`、`local.properties`、`hsconfig/` 原值。
- 构建仓库凭据只记录为 credential fields / placeholder，不复制用户名、密码、token 或签名信息。
- 账户页 evidence 只记录结构与职责，不复制账户数据或订单数据。

## 7. Quality Gate 摘要

- Evidence Auditor: pass，所有新 draft 规则均引用 `EV-APP-*` evidence；无 evidence 的候选进入 pending。
- Team Standard Reviewer: warn，新规则来自单项目 evidence，适合 draft，暂不建议自动 active。
- AI Executability Reviewer: pass，AI rules 明确区分 active 与 draft。
- Review Checklist Reviewer: pass，新增 draft 规则均派生检查项。
- Conflict Reviewer: pass，未发现与 `standard-module-boundary.md` active 规则冲突。
- Industry Risk Reviewer: pass，行业交易规则未自动生成。
- Context Governance Reviewer: pass，未复制敏感配置原值；候选索引保持 candidate。

## 8. 行动建议

1. 先审查 `standard-android.md`，重点确认 `PENDING-APP-2` 和 `PENDING-APP-3`。
2. 再审查 `standard-kmp-shared.md`，确认 KMP ObjC 暴露边界和 Presenter 状态流规则。
3. 最后审查 `standard-build-governance.md`，确认快速构建开关是否适合推广到团队规范。
