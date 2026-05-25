---
name: three-state-cases
description: 三态激活机制评估场景：AE7（baseline 不进执行路径）/ AE8（candidate 升级条件）/ AE10（无 evidence → candidate）
type: evals
phase: phase-2
ae: [AE7, AE8, AE10]
---

# Three-State Activation Cases

## TSC-001 — AE7: baseline 维度不进 AI 默认执行路径

**Given**

```yaml
domain: 01-app-client
dimension_id: EA-Client-07
activation_state: baseline
evidence_tier: real-evidence
ai_rules_section: "EA-Client-07 启动性能优化"
```

baseline 维度通过加权阈值检查,但 weight 合计未达 threshold=2（仅 weight=1 信号命中）。

**When**

AI agent 读取 `standard-android.md` 并执行代码审查。

**Then**

- `EA-Client-07` 章节的 inline metadata 含 `status: baseline`
- AI 不将 baseline 章节作为强制规则推入默认执行路径（不出现在 `ai-rules.md` 顶层 must 列表中）
- baseline 章节在 `standard.md` 中仍存在并可被人工引用（骨架不丢失）
- `dimension-activation-report.json` 中 `EA-Client-07.state = "baseline"` 且 `depth_indicator = "shallow"`
- `pending-confirmation.md` 中存在对应条目,说明"weighted 未达阈值,建议 owner 确认是否有遗漏 signal"

**回归断言（grep）**

```bash
grep -A3 "EA-Client-07" standard-android.md | grep -q "baseline"
grep "EA-Client-07" ai-rules.md | grep -vq "must"   # 不进 must 列表
```

---

## TSC-002 — AE8: candidate 维度有明确升级条件

**Given**

```yaml
domain: 09-industry
dimension_id: SEC-09
activation_state: candidate
candidate_hint: "出现 pricing/market-making/greeks 模块 + 风险敞口字段"
```

project 为经纪业务平台,无自营定价模块。

**When**

generation agent 填充 `01-securities-standard.md §6.9 SEC-09`。

**Then**

- §6.9 章节含 `[candidate]` 状态标注
- 章节内含 candidate_hint 说明升级条件（至少包含"pricing/market-making/greeks"关键词）
- `未激活维度地图` 表格中 SEC-09 行存在,升级条件清晰
- `dimension-activation-report.json` 中 `SEC-09.candidate_hint` 字段非空
- 不生成任何 AI 强制规则（`ai-rules.md` 中 SEC-09 节只有 advisory 标注）

**回归断言（jq）**

```bash
jq '.dimensions[] | select(.dimension_id=="SEC-09") | .state' activation-report.json | grep -q "candidate"
jq '.dimensions[] | select(.dimension_id=="SEC-09") | .candidate_hint' activation-report.json | grep -q "pricing"
```

---

## TSC-003 — AE10: 无 evidence → candidate，不强制生成

**Given**

```yaml
domain: 04-backend
dimension_id: EA-Backend-09
activation_signals: []    # 扫描后零信号命中
evidence_tier: real-evidence
```

**When**

dimension-activator 完成信号扫描,发现 EA-Backend-09 无任何 signal 命中。

**Then**

- `EA-Backend-09.state = "candidate"`（不强制写成 activated）
- generation agent **不生成** EA-Backend-09 的规则正文（骨架节占位,但规则体为空或注释为"待 evidence"）
- `pending-confirmation.md` 中不强制添加 EA-Backend-09 条目（无 evidence 不是 pending,是 candidate）
- `dimension-activation-report.json` 中 `EA-Backend-09.evidence_count = 0`，`depth_score = 0.0`
- `candidate_hint` 说明需要什么信号才能触发激活

**回归断言**

```bash
jq '.dimensions[] | select(.dimension_id=="EA-Backend-09") | .evidence_count' report.json | grep -q "^0$"
jq '.dimensions[] | select(.dimension_id=="EA-Backend-09") | .state' report.json | grep -q "candidate"
```
