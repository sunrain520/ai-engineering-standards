#!/usr/bin/env node
import path from 'node:path';
import { parseArgs, requireArg } from './lib/args.mjs';
import { readJson, writeJson } from './lib/fs-utils.mjs';
import { normalizeProjectInput } from './lib/input-normalizer.mjs';
import { assertSingleDomain, routeForTarget } from './lib/domain-router.mjs';
import { buildRunId, buildSnapshotId, computeDirectoryContentHash, computeInputFingerprint, formatRunTimestamp, isoLocal, pathHash } from './lib/fingerprint.mjs';
import { runDir, writeManifest } from './lib/manifest.mjs';
import { extractGitMetadata } from '../collectors/common/extract-git-metadata.mjs';
import { scanFiles } from '../collectors/common/scan-files.mjs';
import { assertValid } from './lib/contracts.mjs';

export async function runProfile({ inputPath, workspaceRoot = process.cwd(), fixedTimestamp } = {}) {
  const raw = await readJson(inputPath);
  const input = await normalizeProjectInput(raw, workspaceRoot);
  await assertSingleDomain(input.project_paths, input.extraction_target);

  const timestamp = fixedTimestamp ?? process.env.PSE_FIXED_TIMESTAMP ?? formatRunTimestamp();
  const inputFingerprint = computeInputFingerprint(input);
  const runId = buildRunId({
    timestamp,
    domain: input.extraction_target.domain,
    subDomain: input.extraction_target.sub_domain,
    inputFingerprint
  });
  const snapshotId = buildSnapshotId({ timestamp, inputFingerprint });
  const route = routeForTarget(input.extraction_target);

  const sourceProjects = [];
  const detectedStacks = new Set();
  const blindSpots = [];

  for (let index = 0; index < input.project_paths.length; index += 1) {
    const projectPath = input.project_paths[index];
    const git = await extractGitMetadata(projectPath);
    const content = await computeDirectoryContentHash(projectPath, input.scope);
    const javaFiles = await scanFiles(projectPath, ['**/*.java'], input.scope);
    const poms = await scanFiles(projectPath, ['**/pom.xml'], input.scope);
    if (javaFiles.length > 0) detectedStacks.add('java');
    if (poms.length > 0) detectedStacks.add('maven');
    if (javaFiles.length > 0 && poms.length > 0) detectedStacks.add('spring-candidate');

    sourceProjects.push({
      project_id: `source-${index + 1}`,
      path_hash: pathHash(projectPath),
      source_type: git.available ? 'git' : 'filesystem',
      is_git_repo: git.available,
      git_commit: git.commit,
      snapshot_id: snapshotId,
      file_count: content.fileCount
    });
  }

  const batchPlan = [
    {
      batch_id: 'backend-java-layering',
      domain: input.extraction_target.domain,
      sub_domain: input.extraction_target.sub_domain,
      paths: ['src/main/java', 'src/main/resources'],
      purpose: 'extract backend Java layering, API, transaction, exception and infrastructure conventions',
      risk_level: 'medium',
      status: 'ready'
    }
  ];

  const manifest = {
    run_id: runId,
    tool: 'project-standard-extractor',
    domain: input.extraction_target.domain,
    sub_domain: input.extraction_target.sub_domain,
    created_at: isoLocal(),
    input_fingerprint: inputFingerprint,
    source_projects: sourceProjects,
    output_base_dir: route.outputDir,
    status: 'running'
  };
  await writeManifest(workspaceRoot, manifest);

  const profile = {
    schema: 'repo-profile.v1',
    run_id: runId,
    extraction_target: input.extraction_target,
    source_projects: sourceProjects,
    detected_stacks: [...detectedStacks],
    domain_match: 'confirmed',
    domain_mismatch_warnings: [],
    module_candidates: [],
    batch_plan: batchPlan,
    blind_spots: blindSpots
  };
  await assertValid('repo-profile.v1', profile, 'repo-profile');

  const batchArtifact = {
    schema: 'batch-plan.v1',
    run_id: runId,
    batches: batchPlan
  };
  await assertValid('batch-plan.v1', batchArtifact, 'batch-plan');

  const dir = runDir(workspaceRoot, runId);
  await writeJson(path.join(dir, 'project-input.v1.json'), {
    ...input,
    project_paths: raw.project_paths
  });
  await writeJson(path.join(dir, 'repo-profile.v1.json'), profile);
  await writeJson(path.join(dir, 'batch-plan.v1.json'), batchArtifact);
  return { run_id: runId, manifest, profile };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = parseArgs();
  const result = await runProfile({ inputPath: requireArg(args, 'input'), workspaceRoot: args['workspace-root'] ?? process.cwd() });
  console.log(JSON.stringify(result, null, 2));
}
