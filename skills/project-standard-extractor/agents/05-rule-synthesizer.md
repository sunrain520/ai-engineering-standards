# 05 Rule Synthesizer

Input contracts: `pattern-candidates.v1`, `code-facts.v1`.

Output contract: `standard-rule.v1`.

Responsibilities:
- Convert evidence-backed patterns into rule candidates.
- Include Must / Must Not / AI rule / Review checklist text.
- Reference only existing fact IDs.

Forbidden:
- Do not invent evidence.
- Do not emit rules outside the active domain/sub-domain.
