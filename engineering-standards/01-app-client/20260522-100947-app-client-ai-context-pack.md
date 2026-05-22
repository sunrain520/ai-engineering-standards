---
doc_id: "app-client-20260522-100947-app-client-ai-context-pack"
title: "App Client Module Boundary AI Context Pack"
domain: "app-client"
sub_domain: "module-boundary"
doc_type: "ai-context-pack"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "module-boundary"
  - "ai-context-pack"
---

# App Client Module Boundary AI Context Pack

## 1. 当前需求

使用 `project-standard-extractor` 从 `kaz-mvp` 的 module-boundary batch 萃取 APP 客户端模块边界规范。

## 2. 任务识别

- domain: `app-client`
- sub_domain: `module-boundary`
- task_type: `cross-module-contract`
- module: `contract`
- batch_id: `app-client-module-boundary-contract-layer`
- status: `candidate`

## 3. 命中规则

| source_doc | section_title | level | evidence_doc | tags |
| --- | --- | --- | --- | --- |
| `standard-module-boundary.md` | `P1 跨域协作必须通过 contract 稳定边界` | P1 | `evidence/code-facts.md` | `app-client`, `module-boundary`, `cross-module-contract` |

引用格式：

```text
standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」
```

## 4. 必须加载的规范

- `engineering-standards/01-app-client/standard-module-boundary.md`
- `engineering-standards/01-app-client/ai-rules.md`
- `engineering-standards/01-app-client/review-checklist.md`
- `engineering-standards/01-app-client/evidence/code-facts.md`
- `engineering-standards/01-app-client/pending-confirmation.md`

## 5. 相关代码路径

- `contract/trade/build.gradle.kts`
- `contract/quotes/build.gradle.kts`
- `contract/platform/build.gradle.kts`
- `contract/trade/src/main/AndroidManifest.xml`
- `contract/quotes/src/main/AndroidManifest.xml`
- `contract/platform/src/main/AndroidManifest.xml`
- `KAZ模块化架构设计规范.md`

## 6. 生成代码要求

- 必须通过 `contract`、路由契约或稳定接口处理跨业务域调用。
- 必须保持 `contract` 不依赖 `feature` 实现模块。
- 不得在 `contract` 中生成页面实现、复杂业务流程或内部状态管理代码。
- 命中 `pending-confirmation.md「PENDING-APP-1: contract 模块 UI 依赖是否应收敛」` 时，只能提示负责人确认。

## 7. 自检要求

生成后必须逐条引用 `standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」` 输出遵守情况。
