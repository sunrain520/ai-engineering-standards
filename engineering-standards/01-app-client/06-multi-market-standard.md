---
doc_id: "app-client-multi-market-standard-archived"
title: "多展业地 APP 规范（待 evidence 归档）"
domain: "app-client"
sub_domain: "multi-market"
doc_type: "standard"
version: "v0.1.0"
status: "archived"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
coverage_state: "not-extracted-in-current-run"
tags:
  - "app-client"
  - "multi-market"
  - "archived"
---

> 本次 `hszq-app` run 未形成多展业地维度的高置信规则，本文件仅保留历史规范草案。AI 不得把本文内容作为默认执行规则。

# 多展业地 APP 规范

## 1. 规范定位

多展业地规范用于支撑 KAZ APP 以及后续全球化展业场景。核心目标是让域名、语言、主题、功能开关、业务规则、接口差异和合规差异可以通过配置、策略或 DI 管理，而不是散落在页面层硬编码。

## 2. 架构原则

1. 核心业务能力模块化。
2. 展业地差异配置化。
3. UI 风格可替换。
4. 语言、主题、域名、功能开关可配置。
5. 后端接口差异通过 DTO Mapper 隔离。
6. 业务规则差异通过策略、配置或依赖注入解决。
7. 不允许为单一展业地硬编码分支污染主流程。

## 3. 配置管理中心规范

配置中心应覆盖：

- app-config 全量页面触达。
- 域名配置。
- API 路由配置。
- 功能开关。
- Tab 配置。
- 首页模块配置。
- 交易市场配置。
- 语言配置。
- 主题配置。
- 合规配置。
- 风控配置。
- 推送配置。

## 4. 配置 Provider 示例

推荐：

```kotlin
interface MarketConfigProvider {
    fun getCurrentMarket(): Market
    fun getApiDomain(): String
    fun isFeatureEnabled(featureKey: String): Boolean
}
```

禁止：

```kotlin
if (country == "KAZ") {
    // 大量硬编码业务逻辑
}
```

## 5. 多展业地代码规则

强制规则：

1. 展业地差异优先通过配置中心解决。
2. 配置无法解决时，通过策略模式解决。
3. 策略无法解决时，通过依赖注入替换实现。
4. 不允许在 UI 层大量编写展业地 if/else。
5. 不允许把 KAZ 特殊逻辑硬编码到华盛通主流程。
6. 新增展业地必须明确域名、语言、主题、功能开关、业务模块开关、接口 DTO Mapper 和合规差异。

推荐规则：

1. 多展业地差异应在模块入口统一收敛。
2. 页面只消费配置结果，不关心配置来源。
3. 市场差异、合规差异、风控差异应分开建模。
4. 复杂业务差异应通过 strategy interface 表达。

## 6. 差异处理优先级

处理展业地差异时按以下优先级选择：

1. 配置中心。
2. 主题、多语言、组件参数。
3. DTO Mapper。
4. Strategy。
5. DI 替换实现。
6. 独立展业地适配模块。

禁止优先使用：

- 页面层 if/else。
- 散落在 ViewModel 或 Reactor 中的国家判断。
- 对主流程侵入式修改。
- 复制一套业务模块。

## 7. 新增展业地准入清单

新增展业地必须明确：

- 展业地编码。
- API 域名。
- 静态资源域名。
- 默认语言。
- 支持语言列表。
- 主题配置。
- 首页 Tab 配置。
- 业务模块开关。
- 交易市场配置。
- 合规配置。
- 风控配置。
- 推送配置。
- 接口 DTO 差异。
- 错误码差异。
- 日志和埋点差异。

## 8. DTO Mapper 差异隔离

接口差异优先通过 mapper 隔离：

```text
Market A DTO
    ↓
Mapper
    ↓
Domain Model

Market B DTO
    ↓
Mapper
    ↓
Domain Model
```

强制规则：

1. 不允许 UI 直接兼容不同展业地的接口字段。
2. 不允许 Domain Model 跟随某一展业地接口字段变化。
3. mapper 必须覆盖字段缺失、默认值、枚举兼容和错误码差异。

## 9. AI 生成规则

AI 生成多展业地代码时必须遵守：

1. 域名、语言、主题、功能开关必须走配置。
2. UI 风格差异优先通过主题和组件配置解决。
3. 业务差异优先通过策略接口解决。
4. 接口差异优先通过 DTO Mapper 解决。
5. 不允许在页面中硬编码国家、市场、展业地逻辑。
6. 新增展业地必须说明配置项和适配点。

## 10. Review 检查项

- 差异是否配置化。
- 是否存在硬编码展业地判断。
- 是否支持语言、主题、域名、功能开关配置。
- 是否影响已有展业地。
- DTO 差异是否通过 mapper 隔离。
- 业务差异是否通过策略或 DI 隔离。
- UI 风格差异是否通过主题或组件契约隔离。
