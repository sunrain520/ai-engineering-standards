---
doc_id: "app-client-android-ai-rules-batch-001"
title: "APP Android AI Rules（batch-001 trade architecture）"
domain: "app-client"
sub_domain: "android"
doc_type: "ai-rules"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260526-212711-app-client"
tags:
  - "app-client"
  - "android"
  - "ai-rules"
  - "batch-001-trade-architecture"
---

# APP Android AI Rules（batch-001 trade architecture）

> 派生自: temp/20260526-212711-app-client-standard-trade-architecture.md
> 本文件不新增独立规则，仅汇总 standard 中可被 AI 无歧义执行的约束。
> status: **active** — 已确认为 AI 默认强约束。

## 新功能开发

1. **[P1]** 新建 trade 模块 feature 时，必须按 `data/` → `domain/` → `presentation/` 三层组织。先创建 domain 层接口和 UseCase，再创建 data 层和 presentation 层。
2. **[P1]** ViewModel 不得直接调用网络 API 或 DAO，必须经过 UseCase。
3. **[P1]** UseCase 不得引用 Android framework 类型（Context、LiveData、View 等）。
4. **[P1]** 依赖方向严格单向：`presentation` → `domain` ← `data`。

## ViewModel 规范

5. **[P1]** 新建 ViewModel 前先判断类型：业务型 / 事件协调型 / scope 共享型，在命名或注释中体现。
6. **[P1]** 事件协调型 ViewModel（`*EventVM`）只持有事件 LiveData，不得添加网络请求或数据转换。
7. **[P1]** 单个 ViewModel 不得超过 400 行；超过时必须提出拆分建议。
8. **[P2]** 不得在 ViewModel 中直接 import Room DAO 或 Database 类。
9. **[P2]** 新建 Repository 时必须先定义 domain 层接口。

## 禁止项

10. **[FORBIDDEN]** 不得新建 Presenter 类、实现 onInitPresenter、或创建 MVP Contract 接口。
11. **[FORBIDDEN]** 如被要求在 MVP 模块修改，结论中必须建议迁移到 MVVM。
12. **[P2]** 不得新建继承 BaseVMDataHelper 的类；使用标准 `ViewModelProvider` / `by viewModels()` / `by activityViewModels()`。
