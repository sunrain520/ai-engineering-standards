---
doc_id: "app-client-20260526-212711-hszq-app-extraction-map"
title: "hszq-app 萃取地图"
domain: "app-client"
sub_domain: "android"
doc_type: "extraction-map"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260526-212711-app-client"
tags:
  - "app-client"
  - "android"
  - "extraction-map"
  - "hszq-app"
---

# hszq-app 萃取地图

> run_id: 20260526-212711-app-client
> 目标仓库: hszq-app
> evidence 来源: GitNexus 深度索引 + 目录扫描

## 1. 可萃取区域矩阵

| domain | sub_domain | task_type | candidate_signals | evidence_kind | GitNexus 能力 |
| --- | --- | --- | --- | --- | --- |
| app-client | android | 架构分层 | Fragment/Activity 基类层级、MVP/MVVM/Clean Architecture pattern 分布 | code-facts, positive-examples | query, impact, context |
| app-client | module-boundary | 模块边界 | 模块间 import 边、platformcomm 共享底座、三层依赖链 | code-facts, forbidden-examples | cypher, impact |
| app-client | base-class-governance | 基类治理 | BaseFeedFragment CRITICAL 影响、MarketListBaseActivity 遗留 | code-facts, legacy-compatible | impact, context |
| app-client | data-layer | 数据层组织 | Api 直调 177 符号、Repository 仅 trade/dao、UseCase 仅 trade/demo | code-facts, pending-confirmation | query |
| app-client | ui-component | UI 组件 | Fragment 519 符号、Adapter 134 符号、ViewBinding/DataBinding 使用 | code-facts, positive-examples | query, cypher |
| app-client | build-governance | 构建治理 | gradle-repo + module-repo 插件、settings.gradle 模块注册策略 | code-facts | file_existence |
| app-client | testing | 测试覆盖 | test/ 目录分布、mock/fake 使用、CI 配置 | code-facts | query |
| app-client | navigation-routing | 导航路由 | DeepLink/Router 使用、Fragment 跳转方式 | code-facts | route_map, query |

## 2. 候选 evidence 文件分布

### 2.1 架构分层

| 路径模式 | evidence 类型 | 说明 |
| --- | --- | --- |
| `trade/demo/domain/usecase/` | positive-example | Clean Architecture pilot |
| `trade/demo/presentation/viewmodel/` | positive-example | MVVM 示例 |
| `quotes/**/Presenter*` | legacy-compatible | MVP 遗留 |
| `trade/**/ViewModel*` | code-facts | trade 内 MVVM 分布 |
| `community/**/Fragment*` | code-facts | Fragment + Api 直调传统模式 |

### 2.2 模块边界

| 路径模式 | evidence 类型 | 说明 |
| --- | --- | --- |
| `platformcomm/src/**` | code-facts | 全仓共享底座 bean/interface |
| `feed/src/**/base/BaseFeedFragment.kt` | code-facts | 跨模块基类 |
| `community/src/**/*Fragment*` | code-facts | 依赖 feed 基类的下游 |

### 2.3 基类治理

| 路径模式 | evidence 类型 | 说明 |
| --- | --- | --- |
| `feed/src/**/BaseFeedFragment.kt` | code-facts | ~943 行超大基类，CRITICAL 影响 |
| `quotes/**/MarketListBaseActivity*` | legacy-compatible | 已边缘化 MVP 基类 |
| `app-core/src/**/*Base*` | code-facts | 待确认 app-core 基类分布 |

### 2.4 数据层

| 路径模式 | evidence 类型 | 说明 |
| --- | --- | --- |
| `trade/common/dao/**Repository*` | code-facts | 唯一 Repository 实现 |
| `trade/demo/domain/usecase/**UseCase*` | positive-example | 唯一 UseCase 实现 |
| `**/api/**Api*` | code-facts | 177 个 Api 类分布 |

## 3. 不可萃取区域

| 路径 / 模式 | 原因 |
| --- | --- |
| `build/`、`.gradle/` | 构建产物和缓存 |
| `**/keystore*`、`signing*` | 敏感凭据 |
| `repo.xml`、`repo_child_*.json`、`repoproject.json` | 内部仓库管理 |
| `hszq-version/` | 版本管理工具，非业务代码 |
| `annotation/`、`annotationprocessor/` | 基础设施代码，不含业务规范 evidence |
| `doc/`、`openspec/` | 文档和规范工具链，不是被萃取的业务代码 |

## 4. GitNexus 能力利用策略

| 阶段 | GitNexus 工具 | 用途 |
| --- | --- | --- |
| facts-and-classification | `query` | 搜索特定 pattern（Presenter/ViewModel/Repository/UseCase）的全仓分布 |
| facts-and-classification | `impact` | 分析核心基类/接口的下游影响范围和风险级别 |
| facts-and-classification | `context` | 获取关键 symbol 的完整上下文（定义、实现接口、调用关系）|
| facts-and-classification | `cypher` | 查询模块间 import 边数、社区分布、文件计数 |
| facts-and-classification | `route_map` | 分析导航路由 pattern（如果存在 Router/DeepLink 配置）|
