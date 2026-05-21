# Workflow

## 1. 总览

```text
project_paths
  -> intake-and-scope
  -> project-profile
  -> extraction-map
  -> batch-plan
  -> selected-batch facts-and-classification
  -> generation
  -> review-and-quality-gate
  -> merge-coordinator
  -> standards docs + evidence + candidate index artifacts
```

`project-standard-extractor` 允许用户输入完整项目、完整仓库或多个服务路径，但执行必须先把大输入压缩为小批次。广范围输入只允许进入 `profile-first`，不得直接读取完整代码并生成 `standard.md`。

## 2. 萃取模式

| extraction_mode | 适用输入 | 允许输出 | 禁止事项 |
| --- | --- | --- | --- |
| `profile-first` | 完整项目、完整仓库、多服务、未知域或 broad scope | `project-profile`、`extraction-map`、`batch-plan`、代表性文件候选 | 不生成正式规范规则 |
| `batch-extraction` | 已选择一个 batch | `code-facts`、classification、规范草案、evidence、候选索引产物 | 不跨 batch 读取源码 |
| `focused-module` | 用户已经给出模块级窄范围 | scoped facts、classification、规范草案 | 不跳过敏感文件和 evidence 边界 |
| `review-only` | 已有萃取产物待评审 | review report、quality gate decision | 不新增规则 |
| `merge-only` | 已有人确认的候选待合并 | append-only merge summary | 不覆盖已有规则 |

默认判定：

1. `project_paths` 包含仓库根、多个服务、多个端、未知研发域或用户说“完整项目 / 全仓 / 多服务”时，强制 `profile-first`。
2. 只有用户提供 focused module 或已选择 `batch_id` 时，才允许进入 `focused-module` 或 `batch-extraction`。
3. `profile-first` 的输出是后续执行输入，不是团队规范规则。

## 3. 阶段 1：Intake and Scope

输入：

- `project_paths`
- `extraction_mode`（可由 Skill 推断）
- 用户选择或自动推断的研发域
- 行业场景
- 输出范围
- 已有规范或参考文档

输出：

- `scope_summary`
- `run_id`
- `extraction_mode`
- `domain_selection`
- `sub_domain_matrix`
- `sensitive_file_policy`
- `output_targets`

要求：

1. 如果用户只给项目路径，先推断研发域、输入规模和 `extraction_mode`，再逐项确认。
2. 如果推断和用户选择冲突，记录为 scope conflict 并让用户确认。
3. 敏感文件只允许记录路径类别和存在事实。
4. 广范围输入必须转入阶段 2 的 `project-profile`，不得进入 generation。

## 4. 阶段 2：Project Profile

输入：

- `scope_summary`
- `project_paths`
- `config/context-governance.md`
- `config/domain-sampling-adapters.md`

输出：

- `{run_id}-project-profile.md`

要求：

1. 只读取项目结构、清单、配置类别、目录命名和少量代表性文件候选。
2. 输出项目画像：路径列表、推断研发域、子领域、行业候选、敏感文件策略、候选模块、需要确认的问题。
3. 不输出正式规则结论。
4. 不复制完整源码片段，不读取密钥、token、私钥、生产凭据原值。

## 5. 阶段 3：Extraction Map and Batch Plan

输入：

- `{run_id}-project-profile.md`
- 研发域和子领域候选
- `config/extraction-batch-policy.md`
- `config/domain-sampling-adapters.md`

输出：

- `{run_id}-extraction-map.md`
- `{run_id}-batch-plan.md`

batch 必须包含：

- `batch_id`
- `domain`
- `sub_domain`
- `module` 或 `task_type`
- `candidate_files`
- `excluded_paths`
- `evidence_limit`
- `rule_limit`
- `stop_conditions`
- `status`

要求：

1. batch 是正式萃取的最小执行边界。
2. 每个 batch 只列代表性文件候选，不承诺读取全部文件。
3. 没有代表性 evidence 候选的 batch 标为 `pending-confirmation` 或 `skipped`。
4. 用户或调用方必须选定一个 batch 后，才能进入阶段 4。

## 6. 阶段 4：Selected-Batch Facts and Classification

输入：

- 选定的 `batch_id`
- `{run_id}-project-profile.md`
- `{run_id}-extraction-map.md`
- `{run_id}-batch-plan.md`
- 选定 batch 的 `candidate_files`
- 已有规范和文档

输出：

- `evidence/code-facts.md`
- `evidence/positive-examples.md`
- `evidence/forbidden-examples.md`
- `evidence/legacy-compatible.md`
- `classification`

分类桶：

- `recommended`
- `forbidden`
- `legacy-compatible`
- `pending-confirmation`
- `conflict`

要求：

1. 只读取选定 batch 的候选文件和必要邻近文件。
2. 先写事实，不直接写规则。
3. 对每条事实标明推导边界、证据强度、所属 batch 和敏感信息处理。
4. 不读取或复制 secret、token、private key、生产凭据。
5. 如果读取预算用尽，停止并记录 `stop_condition`，不得扩大到全项目读取。

## 7. 阶段 5：Generation

输入：

- `code-facts`
- `classification`
- 选定 batch 摘要
- `domain-taxonomy`
- 全局模板

输出：

- `standard.md`
- `ai-rules.md`
- `review-checklist.md`
- 带 YAML Front Matter 的 Markdown 文档
- `evidence/*`
- 候选 `rules-index` / `llms` / `ai-context-pack` 产物

要求：

1. 每个输出 Markdown 顶部必须符合 `config/frontmatter-format.md`。
2. 规则正文不写具体路径。
3. 规则必须带 `status`、`level`、`source_kind`、`evidence_tier`、`risk_tag`、`recommended_action`(可选: `conflicts_with`、`superseded_by`),取值符合 `config/frontmatter-format.md §4` 枚举。
4. AI Rules 必须说明 draft / high-risk / pending 的使用边界。
5. Review Checklist 必须能被 reviewer 判断。
6. 规则 H2 标题必须满足 `^(P0|P1|P2|FORBIDDEN) ` 前缀，且与 `rules-index.json.section_title` 字面一致；**不使用 Rule ID，不使用 HTML anchor**。规则跨文档引用统一为 `{source_doc}「{section_title}」` 二元组。
7. 候选 `rules-index` / `llms` / `ai-context-pack` 只作为人工合并建议，除非用户明确要求发布根级文件。

## 8. 阶段 6：Review and Quality Gate

输入：

- 生成的规则、evidence、候选索引产物。

输出：

- `review_report`
- `quality_gate_decision`
- `recommended_action`

评审面：

1. Evidence Auditor。
2. Team Standard Reviewer。
3. AI Executability Reviewer。
4. Review Checklist Reviewer。
5. Conflict Reviewer。
6. Industry Risk Reviewer。
7. Context Governance Reviewer。

要求：

1. Quality Gate 只能给状态建议，不能发布 `active`。
2. 无 evidence 规则进入 `pending-confirmation`。
3. 冲突规则进入 `conflicts.md`。
4. 审查必须确认生成阶段没有突破 batch 边界。

## 9. 阶段 7：Merge Coordinator

输入：

- `quality_gate_decision`
- 现有规范目录。
- 候选索引产物。

输出：

- append-only 文档变更。
- `rules-index` / `llms` / `ai-context-pack` 候选合并建议。

规则：

1. 不覆盖已有 `active`。
2. 不覆盖已有 `draft`。
3. 新 evidence 追加到 `evidence/`。
4. 相近规则写入 `merge-suggestions.md`。
5. 冲突写入 `conflicts.md`。
6. 待确认写入 `pending-confirmation.md`。
7. 候选索引产物必须标记 candidate，不得默认发布为正式 `.index/rules-index.json` 或根 `llms.txt`。

## 10. 完成标准

一次萃取完成必须输出：

- 修改文件列表。
- `extraction_mode` 和 batch 边界说明。
- 新增规则定位列表（`source_doc + section_title`）。
- evidence 列表。
- Quality Gate 结果。
- 是否存在 `pending-confirmation` 或 `conflict`。
- 候选 `rules-index` / `llms` / `ai-context-pack` 产物状态。
- AI 使用警告。
- 负责人确认项。
