import { createHash } from 'node:crypto';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import fg from 'fast-glob';
import { toPosixPath } from './fs-utils.mjs';

export function sha256(value) {
  return `sha256:${createHash('sha256').update(value).digest('hex')}`;
}

export function shortHash(value, length = 7) {
  return createHash('sha256').update(value).digest('hex').slice(0, length);
}

export function pathHash(value) {
  return sha256(path.resolve(value));
}

export function formatRunTimestamp(date = new Date()) {
  const pad = (number) => String(number).padStart(2, '0');
  return [
    date.getFullYear(),
    pad(date.getMonth() + 1),
    pad(date.getDate())
  ].join('') + '-' + [
    pad(date.getHours()),
    pad(date.getMinutes()),
    pad(date.getSeconds())
  ].join('');
}

export function isoLocal(date = new Date()) {
  return date.toISOString();
}

export function buildRunId({ timestamp, domain, subDomain, inputFingerprint }) {
  return `${timestamp}-${domain}-${subDomain}-${shortHash(inputFingerprint)}`;
}

export function buildSnapshotId({ timestamp, inputFingerprint }) {
  return `snapshot-${timestamp}-${shortHash(inputFingerprint)}`;
}

export function computeInputFingerprint(input) {
  const normalized = {
    extraction_target: input.extraction_target,
    project_paths: input.project_paths.map((projectPath) => pathHash(projectPath)).sort(),
    scope: input.scope,
    output: input.output
  };
  return sha256(JSON.stringify(normalized));
}

export async function computeDirectoryContentHash(projectPath, scope = {}) {
  const include = scope.include?.length ? scope.include : ['**/*'];
  const ignore = scope.exclude?.length ? scope.exclude : defaultIgnore();
  const files = await fg(include, {
    cwd: projectPath,
    onlyFiles: true,
    dot: false,
    ignore,
    absolute: false
  });
  const hash = createHash('sha256');
  for (const file of files.sort()) {
    const fullPath = path.join(projectPath, file);
    hash.update(toPosixPath(file));
    hash.update(await fs.readFile(fullPath));
  }
  return {
    hash: `sha256:${hash.digest('hex')}`,
    fileCount: files.length
  };
}

export function snippetHash(snippet) {
  return sha256(snippet.trim());
}

export function defaultIgnore() {
  return [
    '**/.git/**',
    '**/target/**',
    '**/build/**',
    '**/generated/**',
    '**/node_modules/**',
    '**/.gradle/**',
    '**/dist/**'
  ];
}
