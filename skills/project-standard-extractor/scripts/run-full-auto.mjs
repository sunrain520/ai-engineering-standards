#!/usr/bin/env node
import { parseArgs, requireArg } from './lib/args.mjs';
import { updateManifestStatus } from './lib/manifest.mjs';
import { runProfile } from './run-profile.mjs';
import { runFactCollection } from './run-fact-collection.mjs';
import { runPatternMining } from './run-pattern-mining.mjs';
import { runQualityGates } from './run-quality-gates.mjs';
import { runRenderStandards } from './render-standards.mjs';
import { runMergeAppendOnly } from './merge-append-only.mjs';
import { runValidateContracts } from './validate-contracts.mjs';

export async function runFullAuto({ inputPath, workspaceRoot = process.cwd(), fixedTimestamp } = {}) {
  const { run_id: runId } = await runProfile({ inputPath, workspaceRoot, fixedTimestamp });
  try {
    await runFactCollection({ runId, workspaceRoot });
    await runPatternMining({ runId, workspaceRoot });
    await runQualityGates({ runId, workspaceRoot });
    await runRenderStandards({ runId, workspaceRoot });
    await runValidateContracts({ runId, workspaceRoot });
    await runMergeAppendOnly({ runId, workspaceRoot });
    await updateManifestStatus(workspaceRoot, runId, 'completed');
    return { run_id: runId, status: 'completed' };
  } catch (error) {
    await updateManifestStatus(workspaceRoot, runId, 'failed', { error: error.message });
    throw error;
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = parseArgs();
  const result = await runFullAuto({ inputPath: requireArg(args, 'input'), workspaceRoot: args['workspace-root'] ?? process.cwd(), fixedTimestamp: args.timestamp });
  console.log(JSON.stringify(result, null, 2));
}
