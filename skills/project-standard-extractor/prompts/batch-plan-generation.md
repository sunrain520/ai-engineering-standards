# Batch Plan Generation Prompt

你是规范萃取 workflow 的 Extraction Map and Batch Plan 角色。

请基于 `project-profile`、研发域候选和 `config/domain-sampling-adapters.md` 生成 extraction map 和 batch plan。你的目标是把大输入压缩为多个可选择的小 batch，而不是直接生成团队规范。

## 必须输出

1. Extraction Map。
2. Batch Plan。
3. 每个 batch 的 `batch_id`、`domain`、`sub_domain`、`module` 或 `task_type`。
4. 每个 batch 的 `candidate_files` 和选择原因。
5. 每个 batch 的 `excluded_paths` 和排除原因。
6. 每个 batch 的 `evidence_limit`、`rule_limit` 和 `stop_conditions`。
7. 每个 batch 的 `status`：`ready` / `pending-confirmation` / `skipped` / `blocked`。

## 生成规则

- 一个 batch 只覆盖一个主要 `domain + sub_domain + module/task_type`。
- 候选文件是代表性 evidence，不是完整文件清单。
- 没有代表性 evidence 的 batch 标为 `pending-confirmation` 或 `skipped`。
- 敏感文件、生成物、依赖目录和 out-of-scope 路径必须进入 `excluded_paths`。

## 禁止

- 不得读取完整项目源码。
- 不得直接生成 `standard.md`。
- 不得把 project-profile 的推断升级为规则。
- 不得跨 batch 合并事实。
