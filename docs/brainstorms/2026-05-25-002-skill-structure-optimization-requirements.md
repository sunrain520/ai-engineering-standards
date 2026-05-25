---
doc_id: BST-2026-05-25-002
title: project-standard-extractor Skill 目录结构优化需求
status: draft
date: 2026-05-25
author: 矿工
tags: [skill, structure, optimization, project-standard-extractor]
---

# project-standard-extractor Skill 目录结构优化需求

## 背景

`skills/project-standard-extractor` 是 Spec-Driven Development 的源头工具，当前需同时满足两种交付场景：

1. **本仓库直接用**：工程师在此仓库的 AI 会话中直接引用 SKILL.md 驱动萃取流程
2. **打包为 .skill 分发**：通过 `skill-creator/scripts/package_skill.py` 打包为 `.skill` 文件，供其他团队或 AI 宿主安装

当前目录结构违反 skill-creator 硬性规则，同时存在上下文效率问题和分发包内容边界不清的问题。

### 关键约束发现

`package_skill.py` 用 `rglob('*')` 把整个 skill 目录无条件打包，**不支持 `.skillignore`**。因此，需要"排出分发包但保留在项目中"的文件，必须物理移出 skill 目录，而不是依赖排除配置文件。

---

## 问题陈述

### P0：硬性规则违反（skill-creator 明确禁止）

skill-creator 明确禁止在 skill 目录内创建辅助文档类文件（README.md、安装说明、使用指南等）。当前存在 7 个此类文件共 969 行：

| 文件 | 行数 |
|---|---|
| `README.md` | 72 |
| `usage-guide.md` | 264 |
| `installation-or-consumption.md` | 125 |
| `input-guide.md` | 287 |
| `references/agents/README.md` | 91 |
| `scripts/README.md` | 72 |
| `references/config/backup/README.md` | 58 |

这些文件在 AI 触发 skill 时不必要地占用上下文窗口，且会导致 `package_skill.py` 将用户文档打进分发包。

### P1：目录命名不符合 skill-creator 约定

skill-creator 定义了三个标准子目录：`scripts/`（可执行脚本）、`references/`（按需加载的参考文档）、`assets/`（输出用文件）。当前使用了 `references/agents/`、`references/config/`、`references/prompts/`、`assets/` 等非标准名称，导致：

- AI 在阅读 SKILL.md 时无法通过目录名推断内容性质
- 打包后的分发包结构与 skill-creator 生态不兼容

### P2：evals/ 混入 skill 目录

`evals/`（17 个文件，含 AE7–AE25 共 25+ 个回归用例）是维护者在修改 skill 后的回归检查基准，不是 AI 执行萃取时需要的文件。它不应出现在分发包中，但直接删除会丢失回归维护锚点。

### P3：SKILL.md 超过建议行数

SKILL.md 当前 143 行，超过 write-a-skill 推荐的 100 行上限。其中约 50 行是可外移的细节（铁律段落、强制边界说明段落），导致触发 skill 时加载了不必要的细节。

---

## 目标

1. **消除 P0 违规**：skill 目录内不再有 skill-creator 禁止的辅助文档
2. **结构符合标准**：顶层子目录只有 `references/`、`assets/`、`scripts/`（和 `evals/` 移走后）
3. **分发包干净**：`package_skill.py` 打包产物只含 AI 执行所需文件，不含维护工具文件
4. **上下文精简**：SKILL.md ≤ 100 行，detail 按需读取
5. **回归锚点保留**：evals/ 内容完整迁移到项目级，维护者仍可引用

---

## 非目标

- 修改 `package_skill.py` 或添加 `.skillignore` 机制
- 修改任何 agent 合约的执行逻辑
- 修改 `references/config/dimension-framework/` 或 `assets/skeletons/` 的内部结构
- 为 agent 合约添加 Claude Agent SDK sub-agent frontmatter
- 添加 CI 自动化执行 evals/

---

## 范围与变更清单

### 删除（P0 修复 + 纯开发自检文档）

| 文件 | 理由 |
|---|---|
| `skills/project-standard-extractor/README.md` | P0 硬性禁止 |
| `skills/project-standard-extractor/usage-guide.md` | P0 硬性禁止 |
| `skills/project-standard-extractor/installation-or-consumption.md` | P0 硬性禁止 |
| `skills/project-standard-extractor/input-guide.md` | P0 硬性禁止（核心内容已在 SKILL.md §调用协议）|
| `skills/project-standard-extractor/references/agents/README.md` | P0 硬性禁止（Handoff Chain 移入 references/workflow.md）|
| `skills/project-standard-extractor/scripts/README.md` | P0 硬性禁止（脚本边界说明移入 references/workflow.md 或 scripts 直接文档）|
| `skills/project-standard-extractor/references/config/backup/README.md` | P0 硬性禁止（备份治理说明移入 references/workflow.md 或删除）|
| `skills/project-standard-extractor/examples/consistency-checklist.md` | 纯开发自检，无用户价值 |
| `skills/project-standard-extractor/references/examples/phase-2/integration-validation-report.md` | 纯开发集成验证，无用户价值 |

### 移动到项目级（evals/ 物理迁出 skill 目录）

| 当前路径 | 目标路径 | 理由 |
|---|---|---|
| `skills/project-standard-extractor/evals/` | `docs/evals/project-standard-extractor/` | 维护者回归基准，不属于分发内容；`docs/` 已有 brainstorms/plans/reviews/solutions 等同类 |

迁移后 `docs/evals/project-standard-extractor/` 内容完整，与 `docs/brainstorms/` 中的 requirements doc 交叉引用关系不变（AE 编号体系保持）。

### 目录重命名（P1 修复）

| 当前路径 | 目标路径 | 分类依据 |
|---|---|---|
| `skills/project-standard-extractor/references/agents/` | `skills/project-standard-extractor/references/agents/` | phase contracts 是按需读取的参考文档 |
| `skills/project-standard-extractor/references/config/` | `skills/project-standard-extractor/references/config/` | 维度框架配置是参考文档 |
| `skills/project-standard-extractor/references/prompts/` | `skills/project-standard-extractor/references/prompts/` | signal-library + orchestrator prompt 是参考文档 |
| `skills/project-standard-extractor/assets/` | `skills/project-standard-extractor/assets/` | 输出用模板/骨架是 assets |
| `skills/project-standard-extractor/references/workflow.md`（顶级）| `skills/project-standard-extractor/references/workflow.md` | 按需读取的参考文档 |
| `skills/project-standard-extractor/references/quality-gate.md`（顶级）| `skills/project-standard-extractor/references/quality-gate.md` | 按需读取的参考文档 |

### 保留位置（移入 references/ 的 examples）

| 当前路径 | 目标路径 | 保留理由 |
|---|---|---|
| `skills/project-standard-extractor/references/examples/golden-sample-run.md` | `skills/project-standard-extractor/references/examples/golden-sample-run.md` | Phase 1 基础执行闭环参考 |
| `skills/project-standard-extractor/references/examples/thin-dogfood-run.md` | `skills/project-standard-extractor/references/examples/thin-dogfood-run.md` | 最小可行运行样例 |
| `skills/project-standard-extractor/references/examples/phase-2/*.md`（主要 walkthrough）| `skills/project-standard-extractor/references/examples/phase-2/` | Phase 2 高阶功能使用指南，有用户 onboarding 价值 |

### 内部路径引用批量更新

目录重命名后，所有文件内的路径引用字符串需同步更新（约 15 个文件，纯字符串替换，不改逻辑）。关键映射：

| 旧路径前缀 | 新路径前缀 |
|---|---|
| `references/agents/` | `references/agents/` |
| `references/config/` | `references/config/` |
| `references/prompts/` | `references/prompts/` |
| `assets/` | `assets/` |
| `references/quality-gate.md` | `references/quality-gate.md` |
| `references/workflow.md` | `references/workflow.md` |

**不动项**：`references/config/dimension-framework/` 内部 YAML 相互引用（相对路径，不受影响）；`assets/skeletons/` 文件名（被 generation.md 枚举映射）；所有 agent 合约执行逻辑。

### SKILL.md 精简（P2）

- 目标行数：≤ 100 行（当前 143 行）
- 可外移的内容（~50 行）：§维度激活态对外说明的 5 条铁律（移入 `references/workflow.md`）；§强制边界各条的说明段落（压缩为每条 1 行表格）；关键引用表（从平铺 14 行改为 4 类分组 8 行）
- 不动的内容：frontmatter、调用协议 YAML、7-stage ASCII 执行图、5 状态摘要表（无铁律）、强制边界表（精简后）、关键引用分组表
- 同步优化 description 字段：补充英文触发关键词（当前仅中文，影响英文 AI 宿主的 skill 触发准确率）

---

## 目标目录结构（After）

```
skills/project-standard-extractor/
├── SKILL.md                              # 精简入口（≤ 100 行）
├── references/
│   ├── workflow.md
│   ├── quality-gate.md
│   ├── agents/                           # 11 个 phase contracts
│   ├── config/                           # 维度框架 + 配置文件
│   │   └── dimension-framework/          # 内部结构不变
│   ├── prompts/                          # signal-library + orchestrator
│   └── examples/
│       ├── golden-sample-run.md
│       ├── thin-dogfood-run.md
│       └── phase-2/                      # Phase 2 使用指南（保留）
├── assets/                               # 原 assets/（输出用模板 + 骨架）
│   ├── standard-template.md
│   └── skeletons/                        # 内部结构不变
└── scripts/
    ├── backup.sh
    └── force-rebuild-validate.sh

docs/evals/project-standard-extractor/   # 原 evals/（项目级，不进分发包）
├── README.md
├── trigger-cases.md
├── boundary-cases.md
├── failure-cases.md
├── expected-behavior.md
└── dimension-framework/                  # AE7–AE25 共 25+ cases
    └── ...（12 个 case 文件）
```

---

## 验收标准

### Phase A 完成（P0 修复）

```bash
# skill 顶级不再有辅助文档
find skills/project-standard-extractor -maxdepth 1 -name "*.md" | sort
# → 只有 SKILL.md

# evals 迁移完整
ls docs/evals/project-standard-extractor/dimension-framework/ | wc -l
# → 12（原有 case 文件全部到位）
```

### Phase B 完成（目录重命名 + 路径更新）

```bash
# 顶级目录只有标准子目录
find skills/project-standard-extractor -maxdepth 1 -type d | sort
# → references/  assets/  scripts/

# 无遗留旧路径引用
grep -rn "^references/agents/\|^references/config/\|^references/prompts/\|^assets/" \
  --include="*.md" --include="*.yaml" \
  skills/project-standard-extractor/
# → 无输出
```

### Phase C 完成（SKILL.md 精简）

```bash
wc -l skills/project-standard-extractor/SKILL.md
# → ≤ 100
```

### 整体交付

1. `python skill-creator/scripts/package_skill.py skills/project-standard-extractor` 打包成功（frontmatter 合规）
2. 打包产物中不含 `evals/`（因已物理移出）
3. `docs/evals/project-standard-extractor/` AE 编号体系完整，可被维护者引用
4. 在 Claude Code 会话中 `@SKILL.md` 后，AI 能识别调用协议并正确导航到 `references/` 下各合约
5. `references/examples/golden-sample-run.md` 展示的端到端执行链路与新路径一致

---

## 关键决策记录

| 决策 | 选择 | 理由 |
|---|---|---|
| evals/ 处置 | 物理移出 skill 目录到 `docs/evals/` | `package_skill.py` 不支持排除，移出是唯一不需要改工具的干净方案 |
| .skillignore 机制 | 不引入 | evals/ 移出后不再需要；修改打包工具超出本次范围 |
| references/examples/phase-2/ | 保留到 `references/examples/phase-2/` | 4 个 walkthrough 有真实用户 onboarding 价值，不是开发废弃物 |
| references/config/dimension-framework/ 内部 | 不动 | YAML 间用相对路径引用，重组会触发级联修改 |
| package_skill.py | 不修改 | 超出本次范围；当前工具完成打包验证已足够 |

---

## 执行分阶段

| 阶段 | 内容 | 工时估计 | 风险 |
|---|---|---|---|
| Phase A | 删除 9 个文件，移动 evals/ 到 docs/ | ≈ 30 分钟 | 零逻辑风险 |
| Phase B | 目录重命名 + 内部路径引用批量更新 | ≈ 2 小时 | 中（路径替换遗漏）|
| Phase C | SKILL.md 精简 + description 优化 | ≈ 1 小时 | 低 |

建议顺序：A → B → C，每阶段独立验收后再进入下一阶段。

---

## 规划交接上下文

- 实施完成后不再保留 `skills/project-standard-extractor/OPTIMIZATION-PLAN.md`；目录结构、验收口径以本文档和完成后的 skill 包结构为准
- Phase B 路径替换前，先运行 `grep -rn "references/agents/\|^references/config/\|^references/prompts/\|^assets/" --include="*.md" skills/project-standard-extractor/` 建立基线
- `references/config/dimension-framework/` 内的 YAML 文件之间用相对路径，移动后无需更新
- evals/ 已迁移到 `docs/evals/project-standard-extractor/`，该目录作为项目级回归锚点，不进入 skill 分发包
