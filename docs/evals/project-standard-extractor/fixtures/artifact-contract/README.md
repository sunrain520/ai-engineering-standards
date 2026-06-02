# Artifact Contract Fixtures

These fixtures are intentionally small generated-domain samples for `artifact-contract-validate.sh`.

- `valid-phase1/`: Phase 1 full-auto output without activation report.
- `valid-phase2/`: Phase 2 output with persisted `evidence/dimension-activation-report.json`.
- `invalid-phase1-activation-leak/`: negative fixture; it mirrors the valid Phase 1 shape but adds a forbidden Phase 1 `activation-report.json`.

Run the passing fixtures from the repo root:

```bash
bash tools/maintainer/project-standard-extractor/artifact-contract-validate.sh docs/evals/project-standard-extractor/fixtures/artifact-contract/valid-phase1 docs/evals/project-standard-extractor/fixtures/artifact-contract/valid-phase2
```

Run the negative fixture separately. It must fail with `PHASE1_ACTIVATION_REPORT_LEAK`.

```bash
bash tools/maintainer/project-standard-extractor/artifact-contract-validate.sh docs/evals/project-standard-extractor/fixtures/artifact-contract/invalid-phase1-activation-leak
```
