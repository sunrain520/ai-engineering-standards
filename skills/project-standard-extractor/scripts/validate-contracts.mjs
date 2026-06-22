#!/usr/bin/env node
import path from 'node:path';
import fg from 'fast-glob';
import { parseArgs } from './lib/args.mjs';
import { readJson } from './lib/fs-utils.mjs';
import { runDir } from './lib/manifest.mjs';
import { assertValid, validateSchemas } from './lib/contracts.mjs';

export async function runValidateContracts({ runId, workspaceRoot = process.cwd() } = {}) {
  const schemaResults = await validateSchemas();
  const invalidSchemas = schemaResults.filter((result) => !result.valid);
  if (invalidSchemas.length > 0) {
    throw new Error(`Invalid schemas: ${invalidSchemas.map((result) => result.schema).join(', ')}`);
  }

  const artifactResults = [];
  if (runId) {
    const dir = runDir(workspaceRoot, runId);
    const files = await fg(['*.v1.json'], { cwd: dir, onlyFiles: true });
    for (const file of files) {
      const artifact = await readJson(path.join(dir, file));
      if (artifact.schema) {
        await assertValid(artifact.schema, artifact, file);
        artifactResults.push(file);
      }
    }
  }
  return { schemas: schemaResults.length, artifacts: artifactResults };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = parseArgs();
  const result = await runValidateContracts({ runId: args['run-id'], workspaceRoot: args['workspace-root'] ?? process.cwd() });
  console.log(JSON.stringify(result, null, 2));
}
