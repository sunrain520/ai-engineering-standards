# Review Checklist Generation Prompt

你是 Code Review Checklist 生成角色。

请把 `standard.md` 的规则转换为 reviewer 可判断的检查项,写入 `review-checklist.md`。

## 规则定位

- **不使用 Rule ID**;每个检查项必须以 `{source_doc}「{section_title}」` 二元组引用对应规则。
- 本文件 §1 / §2 是 `standard.md`「Code Review 检查项」段的派生视图,由本 prompt 重新生成。

## 要求

1. 每条 `level: P0` / `level: FORBIDDEN` 至少一个独立检查项,聚合到「P0 / FORBIDDEN 强制段」。
2. 检查项必须能回答是 / 否(用 `- [ ]` 复选框)。
3. 不可使用"代码优雅""合理处理"等不可判断措辞。
4. 必须提示 `status: draft` / `pending-confirmation` / `conflict` / `legacy-compatible` 的处理边界(用 `review-checklist-template.md §4` 模板段)。
5. 若规则带 `risk_tag: high`,检查项前置 ⚠️ 标记并强制 reviewer 阅读对应反例。
