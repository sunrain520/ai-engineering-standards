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
| `artifact-contract-cases.md` | 产物契约、lineage、owner queue、Phase1/Phase2 边界和 validator 用例 |

## AE 映射

| AE | 覆盖文件 | 核心断言 |
| --- | --- | --- |
| AE-01 | `trigger-cases.md`, `expected-behavior.md` | broad input 默认 full-auto,内部 profile-first 后按 `ordered_batch_queue` 执行 ready/pending batch。 |
| AE-02 | `trigger-cases.md`, `expected-behavior.md` | 多 batch 独立进入 `phase1-selected-batch`,单个 batch 失败不污染其它 batch。 |
| AE-03 | `failure-cases.md`, `expected-behavior.md` | 单样本/历史包袱不得自动升权威,应进入 draft/pending/legacy 隔离路径。 |
| AE-04 | `failure-cases.md`, `expected-behavior.md` | 与既有 active/draft 冲突时写 `conflicts.md` / owner queue,不得自动改写既有正文。 |
| AE-05 | `failure-cases.md`, `boundary-cases.md` | 敏感路径只记录脱敏存在事实或停止受影响 batch。 |
| AE-06 | `expected-behavior.md` | 高质量规则通过 evidence、结构、AI 可执行性和 review 可检查性 gate。 |
| AE-07 | `expected-behavior.md` | GitNexus/stale candidate 只能作指针,必须 direct-scan 确认后产出 evidence。 |
| AE-08 | `trigger-cases.md`, `boundary-cases.md` | focused module path 走同一 full-auto/selected-batch 语义,保持 evidence 和 append-only 边界。 |
| AE-09 | `expected-behavior.md`, `artifact-contract-cases.md` | 缺 Front Matter 或非法 `doc_type` 触发 artifact validator BLOCK。 |
| AE-10 | `expected-behavior.md`, `artifact-contract-cases.md` | candidate fast-index 不得覆盖正式 `.index/rules-index.json` 或根 `llms.txt`。 |
| AE-11 | `expected-behavior.md`, `artifact-contract-cases.md` | `rules-index.section_title` 必须与 source doc 的 H2/H3 字面一致。 |
| AE-12 | `expected-behavior.md`, `failure-cases.md` | 结构不足或 low-confidence 内容不得进入 AI 默认执行路径。 |
| AE-13 | `expected-behavior.md`, `boundary-cases.md` | placeholder/no-evidence domain 显式标为 non-executable。 |
| AE-14 | `artifact-contract-cases.md`, `failure-cases.md` | 派生 AI/review/index 规则缺 lineage 时触发 `LINEAGE_INCOMPLETE` / `ORPHAN_RULE`。 |
| AE-15 | `expected-behavior.md` | review summary/domain entry 暴露 `usable_now`、可读/不可读文件、owner queue 和 recommended action。 |
| AE-16 | `trigger-cases.md`, `expected-behavior.md` | validators 可从 repo root 或 maintainer script directory 运行。 |
| AE-17 | `expected-behavior.md`, `failure-cases.md`, `artifact-contract-cases.md` | BR-016/BR-017 过闸规则升 `auto-active`;黑名单/高风险域降 pending。 |
| AE-18 | `expected-behavior.md`, `artifact-contract-cases.md` | owner rejection 与 stale auto-active 会移出默认执行路径并进入 owner queue。 |

## 使用方式

修改 `SKILL.md`、`references/workflow.md`、`references/agents/` 或 `assets/` 后，至少抽样检查这些用例：

1. 触发样例能进入 `project-standard-extractor`。
2. 边界样例不会被误判为规范萃取任务。
3. 失败样例不会生成 AI 可执行规则。
4. 期望产物仍满足 append-only、evidence-first、auto-active 闸、owner queue 和撤销链约束。
5. broad input 默认进入 full-auto：内部先 `profile-first`，再按 `ordered_batch_queue` 逐 batch 执行。
6. `batch-extraction` 仍要求单个 `selected_batch`；full-auto 外层循环不得把多个 batch 一次性塞给 worker。
7. 候选 fast-index artifacts 仍不包含 `rule_id` / `anchor`，且不默认发布正式索引。
8. 运行 `tools/maintainer/project-standard-extractor/public-surface-validate.sh` 和 `tools/maintainer/project-standard-extractor/artifact-contract-validate.sh` 检查公开面、maintainer gate、产物契约和 eval authority 是否仍一致。
9. 运行正例 fixture：

```bash
bash tools/maintainer/project-standard-extractor/artifact-contract-validate.sh docs/evals/project-standard-extractor/fixtures/artifact-contract/valid-phase1 docs/evals/project-standard-extractor/fixtures/artifact-contract/valid-phase2
```

10. 运行负例 fixture 时必须失败，并至少包含 `PHASE1_ACTIVATION_REPORT_LEAK`：

```bash
bash tools/maintainer/project-standard-extractor/artifact-contract-validate.sh docs/evals/project-standard-extractor/fixtures/artifact-contract/invalid-phase1-activation-leak
```
