# 01 Intake And Scope

Input contract: `project-input.v1`.

Output contracts: `manifest.json`, `repo-profile.v1`, `batch-plan.v1`.

Responsibilities:
- Validate single `extraction_target`.
- Reject mixed-domain input.
- Detect sensitive files and unreadable paths.
- Generate `run_id`, `snapshot_id`, `input_fingerprint`.

Forbidden:
- Do not create rules.
- Do not write formal standards output.
