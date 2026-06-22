# Output Quality Scorecard

`reports/output_quality_scorecard.md` records the current output eval posture for `project-standard-extractor`.

## Scope

- input_files: `evals/golden-samples/java-spring/project-input.json`, `evals/golden-samples/java-spring/sample-service` and `tests/quality-gates.test.mjs`.
- file-backed fixture: Java Spring golden sample under `evals/golden-samples/java-spring/sample-service`.
- output contract: formal outputs under `engineering-standards/04-backend/` and run artifacts under `.runs/{run_id}/`, including confidence and autonomy fields in `rule-decision.v1`.
- rollback boundary: source changes are limited to this skill package, root package metadata and `CHANGELOG.md`; business project source is read-only.

## Case Summary

| Case | Type | Expected signal |
| --- | --- | --- |
| `output-java-spring-formal-artifacts` | file-backed fixture | standard, AI rules and checklist are generated with traceable rule ids. |
| `output-owner-queue-for-conflict` | boundary | conflict rules stay out of auto-active output and enter Owner queue. |
| `output-autonomous-confidence-decision` | file-backed fixture | low/medium-risk passing rules expose confidence and autonomous publish policy. |
| `output-non-git-evidence-anchors` | file-backed fixture | filesystem evidence uses snapshot and hash anchors. |
| `output-mixed-domain-rejection` | near-neighbor | mixed backend/frontend input is rejected before formal writes. |
| `output-warning-state-not-silent-active` | boundary | warning gate states produce explicit draft or Owner next actions. |

## Current Score

- Baseline without skill: not scored; no reusable evidence-backed workflow exists in the package.
- With-skill deterministic assertions: covered by `npm test`.
- Model-executed output eval: missing evidence.
- Blind A/B review pack: missing evidence.
- Human adjudication: scoped to conflict, high-risk and explicit owner-required rules; blind A/B adjudication remains missing evidence.

## Recommended Next Fix

Record provider-backed model output eval only after a reviewed runner is available. Until then, treat this scorecard as deterministic local evidence, not provider-backed model evidence.
