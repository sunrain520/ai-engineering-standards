# Dimension Framework Eval Cases

> 维度框架(phase 2)新增 / 扩展的回归用例索引。本目录与 `../trigger-cases.md` / `../boundary-cases.md` / `../failure-cases.md` 并列,但只覆盖 phase 2 引入的能力。

## 文件清单

| 文件 | 覆盖 AE | 场景数 |
| --- | --- | --- |
| `force-rebuild-cases.md` | AE23 / AE24 / AE25 | 9 |
| `three-state-cases.md` | AE7 / AE8 / AE10 | 3 |
| `activation-signal-cases.md` | AE9 / AE18 | 2 |
| `end-adapter-dispatch-cases.md` | AE17 | 1 |
| `gitnexus-cases.md` | AE12 / AE13 | 2 |
| `incremental-mode-cases.md` | AE14 | 1 |
| `cross-project-cases.md` | AE15 / AE11 | 2 |
| `orchestration-cases.md` | AE16 / AE19 / AE20 | 3 |
| `industry-coexist-cases.md` | AE21 | 1 |
| `securities-poc-cases.md` | AE22 | 1 |
| `doc-source-cases.md` | EA-Doc（DSC-A~H，U27）| 8 |

## AE → Case 完整映射（AE7–AE25）

| AE | 描述 | Case ID | 文件 |
| --- | --- | --- | --- |
| AE7 | baseline 维度不进 AI 默认执行路径 | TSC-001 | `three-state-cases.md` |
| AE8 | candidate 维度有明确升级条件 | TSC-002 | `three-state-cases.md` |
| AE9 | 激活信号命中 → activated | ASC-001 | `activation-signal-cases.md` |
| AE10 | 无 evidence → candidate，不强制生成 | TSC-003 | `three-state-cases.md` |
| AE11 | 跨项目对比发现新信号 → 更新激活状态 | CPC-002 | `cross-project-cases.md` |
| AE12 | GitNexus 可用 → 消费 graph-facts.json | GNC-001 | `gitnexus-cases.md` |
| AE13 | GitNexus 不可用 → fallback,记录 limitations | GNC-002 | `gitnexus-cases.md` |
| AE14 | diff 模式 → 只重评受影响维度 | IMC-001 | `incremental-mode-cases.md` |
| AE15 | 跨项目 unified-activation-map 合并正确 | CPC-001 | `cross-project-cases.md` |
| AE16 | quality-gate PASS 路径正确 | ORC-001 | `orchestration-cases.md` |
| AE17 | 端 adapter dispatch 按 sub_domain 选骨架 | EAD-001 | `end-adapter-dispatch-cases.md` |
| AE18 | weighted threshold 不达 → baseline 兜底(高风险) | ASC-002 | `activation-signal-cases.md` |
| AE19 | quality-gate FAIL → 不进 merge | ORC-002 | `orchestration-cases.md` |
| AE20 | merge-coordinator 三态汇总正确 | ORC-003 | `orchestration-cases.md` |
| AE21 | 行业规范与端规范共存,不冲突覆盖 | ICC-001 | `industry-coexist-cases.md` |
| AE22 | 证券 PoC 端到端激活报告与骨架一致 | SPC-001 | `securities-poc-cases.md` |
| AE23 | 完整 force-rebuild 成功路径 | FRC-001 | `force-rebuild-cases.md` |
| AE24 | Quality Gate 失败 → atomic rollback(无残留) | FRC-002 | `force-rebuild-cases.md` |
| AE25 | 互斥校验:R91/R92 / 强制边界 #9/#10 | FRC-003 | `force-rebuild-cases.md` |

## 共通验收

每个 case 必须能被 `../expected-behavior.md` 的"输出结构 / 状态边界 / 安全 / Append-only"清单匹配。

## 引用

- `references/agents/backup-manager.md`(决策算法 12 步)
- `references/prompts/orchestrator/force-rebuild/`（force-rebuild / changelog-append）
- `scripts/force-rebuild-validate.sh`（4 项确定性 check + JSON 输出）
- `references/quality-gate.md §5.5`（force-rebuild 模式双门禁）
- `references/config/dimension-framework/` (维度定义 + 激活规则)
