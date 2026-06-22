---
name: project-standard-extractor
description: 从真实项目代码路径中萃取 evidence-backed 团队研发规范、AI Coding Rules、Review Checklist 和 Owner 待裁定队列。每次运行只绑定一个 extraction_target，不修改业务代码。
---

# Project Standard Extractor

## Purpose

从真实代码中抽取确定性事实，经过模式挖掘、规则归纳、质量门禁和自治决策策略，发布可追溯的端内研发规范。

## When To Use

- 用户提供 `extraction_target{domain, sub_domain}` 与 `project_paths`
- 需要生成 `standard-*`、`ai-rules-*`、`review-checklist-*`、evidence、lineage 或 Owner queue
- 需要验证某一端的规范是否可以从源码证据中派生

## When Not To Use

- 不用于解释单个代码文件
- 不用于写无 evidence 的通用最佳实践
- 不用于修改业务项目源码
- 不用于自动激活交易、资金、权限、安全、合规等高风险规则；这些规则只能进入 Owner gate
- 不用于一次性混合抽取多个端

## Default Workflow

1. `workflows/full-auto.md`
2. `agents/01-intake-and-scope.md`
3. `agents/02-repo-profiler.md`
4. `agents/03-fact-collector.md`
5. `agents/04-pattern-miner.md`
6. `agents/05-rule-synthesizer.md`
7. `agents/06-quality-gate.md`
8. `agents/07-publisher.md`

## Package Evidence

- `manifest.json` declares owner, maturity, lifecycle, input_files, output contract and rollback boundary.
- `agents/interface.yaml` is the reusable execution interface for callers and reviewers.
- `evals/trigger-cases.json` and `evals/output-cases.json` define route and output quality checks.
- `reports/trust_report.md` and `reports/output_quality_scorecard.md` record reviewer-visible evidence and missing evidence.

## Hard Rules

- 每次运行必须绑定唯一 `extraction_target{domain, sub_domain}`。
- Phase 0 只支持 `backend/java-spring`；其他 domain 目录是占位，不代表可抽取。
- LLM 只能基于 `code-facts.v1` 和 `pattern-candidates.v1` 归纳规则候选，不得伪造 evidence。
- `rule-decision.v1` 必须输出多维 `confidence`、`autonomy` 和 `decision_trace`，让自动发布或 Owner gate 都可审计。
- 低/中风险且所有门禁通过的规则默认自治发布；只有 conflict、high risk 或显式 `owner_required` 进入 Owner review。
- `ai-rules-*.md` 与 `review-checklist-*.md` 只能从已接受 standard 规则派生。
- 非 Git 项目可以抽取，但必须使用 `snapshot_id + path_hash + file + line_range + snippet_hash` 锚定。
- merge 只能写入当前 domain 允许的 `engineering-standards/{domain}/` 目录。
