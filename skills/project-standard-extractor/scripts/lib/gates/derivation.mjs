export function evaluateDerivation(rule, evidenceResult) {
  if (evidenceResult.status === 'fail') {
    return { status: 'fail', reason: 'Derived outputs cannot use a rule without accepted evidence.' };
  }
  if (!rule.ai_coding_rule || rule.review_checklist.length === 0) {
    return { status: 'warning', reason: 'Rule has no derived AI or review output.' };
  }
  return { status: 'pass', reason: 'Derived outputs reference an evidence-backed standard rule.' };
}
