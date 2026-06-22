import test from 'node:test';
import assert from 'node:assert/strict';
import { runProfile } from '../scripts/run-profile.mjs';
import { runFactCollection } from '../scripts/run-fact-collection.mjs';
import { runPatternMining } from '../scripts/run-pattern-mining.mjs';
import { backendInput, tempWorkspace, writeInput } from './test-helpers.mjs';

test('pattern mining produces conflict-aware candidates and rules', async () => {
  const workspaceRoot = await tempWorkspace();
  const inputPath = await writeInput(workspaceRoot, backendInput());
  const { run_id: runId } = await runProfile({ inputPath, workspaceRoot, fixedTimestamp: '20260604-010203' });
  await runFactCollection({ runId, workspaceRoot });
  const { patternArtifact, standardArtifact } = await runPatternMining({ runId, workspaceRoot });
  assert.ok(patternArtifact.patterns.some((pattern) => pattern.suggested_state === 'conflict'));
  assert.ok(standardArtifact.rules.some((rule) => rule.negative_evidence.length > 0));
});
