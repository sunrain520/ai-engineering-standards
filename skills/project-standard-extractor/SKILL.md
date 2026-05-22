---
name: project-standard-extractor
description: 从一个或多个真实项目代码路径中全自动萃取团队级研发规范，输出规范文档、AI Coding Rules、Review Checklist 和 evidence。适用于部门级 engineering-standards 仓库。
---

# Project Standard Extractor

## Purpose / 目的

本 Skill 是编排器入口。用户提供项目路径后，Skill 自动调用 6 个内部 agent 完成全流程萃取，最终输出一批 `draft` 状态的规范文档供用户审查。**用户只需在最后审查文档并决定哪些内容升级为 active。**

## When To Use / 何时使用

- 需要从真实代码中沉淀 APP、PC、前端、后端或行业规范。
- 需要生成 AI Coding Rules、Review Checklist、正反例和 evidence。
- 需要把多项目实践整理为团队级标准。

## When Not To Use / 何时不要使用

- 只想解释某个项目代码。
- 只想生成行业通用最佳实践，且没有团队代码或负责人确认。
- 需要修改业务代码。

---

## Inputs / 输入

**最小输入**：一个或多个 `project_paths`，其余全部自动推断。

```yaml
project_paths:
  - /path/to/project1
  - /path/to/project2          # 可选，多项目
domain: ""                     # 可选，留空则自动推断
output_dir: ""                 # 可选，默认 engineering-standards/{domain}/
run_mode: auto                 # auto（默认）| interactive（逐步确认）
```

`run_mode: auto`（默认）：Skill 自动推断所有参数，自动执行全部 batch，无中途停顿，最后输出 review summary 供用户审查。

`run_mode: interactive`：保留原有逐步确认行为，适合首次探索或高风险场景。

---

## Workflow / 自动编排流程

Skill 按以下顺序调用内部 agent，自动执行全流程：

```
用户输入 project_paths
    │
    ▼
【Agent 1】intake-and-scope
    · 推断 domain、sub_domain、extraction_mode
    · 识别敏感文件，建立排除清单
    · auto 模式：只在硬性阻断（路径不可读、所有路径均敏感）时停止
    · 输出: scope_summary + run_id
    │
    ▼
【Agent 2】profile-and-batch-planner
    · 轻量目录扫描（≤30 文件，≤3 层）
    · 按 sub_domain 生成 extraction-map 和 batch-plan
    · auto 模式：按优先级自动排序所有 ready batch
    · 输出: project-profile.md / extraction-map.md / batch-plan.md
            + ordered_batch_queue（所有 ready batch，按优先级排列）
    │
    ▼  ┌──────────────────────────────────────────────────────────┐
    │  │  FOR EACH batch IN ordered_batch_queue (顺序执行)        │
    │  │                                                          │
    │  │  【Agent 3】facts-and-classification                     │
    │  │      · 读取 batch 候选文件（evidence_limit: 25）         │
    │  │      · 萃取事实 → 分类（recommended/forbidden/pending）  │
    │  │                                                          │
    │  │  【Agent 4】generation                                   │
    │  │      · Sub-step A: 写 evidence/*                        │
    │  │      · Sub-step B: 综合编写 Developer Guide              │
    │  │        standard-{sub_domain}.md（新建或补充已有章节）    │
    │  │      · Sub-step C: 派生 ai-rules.md / review-checklist  │
    │  │      · Sub-step D: 生成候选索引产物                     │
    │  │                                                          │
    │  │  【Agent 5】review-and-quality-gate                     │
    │  │      · 7 persona 评审（Evidence/Team/AI/Review/         │
    │  │        Conflict/Industry/Governance）                    │
    │  │      · 输出 quality_gate_decisions                      │
    │  │                                                          │
    │  │  【Agent 6】merge-coordinator                           │
    │  │      · append-only 写入规范目录                         │
    │  │      · 冲突 → conflicts.md                              │
    │  │      · 待确认 → pending-confirmation.md                 │
    │  │                                                          │
    │  │  → 记录该 batch 完成状态到 run_log                      │
    │  └──────────────────────────────────────────────────────────┘
    │  （循环结束）
    │
    ▼
【最终步骤】生成 {run_id}-review-summary.md
    · 本次运行所有 batch 的完成状态
    · 所有新增/更新的规范文件清单
    · 需要用户审查的标记项（FORBIDDEN / draft / conflict / pending）
    · 负责人确认项清单
    │
    ▼
用户审查 draft 文档，手动将认可内容的 status 改为 active
```

**完整说明见 `workflow.md`。Agent 契约见 `agents/`。输出模板见 `templates/`。**

---

## 强制边界

1. 规则正文不得包含具体项目路径；路径只能进入 `evidence/`。
2. 没有真实 evidence 的内容不得进入 AI 可执行 `draft`；无 evidence → `pending-confirmation.md`。
3. 不得覆盖已有 `active`，不得覆盖已有 `draft`（只追加）。
4. FORBIDDEN 标注必须有直接负例代码 evidence。
5. 敏感配置、密钥、token、生产凭据只记录脱敏存在事实。
6. **auto 模式直接输出 `active`**，用户审查后删除或修改不认可的内容即可；interactive 模式输出 `draft`，由用户手动升级。
7. 所有输出 Markdown 顶部必须包含 `config/frontmatter-format.md` 定义的 YAML Front Matter。
8. evidence 按 `sub_domain` 拆分；跨 sub_domain 共性使用 `sub_domain: common`。
9. 广范围输入必须先走 profile-first（Agent 2），不得直接读完整源码生成规范。
10. 每次循环只处理一个 batch，Agent 3-6 的读取范围严格限定在该 batch 的 `candidate_files`。
11. 候选索引产物（rules-index / llms / ai-context-pack）永远标记 `candidate`，不自动发布。

---

## Outputs / 输出

每次运行最终产出（写入 `output_dir`）：

**规范文档（用户审查目标）**
- `standard-{sub_domain}.md` — 每个 sub_domain 一份 Developer Guide
- `standard-common.md` — 跨 sub_domain 共性规范（如有）
- `ai-rules.md` — AI 编码规则汇总视图
- `review-checklist.md` — Review 检查项汇总视图

**证据文件**
- `evidence/code-facts.md`
- `evidence/positive-examples.md`
- `evidence/forbidden-examples.md`
- `evidence/legacy-compatible.md`

**待处理文件**
- `pending-confirmation.md` — 需负责人确认的候选规则
- `conflicts.md` — 与已有规则冲突的候选
- `merge-suggestions.md` — 相似规则合并建议

**运行时 handoff（indexable: false）**
- `{run_id}-project-profile.md`
- `{run_id}-extraction-map.md`
- `{run_id}-batch-plan.md`
- `{run_id}-review-summary.md` ← **用户审查入口**

**候选索引产物（需人工发布）**
- `{run_id}-rules-index-candidate.json`
- `{run_id}-llms-candidate.txt`
- `{run_id}-ai-context-pack.md`

---

## Failure Modes / 失败模式

| 失败模式 | 触发条件 | 处理方式 |
| --- | --- | --- |
| `NO_VALID_PROJECT_PATHS` | 所有路径不可读 | **停止整个运行**，请用户重新提供路径 |
| `ALL_PATHS_SENSITIVE` | 所有路径均命中敏感文件策略 | **停止整个运行**，说明原因 |
| `NO_READY_BATCHES` | batch-plan 中所有 batch 状态为 pending/skipped/blocked | 输出 profile + batch-plan，说明需要用户补充 evidence 或确认后再运行 |
| `BATCH_INSUFFICIENT_EVIDENCE` | 某个 batch 没有代表性 evidence | 跳过该 batch，记录到 review-summary，继续下一个 batch |
| `BATCH_ALL_SENSITIVE` | 某个 batch 所有候选文件均为敏感文件 | 跳过该 batch，记录原因，继续下一个 batch |
| `TARGET_CONFLICT` | 新规则与已有 `active` 冲突 | 写入 `conflicts.md`，不覆盖，继续执行 |
| `GENERATION_FAILED` | generation agent 产出为空 | 记录到 review-summary，继续下一个 batch |

**auto 模式原则：单个 batch 失败不中止整个运行，记录失败原因并跳过，继续处理剩余 batch。**

---

## 最小验收

一次有效运行（auto 模式）必须证明：

1. 所有 ready batch 都被尝试执行（跳过的有记录）。
2. 每份 standard-{sub_domain}.md 包含：技术栈、分层图、≥1 个角色规范节、AI 规则、Review 检查项。
3. 所有规则都能追溯到 evidence（无 evidence → pending-confirmation）。
4. 所有输出状态为 `draft`（没有 `active`）。
5. `{run_id}-review-summary.md` 已生成，包含完整变更清单和待确认项。
6. 敏感文件没有被读取或复制原值。
