# 06 Quality Gate

Input contracts: `standard-rule.v1`, `code-facts.v1`, `pattern-candidates.v1`.

Output contract: `rule-decision.v1`.

Responsibilities:
- Run Evidence, Actionability, Abstraction, Conflict, Risk, Derivation and GIT-001 gates.
- Compute multi-signal confidence for every rule decision.
- Apply autonomy policy: publish low/medium-risk rules when gates and confidence pass; route only conflict/high-risk/owner-required rules to Owner review.
- Fail closed when required gate data is absent.
- Route evidence/abstraction gaps to autonomous draft refinement instead of Owner review.
- Route conflict and high-risk rules away from active outputs.

Forbidden:
- Do not auto-activate high-risk rules.
- Do not ask an Owner to adjudicate ordinary low-confidence rules that need more evidence or refinement.
