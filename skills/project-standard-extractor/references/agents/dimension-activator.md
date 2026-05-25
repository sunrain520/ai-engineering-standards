# Dimension Activator Contract

## 角色目标

基于 scope、维度池、activation-rules、上游 `signal_hits[]` 与 `doc_facts[]`，对每个维度计算三态激活结果（`baseline` / `activated` / `candidate`，外加 `pending-confirmation` / `shallow` 标注），输出 `activation-report.json`，作为下游 generation / review / merge 的唯一权威源。

> 上游：`facts-and-classification`（产出 signal_hits / doc_facts / fact_candidates）。下游：`generation`、`review-and-quality-gate`、`merge-coordinator`。本 agent 不执行信号扫描，只消费上游已记录的信号结果并统一裁决 state。

## 输入

- `scope_summary`（来自 intake-and-scope）
- `temp/{run_id}-project-profile.md` + `temp/{run_id}-batch-plan.md`（来自 profile-and-batch-planner）
- `signal_scan`（来自 facts-and-classification，schema=`signal-scan.v1`，含 `signal_hits[]` / `doc_facts[]` / `fact_candidates[]`）
- 维度池配置（U1）：
  - `references/config/dimension-framework/baseline-dimensions.yaml`
  - `references/config/dimension-framework/dimensions-app-client.yaml`
  - `references/config/dimension-framework/dimensions-frontend.yaml`
  - `references/config/dimension-framework/dimensions-backend.yaml`
  - `references/config/dimension-framework/dimensions-industry.yaml`
  - `references/config/dimension-framework/dimensions-industry-securities.yaml`
  - `references/config/dimension-framework/depth-indicator.yaml`
- 激活规则（U3）：
  - `references/config/dimension-framework/activation-rules-app-client.yaml`
  - `references/config/dimension-framework/activation-rules-frontend.yaml`
  - `references/config/dimension-framework/activation-rules-backend.yaml`
  - `references/config/dimension-framework/activation-rules-industry.yaml`
  - `references/config/dimension-framework/activation-rules-doc.yaml`
- 信号库（U2）：
  - `references/prompts/signal-library/grep-signal.md`
  - `references/prompts/signal-library/ast-signal.md`
  - `references/prompts/signal-library/file-existence-signal.md`
  - `references/prompts/signal-library/dependency-signal.md`
  - `references/prompts/signal-library/gitnexus-signal.md`
- 骨架池（U4，仅做激活态合法性校验，不在本阶段落盘）：
  - `assets/skeletons/`
- 可选：host project GitNexus readiness `<repo_root>/.spec-first/graph/graph-facts.json`

## Run Mode

| run_mode | 行为 |
| --- | --- |
| `auto`（默认） | 所有维度按规则自动判定；置信度 low → 落 `pending-confirmation`，不阻塞 |
| `interactive` | weighted 阈值临界、gitnexus readiness 不可用、signal 矛盾时主动询问 owner |

**激活规则未覆盖的维度** 永远落 `candidate`，不在 auto 模式下静默升级。

## 输出（Handoff Schema）

落盘到 `temp/{run_id}-activation-report.json`：

```json
{
  "schema": "activation-report.v1",
  "run_id": "<YYYYMMDD-HHMMSS-domain>",
  "scope": {
    "dev_domains": ["app-client"],
    "sub_domains": ["kmp-shared", "android", "ios", "hybrid-bridge"],
    "industry_domains": []
  },
  "gitnexus_readiness": {
    "available": true,
    "graph_facts_path": "<repo_root>/.spec-first/graph/graph-facts.json",
    "graph_mtime_iso": "2026-05-25T00:00:00Z",
    "stale_days": 2,
    "fallback_used": false,
    "state": "available"
  },
  "dimensions": [
    {
      "dimension_id": "D02",
      "name": "命名规范",
      "layer": "baseline",
      "state": "baseline",
      "rationale": "baseline 不参与激活判定",
      "signals_evaluated": [],
      "evidence_paths": [],
      "depth_score": null,
      "skeleton_section": null
    },
    {
      "dimension_id": "EA-Client-02",
      "name": "跨平台共享层",
      "layer": "end:app-client",
      "state": "activated",
      "rationale": "weighted threshold=2 命中 (commonMain glob + kotlin-multiplatform dep)",
      "signals_evaluated": [
        {"id": "kmp-source-set", "type": "file_existence", "source": "file_existence", "hit": true, "weight": 1},
        {"id": "kmp-gradle-plugin", "type": "dependency", "source": "dependency", "hit": true, "weight": 1}
      ],
      "evidence_paths": ["shared/src/commonMain/", "shared/build.gradle.kts"],
      "depth_score": 0.82,
      "skeleton_section": "assets/skeletons/app-client/kmp-shared-skeleton.md"
    },
    {
      "dimension_id": "EA-Client-08",
      "name": "数据安全",
      "layer": "end:app-client",
      "state": "pending-confirmation",
      "rationale": "weighted threshold=2 命中 1 项 (Keystore import)；不足阈值,需 owner 确认",
      "signals_evaluated": [
        {"id": "android-keystore-import", "type": "grep", "source": "grep", "hit": true, "weight": 1},
        {"id": "ios-keychain-import", "type": "grep", "source": "grep", "hit": false, "weight": 1}
      ],
      "evidence_paths": ["app/src/main/.../KeystoreBridge.kt"],
      "depth_score": 0.45,
      "skeleton_section": null
    },
    {
      "dimension_id": "EA-Client-07",
      "name": "启动性能",
      "layer": "end:app-client",
      "state": "candidate",
      "rationale": "无任何 signal 命中",
      "signals_evaluated": [],
      "evidence_paths": [],
      "depth_score": 0.0,
      "skeleton_section": null,
      "candidate_hint": {
        "trigger_when": "出现 baseline-profiler / Macrobenchmark / Startup library import",
        "suggested_owner_question": "项目当前是否有冷启动 P95 / TTFD 指标治理?"
      }
    }
  ],
  "summary": {
    "total_dimensions": 8,
    "baseline_count": 6,
    "activated_count": 1,
    "pending_count": 1,
    "candidate_count": 0,
    "shallow_count": 0
  },
  "open_questions": [],
  "stop_conditions_hit": []
}
```

下游消费契约：

| 字段 | 消费方 | 用途 |
| --- | --- | --- |
| `dimensions[].state` | facts / generation / merge / review | 决定是否萃取、用哪个 skeleton、章节标注、是否进入未激活地图 |
| `dimensions[].evidence_paths` | facts-and-classification | 限定 batch 萃取范围 |
| `dimensions[].skeleton_section` | generation | 选用 `assets/skeletons/` 内具体文件 |
| `dimensions[].depth_score` | review-and-quality-gate | 与 `depth-indicator.yaml` 阈值比较，低于阈值改判 `shallow` |
| `summary` | merge-coordinator | 写入 overview 「未激活维度地图」段统计 |

## 执行步骤

### Step 1 — 加载并校验配置

1. 读取所有 U1 维度 yaml 与 U3 激活规则 yaml；按 `schema.json` / `activation-rules.schema.json` 自检。
2. 维度 ID 与激活规则 ID 必须 1:1 对齐；缺失或冗余 → 抛 `DIMENSION_RULE_MISMATCH`。
3. 加载 signal library 6 个 prompt（`overview.md` + 5 类信号）只用于校验 `signal_hits[].source` 与 fallback 标注，不在本阶段重新扫描项目。

### Step 2 — 锁定 scope ↔ 维度集

1. 从 `scope_summary` 取 `dev_domains` / `sub_domains` / `industry_domains`。
2. 计算待评估维度集合：
   - 永远包含：`baseline-dimensions.yaml` 全集
   - 包含：每个 `dev_domain` 对应的 `dimensions-{domain}.yaml`
   - 包含：每个 `industry_domain` 对应的 `dimensions-industry-{name}.yaml`（如 `securities`）
3. 维度集合空集 → 抛 `EMPTY_DIMENSION_SET`，停止（intake 必须重做）。

### Step 3 — GitNexus readiness 探测

1. 读取 `<repo_root>/.spec-first/graph/graph-facts.json`，验证 schema=`graph-facts.v1`。
2. 校验 `capabilities.query_global_graph == true` 且 ready provider 包含 GitNexus；否则 `available=false, fallback_used=true`。
3. 如果 readiness artifact 暴露 `worktree_status_hash`，必须与当前 worktree status hash 匹配；不匹配时 `state=dirty-advisory`，GitNexus evidence 只能作为候选。
4. 计算 `mtime`；`mtime < now - 14 天` → stale；`mtime >= now - 14 天` 才可视为 fresh。
5. 文件不存在 / mcp 不可用 → 同上，`limitations` 中提示用户运行 `$spec-graph-bootstrap` 或 `$spec-mcp-setup`。
6. **不允许** 因 GitNexus 缺失而阻塞流程；只允许降级。

### Step 4 — 信号结果归并

对待评估维度集合中每个 dimension：

1. 取 `activation-rules-*.yaml` 中对应规则；规则缺失 → 该维度落 `candidate`，记 `rationale = "no activation rule defined"`。
2. 从 `signal_scan.signal_hits[]` 和 `doc_facts[]` 按 `dimension_id + signal_id` 汇总命中结果。
3. 规则声明的 signal 未出现在 signal_scan 中时，按 `hit=false` 记录，并保留 `missing_signal_result` warning。
4. 每个 signal 记录 `{id, type, source, hit, weight, evidence_paths[], evidence_truncated}`；`source` 必填且必须是真实来源,`source=gitnexus` 只允许在 readiness available 且 signal_scan 明确提供时出现。

### Step 5 — 组合判定

按 `combination` 类型：

| combination | 判定 |
| --- | --- |
| `any` | 任一 signal hit → `activated` |
| `all` | 全部 signal hit → `activated`；否则 `candidate`（部分命中也不升级） |
| `weighted` | sum(weight×hit) ≥ `threshold` → `activated`；命中但 < threshold → `pending-confirmation`；零命中 → `candidate` |

baseline 维度默认 `state = pending-confirmation`，除非存在 owner 确认或可验证 evidence 支撑最小 baseline 内容；generation 只能从 `baseline-dimensions.yaml.default_content` 渲染，不得编造强制规则。

### Step 6 — 深度核验（depth-indicator）

仅对 `activated` 维度：

1. 按 `depth-indicator.yaml` 的端 / 维度阈值，计算 `depth_score`（evidence 数 / 文件数 / 规则节预估数的归一化分）。
2. `depth_score` < 阈值 → 改判 `shallow`，记 `rationale` 含原 weighted/any/all 命中详情 + 深度未达项。
3. 不抑制 `pending-confirmation` 状态进入 depth 阶段。

### Step 7 — Skeleton 选型

为每个非 `candidate` / 非 baseline 的维度匹配 `assets/skeletons/` 文件：

| 维度归属 | skeleton 文件 |
| --- | --- |
| 端级 overview（任意端激活后） | `assets/skeletons/overview-skeleton.md` |
| sub-domain（如 `kmp-shared`） | `assets/skeletons/app-client/kmp-shared-skeleton.md` |
| sub-domain（`hybrid-bridge`） | `assets/skeletons/app-client/hybrid-bridge-skeleton.md` |
| 横切（如命名 / 错误模型） | `assets/skeletons/cross-cutting-skeleton.md` |
| industry sub | `assets/skeletons/industry/{name}-skeleton.md` |

匹配失败 → 该维度落 `candidate` 并记 `rationale = "no matching skeleton"`。

### Step 8 — 三态汇总与 candidate hint

1. 统计 baseline / activated / pending-confirmation / candidate / shallow 数量。
2. 对每个 `candidate` 维度生成 `candidate_hint`：
   - `trigger_when`：取自激活规则 yaml 中的 `signals[]` 描述
   - `suggested_owner_question`：从维度 yaml 的 `description` 派生（"项目是否有 X 治理 / 是否使用 Y 能力?"）

### Step 9 — Self-check

落盘前自校验：

- [ ] 所有维度 ID 至少出现一次
- [ ] state ∈ {baseline, activated, candidate, pending-confirmation, shallow}
- [ ] activated 维度必须有 ≥ 1 evidence_path
- [ ] activated / shallow 维度必须有 skeleton_section
- [ ] candidate 维度必须有 candidate_hint
- [ ] gitnexus_readiness 字段完整
- [ ] 不出现真实项目绝对路径（路径必须 sanitize 为相对路径或 glob 模式）

任一不通过 → 不移交，写 `temp/{run_id}-activation-report.errors.json` 并停止。

## 共同规则

1. **不得** 在 baseline 之外静默升级维度状态：未在 activation-rules yaml 中显式定义的维度永远 `candidate`。
2. **不得** 因 GitNexus 不可用而阻塞；必须降级到 fallback signal 并明确告知 limitations。
3. **不得** 把 weighted threshold 临界判定为 activated；必须落 `pending-confirmation`。
4. **不得** 把激活报告中的 evidence_paths 直接写入正式规范文档；正式规范的 evidence 由下游 generation agent 重新挑选并 sanitize。
5. **不得** 跨过本 agent 直接由 generation 决定章节激活态；generation 必须读 activation-report.json。

## 失败 / 停止条件

| 错误码 | 触发 | 处置 |
| --- | --- | --- |
| `DIMENSION_RULE_MISMATCH` | U1 维度 yaml 与 U3 规则 yaml ID 不对齐 | 停止，提示用户检查配置 |
| `EMPTY_DIMENSION_SET` | scope 解析后维度集合为空 | 停止，回 intake 重做 scope |
| `SIGNAL_LIBRARY_TIMEOUT` | 单个 signal 超 30s | 跳过该 signal 并记 `skipped: timeout`，继续 |
| `GITNEXUS_DEGRADED` | readiness 不可用 / missing query_global_graph / mtime stale / worktree hash mismatch | 降级 fallback，写 limitations，继续 |
| `SCHEMA_VALIDATION_FAILED` | 输出 json 不匹配 `activation-report.v1` | 抛错并停止 |

## EA-Doc 扩展（U27）

当 signal_scan 含 `doc_facts[]` 时，dimension-activator 在代码信号归并之后追加 EA-Doc-* 5 维的激活评估：

```
信号源合并策略:
  - 代码信号（signal_type: ast / filename / keyword）参与代码维度（D01-D13 / SEC / XSEC）判定
  - doc-content 信号（signal_type: doc-content）参与 EA-Doc-* 5 维判定
  - 二者不混合（不允许 doc-content 信号激活代码维度，反之亦然）

EA-Doc-Decision high_risk_fallback:
  - 无 ADR 信号命中 → state=baseline（同 SEC-10 高风险兜底逻辑）
  - baseline 写入 pending-confirmation.md："建议团队创建 docs/adr/ 并提交 ≥1 条 ADR"
```

评估结果追加到 `activation-report.json` 的 `dimensions[]`（EA-Doc-* 5 条），`summary` 中 `total_dimensions` 加 5。

## Handoff

下游 `generation` / `review-and-quality-gate` / `merge-coordinator` 必须把 activation-report 作为权威输入：

- `activated` 维度可使用上游 fact_candidates 生成正式规则候选
- `pending-confirmation` 维度只生成待确认记录，不进入 AI 默认执行路径
- `shallow` 维度必须标记 low-coverage，并使用 `recommended_action: keep-draft-low-coverage`
- `candidate` 只进入 overview 未激活地图
- `baseline` 只能从 `baseline-dimensions.yaml.default_content` 生成最小内容或 pending 记录
- EA-Doc-* 维度必须写入 `dimensions[]`，不得使用旧数组别名
