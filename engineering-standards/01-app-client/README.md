---
doc_id: "app-client-readme"
title: "APP 客户端规范目录说明"
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
  - "readme"
---

# APP 客户端规范入口

本目录当前以 `hszq-app` 单项目 evidence-backed 产物为现行执行入口。旧 `00-17` 编号文档已保留为归档、待 evidence 或流程说明，不再作为 AI 默认执行规则来源。

## 现行执行入口

| 文件 | 用途 |
| --- | --- |
| `overview.md` | 本次 run 的覆盖范围、状态和 blind spot |
| `standard-build-governance.md` | 构建治理规则 |
| `standard-module-boundary.md` | 模块边界规则 |
| `standard-android.md` | Android 生命周期与新增代码规则 |
| `standard-kmp-shared.md` | Android 侧 KMP 消费边界 |
| `ai-rules.md` | AI 默认执行规则 |
| `review-checklist.md` | Code Review 检查项 |
| `pending-confirmation.md` | 需要 owner 确认的高风险或低证据项 |
| `lineage-ledger.json` | evidence 到派生视图的追溯链 |
| `owner-decision-queue.json` | owner 事后裁定队列 |

## 编号文档状态

`00-17` 文档不会自动升级为现行规则。当前处理方式如下：

1. Android、KMP、模块边界、构建治理相关编号文档指向对应 `standard-*` 现行产物。
2. iOS、数据中台、多展业地、测试、性能、安全合规、可观测性等未在本次 run 形成高置信 evidence 的编号文档保持归档/待 evidence 状态。
3. AI 使用本目录时应优先读取 `ai-rules.md`，再按命中的子领域读取对应 `standard-*`。

## Evidence 边界

本次 run 只记录项目根相对路径和脱敏存在事实。敏感签名、证书、token、生产配置原值不得进入规范正文、AI rules 或 review checklist。
