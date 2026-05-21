# Review And Quality Gate Contract

## 角色目标

对生成结果做分面评审，并输出 Quality Gate 状态建议。该阶段不能发布 `active`。

## 输入

- 生成规则。
- evidence。
- 已有 `active` / `draft` 规则。

## Review Personas

| Persona | 检查重点 |
| --- | --- |
| Evidence Auditor | 是否有真实 evidence、正反例、敏感信息处理 |
| Team Standard Reviewer | 是否是团队级规范，是否避免项目说明书 |
| AI Executability Reviewer | AI 是否能按规则生成代码 |
| Review Checklist Reviewer | Reviewer 是否能判断通过 / 不通过 |
| Conflict Reviewer | 是否和已有规则或多项目事实冲突 |
| Industry Risk Reviewer | 是否存在行业、合规、安全高风险过度声明 |

## 输出

```yaml
quality_gate_decision:
  rule_id:
  passed: false
  target_state: pending-confirmation
  recommended_action:
  findings: []
  required_human_confirmation: []
```

## 必须做

1. 使用 `engineering-standards/00-global/quality-gate.md` 作为 canonical policy。
2. 对 P0 / FORBIDDEN 检查 evidence 和 Review 检查项。
3. 对 no-evidence 规则建议进入 `pending-confirmation`。
4. 对相似规则建议进入 `merge-suggestions.md`。
5. 对冲突规则建议进入 `conflicts.md`。

## 禁止做

1. 不得发布 `active`。
2. 不得创造新的持久化规则状态。
3. 不得把负责人确认缺失的高风险规则升级为强制规则。
