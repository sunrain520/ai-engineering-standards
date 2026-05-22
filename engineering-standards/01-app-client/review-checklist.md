---
doc_id: "app-client-module-boundary-review-checklist"
title: "APP Module Boundary Code Review Checklist"
domain: "app-client"
sub_domain: "module-boundary"
doc_type: "review-checklist"
version: "v0.1.0"
status: "active"
owner: "APP 架构负责人"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "module-boundary"
  - "review-checklist"
---

# APP Module Boundary Code Review Checklist

> 本文件是 `standard-{sub_domain}.md`（各 sub_domain 规范文件）的汇总派生视图，由 generation 阶段自动生成，不接受手工修改。
> 如需修改规则，请更新对应 `standard-{sub_domain}.md` 后重新运行 generation 阶段。

## 1. 必检项

本 batch 未生成 P0 / FORBIDDEN 规则。

## 2. 推荐检查项

### module-boundary

- [ ] `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」`：跨业务域调用通过 `contract`、路由契约或稳定接口完成，没有直接依赖对方 feature 实现。
- [ ] `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」`：`contract` 模块的构建脚本没有新增 `feature` 实现模块依赖。
- [ ] `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」`：`contract` 中没有页面实现、复杂业务流程或内部状态管理代码。
- [ ] `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」`：新增契约只暴露调用方需要依赖的稳定协议，没有把实现细节扩散给外部模块。
- [ ] `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」`：`contract` 新增依赖有明确契约角色，不是页面实现、UI 组件或业务实现依赖。
- [ ] `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」`：`contract` 没有通过依赖传递向调用方暴露 feature 或 UI 能力。
- [ ] `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」`：保留历史 UI 相关依赖时，变更说明写明兼容原因和后续收敛条件。

## 3. 历史兼容说明

本 batch 未生成历史兼容条目。`pending-confirmation.md「PENDING-APP-1: contract 模块 UI 依赖是否应收敛」` 已由负责人确认并升级为 `standard-module-boundary.md「P2 contract 模块应保持依赖轻量」`。
