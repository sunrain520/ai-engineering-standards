# AI 辅助研发工程规范用户手册

## 1. 手册目标

本文面向第一次使用 `AI Engineering Standards` 的研发、Reviewer、架构师和 AI 辅助研发使用者，说明如何从真实项目萃取团队规范、如何读取产物、哪些规则能进入 AI 默认执行路径，以及 owner 在什么时候介入。

## 2. 产品定位

`AI Engineering Standards` 是部门级研发工程规范仓库。它不是通用最佳实践合集，也不是单项目说明书，而是把真实代码里的团队经验转成可追溯、可审查、可被 AI 复用的规范资产。

当前公开稳定能力聚焦 `project-standard-extractor`：

```text
project_paths
  -> intake and scope
  -> profile-first
  -> ordered_batch_queue + coverage_report
  -> per-batch facts/classification/generation/review/merge
  -> standard / ai-rules / review-checklist / evidence
  -> lineage-ledger / owner-decision-queue / review-summary
```

Phase 2 `dimension-activator`、cross-project、EA-Doc、securities PoC、force-rebuild / restore / pin / unpin / list 仍是 repair-only 或 maintainer-only，不是普通用户稳定路径。

## 3. 角色

| 角色 | 典型用途 |
| --- | --- |
| 研发人员 | 查询推荐写法、禁止写法、目录和分层约束 |
| AI 使用者 | 只把 `auto-active` / `owner-confirmed-active` 规则放进默认执行上下文 |
| Reviewer | 用 `review-checklist.md` 做可二值判断的检查 |
| 领域负责人 | 审查 auto-active、pending、conflict、stale-auto-active 和 owner-rejected 队列 |
| 规范维护者 | 执行萃取、校验 artifact contract、维护候选索引与 Changelog |

## 4. 输入

公开入口通常只需要：

```yaml
project_paths:
  - /path/to/project
output_dir: ""
extraction_mode: ""   # full-auto | profile-first | batch-extraction | focused-module
selected_batch:
  batch_id: ""        # 诊断/重跑单 batch 时填写；full-auto 不需要
run_mode: auto
```

默认 `extraction_mode` 是 `full-auto`。完整仓库、多服务、多端或范围不清时，Skill 内部仍先做 profile-first，但不会停下来要求用户手动选 batch；它会生成 `ordered_batch_queue`，串行执行 ready 与 pending-confirmation batch。

公开入口不要传 `output_action`、`restore_from`、`keep`、`full` 或维护者级 `domain` 字段。

## 5. 输出怎么读

| 产物 | 用途 |
| --- | --- |
| `temp/{run_id}-project-profile.md` | 项目画像、技术栈、候选模块、敏感边界 |
| `temp/{run_id}-extraction-map.md` | 可萃取区域和 evidence 候选 |
| `temp/{run_id}-batch-plan.md` | batch 计划和 `ordered_batch_queue` |
| `temp/{run_id}-review-summary.md` | full-auto 汇总、coverage、usable_now、owner 待办 |
| `standard-{sub_domain}.md` | 规范正文，规则用 `source_doc + section_title` 定位 |
| `ai-rules.md` | AI 派生视图，只默认执行 active 类规则 |
| `review-checklist.md` | Review 派生视图 |
| `pending-confirmation.md` | low-confidence、高风险或证据不足内容 |
| `merge-suggestions.md` | 近义或可合并建议 |
| `conflicts.md` | 与已有规则或 evidence 冲突内容 |
| `lineage-ledger.json` | evidence 到规范/AI/Review/index 的派生链 |
| `owner-decision-queue.json` | owner 事后确认、否决、降级、冲突裁定队列 |

候选索引 `temp/{run_id}-rules-index-candidate.json`、`llms-candidate.txt`、`ai-context-pack.md` 不会默认覆盖正式 `.index/rules-index.json` 或根 `llms.txt`。

## 6. 状态模型

| 规则状态 | AI 默认执行 | 来源 |
| --- | --- | --- |
| `auto-active` | 是 | 通过高置信自动升级闸，且未命中高风险域/黑名单 |
| `owner-confirmed-active` | 是 | owner 手动确认 |
| `draft` | 否 | 有 evidence，但未过自动升级闸 |
| `pending-confirmation` | 否 | low-confidence、高风险、黑名单或证据不足 |
| `stale-auto-active` | 否 | 复检发现 auto-active 不再满足闸 |
| `owner-rejected` | 否 | owner 否决 auto-active |
| `conflict` / `legacy-compatible` / `rejected` | 否 | 冲突、历史兼容或驳回 |

`auto-active` 只说明“在本仓库 evidence 下足够代表当前项目实践”，不是行业最佳实践背书。它必须带 `authority_scope: this-repo`、`upgrade_mode: auto-active`、`deterministic_occurrence_count` 和 lineage 闸判据快照。

## 7. Coverage

`coverage_report` 只承诺 profile 识别范围内的覆盖，不承诺全仓无盲区。它必须列出：

- profile 矩阵内覆盖率。
- ready / pending-confirmation / skipped / blocked 分布。
- low-confidence 归因。
- skipped/blocked 的解决建议。
- profile blind spots，例如未解析目录、不可读路径、跳过的顶层模块。

如果 `usable_now` 全部为 no，review summary 应说明 evidence 稀疏或高风险，而不是把它包装成运行失败。

## 8. 常用验证

维护者在修改 Skill source 后至少运行：

```bash
bash tools/maintainer/project-standard-extractor/public-surface-validate.sh
bash tools/maintainer/project-standard-extractor/artifact-contract-validate.sh
```

普通用户不需要运行 maintainer repair 工具。遇到 `MAINTAINER_CONTEXT_REQUIRED` 时，说明当前请求越过了公开稳定路径。
