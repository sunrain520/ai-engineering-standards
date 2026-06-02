---
name: golden-sample-securities-run
description: 证券子领域设计样例：合成 demo-broker-platform 项目，仅演示 16 维激活机制（SEC-01~10 + XSEC-01~06）
type: example
phase: phase-2
run_id: 20260525-030800-industry
evidence_tier: synthetic-poc
validation_status: NOT_EVIDENCE
domain: 09-industry
sub_domain: securities
---

# Golden Sample — 证券子领域设计样例

> **说明**：本样例使用合成 mock 项目 `demo-broker-platform` 验证 16 维骨架 + 三态激活机制。
> 它只演示 intake → profile → dimension-activator → generation → review → merge 的目标形态,**不代表**真实 evidence、真实端到端跑批或团队规范。
> 真实运行参数与 evidence 需接入实际经纪平台代码后重跑。

---

## 一、输入参数

```yaml
project_paths:
  - /mock/demo-broker-platform          # 合成项目，含 Java Spring 后端 + KMP+Clean APP + React 管理后台 + H5/RN 跨端
extraction_mode: full
domain: 09-industry
sub_domain: securities
industry_scenario: securities-brokerage
run_mode: interactive
evidence_tier: synthetic-poc
poc_disclaimer: "all file paths, class names, signal hits are synthetic mock data for dimension framework validation only"
```

### 1.1 合成项目结构速览

```
demo-broker-platform/
├── backend/                        # Java Spring Boot 经纪业务后端
│   ├── order-service/
│   │   ├── OrderController.java
│   │   ├── OrderService.java
│   │   ├── OrderRepository.java
│   │   └── TradeValidator.java
│   ├── account-service/
│   │   ├── AccountService.java
│   │   ├── KYCValidator.java      # SEC-01 KYC 信号
│   │   └── AMLChecker.java        # SEC-01 AML 信号
│   ├── risk-service/
│   │   ├── RiskEngine.java        # SEC-05 风控引擎
│   │   └── PositionLimitChecker.java
│   ├── audit-service/
│   │   ├── AuditLogWriter.java    # SEC-07 审计日志信号
│   │   └── ImmutableAuditRecord.java
│   └── references/config/
│       ├── SecurityConfig.java    # SEC-02 权限信号
│       └── DataMaskConfig.java    # SEC-08 数据脱敏信号
├── shared/                        # KMP 共享层
│   ├── domain/
│   │   ├── OrderModel.kt
│   │   ├── AccountModel.kt
│   │   └── PortfolioModel.kt
│   ├── repository/
│   │   └── OrderRepository.kt
│   └── usecase/
│       └── PlaceOrderUseCase.kt
├── android/                       # Android 端（KMP+Clean架构）
│   └── feature/trade/
│       ├── TradeViewModel.kt
│       └── TradeScreen.kt
├── admin-frontend/                # React 管理后台
│   └── src/components/
│       └── PortfolioTable.tsx
├── hk-stock-h5/                   # 港股 H5 跨端（RN）
│   ├── src/
│   │   ├── screens/StockDetailScreen.tsx  # XSEC-02 港股 H5/RN 信号
│   │   └── NativeBridge.ts               # TurboModule/NativeBridge 收口
│   └── package.json
├── cross-border/                  # 跨境逻辑（XSEC 系列）
│   ├── currency/
│   │   └── FXRateService.java     # XSEC-02 多币种信号
│   └── settlement/
│       └── CrossBorderSettlement.java  # XSEC-03 跨境结算信号
└── docs/
    ├── architecture.md
    └── compliance-overview.md
```

---

## 二、阶段执行摘要

### Phase 1: Intake & Scope

**intake-and-scope agent 推断结果（免追问直接确认）：**

| 推断项 | 推断值 | 信心度 | 判断依据 |
| --- | --- | --- | --- |
| 域 | 09-industry / securities | HIGH | 目录含 order-service / KYCValidator / AMLChecker |
| 架构 | KMP+Clean + Spring 后端 + RN 跨端 | HIGH | shared/domain/ + android/ + hk-stock-h5/NativeBridge |
| 行业场景 | securities-brokerage（经纪，非自营） | HIGH | 无 pricing / market-making / greeks 模块 |
| 跨境 | 港股 + 多币种 + 跨境结算 | MEDIUM | hk-stock-h5/ + FXRateService + CrossBorderSettlement |
| 敏感文件 | references/config/*.properties（脱敏,只记录存在事实） | — | 规则:不读取 credentials 原值 |

**batch plan（全量模式 → 单 batch）：**

```yaml
batch_id: batch-01-securities-full
dimensions: [SEC-01, SEC-02, SEC-03, SEC-04, SEC-05, SEC-06, SEC-07, SEC-08, SEC-09, SEC-10, XSEC-01, XSEC-02, XSEC-03, XSEC-04, XSEC-05, XSEC-06]
estimated_evidence_files: 18
estimated_tokens: ~42K
```

### Phase 2: Dimension Activator

**dimension-activator 信号扫描 → 三态判定：**

| 维度 | 命中信号 | weight 合计 / threshold | 三态 | 说明 |
| --- | --- | --- | --- | --- |
| SEC-01 | KYCValidator, AMLChecker, aml-screening-service | — | **activated** | 双信号命中 |
| SEC-02 | SecurityConfig, RBAC, oauth2-resource-server | — | **activated** | 权限注解 + RBAC |
| SEC-03 | OrderService（无独立 quote-/trade- 模块隔离,无熔断关键字） | w=1 / threshold=2 | **baseline** | 加权不达,高风险兜底 |
| SEC-04 | OrderController + TradeValidator | — | **activated** | 委托撮合链路 |
| SEC-05 | RiskEngine, PositionLimitChecker | — | **activated** | 风控双信号 |
| SEC-06 | DataMaskConfig, idCardMask, bankAccountMask | w=4 / threshold=2 ✓ + 高风险强制 | **baseline** | 加权达阈 + 强制兜底 |
| SEC-07 | AuditLogWriter, ImmutableAuditRecord | — | **activated** | 审计日志双信号 |
| SEC-08 | DataMaskConfig, EncryptionUtil, PCI-DSS | — | **activated** | 加密+脱敏双链路 |
| SEC-09 | 无 pricing/market-making/greeks | — | **candidate** | 经纪业务不做自营定价 |
| SEC-10 | 无 disaster-recovery/ 或演练脚本 | — | **baseline** + pending | 无演练脚本,pending-confirmation |
| XSEC-01 | ZoneId.of("Asia/Hong_Kong")（单处） | w=1 / threshold=2 | **baseline** | 加权不达,高风险兜底 |
| XSEC-02 | StockDetailScreen.tsx, NativeBridge, RN 跨端 | — | **activated** | H5/RN 双信号 |
| XSEC-03 | CrossBorderSettlement, FXRateService | w=2 / threshold=2 ✓ | **baseline** | 加权达阈（无明细拆分规则证据,保 baseline） |
| XSEC-04 | 无具名行情源 SDK | — | **candidate** | 需接入 NASDAQ/Bloomberg/HKEX |
| XSEC-05 | FXRateService, CNY/HKD 兑换链路 | — | **activated** | 汇率兑换双信号 |
| XSEC-06 | 无 1042-S / DTCC 字段 | — | **candidate** | 无税务/交收对接证据 |

**三态分布：** baseline=5 / activated=8 / candidate=3 / total=16 ✓

### Phase 3: Generation（骨架填充）

**generation agent 选用 securities-skeleton.md 作为蓝本，完成以下操作：**

1. 读取 `assets/skeletons/industry/securities-skeleton.md`（254 行）
2. 替换 `[{{activation_state}}]` placeholder → 实际三态值
3. 对每个维度章节写入 `dimension_id` 元数据 blockquote + `signal_hits` + `depth_score`
4. 生成 §12 Evidence 参考（EV-IND-001~013 共 13 条证据）
5. 生成 §13 维度激活汇总表格
6. 生成 §14 未激活维度地图（6 条升级条件）
7. 生成 §15 PoC 局限性与下一步
8. 生成 `evidence/dimension-activation-report.json`（activation-report.v1 schema）

**产物文件清单：**

| 文件 | 状态 | 位置 |
| --- | --- | --- |
| `01-securities-standard.md` | CREATED | `engineering-standards/09-industry/` |
| `evidence/dimension-activation-report.json` | CREATED | `engineering-standards/09-industry/evidence/` |
| `overview.md`（含未激活地图） | UPDATED | `engineering-standards/09-industry/` |

### Phase 4: Review & Quality Gate

**review-and-quality-gate agent 设计态评分（双门禁示例,非真实 evidence）：**

```
门禁 A — 最低发布门禁（required: ALL pass）
  ✅ A1 结构完整性：16 维度章节均存在
  ✅ A2 三态状态机一致：每维度 [state] 与 activation-report.json dimensions[].state 一致
  ✅ A3 evidence_tier 标注：frontmatter 含 synthetic-poc + poc_disclaimer
  ✅ A4 pending-confirmation 引用正确：SEC-10 / SEC-03 pending 均有 owner_confirmations[]
  ✅ A5 候选升级条件清晰：candidate 维度均有 candidate_hint

门禁 B — 深度门禁（required: ≥70%）
  Coverage Reviewer:
    [+] 10 core-securities 维度全覆盖
    [+] 6 cross-border 维度全覆盖
    [-] evidence_tier=synthetic-poc（depth_score 上限 0.85）
    [-] 5 baseline 维度 depth_score < 0.6（weight 不达）
  B1 覆盖率：16/16 = 100% ✅
  B2 深度分：avg depth_score = 0.538 ⚠️（合成 PoC 预期，不阻塞 poc 产物）
  B3 无 real-evidence 规则混入 ✅（frontmatter 明确标注）

门禁结论：NOT_EVIDENCE（poc-draft 级别，不进 active 执行路径）
```

### Phase 5: Merge

**merge-coordinator 决策：**

```
目标目录：engineering-standards/09-industry/
现有文件状态：
  overview.md → 已存在（no-evidence）→ MERGE 更新子行业矩阵 + 未激活地图
  01-securities-standard.md → 不存在 → CREATE（新文件无冲突）
  evidence/dimension-activation-report.json → 不存在 → CREATE

merge-suggestions.md：无需新增（新文件,无相近规则冲突）
conflicts.md：无冲突（新域,无既有 owner-confirmed-active / legacy active 规则）
pending-confirmation.md：追加 SEC-10 演练脚本确认项 + SEC-03/XSEC-01 weighted 重新核查项
```

---

## 三、Quality Gate 决策摘要

```
run_id: 20260525-030800-industry
evidence_tier: synthetic-poc
质量门禁: NOT_EVIDENCE（poc-draft 级别）
发布状态: draft — 不可进默认执行路径

主要局限（PoC）：
  1. 所有 signal_hits 来自合成 mock，非真实代码扫描
  2. GitNexus 不可用（standalone PoC），fallback_used=true
  3. 5 个 baseline 维度 weighted threshold 未达，按高风险规则强制兜底

下一步（接入真实代码）：
  1. 提供真实经纪平台 project_paths
  2. 确保 GitNexus graph-bootstrap 完成（graph_readiness.state=ready）
  3. 重跑 extraction_mode=full + output_action=force-rebuild
  4. owner 确认 SEC-03 / SEC-10 / XSEC-01 pending 项后升级为 owner-confirmed-active
```

---

## 四、验证检查项

| 检查项 | 预期 | 实际 |
| --- | --- | --- |
| `01-securities-standard.md` 文件存在 | design sample | present |
| frontmatter `status: draft` | design sample | present |
| frontmatter `evidence_tier: synthetic-poc` | boundary marker | present |
| 16 维度章节均存在（SEC-01~10 + XSEC-01~06） | design sample | present |
| `[activation_state]` 均有实际值（无 placeholder） | design sample | present |
| 维度激活汇总表格 baseline=5/activated=8/candidate=3 | design sample | present |
| `dimension-activation-report.json` 存在 | schema sample | present |
| dimensions[] 数量 = 16 | schema sample | present |
| summary.total_dimensions = 16 | schema sample | present |
| `overview.md` 含"未激活维度地图"章节 | design sample | present |
| 6 条升级条件清晰描述 | design sample | present |
| GitNexus fallback 路径记录在 activation-report.json | fallback sample | present |
| 路径落在 09-industry/（以当前仓库真实目录为准） | code-is-truth | present |

---

## 五、与其他样例的对比

| 样例 | 域 | extraction_mode | evidence_tier | 维度数 | 关键特性验证 |
| --- | --- | --- | --- | --- | --- |
| `golden-sample-run.md` | 01-app-client | full | real-evidence | — | 基础闭环 |
| `thin-dogfood-run.md` | 01-app-client | profile-first | real-evidence | — | 轻量画像 |
| `force-rebuild-walkthrough.md` | 01-app-client | force-rebuild | real-evidence | — | safeguard + atomic rollback |
| **本文件** | **09-industry** | **full** | **synthetic-poc** | **16** | **三态激活 + 证券 PoC + GitNexus fallback** |

---

## 六、相关文档

- `engineering-standards/09-industry/01-securities-standard.md` — PoC 产物
- `engineering-standards/09-industry/evidence/dimension-activation-report.json` — 激活报告
- `engineering-standards/09-industry/overview.md` — 未激活维度地图
- `skills/project-standard-extractor/assets/skeletons/industry/securities-skeleton.md` — 骨架蓝本
- `skills/project-standard-extractor/references/config/dimension-framework/dimensions-industry-securities.yaml` — 维度定义
- `skills/project-standard-extractor/references/config/dimension-framework/activation-rules-industry.yaml` — 激活规则
