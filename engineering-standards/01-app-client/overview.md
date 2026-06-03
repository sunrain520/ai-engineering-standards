---
doc_id: "app-client-overview"
title: "APP 客户端规范总览"
domain: "app-client"
sub_domain: "common"
doc_type: "overview"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "overview"
---

# APP 客户端规范总览

本目录保存从 `hszq-app` 萃取出的 App 客户端工程规范。当前覆盖 Android、KMP Android 消费侧、模块边界和构建治理四个子领域。

## 当前产物

| 文档 | 子领域 | 说明 |
| --- | --- | --- |
| `standard-android.md` | android | Kotlin 新增代码、Fragment 生命周期、Flow 订阅、EventBus |
| `standard-kmp-shared.md` | kmp-shared | Android 侧消费 KMP Presenter / Flow / Service 的边界 |
| `standard-module-boundary.md` | module-boundary | trade-core、provider request、账户导航、core-ui-kit 边界 |
| `standard-build-governance.md` | build-governance | hszq-version、settings include、主应用构建语义、敏感配置 |
| `ai-rules.md` | common | AI 默认执行规则和非执行警告 |
| `review-checklist.md` | common | Code Review 检查项 |
| `pending-confirmation.md` | common | 高风险或证据不足待 owner 确认项 |
| `evidence/` | common | 本次直接扫描证据和历史兼容证据 |
| `lineage-ledger.json` | common | evidence 到 standard / AI / review / index 的派生链 |
| `owner-decision-queue.json` | common | auto-active 和 pending 规则的负责人裁定队列 |

## 状态说明

- `auto-active`：在 `hszq-app` 当前 evidence 下满足自动升级闸，可进入 AI 默认执行路径，但仍需 owner 事后审查。
- `pending-confirmation`：涉及安全、发布、全局生命周期或证据不足，不进入 AI 默认执行路径。
- `draft`：有 evidence 但未达到自动升级闸，仅作为参考上下文。

## Coverage 边界

本次 run 使用本地 `hszq-app` 仓库，直接扫描目标仓库当前 commit `feb6f82ae442bdf3444624270dc24ca15d437e55`。`AGENTS.md` 要求参考 `./submodules/biz-common/CLAUDE.md`，但当前授权路径下不存在 `submodules/` 目录，因此 KMP shared 源码内部规范只记录为 blind spot，不在本次规则中强制声明。
