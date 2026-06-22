export function mineApiPatterns(facts) {
  const apiFacts = facts.filter((fact) => fact.scope !== 'test' && fact.kind === 'spring-api');
  if (apiFacts.length < 2) return [];
  const highRisk = apiFacts.some((fact) => /login|logout|auth|security|permission|权限|认证|安全/i.test(fact.source_anchor.file));
  return [{
    pattern_id: 'PAT-BE-JAVA-API-001',
    title: 'Spring MVC annotations define backend HTTP APIs',
    category: 'api',
    source_fact_ids: apiFacts.slice(0, 12).map((fact) => fact.fact_id),
    positive_fact_ids: apiFacts.slice(0, 12).map((fact) => fact.fact_id),
    negative_fact_ids: [],
    occurrence_count: apiFacts.length,
    module_diversity: new Set(apiFacts.map((fact) => fact.module)).size,
    role_diversity: [...new Set(apiFacts.map((fact) => fact.role))],
    risk_level: highRisk ? 'high' : 'medium',
    suggested_rule_level: 'P1',
    suggested_state: highRisk ? 'pending-confirmation' : 'auto-active',
    reason: highRisk
      ? 'Spring MVC endpoint annotations include authentication or permission related API anchors, so Owner confirmation is required.'
      : 'Spring MVC endpoint annotations appear repeatedly in production scope.'
  }];
}
