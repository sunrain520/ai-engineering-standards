import { promises as fs } from 'node:fs';
import path from 'node:path';
import { assertOutputWithinDomain, routeForTarget } from './domain-router.mjs';
import { ensureDir, pathExists, readJson, writeJson } from './fs-utils.mjs';

export async function mergeFormalOutput({ workspaceRoot, runId, target }) {
  const route = routeForTarget(target);
  const sourceRoot = path.join(workspaceRoot, '.runs', runId, 'formal-output', route.outputDir);
  const destinationRoot = path.join(workspaceRoot, route.outputDir);
  await copyTree({ sourceRoot, destinationRoot, route, target });
}

async function copyTree({ sourceRoot, destinationRoot, route, target, relative = '' }) {
  const entries = await fs.readdir(path.join(sourceRoot, relative), { withFileTypes: true });
  for (const entry of entries) {
    const rel = path.join(relative, entry.name);
    const outputRel = `${route.outputDir}/${rel.split(path.sep).join('/')}`;
    assertOutputWithinDomain(outputRel, target);
    const source = path.join(sourceRoot, rel);
    const destination = path.join(destinationRoot, rel);
    if (entry.isDirectory()) {
      await ensureDir(destination);
      await copyTree({ sourceRoot, destinationRoot, route, target, relative: rel });
      continue;
    }
    await ensureDir(path.dirname(destination));
    if (entry.name.endsWith('.json') && await pathExists(destination)) {
      await writeJson(destination, mergeJson(await readJson(destination), await readJson(source)));
    } else if (entry.name.endsWith('.md') && await pathExists(destination)) {
      const existing = await fs.readFile(destination, 'utf8');
      const next = await fs.readFile(source, 'utf8');
      if (!existing.includes(next.trim())) {
        await fs.writeFile(destination, `${existing.trim()}\n\n---\n\n${next}`, 'utf8');
      }
    } else {
      await fs.copyFile(source, destination);
    }
  }
}

function mergeJson(existing, next) {
  if (Array.isArray(existing) && Array.isArray(next)) {
    return [...existing, ...next];
  }
  if (existing?.rules && next?.rules) {
    return { ...next, rules: mergeByKey(existing.rules, next.rules, 'rule_id') };
  }
  if (existing?.entries && next?.entries) {
    return { ...next, entries: mergeByKey(existing.entries, next.entries, 'rule_id') };
  }
  if (existing?.items && next?.items) {
    return { ...next, items: mergeByKey(existing.items, next.items, 'rule_id') };
  }
  return next;
}

function mergeByKey(existing, next, key) {
  const map = new Map();
  for (const item of existing) map.set(item[key], item);
  for (const item of next) map.set(item[key], item);
  return [...map.values()];
}
