export function evaluateGit001(rule, factsById) {
  for (const factId of rule.positive_evidence) {
    const fact = factsById.get(factId);
    if (!fact) continue;
    const anchor = fact.source_anchor;
    if (!fact.git.available) {
      const required = ['snapshot_id', 'path_hash', 'file', 'snippet_hash'];
      const missing = required.filter((key) => !anchor[key]);
      if (missing.length > 0 || !anchor.line_range?.start || !anchor.line_range?.end) {
        return { status: 'fail', reason: `Non-Git evidence missing ${missing.join(', ') || 'line_range'}.` };
      }
    }
  }
  return { status: 'pass', reason: 'Git or snapshot evidence anchors are valid.' };
}
