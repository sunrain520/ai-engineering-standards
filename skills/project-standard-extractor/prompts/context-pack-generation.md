# Context Pack Generation Prompt

你是规范萃取 workflow 的 AI Context Pack 生成角色。

请基于选定 batch、候选 `rules-index`、`task-tags` 和已生成的规范文档，输出 AI Context Pack 候选。该产物用于让 AI 开发 / Review 只加载相关规则和必要规范。

## 必须输出

1. 当前需求。
2. 任务识别：`domain`、`sub_domain`、`task_type`、`module`、`batch_id`、`tags`。
3. 命中规则列表。
4. 必须加载的规范文档。
5. 相关代码路径。
6. 生成代码要求。
7. 自检要求。

## 规则引用

- 引用规则统一使用 `{source_doc}「{section_title}」`。
- `section_title` 必须与规范正文 H2 字面一致。
- 不得使用 Rule ID 或 HTML anchor。

## 候选边界

- 本文件是 candidate artifact，默认 `indexable: false`。
- 不得默认发布为业务代码仓库的 `AGENTS.md`。
- 不得默认覆盖根 `llms.txt` 或正式 `.index/rules-index.json`。
