---
name: securities-poc-cases
description: 证券 PoC 评估场景：AE22 真实 evidence 门槛与 synthetic-poc 降级
type: evals
phase: phase-2
ae: [AE22]
---

# Securities PoC Cases

## SPC-001 — AE22: synthetic-poc 不得作为真实端到端 evidence

**Given**

```yaml
run_id: 20260525-030800-industry
domain: 09-industry
sub_domain: securities
evidence_tier: synthetic-poc
project: /mock/demo-broker-platform
expected_eval_status: NOT_EVIDENCE
expected_activation:
  total_dimensions: 16
  baseline: [SEC-03, SEC-06, SEC-10, XSEC-01, XSEC-03]
  activated: [SEC-01, SEC-02, SEC-04, SEC-05, SEC-07, SEC-08, XSEC-02, XSEC-05]
  candidate: [SEC-09, XSEC-04, XSEC-06]
artifacts:
  - engineering-standards/09-industry/01-securities-standard.md
  - engineering-standards/09-industry/evidence/dimension-activation-report.json
  - engineering-standards/09-industry/overview.md
```

**When**

对已产出的 PoC artifacts 执行边界验证。该验证只允许证明设计样例自洽，不允许把 AE22 标成 `PASS`。

**Then**

**T1 — 文件存在性**

```bash
[ -f engineering-standards/09-industry/01-securities-standard.md ]
[ -f engineering-standards/09-industry/evidence/dimension-activation-report.json ]
[ -f engineering-standards/09-industry/overview.md ]
```

**T2 — activation-report.json 维度数**

```bash
jq '.summary.total_dimensions' dimension-activation-report.json | grep -q "^16$"
jq '.summary.baseline_count' dimension-activation-report.json | grep -q "^5$"
jq '.summary.activated_count' dimension-activation-report.json | grep -q "^8$"
jq '.summary.candidate_count' dimension-activation-report.json | grep -q "^3$"
jq '.dimensions | length' dimension-activation-report.json | grep -q "^16$"
```

**T3 — 骨架与报告三态一致**

每个维度：`standard.md` 中的 `[activation_state]` 内联标注必须与 `dimensions[].state` 一致。

验证脚本逻辑（伪代码）：

```bash
for dim_id in SEC-{01..10} XSEC-{01..06}; do
  # 从 report 获取期望 state
  expected=$(jq -r --arg id "$dim_id" '.dimensions[] | select(.dimension_id==$id) | .state' report.json)
  # 从 standard.md 获取实际 [state]
  actual=$(grep -A2 "dimension_id: $dim_id" 01-securities-standard.md | grep -oP '\[(activated|baseline|candidate)\]' | tr -d '[]')
  [ "$expected" = "$actual" ] || echo "MISMATCH: $dim_id expected=$expected actual=$actual"
done
```

**T4 — 高风险 baseline 兜底验证**

```bash
# SEC-03 / SEC-06 / SEC-10 / XSEC-01 / XSEC-03 均为 baseline
for dim in SEC-03 SEC-06 SEC-10 XSEC-01 XSEC-03; do
  jq -r --arg id "$dim" '.dimensions[] | select(.dimension_id==$id) | .state' report.json | grep -q "baseline" || echo "FAIL: $dim not baseline"
done
```

**T5 — candidate 维度有升级条件**

```bash
for dim in SEC-09 XSEC-04 XSEC-06; do
  jq -r --arg id "$dim" '.dimensions[] | select(.dimension_id==$id) | .candidate_hint' report.json | grep -qv "^null$" || echo "FAIL: $dim missing candidate_hint"
done
```

**T6 — overview.md 含未激活地图**

```bash
grep -q "未激活维度地图\|Unactivated Dimension Map" overview.md
# 6 个未激活维度行
dim_count=$(grep -cP "SEC-03|SEC-09|SEC-10|XSEC-01|XSEC-04|XSEC-06" overview.md)
[ "$dim_count" -ge 6 ] || echo "FAIL: 未激活地图不完整"
```

**T7 — synthetic-poc 边界标注**

```bash
grep -q "evidence_tier.*synthetic-poc\|synthetic-poc" 01-securities-standard.md
grep -q "poc_disclaimer" 01-securities-standard.md
grep -q "synthetic-poc\|evidence_tier" overview.md
```

**T8 — GitNexus fallback 记录**

```bash
jq '.gitnexus_readiness.state' report.json | grep -q '"unavailable"'
jq '.gitnexus_readiness.fallback_used' report.json | grep -q 'true'
```

**全量通过标准**：T1~T8 全部满足时，SPC-001 = `NOT_EVIDENCE`；只有输入切换为真实或批准脱敏证券项目，并保留实际命令、输入路径、valid `activation-report.v1`、生成产物和 owner review 记录后，AE22 才可升级为 `PASS`。

## SPC-002 — AE22: 真实或脱敏证券输入缺失时保持 blocked

**Given**

```yaml
real_or_sanctioned_redacted_project: null
synthetic_poc_available: true
```

**Then**

- eval status = `BLOCKED`
- `01-securities-standard.md` 可保留为 draft / design sample
- 不得把 synthetic evidence 写入 active 标准或 owner-approved evidence
