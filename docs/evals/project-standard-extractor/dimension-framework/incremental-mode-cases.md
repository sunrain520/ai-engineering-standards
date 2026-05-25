---
name: incremental-mode-cases
description: 增量模式评估场景：AE14（diff 模式只重评受影响维度）
type: evals
phase: phase-2
ae: [AE14]
---

# Incremental Mode Cases

## IMC-001 — AE14: diff 模式 → 只重评受影响维度

**Given**

```yaml
project_path: /mock/kaz-mvp
extraction_mode: diff
diff_scope:
  changed_files:
    - shared/domain/OrderModel.kt          # KMP shared domain 变更
    - android/feature/trade/TradeViewModel.kt  # Android feature 变更
  unchanged_modules:
    - account-service/
    - risk-service/
    - cross-border/
prior_activation_map:
  EA-Client-01: activated    # KMP shared
  EA-Client-02: activated    # Android
  EA-Client-03: baseline     # iOS（本次无变更）
  EA-Backend-04: activated   # MQ（本次无变更）
  SEC-01: activated          # KYC（本次无变更）
```

**When**

diff-scoper agent 分析 `changed_files`,diff-activator 只重评与变更文件相关的维度。

**Then**

- 只重评 `EA-Client-01`（KMP shared 变更）和 `EA-Client-02`（Android 变更）
- `EA-Client-03`、`EA-Backend-04`、`SEC-01` **不**重跑（unchanged_modules 覆盖范围不变）
- `dimension-activation-report.json` 中重评维度的 `last_evaluated_at` 为本次时间戳;未重评维度保留上次时间戳
- `evolution.transitions[]` 中若状态有变更则记录（state_before / state_after / reason）；若无变更则不新增条目
- 产物只更新受影响章节（`standard-kmp-shared.md`、`standard-android.md`）；其他文件不修改
- 速度: 重评维度数 ≤ 总维度数的 50%（diff 模式效率验证）

**回归断言**

```bash
# 被跳过的维度 last_evaluated_at 不变
jq '.dimensions[] | select(.dimension_id=="EA-Client-03") | .last_evaluated_at' report.json == \
   jq '.dimensions[] | select(.dimension_id=="EA-Client-03") | .last_evaluated_at' prior-report.json

# 受影响维度有新评估时间戳
jq '.dimensions[] | select(.dimension_id=="EA-Client-01") | .last_evaluated_at' report.json | grep -q "2026"
```
