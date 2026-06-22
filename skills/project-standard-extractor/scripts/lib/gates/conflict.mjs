export function evaluateConflict(rule) {
  if (rule.negative_evidence.length > 0) {
    return { status: 'warning', reason: 'Positive and negative evidence both exist.' };
  }
  return { status: 'pass', reason: 'No conflict detected.' };
}
