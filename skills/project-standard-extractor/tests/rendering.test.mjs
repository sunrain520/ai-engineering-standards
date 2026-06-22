import test from 'node:test';
import assert from 'node:assert/strict';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { runFullAuto } from '../scripts/run-full-auto.mjs';
import { backendInput, copyJavaSampleToTemp, tempWorkspace, writeInput } from './test-helpers.mjs';

test('full auto renders derived formal outputs without absolute paths', async () => {
  const workspaceRoot = await tempWorkspace();
  const sourcePath = await copyJavaSampleToTemp();
  const inputPath = await writeInput(workspaceRoot, backendInput([sourcePath]));
  const result = await runFullAuto({ inputPath, workspaceRoot, fixedTimestamp: '20260604-010203' });
  assert.equal(result.status, 'completed');
  const outputDir = path.join(workspaceRoot, 'engineering-standards/04-backend');
  const standard = await fs.readFile(path.join(outputDir, 'standard-java-spring.md'), 'utf8');
  const aiRules = await fs.readFile(path.join(outputDir, 'ai-rules-java-spring.md'), 'utf8');
  const checklist = await fs.readFile(path.join(outputDir, 'review-checklist-java-spring.md'), 'utf8');
  assert.match(standard, /Evidence:/);
  assert.match(standard, /Confidence:/);
  assert.match(standard, /Autonomy:/);
  assert.match(aiRules, /standard:/);
  assert.match(checklist, /standard:/);
  assert.doesNotMatch(standard + aiRules + checklist, /\/Users\//);
});
