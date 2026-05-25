---
doc_id: "industry-securities-standard"
title: "证券业务规范"
domain: "industry"
sub_domain: "securities"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["industry", "securities", "trading", "compliance"]
---

# 证券业务规范

<!-- 写作说明（生成时删除）
- 本骨架是行业 industry/securities 专用长文,在通用 sub-domain-skeleton 12 节基础上扩展核心维度章节:
  §6.1–§6.10 = SEC-01~SEC-10
  §7.1–§7.6  = XSEC-01~XSEC-06
- 每条核心维度章节标题旁带 `[{{activation_state}}]` 占位符,落盘时由 generation agent 替换。
- 跨境合规 / 风控 / 监管报送 / 时区 这四类高风险维度在 activation-rules 中是 weighted+threshold,落盘 metadata 必须保留 rationale。
-->

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`securities`
- 端类型:`industry`(贯穿 backend / app-client / frontend 各端)
- 子领域信号:`core-securities` / `cross-border`
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:行情、交易、风控、清算结算、账户与适当性、监管报送、跨境合规等业务规则。
**不应承载**:通用 Web / 业务无关的 CRUD 模板、非证券领域逻辑。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
{module}/
├── trading/
├── market-data/
├── risk/
├── clearing/
├── account/
├── regulatory/
├── compliance/
├── cross-border/
└── fx/
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| 行情 (market-data) | 实时 / 历史行情数据接入 | 业务规则混入 |
| 交易 (trading) | 报单 / 撤单 / 成交回报 | 行情订阅 |
| 风控 (risk) | 事前 / 事中风控 | 业务路由 |
| 清算 (clearing) | 资金 / 头寸结算 | 实时交易撮合 |
| 账户 (account) | 适当性 / KYC / 保证金 | 行情广播 |
| 监管 (regulatory) | 报送任务 / WORM 存储 | 业务事务 |

## 5. 命名规范 [{{activation_state_section_5}}]

- 订单状态枚举使用 ISO 标准:`NEW` / `PARTIALLY_FILLED` / `FILLED` / `CANCELED` / `REJECTED`
- 时区 ID 使用 `ZoneId.of("America/New_York")` 等 IANA 标准,**禁止** 使用 GMT 偏移字面量
- 监管报送字段使用 `regulatory_*` 前缀

## 6. 核心维度 - 国内证券 (SEC-01~SEC-10)

### 6.1 行情数据 SEC-01 [{{activation_state_SEC_01}}]

> dimension_id: SEC-01 · risk_tag: high · subdomain: core-securities · 命中信号: market-data-naming / market-data-deps

- 实时与历史行情接入(Level1 / Level2 / Snapshot)
- 行情订阅 / 退订协议(组播 / 长连接)
- 行情失效与重连策略
- {{sec_01_rules}}

### 6.2 报单与成交 SEC-02 [{{activation_state_SEC_02}}]

> dimension_id: SEC-02 · risk_tag: high · subdomain: core-securities · 命中信号: order-state / trading-gateway

- 订单状态机(NEW / PARTIALLY_FILLED / FILLED / CANCELED / REJECTED)
- 单类型与有效期(LIMIT / MARKET / FOK / IOC / GTC)
- 撤单与改单流程
- {{sec_02_rules}}

### 6.3 风控引擎 SEC-03 [{{activation_state_SEC_03}}]

> dimension_id: SEC-03 · risk_tag: high · subdomain: core-securities · combination: weighted threshold=2
> rationale: 风控为证券高风险维度,要求规则引擎依赖 + 业务实现交叉,避免仅 starter jar 即激活

- 事前风控:仓位 / 自成交 / 异常报单 / 反洗钱
- 事中风控:撮合阶段 RSI / 风险敞口
- 事后风控:对账与异常追溯
- {{sec_03_rules}}

### 6.4 清算结算 SEC-04 [{{activation_state_SEC_04}}]

> dimension_id: SEC-04 · risk_tag: high · subdomain: core-securities · 命中信号: clearing-naming / clearing-modules

- T+0 / T+1 / T+2 结算周期
- CCASS / DTCC / 中国结算 接入
- 资金 / 头寸对账
- {{sec_04_rules}}

### 6.5 账户与适当性 SEC-05 [{{activation_state_SEC_05}}]

> dimension_id: SEC-05 · risk_tag: high · subdomain: core-securities · 命中信号: account-naming / kyc-modules

- KYC / 适当性测评流程
- 账户类型(普通 / 融资融券 / 期权 / 北上)
- 客户分级与风险匹配
- {{sec_05_rules}}

### 6.6 监管报送 SEC-06 [{{activation_state_SEC_06}}]

> dimension_id: SEC-06 · risk_tag: high · combination: weighted threshold=2
> rationale: 监管报送涉及不可篡改存证与时效约束,单一 audit 字段不足以覆盖;要求模块 + 报送任务 + 标签注入交叉

- 报送任务调度与失败重试
- WORM 存储与不可篡改证据链
- 报送数据脱敏与字段一致性
- {{sec_06_rules}}

### 6.7 交易日历 SEC-07 [{{activation_state_SEC_07}}]

> dimension_id: SEC-07 · risk_tag: medium · subdomain: core-securities · 命中信号: trading-calendar / holiday-naming

- 交易日 / 节假日 / 半日市判定
- 盘前 / 盘中 / 盘后 / 集合竞价时段
- 临时停牌与紧急休市
- {{sec_07_rules}}

### 6.8 行情 / 交易协议 SEC-08 [{{activation_state_SEC_08}}]

> dimension_id: SEC-08 · risk_tag: high · subdomain: core-securities · 命中信号: protocol-deps / low-latency-naming

- FIX / CTP / 自定义二进制协议
- 低延迟接入(RDMA / kernel-bypass / shared-memory)
- 网关心跳 / 重连 / 序号管理
- {{sec_08_rules}}

### 6.9 定价与风险计量 SEC-09 [{{activation_state_SEC_09}}]

> dimension_id: SEC-09 · risk_tag: medium · subdomain: core-securities · 命中信号: pricing-naming / numerics-deps

- 衍生品定价(Black-Scholes / Monte Carlo)
- Greeks(Delta / Gamma / Vega) 计算
- VaR / 压力测试
- {{sec_09_rules}}

### 6.10 容灾与多活 SEC-10 [{{activation_state_SEC_10}}]

> dimension_id: SEC-10 · risk_tag: high · subdomain: core-securities · 命中信号: dr-naming / dr-modules

- 主备切换 / 同城双活 / 异地多活
- RPO / RTO 指标与演练
- 故障转移自动化与回切
- {{sec_10_rules}}

## 7. 核心维度 - 跨境证券 (XSEC-01~XSEC-06)

### 7.1 跨时区 XSEC-01 [{{activation_state_XSEC_01}}]

> dimension_id: XSEC-01 · risk_tag: high · combination: weighted threshold=2
> rationale: 跨时区维度需 ZoneId 使用 + 隔夜挂单状态机交叉,单一 ZoneId 调用可能仅展示用,未触及交易状态机

- ZoneId 使用规范(IANA tz)
- DST 夏令时切换处理
- 隔夜挂单 / 盘前盘后状态机
- {{xsec_01_rules}}

### 7.2 外汇换算 XSEC-02 [{{activation_state_XSEC_02}}]

> dimension_id: XSEC-02 · risk_tag: high · subdomain: cross-border · 命中信号: fx-naming / fx-modules

- 实时 / 结算汇率源
- 换算精度与四舍五入策略
- 结售汇额度
- {{xsec_02_rules}}

### 7.3 跨境合规 XSEC-03 [{{activation_state_XSEC_03}}]

> dimension_id: XSEC-03 · risk_tag: high · combination: weighted threshold=2
> rationale: 跨境合规涉及监管申报与额度,单一关键词易误命中(如 W-8BEN 文档),要求模块 + 业务代码交叉

- QDII / 北向 / 南向通额度管理
- W-8BEN / W-8 申报
- 外管局 / SEC / FINRA 报送
- {{xsec_03_rules}}

### 7.4 跨境行情源 XSEC-04 [{{activation_state_XSEC_04}}]

> dimension_id: XSEC-04 · risk_tag: medium · subdomain: cross-border · 命中信号: market-source-naming / market-source-deps

- HKEx / NASDAQ / NYSE / 海外交易所行情接入
- Bloomberg / Refinitiv / Wind 数据源
- 行情授权与计费
- {{xsec_04_rules}}

### 7.5 市场规则差异 XSEC-05 [{{activation_state_XSEC_05}}]

> dimension_id: XSEC-05 · risk_tag: high · subdomain: cross-border · 命中信号: market-rule-naming / market-rule-modules

- 最小交易单位 (lotSize) / tickSize 差异
- 限价 / 集合竞价 / 做空 / 融资规则
- 各市场涨跌停与熔断
- {{xsec_05_rules}}

### 7.6 跨境税收清算 XSEC-06 [{{activation_state_XSEC_06}}]

> dimension_id: XSEC-06 · risk_tag: high · subdomain: cross-border · 命中信号: tax-naming / clearing-cross-border

- 1042-S / 1099-DIV 表单
- 印花税 / 利息税 / 红利税预提
- DTCC / CCASS / 中国结算 跨境清算
- {{xsec_06_rules}}

## 8. 数据流链路 [{{activation_state_section_8}}]

```text
行情源 → 行情网关 → 订单簿 → 风控 → 撮合 → 清算 → 账户 → 报送
```

## 9. 错误模型 [{{activation_state_section_9}}]

- 风控拒绝:`RISK_REJECTED_*` 错误码,必须含拒绝原因 + 触发规则 ID
- 撮合失败:`MATCH_FAILED_*`,需带订单 ID 与时间戳
- 报送失败:`REPORT_FAILED_*`,必须落 WORM 存储

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成证券代码必须使用 ISO 订单状态枚举,**禁止** 自定义字符串
- 涉及风控的代码必须显式调用 `RiskControlService`,不得绕过
- 时区使用 IANA tz,**禁止** 使用 `+08:00` 偏移字符串

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] 订单状态机覆盖全部 ISO 终态
- [ ] 风控前置在撮合之前
- [ ] 监管报送字段不被脱敏
- [ ] 跨境业务的 tz / FX / 额度均有显式约束

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-IND-{{N}}` | `**/{trading,risk,clearing,regulatory}/**` | {{core_observation}} | {{confidence}} |
