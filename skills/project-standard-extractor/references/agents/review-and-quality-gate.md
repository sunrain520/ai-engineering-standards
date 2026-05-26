# Review And Quality Gate Contract

## 角色目标

对生成结果做**多 persona 分面评审**，并基于 `activation-report.json` 应用**双门禁**（content gate + activation gate），输出带置信度的 Quality Gate 决策。评审不是橡皮章——每个 persona 必须输出明确 findings（pass / warn / block），未通过的规则必须有明确处置路径。对规则冲突引入 **Proposer-Challenger-Arbiter** 结构，避免无结构覆盖。`shallow` 维度走完整评审,但**强制改判** keep-draft-low-coverage,保留 review 决议优先级。

> 上游：`generation`（standard.md + ai-rules.md + review-checklist.md + evidence/* + 候选索引 + activation-report 透传）。下游：`merge-coordinator`。

## 输入

```yaml
inputs:
  standard_docs:          # 生成的 standard-{sub_domain}.md 列表（按 sub_domain 分文件；含 standard-common.md 如有）
  ai_rules_doc:           # 生成的 ai-rules.md
  review_checklist_doc:   # 生成的 review-checklist.md
  evidence_docs:          # evidence/code-facts.md + positive + forbidden + legacy
  pending_doc:            # pending-confirmation.md
  candidate_index:        # temp/{run_id}-rules-index-candidate.json
  activation_report:      # temp/{run_id}-activation-report.json (schema=activation-report.v1)
                          # 来自 dimension-activator,本阶段权威激活态来源
                          # 决定 P8 Coverage Reviewer + 双门禁聚合 + shallow 强制改判
  depth_indicator:        # references/config/dimension-framework/depth-indicator.yaml
                          # 端 / 维度阈值,P8 Coverage 与 generation depth_score 对照
  existing_standards:     # 当前 engineering-standards/ 下的 active/draft 规则清单
  batch_summary:          # batch_id + evidence_limit + rule_limit + stop_conditions_hit
```

## 双门禁机制

```
┌──────────────────────────────────────────┐
│ Gate A: Content Gate                     │ ← P1-P7 + P8(Coverage) 7+1 persona findings 聚合
│  评审"规则内容是否合格"                  │   规则可读性 / evidence / 团队抽象 / AI 执行性 / 冲突 / 行业 / 治理 / 深度
└──────────────────┬───────────────────────┘
                   │ 任一 BLOCK → block 下游
                   ▼
┌──────────────────────────────────────────┐
│ Gate B: Activation Gate                  │ ← activation-report state × content gate decision 交叉
│  评审"激活态是否与内容决议一致"          │   pending → 强制 move-to-pending; shallow → 强制 keep-draft-low-coverage
└──────────────────┬───────────────────────┘
                   │ 任一冲突 → 强制改判
                   ▼
              quality_gate_decision (final)
```

**铁律**:Gate B 决议**优先**于 Gate A——即使 P1-P8 全部 PASS,只要 dimension_state 是 pending-confirmation,最终决议必须是 move-to-pending;shallow 维度即使 PASS,最终 recommended_action 必须是 keep-draft-low-coverage。

## 输出（Handoff Schema）

```yaml
review_report:
  run_id: ""
  batch_id: ""
  activation_report_ref: ""    # temp/{run_id}-activation-report.json 透传
  evaluated_rules: []          # [{source_doc, section_title, level, dimension_id, dimension_state, outcome}]
  persona_findings: []         # 见各 persona 输出格式
  debate_records: []           # 冲突规则的 Proposer-Challenger-Arbiter 记录
  quality_gate_decisions: []   # 每条规则一个决策
  shallow_overrides: []        # 被 Gate B 强制改判 keep-draft-low-coverage 的规则 id 列表
  pending_overrides: []        # 被 Gate B 强制改判 move-to-pending 的规则 id 列表
  candidate_dim_summary: {}    # 来自 activation-report 的 candidate 维度统计(透传给 merge)

quality_gate_decision:    # 每条规则各一份
  source_doc: ""
  section_title: ""              # 与 standard.md H2 字面一致
  dimension_id: ""               # 关联 activation-report.dimensions[].dimension_id
  dimension_state: ""            # 来自 activation-report,本阶段不重判
  passed: false
  status: ""                     # ok | blocked | conflict（U24 force-rebuild-validate.sh 必读字段；canonical 决策状态）
  target_state: ""               # draft / pending-confirmation / conflict / legacy-compatible / rejected
  recommended_action: ""         # keep-draft / promote-to-active / move-to-pending / mark-conflict / mark-legacy / reject / defer / keep-draft-low-coverage
  confidence: ""                 # high / medium / low（基于 persona 共识度）
  content_gate_outcome: ""       # pass / conditional / soft-fail / hard-fail / reject (Gate A 结论)
  activation_gate_outcome: ""    # pass / forced-pending / forced-low-coverage / forced-candidate-skip (Gate B 结论)
  final_gate_decision: ""        # Gate B override Gate A 后的最终决议
  evidence_result: ""
  team_standard_result: ""
  ai_executability_result: ""
  review_checklist_result: ""
  conflict_result: ""
  industry_risk_result: ""
  context_governance_result: ""
  coverage_result: ""            # 来自 P8 Coverage Reviewer
  required_human_confirmation: []
  blocking_findings: []
  warnings: []
  override_rationale: ""         # Gate B 强制改判原因(如 "dimension_state=pending-confirmation: forced move-to-pending")
```

## Review Personas（8 个，全部必须执行）

### P1 — Evidence Auditor

**职责**：验证每条规则是否有真实、可追溯的 evidence 支撑。

**检查清单**：

- [ ] 规则 YAML 中 `evidence_tier` 非 `none`；若 `none` → **BLOCK**
- [ ] 规则 body 的 Evidence 小节有 ≥ 1 个 `EV/POS/NEG/LEG-DOMAIN-N` 条目编号，且该编号在 `evidence/code-facts.md` 中实际存在
- [ ] P0 / FORBIDDEN 规则必须有 `NEG-DOMAIN-N` 负例 → 若缺失 → **BLOCK**
- [ ] `evidence_tier: single-project` 的规则 → **WARN**（建议补充多项目验证）
- [ ] `evidence_tier: inferred` 的规则 → **WARN**，且 `risk_tag` 必须 ≤ `low`；否则 → **BLOCK**
- [ ] 路径模式不得包含具体项目绝对路径 → 若包含 → **BLOCK**
- [ ] 敏感文件相关 evidence 只有脱敏存在事实，无原值 → 若有原值 → **BLOCK**

**输出格式**：`{rule_locator, check, outcome: pass|warn|block, detail}`

---

### P2 — Team Standard Reviewer

**职责**：确认规则是**团队级抽象**，不是单项目说明书或个人偏好；同时守护规则节的格式契约（inline 元数据行 + 字段全集）。

**检查清单**：

- [ ] 规则说明不含具体项目名称 / 路径 / 内部业务术语（无上下文则难以理解）→ 若含 → **BLOCK**
- [ ] 规则适用范围明确写出 `domain` + `sub_domain` + `适用场景`；若适用范围是"全体项目" → **WARN**（验证是否真的跨项目有 evidence）
- [ ] 推荐做法和禁止做法可操作，不含"尽量"、"适当地"、"注意" 等模糊词 → 若含 → **WARN**
- [ ] 规则不是行业通用知识的重复描述（如"不要写 SQL 注入"等行业常识，需要团队特有做法才能 draft）→ 若是通用知识且无团队特有 evidence → **WARN**
- [ ] 规则 H2/H3 标题前缀严格匹配 `^(P0|P1|P2|FORBIDDEN) `，与 rules-index candidate 的 `section_title` 字面一致 → 若不一致 → **BLOCK**
- [ ] **规则节使用 inline blockquote 元数据行**（`^> level: .* · status: .* · ...`），紧跟规则 H2/H3 标题；**禁止整块 `\`\`\`yaml ... \`\`\`` 元数据**（catalog 风格已废弃）→ 若发现 yaml 块 → **BLOCK**
- [ ] **inline 元数据行字段全集到齐**:必含 `level`、`status`、`source_kind`、`evidence_tier`、`risk_tag`、`owner`、`last_reviewed`、`recommended_action` 共 8 项;字段顺序与 `references/prompts/rule-generation.md` 规定一致 → 若缺字段 → **WARN**;若字段顺序错乱 → **WARN**

---

### P3 — AI Executability Reviewer

**职责**：验证规则中"AI 生成代码要求"是否可被 AI 编码代理无歧义执行。

**检查清单**：

- [ ] 每条 `standard-{sub_domain}.md` 规则有 `## AI 生成代码要求` 小节，且内容不为空 → 若缺失 → **WARN**
- [ ] AI 要求是正向约束句式（"必须…" / "禁止…" / "应在… 中…"），而非描述句式 → 若是描述 → **WARN**
- [ ] `ai-rules.md` 中每条 Rule 有 `standard-{sub_domain}.md「{section_title}」` 来源引用 → 若缺引用 → **BLOCK**
- [ ] `draft / risk_tag: high / pending / conflict / legacy-compatible` 规则在 `ai-rules.md §3` 有 warning → 若缺 warning → **BLOCK**
- [ ] AI 要求不包含"参考项目中的做法" / "按团队习惯" 等无法独立执行的表述 → 若含 → **WARN**
- [ ] P0 / FORBIDDEN 规则的 AI 要求没有"可以"等允许例外的语气 → 若含 → **WARN**

---

### P4 — Review Checklist Reviewer

**职责**：验证每条检查项是否可被 Code Reviewer 独立判断 pass / fail。

**检查清单**：

- [ ] `review-checklist.md` 每条检查项有 `standard-{sub_domain}.md「{section_title}」` 来源引用 → 若缺 → **BLOCK**
- [ ] 检查项是**可判断的陈述**（reviewer 看代码即可二值判断），不是"好好检查…" → 若不可判断 → **WARN**
- [ ] P0 / FORBIDDEN 的检查项在 `§1 必检项` 段 → 若在 §2 → **BLOCK**
- [ ] 检查项数量与各 `standard-{sub_domain}.md` 规则数相匹配（每条规则 ≥ 1 个检查项）→ 若有规则无检查项 → **WARN**
- [ ] 检查项语言精确：含主语（"Controller 层"）+ 谓语 + 宾语，不含 "注意"/"请确认"等模糊前缀 → 若含 → **WARN**

---

### P5 — Conflict Reviewer

**职责**：检测新规则与已有规范的冲突，并触发 Proposer-Challenger 辩论。

**检查清单**：

- [ ] 对每条新规则，在 `existing_standards` 中搜索语义重叠项（同 domain + 相近 section_title / 适用范围）→ 若命中 → 触发 Debate 流程
- [ ] 若 `classification.conflict` 列表非空，验证每条已有对应 `(source_doc, section_title)` 冲突记录 → 若缺 → **BLOCK**
- [ ] 新规则不得与已有 `active` 规则逻辑矛盾（禁止同一场景有不同必须约束）→ 若矛盾 → **BLOCK**（进入 conflicts.md）
- [ ] 新规则与已有 `draft` 冲突 → **WARN**，触发 merge-suggestions

**Debate 流程（命中冲突时执行）**：

```yaml
debate_record:
  rule_locator: "{source_doc}「{section_title}」"
  conflict_with: "{existing_source_doc}「{existing_section_title}」"
  proposer:
    argument: "{新规则支持理由，引用 evidence id}"
    evidence_tier: ""
  challenger:
    argument: "{已有规则保留理由，引用已有 evidence 或 owner 确认}"
    evidence_tier: ""
  arbiter_decision:
    winner: "proposer | challenger | draw"
    rationale: "{决策理由，引用更高 evidence tier 或 owner 确认}"
    recommended_action: "keep-draft | mark-conflict | defer"
```

决策规则（Arbiter）：
- `existing active` vs `new draft` → challenger 默认胜，新规则进 conflicts.md
- `existing draft` vs `new draft` → 比较 evidence tier；cross-project > single-project；平局 → draw，进 merge-suggestions
- `existing pending` vs `new draft` + evidence → proposer 胜，建议替换 pending

---

### P6 — Industry Risk Reviewer

**职责**：检查行业、合规、安全相关规则是否有过度声明风险。

**检查清单**：

- [ ] `industry` domain 的规则必须有 `source_kind: owner-confirmed` 或来自行业标准引用 → 若仅 `extracted` 且无 owner 确认 → **WARN**，`evidence_tier` 不得高于 `single-project`
- [ ] 合规 / 安全相关规则（含 `auth`、`security`、`compliance`、`pii`、`trade`、`order`、`payment` 等关键词）→ `risk_tag` 必须 ≥ `medium`；低于则 → **WARN**
- [ ] 规则不包含未脱敏的敏感词（客户标识符、生产 URL、内部系统名称）→ 若含 → **BLOCK**
- [ ] FORBIDDEN 级别规则不得仅因行业共识声明，必须有团队真实违规事实 → 若无真实负例 → **WARN**，降为 P0

---

### P7 — Context Governance Reviewer

**职责**：验证整个萃取过程是否遵守 profile-first、batch 边界、artifact handoff 和候选索引边界。

**检查清单**：

- [ ] 所有 `standard-{sub_domain}.md` 中不含任何具体项目绝对路径 → 若含 → **BLOCK**
- [ ] 所有规则 evidence 均来自选定 batch 的 `candidate_files`，未越界读取 → 若有 `unread_candidates: []` 以外的路径 → **WARN**
- [ ] `batch_summary.stop_conditions_hit` 不为空时，检查对应规则是否都被正确降级为 pending → 若未降级 → **BLOCK**
- [ ] `rules-index-candidate.json` 的 `status` 字段为 `candidate` → 若为 `active`/`published` → **BLOCK**
- [ ] `ai-context-pack.md` 的 `indexable: false` → 若为 `true` → **BLOCK**
- [ ] `pending-confirmation.md` 中的规则不得出现在 `ai-rules.md §2 可执行规则` 中 → 若出现 → **BLOCK**
- [ ] 所有 standard-{sub_domain}.md 不残留 `{{activation_state` 占位符(grep 验证)→ 若残留 → **BLOCK**
- [ ] `standard-overview.md` §9 未激活维度地图 存在(AE7),即使 candidate=0 也保留章节标题 → 若缺 → **BLOCK**

---

### P8 — Coverage Reviewer (U9 新增)

**职责**：基于 `activation-report.dimensions[].depth_score` 与 `depth-indicator.yaml` 端 / 维度阈值对照,识别 coverage 不足的章节;对 `state == shallow` 的维度强制保留 `coverage = low` 标记。

**输入**: `activation_report.dimensions[]` + `depth_indicator.yaml` + standard 文档章节级激活态标注。

**检查清单**：

- [ ] 每个 `standard-{sub_domain}.md` 章节标注 `[activated]` 或 `[shallow]` 的章节,在 activation-report 都能找到对应 dimension_id → 若孤儿 → **BLOCK**
- [ ] `state == shallow` 维度对应的章节首行有 `> ⚠️ 本节 coverage=low` warning → 若缺 → **BLOCK**
- [ ] `state == shallow` 维度规则的 inline 元数据行 `recommended_action == keep-draft-low-coverage` → 若不一致 → **BLOCK**
- [ ] `state == activated` 维度但 `depth_score < depth_indicator.yaml` 端阈值 → **WARN** + 建议 review 改判 shallow(由 Gate B 决策)
- [ ] `state == pending-confirmation` 维度对应的章节不得出现强制规则 / FORBIDDEN 标注 → 若出现 → **BLOCK**
- [ ] `state == candidate` 维度对应内容不得出现在 `standard-{sub_domain}.md` 章节内(只能在 overview §9 未激活地图) → 若出现 → **BLOCK**
- [ ] `state == baseline` 维度对应的章节内容能在 `baseline-dimensions.yaml` default 中找到对应起源 → 若内容杜撰 → **BLOCK**
- [ ] `ai-rules.md` 不收录 `pending` / `candidate` 维度规则 → 若收录 → **BLOCK**
- [ ] `review-checklist.md` 不收录 `pending` / `candidate` 维度检查项 → 若收录 → **BLOCK**

**深度未达改判建议**:对 `state == activated` 但 `depth_score` 低于阈值的维度,P8 输出 `suggest_demote_to_shallow: true`,由 Gate B 决议是否落实改判。

**输出格式**：`{rule_locator, dimension_id, dimension_state, depth_score, threshold, outcome: pass|warn|block, suggest_demote_to_shallow, detail}`

---

## Quality Gate 聚合（双门禁 + 8 persona 输出）

### Gate A — Content Gate（P1-P8 内容评审聚合）

### Gate A 决策矩阵

| 状态 | 条件 | content_gate_outcome | 初步 target_state | 初步 recommended_action |
| --- | --- | --- | --- | --- |
| 全通过（PASS） | 8 persona 无 BLOCK，WARN ≤ 2 | `pass` | `draft` | `keep-draft` |
| 有 WARN（CONDITIONAL） | 8 persona 无 BLOCK，WARN > 2 | `conditional` | `draft` | `keep-draft`（标注警告） |
| 单 BLOCK（SOFT FAIL） | 1–2 个 BLOCK，可通过补 evidence 或修规则解决 | `soft-fail` | `pending-confirmation` | `move-to-pending` |
| 多 BLOCK / 冲突（HARD FAIL） | ≥ 3 个 BLOCK 或与 active 冲突 | `hard-fail` | `conflict` | `mark-conflict` |
| 无 evidence / 无执行性（REJECT） | evidence_tier: none 且无法补救 | `reject` | `rejected` | `reject` |
| 行业高风险（DEFER） | P6 BLOCK 且无 owner 确认 | `soft-fail` | `pending-confirmation` | `defer` |

### Gate B — Activation Gate（激活态强制改判）

Gate B 在 Gate A 完成后**串行**执行。读取 `activation-report.dimensions[]` 与 P8 Coverage suggest_demote_to_shallow 输出,按下表强制改判:

| dimension_state | P8 suggest_demote | activation_gate_outcome | 最终 target_state | 最终 recommended_action |
| --- | --- | --- | --- | --- |
| `activated` | false | `pass` | 沿用 Gate A 决议 | 沿用 Gate A 决议 |
| `activated` | true (深度未达) | `forced-low-coverage` | `draft` | `keep-draft-low-coverage` |
| `shallow` | — | `forced-low-coverage` | `draft` | `keep-draft-low-coverage` |
| `pending-confirmation` | — | `forced-pending` | `pending-confirmation` | `move-to-pending` |
| `baseline` | — | `pass` | `draft` | `keep-draft` |
| `candidate` | — | `forced-candidate-skip` | 该规则**不应在 standard 中** → P8 已 BLOCK,不进 Gate B |

**override_rationale 必填**:Gate B 改判时必须写入 `override_rationale`,例如 `dimension_state=pending-confirmation: forced move-to-pending despite Gate A pass`。

### `quality_gate_decisions[].status` 枚举(U24 force-rebuild-validate.sh canonical 字段)

每条决策必须输出 `status` 字段(枚举三选一),force-rebuild-validate.sh check (d) 只解析 `quality_gate_decisions:` YAML 段内的 `status: blocked | conflict` 来统计阻断:

| status | 触发条件(任一) | 写入 review-summary.md `quality_gate_decisions:` 段格式 |
| --- | --- | --- |
| `ok` | content_gate_outcome ∈ {pass, conditional} 且 activation_gate_outcome ≠ forced-candidate-skip 且无 P0 BLOCK | `status: ok` |
| `blocked` | 任一 persona 输出 BLOCK / hard-fail / activation_gate_outcome=forced-candidate-skip(candidate 维度误植入)/ P0 evidence 缺失 | `status: blocked` |
| `conflict` | conflicts.md 新增 ≥ 1 条 breaking 与本条规则关联 / debate_record.arbiter 决议 = unresolved / 跨项目 partial_activated 维度未裁定 | `status: conflict` |

**铁律**:`status` 字段值必须出现在 review-summary.md `quality_gate_decisions:` YAML 段内,**每行单独一个 `status: <value>`**；正文、示例或其他 YAML 段中的同名字段不参与 U24 阻断统计。

force-rebuild 模式下,只要 `status: blocked` 或 `status: conflict` ≥ 1 行,U24 validate.sh check (d) 立即 fail,backup-manager step 10b 触发 atomic rollback。

### 置信度计算

```
confidence:
  high   = 8/8 personas pass 或 WARN 仅 P2/P6 + Gate B activated 维度
  medium = 6-7/8 personas pass，BLOCK ≤ 1 且已标注修复路径,或 shallow / pending 维度强制改判后内容质量良好
  low    = ≤ 5/8 personas pass 或有 BLOCK 且不可修复,或 candidate 维度误植入端规范
```

### 规则数量门禁

- 若总 PASS 规则数 > `batch.rule_limit`：按 level 优先（FORBIDDEN > P0 > P1 > P2）+ evidence tier 优先（cross-project > single-project）+ 维度状态优先（activated > shallow > baseline,pending 维度本就不进入计数）截断，超出部分 recommended_action = `defer`。

## Self-check（移交前）

- [ ] 8 个 persona 全部执行，无跳过(P1-P8)
- [ ] 每条规则有 `quality_gate_decision` 输出
- [ ] 所有 BLOCK finding 都有 `detail` 字段说明
- [ ] conflict 规则都有完整 `debate_record`（Proposer + Challenger + Arbiter）
- [ ] `required_human_confirmation` 列表非空时，对应规则 `target_state` 不得为 `active`
- [ ] `recommended_action` 取值必须在 `references/config/frontmatter-format.md §4.7` 枚举内，无自创取值
- [ ] 没有规则被静默批准（每条决策都有 persona 结果支撑）

**双门禁与激活态相关**(U9 新增):

- [ ] activation-report schema=v1 校验通过 + run_id 一致
- [ ] 每条 quality_gate_decision 包含 `dimension_id` + `dimension_state`(取自 activation-report,不本地推断)
- [ ] Gate A 与 Gate B 都执行,`content_gate_outcome` + `activation_gate_outcome` + `final_gate_decision` 三字段齐全
- [ ] 所有 `dimension_state == pending-confirmation` 的规则最终 `recommended_action == move-to-pending`,且 `override_rationale` 写明 forced-pending
- [ ] 所有 `dimension_state == shallow` 的规则最终 `recommended_action == keep-draft-low-coverage`
- [ ] 所有被 P8 标记 `suggest_demote_to_shallow: true` 的 activated 规则在 review_report.shallow_overrides 中
- [ ] candidate_dim_summary 已透传(包含 candidate 维度 id / name / layer / trigger_when),供 merge-coordinator 写未激活地图汇总
- [ ] standard-{sub_domain}.md 不残留 `{{activation_state` 占位符(P7 已查)

## 失败模式映射

| 命中条件 | 处理 |
| --- | --- |
| evidence_tier: none 规则 > 50% | 整批标记 `INSUFFICIENT_EVIDENCE`；所有规则进入 pending-confirmation |
| P0/FORBIDDEN 无 NEG 负例 | P1 BLOCK；规则降为 P1 或进 pending-confirmation |
| 与已有 active 冲突 | P5 HARD FAIL；不得写入 standard-{sub_domain}.md；进 conflicts.md |
| industry 规则无 owner 确认 | P6 DEFER；不进 ai-rules.md 可执行段 |
| `dimension_state == pending-confirmation` 但章节出现强制规则 | P8 BLOCK + Gate B forced-pending;记 override_rationale |
| `dimension_state == shallow` 但章节缺 low-coverage warning | P8 BLOCK;返回 generation 修正 |
| `dimension_state == candidate` 但内容混入 standard 章节 | P8 BLOCK;Gate B forced-candidate-skip |
| activation-report.json 缺失或 schema 不匹配 | `ACTIVATION_REPORT_SCHEMA_INVALID`;停止评审 |
| activation-report.run_id 与当前不一致 | `ACTIVATION_REPORT_RUN_MISMATCH`;停止评审 |

## 必须做

1. 执行全部 8 个 persona（P1-P8），不得跳过或合并。
2. 对每条冲突规则执行 Proposer-Challenger-Arbiter debate 流程。
3. `recommended_action` 只能使用 `references/config/frontmatter-format.md §4.7` 的 canonical 枚举值。
4. 不得发布 `active`（那是负责人手工动作）。
5. BLOCK 级 finding 必须有具体 `detail` 和修复建议。
6. **双门禁串行执行**:Gate A 完成后才能执行 Gate B;Gate B 决议优先于 Gate A 内容决议。
7. **shallow 维度强制改判**:即使 Gate A PASS,recommended_action 必须是 `keep-draft-low-coverage`,coverage 标记必须保留。
8. **pending-confirmation 维度强制改判**:即使 Gate A PASS,recommended_action 必须是 `move-to-pending`,不得保留为 keep-draft。
9. **transparent override**:每次 Gate B 改判都要写 `override_rationale`,审计可追溯。

## 禁止做

1. 不得静默通过任何规则（无 persona 结果支撑的决策无效）。
2. 不得创造新的持久化规则状态（枚举只在 `frontmatter-format.md` 中定义）。
3. 不得把负责人确认缺失的高风险规则升级为强制执行规则。
4. 不得忽略 batch 边界检查（P7 必须执行）。
5. 不得把 project-profile 的推断当成 evidence（P1 会 BLOCK 这种情况）。
6. **不得本地重新计算维度激活态**——activation-report 是唯一权威源;dimension_state 字段必须从 report 拷贝。
7. **不得让 Gate A pass 覆盖 Gate B 的强制改判**——pending / shallow 维度的最终决议必须遵循 Gate B。
8. **不得跳过 P8 Coverage Reviewer**——这是双门禁的关键 input。
9. **不得让 candidate 维度规则进入 quality_gate_decisions[]**——candidate 内容不应出现在 standard 中,出现就是 P8 BLOCK。
