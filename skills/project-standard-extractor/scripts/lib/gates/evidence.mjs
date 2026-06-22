export function evaluateEvidence(rule, factsById) {
  const evidenceIds = [...rule.positive_evidence, ...rule.negative_evidence];
  const missing = evidenceIds.filter((factId) => !factsById.has(factId));
  if (rule.positive_evidence.length === 0 || missing.length > 0) {
    return { status: 'fail', reason: 'Rule lacks valid source evidence.' };
  }
  if (rule.positive_evidence.length < 2) {
    return { status: 'warning', reason: 'Rule has evidence but not enough deterministic occurrences for auto-active.' };
  }
  return { status: 'pass', reason: 'Evidence is present.' };
}
