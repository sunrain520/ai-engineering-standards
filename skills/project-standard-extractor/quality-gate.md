# project-standard-extractor Quality Gate

本文件是 Skill 侧 workflow adapter。Canonical policy 见 `engineering-standards/00-global/quality-gate.md`。

## 执行顺序

1. 读取全局 `quality-gate.md`。
2. 对每条规则收集 evidence、AI Rules、Review Checklist。
3. 运行六个分面 reviewer。
4. 汇总为一个 `quality_gate_decision`。
5. 交给 Merge Coordinator 写入目标文件。

## 状态建议

| 条件 | target_state |
| --- | --- |
| 有 evidence、可执行、可检查、无冲突 | `draft` |
| 已有负责人确认且无冲突 | `draft`，并输出 `recommended_action: consider promotion`，由负责人手动处理 |
| 无 evidence 或需确认 | `pending-confirmation` |
| 与已有规则或事实冲突 | `conflict` |
| 历史包袱只允许保留 | `legacy-compatible` |
| 不可执行、不可检查或包含敏感信息 | `rejected` |

## 输出格式

```yaml
quality_gate_decision:
  rule_id:
  target_state:
  recommended_action:
  evidence_result:
  team_standard_result:
  ai_executability_result:
  review_checklist_result:
  example_result:
  conflict_result:
  industry_risk_result:
  required_human_confirmation:
```
