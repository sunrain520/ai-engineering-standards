import test from 'node:test';
import assert from 'node:assert/strict';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { runProfile } from '../scripts/run-profile.mjs';
import { backendInput, frontendSamplePath, javaSamplePath, tempWorkspace, writeInput } from './test-helpers.mjs';
import { assertOutputWithinDomain } from '../scripts/lib/domain-router.mjs';

test('profile creates running manifest for backend java input', async () => {
  const workspaceRoot = await tempWorkspace();
  const inputPath = await writeInput(workspaceRoot, backendInput());
  const result = await runProfile({ inputPath, workspaceRoot, fixedTimestamp: '20260604-010203' });
  assert.match(result.run_id, /^20260604-010203-backend-java-spring-/);
  const manifest = JSON.parse(await fs.readFile(path.join(workspaceRoot, '.runs', result.run_id, 'manifest.json'), 'utf8'));
  assert.equal(manifest.status, 'running');
  assert.equal(manifest.output_base_dir, 'engineering-standards/04-backend');
});

test('mixed-domain input is rejected before run creation', async () => {
  const workspaceRoot = await tempWorkspace();
  const inputPath = await writeInput(workspaceRoot, backendInput([javaSamplePath, frontendSamplePath]));
  await assert.rejects(() => runProfile({ inputPath, workspaceRoot, fixedTimestamp: '20260604-010203' }), /Mixed-domain input/);
});

test('merge boundary rejects another domain output', () => {
  assert.throws(
    () => assertOutputWithinDomain('engineering-standards/03-frontend/standard-vue.md', { domain: 'backend', sub_domain: 'java-spring' }),
    /outside allowed domain/
  );
});
