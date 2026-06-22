# Quality Gates

`project-standard-extractor` Phase 0 runs seven gates plus an autonomy policy before any rule can enter formal derived outputs.

| Gate | Implementation | Purpose |
| --- | --- | --- |
| Evidence | `scripts/lib/gates/evidence.mjs` | Require valid source-backed positive evidence, and verify all referenced evidence ids exist. |
| Actionability | `scripts/run-quality-gates.mjs` | Reject rules that cannot be executed or reviewed as concrete Must / Must Not guidance. |
| Abstraction | `scripts/run-quality-gates.mjs` | Reject rules that are too thin, and warn when a rule is tied to a single method shape. |
| Conflict | `scripts/lib/gates/conflict.mjs` | Route rules with positive and negative evidence away from auto-active output. |
| Risk | `scripts/lib/gates/risk.mjs` | Require Owner confirmation for high-risk or owner-required rules. |
| Derivation | `scripts/lib/gates/derivation.mjs` | Ensure AI rules and review checklist items derive from evidence-backed standard rules. |
| GIT-001 | `scripts/lib/gates/git-001.mjs` | Enforce Git commit anchors or non-Git snapshot anchors. |
| Autonomy Policy | `scripts/lib/autonomy-policy.mjs` | Score confidence and decide whether the extractor can publish autonomously or must route to Owner. |

The executable entrypoint is `scripts/run-quality-gates.mjs`, which writes `rule-decision.v1.json` for each run.

## Autonomy Policy

Every rule decision includes:

- `confidence.score`: weighted score from evidence strength, evidence distribution, actionability, abstraction, conflict absence, risk clarity, derivation integrity and anchor integrity.
- `confidence.tier`: `low`, `medium` or `high`.
- `autonomy.mode`: `autonomous` or `owner-gated`.
- `autonomy.owner_gate`: `none`, `conflict` or `high-risk`.
- `decision_trace`: deterministic decision passes that explain where the rule published or stopped.

Publishing rule:

- Low/medium-risk rules publish as `auto-active` when all gates pass and `confidence.score >= 0.75`.
- Evidence gaps stay `draft` with `next_action: collect-more-evidence`.
- Abstraction/actionability refinement gaps stay `draft` with `next_action: refine-rule`.
- Conflict, high-risk or explicit `owner_required` rules are the only rules routed to Owner review.

## Warning Routing

Warnings never enter `auto-active` output silently.

- `evidence_gate: warning` routes to `decision: draft` and `next_action: collect-more-evidence`.
- `abstraction_gate: warning` or future actionability warnings route to `decision: draft` and `next_action: refine-rule`.
- `risk_gate: warning` routes to `decision: pending-confirmation` and `next_action: owner-review`.
- `conflict_gate: warning|fail` routes to `decision: conflict` and `next_action: owner-review`.
