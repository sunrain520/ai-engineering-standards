# GitNexus Readiness Check（薄适配 prompt）

> 作用：在调用任何 `mcp__gitnexus__*` 工具前，**先**消费宿主项目自身已装好的 spec-first 产物判定 readiness。本 prompt 不重新实现探测，**只做读取 + 分类**。
>
> Single readiness entry point：`<repo_root>/.spec-first/graph/graph-facts.json`（schema=`graph-facts.v1`）。

---

## 调用方与上游

| 上游产物（who provides） | 谁安装 | Skill 内消费者 |
| --- | --- | --- |
| `<repo_root>/.spec-first/graph/graph-facts.json` | `spec-graph-bootstrap`（宿主项目已装） | `references/prompts/signal-library/gitnexus-signal.md`、`references/agents/dimension-activator.md` |
| `<repo_root>/.spec-first/graph/provider-status.json` | 同上 | 仅作辅助，不替代 graph-facts.json |
| `<repo_root>/.spec-first/providers/gitnexus/status.json` | 同上 | 同上 |
| `<workspace>/.spec-first/workspace/graph-bootstrap-summary.json` | `spec-graph-bootstrap --all-repos`（仅父级 workspace） | 仅 advisory，绝不替代子仓 canonical facts |

**铁律**：本 prompt 不写、不修复、不重建上述任一文件；缺失时引导用户运行 `$spec-graph-bootstrap`（修复 readiness）或 `$spec-mcp-setup`（修复 host 安装）。

---

## Input

```yaml
repo_root: <abs path>           # 当前被分析项目根目录
freshness_window_days: 14       # 默认 14 天；mtime 超过即视为 stale
force_graph: false              # 仅调试用；true 时跳过 stale/dirty-advisory 判定
require_provider: gitnexus      # 必须 query_ready 的 provider 名
```

---

## Readiness 5 状态

| 状态 | 含义 | 触发条件 | 下游行为 |
| --- | --- | --- | --- |
| `available` | 全部条件满足，可走 graph 路径 | 见下方"通过条件"全部命中 | 进入 `query-and-fallback.md` graph 分支 |
| `unavailable` | readiness 入口缺失或解析失败 | `graph-facts.json` 不存在 / JSON 解析失败 / schema 标识不是 `graph-facts.v1` | 立即降级 fallback；`limitations` 引导 `$spec-graph-bootstrap` |
| `stale` | readiness 存在但已陈旧 | mtime 距今 > `freshness_window_days` 天，或 `freshness_state == "dirty-advisory"` 且 `dirty_classification == "graph-affecting-blocked"` | 默认降级；`force_graph: true` 时仍可用但 evidence 必须标 `freshness: stale` |
| `blocked` | readiness 状态明确不可用 | `overall_status ∈ ["blocked", "degraded"]`，或目标 provider `query_ready != true` | 立即降级；`limitations` 引导 `$spec-graph-bootstrap` 或 `$spec-mcp-setup` |
| `query-failed` | readiness 通过但 MCP 工具不可用 | `mcp__gitnexus__list_repos` 返回空 / 调用失败 / 超时 / 工具未注册 | 立即降级；`limitations` 引导 `$spec-mcp-setup`；不重试超过 1 次 |

---

## 通过条件（available）

按顺序依次通过，任一失败立即跳到对应状态：

1. **入口存在**：`<repo_root>/.spec-first/graph/graph-facts.json` 文件可读 → 否则 `unavailable: missing`。
2. **解析成功**：JSON 解析无错误 → 否则 `unavailable: parse_error`。
3. **Schema 版本**：`schema == "graph-facts.v1"` 或 `schema_version == "graph-facts.v1"` → 否则 `unavailable: schema_mismatch`。
4. **整体状态**：`overall_status ∈ ["ready", "degraded-advisory"]`（不含 `blocked`、`degraded`）→ 否则 `blocked: <overall_status>`。
5. **全局查询能力**：`capabilities.query_global_graph == true` → 否则 `blocked: query_global_graph_disabled`。
6. **Provider 就绪**：`providers[require_provider].query_ready == true` 或 `provider_summary.ready_primary_providers[]` 包含 `gitnexus` → 否则 `blocked: provider_not_ready`。
7. **worktree 新鲜度**：若 facts 暴露 `worktree_status_hash`，必须与当前 `git status --short` hash 匹配；不匹配 → `stale: worktree_status_hash_mismatch`。
8. **mtime 新鲜度**：`mtime >= now - freshness_window_days` 通过；`mtime < now - freshness_window_days` → `stale: mtime_exceeded`。若 `freshness_state == "dirty-advisory"` 且 `dirty_classification == "graph-affecting-blocked"` → `stale: dirty_advisory`（除非 `force_graph: true`）。
9. **MCP 就绪**：`mcp__gitnexus__list_repos` 返回非空且包含目标 repo（30s 超时）→ 否则 `query-failed: mcp_unavailable`。

全部通过 → `available`。

---

## Output

```yaml
readiness:
  state: available | unavailable | stale | blocked | query-failed
  reason: <string>                      # 状态对应的具体原因短串
  freshness_state: ready | dirty-advisory | unknown
  graph_facts_path: <relative path>     # 永远写项目相对路径，不硬编码绝对路径
  schema: graph-facts.v1
  mtime_iso: 2026-05-25T00:00:00Z
  provider:
    name: gitnexus
    query_ready: true | false
  limitations: <string|null>            # 非 available 状态必填,引导用户修复入口
  next_action_hint:                     # 给调用方建议
    - "$spec-graph-bootstrap"           # 修复 readiness
    - "$spec-mcp-setup"                 # 修复 host MCP
```

---

## 边界

1. **绝不**：调用 `spec-graph-bootstrap`、写 `.spec-first/graph/*` / `.spec-first/providers/*` / `.spec-first/impact/*` / `.spec-first/workspace/*`、重新封装 `mcp__gitnexus__*` 为本地 helper。
2. **绝不**：硬编码绝对路径。所有路径都以 `<repo_root>` 为锚点表示为相对路径。
3. **绝不**：在父级多仓 workspace 场景下，把 `<workspace>/.spec-first/workspace/graph-bootstrap-summary.json` 作为子仓 canonical readiness 来源使用——它仅 advisory。子仓的 readiness 必须读子仓自身的 `<repo_root>/.spec-first/graph/graph-facts.json`。
4. **绝不**：超过 30s 等待 `mcp__gitnexus__*` 调用——超时立即降级。
5. **绝不**：缓存 readiness 跨 run；每个 run 重新读一次（除非显式传入 `cached_readiness` 字段）。

---

## Test scenarios

| 场景 | 期望 state | reason | limitations 是否提及 |
| --- | --- | --- | --- |
| `graph-facts.json` 不存在 | `unavailable` | `missing` | `$spec-graph-bootstrap` |
| `graph-facts.json` 存在但 JSON 损坏 | `unavailable` | `parse_error` | `$spec-graph-bootstrap` |
| `schema: graph-facts.v0` | `unavailable` | `schema_mismatch` | `$spec-graph-bootstrap` |
| `overall_status: blocked` | `blocked` | `overall_status=blocked` | `$spec-graph-bootstrap` |
| `providers.gitnexus.query_ready: false` | `blocked` | `provider_not_ready` | `$spec-graph-bootstrap` |
| mtime 距今 30 天 | `stale` | `mtime_exceeded` | `$spec-graph-bootstrap` |
| `capabilities.query_global_graph: false` | `blocked` | `query_global_graph_disabled` | `$spec-graph-bootstrap` |
| `worktree_status_hash` 与当前 git status hash 不一致 | `stale` | `worktree_status_hash_mismatch` | `$spec-graph-bootstrap` |
| `freshness_state: dirty-advisory` + `dirty_classification: graph-affecting-blocked` | `stale` | `dirty_advisory` | `$spec-graph-bootstrap` |
| readiness 通过但 `mcp__gitnexus__list_repos` 超时 | `query-failed` | `mcp_timeout` | `$spec-mcp-setup` |
| readiness 通过 + MCP 工具就绪 | `available` | `ok` | `null` |
| `force_graph: true` + mtime 30 天 | `available`（force-allowed） | `forced` | `evidence freshness: stale` 标注 |
