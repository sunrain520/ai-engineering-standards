# Merge Coordinator Contract

## 角色目标

把通过 Quality Gate 的结果写入规范目录，同时保持 append-only、不覆盖已有规则。

## 输入

- `quality_gate_decision`
- 现有 domain 目录。
- output targets。
- Front Matter 索引字段。
- 候选 `rules-index` / `llms` / `ai-context-pack` 产物。

## 输出

- 修改文件列表。
- 新增规则定位列表（`(source_doc, section_title)` 二元组）。
- 新增 Evidence 条目编号列表（`EV-/POS-/NEG-/LEG-{DOMAIN}-{NUMBER}`）。
- merge / conflict / pending 列表。
- candidate index artifact 列表。

> 规则不使用 Rule ID，不写 HTML anchor；引用规则统一为 `{source_doc}「{section_title}」`。

## 写入策略

| Decision | 写入位置 |
| --- | --- |
| evidence-backed draft | `standard.md`、`ai-rules.md`、`review-checklist.md`、`evidence/*` |
| no-evidence | `pending-confirmation.md` |
| similar existing rule | `merge-suggestions.md` |
| conflicting rule | `conflicts.md` |
| legacy pattern | `evidence/legacy-compatible.md` |
| fast-index candidate | `{run_id}-rules-index-candidate.json`、`{run_id}-llms-candidate.txt`、`{run_id}-ai-context-pack.md` |
| rejected | 不进入执行路径，可记录在 review report |

## 幂等合并协议

写入前必须先建立目标目录索引：

```yaml
existing_index:
  docs:
    - doc_id:
      doc_type:
      domain:
      sub_domain:
      indexable:
  rule_locators: []        # [{source_doc, section_title, level, status}]
  evidence_ids: []          # EV-/POS-/NEG-/LEG-{DOMAIN}-{NUMBER}
  title_fingerprints: []
  states:
    active: []
    draft: []
    pending-confirmation: []
    conflict: []
    legacy-compatible: []
```

合并决策规则（以 `(source_doc, section_title)` 为规则唯一定位）：

1. 如果 `(source_doc, section_title)` 已存在，不重写规则正文，只追加新的 evidence 或写入 `merge-suggestions.md`。
2. 如果新候选与已有规则在不同 `source_doc` 下语义重复(标题、适用范围和禁止事项相似),或在同一 `source_doc` 下 `section_title` 仅措辞差异,写入 `merge-suggestions.md`,不新增重复规则。
3. 如果新候选与已有 `active` 冲突，写入 `conflicts.md`，不得降级或覆盖已有 `active`。
4. 如果新候选与已有 `draft` 冲突，写入 `conflicts.md`，并保留两个候选的 evidence。
5. 如果 evidence 条目编号已存在，只追加新的观察时间、项目来源或补充说明，不复制重复段落。
6. 如果缺少 evidence、负责人确认或适用范围，写入 `pending-confirmation.md`，不得写入 `ai-rules.md`。
7. 如果目标文件缺少 Front Matter，先追加到 `merge-suggestions.md`，不得直接改写历史文档头部。
8. 新建文件必须按 `config/frontmatter-format.md` 写入 Front Matter，规则 H2 必须以 `P0|P1|P2|FORBIDDEN` 前缀开头。
9. 候选索引产物必须保留 candidate 标记，不得默认覆盖正式 `.index/rules-index.json` 或根 `llms.txt`。

## 必须做

1. 写入前读取目标文件，避免覆盖已有内容。
2. 对同一主题追加 merge suggestion，而不是重复生成规则。
3. 记录每次运行的输出摘要。
4. 保留所有待人工确认项。
5. 保证新建 Markdown 文件顶部可被快速索引。
6. 对 `rules-index` 候选检查字段为 `title/domain/sub_domain/level/source_doc/section_title/evidence_doc/tags`。

## 禁止做

1. 不得覆盖 `active`。
2. 不得覆盖已有 `draft`。
3. 不得删除历史 evidence。
4. 不得把 `pending-confirmation` 写入 AI 默认执行路径。
5. 不得默认发布候选索引产物。
