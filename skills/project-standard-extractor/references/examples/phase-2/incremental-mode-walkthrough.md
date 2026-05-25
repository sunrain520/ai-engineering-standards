---
name: incremental-mode-walkthrough
description: 增量模式（diff）端到端 walkthrough：Android Feature 重构后只重评受影响维度，演示 evolution.transitions[] 与最小化更新
type: example
phase: phase-2
extraction_mode: diff
domain: 01-app-client
---

# Incremental Mode Walkthrough

> **场景**：团队对 `kaz-mvp` 项目完成了一次 Android Feature 模块大范围重构，`shared/domain/` 也新增了 `PortfolioModel.kt`。
> 希望只重评受影响的维度，不重跑全量，避免对未变更规范造成干扰。

---

## 一、输入参数

```yaml
project_paths:
  - /local/kaz-mvp
extraction_mode: diff
diff_scope: auto          # 由 Diff Scoper agent 自动推断变更文件列表
prior_run_id: 20260520-080000-app
domain: 01-app-client
run_mode: interactive
```

---

## 二、Phase 1: Diff Scoper 扫描变更

**Diff Scoper agent 输出（自动推断）**：

```
已检测到以下变更文件（相对于 prior_run_id 20260520-080000-app）:
  M android/feature/portfolio/PortfolioViewModel.kt
  M android/feature/portfolio/PortfolioScreen.kt
  A shared/domain/PortfolioModel.kt
  M shared/usecase/GetPortfolioUseCase.kt
  M android/di/AppModule.kt           # DI 注入变更

受影响模块：
  - android/feature/portfolio/  → EA-Client-02 (Android 端规范)
  - shared/domain/              → EA-Client-01 (KMP shared 层)
  - shared/usecase/             → EA-Client-01 (KMP UseCase)

不受影响模块（跳过）:
  - account-service/  → SEC-01 (不变)
  - risk-service/     → SEC-05 (不变)
  - cross-border/     → XSEC-* (不变)
  - android/feature/trade/     → EA-Client-02 trade 子节 (不变)
```

**Diff Scoper 决策**：

```yaml
dimensions_to_reevaluate: [EA-Client-01, EA-Client-02]
dimensions_to_skip: [EA-Client-03, EA-Client-04, EA-Client-05, EA-Client-06, EA-Client-07, EA-Client-08, SEC-01~10, XSEC-01~06]
estimated_savings: "跳过 22 / 30 维度 = 73% 节省"
```

---

## 三、Phase 2: Dimension Activator（仅重评 2 维）

### EA-Client-01 重评

**变更前**（prior run）：
- state: `activated`
- evidence_count: 3
- depth_score: 0.72

**本次新增信号**：
- `shared/domain/PortfolioModel.kt` 命中 `kmp-domain-model` 信号（weight=1）
- `shared/usecase/GetPortfolioUseCase.kt` 已有，信号不新增

**本次评估结果**：
- state: `activated`（无变化）
- evidence_count: 4（+1）
- depth_score: 0.78（+0.06）

**evolution.transitions 条目**：
```json
{
  "dimension_id": "EA-Client-01",
  "state_before": "activated",
  "state_after": "activated",
  "depth_before": 0.72,
  "depth_after": 0.78,
  "reason": "new evidence file: shared/domain/PortfolioModel.kt",
  "changed": false
}
```
（state 无变化 → `changed: false`，不触发规则正文重生成）

### EA-Client-02 重评

**变更前**（prior run）：
- state: `activated`
- evidence_count: 5
- depth_score: 0.76

**本次新增信号**：
- `PortfolioViewModel.kt` + `PortfolioScreen.kt` 命中 `viewmodel-with-flow` 信号
- `AppModule.kt` 命中 `hilt-di-module` 信号

**本次评估结果**：
- state: `activated`（无变化）
- evidence_count: 7（+2）
- depth_score: 0.82（+0.06）

**evolution.transitions 条目**：
```json
{
  "dimension_id": "EA-Client-02",
  "state_before": "activated",
  "state_after": "activated",
  "depth_before": 0.76,
  "depth_after": 0.82,
  "reason": "new signals: PortfolioViewModel.kt (viewmodel-with-flow), AppModule.kt (hilt-di-module)",
  "changed": false
}
```

---

## 四、Phase 3: Generation（最小化更新）

**generation agent 决策**：

- `EA-Client-01.changed = false` → **不重生成**规则正文（只更新 evidence_count / depth_score metadata）
- `EA-Client-02.changed = false` → **不重生成**规则正文（同上）
- 22 个跳过的维度 → **完全不处理**

**实际文件变更**：

| 文件 | 变更类型 | 说明 |
| --- | --- | --- |
| `evidence/dimension-activation-report.json` | 更新 2 个评估条目 | EA-Client-01 / EA-Client-02 depth_score + evidence_count + last_evaluated_at |
| `standard-kmp-shared.md` | 无变更 | state 不变，规则正文不重写 |
| `standard-android.md` | 无变更 | 同上 |
| 其余 28 维度 | 无变更 | 跳过 |

---

## 五、假设场景：信号触发状态升级

> 下面演示如果 `PortfolioViewModel` 中新增了 `PortfolioCache.kt`（命中 EA-Client-07 缓存性能信号），会触发状态升级。

**假设变更**：

```yaml
new_files:
  - android/feature/portfolio/PortfolioCache.kt   # 命中 EA-Client-07 performance-cache
EA-Client-07_prior_state: baseline   # 之前 weighted=1 不达 threshold=2
EA-Client-07_combined_weight: 3      # 加上 PortfolioCache weight=2 → 总 weight=3 ≥ threshold=2
```

**升级路径**：

```json
{
  "dimension_id": "EA-Client-07",
  "state_before": "baseline",
  "state_after": "activated",
  "reason": "combined weight 3 >= threshold 2; new signal: PortfolioCache.kt (performance-cache, weight=2)",
  "changed": true
}
```

**触发效果**：
- generation agent 为 EA-Client-07 重生成完整规则正文
- `standard-android.md §EA-Client-07` 从 `[baseline]` 更新为 `[activated]`
- 用户收到通知："EA-Client-07 启动性能优化因新 evidence 升级为 activated"

---

## 六、质量门禁与合并

- 门禁 A：仅核查受影响维度（2 维）+ activation-report.json 格式 → PASS
- 门禁 B：覆盖率按全量计（未重评维度保留上次分数）→ PASS
- merge-coordinator：只更新 activation-report.json（2 条 dimensions 更新），其余文件 mtime 不变

---

## 七、产物总结

```
changed:
  - engineering-standards/01-app-client/evidence/dimension-activation-report.json
    （EA-Client-01 / EA-Client-02 的 depth_score / evidence_count / last_evaluated_at）

unchanged（skip）:
  - standard-kmp-shared.md
  - standard-android.md
  - 所有 SEC-* / XSEC-* 规范文件
```

---

## 八、与全量模式的对比

| 指标 | full 模式 | diff 模式（本例） |
| --- | --- | --- |
| 评估维度数 | 30 | 2 |
| 文件变更数 | ~8 | 1（仅 activation-report.json） |
| 运行时间（估算） | ~15 min | ~2 min |
| 适用场景 | 初次萃取 / force-rebuild | 日常迭代后增量更新 |
