export const highRiskTerms = [
  '交易',
  '资金',
  '清结算',
  '权限',
  '认证',
  '隐私',
  '安全',
  '合规',
  '发布',
  '生产变更',
  '风控',
  'auth',
  'security',
  'payment',
  'fund',
  'privacy',
  'compliance'
];

export function inferRiskLevel(text) {
  const lower = text.toLowerCase();
  return highRiskTerms.some((term) => lower.includes(term.toLowerCase())) ? 'high' : 'medium';
}
