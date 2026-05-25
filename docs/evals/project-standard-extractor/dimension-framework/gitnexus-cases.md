---
name: gitnexus-cases
description: GitNexus 集成评估场景：AE12（可用 → 消费 graph-facts）/ AE13（不可用 → fallback + limitations）
type: evals
phase: phase-2
ae: [AE12, AE13]
---

# GitNexus Cases

> GitNexus 由 spec-first graph-bootstrap 安装，产物为 `<repo_root>/.spec-first/graph/graph-facts.json`（schema graph-facts.v1）。
> dimension-activator 通过读取该文件（或调用 `mcp__gitnexus__*` MCP 工具）消费图能力，**不重新实现 readiness/bootstrap**。

## GNC-001 — AE12: GitNexus 可用 → 消费 graph-facts.json

**Given**

```yaml
project_path: /mock/kaz-mvp
gitnexus_state:
  state: available
  graph_facts_path: /mock/kaz-mvp/.spec-first/graph/graph-facts.json
  mtime_days_ago: 2
  schema: graph-facts.v1
  stats:
    symbols: 1240
    edges: 4832
    modules: 18
graph_facts_excerpt:
  - symbol: KYCValidator
    kind: Class
    module: account
    calls: [AMLChecker, ComplianceRepo]
  - symbol: RiskEngine
    kind: Class
    module: risk
    has_methods: [evaluate, getPositionLimit]
```

**When**

dimension-activator 读取 graph-facts.json,用图中 symbol 列表补充激活信号扫描。

**Then**

- `gitnexus_readiness.state = "available"` 写入 `dimension-activation-report.json`
- `fallback_used = false`
- `KYCValidator`、`RiskEngine` 命中对应维度信号（SEC-01 / SEC-05）,`evidence_paths` 中出现 graph-derived 条目
- graph signal 每条都含 `source: gitnexus` 且有非空 `evidence_paths`
- 不重新实现 graph bootstrap,不读取 `.spec-first/` 外的 GitNexus 内部文件
- `depth_score` 相比 fallback 路径有提升（graph-derived evidence 贡献额外 depth 点）

**回归断言**

```bash
jq '.gitnexus_readiness.state' report.json | grep -q '"available"'
jq '.gitnexus_readiness.fallback_used' report.json | grep -q 'false'
jq '.dimensions[] | select(.dimension_id=="SEC-01") | .evidence_paths[]' report.json | grep -q "graph-derived"
jq -e '.dimensions[] | .signals_evaluated[]? | select(.type=="gitnexus" and .source=="gitnexus" and ((.evidence_paths // []) | length > 0))' report.json >/dev/null
```

---

## GNC-002 — AE13: GitNexus 不可用 → fallback,记录 limitations

**Given**

```yaml
project_path: /mock/demo-broker-platform
gitnexus_state:
  state: unavailable    # graph-facts.json 不存在 / bootstrap 未运行
  graph_facts_path: null
  mcp_available: false
```

**When**

dimension-activator 检测 GitNexus readiness 失败,触发 fallback 路径（文件系统 pattern 扫描）。

**Then**

- `gitnexus_readiness.state = "unavailable"` 写入 `dimension-activation-report.json`
- `fallback_used = true`
- `limitations[]` 说明使用了文件系统 pattern 匹配作为替代
- fallback evidence 的 `source` 必须是真实 fallback 类型(`file_existence` / `grep` / `ast`),不得标 `gitnexus`
- `limitations[]` 中出现"GitNexus 不可用，symbol 级跨模块调用链无法追踪"条目
- `warnings[]` 中提示用户运行 `$spec-graph-bootstrap` 可提升维度信号深度
- 激活结果仍然产出,但 `depth_score` 上限受限（无法超过 0.7 for graph-dependent dimensions）
- 不中止萃取流程（fallback 是降级,不是错误）

**回归断言**

```bash
jq '.gitnexus_readiness.fallback_used' report.json | grep -q 'true'
jq -r '.warnings[]' report.json | grep -q "graph-bootstrap"
jq -r '.limitations[]' report.json | grep -qi "gitnexus\|graph"
jq -e '.dimensions[] | .signals_evaluated[]? | select(.type=="gitnexus" and .fallback != null and .source != "gitnexus")' report.json >/dev/null
```
