# Expected Behavior

> Authority: package-local smoke subset only. Full source-of-truth: `docs/evals/project-standard-extractor/expected-behavior.md`.

公开稳定路径的一次有效运行必须满足以下结果。

## Full-auto Profile First

- Broad input 默认进入 `full-auto`，内部先生成 `project-profile.md`、`extraction-map.md`、`batch-plan.md`、`ordered_batch_queue` 和 `coverage_report`。
- `batch-plan.md` 必须列出 batch id、domain、sub_domain、candidate files、excluded paths、evidence limit、rule limit 和 stop conditions。
- full-auto 外层按 queue 调用 generation；每次仍只传一个 selected batch。

## Selected Batch

- 只消费单个 `selected_batch.batch_id` 的 evidence。
- 不要求 `activation-report`，不读取 `dimension-activator`。
- 生成 `standard-{sub_domain}.md`、`ai-rules.md`、`review-checklist.md` 时必须能追溯到 code facts 或负责人确认。
- 通过高置信闸的规则可写 `status: auto-active`；不得自动写 `owner-confirmed-active`。
- `draft` / `pending-confirmation` 不进入 AI 默认执行路径。

## Safety And Merge

- 规则正文不写真实项目绝对路径；路径只允许出现在 evidence 文件中。
- 敏感配置和生产凭据只记录脱敏存在事实，不读取原文。
- 不覆盖已有 owner-confirmed-active / legacy active 或 draft；相近内容写 `merge-suggestions.md`，冲突内容写 `conflicts.md`。
- `ai-rules.md` 与 `review-checklist.md` 只能从 standard 派生，不新增独立规则。
- 每条 auto-active 必须有 lineage ledger 和 owner decision queue 条目。

## Blocked Phase 2

- 普通萃取不得进入 Phase 2 `dimension-activator`、cross-project、EA-Doc、securities PoC 或 force-rebuild runtime。
- 维护者 repair / force-rebuild 验证用例保留在仓库级 `docs/evals/project-standard-extractor/`，不作为公开 skill 触发面。
