import path from 'node:path';
import { assertOutputWithinDomain, routeForTarget } from './domain-router.mjs';
import { ensureDir, writeJson, writeText } from './fs-utils.mjs';

export async function renderFormalOutputs({ workspaceRoot, runId, profile, codeFacts, standardRules, ruleDecisions }) {
  const target = profile.extraction_target;
  const route = routeForTarget(target);
  const outputRoot = path.join(workspaceRoot, '.runs', runId, 'formal-output', route.outputDir);
  await ensureDir(outputRoot);

  const decisionsByRule = new Map(ruleDecisions.decisions.map((decision) => [decision.rule_id, decision]));
  const factsById = new Map(codeFacts.facts.map((fact) => [fact.fact_id, fact]));
  const activeRules = standardRules.rules.filter((rule) => decisionsByRule.get(rule.rule_id)?.decision === 'auto-active');
  const pendingRules = standardRules.rules.filter((rule) => ['draft', 'pending-confirmation'].includes(decisionsByRule.get(rule.rule_id)?.decision));
  const conflictRules = standardRules.rules.filter((rule) => decisionsByRule.get(rule.rule_id)?.decision === 'conflict');

  const files = new Map();
  files.set(`standard-${target.sub_domain}.md`, renderStandard({ target, standardRules, decisionsByRule, factsById, runId }));
  files.set(`ai-rules-${target.sub_domain}.md`, renderAiRules({ target, activeRules }));
  files.set(`review-checklist-${target.sub_domain}.md`, renderReviewChecklist({ target, activeRules }));
  files.set('pending-confirmation.md', renderPending({ pendingRules, decisionsByRule }));
  files.set('conflicts.md', renderConflicts({ conflictRules, decisionsByRule }));

  for (const [file, content] of files) {
    const rel = `${route.outputDir}/${file}`;
    assertOutputWithinDomain(rel, target);
    await writeText(path.join(outputRoot, file), content);
  }

  await writeJson(path.join(outputRoot, 'rules-index.json'), renderRulesIndex({ activeRules, decisionsByRule, target }));
  await writeJson(path.join(outputRoot, 'lineage-ledger.json'), renderLineage({ standardRules, decisionsByRule, runId }));
  await writeJson(path.join(outputRoot, 'owner-decision-queue.json'), renderOwnerQueue({ standardRules, decisionsByRule }));

  for (const rule of standardRules.rules) {
    const evidenceContent = renderEvidence({ rule, factsById, runId });
    const rel = `${route.outputDir}/evidence/${target.sub_domain}/${rule.rule_id}.md`;
    assertOutputWithinDomain(rel, target);
    await writeText(path.join(outputRoot, 'evidence', target.sub_domain, `${rule.rule_id}.md`), evidenceContent);
  }

  return { outputRoot, activeRules: activeRules.length, pendingRules: pendingRules.length, conflictRules: conflictRules.length };
}

function renderStandard({ target, standardRules, decisionsByRule, factsById, runId }) {
  const lines = [
    '---',
    `doc_id: ${target.domain}-${target.sub_domain}-standard`,
    `domain: ${target.domain}`,
    `sub_domain: ${target.sub_domain}`,
    'doc_type: standard',
    'index_format: engineering-standards-md-v1',
    `generated_by_run: ${runId}`,
    '---',
    '',
    `# ${target.sub_domain} 后端开发规范`,
    '',
    '## 适用范围',
    '',
    `本规范适用于 \`${target.domain}/${target.sub_domain}\` 抽取目标，由源码 evidence 和质量门禁派生。`,
    '',
    '## 规则'
  ];

  for (const rule of standardRules.rules) {
    const decision = decisionsByRule.get(rule.rule_id);
    lines.push('', `### ${rule.rule_id}. ${rule.title}`, '', `- Status: ${decision?.decision ?? rule.status}`, `- Level: ${rule.level}`, `- Risk: ${rule.risk_level}`);
    if (decision?.confidence) {
      lines.push(`- Confidence: ${decision.confidence.score} (${decision.confidence.tier})`);
    }
    if (decision?.autonomy) {
      lines.push(`- Autonomy: ${decision.autonomy.mode} / ${decision.autonomy.policy}`);
    }
    lines.push(`- Rule: ${rule.rule_text}`);
    for (const must of rule.must) lines.push(`- Must: ${must}`);
    for (const mustNot of rule.must_not) lines.push(`- Must Not: ${mustNot}`);
    lines.push('- Evidence:');
    for (const factId of [...rule.positive_evidence, ...rule.negative_evidence].slice(0, 12)) {
      const fact = factsById.get(factId);
      if (fact) {
        lines.push(`  - ${factId}: ${fact.source_anchor.file}:${fact.source_anchor.line_range.start} (${fact.source_anchor.snippet_hash})`);
      }
    }
  }

  return `${lines.join('\n')}\n`;
}

function renderAiRules({ target, activeRules }) {
  const lines = [`# ${target.sub_domain} AI Rules`, '', '## Must'];
  for (const rule of activeRules) {
    lines.push(`- ${rule.ai_coding_rule} (standard: ${rule.rule_id})`);
  }
  lines.push('', '## Must Not');
  for (const rule of activeRules) {
    for (const mustNot of rule.must_not) {
      lines.push(`- ${mustNot} (standard: ${rule.rule_id})`);
    }
  }
  return `${lines.join('\n')}\n`;
}

function renderReviewChecklist({ target, activeRules }) {
  const lines = [`# ${target.sub_domain} Review Checklist`, ''];
  for (const rule of activeRules) {
    for (const item of rule.review_checklist) {
      lines.push(`- [ ] ${item} (standard: ${rule.rule_id})`);
    }
  }
  return `${lines.join('\n')}\n`;
}

function renderPending({ pendingRules, decisionsByRule }) {
  const lines = ['# Pending Confirmation', ''];
  for (const rule of pendingRules) {
    const decision = decisionsByRule.get(rule.rule_id);
    lines.push(`## ${rule.rule_id}. ${rule.title}`, '', `- Decision: ${decision?.decision}`);
    if (decision?.confidence) {
      lines.push(`- Confidence: ${decision.confidence.score} (${decision.confidence.tier})`);
    }
    if (decision?.autonomy) {
      lines.push(`- Autonomy: ${decision.autonomy.mode} / ${decision.autonomy.policy}`);
    }
    lines.push(`- Reason: ${decision?.reason}`, '');
  }
  return `${lines.join('\n')}\n`;
}

function renderConflicts({ conflictRules, decisionsByRule }) {
  const lines = ['# Conflicts', ''];
  for (const rule of conflictRules) {
    const decision = decisionsByRule.get(rule.rule_id);
    lines.push(`## ${rule.rule_id}. ${rule.title}`, '');
    if (decision?.confidence) {
      lines.push(`- Confidence: ${decision.confidence.score} (${decision.confidence.tier})`);
    }
    if (decision?.autonomy) {
      lines.push(`- Autonomy: ${decision.autonomy.mode} / ${decision.autonomy.policy}`);
    }
    lines.push(`- Reason: ${decision?.reason}`, `- Positive evidence: ${rule.positive_evidence.join(', ') || 'none'}`, `- Negative evidence: ${rule.negative_evidence.join(', ') || 'none'}`, '');
  }
  return `${lines.join('\n')}\n`;
}

function renderRulesIndex({ activeRules, decisionsByRule, target }) {
  return {
    index_format: 'engineering-standards-rules-index-v2',
    rules: activeRules.map((rule) => ({
      rule_id: rule.rule_id,
      title: rule.title,
      domain: target.domain,
      sub_domain: target.sub_domain,
      level: rule.level,
      status: decisionsByRule.get(rule.rule_id)?.decision,
      source_doc: `04-backend/standard-${target.sub_domain}.md`,
      authority_scope: rule.authority_scope,
      deterministic_occurrence_count: rule.positive_evidence.length,
      confidence_score: decisionsByRule.get(rule.rule_id)?.confidence?.score ?? null,
      confidence_tier: decisionsByRule.get(rule.rule_id)?.confidence?.tier ?? null,
      autonomy_mode: decisionsByRule.get(rule.rule_id)?.autonomy?.mode ?? null,
      autonomy_policy: decisionsByRule.get(rule.rule_id)?.autonomy?.policy ?? null,
      risk_tag: rule.risk_level,
      tags: [target.domain, target.sub_domain, rule.risk_level, decisionsByRule.get(rule.rule_id)?.confidence?.tier].filter(Boolean)
    }))
  };
}

function renderLineage({ standardRules, decisionsByRule, runId }) {
  return {
    schema: 'lineage-ledger.v1',
    entries: standardRules.rules.map((rule) => ({
      rule_id: rule.rule_id,
      created_by_run: runId,
      source_patterns: rule.source_patterns,
      source_facts: [...rule.positive_evidence, ...rule.negative_evidence],
      source_projects: rule.source_projects,
      status_history: [{ status: decisionsByRule.get(rule.rule_id)?.decision ?? rule.status, time: new Date().toISOString(), reason: 'Initial extraction' }]
    }))
  };
}

function renderOwnerQueue({ standardRules, decisionsByRule }) {
  const items = standardRules.rules
    .filter((rule) => ['conflict', 'pending-confirmation'].includes(decisionsByRule.get(rule.rule_id)?.decision))
    .map((rule, index) => ({
      queue_id: `ODQ-${String(index + 1).padStart(3, '0')}`,
      rule_id: rule.rule_id,
      decision_required: 'confirm-or-reject',
      reason: decisionsByRule.get(rule.rule_id)?.reason ?? 'Owner decision required.',
      suggested_owner_role: `${rule.domain}-architecture-owner`,
      options: ['owner-confirmed-active', 'draft', 'legacy-compatible', 'owner-rejected'],
      confidence_score: decisionsByRule.get(rule.rule_id)?.confidence?.score ?? null,
      owner_gate: decisionsByRule.get(rule.rule_id)?.autonomy?.owner_gate ?? 'none'
    }));
  return { schema: 'owner-decision-queue.v1', items };
}

function renderEvidence({ rule, factsById, runId }) {
  const lines = [`# Evidence for ${rule.rule_id}`, '', `- Created by run: ${runId}`, ''];
  for (const factId of [...rule.positive_evidence, ...rule.negative_evidence]) {
    const fact = factsById.get(factId);
    if (!fact) continue;
    lines.push(`## ${factId}`, '', `- Kind: ${fact.kind}`, `- Observation: ${fact.observation}`, `- Source: ${fact.source_anchor.file}:${fact.source_anchor.line_range.start}`, `- Snippet hash: ${fact.source_anchor.snippet_hash}`, `- Path hash: ${fact.source_anchor.path_hash}`, '');
  }
  return `${lines.join('\n')}\n`;
}
