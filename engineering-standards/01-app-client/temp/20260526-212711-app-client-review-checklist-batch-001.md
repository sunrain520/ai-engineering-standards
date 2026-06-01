---
doc_id: "app-client-android-review-checklist-batch-001"
title: "APP Android Review Checklist（batch-001 trade architecture）"
domain: "app-client"
sub_domain: "android"
doc_type: "review-checklist"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260526-212711-app-client"
tags:
  - "app-client"
  - "android"
  - "review-checklist"
  - "batch-001-trade-architecture"
---

# APP Android Review Checklist（batch-001 trade architecture）

> 派生自: temp/20260526-212711-app-client-standard-trade-architecture.md
> 本文件不新增独立检查项，仅汇总 standard 中可被人工或工具 yes/no 判定的检查点。
> status: **active** — 已确认为强制 Review 检查项。

## Clean Architecture 分层（新功能）

- [ ] 新功能是否按 `data/` → `domain/` → `presentation/` 三层组织包结构？
- [ ] `domain` 层是否包含 Model、Repository 接口、UseCase？
- [ ] `data` 层是否包含 DTO、Mapper、RepositoryImpl？
- [ ] `presentation` 层是否包含 ViewModel、UiModel、Activity/Fragment？
- [ ] 依赖方向是否严格单向：`presentation` → `domain` ← `data`？
- [ ] ViewModel 是否仅通过 UseCase 获取数据（无直接 API/DAO 调用）？
- [ ] UseCase 是否未引用 Android framework 类型（Context、LiveData、View）？

## ViewModel 职责分类

- [ ] 新 ViewModel 是否在命名或注释中明确属于业务型/事件协调型/scope 共享型之一？
- [ ] 事件协调型 ViewModel（`*EventVM`）是否仅持有事件 LiveData，无网络请求或数据转换？
- [ ] 单个 ViewModel 是否在 400 行以内？
- [ ] 超过 400 行的 ViewModel 是否附带拆分建议或 TODO？

## MVP 禁止项

- [ ] 新增文件是否包含 `Presenter` 类定义？（禁止）
- [ ] 新增文件是否实现 `onInitPresenter` 生命周期钩子？（禁止）
- [ ] 新增文件是否包含 MVP `Contract` 接口？（禁止）
- [ ] 如果是维护性修改既有 MVP 代码，是否在 PR 描述或注释中标注了迁移建议？

## 数据层隔离

- [ ] 新 ViewModel 是否直接 import 了 Room DAO 或 Database 类？（禁止）
- [ ] 新 Repository 是否有对应 `domain` 层接口定义？
- [ ] 新 ViewModel 获取方式是否使用标准 `ViewModelProvider` / `by viewModels()` / `by activityViewModels()`？
- [ ] 新文件是否继承了 `BaseVMDataHelper`？（禁止扩散）
