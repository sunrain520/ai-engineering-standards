import { promises as fs } from 'node:fs';
import path from 'node:path';
import { scanFiles } from '../common/scan-files.mjs';
import { buildEvidenceAnchor } from '../common/evidence-anchor.mjs';

const annotationKinds = [
  { regex: /@RestController\b|@Controller\b/, kind: 'spring-api', role: 'controller', observation: 'Spring controller exposes HTTP endpoints' },
  { regex: /@RequestMapping\b|@GetMapping\b|@PostMapping\b|@PutMapping\b|@DeleteMapping\b/, kind: 'spring-api', role: 'request-mapping', observation: 'Spring mapping annotation defines API route' },
  { regex: /@Service\b/, kind: 'layering', role: 'service', observation: 'Service layer component is declared' },
  { regex: /@Repository\b/, kind: 'layering', role: 'repository', observation: 'Repository layer component is declared' },
  { regex: /@Mapper\b/, kind: 'layering', role: 'mapper', observation: 'Mapper layer component is declared' },
  { regex: /@Transactional\b/, kind: 'transaction', role: 'transaction-boundary', observation: 'Transactional boundary is declared' },
  { regex: /@RestControllerAdvice\b|@ControllerAdvice\b|@ExceptionHandler\b/, kind: 'exception', role: 'exception-handler', observation: 'Exception handling component is declared' },
  { regex: /@Cacheable\b|@CacheEvict\b|@CachePut\b/, kind: 'cache', role: 'cache', observation: 'Cache annotation is declared' },
  { regex: /@Scheduled\b|@KafkaListener\b|@RabbitListener\b|@RocketMQMessageListener\b/, kind: 'mq-job', role: 'async-job', observation: 'Async job or message listener is declared' }
];

export async function collectJavaFacts({ projectPath, sourceProject, scope }) {
  const files = await scanFiles(projectPath, ['**/*.java'], scope);
  const facts = [];
  let counter = 1;

  for (const relativeFile of files.sort()) {
    const fullPath = path.join(projectPath, relativeFile);
    const content = await fs.readFile(fullPath, 'utf8');
    const lines = content.split(/\r?\n/);
    const isTest = /(^|\/)src\/test\//.test(relativeFile) || /Test\.java$/.test(relativeFile);
    const isControllerFile = /Controller\.java$/.test(relativeFile) || /@RestController\b|@Controller\b/.test(content);

    for (let index = 0; index < lines.length; index += 1) {
      const line = lines[index];
      for (const matcher of annotationKinds) {
        if (matcher.regex.test(line)) {
          facts.push(await buildFact({
            projectPath,
            sourceProject,
            relativeFile,
            lineNumber: index + 1,
            counter: counter++,
            kind: matcher.kind,
            role: matcher.role,
            observation: matcher.observation,
            scope: isTest ? 'test' : 'main'
          }));
        }
      }

      if (isControllerFile && /(Mapper|Repository)\b/.test(line) && !/import\s+.*(Mapper|Repository)/.test(line)) {
        facts.push(await buildFact({
          projectPath,
          sourceProject,
          relativeFile,
          lineNumber: index + 1,
          counter: counter++,
          kind: 'layering-violation',
          role: 'controller-direct-data-access',
          observation: 'Controller directly references Mapper or Repository',
          scope: isTest ? 'test' : 'main'
        }));
      }
    }
  }

  return facts;
}

async function buildFact({ projectPath, sourceProject, relativeFile, lineNumber, counter, kind, role, observation, scope }) {
  return {
    fact_id: `FACT-BE-JAVA-${String(counter).padStart(4, '0')}`,
    kind,
    role,
    observation,
    source_anchor: await buildEvidenceAnchor({ projectPath, relativeFile, lineNumber, sourceProject }),
    git: {
      available: sourceProject.is_git_repo,
      commit: sourceProject.git_commit
    },
    scope,
    positive_examples: kind === 'layering-violation' ? [] : [{ file: relativeFile }],
    negative_examples: kind === 'layering-violation' ? [{ file: relativeFile }] : [],
    deterministic_occurrence_count: 1,
    module: inferModule(relativeFile),
    confidence: 'high'
  };
}

function inferModule(relativeFile) {
  const parts = relativeFile.split('/');
  const javaIndex = parts.indexOf('java');
  if (javaIndex >= 0 && parts[javaIndex + 1]) {
    return parts[javaIndex + 1];
  }
  return parts[0] ?? 'root';
}
