import fg from 'fast-glob';
import { defaultIgnore } from '../../scripts/lib/fingerprint.mjs';

export async function scanFiles(projectPath, patterns, scope = {}) {
  return fg(patterns, {
    cwd: projectPath,
    onlyFiles: true,
    dot: false,
    ignore: scope.exclude?.length ? scope.exclude : defaultIgnore(),
    absolute: false
  });
}
