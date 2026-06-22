import { cp, mkdtemp, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
export const javaSamplePath = path.join(repoRoot, 'skills/project-standard-extractor/evals/golden-samples/java-spring/sample-service');
export const frontendSamplePath = path.join(repoRoot, 'skills/project-standard-extractor/evals/golden-samples/frontend');

export async function tempWorkspace(prefix = 'pse-test-') {
  return mkdtemp(path.join(os.tmpdir(), prefix));
}

export async function writeInput(workspaceRoot, payload) {
  const file = path.join(workspaceRoot, 'input.json');
  await writeFile(file, `${JSON.stringify(payload, null, 2)}\n`, 'utf8');
  return file;
}

export function backendInput(projectPaths = [javaSamplePath]) {
  return {
    schema: 'project-input.v1',
    extraction_target: { domain: 'backend', sub_domain: 'java-spring' },
    project_paths: projectPaths,
    scope: { include: ['**/*'], exclude: ['**/target/**', '**/build/**', '**/generated/**'] },
    output: { base_dir: 'engineering-standards/04-backend', mode: 'append-only' }
  };
}

export async function copyJavaSampleToTemp() {
  const root = await tempWorkspace('pse-source-');
  const target = path.join(root, 'sample-service');
  await cp(javaSamplePath, target, { recursive: true });
  return target;
}
