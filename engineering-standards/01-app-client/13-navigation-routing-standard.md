---
doc_id: "app-client-navigation-routing-standard-archived"
title: "APP 路由与页面协作规范（已归档）"
domain: "app-client"
sub_domain: "navigation-routing"
doc_type: "standard"
version: "v0.1.0"
status: "archived"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
superseded_by: "standard-module-boundary.md"
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "navigation-routing"
  - "archived"
---

> 本文件已归档。跨模块 provider、request 和账户子页导航的现行规则见 `standard-module-boundary.md`。

# APP 路由与页面协作规范

> 当前文档是 APP 路由与页面协作的萃取维度说明，状态为 structure-ready。具体强制规则必须由后续真实 evidence 或负责人确认补齐。

## 1. 适用范围

本规范覆盖页面跳转、模块间协作、DeepLink、路由参数、Provider/Router/Contract 边界，以及跨业务域调用方式。

## 2. 萃取时应关注的 evidence

| 维度 | 候选代码信号 |
| --- | --- |
| 路由入口 | `Router`、`Navigator`、`RoutePath`、`DeepLink`、scheme 配置 |
| 页面参数 | `Bundle`、`Intent` extra、route params、typed argument、Parcelable/Serializable |
| 跨模块调用 | `contract`、`provider`、`service locator`、DI binding |
| 业务域边界 | feature 间依赖、contract module、router module、page provider |
| 降级处理 | 路由不存在、参数缺失、登录态/权限不足、市场不可用 |

## 3. 应沉淀的规则内容

1. 跨业务域页面协作应通过稳定 contract、router 或 provider，不直接依赖对方 feature 实现。
2. 路由参数应使用稳定、可校验的参数模型，禁止在调用方和被调用方各自硬编码散落 key。
3. DeepLink 必须有登录态、权限、展业地和参数合法性校验。
4. 页面跳转失败必须有明确降级策略，不能静默失败。
5. 高风险业务页面不得绕过业务入口校验直接打开内部页面。

## 4. AI 生成代码要求

1. AI 新增跨模块跳转前必须检查是否已有 route/provider/contract。
2. AI 不得为了跳转直接新增 feature-to-feature 依赖。
3. AI 新增 DeepLink 必须同时输出参数校验、登录态/权限判断和失败兜底。

## 5. Code Review 检查项

- [ ] 跨业务域跳转是否通过稳定契约。
- [ ] 路由参数是否集中定义并可校验。
- [ ] DeepLink 是否覆盖登录态、权限和展业地差异。
- [ ] 路由失败是否有兜底。
- [ ] 是否新增了不必要的 feature 实现依赖。
