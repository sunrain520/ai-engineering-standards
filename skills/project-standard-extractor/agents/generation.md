# Generation Contract

## 角色目标

基于 `code_facts` 和 `classification` 生成团队级规范、AI Coding Rules、Review Checklist 和 evidence 文档。输出质量的核心保证是**工序严格性**：evidence 先行 → standard 收口 → ai-rules / review-checklist 派生 → 候选索引最后聚合。任何乱序都会产生规则与证据脱钩。

> 上游：`facts-and-classification`（code_facts + classification）。下游：`review-and-quality-gate`。

## 输入

```yaml
inputs:
  code_facts:             # facts-and-classification 的全量输出
  classification:         # recommended / forbidden / legacy_compatible / pending_confirmation / conflict
  selected_batch_summary: # batch_id / domain / sub_domain / evidence_limit / rule_limit
  global_templates:       # templates/ 目录
  frontmatter_format:     # config/frontmatter-format.md
  output_targets:         # config/output-targets.md
  existing_standard:      # 若 standard.md 已存在，列出已有 (source_doc, section_title) 列表
```

## 输出（完整产物清单）

| 产物 | doc_type | indexable | 生成时机 |
| --- | --- | --- | --- |
| `evidence/code-facts.md` | evidence-code-facts | true | Sub-step A |
| `evidence/positive-examples.md` | evidence-positive | true | Sub-step A |
| `evidence/forbidden-examples.md` | evidence-forbidden | true | Sub-step A |
| `evidence/legacy-compatible.md` | evidence-legacy | true | Sub-step A |
| `standard.md` | standard | true | Sub-step B |
| `pending-confirmation.md` | pending-confirmation | false | Sub-step B |
| `ai-rules.md` | ai-rules | true | Sub-step C |
| `review-checklist.md` | review-checklist | true | Sub-step C |
| `{run_id}-rules-index-candidate.json` | — | — | Sub-step D |
| `{run_id}-llms-candidate.txt` | — | — | Sub-step D |
| `{run_id}-ai-context-pack.md` | ai-context-pack | false | Sub-step D |

## 生成管线（严格工序）

```
Sub-step A: Evidence Writer
  └── 输入: code_facts (raw)
  └── 输出: evidence/*（EV/POS/NEG/LEG 编号固定后不变）
  └── 完成标志: 每条 code_facts 已有对应 evidence 条目编号

Sub-step B: Standard Author
  └── 输入: classification + evidence 编号表
  └── 输出: standard.md（唯一规范来源 single source of truth）
  └── 完成标志: 每条 recommended/forbidden 规则有 evidence 编号引用

Sub-step C: Derivative Generator（可并行两份）
  ├── ai-rules.md       ← 直接从 standard.md §"AI 生成代码要求" 提取，不再创作
  └── review-checklist.md ← 直接从 standard.md §"Code Review 检查项" 提取，不再创作
  └── 完成标志: ai-rules 每条 Rule 有对应 standard.md「{section_title}」引用

Sub-step D: Index & Pack Aggregator（Sub-step B + C 全部完成后执行）
  ├── rules-index-candidate.json  ← 汇总 standard.md 所有 H2 规则
  ├── llms-candidate.txt          ← 领域入口地图
  └── ai-context-pack.md          ← 命中规则摘要 + 来源 batch
  └── 完成标志: 所有条目指向通过 Sub-step B 生成的规则（非 pending / conflict）
```

**工序约束**：未完成上一步 before 不得执行下一步。Sub-step B 不得在 evidence 编号未锁定前开始写规则。Sub-step D 不得在 B + C 全部完成前生成候选索引。

## 执行步骤

### Sub-step A — Evidence Writer

**A1. Front Matter 写入**

对每个 evidence 文件写入符合 `config/frontmatter-format.md` 的 YAML Front Matter，字段完整（`doc_id`、`domain`、`sub_domain`、`doc_type`、`indexable: true`、`tags`）。

**A2. 条目编号分配**

```
EV-{DOMAIN}-{N}   → evidence/code-facts.md
POS-{DOMAIN}-{N}  → evidence/positive-examples.md
NEG-{DOMAIN}-{N}  → evidence/forbidden-examples.md
LEG-{DOMAIN}-{N}  → evidence/legacy-compatible.md
```

`{N}` 单调递增，不重排，不复用。若目标文件已存在条目，从当前最大 N+1 开始追加。

**A3. 写入规则**

- code-facts：每条 fact（含 `observed_pattern`、`boundary`、`confidence`、`file_role`）。
- positive-examples：classification.recommended 关联的事实，附路径模式（不写具体项目路径）和解释。
- forbidden-examples：classification.forbidden 关联的事实，附反例模式和风险说明。
- legacy-compatible：classification.legacy_compatible 关联的事实，附兼容边界说明。

**A4. 路径保护**

- evidence 正文可写**路径模式**（`src/main/java/**/Controller.java`），**不写具体项目绝对路径**。
- 具体项目绝对路径只允许出现在 evidence front matter 的 `source_batch` 字段，且用相对路径引用。

### Sub-step B — Standard Author

**B1. 规则结构模板**

每条规则按以下结构写入：

```markdown
## {P0|P1|P2|FORBIDDEN} {规则标题}

```yaml
status: draft
level: {P0|P1|P2|FORBIDDEN}
source_kind: extracted
evidence_tier: {direct-code|cross-project|single-project|inferred|none}
risk_tag: {high|medium|low|none}
owner: TBD
last_reviewed: {YYYY-MM-DD}
recommended_action: keep-draft
```

### 适用范围

{说明本规则适用哪些场景、语言、框架版本}

### 推荐做法

{具体的、可操作的正向说明；语言简短；必要时给模式示意}

### 禁止做法

{具体的、可操作的负向说明；不重复适用范围}

### AI 生成代码要求

{AI 在生成/修改相关代码时应满足的约束，直接可执行}

### Code Review 检查项

- [ ] {检查项1，reviewer 可判断 pass/fail}
- [ ] {检查项2}

### Evidence

- {EV/POS/NEG/LEG-DOMAIN-N}「{brief description}」
```

**B2. 规则编写约束**

1. `level: P0 / FORBIDDEN` 必须有 `risk_tag: high`，且 evidence 中有 NEG- 编号引用。
2. `evidence_tier: none` 的规则进入 `pending-confirmation.md`，不进入 `standard.md`。
3. `source_kind: template-placeholder` 不得写成强制规则（P0/FORBIDDEN）。
4. 规则 H2 标题必须满足 `^(P0|P1|P2|FORBIDDEN) ` 前缀，同一 `source_doc` 内 `section_title` 唯一。
5. 规则正文不写具体项目路径。
6. **注释剥离**：写入文件时剥离所有解释性内联注释（如模板里 `# draft / active / ...` 枚举说明、`# 填写路径` 等），保留有意义的业务注释。

**B3. 规则数量门禁**

- 最终进入 `standard.md` 的规则数 ≤ `batch.rule_limit`。
- 超出部分：evidence tier = cross-project 优先保留；其余降为 `pending-confirmation`。

**B4. Pending Confirmation 落点**

classification.pending_confirmation 和超出规则数的候选，写入 `pending-confirmation.md` 并标注：

```yaml
PENDING-{DOMAIN}-{N}:
  source_fact: EV-{DOMAIN}-{N}
  reason: "{low_confidence|single_project|rule_limit_exceeded|owner_required}"
  promotion_criteria: "{明确升级为 draft 所需条件}"
```

### Sub-step C — Derivative Generator

**C1. ai-rules.md 生成规则**

- 只从 `standard.md` 的 `## AI 生成代码要求` 小节提取，**不新写内容**。
- 结构：`§1 全局约束（draft 规则的使用边界）` + `§2 可执行规则列表` + `§3 高风险警告`。
- 每条 AI Rule 必须引用来源：`standard.md「{section_title}」`。
- 对 `draft / risk_tag: high / pending / conflict / legacy-compatible` 状态的规则：必须在 §3 输出 warning，说明为什么 AI 不得无条件执行。

**C2. review-checklist.md 生成规则**

- 只从 `standard.md` 的 `## Code Review 检查项` 小节提取，**不新写内容**。
- 结构：`§1 必检项（P0/FORBIDDEN）` + `§2 推荐检查项（P1/P2）` + `§3 历史兼容说明`。
- 每个检查项必须是 reviewer 可判断 pass / fail 的陈述（不接受"适当地"、"尽量"等模糊表述）。
- 每条检查项引用来源：`standard.md「{section_title}」`。

**C3. 派生声明**

在 `ai-rules.md` 和 `review-checklist.md` 顶部注明：

```markdown
> 本文件是 `standard.md` 的派生视图，由 generation 阶段自动生成，不接受手工修改。
> 如需修改规则，请更新 `standard.md` 后重新运行 generation 阶段。
```

### Sub-step D — Index & Pack Aggregator

**D1. rules-index-candidate.json**

遍历 `standard.md` 所有 `## {level} {title}` H2，生成：

```json
{
  "generated_at": "{ISO8601}",
  "batch_id": "{batch_id}",
  "status": "candidate",
  "rules": [
    {
      "title": "{P0|P1|P2|FORBIDDEN} {规则标题}",
      "domain": "",
      "sub_domain": "",
      "level": "",
      "source_doc": "standard.md",
      "section_title": "{规则标题（无前缀）}",
      "evidence_doc": "evidence/code-facts.md",
      "tags": []
    }
  ]
}
```

字段说明：
- 不含 `rule_id` 或 `anchor`
- `section_title` 与 standard.md H2 字面一致（不改写）
- `status: candidate` 必须保留，不得默认发布

**D2. llms-candidate.txt**

一个领域入口地图，格式：

```
# Engineering Standards — {domain} — {sub_domain} — candidate
# Generated: {ISO8601}, Batch: {batch_id}

## 规范文件
- standard.md        — 团队级规范（{N} 条规则）
- ai-rules.md        — AI 编码规则（{N} 条）
- review-checklist.md — Review 检查项（{N} 条）

## Evidence
- evidence/code-facts.md
- evidence/positive-examples.md
- evidence/forbidden-examples.md
- evidence/legacy-compatible.md

## 状态
- draft 规则：{N} 条
- pending-confirmation：{N} 条
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
Batch: {batch_id} | 规则数: {N} | Evidence: {N}

## 高优先级规则（P0 / FORBIDDEN）
{列出 source_doc「section_title」+ 一句话摘要}

## AI 编码警告
{draft / high-risk / pending 规则的使用边界说明}

## 来源 Batch 信息
{batch_id, domain, sub_domain, evidence_limit, rule_limit}
```

### Step（全局）Self-check

- [ ] Sub-step A 全部 evidence 写入完成后才开始 Sub-step B
- [ ] 每条 `standard.md` 规则有对应 `EV/POS/NEG/LEG` 编号引用
- [ ] `ai-rules.md` 每条 Rule 有 `standard.md「{section_title}」` 引用
- [ ] `review-checklist.md` 每条检查项有 `standard.md「{section_title}」` 引用
- [ ] Sub-step D 在 B + C 全部完成后才执行
- [ ] `rules-index-candidate.json` 不含 `rule_id` 或 `anchor`
- [ ] 所有 Markdown 文件 Front Matter 字段完整，通过 `config/frontmatter-format.md` 枚举校验
- [ ] `evidence_tier: none` 的规则都在 `pending-confirmation.md`，不在 `standard.md`
- [ ] `draft` / `risk_tag: high` 规则在 `ai-rules.md §3` 有 warning
- [ ] 规则正文没有具体项目绝对路径
- [ ] 所有模板解释性注释已剥离

## 失败模式映射

| 命中条件 | 处理 |
| --- | --- |
| code_facts 为空或全部 pending | 不生成 standard.md；仅输出 pending-confirmation.md |
| evidence 编号无法与 standard 规则对应 | `INSUFFICIENT_EVIDENCE`；该规则降入 pending-confirmation |
| standard.md 生成时发现规则与已有 active 冲突 | 写入 `conflicts.md`，不写入 standard.md |
| 超出 rule_limit | 按 evidence tier 优先级截断，其余入 pending-confirmation |

## 必须做

1. 严格按 Sub-step A → B → C → D 顺序执行，C 可并行，D 在 B+C 后执行。
2. ai-rules 和 review-checklist 是 standard 的派生，不得新创内容。
3. 候选索引产物标记 `candidate`，不得默认发布。
4. 写入前剥离模板解释性注释。
5. 每条规则都有 evidence 引用。

## 禁止做

1. 不得在 Sub-step A 未完成时开始写规则。
2. 不得在 Sub-step D 中为未通过 quality gate 的规则生成索引条目。
3. 不得把无证据模板内容写成强制规则（P0/FORBIDDEN）。
4. 不得在 ai-rules.md 里强制执行 pending/conflict/rejected/legacy-compatible 规则。
5. 不得生成 Rule ID 或 HTML anchor。
6. 不得默认发布候选索引产物为正式 `.index/rules-index.json` 或根 `llms.txt`。
