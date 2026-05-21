# Context Governance

本文件约束 `project-standard-extractor` 如何处理大输入。目标是允许用户给完整项目、完整仓库或多服务路径，但执行时必须先压缩上下文，再按 batch 聚焦读取 representative evidence。

## 1. 强制原则

1. **大输入先画像**：完整项目、完整仓库、多服务、多端、未知研发域或 broad scope 默认进入 `profile-first`。
2. **不得全量读取源码**：任何阶段都不得为了“更完整”而读取整个仓库、整个 Skill 目录或所有服务文件。
3. **阶段间只传 artifact**：后续阶段优先读取 `project-profile`、`extraction-map`、`batch-plan`、`code-facts` 摘要和路径，不传递完整源码。
4. **正式萃取只处理一个 batch**：一次 `batch-extraction` 必须选择一个 `batch_id`，不得跨 batch 合并读取。
5. **规则来自 evidence，不来自画像**：`project-profile` 和 `extraction-map` 只能产生候选方向，不能直接升级为团队规则。
6. **敏感信息只记存在事实**：secret、token、私钥、生产凭据、生产配置值不得复制到任何产物。

## 2. 模式边界

| 模式 | 最大允许读取 | 允许产物 | 不允许产物 |
| --- | --- | --- | --- |
| `profile-first` | 目录结构、清单、配置类别、少量代表性文件候选 | project profile、extraction map、batch plan | standard、ai-rules、review-checklist |
| `batch-extraction` | 一个 batch 的 candidate files 和必要邻近文件 | code facts、classification、draft rules、evidence | 其它 batch 的事实或规则 |
| `focused-module` | 用户指定模块和必要邻近文件 | scoped facts、draft rules、evidence | 全项目总结 |
| `review-only` | 已有萃取产物 | review report、quality gate decision | 新规则 |
| `merge-only` | 目标规范目录和已确认候选 | append-only merge | 新 evidence scan |

## 3. 默认预算

默认预算用于避免隐性全量读取。实现时可在用户确认后收紧或放宽，但必须记录。

| 项 | 默认上限 |
| --- | --- |
| profile 阶段代表性目录深度 | 3 层 |
| 每个 batch 候选文件数 | 20 |
| 每个 batch evidence 条目数 | 8 |
| 每个 batch 候选规则数 | 10 |
| 每次正式萃取 batch 数 | 1 |

预算耗尽时停止并记录 `stop_condition`，不得自动扩大范围。

## 4. Artifact Handoff

阶段间必须用以下 artifact 交接：

1. `project-profile`：项目画像、域推断、敏感策略、候选模块。
2. `extraction-map`：domain / sub_domain / module / task_type 到候选 evidence 的映射。
3. `batch-plan`：可执行 batch 列表、候选文件、排除范围、限制和停止条件。
4. `code-facts`：选定 batch 的事实摘要、证据强度和推导边界。

后续阶段可以读取这些 artifact 和其中列出的候选路径，但不能把上一阶段的原始源码上下文原样带入。

## 5. 示例和 eval 读取边界

修改或运行 examples / evals 时：

- 可以读取目标示例文件和它直接引用的模板 / prompt。
- 不得为了“确保一致”读取整个 `skills/project-standard-extractor/` 目录后生成大段总结。
- 回归搜索可以使用 `rg`，但命中项必须逐条判断是否为禁止项、示例说明或历史记录。
