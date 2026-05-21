# {Domain} AI Coding Rules

## 1. 规则使用边界

AI 默认只执行：

- `status` 为 `active`。
- 或 `status` 为 `draft` 且 `source_kind` 为 `extracted` / `owner-confirmed`、`evidence_tier` 不为 `none`。

AI 不得执行：

- `pending-confirmation`
- `conflict`
- `rejected`
- `source_kind: template-placeholder`
- `evidence_tier: none`

## 2. 生成前必须检查

1. 当前需求属于哪个子领域？
2. 是否已有 `active` 或 evidence-backed `draft` 规则？
3. 是否有待合并或冲突规则？
4. 是否涉及高风险模块？
5. 是否需要补充 evidence？

## 3. 生成时必须遵守

1. 遵守适用规则 ID。
2. 复用已有模块、组件、服务和数据访问入口。
3. 不把 DTO / Entity / 底层 API 暴露到不该暴露的层。
4. 不把单项目路径当成团队标准。

## 4. 生成后自检

```markdown
- 适用规则：
- evidence tier：
- 是否包含 draft warning：
- 是否存在 pending/conflict：
- 是否需要负责人确认：
```
