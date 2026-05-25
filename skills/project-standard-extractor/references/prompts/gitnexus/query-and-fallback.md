# GitNexus Query & Fallback（薄适配 prompt）

> 作用：readiness 通过后把维度 `fact_query` 字段映射到 `mcp__gitnexus__*` 工具调用；失败 / 超时 / readiness 不就绪时降级到 `file_existence` / `grep` / `ast` signal。
>
> 上游：`references/prompts/gitnexus/readiness-check.md`（必先通过 readiness 才能走 graph 路径）。
> 下游：`references/prompts/signal-library/gitnexus-signal.md` 调用本 prompt；`references/agents/dimension-activator.md` 通过 signal 间接消费。

---

## 路径选择决策树

```
readiness.state == available?
  ├─ YES → Graph 路径（query via mcp__gitnexus__*）
  │         └─ 工具调用失败 / 超时 → 降级 fallback 路径
  └─ NO  → 立即 fallback 路径（按 fallback.type 调起其它 signal）
```

**铁律（R59）**：来自 GitNexus 的 evidence **不得** 只停留在抽象图关系。每条 graph evidence 必须能定位到具体代码 `file_path`，否则降级为"待人工确认"，不写入规则正文；不强制要求再额外搭配 grep / ast 作为第二来源。

---

## Input

```yaml
fact_query:
  module_dependency: "shared -> data"          # 任选其一字段
  call_chain: "OrderController.placeOrder -> StockService.deduct"
  layer_violation: "presentation -> data"
  symbol_kind: Class | Method | Route | Tool   # 配合 name/uid 使用
  symbol_name: <string>                        # symbol_kind 模式下必填
expected:                                      # 命中条件,graph 与 fallback 共用
  - "shared depends on data"
fallback:
  type: file_existence | grep | ast
  patterns: ["shared/", "data/"]
  match_mode: any | all
weight: 1
max_evidence: 20
timeout_seconds: 30
```

---

## Graph 路径（readiness=available）

### 工具映射表

| `fact_query` 字段 | 主用工具 | 备选工具 | 说明 |
| --- | --- | --- | --- |
| `module_dependency` | `mcp__gitnexus__cypher` | — | 用 `MATCH (a:File)-[:CodeRelation {type: 'IMPORTS'}]->(b:File) ...` |
| `call_chain` | `mcp__gitnexus__impact` | `mcp__gitnexus__cypher` | impact 直接给 byDepth；cypher 兜底 |
| `layer_violation` | `mcp__gitnexus__cypher` | — | 用层间 `IMPORTS` / `CALLS` 反向断言 |
| `symbol_kind` + `symbol_name` | `mcp__gitnexus__query` | `mcp__gitnexus__context` | query 列结果；context 给 360 度上下文 |
| Route 端点 | `mcp__gitnexus__route_map` | `mcp__gitnexus__api_impact` | 路由消费图 / 影响面 |
| Tool 端点 | `mcp__gitnexus__tool_map` | — | MCP/RPC 工具映射 |

### 调用约束

1. **超时**：单次 `mcp__gitnexus__*` 调用 ≤ `timeout_seconds`（默认 30s）；超时立即降级。
2. **重试**：失败不超过 1 次；第二次失败立即降级。
3. **Evidence 提取**：每条命中事实转 `{file_path, line, snippet, source: "gitnexus", confidence: <0..1>}`；若 symbol 不可定位到具体代码行 → 该事实降级为"待人工确认"（写到 `pending-confirmation` 桶，**不**进 graph hit），与 R59 一致。
4. **截断**：evidence 数量 ≤ `max_evidence`（默认 20）；超出截断保留前 20 条并附 `truncated: true`。
5. **R59 单源约束**：所有 graph evidence 必须有 `file_path` 非空且文件确实存在；任一不满足即剔除该条 evidence。

### 命中判定

- `expected[]` 全部命中（用文本包含 / 关系存在 等语义判断）→ `hit: true`。
- 部分命中 → `hit: false`，但仍输出 `partial_evidence[]` 用于审计。
- 全部未命中 → `hit: false`，仅记录 graph 查询统计。

---

## Fallback 路径（readiness ≠ available 或 graph 工具失败）

按 `fallback.type` 调起对应 signal，复用 `fallback.patterns` 与 `fallback.match_mode`：

- `file_existence` → 调 `references/prompts/signal-library/file-existence-signal.md`
- `grep` → 调 `references/prompts/signal-library/grep-signal.md`
- `ast` → 调 `references/prompts/signal-library/ast-signal.md`

**Fallback 输出附加约定**：

```yaml
fallback: file_existence | grep | ast
limitations: |
  graph not used: <readiness.reason>;
  run $spec-graph-bootstrap to refresh readiness
  (or $spec-mcp-setup to fix host MCP)
freshness:
  graph_facts_state: <readiness.state>
```

调用方（如 `dimension-activator`）应把 `limitations` 直接透传到 `activation-report.json` 的 `dimensions[].rationale` 中，让用户能看见"为什么这里走了 fallback"。

---

## Output（统一 schema，无论 graph 还是 fallback）

```json
{
  "signal_id": "ea-client-01-shared-module",
  "type": "gitnexus",
  "source": "gitnexus",
  "hit": true,
  "weight": 1,
  "evidence": [
    {
      "file_path": "shared/build.gradle.kts",
      "line": 1,
      "snippet": "module shared depends on module data",
      "source": "gitnexus",
      "confidence": 0.95
    }
  ],
  "fallback": null,
  "limitations": null,
  "freshness": { "graph_facts_state": "available" },
  "stats": {
    "tools_used": ["mcp__gitnexus__cypher"],
    "elapsed_ms": 1240,
    "evidence_count": 1,
    "truncated": false
  }
}
```

降级示例（readiness=stale，fallback=grep）：

```json
{
  "signal_id": "ea-client-01-shared-module",
  "type": "gitnexus",
  "source": "grep",
  "hit": true,
  "weight": 1,
  "evidence": [
    { "file_path": "shared/src/main.kt", "line": 12, "snippet": "import data.repository", "source": "grep", "confidence": 0.7 }
  ],
  "fallback": "grep",
  "limitations": "graph not used: stale (mtime_exceeded); run $spec-graph-bootstrap to refresh readiness",
  "freshness": { "graph_facts_state": "stale" },
  "stats": { "tools_used": ["grep"], "elapsed_ms": 80, "evidence_count": 1, "truncated": false }
}
```

---

## 边界

1. **绝不**：在父级多仓 workspace 用父级 `graph-bootstrap-summary.json` 作为 canonical 来源；只读取子仓自身 `<repo_root>/.spec-first/graph/graph-facts.json`。
2. **绝不**：同一个 dimension 的 `signals[]` 全部为 gitnexus 来源就直接 activate；激活规则的 `combination`（any/all/weighted+threshold）必须在 dimension-activator 内单独评估，本 prompt 仅产出 signal hit。
3. **绝不**：把降级 evidence 标 `source: gitnexus`；fallback 路径下 `source` 必须是真实信号类型（`file_existence`/`grep`/`ast`）。
4. **绝不**：把无 `file_path` 的 graph 事实写进规则正文；这类事实只能进 pending-confirmation。
5. **绝不**：超过 1 次重试；第二次失败立即降级，避免阻塞 batch 整体进度。

---

## Test scenarios

| 场景 | readiness state | 期望路径 | hit | source | fallback 字段 | limitations |
| --- | --- | --- | --- | --- | --- | --- |
| `module_dependency: "shared -> data"`，graph ready，cypher 命中 | available | graph | true | gitnexus | null | null |
| 同上但 cypher 超时 30s | available → 降级 | fallback(grep) | true | grep | "grep" | "graph not used: query timeout..." |
| readiness `unavailable: missing` + fallback grep `shared/` 命中 | unavailable | fallback | true | grep | "grep" | "graph not used: missing; run $spec-graph-bootstrap" |
| readiness `stale: mtime_exceeded` + fallback file_existence | stale | fallback | depends | file_existence | "file_existence" | "graph not used: stale (mtime_exceeded)..." |
| graph 命中但 evidence 全部无 `file_path` | available | graph | false（R59 剔除后空） | — | null | "all evidence dropped: missing file_path" |
| Route `/api/orders` route_map 命中 + 关联 `OrderController.java:14` | available | graph | true | gitnexus | null | null |
| readiness `query-failed: mcp_timeout` + fallback grep 命中 | query-failed | fallback | true | grep | "grep" | "graph not used: mcp_timeout; run $spec-mcp-setup" |
