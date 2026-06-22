const AUTO_ACTIVE_THRESHOLD = 0.75;

export function evaluateAutonomyPolicy({ rule, gateResults, gateDetails, factsById }) {
  const confidence = scoreRuleConfidence({ rule, gateResults, factsById });
  const allGatesPass = Object.values(gateResults).every((status) => status === 'pass');
  const hardFail = [gateDetails.evidence, gateDetails.actionability, gateDetails.abstraction, gateDetails.derivation, gateDetails.git001]
    .some((result) => result.status === 'fail');
  const refinementWarning = [gateDetails.actionability, gateDetails.abstraction].some((result) => result.status === 'warning');

  const decisionTrace = [
    traceStep('gate-screen', !hardFail, hardFail ? 'required gate failed' : 'required gates did not fail'),
    traceStep('conflict-screen', gateDetails.conflict.status === 'pass', gateDetails.conflict.reason),
    traceStep('risk-screen', gateDetails.risk.status === 'pass', gateDetails.risk.reason),
    traceStep('confidence-score', confidence.score >= AUTO_ACTIVE_THRESHOLD, `confidence=${confidence.score}, tier=${confidence.tier}`),
    traceStep('autonomy-policy', allGatesPass && confidence.score >= AUTO_ACTIVE_THRESHOLD, 'low/medium risk rules may publish autonomously when all gates pass')
  ];

  if (hardFail) {
    return {
      decision: 'rejected',
      next_action: 'fix-or-drop-rule',
      confidence,
      autonomy: autonomy('autonomous', 'none', 'reject', 'Required gate failure is handled by the extractor, not by Owner adjudication.'),
      decision_trace: decisionTrace
    };
  }

  if (gateDetails.conflict.status !== 'pass') {
    return {
      decision: 'conflict',
      next_action: 'owner-review',
      confidence,
      autonomy: autonomy('owner-gated', 'conflict', 'owner-review', 'Conflicting positive and negative evidence requires organizational intent, not more model scoring.'),
      decision_trace: decisionTrace
    };
  }

  if (gateDetails.risk.status !== 'pass') {
    return {
      decision: 'pending-confirmation',
      next_action: 'owner-review',
      confidence,
      autonomy: autonomy('owner-gated', 'high-risk', 'owner-review', 'High-risk or owner-required rules need explicit authorization before they constrain future work.'),
      decision_trace: decisionTrace
    };
  }

  if (gateDetails.evidence.status === 'warning') {
    return {
      decision: 'draft',
      next_action: 'collect-more-evidence',
      confidence,
      autonomy: autonomy('autonomous', 'none', 'collect-more-evidence', 'Evidence is below the autonomous publish threshold; the system should collect more facts before asking an Owner.'),
      decision_trace: decisionTrace
    };
  }

  if (refinementWarning || confidence.score < AUTO_ACTIVE_THRESHOLD) {
    return {
      decision: 'draft',
      next_action: 'refine-rule',
      confidence,
      autonomy: autonomy('autonomous', 'none', 'refine-rule', 'The rule is not risky enough for Owner review; the extractor should refine wording, abstraction or evidence strength.'),
      decision_trace: decisionTrace
    };
  }

  if (allGatesPass) {
    return {
      decision: 'auto-active',
      next_action: 'publish',
      confidence,
      autonomy: autonomy('autonomous', 'none', 'auto-publish', 'All gates passed and confidence is above the autonomous publish threshold.'),
      decision_trace: decisionTrace
    };
  }

  return {
    decision: 'draft',
    next_action: 'keep-draft',
    confidence,
    autonomy: autonomy('autonomous', 'none', 'keep-draft', 'No owner gate was triggered, but publishability was not proven.'),
    decision_trace: decisionTrace
  };
}

export function scoreRuleConfidence({ rule, gateResults, factsById }) {
  const positiveFacts = rule.positive_evidence.map((factId) => factsById.get(factId)).filter(Boolean);
  const distinctFiles = new Set(positiveFacts.map((fact) => fact.source_anchor?.file).filter(Boolean)).size;
  const signalScores = {
    evidence_strength: scoreEvidenceStrength(rule.positive_evidence.length),
    evidence_distribution: scoreEvidenceDistribution(distinctFiles),
    actionability: scoreGate(gateResults.actionability_gate),
    abstraction: scoreGate(gateResults.abstraction_gate),
    conflict_absence: scoreGate(gateResults.conflict_gate),
    risk_clarity: scoreRisk(rule, gateResults.risk_gate),
    derivation_integrity: scoreGate(gateResults.derivation_gate),
    anchor_integrity: scoreGate(gateResults.git_001_gate)
  };

  const weights = {
    evidence_strength: 0.24,
    evidence_distribution: 0.08,
    actionability: 0.14,
    abstraction: 0.10,
    conflict_absence: 0.16,
    risk_clarity: 0.10,
    derivation_integrity: 0.12,
    anchor_integrity: 0.06
  };

  const score = round(Object.entries(weights).reduce((sum, [signal, weight]) => sum + signalScores[signal] * weight, 0));
  return {
    score,
    tier: score >= 0.85 ? 'high' : score >= 0.65 ? 'medium' : 'low',
    threshold: AUTO_ACTIVE_THRESHOLD,
    evidence_count: rule.positive_evidence.length,
    distinct_file_count: distinctFiles,
    signals: signalScores
  };
}

function scoreEvidenceStrength(count) {
  if (count >= 5) return 1;
  if (count >= 3) return 0.9;
  if (count >= 2) return 0.78;
  if (count === 1) return 0.45;
  return 0;
}

function scoreEvidenceDistribution(distinctFiles) {
  if (distinctFiles >= 3) return 1;
  if (distinctFiles === 2) return 0.85;
  if (distinctFiles === 1) return 0.6;
  return 0;
}

function scoreGate(status) {
  if (status === 'pass') return 1;
  if (status === 'warning') return 0.45;
  return 0;
}

function scoreRisk(rule, status) {
  if (status !== 'pass') return 0;
  if (rule.risk_level === 'low') return 1;
  if (rule.risk_level === 'medium') return 0.85;
  return 0;
}

function autonomy(mode, owner_gate, policy, rationale) {
  return { mode, owner_gate, policy, rationale };
}

function traceStep(step, passed, reason) {
  return {
    step,
    result: passed ? 'pass' : 'stop',
    reason
  };
}

function round(value) {
  return Math.round(value * 100) / 100;
}
