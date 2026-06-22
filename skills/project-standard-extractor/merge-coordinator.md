# Merge Coordinator

The merge coordinator copies validated formal outputs from `.runs/{run_id}/formal-output/` into the allowed `engineering-standards/{domain}/` directory.

Rules:
- Validate output path before every write.
- Never write another domain directory.
- Preserve formal output derivation from validated run artifacts.
- Keep `.runs/` transient.
