---
doc_id: "app-client-20260526-212711-ai-context-pack"
title: "APP Client AI Context Pack（batch-001）"
domain: "app-client"
sub_domain: "android"
doc_type: "ai-context-pack"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260526-212711-app-client"
tags:
  - "app-client"
  - "android"
  - "ai-context-pack"
  - "batch-001-trade-architecture"
---

# APP Client AI Context Pack（batch-001 trade architecture）

> 本文件是 AI 代码生成/审查时的快速上下文注入包。
> 包含当前 batch 所有已通过 Quality Gate 的强约束摘要。

## 约束摘要

### 架构约束

1. **[P1]** 新 trade 模块 feature 必须按 `data/` → `domain/` → `presentation/` 三层组织。
2. **[P1]** 依赖方向严格单向：`presentation` → `domain` ← `data`。
3. **[P1]** ViewModel 不得直接调用网络 API 或 DAO，必须经过 UseCase。
4. **[P1]** UseCase 不得引用 Android framework 类型（Context、LiveData、View 等）。

### ViewModel 约束

5. **[P1]** 新建 ViewModel 前先判断类型：业务型 / 事件协调型 / scope 共享型。
6. **[P1]** 事件协调型 ViewModel（`*EventVM`）只持有事件 LiveData，不含业务逻辑。
7. **[P1]** 单个 ViewModel 不超过 400 行；超过时必须提出拆分建议。
8. **[P2]** 不得在 ViewModel 中直接 import Room DAO 或 Database 类。
9. **[P2]** 新建 Repository 时必须先定义 domain 层接口。

### 禁止项

10. **[FORBIDDEN]** 不得新建 Presenter 类、实现 onInitPresenter、或创建 MVP Contract 接口。
11. **[FORBIDDEN]** 如被要求在 MVP 模块修改，结论中必须建议迁移到 MVVM。
12. **[P2]** 不得新建继承 BaseVMDataHelper 的类；使用标准 `ViewModelProvider` / `by viewModels()` / `by activityViewModels()`。

## ViewModel 类型速查

| 类型 | 职责 | 命名模式 | 示例 |
| --- | --- | --- | --- |
| 业务型 | 持有 UiState，通过 UseCase 获取和转换数据 | `*ViewModel` | DemoTextViewModel |
| 事件协调型 | 跨 Fragment 事件总线，只持有事件 LiveData | `*EventVM` | TradeTabEventVM |
| Scope 共享型 | 跨子 Fragment 共享状态属性，不做网络请求 | 按功能命名 | StockDetailTradeHomeVM |

## 新功能模板结构

```text
feature_name/
├── data/
│   ├── dto/          # 网络/数据库数据传输对象
│   ├── mapper/       # DTO → Domain Model 映射
│   └── repository/   # RepositoryImpl（实现 domain 接口）
├── domain/
│   ├── model/        # 纯数据类（Kotlin data class）
│   ├── repository/   # Repository 接口
│   └── usecase/      # 单一业务操作封装
└── presentation/
    ├── mapper/       # Domain → UiModel 映射
    ├── model/        # UiModel / UiState
    ├── viewmodel/    # ViewModel（持有 UiState）
    └── ui/           # Activity / Fragment
```

## Evidence 来源

- batch: batch-001-trade-architecture
- 目标仓库: hszq-app
- evidence 方法: GitNexus 深度索引（158K nodes）
- 参考实现: `trade/src/main/java/com/hstong/trade/demo/`（Clean Architecture pilot）
