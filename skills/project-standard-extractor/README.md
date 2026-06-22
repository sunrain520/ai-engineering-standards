# project-standard-extractor

`project-standard-extractor` 是 domain-scoped 研发规范萃取 skill。它按单端运行，先用脚本抽源码事实，再把事实聚成模式，最后经过质量门禁和自治决策策略发布规范产物。

## Phase 0 Scope

- 共享骨架：入口、workflow、8 个 agent、domain-router、merge-coordinator、9 个合同、7 道门禁、自治决策策略和脚本。
- 单端闭环：`backend/java-spring`。
- 输出：`.runs/{run_id}/` 中间产物与 `engineering-standards/04-backend/` 正式产物。
- 自治发布：低/中风险、无冲突、门禁全通过且置信分达到阈值的规则进入 `auto-active`。
- Owner gate：只保留给 conflict、high risk 或显式 `owner_required` 的规则。

## Input

```json
{
  "schema": "project-input.v1",
  "extraction_target": { "domain": "backend", "sub_domain": "java-spring" },
  "project_paths": ["/path/to/java-service"],
  "scope": {
    "include": ["**/*"],
    "exclude": ["**/target/**", "**/build/**", "**/generated/**"]
  },
  "output": { "base_dir": "engineering-standards/04-backend", "mode": "append-only" }
}
```

## Commands

- `npm run pse:full-auto -- --input <project-input.json>`
- `npm run pse:validate -- --run-id <run_id>`
- `npm test`

## Package Evidence

- `manifest.json`: skill owner、maturity、review cadence、input_files、output contract 和 rollback boundary。
- `agents/interface.yaml`: 供调用者和 reviewer 使用的输入、输出、workflow、safety 和验证接口。
- `evals/trigger-cases.json`: should-trigger、should-not-trigger、near-neighbor 和 Phase 0 boundary case。
- `evals/output-cases.json`: 规范产物、派生纪律、自治决策、Owner queue、非 Git evidence 和跨端拒绝断言。
- `reports/trust_report.md` 与 `reports/output_quality_scorecard.md`: trust report、输出质量分数卡和 missing evidence。

## Boundaries

- 不改业务源码。
- 不引入 AST/CodeGraph。
- CodeWiki/PR Review 等外部来源本轮只保留 adapter 占位，不进入 facts 层。
- 证据不足或抽象不足由系统保持 draft 并继续收证/优化，不升级成人工裁定。
- 高风险、冲突或显式 `owner_required` 规则只进入 Owner 待裁定，不自动 active。
