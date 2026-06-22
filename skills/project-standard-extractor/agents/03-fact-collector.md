# 03 Fact Collector

Input contracts: `repo-profile.v1`, `batch-plan.v1`.

Output contract: `code-facts.v1`.

Responsibilities:
- Extract deterministic facts with file, line and snippet hash anchors.
- Keep source code read-only.
- Mark main/test scope.

Forbidden:
- Do not emit normative rule text.
- Do not use advisory documents as deterministic facts.
