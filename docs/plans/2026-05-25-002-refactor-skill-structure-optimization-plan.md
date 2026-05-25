---
spec_id: 2026-05-25-002
plan_id: 2026-05-25-002-refactor-skill-structure-optimization
title: "refactor: project-standard-extractor skill 目录结构合规化"
type: refactor
status: completed
date: 2026-05-25
author: 矿工
origin: docs/brainstorms/2026-05-25-002-skill-structure-optimization-requirements.md
note: origin 文档无 spec_id，plan-local spec_id 生成，origin identity 未继承
---

# refactor: project-standard-extractor skill 目录结构合规化

## Problem Frame

`skills/project-standard-extractor` 同时服务两个场景：本仓库 AI 会话直接引用，以及通过 `package_skill.py` 打包为 `.skill` 分发包。当前结构违反 skill-creator 硬性规则（7 个禁止文件），目录命名不符合标准（`references/`、`assets/` 约定），`evals/` 开发支撑文件混入分发包，SKILL.md 143 行超过建议上限。

**关键约束**：`package_skill.py` 用 `rglob('*')` 全量打包，不支持 `.skillignore`，因此需排除出分发包的文件必须物理移出 skill 目录。（see origin: `docs/brainstorms/2026-05-25-002-skill-structure-optimization-requirements.md §关键约束发现`）

## Scope Boundaries

**In scope**
- 删除 skill-creator 硬性禁止的 9 个辅助文档类文件
- 将 `evals/` 物理迁移到 `docs/evals/project-standard-extractor/`
- 重命名 5 个目录：`references/agents/`、`references/config/`、`references/prompts/`、`assets/` 以及将 `references/workflow.md`、`references/quality-gate.md`、`examples/` 归入 `references/`
- 更新 skill 内所有受影响文件的路径引用字符串（纯字符串替换，不改逻辑）
- 精简 SKILL.md 至 ≤ 100 行，优化 description 字段

**Deferred to Follow-Up Work**
- 修改 `package_skill.py` 以支持 `.skillignore` 机制
- 为 agent 合约补充 Claude Agent SDK sub-agent frontmatter
- `evals/` 接入 CI 自动化执行

**Out of scope (non-goals)**
- 修改任何 agent 合约的执行逻辑或 YAML/JSON 的内容语义
- 修改 `references/config/dimension-framework/` 的内部文件结构
- 修改 `assets/skeletons/` 的文件名映射
- 修改 `scripts/` 脚本内容

---

## Graph Readiness

- target_repo: ai-engineering-standards
- status: unavailable
- fallback_capabilities: bounded direct repo reads
- runtime_mcp_evidence: not applicable
- confidence: n/a
- limitations: 此 refactor 仅操作文件系统（删除、移动、重命名、字符串替换），不涉及代码语义分析，graph 能力不影响计划质量

---

## Context & Research

**路径引用规模扫描**（`grep -rn` 基线，已过滤待删除文件）

| 文件 | 旧路径引用数（估）|
|---|---|
| `SKILL.md` | 12 |
| `references/quality-gate.md` → 迁入 `references/` | 9 |
| `references/workflow.md` → 迁入 `references/` | ~8 |
| `references/agents/generation.md` → 迁入 `references/agents/` | ~5 |
| `references/agents/dimension-activator.md` → 迁入 `references/agents/` | ~4 |
| `references/agents/merge-coordinator.md` → 迁入 `references/agents/` | ~3 |
| `references/prompts/orchestrator/force-rebuild/*.md` | ~5 |
| `references/examples/phase-2/force-rebuild-walkthrough.md` → 迁入 `references/examples/phase-2/` | 2 |

约 13 个文件含需更新的路径引用，路径字符串变更为机械替换（不改内容语义）。

**不动项**
- `references/config/dimension-framework/` 内部 YAML 间相互引用使用相对路径，目录整体移动后内部引用仍有效
- `assets/skeletons/` 文件名被 `references/agents/generation.md` 和 `references/agents/dimension-activator.md` 显式枚举，但枚举值本身是文件名（非路径前缀），更新 `assets/skeletons/` → `assets/skeletons/` 后即保持正确

**待删除文件中的路径引用不需要处理**（U1 删除后自然消除）：`README.md`（8 处）、`usage-guide.md`（8 处）、`installation-or-consumption.md`（4 处）、`references/agents/README.md`（10 处）、`scripts/README.md`、`references/config/backup/README.md`。

---

## Key Technical Decisions

| 决策 | 选择 | 理由 |
|---|---|---|
| evals/ 处置 | 物理移出到 `docs/evals/project-standard-extractor/` | `package_skill.py` 全量打包，移出是唯一不改工具的干净方案 |
| .skillignore | 不引入 | evals/ 移出后不再需要；改打包工具超出范围 |
| references/examples/phase-2/ walkthrough | 保留到 `references/examples/phase-2/` | 4 个 walkthrough 是用户 onboarding 文档（force-rebuild/diff/cross-project/securities） |
| references/config/dimension-framework/ 内部 | 不动 | YAML 间相对路径引用，整体移动后不需要更新 |
| SKILL.md 铁律迁移 | 移至 `references/workflow.md` 末尾，SKILL.md 留 1 句摘要+链接 | 避免信息丢失，同时控制 SKILL.md 行数 |

---

## Implementation Units

### U1. Phase A — 删除禁止文件 + 迁移 evals/

**Goal**: 消除 skill-creator P0 硬性违规，将 evals/ 物理迁出 skill 目录，分发包边界即刻干净。

**Requirements**: 满足需求 §P0、§P2（evals/ 问题）；达成验收标准 Phase A。

**Dependencies**: 无。

**Files**
- `skills/project-standard-extractor/README.md` → 删除
- `skills/project-standard-extractor/usage-guide.md` → 删除
- `skills/project-standard-extractor/installation-or-consumption.md` → 删除
- `skills/project-standard-extractor/input-guide.md` → 删除
- `skills/project-standard-extractor/references/agents/README.md` → 删除
- `skills/project-standard-extractor/scripts/README.md` → 删除
- `skills/project-standard-extractor/references/config/backup/README.md` → 删除
- `skills/project-standard-extractor/examples/consistency-checklist.md` → 删除
- `skills/project-standard-extractor/references/examples/phase-2/integration-validation-report.md` → 删除
- `skills/project-standard-extractor/evals/` → 整目录移动（`mv`）到 `docs/evals/project-standard-extractor/`（目录为新建）
- `skills/project-standard-extractor/SKILL.md` → 删除 3 处已删文件的引用行（`usage-guide.md`、`installation-or-consumption.md`、`input-guide.md`），不改其他内容
- `skills/project-standard-extractor/OPTIMIZATION-PLAN.md` → 删除（开发执行草案，不进入分发包）

**Approach**
1. 依次删除 9 个文件（顺序不限）
2. 推荐：`mkdir -p docs/evals && mv skills/project-standard-extractor/evals docs/evals/project-standard-extractor`（先建父目录，再整体重命名；`docs/evals/` 必须不存在才能直接重命名成功）。备选：`mkdir -p docs/evals/project-standard-extractor && mv skills/project-standard-extractor/evals/* docs/evals/project-standard-extractor/ && rmdir skills/project-standard-extractor/evals`（逐文件迁移内容，注意 `dimension-framework/` 子目录也会一起移动）
3. 在 SKILL.md §关键引用表中定位并删除 `usage-guide.md`、`installation-or-consumption.md`、`input-guide.md` 对应的 3 行；保留其余所有内容

**Patterns to follow**: 参照 `git rm` 删除已跟踪文件；`mkdir -p` 创建目标目录。

**Test scenarios**
- **验收 A-1（删除完整）**：`find skills/project-standard-extractor -maxdepth 1 -name "*.md" | sort` 只输出 `SKILL.md`
- **验收 A-2（evals 迁移完整）**：`ls docs/evals/project-standard-extractor/dimension-framework/ | wc -l` 输出 `12`；`ls docs/evals/project-standard-extractor/` 含 `trigger-cases.md`、`boundary-cases.md`、`failure-cases.md`、`expected-behavior.md`
- **验收 A-3（skill 内无 evals/）**：`find skills/project-standard-extractor -type d -name "evals"` 无输出
- **验收 A-4（SKILL.md 引用清洁）**：`grep "usage-guide\|installation-or-consumption\|input-guide" skills/project-standard-extractor/SKILL.md` 无输出

**Verification**: 上述 4 条 shell 命令全部通过即完成。

---

### U2. Phase B — 目录重命名 + 内部路径引用更新

**Goal**: 将 skill 子目录重命名为 skill-creator 标准名称，并更新所有文件内的路径引用字符串，使 skill 本体可直接通过 `package_skill.py` 打包、结构符合生态约定。

**Requirements**: 满足需求 §P1；达成验收标准 Phase B。

**Dependencies**: U1（被删文件的路径引用消除后，更新范围更小）。

**Files**
- 目录操作（不改文件内容）：
  - `skills/project-standard-extractor/references/agents/` → `skills/project-standard-extractor/references/agents/`
  - `skills/project-standard-extractor/references/config/` → `skills/project-standard-extractor/references/config/`
  - `skills/project-standard-extractor/references/prompts/` → `skills/project-standard-extractor/references/prompts/`
  - `skills/project-standard-extractor/assets/` → `skills/project-standard-extractor/assets/`
  - `skills/project-standard-extractor/references/workflow.md` → `skills/project-standard-extractor/references/workflow.md`
  - `skills/project-standard-extractor/references/quality-gate.md` → `skills/project-standard-extractor/references/quality-gate.md`
  - `skills/project-standard-extractor/examples/` → `skills/project-standard-extractor/references/examples/`（含 phase-2/ 子目录，但已删除 integration-validation-report.md）
- 路径引用更新（字符串替换）：
  - `skills/project-standard-extractor/SKILL.md`
  - `skills/project-standard-extractor/references/workflow.md`
  - `skills/project-standard-extractor/references/quality-gate.md`
  - `skills/project-standard-extractor/references/agents/dimension-activator.md`
  - `skills/project-standard-extractor/references/agents/generation.md`
  - `skills/project-standard-extractor/references/agents/merge-coordinator.md`
  - `skills/project-standard-extractor/references/agents/backup-manager.md`
  - `skills/project-standard-extractor/references/agents/facts-and-classification.md`
  - `skills/project-standard-extractor/references/agents/intake-and-scope.md`
  - `skills/project-standard-extractor/references/agents/review-and-quality-gate.md`
  - `skills/project-standard-extractor/references/prompts/orchestrator/force-rebuild/force-rebuild.md`
  - `skills/project-standard-extractor/references/prompts/orchestrator/force-rebuild/changelog-append.md`
  - `skills/project-standard-extractor/references/prompts/orchestrator/force-rebuild/backup-manager.md`
  - `skills/project-standard-extractor/references/examples/phase-2/force-rebuild-walkthrough.md`
  - 删除对 `scripts/backup.sh` 与 `references/config/backup/manifest-schema.json` 的旧引用，改由 `scripts/backup.sh` / `scripts/force-rebuild-validate.sh` 与 `references/config/backup/manifest-schema.json` 承担说明职责

**Approach**

**步骤 1 — 建立基线**（先于任何移动操作）

```
grep -rn "references/agents/\|references/config/\|references/prompts/\|assets/\|quality-gate\.md\|workflow\.md\b\|examples/" \
  --include="*.md" --include="*.yaml" \
  skills/project-standard-extractor/ \
  | grep -v OPTIMIZATION-PLAN \
  > /tmp/path-refs-baseline.txt
```

记录总行数。Phase B 完成后用相同命令（加 `grep -v "references/"` 排除合法新路径）验证归零：与 B-2 验收命令对齐。

**步骤 2 — 目录移动**（先移目录，暂不改内容）

```
mkdir -p skills/project-standard-extractor/references
mv skills/project-standard-extractor/agents  skills/project-standard-extractor/references/agents
mv skills/project-standard-extractor/config  skills/project-standard-extractor/references/config
mv skills/project-standard-extractor/prompts skills/project-standard-extractor/references/prompts
mv skills/project-standard-extractor/templates skills/project-standard-extractor/assets
mv skills/project-standard-extractor/references/workflow.md  skills/project-standard-extractor/references/workflow.md
mv skills/project-standard-extractor/references/quality-gate.md skills/project-standard-extractor/references/quality-gate.md
mv skills/project-standard-extractor/examples skills/project-standard-extractor/references/examples
```

**步骤 3 — 路径字符串替换**（每个文件用 Edit 工具逐文件精确替换）

替换映射（skill-root-relative 路径，不影响 YAML 内部相对路径）：

| 旧字符串 | 新字符串 |
|---|---|
| `references/agents/` | `references/agents/` |
| `references/config/dimension-framework` | `references/config/dimension-framework` |
| `references/config/frontmatter-format` | `references/config/frontmatter-format` |
| `references/config/output-targets` | `references/config/output-targets` |
| `references/config/backup/` | `references/config/backup/` |
| `references/config/extraction-batch-policy` | `references/config/extraction-batch-policy` |
| `references/config/context-governance` | `references/config/context-governance` |
| `references/config/task-tags` | `references/config/task-tags` |
| `references/config/domain-taxonomy` | `references/config/domain-taxonomy` |
| `references/config/domain-sampling-adapters` | `references/config/domain-sampling-adapters` |
| `references/prompts/signal-library` | `references/prompts/signal-library` |
| `references/prompts/orchestrator` | `references/prompts/orchestrator` |
| `references/prompts/gitnexus` | `references/prompts/gitnexus` |
| `assets/skeletons` | `assets/skeletons` |
| `assets/standard-template` | `assets/standard-template` |
| `assets/` 其他引用 | `assets/` |
| `references/quality-gate.md` | `references/quality-gate.md` |
| `references/workflow.md` | `references/workflow.md` |
| `references/examples/golden-sample` | `references/examples/golden-sample` |
| `references/examples/thin-dogfood` | `references/examples/thin-dogfood` |
| `references/examples/phase-2` | `references/examples/phase-2` |

**注意**：`references/config/dimension-framework/` 内部文件（YAML 之间的相互引用）使用 `./` 开头的相对路径，不是 skill-root-relative，**不需要更新**。`assets/skeletons/` 下文件名本身不变，只需更新引用这些文件的**路径前缀**。

**Patterns to follow**: 用 Edit 工具逐文件替换，保留上下文验证替换正确性；不使用 global sed -i（防止误替换上下文中不该动的字符串）。

**Test scenarios**
- **验收 B-1（顶级目录结构）**：`find skills/project-standard-extractor -maxdepth 1 -type d | sort` 只含 `references/`、`assets/`、`scripts/`（不含 `references/agents/`、`references/config/`、`references/prompts/`、`assets/`、`examples/`）
- **验收 B-2（旧路径引用归零）**：`grep -rn "references/agents/\|references/config/\|references/prompts/\|assets/" --include="*.md" --include="*.yaml" skills/project-standard-extractor/ | grep -v OPTIMIZATION-PLAN | grep -v "references/"` 无输出
- **验收 B-3（新路径引用有效）**：抽查 3 个引用链路：
  1. `SKILL.md` 中 `references/agents/intake-and-scope.md` 对应文件存在
  2. `references/agents/generation.md` 中 `assets/skeletons/` 对应目录存在
  3. `references/workflow.md` 中 `references/config/dimension-framework/baseline-dimensions.yaml` 对应文件存在
- **验收 B-4（打包验证）**：`python skill-creator/scripts/package_skill.py skills/project-standard-extractor` 退出码 0；且 `unzip -l project-standard-extractor.skill | grep "evals/"` 无输出（evals/ 未打包）
- **验收 B-5（dimension-framework 内部不动）**：`grep -rn "\.\./\|\./" skills/project-standard-extractor/references/config/dimension-framework/ --include="*.yaml"` 的输出与 Phase B 前一致（内部相对路径未被误改）

**Verification**: 上述 5 条验收全部通过。

---

### U3. Phase C — SKILL.md 精简 + description 优化

**Goal**: SKILL.md 行数降至 ≤ 100，关键引用表用分组格式重构，铁律细节移入 `references/workflow.md`，description 字段补充英文触发关键词提升跨语言触发准确率。

**Requirements**: 满足需求 §P3；达成验收标准 Phase C。

**Dependencies**: U2（SKILL.md 中的路径引用已更新为新路径后，再做内容精简，避免两次编辑同一文件）。

**Files**
- `skills/project-standard-extractor/SKILL.md` — 精简正文 + 更新 frontmatter description
- `skills/project-standard-extractor/references/workflow.md` — 追加"铁律"节（从 SKILL.md 迁入的 5 条铁律内容）

**Approach**

**SKILL.md 精简操作（目标 ≤ 100 行）**

1. **frontmatter description 优化**（约 +2 行）：在现有中文描述后补充英文 "Use when" 子句，示例：
   > 从存量项目代码反向还原结构化团队规范，输出 standard-*.md / ai-rules.md / review-checklist.md。Use when: user provides project_paths and requests extracting/generating engineering standards, coding conventions, or AI rules from code; or asks to reverse-engineer team standards from an existing codebase. Do not trigger for: code review, single-file analysis, or querying existing standards.

2. **§维度激活态对外说明**：5 状态表格保留（约 9 行）；5 条铁律段落（约 18 行）剪切，追加到 `references/workflow.md` 末尾新增 `## 铁律（来自 SKILL.md）` 节；SKILL.md 在表格下方加 1 行摘要 `> 详细铁律见 [references/workflow.md](references/workflow.md#铁律)`

3. **§强制边界**：现有 10 条条目保留编号和核心约束，删除每条下方的说明段落（约 25 行 → 约 12 行表格）

4. **§关键引用**：现有 14 行平铺改为 4 类分组（执行入口 / Agent 合约 / 配置与维度 / 质量门禁），约 14 行 → 约 10 行

净减少：约 46 行（铁律 18 行 + 强制边界段落 13 行 + 引用表 4 行 + 细节 11 行）

**不动内容**：调用协议 YAML 字段定义、互斥规则 R91/R92、7-stage ASCII 执行图、Step 1-3 结构

**Patterns to follow**: `edit` 工具精确替换特定段落，每次替换附上 before/after 对比确认行数减少方向正确。

**Test scenarios**
- **验收 C-1（行数）**：`wc -l skills/project-standard-extractor/SKILL.md` ≤ 100
- **验收 C-2（description 含英文触发词）**：`grep "Use when" skills/project-standard-extractor/SKILL.md` 有输出
- **验收 C-3（铁律完整迁移）**：`grep "CANDIDATE_LEAKED_TO_STANDARD\|PENDING_FORCED_TO_ACTIVE\|SHALLOW_MISSING" skills/project-standard-extractor/references/workflow.md` 有输出（原铁律关键词已移入 references/workflow.md）
- **验收 C-4（调用协议完整）**：`grep "project_paths\|output_action\|extraction_mode\|run_mode" skills/project-standard-extractor/SKILL.md` 仍有输出（YAML 字段未被误删）
- **验收 C-5（快速验证）**：`python skill-creator/scripts/quick_validate.py skills/project-standard-extractor` 退出码 0

**Verification**: 5 条验收全部通过；在 Claude Code 会话中 `@SKILL.md` 后 AI 能正确导航到 `references/` 下的 agent 合约。

---

## Risks

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| U2 路径替换遗漏，AI 执行萃取时读不到 references 文件 | 中 | 高 | 验收 B-2 的 grep 命令精确覆盖，Phase B 前建基线文件 `/tmp/path-refs-baseline.txt` 对比 |
| `assets/skeletons/` 路径前缀替换误改内部文件名枚举 | 低 | 中 | 验收 B-3 抽查链路；替换时限定"路径前缀"而非文件名字符串 |
| U3 精简 SKILL.md 时误删调用协议 YAML 或 ASCII 图 | 低 | 高 | 验收 C-4 检查 YAML 字段存在；Edit 工具精确替换段落，不做大段整段 rewrite |
| `references/config/dimension-framework/` 内 YAML 内部相对路径被误改 | 低 | 高 | 验收 B-5 专门检查此路径的 YAML 引用不变 |

---

## Sequencing

```
U1 (Phase A) → U2 (Phase B) → U3 (Phase C)
```

每阶段独立验收后再进入下一阶段。U1 不影响任何路径引用（删除即消除），可安全先行；U2 在 U1 完成后路径引用范围最小；U3 在 U2 完成后路径已是新路径，精简时无需同时处理路径变更。

---

## Deferred Notes

- OPTIMIZATION-PLAN.md 已删除；本计划完成后只保留 `SKILL.md` 作为 skill 入口
- `docs/evals/project-standard-extractor/` 是迁移后的项目级回归锚点，不进入 skill 分发包
- 若 U2 执行中发现某 agent 合约含硬编码文件名（非路径前缀）引用，实施者可在不改逻辑的前提下局部处理并记录
- `docs/evals/project-standard-extractor/` 内部的路径引用（如 `references/agents/backup-manager.md`、`references/prompts/orchestrator/...`）指向 Phase B 前的旧路径；维护者使用 evals 时按新路径 `references/agents/`、`references/config/` 等对照即可，evals 本身不需要同步更新
- U3 的 C-5（`quick_validate.py`）只检查 frontmatter 格式，不验证 description 内容；C-2 的 `grep "Use when"` 是独立的内容验收，两者测量不同维度，不能互相替代
