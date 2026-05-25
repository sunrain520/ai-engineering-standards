---
name: activation-signal-cases
description: 激活信号评估场景：AE9（信号命中 → activated）/ AE18（weighted threshold 不达 → baseline 兜底）
type: evals
phase: phase-2
ae: [AE9, AE18]
---

# Activation Signal Cases

## ASC-001 — AE9: 激活信号命中 → activated

**Given**

```yaml
domain: 01-app-client
dimension_id: EA-Client-01
activation_rule:
  combination: any
  signals:
    - id: kmp-shared-module
      pattern: "shared/domain/**/*.kt"
    - id: kmp-datasource-impl
      pattern: "shared/data/**Repository*.kt"
project_structure:
  - shared/domain/OrderModel.kt        # 命中 kmp-shared-module
  - shared/data/OrderRepositoryImpl.kt # 命中 kmp-datasource-impl
```

**When**

dimension-activator 扫描 `project_paths` 并比对 `activation-rules-app-client.yaml#EA-Client-01`。

**Then**

- `EA-Client-01.state = "activated"`
- `signals_evaluated` 中 `kmp-shared-module.hit = true` 且 `kmp-datasource-impl.hit = true`
- `evidence_count ≥ 2`
- `depth_score ≥ 0.7`（双信号深度指标）
- generation agent 为 EA-Client-01 生成完整规则正文（非占位骨架）
- 产物 `standard-kmp-shared.md` 中 EA-Client-01 节含 `[activated]` 标注

**回归断言**

```bash
jq '.dimensions[] | select(.dimension_id=="EA-Client-01") | .state' report.json | grep -q "activated"
jq '.dimensions[] | select(.dimension_id=="EA-Client-01") | .evidence_count' report.json | grep -qE "^[2-9]|^[1-9][0-9]"
```

---

## ASC-002 — AE18: weighted threshold 不达 → baseline 兜底（高风险维度）

**Given**

```yaml
domain: 09-industry
dimension_id: SEC-03
activation_rule:
  combination: weighted
  threshold: 2
  signals:
    - id: circuit-breaker-pattern
      weight: 2
      pattern: "(circuit.breaker|CircuitBreaker|resilience4j)"
    - id: isolated-quote-trade-module
      weight: 2
      pattern: "(quote-service|trade-service)/"
    - id: rate-limit-fallback
      weight: 1
      pattern: "(RateLimiter|fallback|degrade)"
  high_risk_fallback: baseline   # SEC-03 属高风险维度,weighted 不达也必须保 baseline
project_signal_hits:
  - id: rate-limit-fallback
    weight: 1
    match_count: 1
    # weight 合计 = 1,未达 threshold=2
```

**When**

dimension-activator 评估 SEC-03:weight 合计 = 1 < threshold=2,触发 `high_risk_fallback=baseline`。

**Then**

- `SEC-03.state = "baseline"`（不是 candidate，也不是 activated）
- `activation-report.json` 中 `SEC-03.rationale` 含"weighted threshold 未达 / 高风险兜底"字样
- `pending-confirmation.md` 中出现 SEC-03 条目,说明"已触发 baseline 兜底,建议 owner 补充 circuit-breaker 证据或降为 candidate"
- `01-securities-standard.md §6.3` 含 `[baseline]` 状态标注
- `ai-rules.md` 中 SEC-03 不进 activated must 列表

**回归断言**

```bash
jq '.dimensions[] | select(.dimension_id=="SEC-03") | .state' report.json | grep -q "baseline"
grep -q "SEC-03" pending-confirmation.md
jq '.dimensions[] | select(.dimension_id=="SEC-03") | .rationale' report.json | grep -qi "高风险\|high.risk\|兜底\|fallback"
```
