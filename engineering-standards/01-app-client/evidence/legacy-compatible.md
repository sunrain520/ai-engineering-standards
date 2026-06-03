---
doc_id: "app-client-legacy-compatible"
title: "APP 客户端历史兼容证据"
domain: "app-client"
sub_domain: "common"
doc_type: "evidence-legacy"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "legacy-compatible"
  - "evidence"
---

# APP 客户端历史兼容证据

## LEG-APP-1 WatchListKmp 使用 globalScope 包装 KMP Service

- 路径：`watchlist-core/src/main/java/com/hstong/stock/core/WatchListKmp.kt:6-22`
- 对应规则：`standard-android.md「P1 Flow 订阅必须绑定 viewModelScope 或 viewLifecycleOwner 生命周期」`
- 观察：`WatchListKmp` object 中存在 `WatchlistService(globalScope)`。
- 兼容边界：这是集中桥接层，不作为 Fragment / ViewModel 新增 UI Flow 订阅模板。
- 建议：保留兼容，新增 KMP 能力优先使用 owner scope 或 ViewModel scope。

## LEG-APP-2 WatchListKmp 集中封装 KMP Service 访问

- 路径：`watchlist-core/src/main/java/com/hstong/stock/core/WatchListKmp.kt:6-22`
- 对应规则：`standard-kmp-shared.md「P2 KMP Service 全局包装属于历史兼容，不作为新增模板」`
- 观察：调用方可通过 `WatchListKmp.getService()` 取得服务，避免到处直接构造 Service。
- 兼容边界：全局 Scope 生命周期未在当前授权路径下完整确认，因此本条保持 pending。

## LEG-APP-3 trade-account 仍临时依赖旧 trade 模块

- 路径：`trade2/trade-account/build.gradle:31-34`
- 对应规则：`standard-module-boundary.md「P1 交易共享能力必须先沉淀到 trade-core，再由交易子模块复用」`
- 观察：`trade-account` 依赖 `trade2:trade-core`，同时有注释说明“暂时依赖老的交易模块，后续逐步重构去掉依赖”。
- 兼容边界：旧模块依赖是迁移期兼容，不应作为新增交易共享能力的落点。
