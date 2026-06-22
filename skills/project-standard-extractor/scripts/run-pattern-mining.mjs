#!/usr/bin/env node
import path from 'node:path';
import { parseArgs, requireArg } from './lib/args.mjs';
import { readJson, writeJson } from './lib/fs-utils.mjs';
import { runDir } from './lib/manifest.mjs';
import { assertValid } from './lib/contracts.mjs';
import { mineLayeringPatterns } from '../miners/mine-layering-patterns.mjs';
import { mineApiPatterns } from '../miners/mine-api-patterns.mjs';
import { mineErrorHandlingPatterns } from '../miners/mine-error-handling-patterns.mjs';
import { mineForbiddenPatterns } from '../miners/mine-forbidden-patterns.mjs';

export async function runPatternMining({ runId, workspaceRoot = process.cwd() }) {
  const dir = runDir(workspaceRoot, runId);
  const codeFacts = await readJson(path.join(dir, 'code-facts.v1.json'));
  const patterns = [
    ...mineLayeringPatterns(codeFacts.facts),
    ...mineApiPatterns(codeFacts.facts),
    ...mineErrorHandlingPatterns(codeFacts.facts),
    ...mineForbiddenPatterns(codeFacts.facts)
  ];

  const patternArtifact = {
    schema: 'pattern-candidates.v1',
    run_id: runId,
    patterns
  };
  await assertValid('pattern-candidates.v1', patternArtifact, 'pattern-candidates');

  const rules = patterns
    .filter((pattern) => pattern.positive_fact_ids.length > 0 || pattern.negative_fact_ids.length > 0)
    .map((pattern, index) => synthesizeRule(pattern, codeFacts, index + 1));

  const standardArtifact = {
    schema: 'standard-rule.v1',
    run_id: runId,
    rules
  };
  await assertValid('standard-rule.v1', standardArtifact, 'standard-rule');

  await writeJson(path.join(dir, 'pattern-candidates.v1.json'), patternArtifact);
  await writeJson(path.join(dir, 'standard-rule.v1.json'), standardArtifact);
  return { patternArtifact, standardArtifact };
}

function synthesizeRule(pattern, codeFacts, ordinal) {
  const target = codeFacts.extraction_target;
  const base = {
    rule_id: `backend-java-${pattern.category}-${String(ordinal).padStart(3, '0')}`,
    domain: target.domain,
    sub_domain: target.sub_domain,
    level: pattern.suggested_rule_level ?? 'P1',
    status: pattern.suggested_state === 'auto-active' ? 'candidate' : pattern.suggested_state,
    positive_evidence: pattern.positive_fact_ids,
    negative_evidence: pattern.negative_fact_ids,
    authority_scope: 'this-repo',
    owner_required: pattern.risk_level === 'high' || pattern.negative_fact_ids.length > 0,
    source_patterns: [pattern.pattern_id],
    source_projects: codeFacts.source_projects.map((project) => project.path_hash),
    risk_level: pattern.risk_level
  };

  if (pattern.category === 'layering' || pattern.category === 'forbidden') {
    return {
      ...base,
      title: 'Controller 不得直接访问 Mapper / Repository',
      rule_text: 'Controller 层只负责协议适配、参数接收和响应封装，业务编排与数据访问必须下沉到 Service 或更低层。',
      must: ['Controller must delegate business orchestration to Service or ApplicationService.'],
      must_not: ['Controller must not call Mapper or Repository directly.'],
      ai_coding_rule: 'When adding a Java Spring API, keep data access below the service layer and do not call Mapper or Repository from Controller.',
      review_checklist: ['Controller 是否直接访问 Mapper / Repository？', '业务编排是否下沉到 Service 或 ApplicationService？']
    };
  }

  if (pattern.category === 'api') {
    return {
      ...base,
      title: 'Spring API 必须通过明确映射注解暴露',
      rule_text: '新增 Java Spring HTTP API 时，Controller 必须使用明确的 Spring MVC 映射注解描述入口。',
      must: ['Controller endpoints must use Spring MVC mapping annotations.'],
      must_not: ['Do not expose HTTP behavior without a controller mapping annotation.'],
      ai_coding_rule: 'When adding a Java Spring endpoint, define it in a Controller with explicit Spring MVC mapping annotations.',
      review_checklist: ['新增接口是否具备明确的 Controller 与 Spring MVC 映射注解？']
    };
  }

  return {
    ...base,
    title: '异常处理应进入统一处理组件',
    rule_text: 'Java Spring 服务应通过 ControllerAdvice 或 ExceptionHandler 集中处理接口异常。',
    must: ['API exceptions should be handled by centralized Spring exception handling components.'],
    must_not: ['Do not scatter unrelated generic exception handling across controllers.'],
    ai_coding_rule: 'When adding API exception handling, prefer centralized ControllerAdvice or ExceptionHandler patterns already present in the service.',
    review_checklist: ['接口异常是否进入统一异常处理组件？']
  };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = parseArgs();
  const result = await runPatternMining({ runId: requireArg(args, 'run-id'), workspaceRoot: args['workspace-root'] ?? process.cwd() });
  console.log(JSON.stringify({ patterns: result.patternArtifact.patterns.length, rules: result.standardArtifact.rules.length }, null, 2));
}
