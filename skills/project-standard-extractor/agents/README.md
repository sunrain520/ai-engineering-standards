# Internal Agent Contracts

第一阶段把阶段 role contracts 定义为可执行 phase contract 文件。宿主支持 subagent 时可以按这些合约拆分执行；宿主不支持时，由一个 agent 按阶段顺序执行。

## 阶段文件（6 个 Phase Contract）

| 文件 | 阶段 | Workflow §§ |
| --- | --- | --- |
| `intake-and-scope.md` | 输入引导、范围确认、敏感文件策略、extraction_mode 决策 | §3 |
| `profile-and-batch-planner.md` | 项目画像（project-profile）、extraction map、batch plan 生成 | §4 §5 |
| `facts-and-classification.md` | 选定 batch 的代码事实萃取、正反例、历史兼容、分类 | §6 |
| `generation.md` | 规范、AI Rules、Review Checklist、evidence 和候选索引生成 | §7 |
| `review-and-quality-gate.md` | 7 persona 分面评审、Proposer-Challenger-Arbiter 冲突仲裁、Quality Gate 汇总 | §8 |
| `merge-coordinator.md` | append-only 合并、冲突严重度分级、候选索引产物处理 | §9 |

## 执行顺序

```
intake-and-scope
  └─→ profile-and-batch-planner        (broad_input=true 时必经；用户选 batch 后继续)
        └─→ facts-and-classification   (selected_batch_id 确认后)
              └─→ generation           (code_facts + classification 完整后)
                    └─→ review-and-quality-gate
                          └─→ merge-coordinator
```

`profile-and-batch-planner` 是 V1 新增阶段，覆盖之前"无人 owns 的 workflow §4-§5"。

## 共同规则

1. 生成阶段不得绕过 `code-facts`。
2. 规则正文不得写真实项目绝对路径。
3. 无证据内容不得进入 AI 可执行 `draft`。
4. 所有高风险规则必须输出 warning。
5. 所有阶段必须保留不确定点。
6. 完整项目 / 完整仓库 / 多服务输入必须先进入 `profile-and-batch-planner`。
7. 正式萃取必须限定到一个选定 batch。
8. 每个阶段移交前必须执行 Self-check，不通过不移交。

## Handoff Chain

每个阶段的 Handoff Schema 定义在各契约的 `## 输出（Handoff Schema）` 节中。跨阶段只传 artifact（文件路径或 YAML 摘要），不传完整源码上下文。

| 从 → 到 | 传递内容 |
| --- | --- |
| intake → profile-planner | `scope_summary` |
| profile-planner → facts | `{run_id}-project-profile.md` + `{run_id}-batch-plan.md` + `selected_batch_id` |
| facts → generation | `code_facts` + `classification`（YAML 摘要，不含源码） |
| generation → review | 产物路径列表 + `batch_summary` |
| review → merge | `quality_gate_decisions[]` + `review_report` |

## R13 角色 → 阶段合约映射

| brainstorm 角色 | 阶段合约 | 在合约中的职责段 |
| --- | --- | --- |
| Intake | `intake-and-scope.md` | 输入收集、确认声明 |
| Project Profiler | `profile-and-batch-planner.md` | 推断研发域、子领域、行业；生成 project-profile |
| Batch Planner | `profile-and-batch-planner.md` | extraction map、batch plan 生成 |
| Evidence Collector | `facts-and-classification.md` | 选定 batch 的代码路径与文档证据采集 |
| Code Facts | `facts-and-classification.md` | `code_facts` 输出 |
| Pattern Classifier | `facts-and-classification.md` | `classification` 桶 |
| APP Standard | `generation.md` | 端 `standard.md` 生成（domain=app-client） |
| Frontend Standard | `generation.md` | 端 `standard.md` 生成（domain=frontend） |
| Backend Standard | `generation.md` | 端 `standard.md` 生成（domain=backend） |
| Industry Standard | `generation.md` | 行业 `standard.md` 生成（domain=industry） |
| AI Rules | `generation.md` | `ai-rules.md` 派生生成 |
| Review Checklist | `generation.md` | `review-checklist.md` 派生生成 |
| Evidence Writer | `generation.md` | Sub-step A：`evidence/*` 写入 |
| Context Pack Writer | `generation.md` | Sub-step D：`rules-index`、`llms`、`ai-context-pack` 候选产物 |
| Evidence Auditor | `review-and-quality-gate.md` | Review Persona P1：证据 |
| Team Standard Reviewer | `review-and-quality-gate.md` | Review Persona P2：团队级抽象 |
| AI Executability Reviewer | `review-and-quality-gate.md` | Review Persona P3：AI 可执行性 |
| Review Checklist Reviewer | `review-and-quality-gate.md` | Review Persona P4：Review 可检查性 |
| Conflict Reviewer | `review-and-quality-gate.md` | Review Persona P5：冲突 + Debate 仲裁 |
| Industry Risk Reviewer | `review-and-quality-gate.md` | Review Persona P6：行业风险 |
| Context Governance Reviewer | `review-and-quality-gate.md` | Review Persona P7：profile-first / batch 边界 |
| Quality Gate | `review-and-quality-gate.md` | 汇总 `quality_gate_decision` |
| Merge Coordinator | `merge-coordinator.md` | append-only 写入与冲突落点 |

## 未来迭代方向（V2 考虑项，V1 不实施）

- 为每个 phase contract 补充 sub-agent frontmatter（`name / description / tools / maxTurns / permissionMode`），为 Claude Agent SDK 迁移做准备。
- `generation.md` 内的 4 个端 domain（APP/Frontend/Backend/Industry）可拆为并行 sub-agent，各自消费 `code_facts`，对应 Anthropic Parallelization 模式。
- `review-and-quality-gate.md` 7 个 persona 可拆为 orchestrator-workers，并行执行 + aggregator 收口。
- `profile-and-batch-planner.md` 可集成 tree-sitter 符号层扫描（Aider repo-map 模式），替代纯目录扫描，提升 batch 候选质量。
- Generation 输出多格式 artifacts：同时生成 `AGENTS.md`、`.cursor/rules/`、`CLAUDE.md` 兼容格式。
