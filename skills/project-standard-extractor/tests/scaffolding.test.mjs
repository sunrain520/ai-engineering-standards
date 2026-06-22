import test from 'node:test';
import assert from 'node:assert/strict';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import yaml from 'yaml';
import { repoRoot } from './test-helpers.mjs';

test('runtime package and scaffold files exist', async () => {
  const packageJson = JSON.parse(await fs.readFile(path.join(repoRoot, 'package.json'), 'utf8'));
  assert.equal(packageJson.type, 'module');
  for (const script of ['pse:profile', 'pse:facts', 'pse:mine', 'pse:gates', 'pse:validate', 'pse:render', 'pse:merge', 'pse:full-auto', 'test']) {
    assert.ok(packageJson.scripts[script], `missing script ${script}`);
  }

  for (let index = 1; index <= 8; index += 1) {
    const files = await fs.readdir(path.join(repoRoot, 'skills/project-standard-extractor/agents'));
    assert.ok(files.some((file) => file.startsWith(String(index).padStart(2, '0'))), `missing agent ${index}`);
  }

  const gitignore = await fs.readFile(path.join(repoRoot, '.gitignore'), 'utf8');
  assert.match(gitignore, /^\.runs\/$/m);
  assert.doesNotMatch(gitignore, /engineering-standards/);
});

test('skill package governance artifacts are wired to the entrypoint', async () => {
  const skillRoot = path.join(repoRoot, 'skills/project-standard-extractor');
  const skill = await fs.readFile(path.join(skillRoot, 'SKILL.md'), 'utf8');
  for (const ref of [
    'manifest.json',
    'agents/interface.yaml',
    'evals/trigger-cases.json',
    'evals/output-cases.json',
    'reports/trust_report.md',
    'reports/output_quality_scorecard.md'
  ]) {
    assert.match(skill, new RegExp(ref.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')), `SKILL.md should reference ${ref}`);
    await fs.access(path.join(skillRoot, ref));
  }

  const manifest = JSON.parse(await fs.readFile(path.join(skillRoot, 'manifest.json'), 'utf8'));
  assert.equal(manifest.name, 'project-standard-extractor');
  assert.equal(manifest.maturity_tier, 'production');
  assert.equal(manifest.review_cadence, 'quarterly');
  assert.ok(manifest.input_files.includes('agents/interface.yaml'));
  assert.ok(manifest.output_contract.includes('engineering-standards/04-backend/standard-java-spring.md'));
  assert.equal(manifest.factory_components.evals, 'evals/');
  assert.equal(manifest.factory_components.reports, 'reports/');
  for (const file of manifest.input_files) {
    await fs.access(path.join(skillRoot, file));
  }

  const iface = yaml.parse(await fs.readFile(path.join(skillRoot, 'agents/interface.yaml'), 'utf8'));
  assert.equal(iface.name, 'project-standard-extractor');
  assert.equal(iface.mode, 'production');
  assert.equal(iface.capability.supported_targets[0].sub_domain, 'java-spring');
  assert.ok(iface.safety.forbidden.includes('modify business project source'));
});

test('skill package evals and reports expose route, output and trust boundaries', async () => {
  const skillRoot = path.join(repoRoot, 'skills/project-standard-extractor');
  const triggerCases = JSON.parse(await fs.readFile(path.join(skillRoot, 'evals/trigger-cases.json'), 'utf8'));
  const outputCases = JSON.parse(await fs.readFile(path.join(skillRoot, 'evals/output-cases.json'), 'utf8'));
  assert.ok(triggerCases.cases.some((item) => item.kind === 'should-trigger'));
  assert.ok(triggerCases.cases.some((item) => item.kind === 'should-not-trigger'));
  assert.ok(triggerCases.cases.some((item) => item.kind === 'near-neighbor'));
  assert.ok(triggerCases.cases.some((item) => item.id === 'boundary-placeholder-frontend'));
  assert.ok(outputCases.cases.length >= 5);
  assert.ok(outputCases.cases.some((item) => item.kind === 'file-backed fixture'));
  assert.ok(outputCases.cases.some((item) => item.assertions.some((assertion) => assertion.includes('warning routes'))));
  for (const item of outputCases.cases) {
    for (const file of item.input_files) {
      await fs.access(path.join(skillRoot, file));
    }
  }

  const trust = await fs.readFile(path.join(skillRoot, 'reports/trust_report.md'), 'utf8');
  const scorecard = await fs.readFile(path.join(skillRoot, 'reports/output_quality_scorecard.md'), 'utf8');
  for (const label of ['trust report', 'input_files', 'file-backed fixture', 'output contract', 'rollback boundary', 'missing evidence']) {
    assert.match(`${trust}\n${scorecard}`, new RegExp(label));
  }
  assert.match(scorecard, /reports\/output_quality_scorecard\.md/);
});
