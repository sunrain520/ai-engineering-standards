# Expected Behavior

一次有效运行完成后，必须满足以下可检查结果。

## 输出结构

- 已输出修改文件列表。
- 对 broad input，已输出 `project-profile`、`extraction-map`、`batch-plan`、`ordered_batch_queue` 和 `coverage_report`，并自动按 queue 逐 batch 执行。
- 对每个 worker 调用，已记录 `selected_batch.batch_id`、`confidence_tier` 和 batch 边界。
- 已输出新增规则定位列表（`(source_doc, section_title)` 二元组）。
- 已输出新增 Evidence 条目编号列表（`EV-/POS-/NEG-/LEG-{DOMAIN}-{NUMBER}`）。
- 已输出 `Quality Gate` 结果。
- 已输出 `lineage-ledger.json` 与 `owner-decision-queue.json`。
- 已说明是否存在 `pending-confirmation`、`merge-suggestions` 或 `conflicts`。
- 如生成快速索引候选，已输出 candidate `rules-index` / `llms` / `ai-context-pack` 状态。

## Front Matter

- 新建 Markdown 文件顶部包含 YAML Front Matter。
- Front Matter 至少包含 `doc_id`、`domain`、`sub_domain`、`doc_type`、`index_format`、`indexable` 和 `tags`。
- `index_format` 为 `engineering-standards-md-v1`。
- 规则 H2 标题必须以 `P0` / `P1` / `P2` / `FORBIDDEN` 前缀开头，且与 `rules-index.json.section_title` 字面一致；**不使用 Rule ID，不使用 HTML anchor**。
- `project-profile`、`extraction-map`、`batch-plan`、`ai-context-pack` 这类运行级 Markdown artifact 默认 `indexable: false`。

## Evidence-first

- 每条 AI 可执行规则都能追溯到 `code-facts`、lineage ledger 和 `source_doc + section_title`；`auto-active` 还必须追溯到闸判据快照。
- 真实项目路径只出现在 `evidence/` 文件。
- 规则正文是团队级抽象，不写具体项目路径。
- `project-profile` 和 `extraction-map` 的推断不能直接升级为规则。

## Context Governance

- 完整项目 / 完整仓库 / 多服务 / 未知域输入默认进入 `full-auto`，内部第一步是 `profile-first`。
- `profile-first` 生成画像、extraction map、batch plan、`ordered_batch_queue`、`coverage_report` 和代表性文件候选。
- `ready` 与 `pending-confirmation` 进入 ordered queue；`skipped` / `blocked` 只进入 coverage report。
- `batch-extraction` 必须选择一个 batch，且只读取该 batch 的 candidate files 和必要邻近文件。
- selected-batch 公开路径必须使用 `generation_profile: phase1-selected-batch`，不要求 `activation-report`，不读取 `dimension-activator`。
- batch 必须包含 `domain`、`sub_domain`、`module` 或 `task_type`、`candidate_files`、`excluded_paths`、`evidence_limit`、`rule_limit`、`stop_conditions`。
- 命中 stop condition 后停止，不扩大到完整项目读取。

## Fast Index Candidates

- `rules-index` 候选使用 `title`、`domain`、`sub_domain`、`level`、`status`、`source_doc`、`section_title`、`evidence_doc`、`authority_scope`、`upgrade_mode`、`tags`。
- `rules-index` 候选不包含 `rule_id` 或 `anchor`。
- `llms` 候选不默认覆盖根 `llms.txt`。
- `ai-context-pack` 必须引用 `source_doc + section_title`。

## 状态边界

- AI 默认执行路径只允许 `status: auto-active` 或 `status: owner-confirmed-active`。
- 新萃取规则不得自动写 `owner-confirmed-active`；只有通过 BR-016/BR-017 闸的规则可自动写 `auto-active`。
- `draft`、`pending-confirmation`、`stale-auto-active`、`owner-rejected`、`conflict`、`legacy-compatible`、`rejected` 不进入 AI 默认执行路径。
- `recommended_action` 取值必须在 `references/config/frontmatter-format.md §4.7` 枚举内(`auto-activate` / `keep-draft` / `keep-draft-low-coverage` / `move-to-pending` / `mark-conflict` / `mark-legacy` / `mark-stale-auto-active` / `mark-owner-rejected` / `reject` / `defer`),只作为建议,不是 owner 确认状态。
- `owner-decision-queue.json` 的队列动作必须使用 `owner_queue_action`，取值来自 `output-artifact-contract.json.owner_queue_actions`；不得复用规则级 `recommended_action`。

## AE-17 Auto-active Gate

- 满足 `deterministic_occurrence_count >= 2`、`confidence: high`、多角色/多文件覆盖、evidence 充分、无未裁定 conflict、结构完整、未命中 `anti-pattern-blocklist.yaml`、非高风险域的规则可标 `auto-active`。
- `auto-active` 规则必须写入 `authority_scope: this-repo`、`upgrade_mode: auto-active`、`last_evidence_confirmed_run`，并在 lineage ledger 记录闸判据快照。
- 命中黑名单或 high-risk domain 的规则即使高频也必须降 `pending-confirmation`。
- review summary 必须标明 auto-active 只证明本项目代表性，不证明行业最佳实践。

## AE-18 Owner Rejection And Stale Exit

- owner 否决 auto-active 后，规则标 `owner-rejected`，下次运行不得重新进入 AI 默认执行路径。
- auto-active 复检不再满足 BR-016/BR-017 时，标 `stale-auto-active`，从 `ai-rules.md §2` / review checklist 默认执行段移出，并进入 owner queue。
- `owner-confirmed-active` 的退出仍需 owner 决策，full-auto 不得自动降级。

## Append-only

- 不覆盖已有 `owner-confirmed-active` / legacy `active`。
- 不覆盖已有 `draft`。
- 同一规则（按 `(source_doc, section_title)` 二元组识别）只追加 evidence 或 merge suggestion。
- 重复运行同一仓库时，existing_index 对齐后只标注 `added`、`evidence-changed`、`superseded` 或 `stale-active-needs-owner-review`，不得堆积近义重复规则。
- low-confidence pending 条目被新 standard 承接时，pending 条目追加 `superseded_by`，coverage 去重。
- 冲突进入 `conflicts.md`。

## 安全

- 不读取、不复制密钥、token、私钥、生产凭据原值。
- 敏感文件只记录脱敏存在事实。
- 输出报告必须说明敏感文件处理策略。
- SKILL.md 的 `Inputs` 与公开稳定流程不暴露 `output_action` / `restore_from` / `keep`。
- `output_action != append` 必须带显式 maintainer / repair-only 上下文，否则触发 `MAINTAINER_CONTEXT_REQUIRED`。
- 普通 `profile-first` / `batch-extraction` 公开路径不得进入 backup-manager 或调用 maintainer 脚本。

## 成功标准:不要用过程指标度量

过程指标会让团队朝错误方向用力——盯着"AI 生码率""规则产出数"这种数字,容易陷入"灌水换分"的陷阱,而真正决定 Skill 价值的,是规则被复用、被拦截、被升级的程度。

本 Skill 的成功**不应**用以下过程指标衡量:

- ❌ 单次运行萃取了多少条规则
- ❌ standard-*.md 总行数 / Front Matter 字段数 / evidence 条目数
- ❌ AI 在生成代码时多快引用了规则

本 Skill 的成功**应**用以下结果指标衡量:

- ✅ 萃取规则中有多少通过高置信闸进入 `auto-active`,以及有多少被领域负责人确认为 `owner-confirmed-active`(资产化率)
- ✅ AI 在新一轮编码任务里命中并正确执行了多少条 `auto-active` / `owner-confirmed-active` evidence-backed 规则(被复用率)
- ✅ Code Reviewer 用 review-checklist 拦下了多少违反团队规范的 PR(拦截价值)
- ✅ 同一类反范式(NEG-* evidence)在后续提交中复发率是否下降(规范有效性)

设计原因:**代码一旦生产出来,首先是负债**——同理,规范一旦生产出来,首先也是潜在文档负担,只有被复用、被拦截、通过高置信闸或 owner 确认进入默认执行路径的规则才转化为资产。Skill 的所有质量门禁、Self-check、append-only、`auto-active` 闸、`owner-confirmed-active` 人工边界都是为这个原则服务,不是为了多产出文档。
