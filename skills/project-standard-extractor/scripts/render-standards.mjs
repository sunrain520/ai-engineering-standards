#!/usr/bin/env node
import path from 'node:path';
import { parseArgs, requireArg } from './lib/args.mjs';
import { readJson } from './lib/fs-utils.mjs';
import { runDir } from './lib/manifest.mjs';
import { renderFormalOutputs } from './lib/rendering.mjs';
import { assertValid } from './lib/contracts.mjs';

export async function runRenderStandards({ runId, workspaceRoot = process.cwd() }) {
  const dir = runDir(workspaceRoot, runId);
  const profile = await readJson(path.join(dir, 'repo-profile.v1.json'));
  const codeFacts = await readJson(path.join(dir, 'code-facts.v1.json'));
  const standardRules = await readJson(path.join(dir, 'standard-rule.v1.json'));
  const ruleDecisions = await readJson(path.join(dir, 'rule-decision.v1.json'));
  const result = await renderFormalOutputs({ workspaceRoot, runId, profile, codeFacts, standardRules, ruleDecisions });

  const lineage = await readJson(path.join(result.outputRoot, 'lineage-ledger.json'));
  const ownerQueue = await readJson(path.join(result.outputRoot, 'owner-decision-queue.json'));
  await assertValid('lineage-ledger.v1', lineage, 'lineage-ledger');
  await assertValid('owner-decision-queue.v1', ownerQueue, 'owner-decision-queue');
  return result;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = parseArgs();
  const result = await runRenderStandards({ runId: requireArg(args, 'run-id'), workspaceRoot: args['workspace-root'] ?? process.cwd() });
  console.log(JSON.stringify(result, null, 2));
}
