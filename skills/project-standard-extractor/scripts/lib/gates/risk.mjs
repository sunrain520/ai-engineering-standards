import { inferRiskLevel } from '../risk-tags.mjs';

export function evaluateRisk(rule) {
  const level = rule.risk_level === 'high' || inferRiskLevel(`${rule.title} ${rule.rule_text}`) === 'high' ? 'high' : rule.risk_level;
  if (level === 'high' || rule.owner_required) {
    return { status: 'warning', reason: 'High-risk or owner-required rule must be confirmed by Owner.' };
  }
  return { status: 'pass', reason: 'Risk does not require Owner confirmation.' };
}
