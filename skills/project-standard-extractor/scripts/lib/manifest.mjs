import path from 'node:path';
import { ensureDir, readJson, writeJson } from './fs-utils.mjs';

export function runDir(workspaceRoot, runId) {
  return path.join(workspaceRoot, '.runs', runId);
}

export async function writeManifest(workspaceRoot, manifest) {
  const dir = runDir(workspaceRoot, manifest.run_id);
  await ensureDir(dir);
  await writeJson(path.join(dir, 'manifest.json'), manifest);
  return manifest;
}

export async function updateManifestStatus(workspaceRoot, runId, status, extra = {}) {
  const file = path.join(runDir(workspaceRoot, runId), 'manifest.json');
  const manifest = await readJson(file);
  const next = { ...manifest, ...extra, status };
  await writeJson(file, next);
  return next;
}
