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
10. 上下文治理门禁：是否遵守 full-auto 外层循环、单 batch worker、artifact handoff 和候选索引边界。

## 规则定位

- **不使用 Rule ID**;输出与所有内部表格使用 `(source_doc, section_title)` 二元组。

## 执行剖面（Phase 1 / Phase 2 分支）

**Phase 1 full-auto（缺失 `activation_report` 且存在 `batch_summary.batch_id`）**：
- 只执行 Gate A（P1-P8 content gate）+ structure/runtime policy 检查
- `final_gate_decision` 直接取 Gate A 决议
- `activation_gate_outcome` 固定输出 `phase1-not-applicable`
- 不跑 Gate B，不做 activation-report 收口校验

**Phase 2 dimension-aware（存在 `activation_report`）**：
- 先执行 Gate A，再串行执行 Gate B
- Gate B 决议**优先**于 Gate A（pending-confirmation 强制 move-to-pending；shallow 强制 keep-draft-low-coverage）

## 输出

每条规则一份 `quality_gate_decision`，字段对齐 `references/agents/review-and-quality-gate.md` 的 schema：

```yaml
quality_gate_decision:
  source_doc: ""
  section_title: ""        # 与 standard.md H2 字面一致
  passed: false
  target_state: ""         # auto-active / owner-confirmed-active / draft / pending-confirmation / conflict / legacy-compatible / stale-auto-active / owner-rejected / rejected
  recommended_action: ""   # auto-activate / keep-draft / keep-draft-low-coverage / move-to-pending / mark-conflict / mark-legacy / mark-stale-auto-active / mark-owner-rejected / reject / defer
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

不得新发布 `owner-confirmed-active`(那是负责人手工动作,本阶段只能识别或保留既有签字状态)。只有通过 BR-016/BR-017 且 lineage 判据完整的规则可 `auto-activate`。`recommended_action` 取值见 `references/config/frontmatter-format.md §4.7`,不得自创。
