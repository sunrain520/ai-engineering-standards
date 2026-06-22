import path from 'node:path';
import fg from 'fast-glob';

export const domainRoutes = {
  backend: {
    directory: '04-backend',
    subDomains: {
      'java-spring': {
        outputDir: 'engineering-standards/04-backend',
        collectors: [
          'collect-java-layer-facts',
          'collect-spring-api-facts',
          'collect-transaction-facts',
          'collect-exception-log-facts',
          'collect-cache-facts',
          'collect-mq-job-facts'
        ],
        miners: [
          'mine-layering-patterns',
          'mine-api-patterns',
          'mine-error-handling-patterns',
          'mine-log-patterns'
        ]
      }
    }
  }
};

export function routeForTarget(target) {
  const domain = domainRoutes[target.domain];
  const route = domain?.subDomains?.[target.sub_domain];
  if (!route) {
    throw new Error(`Unsupported extraction_target: ${target.domain}/${target.sub_domain}`);
  }
  return {
    domainDir: domain.directory,
    ...route
  };
}

export async function detectProjectDomain(projectPath) {
  const counts = {
    backend: (await fg(['**/*.java', '**/pom.xml'], { cwd: projectPath, onlyFiles: true, ignore: ['**/target/**', '**/build/**'] })).length,
    frontend: (await fg(['**/package.json', '**/*.vue', '**/*.tsx', '**/*.jsx'], { cwd: projectPath, onlyFiles: true, ignore: ['**/node_modules/**', '**/dist/**'] })).length,
    'app-client': (await fg(['**/*.kt', '**/*.swift'], { cwd: projectPath, onlyFiles: true, ignore: ['**/build/**', '**/.gradle/**'] })).length
  };
  const detected = Object.entries(counts).filter(([, count]) => count > 0).map(([domain]) => domain);
  return detected;
}

export async function assertSingleDomain(projectPaths, target) {
  const found = new Set();
  for (const projectPath of projectPaths) {
    for (const domain of await detectProjectDomain(projectPath)) {
      found.add(domain);
    }
  }
  if (found.size > 1) {
    throw new Error(`Mixed-domain input detected (${[...found].join(', ')}). Split into one run per domain.`);
  }
  if (found.size === 1 && !found.has(target.domain)) {
    throw new Error(`Input appears to be ${[...found][0]}, not ${target.domain}.`);
  }
  return [...found];
}

export function assertOutputWithinDomain(outputPath, target) {
  const route = routeForTarget(target);
  const normalized = outputPath.split(path.sep).join('/');
  if (!normalized.startsWith(`${route.outputDir}/`) && normalized !== route.outputDir) {
    throw new Error(`Output path ${outputPath} is outside allowed domain directory ${route.outputDir}`);
  }
}
