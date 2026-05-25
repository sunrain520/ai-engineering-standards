---
doc_id: industry-overview
domain: 09-industry
status: draft
sub_domain: industry-portfolio
ai_consumption_priority: high
last_updated: 2026-05-25
owner: leokuang
evidence_tier: synthetic-poc
---

# 行业规范概览

本目录沉淀证券、信贷、银行等跨研发域行业规范。行业规则用于补充研发域规范,不替代 APP、前端、后端、PC 的架构规则。

## 1. 为什么独立成目录

行业规则跨多个研发域使用,需要独立 owner、独立 AI 输入入口和清晰发现路径。相比放入 `00-global/industry-risk/` 或挂在各端目录下,独立目录能减少重复维护和规则混淆。

## 2. 子行业覆盖矩阵

| 子行业 | 状态 | 维度激活情况 | 下一步 |
| --- | --- | --- | --- |
| Securities | poc-synthetic | 16 维(SEC-01~10 + XSEC-01~06):baseline=5 / activated=8 / candidate=3 | 接入真实经纪平台代码后重跑,见 `01-securities-standard.md` §15 |
| Credit | no-evidence | — | 提供项目路径后萃取 |
| Banking | no-evidence | — | 提供项目路径后萃取 |
| Risk Control | no-evidence | — | 提供项目路径后萃取 |
| Compliance | no-evidence | — | 提供项目路径后萃取 |
| Transaction Safety | no-evidence | — | 提供项目路径后萃取 |

## 3. 未激活维度地图

下列维度在已萃取子行业中未达到 `activated`,但仍是 AI 默认应该警觉的盲区。一旦项目侧出现升级条件,应触发重萃取并升级状态。

| 维度 ID | 名称 | 当前状态 | 升级条件(出现以下证据即应升级) | 跟踪文件 |
| --- | --- | --- | --- | --- |
| SEC-03 | 行情/交易接入与故障域隔离 | baseline(weighted threshold=2 未达) | (a) 出现独立 `quote-` / `trade-` 模块,且 (b) 命中熔断/降级关键字(circuit-breaker / rate-limit / fallback) | `01-securities-standard.md` §6.3 / `evidence/dimension-activation-report.json#SEC-03` |
| SEC-09 | 自营做市与定价(基差/Greeks) | candidate(经纪业务不做自营定价) | 出现 `pricing` / `market-making` / `greeks` 模块 + 风险敞口风控字段 | `01-securities-standard.md` §6.9 |
| SEC-10 | 灾备与切换演练 | baseline + pending-confirmation(无演练脚本) | (a) `disaster-recovery/` 目录,或 (b) `runbook.md` / `failover-script.sh` 等可执行演练材料 | `01-securities-standard.md` §6.10 / `pending-confirmation.md` |
| XSEC-01 | 跨境数据流向与时区合规 | baseline(zone-id 使用 weight=1 未达 weight=2) | (a) 跨境数据出境链路代码 + (b) `compliance` / `gdpr` / `pipl` 关键字命中 | `01-securities-standard.md` §7.1 |
| XSEC-04 | 美股/港股行情源接入(NASDAQ / Bloomberg / 港交所) | candidate | 出现具名行情源 SDK 或 vendor 适配器(NASDAQ / Bloomberg / HKEX feed) | `01-securities-standard.md` §7.4 |
| XSEC-06 | 美股税务与跨境交收(1042-S / DTCC) | candidate | 出现税务字段(`tax_form_1042s` / `dividend_withholding`)或交收对接(`dtcc_*`) | `01-securities-standard.md` §7.6 |

## 4. 当前使用边界

- 当前 `01-securities-standard.md` 是 **synthetic-poc** 产物(`evidence_tier: synthetic-poc`),用于验证 16 维骨架 + 三态激活机制;**不是** real-evidence 团队规范。
- AI 在 `evidence_tier=synthetic-poc` 文档下提示的规则只能作为 advisory hint,不进默认执行边界。
- 真实行业规范产出后,本表"维度激活情况"列从 `poc-synthetic` 升级为 `evidence-backed`,并由领域负责人将 `01-securities-standard.md` 状态从 `draft` 升级为 `active`(见 `engineering-standards/00-global/rule-lifecycle.md`)。
- 跨子行业冲突归并到 `engineering-standards/00-global/` 通则;**本目录内** `merge-suggestions.md` / `conflicts.md` 只处理本子行业自身。

## 5. 相关文档索引

| 想知道 | 看这里 |
| --- | --- |
| Securities PoC 16 维端到端产物 | `01-securities-standard.md` |
| Securities 维度激活报告 JSON | `evidence/dimension-activation-report.json` |
| 三态激活机制原理 | `skills/project-standard-extractor/config/dimension-framework/dimensions-industry-securities.yaml` |
| 行业骨架蓝本 | `skills/project-standard-extractor/templates/skeletons/industry/securities-skeleton.md` |
| 维度激活规则 | `skills/project-standard-extractor/config/dimension-framework/activation-rules-industry.yaml` |
| PoC 跑批样例 | `skills/project-standard-extractor/examples/phase-2/golden-sample-securities-run.md` |
