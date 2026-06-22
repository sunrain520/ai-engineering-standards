import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

export async function extractGitMetadata(projectPath) {
  try {
    const inside = await execFileAsync('git', ['-C', projectPath, 'rev-parse', '--is-inside-work-tree']);
    if (inside.stdout.trim() !== 'true') {
      return { available: false, commit: null };
    }
    const commit = await execFileAsync('git', ['-C', projectPath, 'rev-parse', 'HEAD']);
    return { available: true, commit: commit.stdout.trim() };
  } catch {
    return { available: false, commit: null };
  }
}
