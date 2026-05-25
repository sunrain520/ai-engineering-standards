---
doc_id: "industry-securities-standard"
title: "证券业务规范"
domain: "industry"
sub_domain: "securities"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD（行业 owner 待指定）"
source_batch: "industry-securities-poc"
evidence_tier: "synthetic-poc"
last_reviewed: "2026-05-25"
run_id: "20260525-030800-industry"
activation_state: "mixed"
tags: ["industry", "securities", "trading", "compliance", "poc"]
poc_disclaimer: "本文件为 phase 2 维度框架 PoC 合成产物，evidence 路径为脱敏 mock，非真实生产代码；仅用于验证 SEC-01~10 + XSEC-01~06 全 16 维骨架可行性与三态激活准确性。任何规则升级 active 前需基于真实证券系统代码重新萃取并由行业负责人确认。"
---

# 证券业务规范（PoC）

> **PoC 提示**：本文件由 `project-standard-extractor` phase 2 dimension framework 流水线在 2026-05-25 03:08 跑出，输入为脱敏 mock 项目 `demo-broker-platform`（虚构经纪业务系统：Java Spring 后端 + KMP+Clean APP + React 管理后台 + 港美股 H5/RN 跨端模块）。所有 evidence 路径与代码片段为合成示例，仅证明骨架机制可工作。详见 `evidence/dimension-activation-report.json` 和 `skills/project-standard-extractor/examples/phase-2/golden-sample-securities-run.md`。

## 1. 规范定位 [baseline]

- 子领域：`securities`
- 端类型：`industry`（贯穿 backend / app-client / frontend / hybrid-bridge 各端）
- 子领域信号命中：`core-securities`（命中 13 个 trading/order 关键词 + quickfixj 依赖）；`cross-border`（命中 8 个 hkex/nasdaq 关键词 + 2 处 ZoneId IANA 用法）
- 激活态汇总（详见 §13 与 evidence/dimension-activation-report.json）：
  - `baseline`：5 维（SEC-03、SEC-06、SEC-10、XSEC-01、XSEC-03）
  - `activated`：8 维（SEC-01、SEC-02、SEC-04、SEC-05、SEC-07、SEC-08、XSEC-02、XSEC-05）
  - `candidate`：3 维（SEC-09、XSEC-04、XSEC-06）
  - `pending-confirmation`：0 维（baseline 兜底章节列出 owner 待确认事项）

## 2. 职责边界 [baseline]

**应承载**：行情接入、订单生命周期、盘前/实时风控、清算结算、账户与适当性、监管报送、跨境合规、跨时区与多币种、跨境市场规则差异。

**不应承载**：通用 Web/CRUD 模板、与证券业务无关的电商/SaaS/教育规则；非证券领域的统一登录/IM/IM 推送等横切能力（这些属于 `engineering-standards/04-backend` 与 `engineering-standards/01-app-client`）。

## 3. 推荐目录 [activated]

> 来源：mock 项目 `demo-broker-platform/server/` 与 `demo-broker-platform/app/shared/src/commonMain/`。命中信号：`market-data` / `trading` / `risk-control` / `clearing` / `account` / `regulatory` / `cross-border` / `fx` 8 类关键模块。

```text
server/
├── trading/                        # SEC-02 命中
├── market-data/                    # SEC-01 命中
├── risk-control/                   # SEC-03 命中（partial → baseline 兜底）
├── clearing/                       # SEC-04 命中
├── account/                        # SEC-05 命中
│   └── kyc/
├── regulatory/                     # SEC-06 命中（baseline 高风险）
│   └── reporting-job/
├── compliance/                     # XSEC-03 命中（partial → baseline）
├── cross-border/
│   ├── qdii/
│   └── northbound/
├── fx/                             # XSEC-02 命中
├── trading-calendar/               # SEC-07 命中
├── gateway-fix/                    # SEC-08 命中
├── disaster-recovery/              # SEC-10 命中（baseline 高风险，无演练脚本 → pending）
├── us-stock/                       # XSEC-05 命中
└── hk-stock/                       # XSEC-05 命中

app/
├── shared/src/commonMain/kotlin/   # KMP 共享层
├── androidApp/                     # Android UI
├── iosApp/                         # iOS UI
└── hybrid/                         # H5/RN 港美股交易模块（命中 NativeBridge / TurboModule）
```

## 4. 分层规则 [activated]

| 层级 | 核心职责 | 禁止事项 | 激活态 |
| --- | --- | --- | --- |
| 行情 (market-data) | 实时/历史行情接入；订阅生命周期；snapshot 切片 | 业务规则混入；持仓写入 | activated |
| 交易 (trading) | 订单状态机；报单/撤单/成交回报；订单类型 | 行情订阅；账户清算 | activated |
| 风控 (risk-control) | 盘前/实时风控；自成交/异常报单/AML | 业务路由；订单状态推进 | baseline（partial activated） |
| 清算 (clearing) | T+0/T+1/T+2；CCASS/DTCC/中国结算；对账 | 实时撮合；行情订阅 | activated |
| 账户 (account) | KYC；适当性；账户隔离；权限开通 | 行情广播；交易撮合 | activated |
| 监管 (regulatory) | 报送任务；WORM 存证；监管标签注入 | 业务事务；客户可见数据回写 | baseline |
| 跨境 (cross-border) | QDII/北向/南向额度；外管局申报；W-8BEN | 国内 A 股交易主路径 | baseline（partial activated） |
| 跨端 Bridge (hybrid) | H5/RN 港美股交易模块；NativeBridge 收口 | 直接调用交易 SDK | activated |

## 5. 命名规范 [activated]

- **订单状态枚举**：使用 ISO/FIX 标准 `NEW` / `PARTIALLY_FILLED` / `FILLED` / `CANCELED` / `REJECTED` / `EXPIRED`；禁止自定义中文/拼音/缩写。
- **时区 ID**：使用 `ZoneId.of("America/New_York")` / `ZoneId.of("Asia/Hong_Kong")` IANA 标识；**禁止** `+08:00` 或 `GMT+8` 字面量（XSEC-01 强制约束）。
- **监管报送字段前缀**：`regulatory_*`；监管注解 `@Regulated` / `@AuditTrail`（SEC-06 命中信号）。
- **额度命名**：`northboundQuota` / `southboundQuota` / `qdiiQuota`；不与一般限额混用（XSEC-03 命中信号）。
- **跨端 JS-Native 通道**：`NativeBridge.invokeTrading(...)` / `TurboModuleQuoteSubscriber`；不在 H5/RN 侧直接拼装 FIX 报文。

## 6. 核心维度 — 国内证券（SEC-01~SEC-10）

### 6.1 行情数据 SEC-01 [activated]

> dimension_id: SEC-01 · risk_tag: high · subdomain: core-securities · 命中信号: market-data-naming（hit=true, 9 个关键词）+ market-data-deps（hit=true, level2-sdk）

**激活理由**：mock `server/market-data/Level2Snapshot.java` 含 `Level2`、`Quote`、`snapshot`、`Tick` 四个核心命名；`pom.xml` 引入 `level2-sdk:1.4.0`。

**强制规则**：

- 行情订阅必须通过 `MarketDataGateway.subscribe(symbol, level)` 收口；禁止业务代码直接持有 `Level2WebSocket`。
- 行情失效（断连超过 3s）必须触发 `QuoteStaleEvent`，下游订单系统读到 stale 必须拒单或降级到延迟行情。
- 行情合规：未购权用户必须显示"延迟 15 分钟"水印；下行带宽每 connection ≤ 5 Mbps。

### 6.2 报单与成交 SEC-02 [activated]

> dimension_id: SEC-02 · risk_tag: high · subdomain: core-securities · 命中信号: order-state（hit=true, OrderStatus 枚举 + FOK/IOC/GTC）+ trading-gateway（hit=true, quickfixj 依赖）

**激活理由**：mock `server/trading/OrderStatusMachine.java` 完整状态机 6 终态；`build.gradle` 引入 `quickfixj-core:2.3.1`。

**强制规则**：

- 订单状态机覆盖全部 ISO/FIX 终态；任何"中间态"（如 `PENDING_NEW`、`PENDING_CANCEL`）必须显式建模并设置 timeout 转 `REJECTED`。
- 订单类型必须经过 `OrderTypeRegistry` 校验，新增订单类型不能直接 hardcode 字符串。
- 回报通道使用 FIX 顺序号 + 重传机制；客户端断连不得丢失 ExecutionReport。
- 错单（成交价偏离市场显著）必须落 `WrongTradeAuditLog`（对应 SEC-06）+ 通知 ops。

### 6.3 风控引擎 SEC-03 [baseline]

> dimension_id: SEC-03 · risk_tag: high · combination: weighted threshold=2 · 评分 weight 1（risk-modules 命中）→ partial_activated → baseline 兜底
> rationale: 风控为证券高风险维度，单一 risk-control 模块文件存在不足以证明"规则引擎接入 + 业务实现交叉"；落地 baseline，列出 owner 待确认。

**激活理由**：mock `server/risk-control/PreTradeRiskService.java` 文件存在（hit=true, weight 1），但未引入规则引擎依赖（drools/easy-rules 全 miss）；不达 threshold=2，触发 baseline 兜底。

**Baseline 必检事项（owner 待确认）**：

- [ ] 是否存在统一的 `RiskRuleEngine`（即使硬编码也需有版本 + 灰度）。
- [ ] 自成交防护是否在订单簿匹配前执行（pre-trade）。
- [ ] 频繁报撤是否有限频规则（如 1 秒内 ≥ 5 次撤单触发风控告警）。
- [ ] AML 异常交易识别是否上报至 SEC-06 监管报送链路。

### 6.4 清算结算 SEC-04 [activated]

> dimension_id: SEC-04 · risk_tag: high · subdomain: core-securities · 命中信号: clearing-naming（hit=true, T+1/CCASS）+ clearing-modules（hit=true, server/clearing/）

**激活理由**：mock `server/clearing/CcassReconciliation.java` + `server/clearing/T1SettlementJob.java`。

**强制规则**：

- A 股 T+1 / 港股 T+2 / 美股 T+2（2024-05 后改 T+1）必须由 `SettlementCalendar` 统一驱动，不在业务代码 hardcode。
- 对账差异容忍度：金额差 ≤ 0.01 元 → 自动平账；> 0.01 元 → 人工介入并落 audit log。
- 跨境结算（CCASS/DTCC）时差校正使用 `ZoneId.of("UTC")` 统一基准（XSEC-06 联动）。

### 6.5 账户与适当性 SEC-05 [activated]

> dimension_id: SEC-05 · risk_tag: high · subdomain: core-securities · 命中信号: account-naming（hit=true, KYC/Suitability/MarginAccount）+ kyc-modules（hit=true）

**激活理由**：mock `server/account/kyc/SuitabilityAssessment.java` + 5 处 KYC 字段。

**强制规则**：

- 资金账户 / 证券账户 / 衍生品账户必须 schema 隔离（不同表/不同 schema）。
- 港股通/北交所/融资融券/期权交易权限开通必须先校验适当性问卷（C1~C5 风险等级 + 业务类型对应表）。
- KYC 资料留存 ≥ 5 年（金融行业法规，SEC-06 联动）；客户离开仍需保留留痕至期满。

### 6.6 监管报送 SEC-06 [baseline]

> dimension_id: SEC-06 · risk_tag: high · combination: weighted threshold=2 · 评分 weight 3（regulatory-modules+report-task 命中）→ activated → 但 baseline 强制章节存在
> rationale: 监管报送为证券高风险 baseline 维度，本项目命中 weight=3 达阈值，章节同时承担 baseline 兜底（即使 evidence 不充分也必须存在）。

**激活理由**：mock `server/regulatory/RegulatoryReportingJob.java`（含 `submitToRegulator()` 方法）+ `regulatoryTag` 字段在 `OrderEvent` 中注入。

**强制规则**：

- 报送任务必须使用 `@RegulatoryReport` 注解 + 调度器统一管理；失败必须重试 ≥ 3 次，最终失败必须告警 ops + 落 `failure_audit`。
- 报送数据必须落 WORM 存储（不可篡改介质，hash 链或追加式日志），保留期 ≥ 监管要求年限（A 股 5 年 / 港股 7 年 / 美股 6 年）。
- 监管标签 `regulatoryTag` 必须在订单生命周期全链路注入（接收 → 风控 → 撮合 → 清算 → 账户）；不允许中间环节丢失。
- 报送字段不接受脱敏（与 IND-03 敏感数据脱敏冲突时，监管字段优先；脱敏只在客户可见层应用）。

### 6.7 交易日历 SEC-07 [activated]

> dimension_id: SEC-07 · risk_tag: medium · subdomain: core-securities · 命中信号: trading-calendar（hit=true）+ holiday-naming（hit=true, preMarket/afterHours/holiday）

**激活理由**：mock `server/trading-calendar/TradingCalendarService.java` + `holiday.json` 数据文件。

**强制规则**：

- 交易日历类必须全局唯一（Singleton 或 DI Scope=Singleton），禁止业务模块各自维护。
- 节假日数据更新通过定时任务从交易所官网抓取或运维手动 push；变更必须经过双人 review。
- 集合竞价 / 连续竞价 / 收盘集合 时段切换必须由 `TradingSession` 状态机驱动，不在业务代码判断时间字面量。

### 6.8 接入协议 SEC-08 [activated]

> dimension_id: SEC-08 · risk_tag: high · subdomain: core-securities · 命中信号: protocol-deps（hit=true, quickfixj-core）+ low-latency-naming（hit=false）

**激活理由**：mock `pom.xml` 引入 `quickfixj-core:2.3.1`；未命中低延迟链路关键词（项目暂未做 RDMA/kernel-bypass）。

**强制规则**：

- FIX 协议版本统一使用 FIX 4.4 或 FIX 5.0 SP2；版本切换必须经过协议组确认。
- 链路心跳 < 30s；断连必须自动重连（指数退避，max 60s）；重连后必须发起 ResendRequest 补漏。
- 协议授权与计费按交易所对账单核对，月度差异 > 0.5% 必须告警。

### 6.9 金融工程与定价 SEC-09 [candidate]

> dimension_id: SEC-09 · risk_tag: medium · subdomain: core-securities · 命中信号: pricing-naming（hit=false）+ numerics-deps（hit=false）
> candidate hint: 当项目新增 `**/pricing/**` 或 `**/greeks/**` 模块、或引入 quantlib/commons-math3 依赖时，自动升级为 `activated`。

**Candidate 状态说明**：mock `demo-broker-platform` 为经纪业务系统，不做自营定价；故 SEC-09 在本项目无 evidence，归类 candidate。**owner 问题**：未来若新增期权 / 衍生品自营业务，SEC-09 必须重萃。

**Candidate 占位规则（不强制执行，仅供参考）**：

- 定价模型必须版本化与可回放（传入相同输入参数 + 同版本模型 → 输出确定）。
- 希腊字母（Delta/Gamma/Vega/Theta）计算精度与时延按交易类型分级（高频做市 < 100μs / 一般 < 10ms）。

### 6.10 灾备与稳定性 SEC-10 [baseline]

> dimension_id: SEC-10 · risk_tag: high · subdomain: core-securities · 命中信号: dr-naming（hit=true, Failover/MultiRegion）+ dr-modules（hit=true, server/disaster-recovery/）
> baseline 兜底原因：高风险维度，但本 PoC 项目未发现演练脚本（如 chaos engineering / DR drill），章节标 baseline + pending-confirmation。

**激活理由**：mock `server/disaster-recovery/FailoverController.java` 存在；但未发现 DR 演练自动化脚本或 chaos engineering 配置。

**强制规则**：

- RTO ≤ 60s；RPO ≤ 0（交易系统强一致）；其他系统 RPO ≤ 5min。
- 主备切换必须自动化 + 可人工 override；切换决策日志落 audit。
- 降级开关必须有灰度 + 一键回滚；降级期间客户可见公告必须由 SEC-06 报送链路同步监管。

**Pending-confirmation（owner 待确认）**：

- [ ] DR 演练频率（建议 ≥ 每季度一次主备切换演练）。
- [ ] 是否引入 chaos engineering（如 Chaos Monkey / 自研 fault injection）。

## 7. 核心维度 — 跨境证券（XSEC-01~XSEC-06）

### 7.1 跨时区与交易时段 XSEC-01 [baseline]

> dimension_id: XSEC-01 · risk_tag: high · combination: weighted threshold=2 · 评分 weight 1（zone-id-usage hit）→ partial → baseline 兜底
> rationale: 跨时区维度需 ZoneId 使用 + 隔夜挂单状态机交叉；本项目仅命中 `ZoneId.of("Asia/Hong_Kong")` 2 处（dst-handling 与 overnight-order 全 miss），不达 threshold=2。

**激活理由**：mock `app/hybrid/HKStockTradingPage.tsx` 中 `ZoneId.of("Asia/Hong_Kong")` 出现 2 次（用于显示交易时段）；未命中夏令时切换处理与隔夜挂单状态机。

**Baseline 必检事项（owner 待确认）**：

- [ ] 时间字段是否统一 UTC 存储 + 时区转换显示。
- [ ] 隔夜挂单（GTC + 美股 preMarket/afterHours）状态机是否完整。
- [ ] 夏令时切换日（每年 3 月第二个周日 / 11 月第一个周日 ET）是否有边界用例测试。
- [ ] 时区切换不丢单/不重单的回归测试是否覆盖。

### 7.2 多币种与外汇 XSEC-02 [activated]

> dimension_id: XSEC-02 · risk_tag: high · subdomain: cross-border · 命中信号: fx-naming（hit=true, FxRate/USD/HKD）+ fx-modules（hit=true, server/fx/）

**激活理由**：mock `server/fx/FxRateService.java` + `Currency` 枚举含 USD/HKD/CNY。

**强制规则**：

- 多币种账户必须按币种隔离（账户 schema 含 `currency` 字段且 not null）。
- 汇率快照口径：交易使用实时价；估值使用日终中间价；披露使用监管指定基准。
- 跨币种 PnL 计算必须使用统一汇率快照（同一交易日不允许混用不同时点汇率）。
- 结售汇额度按客户等级控制（个人 5 万美元/年；机构按 QDII 额度）。

### 7.3 跨境合规 XSEC-03 [baseline]

> dimension_id: XSEC-03 · risk_tag: high · combination: weighted threshold=2 · 评分 weight 2（cross-border-modules hit, weight=2）→ activated → baseline 强制兜底
> rationale: 跨境合规高风险，命中 weight=2 达阈值，但 W-8BEN 业务代码未命中，章节标 baseline 兼容兜底。

**激活理由**：mock `server/cross-border/qdii/` + `server/cross-border/northbound/` 模块齐全；`northboundQuota` 字段在 `OrderRequest` 中校验。

**强制规则**：

- QDII / 港股通 / 北上资金 / 美股通额度必须实时校验（不接受异步审批），额度不足必须前置拒单。
- 外管局申报数据必须按 T+1 自动生成（联动 SEC-06）；机构客户与个人客户口径不同必须区分。
- W-8BEN 表填写状态必须在账户开通流程中校验；未填或过期 → 美股交易功能必须禁用。
- 跨境数据出境必须经过白名单校验（GDPR/CCPA/中国数据出境规则联动 IND-02）。

### 7.4 跨境行情源 XSEC-04 [candidate]

> dimension_id: XSEC-04 · risk_tag: medium · subdomain: cross-border · 命中信号: market-source-naming（hit=true, HKEx 1 处）+ market-source-deps（hit=false）
> candidate hint: 当项目接入 NASDAQ/NYSE 直连或 Bloomberg/Refinitiv 数据源（grep 命中或依赖命中）时，自动升级为 activated。

**Candidate 状态说明**：mock 仅命中 `HKEx` 1 个关键词（在 `app/hybrid/HKStockMarketDataSource.kt` 注释中），未引入海外行情商 SDK；故归类 candidate。**owner 问题**：是否计划接入 NASDAQ/NYSE 行情？接入后此维度需重萃。

**Candidate 占位规则**：

- 行情授权与计费必须按用户分级精确对账。
- 跨境行情源切换路径必须有 fallback（主源失效切到备源 < 30s）。

### 7.5 交易规则差异 XSEC-05 [activated]

> dimension_id: XSEC-05 · risk_tag: high · subdomain: cross-border · 命中信号: market-rule-naming（hit=true, lotSize/tickSize/marginTrading）+ market-rule-modules（hit=true, server/us-stock/ + server/hk-stock/）

**激活理由**：mock `server/us-stock/UsTradingRules.java` + `server/hk-stock/HkLotSizeValidator.java`。

**强制规则**：

- A 股 T+1 不允许当日撤单后重报；港股 T+0 允许；美股盘前盘后允许限价单 → 必须在订单系统按市场分支处理。
- Lot size / tick size 必须从 `MarketRulesRegistry` 读取，不允许 hardcode。
- 美股 limit-on-close 等特殊订单类型必须在订单 schema 中显式建模（不能用通用 `LIMIT` + 时间标记伪装）。
- 各市场涨跌停与熔断规则差异：必须有差异表（A 股 ±10%/±5%/±20%；港股无涨跌停；美股按市场代码定义）。

### 7.6 跨境结算与税务 XSEC-06 [candidate]

> dimension_id: XSEC-06 · risk_tag: high · subdomain: cross-border · 命中信号: tax-naming（hit=true, 印花税 1 处）+ clearing-cross-border（hit=false）
> candidate hint: 当项目新增 1042-S/1099-DIV 美股税务报告或 DTCC/中国结算跨境清算路径时，自动升级 activated。

**Candidate 状态说明**：mock 仅命中 `印花税` 1 个港股相关关键词，未实现美股 1042-S / 1099-DIV 税务报告，未接入 DTCC 跨境清算。

**Candidate 占位规则**：

- 美股股息预扣税：默认 30% 预扣，签订 W-8BEN 后按税收协议优惠（如中国大陆居民 10%）。
- 港股印花税：买卖双方各 0.1%（自动计入交易费用）。
- 1042-S / 1099-DIV 税务报告必须按年度生成 + 推送给客户（联动 SEC-06）。

## 8. 数据流链路 [activated]

```text
行情源 → 行情网关 → 订阅引擎 → 订单簿 → 风控 → 撮合 → 回报 → 清算 → 账户 → 监管报送
              ↓                     ↓                ↓
           延迟监控               风控审计        WORM 存证
              ↓                                       ↓
           QuoteStaleEvent                    Regulatory Submit
```

跨境补充：港美股链路在订单簿前增加跨境合规校验（XSEC-03 额度 + W-8BEN 状态），在清算后增加外汇结算（XSEC-02）与跨境清算（XSEC-06）。

## 9. 错误模型 [activated]

| 错误类别 | 错误码前缀 | 必含字段 | 落 audit | 关联维度 |
| --- | --- | --- | --- | --- |
| 风控拒绝 | `RISK_REJECTED_*` | 拒绝原因 + 触发规则 ID + 客户 ID + 订单 ID | 是 | SEC-03 |
| 撮合失败 | `MATCH_FAILED_*` | 订单 ID + 时间戳 + 失败原因 | 是 | SEC-02 |
| 清算异常 | `CLEARING_DIFF_*` | 差异金额 + 差异方向 + 对账批次 | 是 | SEC-04 |
| 报送失败 | `REPORT_FAILED_*` | 报送任务 ID + 监管接口 + 重试次数 | WORM | SEC-06 |
| 跨境额度 | `QUOTA_EXCEEDED_*` | 额度类型 + 当前用量 + 客户 ID | 是 | XSEC-03 |
| 时区错误 | `TZ_MISMATCH_*` | 期望时区 + 实际时区 + 业务点 | 是 | XSEC-01 |

## 10. AI 生成要求 [activated]

- AI 生成证券订单代码必须使用 ISO 订单状态枚举（`NEW` / `PARTIALLY_FILLED` / ...），**禁止** 自定义中文/拼音/缩写字符串。
- 涉及风控的代码必须显式调用 `RiskControlService.preTradeCheck(...)`，不得绕过；即使是测试代码也必须用 mock 而非删除调用。
- 时区使用 IANA tz id（`ZoneId.of("America/New_York")` / `ZoneId.of("Asia/Hong_Kong")`），**禁止** `+08:00` 或 `GMT+8` 字面量。
- 涉及监管报送的字段（`regulatoryTag` / `audit_log_id` 等）**禁止** 在生成代码中省略或重命名。
- 跨境业务必须显式约束 tz / FX / 额度三件套；任一缺失 → AI 必须 reject 并提示 owner。

## 11. Review 检查项 [activated]

- [ ] 订单状态机覆盖全部 ISO/FIX 终态（含 `EXPIRED`）。
- [ ] 风控前置在撮合之前（pre-trade ≠ post-trade）。
- [ ] 监管报送字段不被脱敏；脱敏只发生在客户可见层。
- [ ] 跨境业务的 tz / FX / 额度均有显式约束。
- [ ] 行情失效（stale）时下游订单系统行为明确（拒单 or 降级）。
- [ ] DR 演练记录在最近 1 季度内。
- [ ] WORM 存证 hash 链可验证。
- [ ] 港美股 H5/RN 模块通过 `NativeBridge` 收口，未直接调用交易 SDK。

## 12. Evidence 参考 [activated]

> **PoC 提示**：以下 evidence 路径为合成 mock，详见 `evidence/code-facts.md`、`evidence/positive-examples.md`、`evidence/dimension-activation-report.json`。真实运行需替换为脱敏后的真实代码路径。

| evidence_id | 来源文件 | 核心观察 | 置信度 | 关联维度 |
| --- | --- | --- | --- | --- |
| `EV-IND-001` | `server/trading/OrderStatusMachine.java` | 状态机 6 终态完整 + FIX 兼容枚举 | high | SEC-02 |
| `EV-IND-002` | `server/market-data/Level2Snapshot.java` | Level2 + Tick 行情接入；订阅生命周期清晰 | high | SEC-01 |
| `EV-IND-003` | `server/regulatory/RegulatoryReportingJob.java` | `@RegulatoryReport` + WORM 落盘 | medium | SEC-06 |
| `EV-IND-004` | `server/risk-control/PreTradeRiskService.java` | 模块文件存在，但未引规则引擎 | low | SEC-03（partial → baseline） |
| `EV-IND-005` | `server/clearing/CcassReconciliation.java` | T+2 + CCASS 对账 | medium | SEC-04 |
| `EV-IND-006` | `server/account/kyc/SuitabilityAssessment.java` | C1~C5 风险等级问卷 | medium | SEC-05 |
| `EV-IND-007` | `server/trading-calendar/TradingCalendarService.java` | Singleton 全局唯一 + 节假日 JSON | medium | SEC-07 |
| `EV-IND-008` | `pom.xml` | `quickfixj-core:2.3.1` 依赖 | high | SEC-08 |
| `EV-IND-009` | `server/disaster-recovery/FailoverController.java` | 模块存在但无演练脚本 | low | SEC-10（baseline + pending） |
| `EV-IND-010` | `app/hybrid/HKStockTradingPage.tsx` | `ZoneId.of("Asia/Hong_Kong")` 2 处 | low | XSEC-01（baseline 兜底） |
| `EV-IND-011` | `server/fx/FxRateService.java` | 多币种 FxRate 接入 | medium | XSEC-02 |
| `EV-IND-012` | `server/cross-border/qdii/QdiiQuotaService.java` | QDII 额度模块齐全 | medium | XSEC-03（baseline 兜底） |
| `EV-IND-013` | `server/us-stock/UsTradingRules.java` | 美股交易规则差异 | medium | XSEC-05 |

## 13. 维度激活汇总 [baseline]

| 维度 | 名称 | 三态 | 命中 signal | 备注 |
| --- | --- | --- | --- | --- |
| SEC-01 | 行情系统 | activated | market-data-naming + market-data-deps | — |
| SEC-02 | 交易系统 | activated | order-state + trading-gateway | — |
| SEC-03 | 风控引擎 | baseline | risk-modules（weight 1, 不达阈值 2） | partial → baseline 兜底 |
| SEC-04 | 清算结算 | activated | clearing-naming + clearing-modules | — |
| SEC-05 | 账户与适当性 | activated | account-naming + kyc-modules | — |
| SEC-06 | 监管报送 | baseline | regulatory-modules + report-task + regulatory-tag（weight 4） | 高风险 baseline，章节兜底 |
| SEC-07 | 交易日历 | activated | trading-calendar + holiday-naming | — |
| SEC-08 | 接入协议 | activated | protocol-deps（quickfixj） | low-latency miss |
| SEC-09 | 金融工程 | candidate | 全 miss | 经纪业务暂不需要 |
| SEC-10 | 灾备与稳定性 | baseline | dr-naming + dr-modules（无演练脚本） | baseline + pending |
| XSEC-01 | 跨时区 | baseline | zone-id-usage（weight 1, 不达阈值 2） | partial → baseline 兜底 |
| XSEC-02 | 多币种与外汇 | activated | fx-naming + fx-modules | — |
| XSEC-03 | 跨境合规 | baseline | cross-border-modules（weight 2, 达阈值） | 高风险 baseline 强制 |
| XSEC-04 | 跨境行情源 | candidate | HKEx 1 处命中（不接入海外 SDK） | — |
| XSEC-05 | 交易规则差异 | activated | market-rule-naming + market-rule-modules | — |
| XSEC-06 | 跨境结算与税务 | candidate | 印花税 1 处命中（无 1042-S/1099-DIV） | — |

**汇总**：baseline=5；activated=8；candidate=3；partial_activated=0；pending-confirmation=0（baseline 内含 owner 待确认占位）；total=16 ✓

## 14. 未激活维度地图 [baseline]

> **owner 视角的"还需要做什么"清单**。candidate 维度若未来代码演进命中信号，自动升级 activated；baseline 兜底维度需要 owner 显式判定。

| 维度 | 当前态 | 升级条件 | owner 待确认问题 |
| --- | --- | --- | --- |
| SEC-03 | baseline | 引入 drools/easy-rules 规则引擎依赖（达 threshold=2） | 风控规则是否计划用规则引擎？还是继续硬编码？ |
| SEC-09 | candidate | 新增 `**/pricing/**` 或引入 quantlib/commons-math3 | 是否计划做自营定价/期权做市？ |
| SEC-10 | baseline | 新增 DR 演练脚本（chaos engineering / 自动化演练） | 演练频率与机制？ |
| XSEC-01 | baseline | 新增隔夜挂单状态机 + DST 切换处理（达 threshold=2） | 美股 GTC 订单是否纳入产品？ |
| XSEC-04 | candidate | 接入 NASDAQ/NYSE 直连或 Bloomberg/Refinitiv | 是否计划自建海外行情接入？ |
| XSEC-06 | candidate | 新增 1042-S/1099-DIV 报告 + DTCC 接入 | 美股税务报告是否产品化？ |

## 15. PoC 局限性与下一步 [baseline]

**已知局限性**：

- 全部 evidence 为 mock 合成，不能替代真实证券系统代码萃取；任何升级 active 都必须基于真实代码重萃。
- SEC-09 / XSEC-04 / XSEC-06 三个 candidate 维度尚无 evidence 支持，规则文本仅供参考。
- 风控（SEC-03）依赖 risk-control 模块文件存在但未发现规则引擎依赖；真实项目可能有自研引擎，需 owner 确认。
- DR 演练（SEC-10）模块存在但 PoC 未跑出演练脚本/chaos engineering 配置；owner 需确认演练频率与机制。

**下一步**：

1. 行业 owner 接到本 PoC 文档后，应在 1 周内对 14 个未激活维度逐一确认。
2. 在真实证券系统代码（脱敏）跑一次 phase 2 流水线，对比本 PoC 的三态分布。
3. 若真实跑出的活跃维度数与本 PoC 偏离超过 30%，需回炉 U4（骨架模板）+ U3（激活规则）调整。
4. 升级 `status: draft → active` 必须由行业 owner 在 `pending-confirmation.md` 签字确认。

## 16. 变更记录 [baseline]

| 版本 | 日期 | 作者 | 变更 |
| --- | --- | --- | --- |
| v0.1.0 | 2026-05-25 | leokuang（U18 PoC） | 首次 PoC 产出：SEC-01~10 + XSEC-01~06 全 16 维章节 + 三态激活汇总 + 未激活维度地图。evidence_tier=synthetic-poc，待真实代码萃取后升级。 |
