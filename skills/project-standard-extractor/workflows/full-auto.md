# Full Auto Workflow

1. Validate `project-input.v1`.
2. Create `run_id`, `snapshot_id`, manifest and repo profile.
3. Route to the selected domain/sub-domain.
4. Collect deterministic code facts.
5. Mine pattern candidates.
6. Synthesize standard-rule candidates from facts and patterns.
7. Run all quality gates.
8. Score confidence and apply autonomy policy.
9. Render formal outputs.
10. Merge into the allowed domain output directory.

Fail before formal writes when input, contract validation, evidence, or merge boundary checks fail.
