import { promises as fs } from 'node:fs';
import path from 'node:path';
import { pathHash, snippetHash } from '../../scripts/lib/fingerprint.mjs';
import { toPosixPath } from '../../scripts/lib/fs-utils.mjs';

export async function buildEvidenceAnchor({ projectPath, relativeFile, lineNumber, sourceProject }) {
  const fullPath = path.join(projectPath, relativeFile);
  const lines = (await fs.readFile(fullPath, 'utf8')).split(/\r?\n/);
  const snippet = lines[lineNumber - 1] ?? '';
  return {
    source_type: sourceProject.source_type,
    snapshot_id: sourceProject.snapshot_id,
    path_hash: sourceProject.path_hash ?? pathHash(projectPath),
    file: toPosixPath(relativeFile),
    line_range: { start: lineNumber, end: lineNumber },
    snippet_hash: snippetHash(snippet)
  };
}
