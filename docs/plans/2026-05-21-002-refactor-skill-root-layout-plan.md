---
title: "refactor: Move project-standard-extractor to root skills directory"
type: refactor
status: completed
date: 2026-05-21
spec_id: 2026-05-21-002-skill-root-layout
origin: none
---

# refactor: Move project-standard-extractor to root skills directory

## Summary

本计划将 `project-standard-extractor` 从 `engineering-standards/08-ai-coding/` 迁移到一级 `skills/` 目录，使“工具 / workflow”和“规范结果文档”分离。`agents/` 暂不升为一级目录，继续作为 `project-standard-extractor` 的内部阶段合约。

---

## Problem Frame

当前 `project-standard-extractor` 源包位于：

```text
engineering-standards/08-ai-coding/project-standard-extractor/
```

这个位置可以运行，但语义上把“生成规范的工具”放进了“规范结果文档”目录。随着仓库定位逐步清晰，用户会同时面对两类资产：

1. `engineering-standards/`：给人和 AI 使用的规范结果文档。
2. Skill：生成、萃取、评审规范的工具 / workflow。

如果二者继续混放，后续安装说明、入口文档、目录索引和用户心智都会变复杂。因此需要一次目录重构，把 Skill 源包迁移到一级 `skills/`，并同步更新引用。

---

## Requirements

- R1. 新增一级 `skills/` 目录，作为 Skill source package 的 canonical home。
- R2. 将 `project-standard-extractor` 整体迁移到 `skills/project-standard-extractor/`，保持内部文件结构不变。
- R3. `agents/` 暂不拆成一级目录；保留为 `skills/project-standard-extractor/agents/`。
- R4. `engineering-standards/` 只保留规范结果文档、AI 输入规范、Review 规则和 prompts，不再承载 Skill 源包。
- R5. 更新当前入口文档、安装说明、prompt 和配置引用，指向新的 `skills/project-standard-extractor/`。
- R6. 对历史计划和技术方案中的旧路径引用给出处理策略：当前使用入口必须更新；历史背景文档可保留旧路径时必须避免被误读为当前 canonical path。
- R7. 迁移后不得修改 `.agents/skills/**`、`.codex/**`、`.claude/**` 等 runtime mirror。
- R8. 迁移后需要验证不存在当前入口继续指向旧 canonical path，且 `SKILL.md` frontmatter 仍可解析。

---

## Assumptions

- A1. 当前目标是重构仓库源资产布局，不安装 Skill 到宿主 runtime。
- A2. `skills/` 未来可能容纳多个 Skill，但本次只迁移 `project-standard-extractor`。
- A3. 顶层公共 `agents/` 只有在多个 Skill 复用同一批 agent contract 时再引入；当前没有足够复用证据。
- A4. 迁移应尽量使用文件移动，避免重写 Skill 内容。

---

## Scope Boundaries

- 不改变 `project-standard-extractor` 的 workflow 语义。
- 不拆分 `project-standard-extractor` 为多个 Skill。
- 不新增一级公共 `agents/`。
- 不安装或同步 runtime Skill。
- 不修改生成镜像目录 `.agents/skills/**`、`.codex/**`、`.claude/**`。
- 不重写已完成计划的历史决策内容，除非该内容作为当前入口会误导用户。

### Deferred to Follow-Up Work

- 公共 `agents/` 目录：等至少两个 Skill 复用同一批 agent 合约后再规划。
- Skill 安装脚本或自动同步命令：作为后续工具化能力单独规划。
- 多 Skill marketplace / index：等 `skills/` 下存在多个稳定 Skill 后再规划。

---

## Graph Readiness

- target_repo: `.`
- status: unavailable
- source_revision: unavailable
- current_revision: unknown
- stale: unknown
- primary_providers: none
- degraded_providers: none
- fallback_capabilities: bounded direct repo reads
- runtime_mcp_evidence: not used
- confidence: high
- limitations: 本次是文档和目录布局重构，不依赖代码图谱或调用链影响分析。

---

## Context & Research

### Relevant Code and Patterns

- `engineering-standards/08-ai-coding/project-standard-extractor/` 是当前 Skill 源包，包含 `SKILL.md`、`workflow.md`、`agents/`、`templates/`、`prompts/`、`examples/`。
- `engineering-standards/README.md` 当前把 `08-ai-coding/` 描述为 AI 规则和 Skill 入口。
- `README.md` 当前把 `engineering-standards/08-ai-coding/project-standard-extractor/` 作为快速入口。
- `engineering-standards/prompts/project-standard-extraction-input.md` 和 `engineering-standards/prompts/project-standard-extractor-run.md` 引用旧 Skill 路径。
- `docs/01-版本路线/README.md`、`docs/02-技术方案/README.md` 引用旧 Skill 落地路径。
- `CHANGELOG.md` 需要记录用户可见目录结构变化。

### Institutional Learnings

- 当前没有 `docs/solutions/` 可复用经验。
- 最近一次实施计划已经明确：Skill source package 不应写入 generated runtime mirrors。

### External References

- 未使用外部资料。本次目录重构由当前仓库产品定位和 Skill 目录语义驱动。

---

## Key Technical Decisions

- `skills/` 作为一级目录：清晰表达“工具 / workflow”资产，和 `engineering-standards/` 的“规范结果文档”职责分离。
- 保留内部 `agents/`：当前 agents 是 `project-standard-extractor` 的阶段角色，不是跨 Skill 公共资产；提前升为一级目录会造成过度抽象。
- 不保留旧目录副本：避免两个 Skill 源包并存导致使用者不知道哪个是 canonical path。
- 可选保留旧路径说明：如需要兼容旧链接，可在 `engineering-standards/08-ai-coding/README.md` 或相关入口文档说明新路径，但不保留完整 Skill 资产副本。
- 当前入口文档优先更新：README、规范资产入口、安装说明、prompts 必须指向 `skills/project-standard-extractor/`。

---

## Open Questions

### Resolved During Planning

- 是否新增一级 `skills/`：是，作为 Skill source package 的 canonical home。
- 是否新增一级 `agents/`：否，当前 agents 继续作为 Skill 内部目录。
- 是否安装到 runtime：否，本次只重构源资产路径。

### Deferred to Implementation

- 是否需要在旧路径放置跳转 README：执行时根据旧目录是否还承载其他 AI 规则文件决定；如果旧目录为空或只剩通用 AI 文件，优先在 `engineering-standards/08-ai-coding/README.md` 说明 Skill 已迁移。
- 是否批量更新历史技术方案里的旧路径：执行时区分“历史记录”与“当前入口”；历史背景可保留，当前入口必须更新。

---

## Output Structure

```text
ai-engineering-standards/
├── skills/
│   ├── README.md
│   └── project-standard-extractor/
│       ├── SKILL.md
│       ├── README.md
│       ├── workflow.md
│       ├── input-guide.md
│       ├── installation-or-consumption.md
│       ├── config/
│       ├── agents/
│       ├── templates/
│       ├── prompts/
│       ├── quality-gate.md
│       └── examples/
├── engineering-standards/
│   ├── 00-global/
│   ├── 01-app-client/
│   ├── 03-frontend/
│   ├── 04-backend/
│   ├── 08-ai-coding/
│   ├── 09-industry/
│   └── prompts/
├── docs/
├── README.md
└── CHANGELOG.md
```

---

## Implementation Units

### U1. Move Skill Source Package

**Goal:** 将 `project-standard-extractor` 源包迁移到一级 `skills/`，并保持内部结构完整。

**Requirements:** R1, R2, R3, R4, R7

**Dependencies:** None

**Files:**
- Create: `skills/README.md`
- Move: `engineering-standards/08-ai-coding/project-standard-extractor/` -> `skills/project-standard-extractor/`

**Approach:**
- 使用文件移动保留目录内部结构。
- `skills/README.md` 定义一级 `skills/` 的职责、标准最小结构和复杂 workflow 推荐结构。
- 保持 `skills/project-standard-extractor/agents/` 不变。
- 不创建一级 `agents/`。

**Patterns to follow:**
- `skills/project-standard-extractor/SKILL.md` 的现有 source package 结构。
- 当前仓库不编辑 runtime mirrors 的边界。

**Test scenarios:**
- Test expectation: none -- 这是文档和目录布局变更，无行为代码。

**Verification:**
- `skills/project-standard-extractor/SKILL.md` 存在。
- `skills/project-standard-extractor/agents/README.md` 存在。
- `engineering-standards/08-ai-coding/project-standard-extractor/` 不再作为完整 Skill 源包存在。
- 未创建一级 `agents/`。

---

### U2. Update Current Entry References

**Goal:** 把当前用户入口和安装使用说明从旧路径更新到 `skills/project-standard-extractor/`。

**Requirements:** R5, R6, R8

**Dependencies:** U1

**Files:**
- Modify: `README.md`
- Modify: `engineering-standards/README.md`
- Modify: `docs/01-版本路线/README.md`
- Modify: `docs/02-技术方案/README.md`
- Modify: `skills/project-standard-extractor/README.md`
- Modify: `skills/project-standard-extractor/installation-or-consumption.md`
- Modify: `engineering-standards/prompts/project-standard-extraction-input.md`
- Modify: `engineering-standards/prompts/project-standard-extractor-run.md`
- Modify: `engineering-standards/prompts/draft-output-self-review.md`

**Approach:**
- 当前入口文档全部指向 `skills/project-standard-extractor/`。
- 安装说明示例使用新路径。
- prompt 中涉及 Skill 路径的地方改为新路径。
- `engineering-standards/08-ai-coding/` 只描述 AI 输入、自检、评审规则，不再描述为 Skill 源包所在地。

**Patterns to follow:**
- `README.md` 的快速入口表格。
- `skills/project-standard-extractor/installation-or-consumption.md` 的第一阶段边界说明。

**Test scenarios:**
- Test expectation: none -- 文档引用更新，无行为代码。

**Verification:**
- 当前入口文档中不再出现 `engineering-standards/08-ai-coding/project-standard-extractor/` 作为 canonical path。
- 安装说明中的复制源路径指向 `skills/project-standard-extractor/`。

---

### U3. Add Compatibility Notes For Historical References

**Goal:** 避免历史技术方案中的旧路径被误读为当前 canonical path，同时不重写历史决策文档。

**Requirements:** R6

**Dependencies:** U1, U2

**Files:**
- Modify: `docs/02-技术方案/第一阶段技术方案.md`
- Modify: `docs/plans/2026-05-21-001-feat-project-standard-extractor-plan.md`
- Optional Modify: `engineering-standards/08-ai-coding/README.md`

**Approach:**
- 在历史方案或已完成计划的顶部追加“路径迁移说明”，说明当前 canonical path 已迁移到 `skills/project-standard-extractor/`。
- 不逐行改写历史方案正文，避免破坏历史上下文。
- 如果 `engineering-standards/08-ai-coding/README.md` 不存在，则创建它作为 AI 规则目录入口，并指向新的 Skill 路径。

**Patterns to follow:**
- 当前 docs README 中“第一阶段实际落地基线”的提示风格。

**Test scenarios:**
- Test expectation: none -- 文档兼容说明，无行为代码。

**Verification:**
- 用户从历史方案顶部能看到当前 Skill canonical path。
- `engineering-standards/08-ai-coding/` 不再被误认为 Skill 源包目录。

---

### U4. Validate Layout And Update Changelog

**Goal:** 验证迁移完整性，并记录用户可见变更。

**Requirements:** R7, R8

**Dependencies:** U1, U2, U3

**Files:**
- Modify: `CHANGELOG.md`

**Approach:**
- 校验 `SKILL.md` frontmatter 仍可解析。
- 搜索旧 canonical path，确认只保留在历史说明、迁移说明或 changelog 中。
- 搜索一级 `agents/`，确认未新增。
- 搜索 runtime mirrors，确认未修改 `.agents/skills/**`、`.codex/**`、`.claude/**`。
- 更新 `CHANGELOG.md`，标记 `(user-visible)`。

**Patterns to follow:**
- `CHANGELOG.md` 当前格式。

**Test scenarios:**
- Test expectation: none -- 目录和文档验证，不涉及运行时代码。

**Verification:**
- `skills/project-standard-extractor/SKILL.md` frontmatter 可解析。
- `find skills/project-standard-extractor -maxdepth 3 -type f` 能看到完整源包。
- 当前入口文档指向新路径。
- 旧路径引用只存在于迁移说明或历史记录。
- `CHANGELOG.md` 有用户可见记录。

---

## System-Wide Impact

- **Interaction graph:** 用户入口从 `engineering-standards/08-ai-coding/project-standard-extractor/` 迁移到 `skills/project-standard-extractor/`。
- **Error propagation:** 如果旧路径引用未更新，用户安装或运行 Skill 会找不到源包。
- **State lifecycle risks:** 无规则状态变更；本次只移动 Skill 源包。
- **API surface parity:** Codex / Claude Code 的手动安装说明都应使用同一个新路径。
- **Integration coverage:** 通过 frontmatter 解析和路径搜索验证。
- **Unchanged invariants:** `project-standard-extractor` 内部 workflow、agents、templates、prompts、examples 不改变。

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| 旧路径引用遗漏 | 搜索 `engineering-standards/08-ai-coding/project-standard-extractor`，区分当前入口和历史说明 |
| 用户误以为 agents 是公共一级能力 | `skills/README.md` 和 Skill README 明确 agents 是内部合约 |
| 迁移后安装说明失效 | 更新 `installation-or-consumption.md` 和根 README |
| 历史计划被大规模改写 | 只追加迁移说明，不重写历史正文 |
| runtime mirror 被误改 | 验证 `.agents/skills/**`、`.codex/**`、`.claude/**` 没有本次变更 |

---

## Documentation / Operational Notes

- 执行迁移时优先使用 `mv` 保留文件历史。
- 如需兼容旧入口，只放 README 指引，不保留完整副本。
- 本计划完成后，可以继续用 `$spec-work docs/plans/2026-05-21-002-refactor-skill-root-layout-plan.md` 执行。

---

## Sources & References

- Related implementation plan: [docs/plans/2026-05-21-001-feat-project-standard-extractor-plan.md](2026-05-21-001-feat-project-standard-extractor-plan.md)
- Current Skill source package: `engineering-standards/08-ai-coding/project-standard-extractor/`
- Current standards entry: `engineering-standards/README.md`
- Current root entry: `README.md`
