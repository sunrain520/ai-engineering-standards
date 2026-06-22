import test from 'node:test';
import assert from 'node:assert/strict';
import { runProfile } from '../scripts/run-profile.mjs';
import { runFactCollection } from '../scripts/run-fact-collection.mjs';
import { backendInput, copyJavaSampleToTemp, tempWorkspace, writeInput } from './test-helpers.mjs';

test('non-git input is not blocked and produces snapshot evidence', async () => {
  const workspaceRoot = await tempWorkspace();
  const sourcePath = await copyJavaSampleToTemp();
  const inputPath = await writeInput(workspaceRoot, backendInput([sourcePath]));
  const { run_id: runId, profile } = await runProfile({ inputPath, workspaceRoot, fixedTimestamp: '20260604-010203' });
  assert.equal(profile.source_projects[0].is_git_repo, false);
  const facts = await runFactCollection({ runId, workspaceRoot });
  assert.ok(facts.facts.every((fact) => fact.source_anchor.snapshot_id.startsWith('snapshot-')));
});
