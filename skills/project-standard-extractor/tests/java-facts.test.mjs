import test from 'node:test';
import assert from 'node:assert/strict';
import { runProfile } from '../scripts/run-profile.mjs';
import { runFactCollection } from '../scripts/run-fact-collection.mjs';
import { backendInput, copyJavaSampleToTemp, tempWorkspace, writeInput } from './test-helpers.mjs';

test('java fact collection emits non-git source anchors', async () => {
  const workspaceRoot = await tempWorkspace();
  const sourcePath = await copyJavaSampleToTemp();
  const inputPath = await writeInput(workspaceRoot, backendInput([sourcePath]));
  const { run_id: runId } = await runProfile({ inputPath, workspaceRoot, fixedTimestamp: '20260604-010203' });
  const artifact = await runFactCollection({ runId, workspaceRoot });
  assert.ok(artifact.facts.some((fact) => fact.role === 'controller'));
  assert.ok(artifact.facts.some((fact) => fact.kind === 'layering-violation'));
  const nonGit = artifact.facts.find((fact) => !fact.git.available);
  assert.ok(nonGit.source_anchor.snapshot_id);
  assert.ok(nonGit.source_anchor.path_hash);
  assert.ok(nonGit.source_anchor.file);
  assert.ok(nonGit.source_anchor.snippet_hash);
});
