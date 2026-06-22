
## 代码证据驱动的各端团队开发规范萃取 Skill

版本：V2 设计稿
目标项目：`ai-engineering-standards / feat/project-standard-extractor`
核心目标：**通过真实代码，萃取 APP、PC、前端、后端、测试、发布、安全、行业等研发域的团队开发规范，并输出 AI 可执行规则与 Review 检查项。**

---

## 1. 背景与问题定义

当前 `ai-engineering-standards` 已经明确定位为部门级研发工程规范仓库，用于沉淀各端开发规范、架构约束、AI 辅助编码规则、Code Review Checklist 和工程最佳实践；当前第一阶段聚焦 `project-standard-extractor`，链路是“真实项目代码 → 代码事实 → 团队级规范 → AI Coding Rules → Review Checklist → evidence / pending / merge / conflict”。([GitHub][1])

当前 Skill 的对外定位也已经清楚：它用于从一个或多个真实项目代码路径中萃取团队级研发规范，输出规范文档、AI Coding Rules、Review Checklist 和 evidence，不用于自动修改业务代码。([GitHub][2])

本次重新设计不是推翻当前方向，而是把它从：

```text
“AI 阅读代码后生成规范”
```

升级为：

```text
“确定性代码事实 + LLM 归纳 + 质量门禁 + Owner 裁定 + 规范发布”
```

核心原则：

> **LLM 不能直接立法。LLM 只能基于代码事实归纳规范候选。**

---

# 2. 设计目标

## 2.1 一句话目标

从真实项目代码中，自动提取团队长期实践形成的开发规范，并沉淀为：

```text
人能读的 standard 文档
AI 能执行的 ai-rules
Reviewer 能检查的 review-checklist
机器能索引的 rules-index
Owner 能裁定的 pending / conflict / decision queue
```

## 2.2 具体目标

### G1：从代码事实出发

不是写“通用最佳实践”，而是从真实代码中提取：

```text
目录结构
分层架构
模块边界
API 组织方式
状态管理方式
异常处理方式
日志规范
缓存规范
配置规范
测试组织方式
安全红线
行业约束
```

### G2：支持多端团队

覆盖：

```text
01-app-client    APP 客户端：KMP / Android / iOS
02-pc-client     PC 客户端：Windows / macOS
03-frontend      H5 / Admin / Web 前端
04-backend       Java / Python 后端
05-testing       测试规范
06-release       发布规范
07-security      安全规范
09-industry      证券 / 银行 / 信贷等行业规范
```

### G3：每条规则必须可追溯

每条规范必须能回答：

```text
这条规则来自哪些项目？
来自哪些文件？
有哪些正例？
有没有反例？
出现了几次？
适用范围是什么？
是否已经负责人确认？
是否可以进入 AI 默认执行路径？
```

### G4：AI 可执行

输出不能只是文档，而要变成 AI Coding 可以使用的契约：

```text
Must
Must Not
When modifying X, do Y
Never do Z
Check before commit
Review checklist
```

### G5：支持部门级演进

支持从单项目规则升级到团队规则、部门规则：

```text
this-repo candidate
team-candidate
owner-confirmed-active
department-active
```

---

# 3. 非目标

第一阶段不做：

```text
1. 不做 Web 平台
2. 不做完整 CLI 产品
3. 不做自动 CI 全量扫描
4. 不做向量索引
5. 不直接修改业务代码
6. 不直接从 CodeWiki / README / LLM 总结生成 active 规则
7. 不自动激活交易、资金、权限、安全、合规类高风险规则
```

当前 README 也明确第一阶段不建设 Web 平台、完整 CLI、自动 CI 或向量索引，普通入口默认 full-auto，内部先 profile-first，再按 ordered batch queue 逐 batch 生成 evidence-backed 产物。([GitHub][1])

---

# 4. 总体架构

## 4.1 核心架构图

```text
                         ┌────────────────────────────┐
                         │        project_paths        │
                         │  一个或多个真实项目代码路径  │
                         └─────────────┬──────────────┘
                                       │
                                       ▼
                         ┌────────────────────────────┐
                         │      1. Skill Gateway       │
                         │ 输入校验 / 路由 / 输出边界   │
                         └─────────────┬──────────────┘
                                       │
                                       ▼
                         ┌────────────────────────────┐
                         │      2. Repo Profiler       │
                         │ 技术栈 / 端类型 / 模块 / batch│
                         └─────────────┬──────────────┘
                                       │
                ┌──────────────────────┼──────────────────────┐
                ▼                      ▼                      ▼
      ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
      │ CodeWiki Signals │   │ CodeGraph / AST   │   │ PR Review Mining │
      │ advisory context │   │ deterministic     │   │ team corrections │
      └────────┬─────────┘   └────────┬─────────┘   └────────┬─────────┘
               │                      │                      │
               └──────────────────────┼──────────────────────┘
                                      ▼
                         ┌────────────────────────────┐
                         │     3. Fact Collectors     │
                         │ 输出 code-facts.v1          │
                         └─────────────┬──────────────┘
                                       │
                                       ▼
                         ┌────────────────────────────┐
                         │      4. Pattern Miner       │
                         │ 重复模式 / 反模式 / 冲突     │
                         └─────────────┬──────────────┘
                                       │
                                       ▼
                         ┌────────────────────────────┐
                         │     5. Rule Synthesizer     │
                         │ 规范候选 / AI 规则 / Review │
                         └─────────────┬──────────────┘
                                       │
                                       ▼
                         ┌────────────────────────────┐
                         │       6. Quality Gate       │
                         │ evidence / risk / conflict │
                         └─────────────┬──────────────┘
                                       │
                                       ▼
                         ┌────────────────────────────┐
                         │        7. Publisher         │
                         │ standard / rules / checklist│
                         └─────────────┬──────────────┘
                                       │
          ┌────────────────────────────┼────────────────────────────┐
          ▼                            ▼                            ▼
┌──────────────────┐        ┌──────────────────┐        ┌──────────────────┐
│ standard-*.md    │        │ ai-rules.md      │        │ review-checklist │
│ 人读规范          │        │ AI 执行规则       │        │ Review 检查项     │
└──────────────────┘        └──────────────────┘        └──────────────────┘
          │                            │                            │
          └────────────────────────────┼────────────────────────────┘
                                       ▼
                         ┌────────────────────────────┐
                         │ rules-index / lineage /    │
                         │ pending / conflict / owner │
                         └────────────────────────────┘
```

---

# 5. 设计原则

## 5.1 代码事实优先

规范必须来自：

```text
源码 evidence
AST / 符号 / 调用关系 evidence
PR Review evidence
Lint / CI / 测试 evidence
Owner confirmation
```

不能只来自：

```text
CodeWiki 总结
README 总结
LLM 自己理解
行业通用最佳实践
```

## 5.2 Profile 不是规则

Repo Profile 只用于识别：

```text
项目是什么
技术栈是什么
模块在哪里
哪些 batch 先抽
哪些路径不可读
```

不能把 profile 直接升级成规则。

错误示例：

```text
发现项目有 controller/service/repository 目录
=> 直接生成“必须使用三层架构”
```

正确示例：

```text
发现项目有 controller/service/repository 目录
=> 进入 batch
=> 抽源码事实
=> 发现多个 Controller 都只调用 Service
=> 生成候选规则
=> 质量门禁判断是否 active
```

## 5.3 LLM 只做归纳，不做事实判定

LLM 可以做：

```text
把事实归纳成规则
把正反例整理成规范文档
把规则转成 AI Rules
把规则转成 Review Checklist
识别规则之间的语义重复
```

LLM 不可以做：

```text
伪造 evidence
判断源码是否真的调用了某个函数
凭印象提升 confidence
绕过 quality gate
直接把高风险规则设为 active
```

## 5.4 规则必须可执行

不接受空泛规则：

```text
代码要优雅
模块要清晰
异常要合理
注意安全
注意性能
```

接受可执行规则：

```text
Controller 不得直接调用 Repository / Mapper。
新增写接口必须在 ApplicationService 定义事务边界。
前端页面组件不得直接调用 axios / fetch，必须经过统一 API Client。
KMP shared 层承载跨端业务逻辑，平台层只做适配。
```

## 5.5 规则生命周期治理

规则不是一次性生成，而是逐步升级：

```text
candidate
draft
auto-active
team-candidate
owner-confirmed-active
department-active
legacy-compatible
owner-rejected
conflict
```

---

# 6. Skill 目录重构方案

建议重构为：

```text
skills/project-standard-extractor/
├── SKILL.md
├── README.md
│
├── workflows/
│   ├── full-auto.md
│   ├── profile-first.md
│   ├── batch-extraction.md
│   ├── diff-extraction.md
│   └── owner-review.md
│
├── agents/
│   ├── 01-intake-and-scope.md
│   ├── 02-repo-profiler.md
│   ├── 03-fact-collector.md
│   ├── 04-pattern-miner.md
│   ├── 05-rule-synthesizer.md
│   ├── 06-quality-gate.md
│   ├── 07-publisher.md
│   └── 08-owner-review.md
│
├── contracts/
│   ├── project-input.v1.schema.json
│   ├── repo-profile.v1.schema.json
│   ├── batch-plan.v1.schema.json
│   ├── code-facts.v1.schema.json
│   ├── pattern-candidates.v1.schema.json
│   ├── standard-rule.v1.schema.json
│   ├── rule-decision.v1.schema.json
│   ├── lineage-ledger.v1.schema.json
│   └── owner-decision-queue.v1.schema.json
│
├── collectors/
│   ├── common/
│   │   ├── scan-files.mjs
│   │   ├── detect-stack.mjs
│   │   ├── detect-domain.mjs
│   │   ├── detect-sensitive-files.mjs
│   │   └── extract-git-metadata.mjs
│   │
│   ├── app-client/
│   │   ├── collect-kmp-facts.mjs
│   │   ├── collect-android-facts.mjs
│   │   ├── collect-ios-reactorkit-facts.mjs
│   │   └── collect-mobile-data-layer-facts.mjs
│   │
│   ├── frontend/
│   │   ├── collect-route-facts.mjs
│   │   ├── collect-api-client-facts.mjs
│   │   ├── collect-state-facts.mjs
│   │   ├── collect-component-layer-facts.mjs
│   │   └── collect-permission-facts.mjs
│   │
│   ├── backend/
│   │   ├── collect-java-layer-facts.mjs
│   │   ├── collect-spring-api-facts.mjs
│   │   ├── collect-transaction-facts.mjs
│   │   ├── collect-exception-log-facts.mjs
│   │   ├── collect-cache-facts.mjs
│   │   ├── collect-mq-job-facts.mjs
│   │   └── collect-python-service-facts.mjs
│   │
│   └── pc-client/
│       ├── collect-windows-client-facts.mjs
│       ├── collect-macos-client-facts.mjs
│       └── collect-pc-platform-adapter-facts.mjs
│
├── miners/
│   ├── mine-layering-patterns.mjs
│   ├── mine-naming-patterns.mjs
│   ├── mine-api-patterns.mjs
│   ├── mine-error-handling-patterns.mjs
│   ├── mine-log-patterns.mjs
│   ├── mine-test-patterns.mjs
│   ├── mine-forbidden-patterns.mjs
│   ├── mine-legacy-compatible-patterns.mjs
│   └── mine-cross-repo-consistency.mjs
│
├── quality-gates/
│   ├── evidence-gate.md
│   ├── actionability-gate.md
│   ├── abstraction-gate.md
│   ├── conflict-gate.md
│   ├── risk-gate.md
│   └── derivation-gate.md
│
├── templates/
│   ├── standard-template.md
│   ├── ai-rules-template.md
│   ├── review-checklist-template.md
│   ├── evidence-template.md
│   ├── pending-confirmation-template.md
│   ├── conflicts-template.md
│   ├── merge-suggestions-template.md
│   └── rules-index-template.json
│
├── integrations/
│   ├── codewiki.md
│   ├── codegraph.md
│   ├── graphify.md
│   ├── pr-review-mining.md
│   └── opendeepwiki.md
│
├── evals/
│   ├── golden-samples/
│   ├── thin-dogfood/
│   ├── regression/
│   └── quality-cases/
│
└── scripts/
    ├── run-profile.mjs
    ├── run-fact-collection.mjs
    ├── run-pattern-mining.mjs
    ├── validate-contracts.mjs
    ├── render-standards.mjs
    ├── merge-append-only.mjs
    └── generate-review-summary.mjs
```

---

# 7. `SKILL.md` 重写建议

`SKILL.md` 应该变薄，成为唯一对外入口。

```md
---
name: project-standard-extractor
description: 从一个或多个真实项目代码路径中萃取团队级开发规范、AI Coding Rules、Review Checklist 和 evidence。适用于部门级 engineering-standards 仓库，不用于自动修改业务代码。
---

# Project Standard Extractor

## Purpose

Extract evidence-backed engineering standards from real codebases.

## When To Use

Use this skill when the user provides one or more `project_paths` and asks to extract:

- APP / PC / Frontend / Backend engineering standards
- AI Coding Rules
- Code Review Checklist
- positive / negative examples
- evidence-backed team conventions

## When Not To Use

Do not use this skill for:

- explaining a single code file
- writing generic best-practice documents without code evidence
- modifying business code
- producing active security / trading / fund / auth rules without owner confirmation

## Default Workflow

For broad extraction requests, run:

1. `workflows/full-auto.md`
2. `agents/01-intake-and-scope.md`
3. `agents/02-repo-profiler.md`
4. `agents/03-fact-collector.md`
5. `agents/04-pattern-miner.md`
6. `agents/05-rule-synthesizer.md`
7. `agents/06-quality-gate.md`
8. `agents/07-publisher.md`

## Hard Rules

- Never create active rules without source evidence.
- Never treat repo profile, CodeWiki, README, or LLM summary as deterministic evidence.
- Never overwrite existing `owner-confirmed-active`, `legacy-compatible`, or existing draft rules.
- Security, auth, payment, trading, fund, privacy, release, and compliance rules require owner confirmation.
- AI Rules and Review Checklist must be derived from accepted standards only.
```

---

# 8. Full-auto 工作流

## 8.1 输入

最小输入：

```yaml
project_paths:
  - /path/to/project-a
  - /path/to/project-b
```

增强输入：

```yaml
project_paths:
  - /path/to/project-a
  - /path/to/project-b

target_domains:
  - app-client
  - frontend
  - backend

industry_context:
  - securities
  - multi-region
  - trading

output_scope:
  standards: true
  ai_rules: true
  review_checklist: true
  evidence: true

context_sources:
  codewiki:
    enabled: true
    mode: advisory
  pr_review:
    enabled: true
    source: github
  codegraph:
    enabled: true
    mode: deterministic
```

## 8.2 流程

```text
Step 1. Intake and Scope
  - 校验项目路径
  - 判断是否 Git repo
  - 识别敏感文件
  - 生成 run_id
  - 记录输入边界

Step 2. Repo Profile
  - 扫描目录结构
  - 识别技术栈
  - 识别端类型
  - 识别模块候选
  - 生成 batch plan

Step 3. Fact Collection
  - 按 batch 调用 collector
  - 输出 code-facts.v1
  - 抽源码路径、符号、调用关系、正反例

Step 4. Pattern Mining
  - 发现重复模式
  - 发现反模式
  - 发现 legacy-compatible
  - 发现 conflict
  - 输出 pattern-candidates.v1

Step 5. Rule Synthesis
  - LLM 基于 pattern 生成规范候选
  - 绑定 evidence
  - 生成 standard-rule.v1

Step 6. Quality Gate
  - Evidence Gate
  - Actionability Gate
  - Abstraction Gate
  - Conflict Gate
  - Risk Gate
  - Derivation Gate

Step 7. Publish
  - 生成 standard-{sub_domain}.md
  - 生成 ai-rules.md
  - 生成 review-checklist.md
  - 更新 rules-index.json
  - 更新 lineage-ledger.json
  - 更新 owner-decision-queue.json

Step 8. Review Summary
  - 本次新增规则
  - pending 列表
  - conflict 列表
  - blind spots
  - 人工决策项
```

---

# 9. 核心数据合同设计

## 9.1 `project-input.v1`

```json
{
  "schema": "project-input.v1",
  "run_id": "run-20260603-001",
  "project_paths": [
    "/path/to/project-a"
  ],
  "target_domains": [
    "backend"
  ],
  "target_sub_domains": [
    "java"
  ],
  "industry_context": [
    "securities",
    "trading"
  ],
  "output_scope": {
    "standards": true,
    "ai_rules": true,
    "review_checklist": true,
    "evidence": true
  },
  "constraints": {
    "no_business_code_modification": true,
    "mask_sensitive_values": true,
    "no_active_high_risk_without_owner": true
  }
}
```

## 9.2 `repo-profile.v1`

```json
{
  "schema": "repo-profile.v1",
  "run_id": "run-20260603-001",
  "repo": {
    "name": "trade-service",
    "path_hash": "sha256:xxx",
    "git_commit": "abc123",
    "default_branch": "main"
  },
  "domain": "backend",
  "sub_domain": "java",
  "detected_stacks": [
    "spring-boot",
    "mybatis",
    "redis",
    "rocketmq"
  ],
  "module_candidates": [
    {
      "module_id": "order",
      "paths": [
        "src/main/java/com/company/trade/order"
      ],
      "confidence": "high"
    }
  ],
  "batch_plan": [
    {
      "batch_id": "backend-java-layering-order",
      "paths": [
        "src/main/java/com/company/trade/order"
      ],
      "purpose": "extract layering, API, exception and transaction conventions",
      "risk_level": "medium",
      "status": "ready"
    }
  ],
  "blind_spots": [
    {
      "path": "generated/",
      "reason": "generated code excluded"
    }
  ]
}
```

## 9.3 `code-facts.v1`

```json
{
  "schema": "code-facts.v1",
  "run_id": "run-20260603-001",
  "batch_id": "backend-java-layering-order",
  "facts": [
    {
      "fact_id": "FACT-BE-JAVA-001",
      "kind": "layering",
      "observation": "Controller delegates business orchestration to ApplicationService",
      "positive_examples": [
        {
          "file": "src/main/java/order/OrderController.java",
          "symbol": "OrderController#createOrder",
          "snippet_ref": "evidence/snippets/FACT-BE-JAVA-001-pos-1.md"
        },
        {
          "file": "src/main/java/order/CancelOrderController.java",
          "symbol": "CancelOrderController#cancel",
          "snippet_ref": "evidence/snippets/FACT-BE-JAVA-001-pos-2.md"
        }
      ],
      "negative_examples": [],
      "deterministic_occurrence_count": 2,
      "role_diversity": [
        "controller",
        "application-service"
      ],
      "module_diversity": 1,
      "confidence": "high"
    }
  ]
}
```

## 9.4 `pattern-candidates.v1`

```json
{
  "schema": "pattern-candidates.v1",
  "run_id": "run-20260603-001",
  "patterns": [
    {
      "pattern_id": "PAT-BE-JAVA-001",
      "title": "Controller delegates to ApplicationService",
      "category": "layering",
      "source_fact_ids": [
        "FACT-BE-JAVA-001",
        "FACT-BE-JAVA-002"
      ],
      "occurrence_count": 8,
      "module_diversity": 4,
      "role_diversity": [
        "controller",
        "application-service",
        "repository"
      ],
      "negative_examples": 1,
      "risk_level": "medium",
      "suggested_rule_level": "P1",
      "suggested_state": "draft",
      "reason": "positive pattern is common but one conflict exists"
    }
  ]
}
```

## 9.5 `standard-rule.v1`

```json
{
  "schema": "standard-rule.v1",
  "rule": {
    "rule_id": "backend-java-layering-001",
    "title": "P1 Controller 不得直接访问 Repository / Mapper",
    "domain": "backend",
    "sub_domain": "java",
    "level": "P1",
    "status": "draft",
    "rule_text": "Controller 层只负责协议适配、参数接收、鉴权上下文读取和响应封装，不得直接访问 Repository / Mapper。",
    "must": [
      "Controller must delegate business orchestration to ApplicationService or Service.",
      "Repository / Mapper access must be encapsulated below service layer."
    ],
    "must_not": [
      "Do not call Repository / Mapper directly from Controller."
    ],
    "positive_evidence": [
      "FACT-BE-JAVA-001"
    ],
    "negative_evidence": [
      "FACT-BE-JAVA-009"
    ],
    "ai_coding_rule": "When adding a new REST API, create or reuse an ApplicationService; do not call Repository / Mapper in Controller.",
    "review_checklist": [
      "Controller 是否直接访问 Repository / Mapper？",
      "业务编排是否下沉到 ApplicationService / Service？"
    ],
    "authority_scope": "this-repo",
    "owner_required": false
  }
}
```

## 9.6 `rule-decision.v1`

```json
{
  "schema": "rule-decision.v1",
  "rule_id": "backend-java-layering-001",
  "decision": "draft",
  "gate_results": {
    "evidence_gate": "pass",
    "actionability_gate": "pass",
    "abstraction_gate": "pass",
    "conflict_gate": "warning",
    "risk_gate": "pass",
    "derivation_gate": "pass"
  },
  "reason": "Evidence is sufficient for draft, but one negative example prevents auto-active.",
  "next_action": "owner-review"
}
```

## 9.7 `lineage-ledger.v1`

```json
{
  "schema": "lineage-ledger.v1",
  "entries": [
    {
      "rule_id": "backend-java-layering-001",
      "created_by_run": "run-20260603-001",
      "source_patterns": [
        "PAT-BE-JAVA-001"
      ],
      "source_facts": [
        "FACT-BE-JAVA-001",
        "FACT-BE-JAVA-002"
      ],
      "source_projects": [
        "trade-service",
        "account-service"
      ],
      "status_history": [
        {
          "status": "draft",
          "time": "2026-06-03T12:00:00+08:00",
          "reason": "Initial extraction"
        }
      ]
    }
  ]
}
```

## 9.8 `owner-decision-queue.v1`

```json
{
  "schema": "owner-decision-queue.v1",
  "items": [
    {
      "queue_id": "ODQ-001",
      "rule_id": "backend-java-layering-001",
      "decision_required": "confirm-or-reject",
      "reason": "Pattern has one negative example and may be a legacy exception.",
      "suggested_owner_role": "backend-architecture-owner",
      "options": [
        "owner-confirmed-active",
        "draft",
        "legacy-compatible",
        "owner-rejected"
      ]
    }
  ]
}
```

---

# 10. 各端事实抽取器设计

## 10.1 APP 客户端抽取器

目标技术栈：

```text
KMP
Android Jetpack MVVM
BaseVM / HSLoadData
LiveData / Flow
iOS ReactorKit
HSDataCenterKit
Ktor
SQLDelight
Napier
```

抽取维度：

```text
1. KMP shared 层职责
2. Android ViewModel 职责
3. iOS ReactorKit Action / Mutation / State 边界
4. Repository / DataSource / Cache 分层
5. 网络访问是否统一走数据中台
6. SQLDelight / 本地缓存访问边界
7. 日志是否统一封装
8. 多展业地配置是否硬编码
```

候选规则：

```text
P1 shared 层承载跨端业务逻辑，平台层只做适配。
P1 ViewModel / Reactor 不得直接访问底层网络实现。
P1 Repository 统一封装远端数据源、本地缓存和数据转换。
FORBIDDEN 页面层直接调用 Ktor / SQLDelight。
FORBIDDEN State 中混入一次性副作用。
```

输出 evidence：

```text
Kotlin shared layer files
Android ViewModel files
iOS Reactor files
Repository files
DataSource files
Cache files
```

---

## 10.2 前端 H5 / Admin 抽取器

抽取维度：

```text
1. 路由组织
2. 权限挂载位置
3. API Client 封装
4. Store / Hook / Composable 使用方式
5. 页面层与业务组件边界
6. 表格 / 表单封装方式
7. 错误处理方式
8. 多展业地配置方式
```

候选规则：

```text
P1 页面层只负责组合，不直接散落接口细节。
P1 API 调用必须经过统一 request client。
P1 权限判断应沉淀到 route meta / guard / permission hook。
P1 业务组件不得直接依赖具体页面路由。
FORBIDDEN 组件内硬编码展业地差异。
FORBIDDEN 页面内重复拼装后端 DTO。
```

抽取器：

```text
collect-route-facts.mjs
collect-api-client-facts.mjs
collect-state-facts.mjs
collect-component-layer-facts.mjs
collect-permission-facts.mjs
```

---

## 10.3 Java 后端抽取器

抽取维度：

```text
1. Controller / Service / Repository / Mapper 分层
2. DTO / VO / Command / Entity 转换
3. 事务边界
4. 异常处理
5. 日志与 traceId
6. 缓存 Key / TTL / 一致性
7. MQ Consumer 幂等
8. Job 重试 / 补偿
9. 配置读取方式
10. 安全与权限边界
```

候选规则：

```text
P0 Controller 不得直接访问 Mapper / Repository。
P0 交易类写操作必须由 ApplicationService 统一编排事务边界。
P1 业务异常必须转换为统一错误码。
P1 MQ Consumer 必须具备幂等保护。
P1 缓存 Key 必须统一命名并设置 TTL。
FORBIDDEN 捕获 Exception 后只打印日志不抛出或补偿。
FORBIDDEN 在事务内发起不可控远程调用。
```

抽取器：

```text
collect-java-layer-facts.mjs
collect-spring-api-facts.mjs
collect-transaction-facts.mjs
collect-exception-log-facts.mjs
collect-cache-facts.mjs
collect-mq-job-facts.mjs
```

---

## 10.4 Python 后端 / 工具服务抽取器

抽取维度：

```text
1. 包结构
2. API / Service / Repository 分层
3. Pydantic / dataclass / typing 使用
4. 配置管理
5. 异常与日志
6. 任务幂等
7. pytest / fixture / mock
8. CLI 参数解析
```

候选规则：

```text
P1 服务层不得直接读取环境变量，必须经过配置对象。
P1 对外 API 入参必须有 schema 校验。
P1 任务脚本必须具备幂等和重试边界。
P1 测试 fixture 必须放在统一目录或 conftest。
FORBIDDEN 业务代码硬编码本地路径、密钥、环境名。
```

---

## 10.5 PC 客户端抽取器

抽取维度：

```text
1. 平台适配层
2. UI 与业务逻辑分层
3. 本地配置和存储
4. 网络连接 / 重连 / 心跳
5. 日志与崩溃采集
6. 自动升级
7. 多展业地配置
```

候选规则：

```text
P1 平台 API 必须收敛在 adapter 层。
P1 UI 层不得直接访问本地存储细节。
P1 网络重连策略必须统一封装。
P1 崩溃日志必须包含版本、展业地、设备和关键上下文。
FORBIDDEN 在 UI 事件里直接写复杂业务流程。
```

---

# 11. Pattern Miner 设计

Pattern Miner 负责把代码事实转成候选模式。

## 11.1 输入

```text
repo-profile.v1
code-facts.v1
optional: codewiki-signals.v1
optional: pr-review-signals.v1
optional: codegraph-facts.v1
```

## 11.2 输出

```text
pattern-candidates.v1
```

## 11.3 评分维度

```text
occurrence_count
  出现次数

module_diversity
  是否跨多个模块

role_diversity
  是否覆盖 controller / service / repository 等不同角色

negative_examples
  是否存在反例

legacy_signals
  是否可能是历史兼容写法

risk_level
  是否涉及交易、资金、权限、安全、合规

owner_signal
  PR Review 或负责人文档是否出现过类似意见
```

## 11.4 状态建议

```text
occurrence_count >= 2
+ confidence high
+ no conflict
+ low/medium risk
=> auto-active candidate

有 evidence 但样本不足
=> draft

只有 CodeWiki / README / LLM 总结
=> pending-confirmation

存在正反冲突
=> conflict

高风险领域
=> pending-confirmation / owner-confirmed-required
```

---

# 12. Rule Synthesizer 设计

Rule Synthesizer 使用 LLM，但输入必须是结构化 facts 和 patterns。

## 12.1 输入

```text
pattern-candidates.v1
code-facts.v1
standard-template.md
domain-specific style guide
existing rules-index.json
```

## 12.2 输出

```text
standard-rule.v1
```

## 12.3 生成要求

每条规则必须包含：

```text
规则标题
级别：P0 / P1 / P2 / FORBIDDEN
状态建议
适用范围
规则说明
Must
Must Not
正例
反例
AI Coding 要求
Code Review 检查项
Evidence 引用
风险说明
Owner 是否 required
```

## 12.4 禁止行为

```text
不得生成无 evidence 规则
不得把 CodeWiki 结论当正例
不得把项目路径写进规则正文
不得把单个项目局部习惯升级为部门规范
不得自动激活高风险规则
```

---

# 13. Quality Gate 设计

## 13.1 Evidence Gate

通过条件：

```text
1. 至少 1 条源码 evidence
2. auto-active 至少 2 条 deterministic evidence
3. evidence 必须包含文件、符号、片段或结构事实
4. 不能只引用 CodeWiki / README / LLM 总结
```

阻断条件：

```text
no evidence
only advisory context
fake path
snippet missing
source file not in batch scope
```

---

## 13.2 Actionability Gate

通过条件：

```text
规则能被 AI 执行
规则能被 Reviewer 检查
规则有明确 Must / Must Not
```

阻断示例：

```text
代码要优雅
接口要合理
注意异常
模块要清晰
```

---

## 13.3 Abstraction Gate

规则不能太具体，也不能太空。

太具体：

```text
OrderController#createOrder 必须调用 OrderService#create
```

合适：

```text
Controller 层只做协议适配，不承载业务编排；业务编排下沉到 ApplicationService。
```

---

## 13.4 Conflict Gate

如果正反例并存：

```text
写入 conflicts.md
不得 auto-active
生成 owner-decision-queue
```

---

## 13.5 Risk Gate

以下领域必须 Owner 确认：

```text
交易
资金
清结算
权限
认证
隐私
安全
合规
发布
生产变更
风控
```

---

## 13.6 Derivation Gate

`ai-rules.md` 和 `review-checklist.md` 只能从 accepted standard rules 派生。

禁止：

```text
在 ai-rules.md 新增 standard.md 不存在的规则。
在 review-checklist.md 新增未通过 quality gate 的检查项。
```

---

# 14. 规则生命周期

## 14.1 状态定义

```text
candidate
  从 facts / patterns 发现，尚未生成正式规则。

draft
  有 evidence，但样本不足或仅适用于单仓。

auto-active
  多 evidence、高置信、低/中风险、无冲突，可进入 AI 默认执行路径。

team-candidate
  多仓库出现，但尚未 Owner 确认。

owner-confirmed-active
  负责人确认，可信度最高。

department-active
  跨团队确认，进入部门级规范。

pending-confirmation
  需要人工判断，不进入 AI 默认执行。

conflict
  正反模式并存，等待裁定。

legacy-compatible
  历史兼容写法，AI 不应新增，但 Review 不必立即阻断。

owner-rejected
  已被负责人否决，后续不得重复激活。
```

## 14.2 升级路径

```text
candidate
  -> draft
  -> auto-active
  -> team-candidate
  -> owner-confirmed-active
  -> department-active
```

## 14.3 降级路径

```text
auto-active
  -> stale-auto-active
  -> pending-confirmation
  -> owner-rejected

draft
  -> conflict
  -> owner-rejected
```

---

# 15. 输出产物设计

## 15.1 `standard-{sub_domain}.md`

人读规范。

结构：

```md
---
doc_id: backend-java-standard
domain: backend
sub_domain: java
doc_type: standard
index_format: engineering-standards-md-v1
tags:
  - backend
  - java
  - layering
---

# Java 后端开发规范

## 适用范围

## 技术栈画像

## P0 强制规则

## P1 推荐规则

## P2 建议规则

## FORBIDDEN 禁止事项

## 正例

## 反例

## AI 生成代码要求

## Code Review 检查项

## Evidence 索引

## Pending / Conflict
```

---

## 15.2 `ai-rules.md`

AI Coding 默认执行规则。

特点：

```text
短
明确
无长解释
只包含 auto-active / owner-confirmed-active
```

示例：

```md
# Java Backend AI Rules

## Must

- New REST APIs must follow Controller -> ApplicationService -> DomainService/Repository.
- Controller must not call Repository or Mapper directly.
- Business exceptions must use the unified error-code model.

## Must Not

- Do not open database transactions in Controller.
- Do not catch Exception and only log it.
- Do not hardcode market / region / tenant branches in business code.
```

---

## 15.3 `review-checklist.md`

人工 Review 和 AI Review 检查表。

```md
# Java Backend Review Checklist

- [ ] Controller 是否只做协议适配？
- [ ] 是否存在 Controller 直接访问 Mapper / Repository？
- [ ] 写操作事务边界是否在 ApplicationService？
- [ ] 异常是否转换为统一错误码？
- [ ] 日志是否包含敏感字段？
- [ ] MQ Consumer 是否具备幂等保护？
```

---

## 15.4 `rules-index.json`

机器索引。

```json
{
  "index_format": "engineering-standards-rules-index-v2",
  "rules": [
    {
      "rule_id": "backend-java-layering-001",
      "title": "P1 Controller 不得直接访问 Repository / Mapper",
      "domain": "backend",
      "sub_domain": "java",
      "level": "P1",
      "status": "auto-active",
      "source_doc": "04-backend/standard-java.md",
      "section_title": "P1 Controller 不得直接访问 Repository / Mapper",
      "evidence_doc": "04-backend/evidence/java-layering.md",
      "authority_scope": "this-repo",
      "upgrade_mode": "auto-active",
      "deterministic_occurrence_count": 6,
      "module_diversity": 3,
      "risk_tag": "medium",
      "tags": [
        "backend",
        "java",
        "layering",
        "controller"
      ]
    }
  ]
}
```

---

## 15.5 `pending-confirmation.md`

用于沉淀待人工确认的规则。

```md
# Pending Confirmation

## PENDING-001 Controller 是否禁止直接访问 Repository

原因：
- 有 2 个正例
- 有 1 个反例
- 反例可能是历史兼容代码

需要 Owner 决策：
- 是否确认该规则为 active？
- 反例是否标记为 legacy-compatible？
```

---

## 15.6 `conflicts.md`

用于记录冲突模式。

```md
# Conflicts

## CONFLICT-001 API 返回体封装方式不一致

模式 A：
- trade-service 使用 Result<T>

模式 B：
- account-service 使用 ApiResponse<T>

影响：
- AI 无法默认选择统一返回模型

建议：
- 后端 Owner 裁定部门级返回体规范
```

---

## 15.7 `lineage-ledger.json`

记录规则来源和状态变化。

```json
{
  "rule_id": "backend-java-layering-001",
  "created_by_run": "run-20260603-001",
  "source_projects": [
    "trade-service"
  ],
  "source_facts": [
    "FACT-BE-JAVA-001"
  ],
  "status_history": [
    {
      "status": "draft",
      "time": "2026-06-03T12:00:00+08:00",
      "reason": "Initial extraction"
    }
  ]
}
```

---

# 16. 外部工具集成设计

## 16.1 CodeWiki 集成

定位：

```text
仓库理解增强器
规范候选信号源
batch planning hint
```

不能作为：

```text
deterministic evidence
auto-active 判断依据
强制 AI Rules 来源
```

接入方式：

```text
CodeWiki 输出
  -> codewiki-signals.v1
  -> Repo Profiler / Pattern Miner advisory input
  -> Fact Collector 回源代码验证
```

合同：

```json
{
  "schema": "codewiki-signals.v1",
  "source": "codewiki",
  "trust_level": "advisory",
  "evidence_required": true,
  "candidate_patterns": [
    {
      "title": "Controller-Service-Repository layering",
      "source_docs": [
        ".codewiki/docs/overview.md"
      ],
      "evidence_required": true
    }
  ]
}
```

---

## 16.2 CodeGraph / AST 集成

定位：

```text
确定性代码事实层
```

提供：

```text
函数 / 类 / 方法
调用关系
依赖关系
路由
模块边界
符号引用
影响面
```

接入位置：

```text
Fact Collectors
Pattern Miner
Evidence Gate
```

---

## 16.3 PR Review Mining 集成

定位：

```text
团队隐性规范抽取器
```

PR Review 评论非常关键，因为：

```text
代码里有好代码，也有坏代码。
Review 评论里有团队真正纠正过的问题。
```

抽取内容：

```text
重复出现的 review comment
禁止模式
架构偏好
异常处理偏好
命名约定
测试要求
安全红线
```

输出：

```json
{
  "schema": "pr-review-signals.v1",
  "review_patterns": [
    {
      "title": "不要在 Controller 直接访问 Mapper",
      "comments_count": 5,
      "source_prs": [
        "PR-123",
        "PR-456"
      ],
      "suggested_rule_category": "layering"
    }
  ]
}
```

---

## 16.4 OpenDeepWiki 集成

定位：

```text
部门级知识库展示与消费平台
```

`project-standard-extractor` 负责生产规范资产，OpenDeepWiki 负责：

```text
规范检索
Wiki 展示
Chat 问答
MCP 分发
部门权限
知识库入口
```

---

## 16.5 spec-first / AI Coding Harness 集成

最终消费路径：

```text
engineering-standards/rules-index.json
engineering-standards/**/ai-rules.md
engineering-standards/**/review-checklist.md
  -> spec-first
  -> PRD / Plan / Work / Review
```

使用方式：

```text
PRD 阶段：
  读取相关研发域规范，避免需求设计违背工程约束。

Plan 阶段：
  根据 rules-index 选择相关规则。

Work 阶段：
  AI Coding 按 ai-rules 生成代码。

Review 阶段：
  根据 review-checklist 做自动检查。
```

---

# 17. 多仓库抽取策略

1000+ 工程不能一开始全量抽。

## 17.1 第一层：黄金样本仓库

每个端选择高质量项目：

```text
APP：5-10 个
PC：3-5 个
H5/Admin：10 个
Java 后端：20 个
Python：5 个
公共 SDK / 基础库：5-10 个
```

目标：

```text
抽出第一版高质量规范
形成各端 standard / ai-rules / checklist
```

---

## 17.2 第二层：验证仓库

选择中等质量项目验证：

```text
规则是否过拟合？
是否能覆盖真实项目？
是否存在大量 conflict？
是否需要 legacy-compatible？
```

目标：

```text
把 this-repo 规则升级成 team-candidate
```

---

## 17.3 第三层：全量扫描

对 1000+ 工程只做：

```text
规则命中率
违反情况
例外清单
legacy-compatible
规范覆盖率
```

目标不是继续生成大量新规则，而是验证和治理。

---

# 18. 实施路线图

## Phase 0：当前设计固化

目标：

```text
确认 V2 方案
明确 Skill 边界
冻结数据合同
```

交付物：

```text
docs/02-技术方案/project-standard-extractor-v2.md
skills/project-standard-extractor/contracts/*.schema.json
skills/project-standard-extractor/workflows/full-auto.md
```

---

## Phase 1：最小闭环

实现：

```text
薄 SKILL.md
repo-profile.v1
batch-plan.v1
code-facts.v1
pattern-candidates.v1
standard-rule.v1
quality gate
publisher
```

只支持三个抽取器：

```text
Java 后端 layering / exception / logging
前端 route / api-client / state
APP KMP / ViewModel / Repository
```

验收：

```text
能从 3 个真实项目抽出 evidence-backed draft 规范。
ai-rules.md 不包含无 evidence 规则。
review-checklist.md 只从 standard 派生。
```

---

## Phase 2：多端扩展

新增：

```text
Python collector
PC collector
MQ / cache / transaction collector
testing collector
release collector
security pending collector
```

目标：

```text
覆盖 APP / PC / Frontend / Backend 各端第一版规范。
```

---

## Phase 3：外部工具接入

接入：

```text
CodeWiki advisory signals
CodeGraph deterministic facts
PR Review Mining
```

目标：

```text
提高 batch planning 准确性。
提高 evidence 质量。
补齐团队隐性规范。
```

---

## Phase 4：多仓库治理

新增：

```text
cross-repo consistency miner
team-candidate upgrade
owner-confirmed workflow
department-active workflow
```

目标：

```text
从单仓规范升级为团队 / 部门规范。
```

---

## Phase 5：知识库与 Harness 消费

接入：

```text
OpenDeepWiki
spec-first
MCP
AI Coding Harness
```

目标：

```text
规范可检索
AI 可调用
Review 可执行
持续治理
```

---

# 19. Eval 与验收标准

## 19.1 Golden Sample

每个端至少准备：

```text
1 个优秀项目
1 个普通项目
1 个存在反模式项目
```

## 19.2 质量指标

```text
evidence coverage
  每条规则是否有 evidence

active precision
  auto-active 规则人工认可率

pending recall
  有风险规则是否进入 pending

conflict detection
  正反模式并存是否被识别

AI usability
  ai-rules 是否能指导 AI 写代码

review usability
  review-checklist 是否能用于真实 PR Review

owner workload
  pending 是否过多，是否可裁定
```

## 19.3 阻断条件

```text
出现无 evidence active 规则
CodeWiki-only 规则进入 ai-rules
高风险规则自动 active
覆盖已有 owner-confirmed 规则
规则正文泄露具体项目路径或敏感信息
```

---

# 20. 推荐落地文件变更

第一批提交建议：

```text
skills/project-standard-extractor/
├── workflows/full-auto.md
├── agents/01-intake-and-scope.md
├── agents/02-repo-profiler.md
├── agents/03-fact-collector.md
├── agents/04-pattern-miner.md
├── agents/05-rule-synthesizer.md
├── agents/06-quality-gate.md
├── agents/07-publisher.md
├── contracts/repo-profile.v1.schema.json
├── contracts/code-facts.v1.schema.json
├── contracts/pattern-candidates.v1.schema.json
├── contracts/standard-rule.v1.schema.json
├── collectors/common/detect-stack.mjs
├── collectors/backend/collect-java-layer-facts.mjs
├── miners/mine-layering-patterns.mjs
├── scripts/validate-contracts.mjs
└── scripts/render-standards.mjs
```

第二批提交：

```text
collectors/frontend/
collectors/app-client/
quality-gates/
integrations/codewiki.md
integrations/codegraph.md
integrations/pr-review-mining.md
evals/golden-samples/
```

---

# 21. 最终总结

重新设计后的 `project-standard-extractor` 不再是一个“写规范的 Prompt”，而是一个完整的规范萃取系统：

```text
代码事实层
  用确定性工具从源码抽 facts

模式发现层
  从 facts 中发现重复模式、反模式和冲突

规范生成层
  用 LLM 把模式转成标准规则

质量门禁层
  控制 evidence、风险、冲突和可执行性

发布治理层
  生成 standard、ai-rules、review-checklist、rules-index

AI 消费层
  给 spec-first / AI Coding Harness / Review 使用
```

最终目标是：

> **从团队优秀代码和真实 Review 反馈中，沉淀 AI 可执行、Reviewer 可检查、Owner 可裁定、Evidence 可追溯的研发编码契约。**

[1]: https://raw.githubusercontent.com/sunrain520/ai-engineering-standards/feat/project-standard-extractor/README.md "raw.githubusercontent.com"
[2]: https://raw.githubusercontent.com/sunrain520/ai-engineering-standards/feat/project-standard-extractor/skills/project-standard-extractor/SKILL.md "raw.githubusercontent.com"
