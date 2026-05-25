---
name: cross-project-cases
description: 跨项目对比评估场景：AE15（unified-activation-map 合并）/ AE11（跨项目发现新信号）
type: evals
phase: phase-2
ae: [AE15, AE11]
---

# Cross-Project Cases

## CPC-001 — AE15: 跨项目 unified-activation-map 合并正确

**Given**

```yaml
project_paths:
  - /mock/project-a           # 港股经纪 APP（KMP+Android）
  - /mock/project-b           # 美股 H5 跨端（RN + 跨境结算）
per_project_activation:
  project_a:
    EA-Client-01: activated
    EA-Client-02: activated
    SEC-01: activated
    SEC-03: baseline
    XSEC-01: baseline
    XSEC-02: candidate        # 港股 RN（project-a 无 H5）
  project_b:
    EA-Client-01: activated
    XSEC-01: activated        # 美股有完整跨境数据合规链路
    XSEC-02: activated        # 美股 H5 命中
    XSEC-04: candidate        # 美股行情源（Bloomberg 适配中）
    SEC-03: activated         # 美股有 circuit-breaker 模块
```

**When**

cross-project-aggregator 合并两个项目的 per-project activation map → unified-activation-map。

**Then**

合并规则：同一维度取"最高状态"（activated > baseline > candidate），有冲突时记录 `evidence_source`：

| 维度 | project-a | project-b | unified | 依据 |
| --- | --- | --- | --- | --- |
| EA-Client-01 | activated | activated | activated | 一致 |
| EA-Client-02 | activated | — | activated | 仅 a,保留 |
| SEC-01 | activated | — | activated | 仅 a,保留 |
| SEC-03 | baseline | activated | **activated** | b 更高,升级 |
| XSEC-01 | baseline | activated | **activated** | b 更高,升级 |
| XSEC-02 | candidate | activated | **activated** | b 更高,升级 |
| XSEC-04 | — | candidate | candidate | 仅 b,保留 |

- `unified-activation-map.json` 中 `SEC-03.state = "activated"`,`evidence_source = ["project-b"]`
- `XSEC-01.state = "activated"`,`evidence_source = ["project-b"]`（project-a 的 baseline 不降级 unified）
- 无维度被降级（合并只升不降）
- `cross_project.enabled = true`,`project_count = 2`

**回归断言**

```bash
jq '.cross_project.enabled' report.json | grep -q 'true'
jq '.dimensions[] | select(.id=="SEC-03") | .state' unified-map.json | grep -q "activated"
jq '.dimensions[] | select(.id=="XSEC-01") | .state' unified-map.json | grep -q "activated"
```

---

## CPC-002 — AE11: 跨项目对比发现新信号 → 更新激活状态

**Given**

```yaml
prior_activation:
  XSEC-05: baseline   # 上次运行仅 project-a（汇率兑换信号 weight=1）
new_project_added: /mock/project-b
project_b_signals:
  - id: fx-rate-multi-currency
    weight: 2
    match_count: 3    # FXRateService + CNY/HKD 双路径
```

**When**

cross-project-aggregator 发现 project-b 为 XSEC-05 新增 weight=2 信号,合并后 weight=3 ≥ threshold=2。

**Then**

- `XSEC-05.state` 从 `baseline` 升级为 `activated`（combined weight 超过阈值）
- `evolution.transitions[]` 记录该升级：`{dimension_id: "XSEC-05", state_before: "baseline", state_after: "activated", reason: "cross-project combined weight exceeded threshold", triggered_by: "project-b"}`
- `generation agent` 被触发重新生成 XSEC-05 规则正文（从骨架 → 完整规则）
- 用户收到通知："XSEC-05 汇率合规因跨项目合并升级为 activated"

**回归断言**

```bash
jq '.evolution.transitions[] | select(.dimension_id=="XSEC-05") | .state_after' report.json | grep -q "activated"
jq '.evolution.transitions[] | select(.dimension_id=="XSEC-05") | .triggered_by' report.json | grep -q "project-b"
```
