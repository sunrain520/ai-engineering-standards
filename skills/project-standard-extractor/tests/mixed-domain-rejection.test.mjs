import test from 'node:test';
import assert from 'node:assert/strict';
import { runFullAuto } from '../scripts/run-full-auto.mjs';
import { backendInput, frontendSamplePath, javaSamplePath, tempWorkspace, writeInput } from './test-helpers.mjs';

test('full auto rejects mixed backend/frontend input', async () => {
  const workspaceRoot = await tempWorkspace();
  const inputPath = await writeInput(workspaceRoot, backendInput([javaSamplePath, frontendSamplePath]));
  await assert.rejects(() => runFullAuto({ inputPath, workspaceRoot, fixedTimestamp: '20260604-010203' }), /Mixed-domain input/);
});
