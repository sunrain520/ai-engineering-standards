# Draft 输出自评 Prompt

请评审本次 `project-standard-extractor` 输出是否可进入 `draft`。

检查维度：

1. 是否所有规则都有 `source_kind` 和 `evidence_tier`？
2. 是否所有 AI 可执行 `draft` 都有 evidence 或负责人确认？
3. 是否 P0 / FORBIDDEN 有正反例和 Review 检查项？
4. 是否没有把项目路径写入规则正文？
5. 是否没有把无 evidence 内容写成强制规则？
6. 是否没有泄露敏感信息？
7. 是否正确写入 `pending-confirmation.md`、`merge-suggestions.md`、`conflicts.md`？
8. 是否没有覆盖已有 `active` 或 `draft`？

输出格式：

```markdown
## 自评结论

- 结果：pass / fail
- 阻塞问题：
- 建议修复：
- 可交给负责人确认的规则：
```
