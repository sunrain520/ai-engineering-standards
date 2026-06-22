export function mineForbiddenPatterns(facts) {
  const violations = facts.filter((fact) => fact.scope !== 'test' && fact.kind === 'layering-violation');
  if (violations.length === 0) return [];
  return [{
    pattern_id: 'PAT-BE-JAVA-FORBIDDEN-001',
    title: 'Controller direct data access is a forbidden layering signal',
    category: 'forbidden',
    source_fact_ids: violations.map((fact) => fact.fact_id),
    positive_fact_ids: [],
    negative_fact_ids: violations.map((fact) => fact.fact_id),
    occurrence_count: violations.length,
    module_diversity: new Set(violations.map((fact) => fact.module)).size,
    role_diversity: [...new Set(violations.map((fact) => fact.role))],
    risk_level: 'medium',
    suggested_rule_level: 'P1',
    suggested_state: 'conflict',
    reason: 'At least one controller directly references Mapper or Repository.'
  }];
}
