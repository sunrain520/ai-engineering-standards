#!/usr/bin/env node
import path from 'node:path';
import { parseArgs, requireArg } from './lib/args.mjs';
import { readJson, writeJson } from './lib/fs-utils.mjs';
import { runDir } from './lib/manifest.mjs';
import { assertValid } from './lib/contracts.mjs';
import { collectJavaFacts } from '../collectors/backend/collect-java-layer-facts.mjs';

export async function runFactCollection({ runId, workspaceRoot = process.cwd() }) {
  const dir = runDir(workspaceRoot, runId);
  const profile = await readJson(path.join(dir, 'repo-profile.v1.json'));
  const projectInput = await readJson(path.join(dir, 'project-input.v1.json'));
  const facts = [];

  for (let index = 0; index < projectInput.project_paths.length; index += 1) {
    const projectPath = path.resolve(workspaceRoot, projectInput.project_paths[index]);
    const sourceProject = profile.source_projects[index];
    facts.push(...await collectJavaFacts({ projectPath, sourceProject, scope: projectInput.scope }));
  }

  const artifact = {
    schema: 'code-facts.v1',
    run_id: runId,
    extraction_target: profile.extraction_target,
    source_projects: profile.source_projects,
    facts
  };
  await assertValid('code-facts.v1', artifact, 'code-facts');
  await writeJson(path.join(dir, 'code-facts.v1.json'), artifact);
  return artifact;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = parseArgs();
  const artifact = await runFactCollection({ runId: requireArg(args, 'run-id'), workspaceRoot: args['workspace-root'] ?? process.cwd() });
  console.log(JSON.stringify({ facts: artifact.facts.length }, null, 2));
}
