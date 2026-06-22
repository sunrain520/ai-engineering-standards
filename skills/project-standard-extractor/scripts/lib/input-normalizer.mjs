import path from 'node:path';
import { assertValid } from './contracts.mjs';
import { defaultIgnore } from './fingerprint.mjs';
import { routeForTarget } from './domain-router.mjs';

export async function normalizeProjectInput(input, workspaceRoot = process.cwd()) {
  const withDefaults = {
    ...input,
    scope: {
      include: input.scope?.include?.length ? input.scope.include : ['**/*'],
      exclude: input.scope?.exclude?.length ? input.scope.exclude : defaultIgnore()
    },
    output: {
      base_dir: input.output?.base_dir ?? routeForTarget(input.extraction_target).outputDir,
      mode: input.output?.mode ?? 'append-only'
    }
  };
  await assertValid('project-input.v1', withDefaults, 'project input');
  return {
    ...withDefaults,
    project_paths: withDefaults.project_paths.map((projectPath) => path.resolve(workspaceRoot, projectPath))
  };
}
