# project-standard-extractor Quality Gate

本文件是 `review-and-quality-gate` agent 的 **single source of truth**——所有评审 persona 的判定、汇总规则、失败模式都以本文件为准。Skill workflow 与全局 `engineering-standards/00-global/references/quality-gate.md`(canonical policy) 协同；本文件只描述 Skill 内部双门禁清单与执行链路,不重复 canonical policy 的策略表述。

## 0. 总览

```
┌──────────────────────────────────────────────────────┐
│ Gate A: Content Gate(R41–R46)                        │ ← P1–P7 + P8 内容评审聚合
│  评审"规则内容是否合格"                              │
│  9 项门禁 = 证据 / 团队抽象 / AI 可执行 / Review 可检 │
│             / 冲突 / 行业风险 / 正反例 / 数量 / 人工确认 │
└──────────────────────┬───────────────────────────────┘
                       │ 任一 BLOCK → 拒绝进入 draft
                       ▼
┌──────────────────────────────────────────────────────┐
│ Gate B: Activation Gate(R53)                         │ ← P8 Coverage + activation-report.v1
│  评审"激活态是否与内容决议一致"                      │
│  4 项门禁 = baseline / activated / candidate / shallow│
└──────────────────────┬───────────────────────────────┘
                       │ 任一冲突 → 强制改判
                       ▼
              quality_gate_decision (final)
```

**铁律**：Gate B 决议**优先**于 Gate A——即使 Gate A 全部 PASS,Gate B 触发的强制改判必须落实(pending → move-to-pending；shallow → keep-draft-low-coverage)。

## 1. Gate A · 内容门禁清单(R41–R46,第一阶段保留)

来源：第一阶段 plan(`docs/plans/2026-05-21-001-feat-project-standard-extractor-plan.md`)R41–R46 + R7。每条规则评审完成后必须给出 `outcome ∈ {pass, warn, block}`,任一 BLOCK → 拒绝进入 draft。

### 1.1 G1·证据门禁(R41)

**职责**:每条规则必须至少 1 条 evidence,且 evidence 来自当前 batch 选定 candidate_files,不得越界。

**Persona**:Evidence Auditor (P0,Generation 自检) + Conflict Reviewer (P5)

**判定细项**:

- [ ] 每条规则在 evidence 文档中能找到至少 1 条 `(file_path, line, snippet, kind)` → 缺 → **BLOCK**
- [ ] evidence path 在 batch.candidate_files 范围内 → 越界 → **WARN**(WARN 累计 ≥ 3 → BLOCK)
- [ ] evidence kind 与规则类型一致(positive / forbidden / legacy) → 不一致 → **BLOCK**
- [ ] evidence 不读密钥 / token / 生产配置 → 命中 → **REJECT**

### 1.2 G2·团队级抽象门禁(R42)

**职责**:规则必须是团队级行为约束,不是项目特有 hack 或一次性补丁。

**Persona**:Team Standard Reviewer (P1)

**判定细项**:

- [ ] 规则文案不含"本项目""本仓""xx 服务"等单项目专属语 → 命中 → **WARN**
- [ ] 规则在多项目运行下若仅 1 个项目命中 → 走 Cross-Project Aggregator 的 partial_activated 处理(不直接 BLOCK,但写入差异说明)
- [ ] 规则不属于 `pending-confirmation`、`legacy-compatible`(如属 → 标记对应 target_state,不进 active)

### 1.3 G3·AI 可执行性门禁(R43)

**职责**:`ai-rules.md` 中每条规则须能被 LLM 转成可执行 prompt(明确动作、明确输入、明确输出)。

**Persona**:AI Executability Reviewer (P2)

**判定细项**:

- [ ] 规则有动词开头的执行指令(必须做 / 禁止做 / 应当 / 不得) → 缺 → **BLOCK**
- [ ] 规则文中所有引用的 path / pattern / config key 在 evidence 中可验证 → 不可验证 → **WARN**
- [ ] 规则不含含糊词("酌情""适当""尽量") → 命中 → **WARN**

### 1.4 G4·Review 可检查性门禁(R44)

**职责**:`review-checklist.md` 每条 checkbox 须能被人工或工具 yes/no 判定。

**Persona**:Review Checklist Reviewer (P3)

**判定细项**:

- [ ] 每条 checklist 项可以转化为 `grep / lint / 编译 / 二选一` 检查 → 不可 → **BLOCK**
- [ ] 不出现"代码风格良好""可读性强"等主观项 → 命中 → **BLOCK**

### 1.5 G5·正反例门禁(R45)

**职责**:每条 P0 / FORBIDDEN 规则必须配 ≥ 1 正例 + ≥ 1 反例(或来源 evidence 文档脱敏引用)。

**Persona**:Example Reviewer (P0 子任务,Generation 自检)

**判定细项**:

- [ ] P0 / FORBIDDEN 规则正反例齐备 → 缺 → **BLOCK**
- [ ] P1 规则至少 1 个示例(正或反) → 缺 → **WARN**
- [ ] P2 规则可省示例 → N/A

### 1.6 G6·规则数量门禁(R46)

**职责**:单 batch 输出规则数 ≤ batch.rule_limit;超出按优先级截断。

**Persona**:Quality Gate 聚合阶段

**判定细项**:

- [ ] 总 PASS 规则数 ≤ batch.rule_limit → 超出 → 按优先级截断(FORBIDDEN > P0 > P1 > P2 + cross-project evidence > single-project evidence + activated > shallow > baseline) + 超出部分 `recommended_action = defer`
- [ ] 同一 section_title 重复规则去重(保留 evidence 数最多者) → 重复 → **WARN**

### 1.7 G7·人工确认门禁(R7)

**职责**:`pending-confirmation.md` 中所有项必须有明确确认对象 + 触发条件 + fallback。

**Persona**:Quality Gate 聚合阶段

**判定细项**:

- [ ] pending-confirmation 项含 `confirm_owner / confirm_question / fallback_action` → 缺 → **BLOCK**
- [ ] pending-confirmation 项不进 `ai-rules.md` 与 `review-checklist.md` → 越界 → **BLOCK**

### 1.8 G8·冲突门禁

**职责**:新规与既有 active / draft 规则不冲突,冲突进入 Proposer-Challenger-Arbiter 仲裁。

**Persona**:Conflict Reviewer (P5)

**判定细项**:

- [ ] 新规与现存同 section 规则不矛盾 → 矛盾 → 进入 debate_records,target_state = `conflict`
- [ ] 同一规则在 standard-common.md 与 standard-{sub_domain}.md 之间不重复 → 重复 → **BLOCK**

### 1.9 G9·行业风险门禁

**职责**:行业域(securities / 医疗 / 金融 etc.)规则必须经行业 owner 确认,否则只能进 pending。

**Persona**:Industry Risk Reviewer (P6)

**判定细项**:

- [ ] industry domain 规则有 owner 签字 evidence → 缺 → 强制 `target_state = pending-confirmation`,`recommended_action = move-to-pending`
- [ ] 行业风险规则不直接进 ai-rules.md 主体(进 pending 区) → 越界 → **BLOCK**

## 2. Gate B · 维度激活门禁清单(R53,本期新增)

来源:Phase 2 plan R53 + R69 + R81。Gate B 输入是 `activation-report.v1` + P8 Coverage Reviewer 输出。每个维度按 `state` 字段进入对应门禁通道。

### 2.1 baseline 维度门禁

**state**:`baseline`(端 / 行业 baseline 维度,无需 signal 命中即默认激活)

**判定细项**:

- [ ] baseline 维度对应章节内容能在 `references/config/dimension-framework/baseline-dimensions.yaml` 的 default 文案中找到起源 → 杜撰 → **BLOCK**
- [ ] baseline 维度若 `evidence_count == 0` 且无端负责人显式确认 → **强制改判** `target_state = pending-confirmation` + `recommended_action = move-to-pending`(不得直接进 draft)
- [ ] baseline 维度若有端负责人显式确认(写入 owner_confirmations 字段) → 可降级 `target_state = draft`,coverage 标 `candidate_with_warning`

### 2.2 activated 维度门禁

**state**:`activated`(signal 命中 + R3 规则判定为激活)

**判定细项**:

- [ ] activated 维度章节至少 1 条 evidence(file_path + line) → 缺 → **BLOCK**
- [ ] activated 维度 `depth_score ≥ depth_indicator.yaml` 端 / 维度阈值 → 不达 → P8 输出 `suggest_demote_to_shallow: true` → Gate B 改判 `shallow`
- [ ] activated 维度对应章节明确写入 `[activated]` 标记,与 activation-report.dimensions[].dimension_id 一一对应 → 孤儿 → **BLOCK**

### 2.3 candidate 维度门禁

**state**:`candidate`(信号弱 / 候选,未达激活阈值)

**判定细项**:

- [ ] candidate 维度**不得**出现在 `standard-{sub_domain}.md` 章节主体 → 出现 → **BLOCK**
- [ ] candidate 维度必须出现在 `standard-overview.md §9 未激活维度地图` → 缺 → **BLOCK**(AE7)
- [ ] candidate 维度**不得**收录到 `ai-rules.md` 与 `review-checklist.md` → 收录 → **BLOCK**
- [ ] §9 candidate 条目附 `trigger_when` 字段(说明何时升级激活) → 缺 → **WARN**

### 2.4 shallow 检测门禁(activated 派生)

**state**:`shallow`(原 activated 但 depth 不达阈值,Gate B 改判)

**判定细项**:

- [ ] shallow 维度章节首行有 `> ⚠️ 本节 coverage=low` warning → 缺 → **BLOCK**
- [ ] shallow 维度规则的 inline 元数据行 `recommended_action == keep-draft-low-coverage` → 不一致 → **BLOCK**
- [ ] shallow 维度**进入** `standard-{sub_domain}.md` 章节(走完整评审,不像 candidate 那样剔除),但保留 coverage 标记
- [ ] shallow 维度规则**进入** `ai-rules.md`(因为 Gate A 已通过),但 `review-checklist.md` 标 `low-coverage` → 不标 → **WARN**

### 2.5 pending-confirmation 维度门禁

**state**:`pending-confirmation`(信号矛盾 / 需 owner 确认)

**判定细项**:

- [ ] pending 维度规则**不得**出现在 standard-{sub_domain}.md / ai-rules.md / review-checklist.md → 出现 → **BLOCK**
- [ ] pending 维度内容写入 `pending-confirmation.md`,含 `confirm_owner / confirm_question / fallback_action` → 缺字段 → **BLOCK**
- [ ] Gate B 强制改判:`target_state = pending-confirmation`、`recommended_action = move-to-pending`(无论 Gate A 内容决议如何)

## 3. 双门禁汇总规则

### 3.1 串行执行

1. Gate A 先行：8 persona(P1–P7 + P8) 各自输出 finding(`pass / warn / block`)。
2. Gate A 聚合：任一 persona BLOCK → `content_gate_outcome = hard-fail`,规则不得进入 draft。
3. Gate B 后置：读取 `activation-report.v1.dimensions[]` + P8 Coverage 的 `suggest_demote_to_shallow`,按 §2 强制改判表决议。
4. 最终 `final_gate_decision`：Gate B 改判 → 最终决议；Gate B 沿用 Gate A → Gate A 决议。

### 3.2 强制改判优先级表

| dimension_state | P8 suggest_demote_to_shallow | activation_gate_outcome | final target_state | final recommended_action |
| --- | --- | --- | --- | --- |
| `activated` | false | `pass` | 沿用 Gate A | 沿用 Gate A |
| `activated` | true (深度未达) | `forced-low-coverage` | `draft` | `keep-draft-low-coverage` |
| `shallow` | — | `forced-low-coverage` | `draft` | `keep-draft-low-coverage` |
| `pending-confirmation` | — | `forced-pending` | `pending-confirmation` | `move-to-pending` |
| `baseline`(无 owner 确认 + 0 evidence) | — | `forced-pending` | `pending-confirmation` | `move-to-pending` |
| `baseline`(其它情况) | — | `pass` | `draft` | `keep-draft` |
| `candidate` | — | `forced-candidate-skip` | (该规则**不应在 standard 中**,P8 阶段已 BLOCK,不进 quality_gate_decisions[]) | — |

### 3.3 Confidence 计算

```
high   = 8/8 personas pass 或 WARN 仅在 P2/P6 + Gate B 维度为 activated
medium = 6-7/8 personas pass,BLOCK ≤ 1 且已标注修复路径,或 shallow / pending 强制改判后内容仍质量良好
low    = ≤ 5/8 personas pass 或有 BLOCK 且不可修复,或 candidate 维度误植入端规范
```

### 3.4 跨项目模式扩展

多项目(`len(project_paths) > 1`)运行时,Gate B 输入由 `unified-activation-map.v1.dimensions[].unified_state` 接管,而非单项目 activation-report.state。具体见 `references/agents/cross-project-aggregator.md` 与 `references/agents/merge-coordinator.md §跨项目合并扩展`。本文件门禁列表本身不变,只是 dimension_state 取值多一种 `partial_activated`,处理路径:

- `partial_activated` 维度：写入 `evidence/project-specific-divergence.md` 与横切维度文件 §3 子领域差异列；**不**进入 standard.md §1/§2 主体；标 `⚠️ 待人工裁定`;Gate B 输出 `forced-pending`(团队规范层视为待裁定)。
- 非 partial_activated 的 unified_state(`activated / shallow / candidate / baseline / pending-confirmation`):按 §3.2 表正常处理。

## 4. 失败模式与人工确认链路

### 4.1 Gate A 失败模式

| 失败模式 | 处置 | 升级路径 |
| --- | --- | --- |
| 规则缺 evidence(G1 BLOCK) | 拒绝进入 draft;标 `target_state = pending-confirmation` | 上游 generation 补 evidence 后重评 |
| 规则文案不可执行(G3 BLOCK) | 拒绝进入 draft;返回 generation 重写 | 重写后重评 |
| Review checklist 不可检查(G4 BLOCK) | 拒绝进入 draft;返回 generation 重写 | 重写后重评 |
| 行业域无 owner 确认(G9) | 强制 `pending-confirmation`,写入 `confirm_owner = TBD` | 等待行业 owner 签字 → 复评 |
| 规则冲突(G8) | `target_state = conflict`,进入 debate_records | Proposer-Challenger-Arbiter 仲裁 → 重评 |
| 规则数量超 batch.rule_limit(G6) | 按优先级截断,超出部分 `defer` | 后续 run 处理低优先级规则 |

### 4.2 Gate B 失败模式

| 失败模式 | 处置 | 升级路径 |
| --- | --- | --- |
| baseline 维度 0 evidence + 无 owner 确认 | 强制 `move-to-pending`;在 pending-confirmation.md 留确认入口 | 端负责人确认 → 重评 |
| activated 维度 depth 不达阈值 | 强制改判 `shallow` + `keep-draft-low-coverage`;章节标 coverage=low | depth_score 提升后(下一次 run)自动恢复 activated |
| candidate 维度内容混入 standard-*.md | P8 BLOCK,要求 generation 移除该章节并写入 §9 | 移除后重评 |
| pending-confirmation 维度任意进入主体文件 | P8 BLOCK,要求 generation 移除并写入 pending-confirmation.md | 移除后重评 |
| activation-report 与 standard.md 章节孤儿(找不到 dimension_id) | P8 BLOCK,要求 generation 修复或上游 dimension-activator 复跑 | 修复后重评 |
| 多项目 partial_activated 维度无人工裁定 | 强制 `forced-pending` + ⚠️ 待人工裁定;写入 divergence.md §4 团队规范裁定表 | 团队 owner 在 divergence.md §4 填写裁定 → 下次 run 重评 |

### 4.3 人工确认链路

所有 Gate A / Gate B 触发的 `pending-confirmation` 必须有完整的 5 字段:

```yaml
pending_item:
  rule_locator: "{source_doc}#{section_title}"
  dimension_id: ""                # 来自 activation-report.v1
  confirm_owner: ""               # 端负责人 / 行业 owner / 项目负责人
  confirm_question: ""            # 一句话:让 owner 回答的具体问题
  fallback_action: ""             # 若 owner 未在 SLA 内确认,采取的默认行为
  triggered_gate: ""              # gate-a-{G编号} / gate-b-{state}
  triggered_at: "{ISO8601}"
```

三类人工确认链路:

1. **端 baseline 确认**:`confirm_owner = 端负责人`,`fallback_action = 维持 pending,下次 run 自动复评`。
2. **行业风险确认**:`confirm_owner = 行业域 owner`,`fallback_action = 排除该规则,只在 evidence 留痕`。
3. **跨项目差异裁定**:`confirm_owner = 团队规范 owner`,`fallback_action = 维持 partial_activated,不入 standard.md 主体`,裁定结果写入 `evidence/project-specific-divergence.md §4 团队规范裁定`。

### 4.4 状态建议(canonical 兼容)

`recommended_action` 取值见 canonical `engineering-standards/00-global/references/quality-gate.md` + `references/config/frontmatter-format.md §4.7`,**不得**自创枚举(包括 "consider promotion" / "evaluate later" 等):

| 触发条件(汇总 Gate A + Gate B) | target_state | recommended_action |
| --- | --- | --- |
| Gate A pass + Gate B pass | `draft` | `keep-draft` |
| Gate A pass + Gate B forced-low-coverage | `draft` | `keep-draft-low-coverage` |
| Gate A pass + Gate B forced-pending | `pending-confirmation` | `move-to-pending` |
| Gate A pass + Gate B forced-candidate-skip | (规则不入 standard,P8 已 BLOCK) | — |
| Gate A 任一 BLOCK | `pending-confirmation` 或 `rejected` | `move-to-pending` 或 `reject` |
| Gate A 冲突(G8) | `conflict` | `mark-conflict` |
| Gate A 历史包袱保留 | `legacy-compatible` | `mark-legacy` |
| 规则数量超限(G6 截断超出部分) | 维持原状 | `defer` |
| 已有负责人签字 + 无冲突 + Gate B pass | `draft` | `promote-to-active`(由负责人手动改 status,Skill 不自动发布) |

## 5. 输出格式

```yaml
quality_gate_decision:    # 每条规则一个决议,由 review-and-quality-gate.merge_summary 合并
  source_doc: ""
  section_title: ""               # 与 standard.md H2 字面一致
  dimension_id: ""                # 关联 activation-report.dimensions[].dimension_id
  dimension_state: ""             # baseline / activated / candidate / pending-confirmation / shallow / partial_activated
  passed: false
  target_state: ""                # draft / pending-confirmation / conflict / legacy-compatible / rejected
  recommended_action: ""          # keep-draft / promote-to-active / move-to-pending / mark-conflict / mark-legacy / reject / defer / keep-draft-low-coverage
  confidence: ""                  # high / medium / low
  content_gate_outcome: ""        # pass / conditional / soft-fail / hard-fail / reject(Gate A)
  activation_gate_outcome: ""     # pass / forced-pending / forced-low-coverage / forced-candidate-skip(Gate B)
  final_gate_decision: ""         # 二者综合后的最终决议
  evidence_result: ""             # G1
  team_standard_result: ""        # G2
  ai_executability_result: ""     # G3
  review_checklist_result: ""     # G4
  example_result: ""              # G5
  rule_count_result: ""           # G6
  human_confirmation_result: ""   # G7
  conflict_result: ""             # G8
  industry_risk_result: ""        # G9
  baseline_gate_result: ""        # §2.1
  activated_gate_result: ""       # §2.2
  candidate_gate_result: ""       # §2.3
  shallow_gate_result: ""         # §2.4
  pending_gate_result: ""         # §2.5
  required_human_confirmation: [] # 触发 §4.3 链路时填充
```

## 5.5 Force Rebuild 模式下双门禁失败的回滚链路

`output_action = force-rebuild` 模式下,Quality Gate 双门禁失败 / merge-coordinator final_status 异常会被 `references/agents/backup-manager.md` step 10 dispatcher 转译为 atomic rollback,而不是仅写 `pending-confirmation`:

| 触发信号(精确 line-level grep) | backup-manager 行为 | CHANGELOG | `.broken-<ts>` |
| --- | --- | --- | --- |
| `quality_gate_decisions[].status: blocked` 任一行命中 | 跳过 validate.sh,直接反向 atomic rename | **不**追加 | mv 回原 `<domain>` 后删 |
| `quality_gate_decisions[].status: conflict` 任一行命中 | 同上 | **不**追加 | 同上 |
| `merge_summary.final_status: failed` | 同上 | **不**追加 | 同上 |
| `merge_summary.final_status: partial` | 同上(force-rebuild 严格模式不接受 partial) | **不**追加 | 同上 |
| `force-rebuild-validate.sh exit 1`(determ check 失败) | 写 failure.log 后反向 atomic rename | **不**追加 | 同上 |
| `force-rebuild-validate.sh exit 2`(runtime error) | 写 failure.log + `VALIDATE_SCRIPT_RUNTIME_ERROR` 后反向 atomic rename | **不**追加 | 同上 |
| changelog-append helper 失败(success path 末段) | **特例**:`mv <domain> <domain>.changelog-fail-<now>` + `cp -a backup_dir/. <domain>/` | **不**追加(回炉到旧版本) | step 10a 中段已删,不再处理 |

**铁律**:

1. 任意失败路径**必须**释放 domain lock(`rmdir .lock`)
2. failure.log 必须用 magic header `force-rebuild-failure.v1`
3. manifest.rollback 段必须含 `rolled_back_at / failure_reason / failure_log_path / validation_failure`
4. `in-progress.lock` 残留**不**自动清(host developer 看到 `lock` 残留即失败信号)
5. status 字段在 `review-and-quality-gate.md` 输出中**必须**写在独立行(canonical 枚举: `ok` / `blocked` / `conflict`),不得 inline comment / code block;以保证 grep `^[[:space:]]*status:[[:space:]]*(blocked|conflict)` 命中确定性

详见 `references/agents/backup-manager.md §10.0 dispatcher` + `references/prompts/orchestrator/force-rebuild/force-rebuild.md §rollback`。

## 6. 引用与协同

- 全局 canonical:`engineering-standards/00-global/references/quality-gate.md`
- Skill 内执行 agent:`references/agents/review-and-quality-gate.md`(P1–P8 评审执行)
- Skill 内合并 agent:`references/agents/merge-coordinator.md`(消费 quality_gate_decisions[])
- 输入文档:`temp/{run_id}-activation-report.json`(schema=activation-report.v1)
- 多项目模式输入:`temp/{run_id}-unified-activation-map.json`(schema=unified-activation-map.v1)
- 深度阈值:`references/config/dimension-framework/depth-indicator.yaml`
- baseline 维度池:`references/config/dimension-framework/baseline-dimensions.yaml`

## 7. 自检清单(Quality Gate agent 移交前必查)

- [ ] Gate A 9 项门禁(G1–G9)每条规则都有 outcome 标注
- [ ] Gate B 5 项门禁(baseline / activated / candidate / shallow / pending)按 dimension_state 分流
- [ ] 任一 BLOCK → 拒绝进入 draft
- [ ] 强制改判表(§3.2)落实:shallow → keep-draft-low-coverage,pending → move-to-pending
- [ ] candidate 维度规则不出现在 standard-*.md / ai-rules.md / review-checklist.md
- [ ] §9 未激活维度地图存在(即使 candidate=0 也保留章节)
- [ ] 多项目 partial_activated 维度走 §3.4 路径,不进 standard.md 主体
- [ ] required_human_confirmation 字段在所有 forced-pending 规则上填充
- [ ] recommended_action 取值在 canonical 枚举内,无自创值
