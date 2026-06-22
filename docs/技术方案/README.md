# project-standard-extractor 设计基线

> 本文件是 `docs/技术方案/` 下三份方案合并后的**设计基线**,所有关键边界已逐项决策并锁定。
> 后续 `/spec:brainstorm` / `/spec:plan` / 实现,均以本基线为唯一权威输入。

---

## 0. 三份方案的关系

本目录三份文档不是平行方案,而是同一个系统的三个切面:

| 文档 | 切面 | 回答的问题 |
| --- | --- | --- |
| `代码规范skill方案.md`(V2 设计稿) | **WHAT / HOW** | 架构、9 个数据合同、规则生命周期、质量门禁、产物形态 |
| `依赖增强方案.md` | **WITH WHAT** | 每一层用什么技术实现、分几个 Phase 引入、怎么依赖隔离 |
| `单端抽取方案.md` | **运行模型修正** | 不是「一次跑全端」,而是「按端运行、端内抽取、跨端二次提炼」 |

阅读顺序:先 V2 设计稿建立全貌,再用依赖方案落实技术栈,最后用单端方案修正运行模型。

---

## 1. 核心定位

> **project-standard-extractor 是 domain-scoped extractor,不是 all-in-one generator。**
> 按端运行、端内抽取、端内合并、跨端二次提炼。

不可动摇的两条红线:

- **LLM 不能立法**:LLM 只能基于脚本抽好的结构化代码事实归纳规范候选,不得伪造 evidence、不得判定调用关系、不得绕过质量门禁、不得自动激活高风险规则。
- **CodeWiki 不进 facts 层**:CodeGraph/AST 是 deterministic(可作 evidence),CodeWiki/README 只是 advisory(必须回源代码验证)。

---

## 2. 已锁定的设计决策

| # | 决策点 | 结论 |
| --- | --- | --- |
| 1 | 运行模型 | **骨架支持三端,运行严格单端**。一套共享骨架,每次 run 只绑定一个 `extraction_target{domain, sub_domain}`;输入含多端必须拆 run |
| 2 | 主体语言 | **Node.js 单语言**。核心依赖 `Node + Git + rg + ajv + ajv-formats + fast-glob + gray-matter + yaml`,本轮不引入 Python |
| 3 | 实现形态 | **混合**:`.mjs`+rg 抽确定性事实 / LLM agent 归纳规则 / ajv 硬校验(Evidence、Derivation、GIT-001)+ LLM 软判定(Abstraction、Actionability) |
| 4 | run 隔离 | **集中 `.runs/{run_id}/`**(中间产物)与 `engineering-standards/`(正式产物)物理分离 |
| 5 | adapters | `tools/adapters/{codewiki,codegraph,pr-review}/` **只预留空目录 + README 占位**,本轮不实现 |
| 6 | 本轮交付 | **Phase 0 共享骨架 + `backend/java-spring` 单端跑通闭环** |
| 7 | 产物命名 | **统一带 `sub_domain` 后缀**,避免同 domain 下多 sub_domain 互相覆盖 |
| 8 | Git 依赖 | **降级为可选**,非 git 项目用 `snapshot_id + path_hash + file + line + snippet_hash` 锚定 evidence |

---

## 3. run_id 与产物落盘约定

### 3.1 run_id 格式

```text
{yyyyMMdd-HHmmss}-{domain}-{sub_domain}-{short_input_hash}
例:20260604-143012-backend-java-spring-a13f9c2
```

- `timestamp` — 排序与追踪
- `domain/sub_domain` — 人肉识别(本身就内嵌「单端」语义)
- `short_input_hash` — `input_fingerprint` 前 7 位,同秒防撞 + 判断输入是否相同

### 3.2 目录布局

```text
.runs/{run_id}/                       # 中间产物,可整体 gitignore
├── manifest.json                     # 完整 fingerprint + 元数据 + status
├── repo-profile.v1.json
├── code-facts.v1.json
├── pattern-candidates.v1.json
├── standard-rule.v1.json
├── rule-decision.v1.json
└── review-report.md

engineering-standards/{domain}/       # 正式产物,append-only
├── standard-{sub_domain}.md
├── ai-rules-{sub_domain}.md
├── review-checklist-{sub_domain}.md
├── rules-index.json
├── lineage-ledger.json
├── pending-confirmation.md
├── conflicts.md
├── owner-decision-queue.json
└── evidence/{sub_domain}/
```

### 3.3 manifest.json

```json
{
  "run_id": "20260604-143012-backend-java-spring-a13f9c2",
  "tool": "project-standard-extractor",
  "domain": "backend",
  "sub_domain": "java-spring",
  "created_at": "2026-06-04T14:30:12+08:00",
  "input_fingerprint": "sha256:...",
  "source_projects": [
    { "path_hash": "sha256:...", "repo_name": "...", "source_type": "filesystem", "git_commit": null }
  ],
  "output_base_dir": "engineering-standards/04-backend",
  "status": "running"
}
```

- `input_fingerprint` = `sha256(规范化后的 project_paths + target_domains + git_commit 列表)`,同输入同指纹,可跳过重复 run
- `created_at` 使用本机时区的 ISO8601(不硬编码时区)
- `status` 枚举:`running` / `completed` / `failed` / `aborted`(写入即 `running`,收尾改 `completed`)

---

## 4. 源码锚定分级(Git 可选)

> 规范抽取的前提是「可读源码 + 可追溯 evidence」,不是必须 Git;Git 只是最强 evidence 锚点。

| 场景 | 允许抽取 | evidence 锚定 | 最高状态 |
| --- | :---: | --- | --- |
| Git 仓库 | ✅ | repo + commit + file + line + snippet_hash(强) | 可升 team / department |
| 非 Git 目录 | ✅ | snapshot_id + path_hash + file + line + snippet_hash(中) | **最高 this-repo auto-active** |
| 临时 / 聚合 checkout | ✅ | snapshot_id + file + line + snippet_hash(中) | 同上 |
| 无法读取源码 | ❌ | 无 evidence | 不生成规则 |

`snapshot_id` 格式:`snapshot-{yyyyMMdd-HHmmss}-{short_input_hash}`,intake 阶段对源码目录做一次内容指纹后生成,facts 引用它。

---

## 5. 系统架构(三份方案合并 · 修正版)

```text
extraction_target{domain, sub_domain}        每次 run 绑定唯一一个
        │
        ▼
   domain-router            选 collectors/miners/template/output_dir + 风险策略
        │
        ▼
   domain profiler  ─→  batch planner          只识别 / 只拆当前端
        │
        ▼
   domain collectors (.mjs + rg)               只跑当前端,抽锚点级 facts
        │
        ▼
   domain pattern miner  ─→  rule synthesis     只生成当前端规则
        │
        ▼
   quality gate × 7(含 GIT-001)
        │
        ▼
   merge-coordinator(append-only + 跨端硬边界校验)
        │
        ▼
   engineering-standards/{domain}/standard-{sub_domain}.md ...
```

---

## 6. 目录骨架

```text
仓库根/
├── package.json                          # type:module + P0 依赖 + pse:* scripts
│
├── skills/project-standard-extractor/
│   ├── SKILL.md                          # 薄入口
│   ├── workflows/                        # domain-scoped full-auto / profile-first / owner-review ...
│   ├── agents/                           # 01-intake ... 08-owner-review
│   ├── domain-router.md                  # 端域路由
│   ├── merge-coordinator.md              # append-only 合并 + 硬边界
│   ├── contracts/*.schema.json           # 9 个数据合同(ajv 校验)
│   ├── domains/{domain}/                 # 按端声明
│   │   ├── {sub_domain}.md
│   │   ├── collectors.json               # 声明:用哪些 collector/miner、output_dir
│   │   └── rule-taxonomy.md
│   ├── collectors/{domain}/*.mjs         # 按端实现:rg 锚点抽取
│   ├── miners/*.mjs
│   ├── quality-gates/                    # 7 道 gate
│   ├── templates/{domain}/               # standard / ai-rules / checklist / evidence 模板
│   ├── evals/                            # golden-samples / regression
│   └── scripts/                          # run-profile / run-facts / run-mining /
│                                         # validate-contracts / render-standards / merge-append-only
│
├── tools/adapters/                       # 全部可选,本轮只占位
│   ├── codewiki/README.md                # advisory,不进 facts 层
│   ├── codegraph/README.md               # deterministic,可进 facts 层
│   └── pr-review/README.md               # 团队隐性规范来源
│
├── .runs/{run_id}/                       # 中间产物(gitignore)
│
└── engineering-standards/                # 正式产物
    ├── 01-app-client/  03-frontend/  04-backend/  ...
    └── 00-global/                        # 跨端二次提炼(仅从已确认端内规范)
```

**共享一次**:`SKILL.md` / `workflows/` / `agents/` / `domain-router` / `merge-coordinator` / `contracts/` × 9 / `quality-gates/` × 7 / `scripts/`
**按端分化**:`domains/{domain}/collectors.json`(声明)+ `collectors/{domain}/*.mjs`(实现)+ `templates/{domain}/`

---

## 7. 9 个数据合同(版本化 · ajv 校验)

| 合同 | 关键字段(本基线新增/修正以 **粗体** 标) |
| --- | --- |
| `project-input.v1` | **extraction_target{domain, sub_domain}**、project_paths、**scope{include, exclude}**、**output{base_dir, mode: append-only}**、constraints |
| `repo-profile.v1` | extraction_target、**repo{source_type, is_git_repo, git_commit?, path_hash, snapshot_id}**、detected_stacks、**domain_match**、**domain_mismatch_warnings**、module_candidates、batch_plan、blind_spots |
| `batch-plan.v1` | batch_id、domain、sub_domain、paths、purpose、risk_level、status |
| `code-facts.v1` | fact_id、kind、observation、**source_anchor{source_type, snapshot_id, file, line_range, snippet_hash}**、**git{available, commit}**、positive/negative_examples、deterministic_occurrence_count、role/module_diversity、confidence |
| `pattern-candidates.v1` | pattern_id、category、source_fact_ids、occurrence_count、module/role_diversity、negative_examples、risk_level、suggested_rule_level、suggested_state |
| `standard-rule.v1` | rule_id、domain、sub_domain、level、status、rule_text、must/must_not、positive/negative_evidence、ai_coding_rule、review_checklist、authority_scope、owner_required、source_projects |
| `rule-decision.v1` | rule_id、decision、gate_results(7 道)、reason、next_action |
| `lineage-ledger.v1` | rule_id、created_by_run、source_patterns/facts/projects、status_history |
| `owner-decision-queue.v1` | queue_id、rule_id、decision_required、reason、suggested_owner_role、options |

---

## 8. 7 道质量门禁

| Gate | 判定方式 | 作用 |
| --- | --- | --- |
| Evidence Gate | **ajv 硬校验** | 至少 1 条源码 evidence;auto-active 需 ≥2 条 deterministic;不能只引 advisory |
| Actionability Gate | LLM 软判定 | 必须有明确 Must / Must Not,可被 AI 执行、被 Reviewer 检查 |
| Abstraction Gate | LLM 软判定 | 不能太具体(绑定单个方法名)也不能太空(「代码要优雅」) |
| Conflict Gate | ajv + LLM | 正反例并存 → 写 conflicts.md,不得 auto-active,生成 owner-decision-queue |
| Risk Gate | 规则表 + LLM | 交易/资金/清结算/权限/认证/隐私/安全/合规/发布/风控 → 必须 Owner 确认 |
| Derivation Gate | **ajv 硬校验** | ai-rules / review-checklist 只能从 accepted standard 派生 |
| **GIT-001 Gate** | **ajv 硬校验** | 缺 Git 不阻断;非 git evidence 必须含 snapshot_id+path_hash+file+line_range+snippet_hash;非 git 项目默认最高到 draft / this-repo auto-active |

---

## 9. 规则生命周期

```text
升级:candidate → draft → auto-active → team-candidate → owner-confirmed-active → department-active
降级:auto-active → stale-auto-active → pending-confirmation → owner-rejected
       draft → conflict → owner-rejected
旁路:conflict(正反并存)  legacy-compatible(历史兼容,AI 不新增但 Review 不阻断)
```

auto-active 硬门槛:`occurrence_count ≥ 2` + `confidence high` + 无冲突 + 低/中风险。任一不满足即降级。

---

## 10. 本轮交付边界(Phase 0 + Java 单端闭环)

**Phase 0 — 共享骨架冻结**:`package.json`、`SKILL.md`、`workflows/`、`agents/01-08`、`domain-router`、`merge-coordinator`、`contracts/` × 9(ajv 可校验)、`quality-gates/` × 7、`scripts/`、`templates/backend/`、`tools/adapters/*/README.md` 占位。

**Java 单端闭环** — 验证整链路:

```yaml
extraction_target: { domain: backend, sub_domain: java-spring }
project_paths: [ "/Users/kuang/ops/code/9627_KAZ展业项目-MVP版本-CRM需求_中台开发" ]
```

- 验证项目:Maven 多模块 Java 中台,**非 git**,3683 个 Java 文件,8 个模块
- Spring 锚点充足:`@RestController`×46 `@Service`×285 `@Repository`×37 `@Mapper`×109 `@Transactional`×105 `@RestControllerAdvice`×2
- 产物落 `engineering-standards/04-backend/`

**验收标准**:

```text
✓ ajv 校验全绿(9 合同 + 7 gate 不变量)
✓ ai-rules-java-spring.md 不含无 evidence 规则
✓ review-checklist-java-spring.md 只从 standard 派生
✓ 输出仅落 04-backend/,不污染其他端目录
✗ 出现无 evidence active 规则 → 阻断
✗ advisory-only 规则进 ai-rules → 阻断
✗ 高风险规则自动 active → 阻断
```

前端 / APP 的 `domains/` 配置与 collector **本轮不实现**,复用同一骨架,留各自的 run。

---

## 11. 分阶段路线(依赖与能力)

| Phase | 依赖 | 抽取能力 |
| --- | --- | --- |
| **P0 最小闭环** | Node + Git + rg + ajv + fast-glob + gray-matter + yaml | rg + 注解/命名锚点级事实 |
| P1 多端增强 | + typescript / ts-morph / @babel/parser / vue-eslint-parser / fast-xml-parser | 前端 / APP 端 collector |
| P2 AST/图谱 | tree-sitter 全家桶 / CodeGraph / LSP(放 adapter) | 调用关系级事实 |
| P3 外部知识 | CodeWiki / GitHub·GitLab API / OpenDeepWiki / MCP | advisory 信号 + PR Review 隐性规范 |

**本轮只做 P0。** 不引入向量库、图数据库、Web 平台、多 Agent 编排框架。
