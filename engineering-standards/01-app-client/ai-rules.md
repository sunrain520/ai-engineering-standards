---
doc_id: "app-client-module-boundary-ai-rules"
title: "APP Module Boundary AI Coding Rules"
domain: "app-client"
sub_domain: "module-boundary"
doc_type: "ai-rules"
version: "v0.1.0"
status: "active"
owner: "APP 架构负责人"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "module-boundary"
  - "ai-rules"
  - "ai-coding"
---

# APP Module Boundary AI Coding Rules

> 本文件是 `standard-{sub_domain}.md`（各 sub_domain 规范文件）的汇总派生视图，由 generation 阶段自动生成，不接受手工修改。
> 如需修改规则，请更新对应 `standard-{sub_domain}.md` 后重新运行 generation 阶段。

## 1. 全局约束

AI 默认必须执行 `status: active` 的 P0 / FORBIDDEN 规则。对 evidence-backed `status: draft` 规则，AI 可以按规则生成草案，但必须在输出中标注 draft 状态和 evidence tier。

AI 不得执行 `pending-confirmation`、`conflict`、`legacy-compatible`、`rejected` 或 `evidence_tier: none` 的规则。

## 2. 可执行规则列表

### module-boundary

- `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」`
  - AI 新增跨业务域调用前，必须先检查目标业务域是否已有可复用的 `contract`。
  - AI 修改 `contract` 模块时，必须保持 `contract` 不依赖 `feature` 实现模块。
  - AI 不得在 `contract` 中生成页面实现、复杂业务流程或内部状态管理代码。
  - AI 发现需要跨域复用但当前没有契约时，应输出待确认项，而不是直接依赖对方 feature 实现。

- `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」`
  - AI 新增或修改 `contract` 模块依赖前，必须说明该依赖服务的契约角色。
  - AI 不得在 `contract` 中默认加入 UI 组件、页面框架或业务实现依赖。
  - AI 发现现有 `contract` 中存在 UI 相关依赖时，应保留兼容现状并提示负责人确认收敛，不得擅自删除。

## 3. 高风险警告

- `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」` 和 `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」` 已确认 active，但 evidence 仍来自单项目 batch。跨项目推广前建议补充第二项目 evidence。
