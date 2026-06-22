import test from 'node:test';
import assert from 'node:assert/strict';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { runFullAuto } from '../scripts/run-full-auto.mjs';
import { backendInput, copyJavaSampleToTemp, tempWorkspace, writeInput } from './test-helpers.mjs';

test('e2e java spring run writes completed manifest and governance outputs', async () => {
  const workspaceRoot = await tempWorkspace();
  const sourcePath = await copyJavaSampleToTemp();
  const inputPath = await writeInput(workspaceRoot, backendInput([sourcePath]));
  const { run_id: runId } = await runFullAuto({ inputPath, workspaceRoot, fixedTimestamp: '20260604-010203' });
  const manifest = JSON.parse(await fs.readFile(path.join(workspaceRoot, '.runs', runId, 'manifest.json'), 'utf8'));
  assert.equal(manifest.status, 'completed');
  for (const file of ['rules-index.json', 'lineage-ledger.json', 'owner-decision-queue.json', 'conflicts.md']) {
    await fs.access(path.join(workspaceRoot, 'engineering-standards/04-backend', file));
  }
  const ownerQueue = JSON.parse(await fs.readFile(path.join(workspaceRoot, 'engineering-standards/04-backend/owner-decision-queue.json'), 'utf8'));
  assert.ok(ownerQueue.items.length >= 1);
  assert.ok(ownerQueue.items.every((item) => typeof item.confidence_score === 'number'));
  assert.ok(ownerQueue.items.some((item) => ['conflict', 'high-risk'].includes(item.owner_gate)));
});
