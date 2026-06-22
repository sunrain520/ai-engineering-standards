# Output Risk Profile

## Artifact Family

`project-standard-extractor` produces reviewer-facing Markdown reports, JSON indexes and AI Coding Rules derived from source evidence.

## Likely Output Failures

| Risk | Guard |
| --- | --- |
| Generic best practices without source evidence | Evidence gate requires fact ids and `code-facts.v1` anchors. |
| AI rules diverge from accepted standards | Derivation gate and renderer only use `auto-active` standard rules. |
| Local absolute paths leak into formal output | Rendering tests reject `/Users/` in formal artifacts. |
| Low-confidence rules become active silently | Autonomy policy requires all gates and `confidence.score >= 0.75` before `auto-active`. |
| Warning states become active silently | `rule-decision.v1` uses explicit `next_action` routing for evidence, abstraction, risk and conflict warnings. |
| Owner queue becomes a catch-all for model uncertainty | Evidence and abstraction gaps stay autonomous draft/refinement; Owner gate is reserved for conflict, high risk or explicit `owner_required`. |
| Placeholder domains are mistaken for implemented extractors | Trigger eval includes frontend boundary rejection. |

## Current Missing Evidence

- missing evidence: provider-backed model output eval has not been run.
- missing evidence: blind A/B human adjudication has not been recorded.
- missing evidence: runtime permission probes for packaged adapters have not been generated.
