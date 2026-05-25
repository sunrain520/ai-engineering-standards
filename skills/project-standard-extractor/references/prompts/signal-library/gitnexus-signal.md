# gitnexus-signal

利用 GitNexus 图谱事实（模块依赖 / 调用链 / 分层结构）做高语义判定。**直接消费 host project 自身已装好的 GitNexus 能力**——不重新实现 readiness、不调度 bootstrap、不封装 MCP 调用为本地 helper。

## 项目内 GitNexus 能力来源

GitNexus 能力是宿主项目通过 spec-first 体系预先装好的，本 signal 只是它的下游消费者：

| 能力 | 由谁安装 | 产物 / 入口（**项目相对路径**，不要硬编码绝对路径） |
| --- | --- | --- |
| MCP host 安装 + 配置 | `spec-mcp-setup` | host MCP 配置（`.claude/`/`.codex/`/全局），暴露 `mcp__gitnexus__*` 工具集 |
| Graph readiness 编译 | `spec-graph-bootstrap`（默认全量；`--incremental` 实验） | `<project>/.spec-first/graph/graph-facts.json`（schema `graph-facts.v1`） |
| Provider 级状态 | `spec-graph-bootstrap` | `<project>/.spec-first/graph/provider-status.json`、`<project>/.spec-first/providers/gitnexus/status.json` |
| Impact 能力 | `spec-graph-bootstrap` | `<project>/.spec-first/impact/bootstrap-impact-capabilities.json` |
| 多仓 advisory（父级 workspace） | `spec-graph-bootstrap --all-repos` | 父级 `<workspace>/.spec-first/workspace/graph-bootstrap-summary.json`、`graph-targets.json`（**仅 advisory，不替代子仓 canonical facts**） |
| 运行时图查询 | host MCP | `mcp__gitnexus__*`：`list_repos` / `query` / `context` / `impact` / `cypher` / `route_map` 等 |

**本 signal 的边界：仅消费、不修复、不重建。** 当 readiness 缺失 / stale / blocked / degraded 时，**降级到 fallback signal**（grep / file_existence），并通过 `limitations` 字段引导用户运行 `$spec-graph-bootstrap`（修复 readiness）或 `$spec-mcp-setup`（修复 host 安装）。

## Input

```yaml
signal_id: <string>
dimension_id: <string>
type: gitnexus
repo_root: <abs path>            # 当前被分析项目的根目录
fact_query: |
  # 任选其一字段；将映射到 mcp__gitnexus__* 工具调用
  module_dependency: from -> to
  call_chain: caller -> callee
  layer_violation: layer_a -> layer_b
  symbol_kind: Class | Method | Route | Tool
expected:                        # 必填，命中条件
  - "module shared depends on module data"
  - "Route /api/orders handled by OrderController"
fallback:                        # 必填，降级配置
  type: file_existence | grep
  patterns:
    - "shared/"
weight: 1
max_evidence: 20
```

## 判定逻辑（薄适配，分两步委托给专用 prompt）

本 signal **不**复刻 readiness / query 细节，全部委托：

1. **Readiness 探测**：调 `references/prompts/gitnexus/readiness-check.md`。
   - 入参：`repo_root`、`freshness_window_days=14`、`force_graph`、`require_provider=gitnexus`。
   - 出参：`readiness.state ∈ {available, unavailable, stale, blocked, query-failed}` + `limitations` + `freshness_state`。
   - `state=available` → 进入 Graph 路径；其它 4 状态 → 立即 Fallback 路径，把 `limitations` 透传到本 signal 输出。
2. **Query / Fallback 分派**：调 `references/prompts/gitnexus/query-and-fallback.md`。
   - Graph 路径：按 `fact_query` 字段映射 `mcp__gitnexus__cypher / impact / query / context / route_map / tool_map`，单次超时 30s、最多重试 1 次。
   - Fallback 路径：按 `fallback.type` 调起 `file-existence-signal` / `grep-signal` / `ast-signal`，复用 `fallback.patterns / match_mode`。
   - **R59 单源约束**：所有 graph evidence 必须能定位到 `file_path` 非空且文件存在；否则该条 evidence 剔除，剩余为空时 `hit: false`，此条事实进 pending-confirmation 不入规则正文。
   - 输出统一 schema：`{hit, weight, evidence[], fallback, limitations, freshness, stats}`，`source` 字段如实标注 `gitnexus | file_existence | grep | ast`。

## Output

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
  ]
}
```

降级示例：

```json
{
  "signal_id": "...",
  "type": "gitnexus",
  "source": "file_existence",
  "hit": true,
  "weight": 1,
  "evidence": [
    {
      "file_path": "shared/build.gradle.kts",
      "line": 1,
      "snippet": "plugins { kotlin(\"multiplatform\") }",
      "source": "file_existence",
      "confidence": 0.7
    }
  ],
  "fallback": "file_existence",
  "limitations": "graph not ready: .spec-first/graph/graph-facts.json missing; run $spec-graph-bootstrap to refresh"
}
```

## 边界条件

- readiness 不可用 / MCP 不可用 → **降级**而非失败；error 字段不出现，`limitations` 必填。
- 单次 `mcp__gitnexus__*` 调用超时 30s → 立即降级。
- `graph-facts.v1` mtime > 14 天或 `freshness_state == "dirty-advisory"` 且 `dirty_classification == "graph-affecting-blocked"` → 默认降级；`force_graph: true` 仅供调试。
- evidence 截断同其他 signal（默认 max_evidence=20）。
- **绝不**在本 signal / skill 内：
  - 调用 spec-graph-bootstrap 脚本或重跑 GitNexus analyze；
  - 写入项目的 `.spec-first/graph/*`、`.spec-first/providers/*`、`.spec-first/impact/*`、`.spec-first/workspace/*`；
  - 重新封装 `mcp__gitnexus__*` 为本地 helper（直接调即可）。
- 父级多仓 workspace 场景：仅当查询本身是只读且需要跨仓 advisory 时才读取 `<workspace>/.spec-first/workspace/graph-bootstrap-summary.json`；写入、修复必须落到具体子仓 scope，不写父级 canonical 产物。

## Test scenarios

- `<repo_root>/.spec-first/graph/graph-facts.json` 不存在、`fallback.type: file_existence`、`patterns: ["shared/"]`、项目含 `shared/` → `hit: true` + `fallback: "file_existence"` + `limitations` 含 `run $spec-graph-bootstrap`，无 error。
- `graph-facts.json` 存在且 `overall_status=ready`，`mcp__gitnexus__cypher` 命中 `module shared depends on module data` → `hit: true`，无 fallback 字段。
- `graph-facts.json` 存在但 `overall_status=degraded` → 自动降级，`limitations` 含 `graph degraded`。
- `graph-facts.json` 存在但 mtime 超 14 天 → 自动降级，`limitations` 含 `graph stale`。
- `graph-facts.json` 存在且 ready，`mcp__gitnexus__list_repos` 调用失败 / 工具未注册 → 自动降级，`limitations` 含 `mcp gitnexus unavailable`。
- `freshness_state=dirty-advisory` 且 `dirty_classification=graph-affecting-blocked` → 默认降级（视为 stale），`limitations` 含 `graph dirty advisory`。
