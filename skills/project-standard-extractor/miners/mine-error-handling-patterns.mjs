export function mineErrorHandlingPatterns(facts) {
  const exceptionFacts = facts.filter((fact) => fact.scope !== 'test' && fact.kind === 'exception');
  if (exceptionFacts.length === 0) return [];
  return [{
    pattern_id: 'PAT-BE-JAVA-EXCEPTION-001',
    title: 'Centralized exception handling exists',
    category: 'exception',
    source_fact_ids: exceptionFacts.slice(0, 8).map((fact) => fact.fact_id),
    positive_fact_ids: exceptionFacts.slice(0, 8).map((fact) => fact.fact_id),
    negative_fact_ids: [],
    occurrence_count: exceptionFacts.length,
    module_diversity: new Set(exceptionFacts.map((fact) => fact.module)).size,
    role_diversity: [...new Set(exceptionFacts.map((fact) => fact.role))],
    risk_level: 'medium',
    suggested_rule_level: 'P1',
    suggested_state: exceptionFacts.length >= 2 ? 'auto-active' : 'draft',
    reason: 'Exception handler anchors were detected.'
  }];
}
