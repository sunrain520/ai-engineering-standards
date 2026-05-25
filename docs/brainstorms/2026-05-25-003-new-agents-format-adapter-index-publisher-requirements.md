---
doc_id: BST-2026-05-25-003
title: 新增两个消费侧 Agent：format-adapter 与 index-publisher
status: draft
date: 2026-05-25
author: 矿工
tags: [skill, agent, format-adapter, index-publisher, project-standard-extractor]
---

# 新增两个消费侧 Agent：format-adapter 与 index-publisher

## 背景

`project-standard-extractor` 的主管道（7 stage）负责从源码萃取并写入 `engineering-standards/` 目录。管道末端有两个明确的手工衔接点，缺乏 agent 支撑：

1. **消费侧格式断裂**：管道生成 `ai-rules.md`（自定义格式），但 AI coding agent 的实际消费格式是 `CLAUDE.md`、`AGENTS.md`、`.cursor/rules/*.mdc` 等宿主特定格式。用户需手工适配，质量因人而异。

2. **候选索引永远停在候选态**：管道生成 `temp/{run_id}-rules-index-candidate.json`、`llms-candidate.txt` 并明确禁止自动发布。从候选到正式没有结构化流程，用户需手工完成差异对比、合并、CHANGELOG 追加。

这两个缺口共同导致"规范已萃取但无法高效交付给目标项目"的现象。

---

## 定义：消费侧 Agent

主管道（intake → merge）是**生产侧**：从代码生产规范文档。本文档提出的两个 agent 是**消费侧**：将生产侧产物转换成可直接使用的格式并发布到正确位置。消费侧 agent 在主管道完成后由用户显式触发，不自动嵌入主管道循环。

---

## Agent 1：format-adapter

### 问题

`ai-rules.md` 是语义正确的规则汇总，但其格式（`## P0 规则名`、inline blockquote 元数据行）对 AI 宿主不可识别。目标项目工程师需要手工把 `ai-rules.md` 改写成：
- Claude Code：`CLAUDE.md` 或 `.claude/AGENTS.md`
- Codex / OpenAI agents：`AGENTS.md`
- Cursor：`.cursor/rules/domain-rules.mdc`（含 YAML frontmatter + glob 模式）
- GitHub Copilot：`.github/copilot-instructions.md`

手工改写耗时且不稳定——同一条规则在不同宿主格式里的表述可能不一致。

### 目标

format-adapter 读取已通过质量门禁的 `ai-rules.md` 和 `activation-report.json`，按指定宿主格式输出可直接部署的文件，使"规范萃取结果 → 目标项目安装"的路径全自动化。

### 输入契约

```yaml
inputs:
  ai_rules_path:          # engineering-standards/{domain}/ai-rules.md（已合并的产物）
  activation_report:      # temp/{run_id}-activation-report.json（提供激活态过滤依据）
  target_hosts:           # 列表，至少 1 个：claude | codex | cursor | copilot
                          # 默认：[claude]
  output_mode:            # local（写入 engineering-standards/{domain}/formatted/）
                          #   或 deploy（写入 target_project_path 指定的目标项目）
  target_project_path:    # output_mode=deploy 时必填，目标项目的根目录绝对路径
  overwrite_policy:       # merge（默认）| overwrite | dry-run
                          # merge：只追加新规则节，不覆盖目标文件中已有内容
                          # overwrite：完整替换目标文件
                          # dry-run：只输出 diff，不写文件
  include_dimensions:     # 可选，只转换指定 dimension_id；默认全部 activated
  exclude_shallow:        # 可选，默认 false；true 时排除 shallow 维度规则
```

### 激活态过滤规则

| state | 是否写入宿主格式 | 附加处理 |
|---|---|---|
| activated | ✅ 写入 | 无 |
| shallow | ✅ 写入 | 每条规则前加 `⚠️ low-coverage: 验证后使用` 标注 |
| baseline | ✅ 写入 | 标注 `advisory: true`，不进 must-do 区块 |
| pending-confirmation | ❌ 不写入 | — |
| candidate | ❌ 不写入 | — |

### 各宿主输出格式规范

**claude**（`CLAUDE.md` 或 `.claude/AGENTS.md`）

```markdown
# [domain] Engineering Standards

## Coding Guidelines
<!-- 来自 ai-rules.md P0/P1/FORBIDDEN 规则 -->

## Commands
<!-- 来自 ai-rules.md review-checklist 相关规则 -->

## Architecture Constraints
<!-- 来自 ai-rules.md 分层/依赖方向类规则 -->
```

**codex**（`AGENTS.md`）
- 与 claude 格式相同，但文件命名为 `AGENTS.md`，放项目根目录

**cursor**（`.cursor/rules/{domain}-rules.mdc`）
```yaml
---
description: {domain} engineering standards
globs: ["**/*.{kt,java,swift,ts,tsx,py,go}"]  # 按 domain 自动推断
alwaysApply: false
---
<!-- 规则正文，cursor 格式：bullet list，每条 ≤ 80 字 -->
```

**copilot**（`.github/copilot-instructions.md`）
```markdown
<!-- 无 frontmatter，纯 markdown -->
# {domain} Coding Standards
<!-- 每条规则一个 bullet，保持简洁 -->
```

### 输出产物

| output_mode | 产物位置 |
|---|---|
| local | `engineering-standards/{domain}/formatted/claude.md`（和/或其他宿主文件） |
| deploy | 直接写入 `target_project_path` 中对应的宿主文件位置 |

dry-run 时只输出 diff 摘要（新增/变更/不变 规则数），不写文件。

### 调用触发时机

- 主管道运行完成并通过人工审阅后，用户显式触发
- `output_action=force-rebuild` 执行成功后，可选择附带触发
- 不自动嵌入主管道循环

### 强制边界

1. 不修改 `ai-rules.md` 或任何 `standard-*.md` 源文件
2. `overwrite_policy=merge` 时，对目标文件中已存在的规则节只追加新规则，不删除现有内容
3. `overwrite_policy=overwrite` 必须先展示变更预览并等待用户确认（类比 force-rebuild 的 safeguard 模式）
4. pending / candidate 维度规则**绝不**写入任何宿主格式文件

### 验收标准

- `CLAUDE.md` 中出现的规则 100% 来自 `ai-rules.md` 的 activated 或 shallow 维度
- `grep "pending\|candidate" <output>` 无输出
- dry-run 输出与 overwrite 执行的规则数量一致
- 生成的 `.mdc` 文件 YAML frontmatter 可被 `yaml.safe_load` 解析
- `output_mode=deploy` 后在目标项目执行 `cat CLAUDE.md | wc -l` 与预期行数一致（±2 行）

---

## Agent 2：index-publisher

### 问题

主管道的候选索引（`rules-index-candidate.json`、`llms-candidate.txt`）需要手工晋升到正式索引（`.index/rules-index.json`、`llms.txt`）。当前没有机制：
- 对比候选和现有正式索引的差异
- 检测冲突规则（same `section_title` 但内容矛盾）
- 执行原子合并并回滚失败路径
- 追加 CHANGELOG

导致用户要么跳过发布（规范停在候选），要么直接覆盖（可能丢失历史规则）。

### 目标

index-publisher 提供结构化的候选 → 正式晋升流程：diff 可视化 → 冲突检测 → 用户确认 → 原子写入 → CHANGELOG 追加。

### 输入契约

```yaml
inputs:
  candidate_rules_index:  # temp/{run_id}-rules-index-candidate.json
  candidate_llms:         # temp/{run_id}-llms-candidate.txt（可选）
  domain:                 # 必填，如 01-app-client，用于 CHANGELOG 标注
  run_id:                 # 候选文件的 run_id，用于溯源
  publish_mode:           # full（默认）| selective | dry-run
                          # full：发布全部通过冲突检测的规则
                          # selective：展示每条候选规则，用户逐条确认
                          # dry-run：只输出 diff 报告，不写文件
  conflict_resolution:    # skip（默认，冲突规则保留候选状态，不写正式）
                          #   或 overwrite（用候选覆盖正式，记录冲突日志）
```

### 执行流程（4 步）

**Step 1 — Diff 计算**

对比 `rules-index-candidate.json` 与 `.index/rules-index.json`（若不存在，视为空基线）：

| 类别 | 定义 | 默认处置 |
|---|---|---|
| new | candidate 中有，正式中无 | 写入 |
| unchanged | `section_title` + `content_hash` 均匹配 | 跳过（已是最新） |
| updated | `section_title` 匹配但内容不同，且无语义冲突 | 写入（覆盖） |
| conflict | `section_title` 匹配，内容不同，且语义方向相反（一条 must，对方 must-not）| 停止，记录 `conflicts_detected`，不写正式 |

**Step 2 — 预览展示**

输出摘要：
```
规则晋升预览（run_id: {run_id}，domain: {domain}）
  新增：N 条
  更新：N 条
  跳过（已最新）：N 条
  冲突（需手工裁定）：N 条

冲突详情：
  [conflict-001] section_title: "P0 ViewModel 状态管理"
    正式版本：必须使用 StateFlow，不得使用 LiveData
    候选版本：StateFlow 和 LiveData 均可，按场景选择
    → 建议：保留正式版，候选加入 pending-confirmation.md
```

**Step 3 — 用户确认**

- `publish_mode=full`：展示摘要后等待 `confirm {domain}` 字面输入（与 force-rebuild safeguard 保持一致）
- `publish_mode=selective`：每条 new/updated 规则单独确认（y/n/pending）
- `publish_mode=dry-run`：直接输出报告，不等待确认

**Step 4 — 原子写入 + CHANGELOG**

写入顺序：
1. 备份当前正式索引到 `temp/{run_id}-rules-index-pre-publish.json`
2. 写入新 `.index/rules-index.json`（原子替换）
3. 如有 `candidate_llms`，同步写入 `llms.txt`
4. 写入成功 → 追加 `CHANGELOG.md`（格式与 force-rebuild changelog-append 一致）
5. 任意步骤失败 → 从备份恢复，CHANGELOG 不追加

冲突规则的处置（`conflict_resolution=skip` 时）：
- 不进入正式索引
- 自动追加到 `engineering-standards/{domain}/pending-confirmation.md` 的冲突裁定节：
  ```
  ## 待裁定冲突（来自 run_id: {run_id}）
  ### [section_title]
  - 正式版本：...
  - 候选版本：...
  - confirm_owner: 领域负责人
  - fallback_action: 保留正式版，下次萃取重评
  ```

### 输出产物

| 产物 | 写入位置 | 条件 |
|---|---|---|
| 更新后的正式索引 | `.index/rules-index.json` | 非 dry-run |
| 更新后的 llms.txt | `llms.txt`（根目录） | 非 dry-run + candidate_llms 有效 |
| 发布前备份 | `temp/{run_id}-rules-index-pre-publish.json` | 非 dry-run |
| 冲突裁定追加 | `engineering-standards/{domain}/pending-confirmation.md` | 检测到冲突时 |
| dry-run 报告 | 控制台输出 | dry-run 时 |
| CHANGELOG 追加 | `CHANGELOG.md` | 写入成功时 |

### 强制边界

1. `publish_mode ≠ dry-run` 时必须等待用户字面确认 `confirm {domain}`，headless / pipeline 模式一律拒绝（`NON_INTERACTIVE_CONTEXT_REJECTED`）
2. 原子写入失败必须从备份恢复；恢复失败时保留备份文件并报 `PUBLISH_RECOVERY_FAILED`，**不**追加 CHANGELOG
3. 候选文件中 `status ≠ "candidate"` 的条目不参与晋升
4. 冲突规则在任何模式下都不得静默写入正式索引

### 验收标准

- dry-run 后 `.index/rules-index.json` 内容不变
- full publish 后 `cat .index/rules-index.json | python3 -c "import json,sys;d=json.load(sys.stdin);print(len(d['sections']))"` 输出 ≥ candidate 中 new+updated 数量
- 检测到冲突时 `grep "待裁定冲突" engineering-standards/{domain}/pending-confirmation.md` 有输出
- CHANGELOG 末尾含 `run_id: {run_id}` 标记
- 执行成功后再次触发 dry-run，new=0 / updated=0（幂等性）

---

## 集成关系

```
主管道（intake → merge）
    ↓ 产出
engineering-standards/{domain}/ai-rules.md
temp/{run_id}-rules-index-candidate.json
temp/{run_id}-llms-candidate.txt
    ↓ 用户审阅 + 显式触发
┌─────────────────┐    ┌──────────────────┐
│  format-adapter │    │  index-publisher  │
│  读 ai-rules.md │    │  读 candidate     │
│  → CLAUDE.md    │    │  → .index/*.json  │
│  → AGENTS.md    │    │  → llms.txt       │
│  → .cursor/*.mdc│    │  → CHANGELOG      │
└─────────────────┘    └──────────────────┘
        ↓                       ↓
  目标项目可直接安装      正式索引可被下游工具消费
```

两个 agent 相互独立，可分别触发，没有依赖关系。均在主管道完成 + 人工审阅后按需调用。

---

## 非目标

- 不自动触发 format-adapter 或 index-publisher（必须用户显式调用）
- format-adapter 不修改 ai-rules.md 源文件
- index-publisher 不处理 `standard-*.md` 的版本晋升（`draft → active` 仍需人工）
- 不支持从正式索引回退到候选（回退走 backup-manager 的 restore 路径）
- format-adapter 的 cursor 格式不自动推断 glob 模式（glob 由用户在 `target_hosts` 参数中通过 overrides 指定，或使用 domain 默认值）

---

## 实施优先级与分阶段建议

| Agent | 推荐实施顺序 | 理由 |
|---|---|---|
| `index-publisher` | 先 | 流程更确定，输入产物已存在（merge-coordinator 已生成 candidate），与现有 force-rebuild safeguard 模式对齐 |
| `format-adapter` | 后 | 需要先稳定各宿主格式规范（CLAUDE.md / AGENTS.md 还在演进），format 细节可随宿主更新迭代 |

两个 agent 均作为**独立 agent 合约文件**添加到 `agents/`（重构后为 `references/agents/`），不修改现有 7 个主管道 agent。

---

## 关键决策记录

| 决策 | 选择 | 理由 |
|---|---|---|
| 消费侧 agent 是否嵌入主管道 | 否，独立触发 | 主管道产物需人工审阅后才能消费；强制嵌入会绕过领域负责人确认环节 |
| format-adapter 输出到 local 还是 deploy | 两种模式均支持 | local 适合先预览再手动部署；deploy 适合 CI 集成场景 |
| index-publisher 冲突默认处置 | skip（不写正式，入 pending-confirmation）| overwrite 有丢失历史规则的风险；skip 强制人工裁定，与规范质量优先原则一致 |
| format-adapter 对 shallow 规则的处理 | 写入但加 ⚠️ 标注 | 不写入会让用户无法知晓 shallow 规则的存在；加标注保留信息同时标明风险 |
| publish 确认方式 | 字面 `confirm {domain}`（与 force-rebuild 一致）| 统一交互模型，防止 AI 自动通过确认步骤 |
