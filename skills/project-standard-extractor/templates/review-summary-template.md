---
doc_id: "{domain}-{run_id}-review-summary"
title: "规范萃取 Review Summary：{run_id}"
domain: "{domain}"
sub_domain: common
doc_type: review-report
version: "v0.1.0"
status: draft
owner: TBD
index_format: engineering-standards-md-v1
indexable: false
run_id: "{run_id}"
tags:
  - "{domain}"
  - "review-summary"
  - "action-required"
---

# 规范萃取 Review Summary

> **这是本次萃取的用户审查入口。** 请从上到下阅读，对每一项做出决定后删除对应行。

---

## 1. 执行概览

| 项 | 值 |
| --- | --- |
| run_id | `{run_id}` |
| 执行时间 | {ISO8601} |
| 输入项目 | {project_paths} |
| 处理 domain | {domain} |
| 总 batch 数 | {total} |
| ✅ 成功 | {completed} 个 |
| ⏭️ 跳过 | {skipped} 个 |
| ❌ 失败 | {failed} 个 |

---

## 2. 新增 / 更新的规范文档

> 这些是本次萃取输出的 draft 文档。**浏览后，将你认可的规则 `status` 手动改为 `active`。**

| 文件 | 状态 | 新增章节 | evidence 数 |
| --- | --- | --- | --- |
| `standard-{sub_domain}.md` | draft（新建） | {章节列表} | {N} 条 |
| `standard-{sub_domain}.md` | draft（已追加章节） | {新增章节} | {N} 条 |
| `ai-rules.md` | draft（已更新） | — | — |
| `review-checklist.md` | draft（已更新） | — | — |

---

## 3. ⚠️ 需要审查的标记项

> 以下内容已生成到对应文档，但需要你特别关注。

### 3.1 FORBIDDEN 标注（有直接负例 evidence）

| 规则位置 | FORBIDDEN 内容 | evidence | 确认动作 |
| --- | --- | --- | --- |
| `standard-{sub_domain}.md §{节名}` | {FORBIDDEN 说明} | `NEG-{DOMAIN}-{N}` | [ ] 确认有效 / [ ] 改为禁止事项（不升 FORBIDDEN） |

### 3.2 置信度 low 的推断（可能不准确）

| 推断内容 | 依据 | 动作 |
| --- | --- | --- |
| {sub_domain 归因} | {推断依据} | [ ] 正确 / [ ] 修正为 {正确值} |

### 3.3 行业高风险规则（需领域负责人确认）

| 规则位置 | 内容摘要 | 动作 |
| --- | --- | --- |
| `standard-{sub_domain}.md §{节名}` | {摘要} | [ ] 确认 / [ ] 降级为 P1 / [ ] 移入 pending |

---

## 4. 待处理清单

> 以下内容**尚未写入规范**，需要你处理后才能生效。

### 4.1 待确认规则（pending-confirmation.md）

| 编号 | 内容摘要 | 无法生成原因 | 升级条件 | 动作 |
| --- | --- | --- | --- | --- |
| `PENDING-{DOMAIN}-{N}` | {摘要} | {reason} | {promotion_criteria} | [ ] 补充 evidence 重跑 / [ ] 负责人确认 / [ ] 放弃 |

### 4.2 冲突规则（conflicts.md）

| 编号 | 新规则 | 已有规则 | 严重度 | 动作 |
| --- | --- | --- | --- | --- |
| `CONFLICT-{DOMAIN}-{N}` | `standard-{sub_domain}.md §{节}` | `{已有 source_doc}「{section_title}」` | breaking / warning / info | [ ] 保留新的 / [ ] 保留旧的 / [ ] 两者合并 |

### 4.3 相似规则建议（merge-suggestions.md）

| 编号 | 内容摘要 | 建议 | 动作 |
| --- | --- | --- | --- |
| `MERGE-{DOMAIN}-{N}` | {摘要} | {合并建议} | [ ] 合并 / [ ] 保留两条 |

---

## 5. 跳过的 Batch

> 以下 batch 因证据不足被跳过，未生成对应规范内容。

| batch_id | 跳过原因 | 如何解决 |
| --- | --- | --- |
| {batch_id} | {skip_reason} | {解决建议} |

---

## 6. 下一步行动

完成审查后的操作：

1. **删除不认可的内容**：打开对应 `standard-{sub_domain}.md`，删除不准确的规则节或章节。
2. **处理冲突**：打开 `conflicts.md`，按裁定结果保留/删除对应规则。
3. **处理 pending**：补充 evidence 后重新运行 Skill，或由领域负责人书面确认后手动添加到规范文档。
4. **升级 active（人工）**：领域负责人显式确认后，手动把认可规则的状态从 `draft` 改为 `active`。
5. **发布索引（可选）**：确认无误后，将 `temp/{run_id}-rules-index-candidate.json` 重命名为正式 `.index/rules-index.json`。

> Skill 自动运行不会发布 `active`；负责人确认前，生成内容只能作为 `draft` 或待处理候选使用。

---

*本文件由 project-standard-extractor 自动生成，完成审查后可删除或归档。*
