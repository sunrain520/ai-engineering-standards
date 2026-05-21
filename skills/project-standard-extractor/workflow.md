# Workflow

## 1. 总览

```text
project_paths
  -> intake-and-scope
  -> facts-and-classification
  -> generation
  -> review-and-quality-gate
  -> merge-coordinator
  -> standards docs + evidence
```

## 2. 阶段 1：Intake and Scope

输入：

- `project_paths`
- 用户选择或自动推断的研发域
- 行业场景
- 输出范围
- 已有规范或参考文档

输出：

- `scope_summary`
- `domain_selection`
- `sub_domain_matrix`
- `sensitive_file_policy`
- `output_targets`

要求：

1. 如果用户只给项目路径，先推断研发域，再逐项确认。
2. 如果推断和用户选择冲突，记录为 scope conflict 并让用户确认。
3. 敏感文件只允许记录路径类别和存在事实。

## 3. 阶段 2：Facts and Classification

输入：

- `scope_summary`
- 项目代码路径
- 已有规范和文档

输出：

- `code-facts`
- `positive-examples`
- `forbidden-examples`
- `legacy-compatible`
- `classification`

分类桶：

- `recommended`
- `forbidden`
- `legacy-compatible`
- `pending-confirmation`
- `conflict`

要求：

1. 先写事实，不直接写规则。
2. 对每条事实标明推导边界和证据强度。
3. 不读取或复制 secret、token、private key、生产凭据。

## 4. 阶段 3：Generation

输入：

- `code-facts`
- `classification`
- `domain-taxonomy`
- 全局模板

输出：

- `standard.md`
- `ai-rules.md`
- `review-checklist.md`
- 带 YAML Front Matter 的 Markdown 文档
- `evidence/*`

要求：

1. 每个输出 Markdown 顶部必须符合 `config/frontmatter-format.md`。
2. 规则正文不写具体路径。
3. 规则必须带 `status`、`level`、`source_kind`、`evidence_tier`、`risk_tag`、`recommended_action`(可选: `conflicts_with`、`superseded_by`),取值符合 `config/frontmatter-format.md §4` 枚举。
4. AI Rules 必须说明 draft / high-risk / pending 的使用边界。
5. Review Checklist 必须能被 reviewer 判断。
6. 规则 H2 标题必须满足 `^(P0|P1|P2|FORBIDDEN) ` 前缀，且与 `rules-index.json.section_title` 字面一致；**不使用 Rule ID，不使用 HTML anchor**。规则跨文档引用统一为 `{source_doc}「{section_title}」` 二元组。

## 5. 阶段 4：Review and Quality Gate

输入：

- 生成的规则和 evidence。

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

要求：

1. Quality Gate 只能给状态建议，不能发布 `active`。
2. 无 evidence 规则进入 `pending-confirmation`。
3. 冲突规则进入 `conflicts.md`。

## 6. 阶段 5：Merge Coordinator

输入：

- `quality_gate_decision`
- 现有规范目录。

输出：

- append-only 文档变更。

规则：

1. 不覆盖已有 `active`。
2. 不覆盖已有 `draft`。
3. 新 evidence 追加到 `evidence/`。
4. 相近规则写入 `merge-suggestions.md`。
5. 冲突写入 `conflicts.md`。
6. 待确认写入 `pending-confirmation.md`。

## 7. 完成标准

一次萃取完成必须输出：

- 修改文件列表。
- 新增规则列表。
- evidence 列表。
- Quality Gate 结果。
- 是否存在 `pending-confirmation` 或 `conflict`。
- AI 使用警告。
- 负责人确认项。
