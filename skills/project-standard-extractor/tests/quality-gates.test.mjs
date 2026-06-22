import test from 'node:test';
import assert from 'node:assert/strict';
import { runProfile } from '../scripts/run-profile.mjs';
import { runFactCollection } from '../scripts/run-fact-collection.mjs';
import { runPatternMining } from '../scripts/run-pattern-mining.mjs';
import { runQualityGates, evaluateRule } from '../scripts/run-quality-gates.mjs';
import { backendInput, tempWorkspace, writeInput } from './test-helpers.mjs';

test('quality gates route conflicts away from auto-active', async () => {
  const workspaceRoot = await tempWorkspace();
  const inputPath = await writeInput(workspaceRoot, backendInput());
  const { run_id: runId } = await runProfile({ inputPath, workspaceRoot, fixedTimestamp: '20260604-010203' });
  await runFactCollection({ runId, workspaceRoot });
  await runPatternMining({ runId, workspaceRoot });
  const artifact = await runQualityGates({ runId, workspaceRoot });
  assert.ok(artifact.decisions.some((decision) => decision.decision === 'conflict'));
  assert.ok(artifact.decisions.some((decision) => decision.decision === 'auto-active'));
  assert.ok(artifact.decisions.every((decision) => typeof decision.confidence?.score === 'number'));
  assert.ok(artifact.decisions.every((decision) => decision.autonomy?.mode));
  assert.ok(artifact.decisions.some((decision) => decision.decision === 'auto-active' && decision.autonomy.policy === 'auto-publish'));
});

test('semantic gates fail vague rules', () => {
  const decision = evaluateRule({
    rule_id: 'rule-vague',
    rule_text: '代码要优雅',
    must: ['代码要优雅'],
    must_not: [],
    positive_evidence: ['FACT-1'],
    negative_evidence: [],
    ai_coding_rule: '代码要优雅',
    review_checklist: ['代码是否优雅？'],
    risk_level: 'medium',
    owner_required: false
  }, new Map([['FACT-1', {
    fact_id: 'FACT-1',
    git: { available: false },
    source_anchor: {
      snapshot_id: 'snapshot-x',
      path_hash: 'sha256:x',
      file: 'src/App.java',
      line_range: { start: 1, end: 1 },
      snippet_hash: 'sha256:y'
    }
  }]]));
  assert.equal(decision.decision, 'rejected');
  assert.equal(decision.gate_results.actionability_gate, 'fail');
  assert.equal(decision.autonomy.mode, 'autonomous');
  assert.equal(decision.autonomy.policy, 'reject');
});

test('evidence gate rejects missing negative evidence anchors', () => {
  const decision = evaluateRule({
    rule_id: 'rule-missing-negative-evidence',
    rule_text: 'Controller 层不得直接访问 Mapper。',
    must: ['Controller must delegate to Service.'],
    must_not: ['Controller must not call Mapper directly.'],
    positive_evidence: ['FACT-1', 'FACT-2'],
    negative_evidence: ['FACT-MISSING'],
    ai_coding_rule: 'Do not call Mapper from Controller.',
    review_checklist: ['Controller 是否直接访问 Mapper？'],
    risk_level: 'medium',
    owner_required: false
  }, new Map([
    ['FACT-1', nonGitFact('FACT-1', 1)],
    ['FACT-2', nonGitFact('FACT-2', 2)]
  ]));

  assert.equal(decision.decision, 'rejected');
  assert.equal(decision.gate_results.evidence_gate, 'fail');
});

test('evidence warnings remain draft with explicit evidence next action', () => {
  const decision = evaluateRule({
    rule_id: 'rule-low-evidence',
    rule_text: '新增 Java Spring HTTP API 时必须使用明确的 Controller 映射注解。',
    must: ['Controller endpoints must use Spring MVC mapping annotations.'],
    must_not: ['Do not expose HTTP behavior without a controller mapping annotation.'],
    positive_evidence: ['FACT-1'],
    negative_evidence: [],
    ai_coding_rule: 'Use explicit Spring MVC mapping annotations.',
    review_checklist: ['新增接口是否具备明确映射注解？'],
    risk_level: 'medium',
    owner_required: false
  }, new Map([['FACT-1', nonGitFact('FACT-1', 1)]]));

  assert.equal(decision.decision, 'draft');
  assert.equal(decision.next_action, 'collect-more-evidence');
  assert.equal(decision.gate_results.evidence_gate, 'warning');
  assert.equal(decision.autonomy.mode, 'autonomous');
  assert.equal(decision.autonomy.owner_gate, 'none');
  assert.equal(decision.confidence.tier, 'medium');
});

test('abstraction warnings remain draft with explicit refinement next action', () => {
  const decision = evaluateRule({
    rule_id: 'rule-method-specific',
    rule_text: 'OrderController#create() 必须使用明确的 Spring MVC 映射注解。',
    must: ['Controller endpoints must use Spring MVC mapping annotations.'],
    must_not: ['Do not expose HTTP behavior without a controller mapping annotation.'],
    positive_evidence: ['FACT-1', 'FACT-2'],
    negative_evidence: [],
    ai_coding_rule: 'Use explicit Spring MVC mapping annotations.',
    review_checklist: ['新增接口是否具备明确映射注解？'],
    risk_level: 'medium',
    owner_required: false
  }, new Map([
    ['FACT-1', nonGitFact('FACT-1', 1)],
    ['FACT-2', nonGitFact('FACT-2', 2)]
  ]));

  assert.equal(decision.decision, 'draft');
  assert.equal(decision.next_action, 'refine-rule');
  assert.equal(decision.gate_results.abstraction_gate, 'warning');
  assert.equal(decision.autonomy.mode, 'autonomous');
  assert.equal(decision.autonomy.policy, 'refine-rule');
});

test('risk warnings keep owner-required rules out of auto-active output', () => {
  const decision = evaluateRule({
    rule_id: 'rule-owner-required',
    rule_text: '认证相关接口变更必须由 Owner 确认后才能成为 active 规范。',
    must: ['Authentication-sensitive API rules must be confirmed by an Owner.'],
    must_not: ['Do not auto-activate authentication-sensitive rules.'],
    positive_evidence: ['FACT-1', 'FACT-2'],
    negative_evidence: [],
    ai_coding_rule: 'Escalate authentication-sensitive API rules to Owner review.',
    review_checklist: ['认证相关规则是否已经 Owner 确认？'],
    risk_level: 'high',
    owner_required: true
  }, new Map([
    ['FACT-1', nonGitFact('FACT-1', 1)],
    ['FACT-2', nonGitFact('FACT-2', 2)]
  ]));

  assert.equal(decision.decision, 'pending-confirmation');
  assert.equal(decision.next_action, 'owner-review');
  assert.equal(decision.gate_results.risk_gate, 'warning');
  assert.equal(decision.autonomy.mode, 'owner-gated');
  assert.equal(decision.autonomy.owner_gate, 'high-risk');
});

test('low and medium risk rules publish autonomously when gates and confidence pass', () => {
  const decision = evaluateRule({
    rule_id: 'rule-autonomous',
    title: 'Controller 必须使用明确映射注解',
    rule_text: '新增 Java Spring HTTP API 时必须使用明确的 Controller 映射注解。',
    must: ['Controller endpoints must use Spring MVC mapping annotations.'],
    must_not: ['Do not expose HTTP behavior without a controller mapping annotation.'],
    positive_evidence: ['FACT-1', 'FACT-2', 'FACT-3'],
    negative_evidence: [],
    ai_coding_rule: 'Use explicit Spring MVC mapping annotations.',
    review_checklist: ['新增接口是否具备明确映射注解？'],
    risk_level: 'medium',
    owner_required: false
  }, new Map([
    ['FACT-1', nonGitFact('FACT-1', 1, 'src/OrderController.java')],
    ['FACT-2', nonGitFact('FACT-2', 2, 'src/AccountController.java')],
    ['FACT-3', nonGitFact('FACT-3', 3, 'src/UserController.java')]
  ]));

  assert.equal(decision.decision, 'auto-active');
  assert.equal(decision.next_action, 'publish');
  assert.equal(decision.autonomy.mode, 'autonomous');
  assert.equal(decision.autonomy.owner_gate, 'none');
  assert.equal(decision.autonomy.policy, 'auto-publish');
  assert.ok(decision.confidence.score >= decision.confidence.threshold);
  assert.equal(decision.confidence.signals.conflict_absence, 1);
});

function nonGitFact(factId, line, file = 'src/App.java') {
  return {
    fact_id: factId,
    git: { available: false },
    source_anchor: {
      snapshot_id: 'snapshot-x',
      path_hash: 'sha256:x',
      file,
      line_range: { start: line, end: line },
      snippet_hash: 'sha256:y'
    }
  };
}
