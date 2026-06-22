#!/usr/bin/env node
import path from 'node:path';
import { parseArgs, requireArg } from './lib/args.mjs';
import { readJson, writeJson } from './lib/fs-utils.mjs';
import { runDir } from './lib/manifest.mjs';
import { assertValid } from './lib/contracts.mjs';
import { evaluateEvidence } from './lib/gates/evidence.mjs';
import { evaluateConflict } from './lib/gates/conflict.mjs';
import { evaluateRisk } from './lib/gates/risk.mjs';
import { evaluateDerivation } from './lib/gates/derivation.mjs';
import { evaluateGit001 } from './lib/gates/git-001.mjs';
import { evaluateAutonomyPolicy } from './lib/autonomy-policy.mjs';

export async function runQualityGates({ runId, workspaceRoot = process.cwd() }) {
  const dir = runDir(workspaceRoot, runId);
  const codeFacts = await readJson(path.join(dir, 'code-facts.v1.json'));
  const standardRules = await readJson(path.join(dir, 'standard-rule.v1.json'));
  const factsById = new Map(codeFacts.facts.map((fact) => [fact.fact_id, fact]));

  const decisions = standardRules.rules.map((rule) => evaluateRule(rule, factsById));
  const artifact = {
    schema: 'rule-decision.v1',
    run_id: runId,
    decisions
  };
  await assertValid('rule-decision.v1', artifact, 'rule-decision');
  await writeJson(path.join(dir, 'rule-decision.v1.json'), artifact);
  return artifact;
}

export function evaluateRule(rule, factsById) {
  const evidence = evaluateEvidence(rule, factsById);
  const actionability = evaluateActionability(rule);
  const abstraction = evaluateAbstraction(rule);
  const conflict = evaluateConflict(rule);
  const risk = evaluateRisk(rule);
  const derivation = evaluateDerivation(rule, evidence);
  const git001 = evaluateGit001(rule, factsById);

  const gate_results = {
    evidence_gate: evidence.status,
    actionability_gate: actionability.status,
    abstraction_gate: abstraction.status,
    conflict_gate: conflict.status,
    risk_gate: risk.status,
    derivation_gate: derivation.status,
    git_001_gate: git001.status
  };

  const autonomyDecision = evaluateAutonomyPolicy({
    rule,
    gateResults: gate_results,
    gateDetails: { evidence, actionability, abstraction, conflict, risk, derivation, git001 },
    factsById
  });

  return {
    rule_id: rule.rule_id,
    decision: autonomyDecision.decision,
    gate_results,
    confidence: autonomyDecision.confidence,
    autonomy: autonomyDecision.autonomy,
    decision_trace: autonomyDecision.decision_trace,
    reason: [evidence, actionability, abstraction, conflict, risk, derivation, git001]
      .filter((result) => result.status !== 'pass')
      .map((result) => result.reason)
      .join(' ') || `${autonomyDecision.autonomy.rationale}`,
    next_action: autonomyDecision.next_action
  };
}

function evaluateActionability(rule) {
  const text = `${rule.rule_text} ${rule.must.join(' ')} ${rule.must_not.join(' ')}`;
  if (!rule.must.length && !rule.must_not.length) {
    return { status: 'fail', reason: 'Rule has no Must or Must Not statements.' };
  }
  if (/代码要优雅|接口要合理|注意异常|模块要清晰/.test(text)) {
    return { status: 'fail', reason: 'Rule is too vague to execute or review.' };
  }
  return { status: 'pass', reason: 'Rule has actionable wording.' };
}

function evaluateAbstraction(rule) {
  if (/#\w+\(/.test(rule.rule_text)) {
    return { status: 'warning', reason: 'Rule may be too tied to a single method.' };
  }
  if (rule.rule_text.length < 12) {
    return { status: 'fail', reason: 'Rule text is too thin.' };
  }
  return { status: 'pass', reason: 'Rule abstraction is acceptable.' };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = parseArgs();
  const artifact = await runQualityGates({ runId: requireArg(args, 'run-id'), workspaceRoot: args['workspace-root'] ?? process.cwd() });
  console.log(JSON.stringify({ decisions: artifact.decisions.length }, null, 2));
}
