# project-standard-extractor Quality Gate

本文件是 Skill 侧 workflow adapter。Canonical policy 见 `engineering-standards/00-global/quality-gate.md`。

## 规则定位

- **不使用 Rule ID**;门禁输出与所有内部表格使用 `(source_doc, section_title)` 二元组。

## 执行顺序

1. 读取全局 `quality-gate.md`。
2. 对每条规则收集 evidence、AI Rules、Review Checklist。
3. 运行六个分面 reviewer。
4. 汇总为一个 `quality_gate_decision`。
5. 交给 Merge Coordinator 写入目标文件。

## 状态建议

`recommended_action` 取值见 `config/frontmatter-format.md §4.7`,**不得**自创枚举(包括"consider promotion"等)。

| 条件 | target_state | recommended_action |
| --- | --- | --- |
| 有 evidence、可执行、可检查、无冲突 | `draft` | `keep-draft` |
| 已有负责人确认且无冲突 | `draft` | `promote-to-active`(由负责人手动改 status,Skill 不自动发布) |
| 无 evidence 或需确认 | `pending-confirmation` | `move-to-pending` |
| 与已有规则或事实冲突 | `conflict` | `mark-conflict` |
| 历史包袱只允许保留 | `legacy-compatible` | `mark-legacy` |
| 不可执行、不可检查或包含敏感信息 | `rejected` | `reject` |
| 评审材料不足,需要下一轮萃取 | 维持原状 | `defer` |

## 输出格式

```yaml
quality_gate_decision:
  source_doc:
  section_title:
  target_state:
  recommended_action:
  evidence_result:
  team_standard_result:
  ai_executability_result:
  review_checklist_result:
  example_result:
  conflict_result:
  industry_risk_result:
  required_human_confirmation: []
```
