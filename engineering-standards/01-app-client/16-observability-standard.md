---
doc_id: "app-client-observability-standard-archived"
title: "APP 日志、埋点与可观测性规范（待 evidence 归档）"
domain: "app-client"
sub_domain: "observability"
doc_type: "standard"
version: "v0.1.0"
status: "archived"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
coverage_state: "not-extracted-in-current-run"
tags:
  - "app-client"
  - "observability"
  - "archived"
---

> 本次 `hszq-app` run 未形成日志、埋点或可观测性维度的高置信规则，本文件仅保留历史规范草案。AI 不得把本文内容作为默认执行规则。

# APP 日志、埋点与可观测性规范

> 当前文档是 APP 日志、埋点与可观测性的萃取维度说明，状态为 structure-ready。具体强制规则必须由后续真实 evidence 或负责人确认补齐。

## 1. 适用范围

本规范覆盖客户端日志、埋点、Crash、性能指标、链路追踪、关键业务事件、错误诊断和问题复盘所需上下文。

## 2. 萃取时应关注的 evidence

| 维度 | 候选代码信号 |
| --- | --- |
| 日志 | log wrapper、tag、level、debug/release gate |
| 埋点 | analytics、Sensors、event name、page exposure、click event |
| Crash | crash reporter、exception handler、breadcrumb |
| 性能 | startup trace、page render、network timing、cache hit |
| 业务诊断 | order id、request id、route id、feature flag、market/account context |

## 3. 应沉淀的规则内容

1. 高风险业务必须记录可诊断但不泄露敏感数据的关键上下文。
2. 日志级别、tag、采样和 release 开关必须统一，不得随意 `print`。
3. 埋点事件必须有稳定命名、触发时机和参数边界。
4. Crash 附加信息不得包含敏感原值，应使用脱敏上下文。
5. 性能问题需要能关联页面、接口、缓存命中、刷新频率和设备环境。

## 4. AI 生成代码要求

1. AI 新增高风险流程时必须考虑日志、埋点和失败诊断上下文。
2. AI 不得直接打印敏感字段或完整请求响应。
3. AI 新增埋点必须说明事件名、触发时机、参数和是否含敏感信息。

## 5. Code Review 检查项

- [ ] 日志是否使用统一封装和级别。
- [ ] 埋点是否有稳定事件名和参数边界。
- [ ] Crash/日志是否不含敏感原值。
- [ ] 高风险流程是否有可诊断上下文。
- [ ] 性能指标是否能定位页面、接口和缓存策略。
