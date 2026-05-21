# Internal Agent Contracts

第一阶段不把内部 agent 落成独立可执行进程，而是定义阶段 role contracts。宿主支持 subagent 时可以按这些合约拆分执行；宿主不支持时，由一个 agent 按阶段顺序执行。

## 阶段文件

| 文件 | 阶段 |
| --- | --- |
| `intake-and-scope.md` | 输入引导、范围确认、敏感文件策略 |
| `facts-and-classification.md` | 代码事实萃取、正反例、历史兼容、分类 |
| `generation.md` | 规范、AI Rules、Review Checklist、evidence 生成 |
| `review-and-quality-gate.md` | 分面评审和质量门禁 |
| `merge-coordinator.md` | append-only 合并和冲突处理 |

## 共同规则

1. 生成阶段不得绕过 `code-facts`。
2. 规则正文不得写真实代码路径。
3. 无证据内容不得进入 AI 可执行 `draft`。
4. 所有高风险规则必须输出 warning。
5. 所有阶段必须保留不确定点。

## R13 角色 → 阶段合约映射

第一阶段 V1 把 brainstorm `R13` 列出的 20 个 agent 角色按职责合并进 5 个 phase contract。下表给出每个角色的 documented home，便于宿主在支持 subagent 时按角色拆分执行。

| brainstorm 角色 | 阶段合约 | 在合约中的职责段 |
| --- | --- | --- |
| Intake | `intake-and-scope.md` | 输入收集、确认声明 |
| Project Profiler | `intake-and-scope.md` | 推断研发域、子领域和行业 |
| Evidence Collector | `facts-and-classification.md` | 代码路径与文档证据采集 |
| Code Facts | `facts-and-classification.md` | `code_facts` 输出 |
| Pattern Classifier | `facts-and-classification.md` | `classification` 桶 |
| APP Standard | `generation.md` | 端 `standard.md` 生成（domain=APP） |
| Frontend Standard | `generation.md` | 端 `standard.md` 生成（domain=Frontend） |
| Backend Standard | `generation.md` | 端 `standard.md` 生成（domain=Backend） |
| Industry Standard | `generation.md` | 行业 `standard.md` 生成（domain=Industry） |
| AI Rules | `generation.md` | `ai-rules.md` 生成 |
| Review Checklist | `generation.md` | `review-checklist.md` 生成 |
| Evidence Writer | `generation.md` | `evidence/*` 写入 |
| Evidence Auditor | `review-and-quality-gate.md` | Review persona：证据 |
| Team Standard Reviewer | `review-and-quality-gate.md` | Review persona：团队级抽象 |
| AI Executability Reviewer | `review-and-quality-gate.md` | Review persona：AI 可执行性 |
| Review Checklist Reviewer | `review-and-quality-gate.md` | Review persona：Review 可检查性 |
| Conflict Reviewer | `review-and-quality-gate.md` | Review persona：冲突 |
| Industry Risk Reviewer | `review-and-quality-gate.md` | Review persona：行业风险 |
| Quality Gate | `review-and-quality-gate.md` | 汇总 `quality_gate_decision` |
| Merge Coordinator | `merge-coordinator.md` | append-only 写入与冲突落点 |

后续如果某个 phase contract 内部某个角色被多 Skill 复用，再考虑提升为独立合约或一级 `agents/`。
