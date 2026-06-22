# project-standard-extractor 执行逻辑与产物分析

## 1. 审查范围

本文件分析 `skills/project-standard-extractor` 的真实执行逻辑、目录结构、运行产物和正式产物。审查方式是完整读取目标 skill 目录下的文件，而不是抽查入口或样例文件。

本次已审查的目标范围：

| 范围 | 数量 | 说明 |
| --- | ---: | --- |
| `skills/project-standard-extractor` 文件总数 | 111 | 覆盖入口、agent、workflow、contracts、scripts、collectors、miners、templates、tests、evals、reports、golden sample |
| 入口与治理文件 | 4 | `SKILL.md`、`README.md`、`manifest.json`、`agents/interface.yaml` |
| agent / workflow 文档 | 13 | 8 个 agent 阶段、5 个 workflow 文档 |
| JSON Schema 合同 | 9 | `project-input` 到 `owner-decision-queue` 的 v1 合同 |
| 可执行脚本与库 | 26 | `run-*`、渲染、合并、校验、门禁和工具库 |
| collector / miner | 17 | 9 个 collector 文件、8 个 miner 文件 |
| 测试文件 | 11 | Node test 覆盖 schema、intake、facts、mining、gates、rendering、e2e、governance scaffolding |
| eval / reports | 15 | trigger/output eval、golden samples、trust report、scorecard、risk profile |
| 当前正式产物 | 11 | `engineering-standards/04-backend` 下的标准、AI rules、review checklist、索引、lineage、Owner queue 和 evidence |

补充读取范围：

- 当前正式产物目录：`engineering-standards/04-backend/`
- 历史运行目录：`.runs/20260604-020908-backend-java-spring-e76b1da/`
- 根目录运行入口：`package.json`
- changelog 约束：`CHANGELOG.md`

## 2. Skill 意图

`project-standard-extractor` 的核心意图是：从真实项目代码路径中抽取确定性代码事实，再把事实聚合成模式，最后经过质量门禁发布可追溯的端内研发规范。

它不是一个“写最佳实践”的 prompt。入口文件明确要求：

- 输入必须绑定单一 `extraction_target{domain, sub_domain}`。
- Phase 0 只支持 `backend/java-spring`。
- 业务项目源码只读。
- LLM 或规则归纳只能基于 `code-facts.v1` 和 `pattern-candidates.v1`，不能伪造 evidence。
- `ai-rules-*.md` 和 `review-checklist-*.md` 必须从已通过门禁的标准规则派生。
- 非 Git 项目允许抽取，但必须用 `snapshot_id + path_hash + file + line_range + snippet_hash` 锚定证据。
- formal merge 只能写入当前 domain 允许的 `engineering-standards/{domain}/` 目录。

适用场景：

- 用户提供真实项目路径，并要求生成 evidence-backed 规范、AI Coding Rules、Review Checklist、lineage 或 Owner queue。
- 需要验证某一端规范是否可以从源码证据派生。
- 需要把规范生成过程保留为 `.runs/{run_id}` 可审计产物。

不适用场景：

- 单文件解释。
- 无项目路径的通用最佳实践。
- PR code review。
- 修改业务源码。
- 一次性混合抽取多个端。
- 自动激活交易、资金、权限、安全、合规等高风险规则。

## 3. 顶层目录结构

`skills/project-standard-extractor` 的目录承担不同职责：

| 目录 / 文件 | 职责 |
| --- | --- |
| `SKILL.md` | skill 入口、触发条件、非触发边界、默认 workflow、硬规则 |
| `README.md` | Phase 0 能力、输入格式、命令、治理证据和边界 |
| `manifest.json` | owner、版本、maturity、review cadence、input files、output contract、rollback boundary |
| `agents/interface.yaml` | 可复用执行接口：能力、输入、workflow 阶段、产物、安全边界、验证命令 |
| `agents/` | 8 个逻辑 agent 阶段说明 |
| `workflows/` | full-auto、profile-first、batch、diff、owner-review 的流程说明 |
| `contracts/` | 9 个 JSON Schema，约束输入、中间产物和治理产物 |
| `scripts/` | Node.js ESM 可执行链路 |
| `collectors/` | 从项目源码抽取确定性事实 |
| `miners/` | 从 facts 聚合 pattern candidates |
| `quality-gates/` | 七道门禁、自治决策策略和 warning 路由说明 |
| `templates/` | backend 输出模板说明；当前具体格式由 renderer 脚本直接生成 |
| `domains/` | domain router 的文档化配置与未来占位 |
| `evals/` | trigger / output eval 和 Java Spring golden sample |
| `reports/` | trust report、output quality scorecard、output risk profile |
| `tests/` | Node test 验证合同、执行链路、门禁、渲染和治理资产 |

Phase 0 的实现重点集中在 `backend/java-spring`。`frontend`、`app-client`、`pc-client` 目录目前只有 README 占位，不代表可运行抽取器。

## 4. 运行入口

根 `package.json` 暴露了以下命令：

| 命令 | 入口脚本 | 作用 |
| --- | --- | --- |
| `npm run pse:profile -- --input <input.json>` | `scripts/run-profile.mjs` | 输入校验、domain 路由、run id、manifest、repo profile、batch plan |
| `npm run pse:facts -- --run-id <run_id>` | `scripts/run-fact-collection.mjs` | 读取 profile/input，抽取 `code-facts.v1.json` |
| `npm run pse:mine -- --run-id <run_id>` | `scripts/run-pattern-mining.mjs` | 从 facts 生成 `pattern-candidates.v1.json` 和 `standard-rule.v1.json` |
| `npm run pse:gates -- --run-id <run_id>` | `scripts/run-quality-gates.mjs` | 七道门禁 + 自治策略，生成 `rule-decision.v1.json` |
| `npm run pse:render -- --run-id <run_id>` | `scripts/render-standards.mjs` | 渲染 `.runs/{run_id}/formal-output/...` |
| `npm run pse:validate -- --run-id <run_id>` | `scripts/validate-contracts.mjs` | 校验 schema 和 run 目录下的 `*.v1.json` artifact |
| `npm run pse:merge -- --run-id <run_id>` | `scripts/merge-append-only.mjs` | 将 formal-output 合并到正式目录 |
| `npm run pse:full-auto -- --input <input.json>` | `scripts/run-full-auto.mjs` | 串联完整链路 |
| `npm test` | `node --test` | 运行全部测试 |

最完整的执行入口是 `runFullAuto()`。它的顺序是：

1. `runProfile`
2. `runFactCollection`
3. `runPatternMining`
4. `runQualityGates`
5. `runRenderStandards`
6. `runValidateContracts`
7. `runMergeAppendOnly`
8. 成功后把 `.runs/{run_id}/manifest.json` 的 `status` 改为 `completed`
9. 任一异常后把 manifest 改为 `failed` 并记录 `error`

因此，formal output 会先写到 `.runs/{run_id}/formal-output/engineering-standards/04-backend/`，合同验证通过后才 merge 到 `engineering-standards/04-backend/`。

## 5. 输入处理与路由

输入合同是 `contracts/project-input.v1.schema.json`，必填字段：

- `schema: "project-input.v1"`
- `extraction_target.domain`
- `extraction_target.sub_domain`
- `project_paths[]`

可选字段：

- `scope.include[]`
- `scope.exclude[]`
- `output.base_dir`
- `output.mode`
- `constraints`

`normalizeProjectInput()` 会做三件事：

1. 为 `scope.include` 填默认值 `["**/*"]`。
2. 为 `scope.exclude` 填默认忽略项：`.git`、`target`、`build`、`generated`、`node_modules`、`.gradle`、`dist`。
3. 为 `output` 填默认值：`base_dir` 来自 domain route，`mode` 为 `append-only`。

随后它用 Ajv 校验 `project-input.v1`，并把 `project_paths` 转成基于 `workspaceRoot` 的绝对路径。注意：`run-profile` 写入 `.runs/{run_id}/project-input.v1.json` 时会保留用户原始 `project_paths`，后续 fact collection 再用 `path.resolve(workspaceRoot, rawPath)` 解析。

domain router 当前只注册一个可执行目标：

| domain | sub_domain | outputDir |
| --- | --- | --- |
| `backend` | `java-spring` | `engineering-standards/04-backend` |

`routeForTarget()` 对不支持的 `extraction_target` 直接抛错。`assertSingleDomain()` 会扫描输入项目路径：

- backend 信号：`**/*.java`、`**/pom.xml`
- frontend 信号：`**/package.json`、`**/*.vue`、`**/*.tsx`、`**/*.jsx`
- app-client 信号：`**/*.kt`、`**/*.swift`

如果同一次运行发现多个 domain，会报错：`Mixed-domain input detected (...)`。如果发现单一 domain 但不是目标 domain，也会报错。当前实现没有 pc-client 检测规则。

一个重要细节是：`output.base_dir` 虽然在输入合同中允许，但实际 formal output 和 merge 边界都使用 router 的 `route.outputDir`。也就是说，调用者不能通过输入把 backend/java-spring 的正式产物重定向到其他目录。

## 6. Run ID、snapshot 和 profile

`runProfile()` 创建运行目录 `.runs/{run_id}`。`run_id` 格式：

```text
{YYYYMMDD-HHMMSS}-{domain}-{sub_domain}-{inputFingerprintShortHash}
```

`snapshot_id` 格式：

```text
snapshot-{YYYYMMDD-HHMMSS}-{inputFingerprintShortHash}
```

`input_fingerprint` 的计算基于：

- `extraction_target`
- 排序后的 `project_paths` 路径 hash
- `scope`
- `output`

`runProfile()` 对每个项目路径收集：

- 是否 Git repo
- Git commit hash，非 Git 为 `null`
- `source_type: git | filesystem`
- `snapshot_id`
- `path_hash`
- 文件数量
- Java/Maven/Spring 候选栈信号

随后写入：

- `.runs/{run_id}/manifest.json`
- `.runs/{run_id}/project-input.v1.json`
- `.runs/{run_id}/repo-profile.v1.json`
- `.runs/{run_id}/batch-plan.v1.json`

当前 batch plan 固定生成一个 batch：

```text
batch_id: backend-java-layering
paths: src/main/java, src/main/resources
purpose: extract backend Java layering, API, transaction, exception and infrastructure conventions
risk_level: medium
status: ready
```

实现里会计算项目内容 hash，但当前只使用 `fileCount`，没有把目录内容 hash 写入 profile 或 manifest。

## 7. Fact Collection 逻辑

`runFactCollection()` 读取 `.runs/{run_id}/repo-profile.v1.json` 和 `.runs/{run_id}/project-input.v1.json`，对每个 `project_path` 调用 `collectJavaFacts()`，最终写出 `code-facts.v1.json`。

实际可执行 collector 是：

- `collectors/backend/collect-java-layer-facts.mjs`

其他 backend collector 文件：

- `collect-spring-api-facts.mjs`
- `collect-transaction-facts.mjs`
- `collect-exception-log-facts.mjs`
- `collect-cache-facts.mjs`
- `collect-mq-job-facts.mjs`

这些文件当前都是 re-export `collectJavaFacts`，没有独立逻辑。真正的 Java collector 在一次扫描中识别多类注解和分层信号。

### 7.1 文件扫描

collector 使用 `fast-glob` 扫描 `**/*.java`，遵守输入 `scope.exclude` 或默认 ignore。它会判断：

- 是否测试文件：路径包含 `src/test/` 或文件名以 `Test.java` 结尾。
- 是否 Controller 文件：文件名以 `Controller.java` 结尾，或内容包含 `@RestController` / `@Controller`。

### 7.2 注解事实

当前 annotation matcher：

| regex | kind | role | observation |
| --- | --- | --- | --- |
| `@RestController` / `@Controller` | `spring-api` | `controller` | Spring controller exposes HTTP endpoints |
| `@RequestMapping` / `@GetMapping` / `@PostMapping` / `@PutMapping` / `@DeleteMapping` | `spring-api` | `request-mapping` | Spring mapping annotation defines API route |
| `@Service` | `layering` | `service` | Service layer component is declared |
| `@Repository` | `layering` | `repository` | Repository layer component is declared |
| `@Mapper` | `layering` | `mapper` | Mapper layer component is declared |
| `@Transactional` | `transaction` | `transaction-boundary` | Transactional boundary is declared |
| `@RestControllerAdvice` / `@ControllerAdvice` / `@ExceptionHandler` | `exception` | `exception-handler` | Exception handling component is declared |
| `@Cacheable` / `@CacheEvict` / `@CachePut` | `cache` | `cache` | Cache annotation is declared |
| `@Scheduled` / `@KafkaListener` / `@RabbitListener` / `@RocketMQMessageListener` | `mq-job` | `async-job` | Async job or message listener is declared |

### 7.3 分层违规事实

如果当前文件是 Controller 文件，并且某一行包含 `Mapper` 或 `Repository`，且不是 import 行，则 collector 生成：

```text
kind: layering-violation
role: controller-direct-data-access
observation: Controller directly references Mapper or Repository
```

这类 fact 的 `positive_examples` 为空，`negative_examples` 包含文件路径。

### 7.4 Evidence anchor

每条 fact 都包含 `source_anchor`：

- `source_type`
- `snapshot_id`
- `path_hash`
- `file`
- `line_range.start`
- `line_range.end`
- `snippet_hash`

Git 信息单独放在 `git.available` 和 `git.commit`。非 Git 项目不会被阻断，因为 GIT-001 门禁接受 snapshot anchor。

## 8. Pattern Mining 和规则合成

`runPatternMining()` 读取 `code-facts.v1.json`，按顺序执行：

1. `mineLayeringPatterns`
2. `mineApiPatterns`
3. `mineErrorHandlingPatterns`
4. `mineForbiddenPatterns`

随后写出：

- `.runs/{run_id}/pattern-candidates.v1.json`
- `.runs/{run_id}/standard-rule.v1.json`

其他 miner 当前是空实现：

- `mine-naming-patterns.mjs`
- `mine-test-patterns.mjs`
- `mine-log-patterns.mjs`
- `mine-legacy-compatible-patterns.mjs`

### 8.1 Layering pattern

`mineLayeringPatterns()` 只使用非 test facts。它要求同时存在 controller 和 service anchor，否则不生成 pattern。

生成 pattern 时：

- positive facts：最多 8 个 controller + 最多 8 个 service。
- negative facts：所有 `layering-violation`。
- suggested state：有 violation 则 `conflict`，否则 positive >= 2 为 `auto-active`，否则 `draft`。
- risk：`medium`。

### 8.2 API pattern

`mineApiPatterns()` 使用非 test 的 `spring-api` facts。少于 2 个不生成。

它会基于文件路径判断高风险：

```text
login|logout|auth|security|permission|权限|认证|安全
```

如果命中，高风险 API pattern：

- `risk_level: high`
- `suggested_state: pending-confirmation`

否则：

- `risk_level: medium`
- `suggested_state: auto-active`

### 8.3 Exception pattern

`mineErrorHandlingPatterns()` 使用非 test 的 `exception` facts。只要存在 exception fact 就生成 pattern。

- exception facts >= 2 时建议 `auto-active`
- 否则建议 `draft`

### 8.4 Forbidden pattern

`mineForbiddenPatterns()` 对非 test 的 `layering-violation` 生成 negative-only pattern：

- `positive_fact_ids: []`
- `negative_fact_ids: violations`
- `suggested_state: conflict`

但后续 evidence gate 要求规则必须有 positive evidence。因此，如果 forbidden pattern 被合成为规则，会先触发 evidence fail 并成为 `rejected`，而不是进入 conflict/Owner 路由。当前测试样例的 conflict 主要由 layering pattern 同时拥有 positive 和 negative facts 触发。

### 8.5 Rule synthesis

`synthesizeRule()` 当前是确定性硬编码文本，不是运行时 LLM 生成。它把 pattern 映射为 `standard-rule.v1`：

| pattern category | 生成规则 |
| --- | --- |
| `layering` / `forbidden` | `Controller 不得直接访问 Mapper / Repository` |
| `api` | `Spring API 必须通过明确映射注解暴露` |
| 其他，当前主要是 `exception` | `异常处理应进入统一处理组件` |

规则 ID 格式：

```text
backend-java-{pattern.category}-{ordinal}
```

`suggested_state === "auto-active"` 会先写成 rule `status: candidate`，最终是否 active 由 quality gates 决定。

## 9. 质量门禁

`runQualityGates()` 读取：

- `.runs/{run_id}/code-facts.v1.json`
- `.runs/{run_id}/standard-rule.v1.json`

并对每条 rule 生成 `rule-decision.v1.json`。门禁共 7 类，门禁之后再进入自治决策策略：

| Gate | 实现 | 逻辑 |
| --- | --- | --- |
| Evidence | `gates/evidence.mjs` | 必须有 positive evidence；所有 positive/negative evidence id 必须存在；positive 少于 2 个为 warning |
| Actionability | `run-quality-gates.mjs` | 必须有 Must 或 Must Not；拒绝“代码要优雅 / 接口要合理 / 注意异常 / 模块要清晰”等泛化表达 |
| Abstraction | `run-quality-gates.mjs` | rule text 过短 fail；包含 `#method()` 形式 warning |
| Conflict | `gates/conflict.mjs` | 有 negative evidence 即 warning |
| Risk | `gates/risk.mjs` | high risk 或 owner_required 为 warning |
| Derivation | `gates/derivation.mjs` | evidence fail 则 fail；缺 AI rule 或 review checklist 为 warning |
| GIT-001 | `gates/git-001.mjs` | 非 Git evidence 必须有 snapshot/path/file/line/snippet anchor |
| Autonomy Policy | `autonomy-policy.mjs` | 汇总多维置信分，决定自治发布、自治 draft/refine，或 Owner gate |

### 9.1 决策优先级

门禁决策顺序非常重要：

1. Evidence、Actionability、Abstraction、Derivation、GIT-001 任一 fail：`decision: rejected`，`next_action: fix-or-drop-rule`
2. Conflict 非 pass：`decision: conflict`，`next_action: owner-review`
3. Risk 非 pass：`decision: pending-confirmation`，`next_action: owner-review`
4. Evidence warning：`decision: draft`，`next_action: collect-more-evidence`
5. Actionability 或 Abstraction warning：`decision: draft`，`next_action: refine-rule`
6. 所有 gates pass 且 `confidence.score >= 0.75`：`decision: auto-active`，`next_action: publish`
7. 其他情况保持 `draft` / `keep-draft`

这意味着 warning 不会静默进入 active 输出；当前 `quality-gates/README.md` 和测试都覆盖了这个约束。v1.10.5 起，`rule-decision.v1` 还会输出：

- `confidence.score` / `confidence.tier`
- `confidence.signals`
- `autonomy.mode`
- `autonomy.owner_gate`
- `autonomy.policy`
- `decision_trace`

低/中风险规则在所有门禁通过且置信分达到阈值时默认自治发布；证据不足或抽象不足保持系统自治 draft/refine，不进入人工裁定。

### 9.2 高风险路由

风险判断来自两处：

- rule 本身 `risk_level === "high"`
- 标题或文本命中高风险词：交易、资金、清结算、权限、认证、隐私、安全、合规、发布、生产变更、风控、auth、security、payment、fund、privacy、compliance

高风险或 `owner_required: true` 的规则不会自动 active，会进入 `pending-confirmation` 和 Owner queue。Owner review 不再作为普通不确定性的兜底，只保留给 conflict、high risk 或显式 `owner_required`。

## 10. 渲染逻辑

`runRenderStandards()` 读取 profile、facts、standard rules 和 rule decisions，调用 `renderFormalOutputs()` 写入：

```text
.runs/{run_id}/formal-output/engineering-standards/04-backend/
```

当前 renderer 不读取 `templates/backend/*` 的内容；模板目录只是说明型占位。具体格式由 `scripts/lib/rendering.mjs` 直接拼接。

### 10.1 formal-output 文件

每次渲染会生成：

| 文件 | 内容来源 | 过滤逻辑 |
| --- | --- | --- |
| `standard-java-spring.md` | 所有 standard rules + decisions + evidence anchors | 包含所有规则，不只 auto-active |
| `ai-rules-java-spring.md` | `activeRules` 的 `ai_coding_rule` 和 `must_not` | 只包含 `decision === auto-active` |
| `review-checklist-java-spring.md` | `activeRules.review_checklist` | 只包含 `decision === auto-active` |
| `pending-confirmation.md` | draft 和 pending-confirmation rules | `decision in ["draft", "pending-confirmation"]` |
| `conflicts.md` | conflict rules | `decision === conflict` |
| `rules-index.json` | active rules 的索引，含 confidence/autonomy 字段 | 只包含 `decision === auto-active` |
| `lineage-ledger.json` | 所有 rules 的 lineage | 包含 rule、source patterns、source facts、source projects、状态历史 |
| `owner-decision-queue.json` | conflict / pending-confirmation rules，含 `confidence_score` 和 `owner_gate` | `decision in ["conflict", "pending-confirmation"]` |
| `evidence/java-spring/{rule_id}.md` | 每条 rule 的 positive/negative facts | 所有 rules 都生成 evidence 文件 |

`standard-java-spring.md` 包含 pending/high-risk 规则是当前实现行为，并会展示 confidence 与 autonomy。只有 AI rules、review checklist 和 rules-index 被限制为 auto-active。

### 10.2 formal output 路径边界

渲染每个 markdown 文件和每个 evidence 文件前都会调用：

```text
assertOutputWithinDomain(rel, target)
```

这保证路径必须以 `engineering-standards/04-backend/` 开头。

JSON 文件写入时没有逐个调用 `assertOutputWithinDomain`，但它们写在同一个 `outputRoot` 下。merge 阶段会对整棵树的每个 entry 再做一次 domain boundary 校验。

## 11. Merge 逻辑

`runMergeAppendOnly()` 读取 run 目录中的 `repo-profile.v1.json`，用 profile 的 `extraction_target` 决定目标目录，然后把：

```text
.runs/{run_id}/formal-output/engineering-standards/04-backend/
```

复制或合并到：

```text
engineering-standards/04-backend/
```

合并规则：

- 每个输出路径都再次经过 `assertOutputWithinDomain()`。
- 新文件直接 copy。
- 目录递归创建。
- JSON 文件若已存在：
  - 两边都是数组：拼接。
  - 两边都有 `rules`：按 `rule_id` 合并，新值覆盖旧值。
  - 两边都有 `entries`：按 `rule_id` 合并。
  - 两边都有 `items`：按 `rule_id` 合并。
  - 其他 JSON：新值覆盖旧值。
- Markdown 文件若已存在：
  - 如果旧内容不包含新内容的 `trim()`，就在旧文档尾部追加分隔线和新文档。

这里有一个实际风险：markdown 的去重基于完整新内容。`standard-java-spring.md` 含 `generated_by_run`，不同 run 即便规则近似，也可能因为 run id 不同导致重复追加。JSON 侧按 `rule_id` merge 更稳。

## 12. 产物目录

### 12.1 临时运行目录 `.runs/{run_id}`

`.runs/` 已在 `.gitignore` 中排除，定位是临时运行与审计目录，不是正式 source。当前仓库保留了两个历史 run：

- `.runs/20260604-020735-backend-java-spring-e76b1da/`
- `.runs/20260604-020908-backend-java-spring-e76b1da/`

典型 run 目录结构：

```text
.runs/{run_id}/
├── manifest.json
├── project-input.v1.json
├── repo-profile.v1.json
├── batch-plan.v1.json
├── code-facts.v1.json
├── pattern-candidates.v1.json
├── standard-rule.v1.json
├── rule-decision.v1.json
└── formal-output/
    └── engineering-standards/04-backend/
        ├── standard-java-spring.md
        ├── ai-rules-java-spring.md
        ├── review-checklist-java-spring.md
        ├── pending-confirmation.md
        ├── conflicts.md
        ├── rules-index.json
        ├── lineage-ledger.json
        ├── owner-decision-queue.json
        └── evidence/java-spring/{rule_id}.md
```

各文件作用：

| 文件 | 内容 |
| --- | --- |
| `manifest.json` | run id、tool、domain、sub_domain、created_at、input_fingerprint、source_projects、output_base_dir、status |
| `project-input.v1.json` | 本次运行使用的输入，保留原始 project paths |
| `repo-profile.v1.json` | source projects、detected stacks、domain match、batch plan、blind spots |
| `batch-plan.v1.json` | 可执行 batch 列表 |
| `code-facts.v1.json` | 源码事实，含 source anchor、git/snapshot、scope、confidence |
| `pattern-candidates.v1.json` | 从 facts 聚合出的 pattern candidates |
| `standard-rule.v1.json` | 从 pattern candidates 合成的规则候选 |
| `rule-decision.v1.json` | 每条规则的门禁结果、decision、next_action |
| `formal-output/...` | merge 前的正式产物候选 |

对当前历史 run `20260604-020908-backend-java-spring-e76b1da` 的统计：

| 项 | 数值 |
| --- | ---: |
| source projects | 1 |
| facts | 1268 |
| patterns | 3 |
| rules | 3 |
| decisions | 3 |
| auto-active decisions | 2 |
| pending-confirmation decisions | 1 |

facts 分布：

| kind | 数量 |
| --- | ---: |
| `spring-api` | 724 |
| `layering` | 430 |
| `transaction` | 105 |
| `exception` | 6 |
| `mq-job` | 3 |

role 分布：

| role | 数量 |
| --- | ---: |
| `request-mapping` | 640 |
| `service` | 285 |
| `mapper` | 108 |
| `transaction-boundary` | 105 |
| `controller` | 84 |
| `repository` | 37 |
| `exception-handler` | 6 |
| `async-job` | 3 |

scope 分布：

| scope | 数量 |
| --- | ---: |
| `main` | 1262 |
| `test` | 6 |

该 run 的三条规则：

| rule | decision | risk | evidence | next action |
| --- | --- | --- | ---: | --- |
| `backend-java-layering-001` | `auto-active` | medium | 16 positive | publish |
| `backend-java-api-002` | `pending-confirmation` | high | 12 positive | owner-review |
| `backend-java-exception-003` | `auto-active` | medium | 4 positive | publish |

### 12.2 正式产物目录 `engineering-standards/04-backend`

当前正式目录文件：

```text
engineering-standards/04-backend/
├── standard-java-spring.md
├── ai-rules-java-spring.md
├── review-checklist-java-spring.md
├── pending-confirmation.md
├── conflicts.md
├── rules-index.json
├── lineage-ledger.json
├── owner-decision-queue.json
└── evidence/java-spring/
    ├── backend-java-api-002.md
    ├── backend-java-exception-003.md
    └── backend-java-layering-001.md
```

当前正式产物内容概览：

| 文件 | 当前内容 |
| --- | --- |
| `standard-java-spring.md` | 3 条 Java Spring 后端规则；包含 `auto-active` 的 layering、exception 规则，也包含 `pending-confirmation` 的 API 规则 |
| `ai-rules-java-spring.md` | 只包含 2 条 active 规则派生出的 AI coding rules：分层访问、统一异常处理 |
| `review-checklist-java-spring.md` | 只包含 2 条 active 规则派生出的 review checklist |
| `pending-confirmation.md` | `backend-java-api-002` 因 high risk / owner required 进入待确认 |
| `conflicts.md` | 当前为空标题，表示正式目录当前没有 conflict rule |
| `rules-index.json` | 仅索引 2 条 auto-active rules |
| `lineage-ledger.json` | 记录 3 条 rule 的 run、source patterns、source facts、source projects、状态历史 |
| `owner-decision-queue.json` | 1 个 Owner 待裁定项：`backend-java-api-002` |
| `evidence/java-spring/*.md` | 每条 rule 对应的 fact evidence anchor、snippet hash、path hash |

需要注意：当前正式产物来自历史 run，source 文件路径显示为业务项目相对路径，并通过 `path_hash` 与 `snippet_hash` 脱敏锚定，没有暴露 `/Users/...` 绝对路径。

## 13. Agent 与 Workflow 文档如何对应实现

`agents/interface.yaml` 定义的阶段与脚本基本对应：

| interface stage | 文档职责 | 实际脚本 |
| --- | --- | --- |
| `01-intake-and-scope` | validate input、single target、run id、snapshot、fingerprint | `run-profile.mjs` + `input-normalizer.mjs` + `domain-router.mjs` |
| `02-repo-profiler` | detect stack、Git/filesystem evidence mode、batch plan | `run-profile.mjs` |
| `03-fact-collector` | deterministic facts、source anchors、main/test scope | `run-fact-collection.mjs` + `collect-java-layer-facts.mjs` |
| `04-pattern-miner` | group facts、positive/negative evidence、risk/conflict | `run-pattern-mining.mjs` + miners |
| `05-rule-synthesizer` | pattern to rule candidates | `synthesizeRule()` |
| `06-quality-gate` | seven gates、draft/conflict/pending routing | `run-quality-gates.mjs` + gates |
| `07-publisher` | formal outputs、derived AI/review、traceability | `render-standards.mjs` + `rendering.mjs` + `merge-append-only.mjs` |
| `08-owner-review` | Owner decision records future workflow | Phase 0 只产 queue，没有交互裁定实现 |

Workflow 文档现状：

| workflow | 当前状态 |
| --- | --- |
| `full-auto.md` | 与 `run-full-auto.mjs` 对齐，是完整主链路 |
| `profile-first.md` | 文档说明可停在 profile/batch plan；实际可通过 `npm run pse:profile` 达成 |
| `batch-extraction.md` | 文档说明 subset batch；Phase 0 没有独立 batch subset runner |
| `diff-extraction.md` | 明确未来保留，未实现 changed-file-only extraction |
| `owner-review.md` | 明确未来保留，Phase 0 只产 `owner-decision-queue.v1` |

## 14. Contract Schema 解释

9 个合同构成一条从输入到正式治理产物的链：

| schema | 产物 | 关键约束 |
| --- | --- | --- |
| `project-input.v1` | 输入 | 单一 extraction target、至少一个 project path、append-only output |
| `repo-profile.v1` | profile | run id、target、source projects、detected stacks、domain match、batch plan、blind spots |
| `batch-plan.v1` | batch plan | batch id、domain、sub_domain、paths、purpose、risk、status |
| `code-facts.v1` | code facts | fact id、kind、observation、source anchor、git info、scope、occurrence count、confidence |
| `pattern-candidates.v1` | patterns | pattern id、category、source facts、occurrence count、risk、suggested state |
| `standard-rule.v1` | rule candidates | rule id、title、status、rule text、must/must_not、evidence、AI rule、checklist、owner/risk |
| `rule-decision.v1` | gate decisions | decision、7 个 gate results、confidence、autonomy、decision trace、reason、next action |
| `lineage-ledger.v1` | lineage | rule、created run、source patterns/facts/projects、status history |
| `owner-decision-queue.v1` | Owner queue | queue id、rule id、decision required、reason、owner role、options、confidence score、owner gate |

合同总体较严格：大部分对象 `additionalProperties: false`，治理关键字段必填。当前较松的地方包括：

- `code-facts.v1.source_projects` 只是 object array，没有复用 `repo-profile` 的 sourceProject 定义。
- `pattern-candidates.v1` 没有强制 `positive_fact_ids` 和 `negative_fact_ids` 必填，但运行时代码默认它们存在。当前 miner 都会写这两个字段。
- `lineage-ledger.status_history` 的 item 只是 object，没有进一步约束状态字段结构。
- `project-input.v1.constraints` 只是 object，没有细化语义。

## 15. Tests / Evals / Reports 覆盖

### 15.1 tests

测试覆盖点：

| 测试文件 | 覆盖 |
| --- | --- |
| `contracts.test.mjs` | 9 个 schema 自身有效；非 Git facts 缺 snapshot anchor 会被 schema 拒绝 |
| `intake-router.test.mjs` | backend/java profile run、running manifest、混合 domain 拒绝、merge boundary 拒绝跨域目录 |
| `java-facts.test.mjs` | Java facts 产生 controller、layering violation、非 Git anchor |
| `pattern-mining.test.mjs` | mining 产出 conflict-aware patterns 和 rules |
| `quality-gates.test.mjs` | conflict 不 auto-active、泛化规则 rejected、missing evidence rejected、evidence warning draft、abstraction warning draft、risk warning pending、自治发布带 confidence/autonomy |
| `rendering.test.mjs` | full auto 渲染 standard/AI/checklist，standard 含 confidence/autonomy，且不含 `/Users/` |
| `e2e-java-spring.test.mjs` | full auto 完成 manifest，正式目录产出 governance outputs，Owner queue 非空且含 confidence/owner gate |
| `non-git-evidence.test.mjs` | 非 Git 输入不阻断，facts 包含 snapshot anchor |
| `mixed-domain-rejection.test.mjs` | full auto 对混合 backend/frontend input 失败 |
| `scaffolding.test.mjs` | npm scripts、8 个 agent、`.runs/` gitignore、manifest/interface/evals/reports 治理资产 |

### 15.2 evals

`evals/trigger-cases.json` 覆盖：

- should-trigger：从 Java Spring 服务路径萃取规范、验证规范是否从源码派生。
- should-not-trigger：单文件解释、通用最佳实践。
- near-neighbor：PR review。
- boundary：frontend 仍是占位，不应触发。

`evals/output-cases.json` 覆盖：

- Java Spring formal artifacts 生成。
- conflict 进入 Owner queue 和 conflicts。
- 非 Git evidence anchors。
- 混合 backend/frontend 输入拒绝。
- warning gate 不静默 active，自治策略会把低/中风险通过项自动发布，把证据/抽象不足项保留为系统自修复 draft。

这些 eval 是本地 deterministic assertions 和记录型 fixture，不是 provider-backed 模型输出评测。

### 15.3 reports

`reports/trust_report.md` 记录：

- governed boundary。
- input_files。
- file-backed fixture。
- output contract。
- rollback boundary。
- runtime/dependency/permission posture。
- missing evidence。

`reports/output_quality_scorecard.md` 记录：

- output case summary。
- deterministic assertions 由 `npm test` 覆盖。
- provider-backed model eval、blind A/B、human adjudication 仍是 missing evidence。

`reports/output-risk-profile.md` 记录主要输出风险：

- 泛化最佳实践缺 evidence。
- AI rules 与 accepted standards 分叉。
- 本地绝对路径泄漏。
- warning 状态静默 active。
- placeholder domains 被误认为已实现。

## 16. Golden Sample 作用

`evals/golden-samples/java-spring/sample-service` 是一个小型 Java Spring fixture，刻意包含：

- `OrderController`、`AccountController`：Controller 和 mapping annotations。
- `OrderService`：Service 和 Transactional anchors。
- `OrderMapper`：Mapper anchor。
- `GlobalExceptionHandler`：ControllerAdvice / ExceptionHandler anchors。
- `OrderController.directAccess()`：Controller 直接调用 `OrderMapper.findOne()`，用于触发分层冲突路径。

`evals/golden-samples/frontend/package.json` 用于混合 domain 拒绝测试。

golden sample 的目的不是模拟完整企业项目，而是提供 file-backed fixture，让事实抽取、冲突路由、非 Git anchor、正式产物派生可以稳定测试。

## 17. 当前实现与文档声明的差异

这部分是审查结论，不是阻断项：

1. `agents/01-intake-and-scope.md` 声明要检测 sensitive files 和 unreadable paths；代码中有 `scripts/lib/sensitive-files.mjs`，但主链路没有调用它。
2. `domains/backend/collectors.json` 声明多个 collectors；实际多数 collector 文件只是 re-export 同一个 `collectJavaFacts()`。不过这个统一 collector 内部已覆盖 API、transaction、exception、cache、mq-job 注解。
3. `templates/backend/*` 是说明文件；当前 renderer 没有读取模板文件，格式由 `rendering.mjs` 直接生成。
4. `batch-extraction.md`、`diff-extraction.md`、`owner-review.md` 多数是未来能力说明，Phase 0 没有完整 runner。
5. `domain_match` 在成功 profile 中固定为 `confirmed`；没有文件信号时也不会进入 warning，只要 target route 支持且未发现混合/错端。
6. `computeDirectoryContentHash()` 计算内容 hash，但 profile 只保存 file count，没有保存 hash。
7. `standard-java-spring.md` 渲染所有 rules，包括 `pending-confirmation`，而 AI rules、review checklist、rules-index 只渲染 auto-active rules。这个行为与“派生产物只能来自 active rule”一致，但“standard 文档是否应只包含 active rule”需要产品上明确。
8. Markdown append-only merge 可能因 run id 或时间戳差异重复追加相似内容；JSON merge 相对更稳定。
9. `lineage-ledger.status_history.time` 使用当前时间，导致相同输入多次运行时 lineage JSON 不完全确定。
10. `generate-review-summary.mjs` 只是输出一句说明，没有独立 review summary 生成逻辑。

## 18. 风险与后续优化建议

优先级较高：

1. 明确 `standard-java-spring.md` 是否应该包含 pending/conflict/draft/rejected 规则；如果标准文档只应代表 active 标准，需要调整 renderer。
2. 把 sensitive file detection 接入 `run-profile`，并把 unreadable path / sensitive path 写入 `blind_spots` 或 profile warning。
3. 改进 markdown merge，按 frontmatter/run/rule section 做结构化合并，避免 run id 变化导致重复追加。
4. 将 `code-facts.v1.source_projects`、`lineage-ledger.status_history`、`pattern-candidates` 的 optional runtime assumptions 收紧到 schema。
5. 为 `output.base_dir` 给出明确语义：要么移除重定向能力，要么在不破坏 domain boundary 的前提下支持配置。

中期建议：

1. 拆分当前统一 Java collector，把 transaction、cache、mq-job、exception collector 从 re-export 升级为独立模块，或在 docs 中明确它们是同一 scanner 的别名。
2. 增加 `diff-extraction` 和 `batch-extraction` 的真实 runner，避免 workflow 文档长期超过实现。
3. 引入 AST 或结构化解析前，继续保留当前 rg/file scanner 作为 deterministic fallback。
4. 为 Owner review 增加裁定记录 schema，并定义 `owner-confirmed-active` 如何回写 lineage、rules-index、AI rules。
5. 增加 provider-backed output eval 和 blind A/B review pack，补齐 reports 中列出的 missing evidence。

## 19. 总结

`project-standard-extractor` 当前已经是一个可运行的 production skill baseline：它有明确的触发边界、单端路由、版本化合同、确定性 fact collection、pattern mining、七道质量门禁、自治决策策略、正式产物渲染、append-only merge、golden sample 和测试覆盖。

它当前最可靠的能力是 `backend/java-spring` 的全链路萃取：输入项目路径后，产出 `.runs/{run_id}` 中间证据和 `engineering-standards/04-backend` 正式规范资产。它当前最需要继续加固的点，不是入口描述，而是实现与声明之间的细节一致性：sensitive file detection、模板使用语义、workflow future stubs、markdown merge 去重、schema 严格度和 Owner review 闭环。

## 20. 审查证据清单

本次直接读取并用于分析的关键文件包括：

- `skills/project-standard-extractor/SKILL.md`
- `skills/project-standard-extractor/README.md`
- `skills/project-standard-extractor/manifest.json`
- `skills/project-standard-extractor/agents/interface.yaml`
- `skills/project-standard-extractor/agents/01-intake-and-scope.md` 到 `08-owner-review.md`
- `skills/project-standard-extractor/workflows/full-auto.md`
- `skills/project-standard-extractor/workflows/profile-first.md`
- `skills/project-standard-extractor/workflows/batch-extraction.md`
- `skills/project-standard-extractor/workflows/diff-extraction.md`
- `skills/project-standard-extractor/workflows/owner-review.md`
- `skills/project-standard-extractor/contracts/*.schema.json`
- `skills/project-standard-extractor/scripts/run-full-auto.mjs`
- `skills/project-standard-extractor/scripts/run-profile.mjs`
- `skills/project-standard-extractor/scripts/run-fact-collection.mjs`
- `skills/project-standard-extractor/scripts/run-pattern-mining.mjs`
- `skills/project-standard-extractor/scripts/run-quality-gates.mjs`
- `skills/project-standard-extractor/scripts/lib/autonomy-policy.mjs`
- `skills/project-standard-extractor/scripts/render-standards.mjs`
- `skills/project-standard-extractor/scripts/merge-append-only.mjs`
- `skills/project-standard-extractor/scripts/validate-contracts.mjs`
- `skills/project-standard-extractor/scripts/lib/*.mjs`
- `skills/project-standard-extractor/scripts/lib/gates/*.mjs`
- `skills/project-standard-extractor/collectors/common/*.mjs`
- `skills/project-standard-extractor/collectors/backend/*.mjs`
- `skills/project-standard-extractor/miners/*.mjs`
- `skills/project-standard-extractor/templates/backend/*`
- `skills/project-standard-extractor/tests/*.mjs`
- `skills/project-standard-extractor/evals/trigger-cases.json`
- `skills/project-standard-extractor/evals/output-cases.json`
- `skills/project-standard-extractor/evals/golden-samples/java-spring/*`
- `skills/project-standard-extractor/evals/golden-samples/frontend/package.json`
- `skills/project-standard-extractor/reports/*.md`
- `engineering-standards/04-backend/*`
- `.runs/20260604-020908-backend-java-spring-e76b1da/*`
