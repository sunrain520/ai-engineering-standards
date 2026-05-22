# Workflow

## 1. 执行模式

| run_mode | 说明 | 适用场景 |
| --- | --- | --- |
| `auto`（默认） | Skill 自动调度所有 agent，遍历全部 ready batch，无中途停顿 | 日常使用、首次建设 domain 规范 |
| `interactive` | 每个关键决策点暂停等待用户确认，逐步推进 | 高风险场景、需要精细控制时 |

**auto 模式是默认行为**，用户只需提供 `project_paths`，最后审查 `{run_id}-review-summary.md`。

---

## 2. Auto 模式执行流程

```
project_paths
    │
    ▼
[Agent 1] intake-and-scope
    推断 domain / sub_domain / extraction_mode / 敏感策略
    auto 模式：只有 NO_VALID_PROJECT_PATHS 或 ALL_PATHS_SENSITIVE 才停止
    输出: scope_summary, run_id
    │
    ▼
[Agent 2] profile-and-batch-planner
    轻量扫描（≤30 文件，≤3 层）
    生成 project-profile + extraction-map + batch-plan
    auto 模式：生成 ordered_batch_queue（所有 ready batch，按优先级排序）
    输出: {run_id}-project-profile.md
          {run_id}-extraction-map.md
          {run_id}-batch-plan.md
          ordered_batch_queue[]
    │
    ▼
    ┌─── NO_READY_BATCHES? ──→ 输出 profile + batch-plan，说明原因，结束
    │
    ▼
╔════════════════════════════════════════════════════╗
║  批次执行循环 (FOR EACH batch IN ordered_batch_queue) ║
║                                                    ║
║  [Agent 3] facts-and-classification               ║
║      只读 batch.candidate_files（evidence_limit）  ║
║      先输出事实 → 再分类                           ║
║      输出: code_facts + classification             ║
║      失败时: 标记 skipped，记录原因，continue      ║
║                      ↓                            ║
║  [Agent 4] generation                             ║
║      Sub-step A: 写 evidence/* (EV/POS/NEG/LEG)   ║
║      Sub-step B: 综合编写 Developer Guide          ║
║        → standard-{sub_domain}.md                 ║
║          若文件已存在: 补充缺失章节，不覆盖已有    ║
║          若文件不存在: 按模板全新生成              ║
║      Sub-step C: 派生 ai-rules + review-checklist ║
║      Sub-step D: 生成候选索引产物                  ║
║      失败时: 标记 failed，记录原因，continue       ║
║                      ↓                            ║
║  [Agent 5] review-and-quality-gate               ║
║      7 persona 评审（pass/warn/block）             ║
║      Proposer-Challenger-Arbiter 冲突仲裁          ║
║      输出: quality_gate_decisions[]               ║
║                      ↓                            ║
║  [Agent 6] merge-coordinator                     ║
║      append-only 写入规范目录                      ║
║      draft → standard-*.md / ai-rules / checklist ║
║      pending → pending-confirmation.md            ║
║      conflict → conflicts.md                     ║
║      similar → merge-suggestions.md              ║
║      记录本 batch 的 run_log 条目                  ║
╚════════════════════════════════════════════════════╝
    │
    ▼（所有 batch 执行完毕）
[最终步骤] 生成 {run_id}-review-summary.md
    汇总: 所有 batch 执行状态
          所有新增/更新的文档清单
          所有 FORBIDDEN 和高风险规则
          pending-confirmation 项目清单
          conflicts 清单
          负责人确认项
    │
    ▼
用户审查 review-summary.md
    ↓ 删除不认可的内容（规则节、章节或整份文档）
    ↓ 修改不准确的描述
    ↓ 对 conflict / pending 做裁定
    ↓ 对认可的 draft 规则，由领域负责人显式确认后手动升级为 active
```

---

## 3. 各阶段详细说明

### 阶段 1：intake-and-scope

**auto 模式行为**（区别于 interactive 模式）：

| 信息项 | interactive | auto |
| --- | --- | --- |
| project_paths 可读性 | 确认后继续 | 不可读则停止；可读则直接继续 |
| domain 推断 | 等用户确认 | 自动推断，记录推断依据到 run_log |
| sub_domain 推断 | 等用户确认 | 自动推断，置信度 low 的标记到 review-summary |
| 敏感文件 | 等用户确认排除策略 | 自动应用 sanitized-existence-only 策略 |
| extraction_mode | 等用户确认 | 自动判定（broad → profile-first；narrow → batch-extraction） |
| batch 选择 | 等用户选择 | 自动生成 ordered_batch_queue，跳过此确认 |

**强制停止条件（auto 模式下唯一停止点）**：

- `NO_VALID_PROJECT_PATHS`：所有路径不可读
- `ALL_PATHS_SENSITIVE`：所有路径均触发敏感策略

输出：`scope_summary`（含 `run_mode: auto`）

---

### 阶段 2：profile-and-batch-planner

**auto 模式附加输出**：除原有 3 个 artifact 外，额外输出：

```yaml
ordered_batch_queue:
  - batch_id: "app-client-android-core-ui-state"
    priority: high
    estimated_doc: "standard-android.md"
    status: ready
  - batch_id: "app-client-kmp-shared-trade-order"
    priority: high
    estimated_doc: "standard-kmp-shared.md"
    status: ready
  - batch_id: "app-client-module-boundary-contract"
    priority: medium
    estimated_doc: "standard-module-boundary.md"
    status: ready
  # pending-confirmation 和 skipped 不进入队列
```

**优先级排序规则**：

1. 已有 owner-confirmed 文档可对照的 batch → `high`
2. 对应多个候选文件且结构清晰的 batch → `high`
3. 单模块局部 batch → `medium`
4. 行业高风险或需要负责人确认的 batch → `low`（仍自动执行，但 review-summary 特别标注）

---

### 阶段 3：facts-and-classification（每 batch 执行一次）

与现有契约相同，新增 auto 模式 skip 条件：

- 候选文件全不可读 → `BATCH_INSUFFICIENT_EVIDENCE`，跳过，记录
- 所有候选为敏感文件 → `BATCH_ALL_SENSITIVE`，跳过，记录

---

### 阶段 4：generation（每 batch 执行一次）

**多 batch 写入同一文档的一致性规则**：

当 `standard-{sub_domain}.md` 已存在（之前的 batch 已写入）：

1. 读取现有文档，扫描已有章节标题
2. 本次 batch 只**补充缺失章节**，不重写已有章节
3. 若本次 batch 有与已有章节相关的新 evidence，追加到该章节末尾的 Evidence 参考表格
4. 新的完整角色/层级 → 新增对应节
5. 不重复生成已存在内容

---

### 阶段 5：review-and-quality-gate（每 batch 执行一次）

与现有契约相同。输出 `quality_gate_decisions` 传给 Agent 6。

---

### 阶段 6：merge-coordinator（每 batch 执行一次 + 全量完成后 1 次）

**每 batch 执行**：append-only 写入（与现有契约相同）

**全量完成后执行一次**：生成 `{run_id}-review-summary.md`（见模板 `templates/review-summary-template.md`）

---

### 最终步骤：review-summary 生成

在所有 batch 循环结束后，merge-coordinator 执行最后一步：汇总整个 run 的所有变更并生成 review-summary。

---

## 4. Interactive 模式（保留）

interactive 模式保留原有逐步确认行为：

1. intake-and-scope 逐项确认（10 步确认协议）
2. profile-and-batch-planner 输出 batch-plan 后暂停，等用户选择 1 个 batch
3. 每个 batch 完成后暂停，用户决定是否继续下一个

适用场景：首次探索新域、高风险项目、需要精细控制的场景。

---

## 5. 文档一致性保证

多 batch 顺序写入同一 domain 目录时，最终文档应读起来像一份完整的规范体系，而不是多次追加的碎片：

| 文件 | 写入策略 |
| --- | --- |
| `standard-{sub_domain}.md` | 每个 sub_domain 一份；同 sub_domain 多次 batch 补充章节 |
| `ai-rules.md` | 每次 batch 追加对应 sub_domain 的 AI 规则段 |
| `review-checklist.md` | 每次 batch 追加对应 sub_domain 的检查项段 |
| `evidence/*` | 追加新条目（编号不复用） |
| `pending-confirmation.md` | 追加 |
| `conflicts.md` | 追加 |
| `merge-suggestions.md` | 追加 |
