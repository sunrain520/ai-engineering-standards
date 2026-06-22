export function mineLayeringPatterns(facts) {
  const mainFacts = facts.filter((fact) => fact.scope !== 'test');
  const controllers = mainFacts.filter((fact) => fact.role === 'controller');
  const services = mainFacts.filter((fact) => fact.role === 'service');
  const violations = mainFacts.filter((fact) => fact.kind === 'layering-violation');
  if (controllers.length === 0 || services.length === 0) {
    return [];
  }

  const positive = [...controllers.slice(0, 8), ...services.slice(0, 8)];
  return [
    {
      pattern_id: 'PAT-BE-JAVA-LAYERING-001',
      title: 'Controller delegates business work below web layer',
      category: 'layering',
      source_fact_ids: [...positive, ...violations].map((fact) => fact.fact_id),
      positive_fact_ids: positive.map((fact) => fact.fact_id),
      negative_fact_ids: violations.map((fact) => fact.fact_id),
      occurrence_count: positive.length,
      module_diversity: new Set(positive.map((fact) => fact.module)).size,
      role_diversity: [...new Set(positive.map((fact) => fact.role))],
      risk_level: 'medium',
      suggested_rule_level: 'P1',
      suggested_state: violations.length > 0 ? 'conflict' : positive.length >= 2 ? 'auto-active' : 'draft',
      reason: violations.length > 0
        ? 'Controller/service layering is common, but direct Mapper/Repository references were also observed.'
        : 'Controller and service anchors appear repeatedly without detected direct data access conflicts.'
    }
  ];
}
