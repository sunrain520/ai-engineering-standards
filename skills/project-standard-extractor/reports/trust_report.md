# Trust Report

This trust report covers `project-standard-extractor` as a production skill package.

## Governed Boundary

- input_files: `SKILL.md`, `agents/interface.yaml`, `contracts/*.schema.json`, `scripts/*.mjs`, and `evals/golden-samples/java-spring/project-input.json`.
- file-backed fixture: `evals/golden-samples/java-spring/sample-service`.
- output contract: `.runs/{run_id}/` intermediate artifacts and `engineering-standards/04-backend/` formal outputs, with confidence/autonomy evidence in `rule-decision.v1`.
- rollback boundary: revert this skill package, root package metadata and `CHANGELOG.md`; never roll back or mutate business project source.

## Script Surface

- Runtime: Node.js ESM scripts invoked through `npm run pse:*`.
- Network: no project-standard-extractor script intentionally performs network calls.
- Writes: `.runs/{run_id}/` and the active domain output directory only.
- Autonomous writes: low/medium-risk rules publish only after all gates pass and confidence reaches the autonomous threshold.
- Owner-gated writes: conflict, high-risk or explicit owner-required rules stay out of derived AI/review outputs until confirmed.
- Business source: read-only.

## Dependency Surface

- `ajv` and `ajv-formats` validate JSON contracts.
- `fast-glob` scans project files.
- `gray-matter` and `yaml` are available project dependencies; `yaml` is used by tests to validate `agents/interface.yaml`.

## Permission And Secret Posture

- Sensitive file detection is handled during intake.
- Formal evidence output uses hashed paths and snippet hashes rather than local absolute source paths.
- missing evidence: no dedicated secret-scan report has been generated for this package.
- missing evidence: runtime permission probes for packaged adapters are not available.

## Reviewer Evidence

- `reports/output_quality_scorecard.md` records output assertions and current missing evidence.
- `evals/trigger-cases.json` records trigger, non-trigger, near-neighbor and boundary cases.
- `evals/output-cases.json` records output contract assertions.
