# 一致性检查清单

执行 `project-standard-extractor` 或修改本 Skill 后，至少检查以下事项。

## 1. 状态词汇

- [ ] 规则级 `status` 只取 `draft` / `active` / `pending-confirmation` / `conflict` / `legacy-compatible` / `rejected`(见 `config/frontmatter-format.md §4.2`)。
- [ ] 文档级 `status` 只取 `draft` / `active` / `pending` / `archived`(见 §4.1)。
- [ ] `recommended_action` 只取 `keep-draft` / `promote-to-active` / `move-to-pending` / `mark-conflict` / `mark-legacy` / `reject` / `defer`(见 §4.7)。**不得**自创 `consider promotion` 等枚举。
- [ ] 没有自动发布 `active` 的说法。

## 2. 规则定位

- [ ] 规则 H2 标题以 `P0` / `P1` / `P2` / `FORBIDDEN ` 之一为前缀。
- [ ] 规则正文不出现 Rule ID(如 `STD-XX-NN-NNN`)。
- [ ] 规则正文不出现 HTML anchor(如 `<a id="…"></a>`)。
- [ ] 跨文档引用规则统一使用 `{source_doc}「{section_title}」` 二元组。
- [ ] `rules-index.json.section_title` 与 standard.md H2 字面一致。

## 3. Evidence 边界

- [ ] 规则正文没有具体项目路径。
- [ ] 真实路径只出现在 `evidence/`。
- [ ] 无 evidence 内容没有进入 AI 默认执行路径。
- [ ] P0 / FORBIDDEN 规则有 evidence 和 Review 检查项。
- [ ] evidence_tier 取值在 `direct-code` / `cross-project` / `single-project` / `inferred` / `none` 范围内,**不**使用 `owner-confirmed` 等冗义值(`owner-confirmed` 是 `source_kind`)。

## 4. 上下文治理

- [ ] 完整项目 / 完整仓库 / 多服务输入先进入 `profile-first`。
- [ ] profile-first 只输出 `project-profile` / `extraction-map` / `batch-plan`，不生成正式规则。
- [ ] 正式萃取只选择一个 batch。
- [ ] batch 包含 `domain`、`sub_domain`、`module` 或 `task_type`、`candidate_files`、`excluded_paths`、`evidence_limit`、`rule_limit` 和 `stop_conditions`。
- [ ] 后续阶段读取 handoff artifacts 和候选路径，不携带完整源码上下文。

## 5. 输出落点

- [ ] `pending-confirmation.md` 存在。
- [ ] `merge-suggestions.md` 存在。
- [ ] `conflicts.md` 存在。
- [ ] `evidence/README.md` 存在。
- [ ] `evidence/code-facts.md` 存在。
- [ ] `evidence/positive-examples.md` 存在。
- [ ] `evidence/forbidden-examples.md` 存在。
- [ ] `evidence/legacy-compatible.md` 存在。
- [ ] `examples/README.md` 存在。
- [ ] 需要时输出 `temp/{run_id}-rules-index-candidate.json`。
- [ ] 需要时输出 `temp/{run_id}-llms-candidate.txt`。
- [ ] 需要时输出 `temp/{run_id}-ai-context-pack.md`。
- [ ] 候选索引产物不默认覆盖正式根文件。

## 6. 安全

- [ ] evidence 没有 secret、token、private key。
- [ ] evidence 没有生产凭据或敏感配置值。
- [ ] 敏感文件只记录脱敏存在事实。

## 7. 建议搜索

```bash
rg -n 'STD-[A-Z]{2,}-' engineering-standards skills/project-standard-extractor
rg -n '<a id=' engineering-standards skills/project-standard-extractor
rg -n 'consider promotion|rule_id|RuleID' engineering-standards skills/project-standard-extractor
rg -n 'read full project|读取完整项目|全量读取' skills/project-standard-extractor
rg -n 'secret|token|private key|password' engineering-standards/*/evidence skills/project-standard-extractor/examples
```

命中不一定代表错误，但必须逐条确认是否为示例、禁止项或需要改写的旧口径。
