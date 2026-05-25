# Evals

本目录保存 `project-standard-extractor` 的回归用例。它们不是业务规范结果，而是检查 Skill 是否仍按预期触发、拒绝越界请求、处理失败模式，并输出稳定产物。

## 权威关系

- 本目录是 `project-standard-extractor` 的完整 eval source-of-truth。
- `skills/project-standard-extractor/evals/` 只保留 package-local smoke subset，不能与本目录写出相反期望。
- public-surface validator 只做跨文件契约检查，不新增产品行为；用例语义仍以本目录为准。

## 用例索引

| 文件 | 目的 |
| --- | --- |
| `trigger-cases.md` | 应该触发 Skill 的输入样例 |
| `boundary-cases.md` | 不应该触发或必须降级处理的边界样例 |
| `failure-cases.md` | 失败模式和预期处理 |
| `expected-behavior.md` | 完整运行后必须满足的产物和安全要求 |

## 使用方式

修改 `SKILL.md`、`references/workflow.md`、`references/agents/` 或 `assets/` 后，至少抽样检查这些用例：

1. 触发样例能进入 `project-standard-extractor`。
2. 边界样例不会被误判为规范萃取任务。
3. 失败样例不会生成 AI 可执行规则。
4. 期望产物仍满足 append-only、evidence-first、draft-only 的约束。
5. broad input 仍先进入 `profile-first`，不会直接生成规则。
6. `batch-extraction` 仍要求单个 `selected_batch`。
7. 候选 fast-index artifacts 仍不包含 `rule_id` / `anchor`，且不默认发布正式索引。
8. 运行 `tools/maintainer/project-standard-extractor/public-surface-validate.sh` 检查公开面、maintainer gate 和 eval authority 是否仍一致。
