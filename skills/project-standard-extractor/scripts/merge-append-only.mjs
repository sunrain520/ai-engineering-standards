#!/usr/bin/env node
import path from 'node:path';
import { parseArgs, requireArg } from './lib/args.mjs';
import { readJson } from './lib/fs-utils.mjs';
import { runDir } from './lib/manifest.mjs';
import { mergeFormalOutput } from './lib/merge-boundary.mjs';

export async function runMergeAppendOnly({ runId, workspaceRoot = process.cwd() }) {
  const profile = await readJson(path.join(runDir(workspaceRoot, runId), 'repo-profile.v1.json'));
  await mergeFormalOutput({ workspaceRoot, runId, target: profile.extraction_target });
  return { merged: true, run_id: runId };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = parseArgs();
  const result = await runMergeAppendOnly({ runId: requireArg(args, 'run-id'), workspaceRoot: args['workspace-root'] ?? process.cwd() });
  console.log(JSON.stringify(result, null, 2));
}
