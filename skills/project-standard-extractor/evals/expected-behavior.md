# Expected Behavior

公开稳定路径的一次有效运行必须满足以下结果。

## Profile First

- Broad input 默认只生成 `project-profile.md`、`extraction-map.md`、`batch-plan.md`。
- `batch-plan.md` 必须列出 batch id、domain、sub_domain、candidate files、excluded paths、evidence limit、rule limit 和 stop conditions。
- 未选择 batch 前不得调用 generation。

## Selected Batch

- 只消费单个 `selected_batch.batch_id` 的 evidence。
- 不要求 `activation-report`，不读取 `dimension-activator`。
- 生成 `standard-{sub_domain}.md`、`ai-rules.md`、`review-checklist.md` 时必须能追溯到 code facts 或负责人确认。
- 规则默认 `status: draft`，不得自动发布 `active`。

## Safety And Merge

- 规则正文不写真实项目绝对路径；路径只允许出现在 evidence 文件中。
- 敏感配置和生产凭据只记录脱敏存在事实，不读取原文。
- 不覆盖已有 active 或 draft；相近内容写 `merge-suggestions.md`，冲突内容写 `conflicts.md`。
- `ai-rules.md` 与 `review-checklist.md` 只能从 standard 派生，不新增独立规则。

## Blocked Phase 2

- 普通萃取不得进入 Phase 2 `dimension-activator`、cross-project、EA-Doc、securities PoC 或 force-rebuild runtime。
- 维护者 repair / force-rebuild 验证用例保留在仓库级 `docs/evals/project-standard-extractor/`，不作为公开 skill 触发面。
