---
doc_id: "app-client-pending-confirmation"
title: "APP 客户端待确认项"
domain: "app-client"
sub_domain: "common"
doc_type: "pending-confirmation"
version: "v0.1.0"
status: "pending"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "pending-confirmation"
---

# APP 客户端待确认项

## PENDING-APP-1 发布签名和生产配置变量注入边界

- 来源规则：`standard-build-governance.md「P1 发布签名和生产配置只能通过变量注入，不能写入规范或源码正文」`
- 当前状态：`pending-confirmation`
- 证据：`evidence/code-facts.md「EV-APP-9」`
- 待确认 owner：发布/CI 负责人
- 待确认问题：
  1. `RELEASE_*` 变量来源是否只来自本地未入库配置或 CI secret。
  2. 是否允许在规范中公开变量名。
  3. 是否需要补充 Google Play、国内渠道、beta/feature 构建的敏感配置边界。
- 临时处理：AI 不得读取或输出签名、证书、token、生产配置原值。

## PENDING-APP-2 KMP Service 全局包装生命周期收敛

- 来源规则：`standard-kmp-shared.md「P2 KMP Service 全局包装属于历史兼容，不作为新增模板」`
- 当前状态：`pending-confirmation`
- 证据：`evidence/code-facts.md「EV-APP-30」`、`evidence/legacy-compatible.md「LEG-APP-2」`
- 待确认 owner：KMP / 自选股模块负责人
- 待确认问题：
  1. `WatchListKmp` 的全局 Scope 是否有统一释放或进程级生命周期约束。
  2. 新增 KMP Service 是否应统一走 ViewModel scope / owner scope 注入。
  3. 历史 bridge 是否需要迁移计划或保留白名单。
- 临时处理：AI 不得复制 `WatchlistService(globalScope)` 模式到新能力。
