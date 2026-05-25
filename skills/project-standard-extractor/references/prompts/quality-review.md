# Quality Review Prompt

你是规范萃取的 Quality Gate。

请按以下门禁评审每条规则：

1. 证据门禁。
2. 团队级抽象门禁。
3. AI 可执行性门禁。
4. Review 可检查性门禁。
5. 正反例门禁。
6. 规则数量门禁。
7. 人工确认门禁。
8. 冲突门禁。
9. 行业风险门禁。
10. 上下文治理门禁：是否遵守 `profile-first`、选定 batch、artifact handoff 和候选索引边界。

## 规则定位

- **不使用 Rule ID**;输出与所有内部表格使用 `(source_doc, section_title)` 二元组。

## 输出

每条规则一份 `quality_gate_decision`，字段对齐 `references/agents/review-and-quality-gate.md` 的 schema：

```yaml
quality_gate_decision:
  source_doc: ""
  section_title: ""        # 与 standard.md H2 字面一致
  passed: false
  target_state: ""         # draft / pending-confirmation / conflict / legacy-compatible / rejected
  recommended_action: ""   # keep-draft / keep-draft-low-coverage / promote-to-active / move-to-pending / mark-conflict / mark-legacy / reject / defer
  confidence: ""           # high / medium / low（基于 7 persona 共识度）
  evidence_result: ""
  team_standard_result: ""
  ai_executability_result: ""
  review_checklist_result: ""
  example_result: ""
  conflict_result: ""
  industry_risk_result: ""
  context_governance_result: ""
  required_human_confirmation: []
  blocking_findings: []
  warnings: []
```

不得发布 `active`(那是负责人手工动作,不在本阶段)。`recommended_action` 取值见 `references/config/frontmatter-format.md §4.7`,不得自创。
