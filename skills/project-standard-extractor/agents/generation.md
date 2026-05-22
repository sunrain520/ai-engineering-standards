# Generation Contract

## 角色目标

基于 `code_facts` 和 `classification` 生成**开发者可直接使用的团队规范指南**，以及派生的 AI Coding Rules、Review Checklist 和候选索引产物。

核心转变：**不是填写规则条目表格，而是综合编写开发指南**。产出文档必须像有经验的架构师写的工作手册，开发者打开就能看懂、能用。工序仍然严格：evidence 先行 → 综合编写 standard 指南 → 派生 ai-rules / review-checklist → 索引聚合。

> 上游：`facts-and-classification`（code_facts + classification）。下游：`review-and-quality-gate`。

## 输入

```yaml
inputs:
  code_facts:             # facts-and-classification 的全量输出
  classification:         # recommended / forbidden / legacy_compatible / pending_confirmation / conflict
  selected_batch_summary: # batch_id / domain / sub_domain / evidence_limit
  project_profile:        # {run_id}-project-profile.md（用于理解架构背景）
  global_templates:       # templates/ 目录（standard-template.md 是主要参考）
  frontmatter_format:     # config/frontmatter-format.md
  output_targets:         # config/output-targets.md
  existing_standards:     # 若 standard-{sub_domain}.md 已存在，列出已有章节标题列表
```

## 输出（完整产物清单）

| 产物 | doc_type | indexable | 生成时机 |
| --- | --- | --- | --- |
| `evidence/code-facts.md` | evidence-code-facts | true | Sub-step A |
| `evidence/positive-examples.md` | evidence-positive | true | Sub-step A |
| `evidence/forbidden-examples.md` | evidence-forbidden | true | Sub-step A |
| `evidence/legacy-compatible.md` | evidence-legacy | true | Sub-step A |
| `standard-{sub_domain}.md` | standard | true | Sub-step B（每 sub_domain 一份 Developer Guide） |
| `pending-confirmation.md` | pending-confirmation | false | Sub-step B |
| `ai-rules.md` | ai-rules | true | Sub-step C |
| `review-checklist.md` | review-checklist | true | Sub-step C |
| `{run_id}-rules-index-candidate.json` | — | — | Sub-step D |
| `{run_id}-llms-candidate.txt` | — | — | Sub-step D |
| `{run_id}-ai-context-pack.md` | ai-context-pack | false | Sub-step D |

## 生成管线（严格工序）

```
Sub-step A: Evidence Writer
  └── 写 evidence/*，固定 EV/POS/NEG/LEG 编号
  └── 完成标志: code_facts 全部编号完毕

Sub-step B: Developer Guide Author（核心）
  └── 综合读取所有 code_facts + 项目画像，理解 sub_domain 架构
  └── 按 standard-template.md 结构综合编写开发指南
  └── 完成标志: 每个主要章节有实质内容；Evidence 参考表格已填写

Sub-step C: Derivative Generator（可并行）
  ├── ai-rules.md    ← 从 standard-{sub_domain}.md §"AI 生成代码规则" 提取
  └── review-checklist.md ← 从 standard-{sub_domain}.md §"Code Review 检查项" 提取
  └── 完成标志: 每条条目引用了来源章节

Sub-step D: Index & Pack Aggregator（B + C 完成后）
  ├── rules-index-candidate.json  ← 按章节索引 standard 内容
  ├── llms-candidate.txt          ← 领域入口地图
  └── ai-context-pack.md          ← 摘要包
```

**工序约束**：Sub-step B 不得在 evidence 编号未锁定前开始。Sub-step D 不得在 B + C 完成前执行。

---

## 执行步骤

### Sub-step A — Evidence Writer（不变）

**A1.** 对每个 evidence 文件写入 YAML Front Matter（`doc_id`、`domain`、`sub_domain`、`doc_type`、`indexable: true`、`tags`）。

**A2.** 编号分配：

```
EV-{DOMAIN}-{N}   → evidence/code-facts.md
POS-{DOMAIN}-{N}  → evidence/positive-examples.md
NEG-{DOMAIN}-{N}  → evidence/forbidden-examples.md
LEG-{DOMAIN}-{N}  → evidence/legacy-compatible.md
```

`{N}` 单调递增，不复用。若文件已存在条目，从最大 N+1 追加。

**A3.** 写入原则：

- code-facts：每条 fact（`observed_pattern`、`boundary`、`confidence`、`file_role`）
- positive-examples：正向 evidence，附路径模式（不写绝对路径）和解释
- forbidden-examples：反向 evidence，附反例模式和风险说明
- legacy-compatible：历史兼容 evidence，附兼容边界说明

---

### Sub-step B — Developer Guide Author（核心，全面重写）

**B0. 编写前：综合理解阶段（全领域通用）**

不要立刻开始写规则条目。先用内部推导回答以下 3 个问题：

1. **这个 sub_domain 的核心架构是什么？** 有哪些层级、角色、关键模式？（从 code_facts 的 `file_role` 和 `observed_pattern` 推断；同时查阅 `config/domain-sampling-adapters.md` 里对应 domain 的信号集和代表性候选描述）
2. **代码事实揭示了哪些真实规律？** 哪些是团队共同遵循的正向模式？哪些是被避开的反模式？
3. **开发者最需要知道什么？** 如果一个新同事第一天接手这个 sub_domain，哪些知识最关键？

**各领域架构推导参考**（从 code_facts file_role 对应关系推断分层）：

| domain | sub_domain 典型 | 推断分层关键词 | 代码示例语言 |
| --- | --- | --- | --- |
| app-client | android | `fragment`, `viewmodel`, `usecase`, `repository`, `dto` | Kotlin |
| app-client | ios | `viewcontroller`, `reactor`, `action`, `mutation`, `state` | Swift |
| app-client | kmp-shared | `usecase`, `repository`, `presenter`, `mapper`, `domain-model` | Kotlin |
| frontend | react/vue/next | `page`, `component`, `store`, `api-client`, `hook`, `type` | TypeScript |
| backend | java-spring | `controller`, `service`, `repository`, `mapper`, `dto` | Java/Kotlin |
| backend | golang | `handler`, `service`, `repository`, `model`, `middleware` | Go |
| backend | python | `view/router`, `service`, `repository`, `schema`, `model` | Python |
| pc-client | electron | `main-process`, `ipc-handler`, `renderer`, `preload` | TypeScript |
| testing | unit/integration | `test-class`, `mock`, `fixture`, `assert` | 随 domain |
| security | — | `validator`, `auth-middleware`, `permission`, `audit-log` | 随 domain |
| industry | — | `workflow`, `risk-check`, `state-transition`, `compliance` | 随 domain |

只有回答清楚这 3 个问题后，才开始写文档。

**B1. 文档路由**

`batch.sub_domain` → 写入 `standard-{sub_domain}.md`。跨 sub_domain 共性内容 → `standard-common.md`（`sub_domain: common`）。文件不存在时新建并写入 Front Matter：

```yaml
doc_id: "{domain}-{sub_domain}-standard"
doc_type: standard
status: active   # auto 模式直接输出 active；用户审查后删除不认可的内容即可
evidence_tier: "{从 code_facts 中最高的 tier}"
source_batch: "{batch_id}"
```

**B2. 文档结构（按 standard-template.md）**

按以下章节顺序综合编写，每节都必须有实质内容（不留空节）：

**§1 技术栈与工程约束**

- 从 build 脚本 evidence（EV-* 中 file_role=gradle-module-config 等）和 import 语句提取
- 列出框架、库、工具名称 + 一行说明用途
- 只写团队真实在用的，不写"推荐"的行业通用方案

**§2 分层职责**

- 从 code_facts 的 `file_role` 分布（controller、viewmodel、usecase、repository 等）推断层级
- 画 ASCII 依赖关系图（上层 → 下层）
- 写责任矩阵表格（层级 | 核心职责 | 禁止事项）

**§3—§N 各层级/角色规范**（数量由 evidence 决定，每层一节）

每节写：

- **强制规则**（numbered list）：对应 classification.recommended，confidence: high + occurrences ≥ 2
- **推荐规则**（numbered list）：confidence: medium 或 occurrences = 1 的正向 evidence
- **禁止事项**（bullet list）：对应 classification.forbidden；有直接负例的用 `⛔ FORBIDDEN` 标注
- **正例代码**（fenced code block）：从 POS-* evidence 提取，路径脱敏，注释说明正确原因
- **反例代码**（fenced code block）：从 NEG-* evidence 提取，路径脱敏，注释说明错误原因和改法

**FORBIDDEN 标注格式**（内联在禁止事项节内）：

```markdown
> ⛔ **FORBIDDEN**：{具体禁止写法，一句话}。负例见 `evidence/forbidden-examples.md「NEG-{DOMAIN}-{N}」`
```

**§"目录与命名规范"**（如果 evidence 中有命名模式，写此节；否则删除）

**§"AI 生成代码规则"**

综合所有 evidence 写 AI 约束，分三段：
1. 生成前必须判断（列出 sub_domain 特有的判断点）
2. 必须遵守（正向约束，对应§3-N 强制规则）
3. 禁止生成（负向约束，对应§3-N 禁止事项）

**§"Code Review 检查项"**

按维度分组（架构合规 / 各层级合规 / AI 生成专项），每条必须可 pass/fail 判断。reviewer 看代码就能得出结论。

**§"Evidence 参考"**（文档末尾）

简化表格，列出本文档主要规则依据的 evidence 编号：

```markdown
| evidence_id | 来源文件（路径模式） | 核心观察 | 置信度 |
| --- | --- | --- | --- |
```

**B3. 写作质量标准**

| 质量维度 | 要求 |
| --- | --- |
| 可读性 | 开发者打开 3 分钟内能理解该 sub_domain 的架构 |
| 可操作性 | 每条规则说明**怎么做**，而不只是"应该" |
| 代码示例 | 至少有 1 个正例 + 1 个反例，直接来自 evidence |
| 密度 | 信息密度高，不写废话，不重复 evidence 文件内容 |
| 架构视角 | §2 分层图能让新人快速定位自己在哪里、能做什么 |

**B4. Pending Confirmation 落点**

以下内容不写进 `standard-{sub_domain}.md`，写进 `pending-confirmation.md`：

- classification.pending_confirmation 的所有内容
- confidence: low 的 fact
- 没有代码 evidence 的规则推断（只有 README/文档来源，无代码验证）
- 需要负责人确认的行业规则

```yaml
PENDING-{DOMAIN}-{N}:
  source_fact: EV-{DOMAIN}-{N}
  reason: "{low_confidence|single_project|owner_required|no_code_evidence}"
  promotion_criteria: "{明确升级所需条件}"
```

---

### Sub-step C — Derivative Generator

**C1. ai-rules.md**

- 从 `standard-{sub_domain}.md` 的 `§"AI 生成代码规则"` 章节提取，**不新写内容**
- 结构：§1 全局约束 + §2 可执行规则（按 sub_domain 分组）+ §3 使用边界警告
- 每条规则来源引用：`standard-{sub_domain}.md §「AI 生成代码规则」`
- 状态为 `draft` 的文档在 §3 输出 warning：`> ⚠️ 本规则来自 draft 状态文档，领域负责人确认前请谨慎强制执行`

**C2. review-checklist.md**

- 从 `standard-{sub_domain}.md` 的 `§"Code Review 检查项"` 章节提取，**不新写内容**
- 结构：§1 必检项（含 FORBIDDEN 标注的规则）+ §2 推荐检查项 + §3 AI 生成专项
- 每条检查项来源引用：`standard-{sub_domain}.md §「Code Review 检查项」`

**C3. 派生声明**

在 `ai-rules.md` 和 `review-checklist.md` 顶部写：

```markdown
> 本文件是 `standard-{sub_domain}.md` 的派生视图，由 generation 阶段自动生成，不接受手工修改。
> 修改规则请更新 `standard-{sub_domain}.md`，然后重新运行 generation。
```

---

### Sub-step D — Index & Pack Aggregator

**D1. rules-index-candidate.json**

按 `standard-{sub_domain}.md` 的主要章节（`## {N}. {章节名}`）生成索引，每个章节一条：

```json
{
  "generated_at": "{ISO8601}",
  "batch_id": "{batch_id}",
  "status": "candidate",
  "doc_mode": "guide",
  "sections": [
    {
      "source_doc": "standard-{sub_domain}.md",
      "section_title": "{章节名，与 H2 字面一致}",
      "section_type": "tech-stack|architecture|role-rules|ai-rules|review-checklist|evidence",
      "domain": "",
      "sub_domain": "",
      "has_forbidden": false,
      "evidence_ids": ["EV-{DOMAIN}-{N}"],
      "tags": []
    }
  ]
}
```

**D2. llms-candidate.txt**

```
# Engineering Standards — {domain} — {sub_domain} — candidate
# Generated: {ISO8601}, Batch: {batch_id}, Mode: guide

## 规范文件（Developer Guide）
- standard-{sub_domain}.md  — {sub_domain} 完整开发指南（{N} 个主要章节）
- standard-common.md        — 跨 sub_domain 共性规范（如有）
- ai-rules.md               — AI 编码规则汇总视图
- review-checklist.md       — Review 检查项汇总视图

## Evidence
- evidence/code-facts.md（{N} 条事实）
- evidence/positive-examples.md
- evidence/forbidden-examples.md
- evidence/legacy-compatible.md

## 状态
- draft 文档：{N} 份
- pending-confirmation：{N} 条待处理
- 候选状态，需人工确认后合并到正式 llms.txt
```

**D3. ai-context-pack.md**

```markdown
---
doc_id: "{domain}-{run_id}-ai-context-pack"
doc_type: ai-context-pack
indexable: false
---

# AI Context Pack — {domain} — {sub_domain}

## 本次萃取摘要
Batch: {batch_id} | 模式: Developer Guide | 章节数: {N} | Evidence: {N} 条

## 核心规范文件
- `standard-{sub_domain}.md` — {sub_domain} 完整开发指南

## 关键约束摘要（FORBIDDEN 和强制规则）
{从 standard 的禁止事项 + FORBIDDEN 标注中提取，每条一行}

## AI 使用边界
{文档状态 draft 的警告，说明哪些规则需要负责人确认}

## 来源 Batch 信息
{batch_id, domain, sub_domain, evidence_tier}
```

---

## Self-check（全局，Sub-step B 完成后执行）

- [ ] `standard-{sub_domain}.md` 包含 §技术栈、§分层职责、≥1 个角色/层级规范节、§AI 规则、§Review 检查项、§Evidence 参考
- [ ] 每个角色/层级节有强制规则 + 禁止事项（至少各 1 条）
- [ ] 有至少 1 个正例代码块（来自 POS-* evidence）
- [ ] 有至少 1 个反例代码块（来自 NEG-* evidence）
- [ ] FORBIDDEN 规则已用 `⛔ FORBIDDEN` 标注，并引用 NEG-* evidence
- [ ] Evidence 参考表格已填写（无空行）
- [ ] `status: active`（auto 模式直接输出 active）
- [ ] 规则正文没有具体项目绝对路径
- [ ] `ai-rules.md` 和 `review-checklist.md` 引用了 standard 章节
- [ ] Sub-step D 在 B+C 完成后才执行
- [ ] `rules-index-candidate.json` 中 `status: candidate`（不是 published）
- [ ] pending_confirmation 的内容写入了 `pending-confirmation.md`

## 失败模式映射

| 命中条件 | 处理 |
| --- | --- |
| code_facts 为空或全部 pending | 不生成 standard；仅输出 pending-confirmation |
| evidence 不足以写完整章节 | 用已有 evidence 写能覆盖的节；其余节用 pending-confirmation 占位 |
| 发现规则与已有 active 冲突 | 写入 `conflicts.md`，不写入 standard |
| B0 推导阶段无法理解架构 | 回到 profile 阶段补充画像，不凭空编写 |

## 必须做

1. 先在 B0 阶段理解 sub_domain 架构，再动笔写文档。
2. `standard-{sub_domain}.md` 是开发者工作手册，不是规则注册表——每节要有实质内容。
3. 代码示例（正例+反例）必须内联在主文档，基于真实 evidence，路径脱敏。
4. `status` 在 auto 模式下输出 `active`，在 interactive 模式下输出 `draft`。
5. ai-rules 和 review-checklist 是 standard 的派生，不得新创内容。
6. 候选索引产物标记 `candidate`，不得默认发布。

## 禁止做

1. 不得写"规则条目注册表"风格（每条规则一个 YAML 块）——这是本次重写的核心改变。
2. 不得在 Sub-step A 未完成时开始写 standard。
3. 不得把无 evidence 的内容写成强制规则或 FORBIDDEN 标注。
4. 不得在 ai-rules.md 里强制执行 pending/conflict/legacy-compatible 规则。
5. 不得输出 `status: active` 在 interactive 模式下——interactive 模式只输出 `draft`。
6. 不得默认发布候选索引产物。
7. 不得凭空编写架构图——从 code_facts 推断，不确定的打「?」标注。
