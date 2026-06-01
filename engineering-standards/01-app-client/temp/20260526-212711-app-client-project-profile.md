---
doc_id: "app-client-20260526-212711-hszq-app-project-profile"
title: "hszq-app 项目画像"
domain: "app-client"
sub_domain: "android"
doc_type: "project-profile"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260526-212711-app-client"
tags:
  - "app-client"
  - "android"
  - "project-profile"
  - "hszq-app"
---

# hszq-app 项目画像

> run_id: 20260526-212711-app-client
> 目标仓库: hszq-app（/Users/kuang/ops/hszq-app）
> extraction_mode: profile-first
> evidence 来源: GitNexus 深度索引（158K nodes, 386K edges, 5974 communities）+ 目录扫描

## 1. 仓库概述

| 维度 | 值 |
| --- | --- |
| 仓库类型 | 超大型 Android 多模块单仓 |
| 源码文件总数 | 5638（.kt + .java） |
| 顶层模块数 | ≥ 87 个目录（至少 15 个可识别功能模块） |
| 构建系统 | Gradle 多模块 + gradle-repo 插件 + module-repo 插件 |
| 包名前缀 | `com.hstong.*` 与 `com.huasheng.stock.*` 双前缀共存（历史迁移未完全收敛）|
| GitNexus 索引 | 已索引；graph available, fts available, vector unavailable |
| AI 工具链 | 已引入 openspec/spec-first（`openspec/`、`doc/CLAUDE.md`、`search/AGENTS.md`）|

## 2. 模块体量分布

| 模块 | .kt/.java 文件数 | 占比 | 备注 |
| --- | --- | --- | --- |
| quotes | 1356 | 24.0% | 行情功能集中区，体量最大 |
| trade | 1148 | 20.4% | 交易功能，内聚度较高 |
| community | 475 | 8.4% | 社区内容，重度依赖 feed 基类 |
| quotes-detail | 150 | 2.7% | 行情详情 |
| quotes-watchlist | 131 | 2.3% | 自选股 |
| platformcomm | 118 | 2.1% | 全仓共享 bean/interface 底座 |
| feed | 93 | 1.6% | 社区内容中间层，BaseFeedFragment 所在 |
| 其余模块 | ~2167 | 38.4% | post/ark/pla/search/parse/position-change 等 |

模块粒度极不均匀：最大（quotes 1356）是最小功能模块（feed 93）的 14.6 倍。

## 3. 架构 Pattern 现状

| Pattern | 分布 | 代表性 |
| --- | --- | --- |
| Fragment + 直接 Api 调用（传统模式） | 全仓库主体 | 绝大多数业务模块当前写法 |
| MVP（Presenter） | quotes（行情列表）、trade（设置页）散点 | 非全局统一，部分遗留 |
| MVVM（ViewModel） | trade 模块局部区域 | 已在 trade 内形成区域 |
| Clean Architecture（UseCase + Repository + ViewModel） | 仅 trade/demo 示例 | 新规范 pilot，尚未推广 |

Fragment 社区 519 个符号（第一大社区），Api 社区 177 个（第二大），Adapter 社区 134 个。

## 4. 模块依赖拓扑

```text
community ──extends──→ feed ──imports──→ platformcomm
    │                    │
    └──imports──→ platformcomm
                         ↑
quotes ──imports─────────┘
trade  ──(内聚，跨出较少)
```

关键依赖事实：
- `platformcomm` 是全仓库的 bean/interface 共享底座，被 feed、community、quotes 等多模块直接 import
- `community` → `feed` → `platformcomm` 存在三层传递依赖链
- `trade` 模块内聚度较高，跨模块 import 相对收敛

## 5. 核心基类影响分析（GitNexus impact）

| 基类 | 位置 | 行数 | 下游影响 | 风险级别 | 直接子类 |
| --- | --- | --- | --- | --- | --- |
| BaseFeedFragment | feed/src/main/java/.../base/ | ~943 行 | 82 个符号 | CRITICAL | 13 个（全在 community 模块）|
| MarketListBaseActivity | quotes/ MVP 包 | - | 1 个符号 | LOW | 已实质边缘化 |

BaseFeedFragment 是全仓库影响范围最大的基类之一，跨越 feed 和 community 两个模块形成强耦合。

## 6. 敏感路径排除

| 路径 / 模式 | 处置 |
| --- | --- |
| `**/build/**` | 排除（构建产物）|
| `**/.gradle/**` | 排除（Gradle 缓存）|
| `**/local.properties` | 排除（本地配置）|
| `**/keystore*`、`**/signing*` | 只记录存在事实，不读取原值 |
| `**/gradle.properties` 中的 nexus/maven 凭据 | 只记录存在事实，不读取原值 |
| `repo.xml`、`repo_child_git.json`、`repo_child_temp.json`、`repoproject.json` | 排除（内部仓库管理配置）|

## 7. 候选研发域与子领域

| domain | sub_domain | 判断依据 |
| --- | --- | --- |
| app-client | android | Gradle Android 多模块；Fragment/Activity 为 UI 主体 |
| app-client | module-boundary | 87 个顶层目录；模块粒度极不均匀 |
| app-client | architecture-pattern | MVP/MVVM/Clean Architecture 三种 pattern 混杂 |
| app-client | base-class-governance | BaseFeedFragment CRITICAL 级影响 |
| app-client | data-layer | Api 直调为主，Repository/UseCase 仅 pilot |

## 8. 适合萃取的模块推荐

| 优先级 | 模块 | 理由 |
| --- | --- | --- |
| 高 | trade | 内聚度高，已有 MVVM 和 Clean Architecture pilot；可作为新架构规范的证据来源 |
| 高 | feed + community | BaseFeedFragment 跨模块影响 CRITICAL；可萃取基类治理和模块依赖规范 |
| 中 | quotes | 体量最大但内部可能混杂多种 pattern；适合萃取分层规范 |
| 中 | platformcomm | 全仓共享底座；适合萃取共享模块 API 契约规范 |
| 低 | quotes-watchlist | MVP 遗留集中区；适合萃取 legacy-compatible 证据 |

## 9. 待确认事项

- `hszq-version/` 目录的版本管理策略需确认（是否为 version catalog 或版本中心化工具）。
- `openspec/` 已存在 spec-first 流程产物，需确认是否有已落地的规范约束应作为冲突基线。
- `com.hstong.*` 与 `com.huasheng.stock.*` 双包名的迁移计划和边界需确认。
- trade/demo 的 Clean Architecture pilot 是否已被团队认可为推荐 pattern 需确认。
