---
doc_id: BST-2026-05-25-004
title: project-standard-extractor 公开入口治理与安全收敛优化方案
status: draft
date: 2026-05-25
revision: r8
revision_log:
  - "r1 (2026-05-25): 初版「目录合规 + 文案剥离」"
  - "r2 (2026-05-25): 引入结构化 regex / intake gate / backup.sh 完整迁移"
  - "r3 (2026-05-25): intake gate 改为调用上下文 flag，膨胀至 456 行"
  - "r4 (2026-05-25): 结构性减法，先决定 description / 命名 / 是否拆分；推 C 方案（maintainer 拆出 skill）"
  - "r5 (2026-05-25): **结合代码全面重审**。A 方案成本被严重高估，改判「A + C 复合方案」；用户后续修订引入 phase1-selected-batch 输入剖面"
  - "r6 (2026-05-25): 自审 7 项修订：① §0/§3 成本上调至 3.5 人日（A 方案含新剖面真实成本 ≥ 2 人日）；② §4.5 攻击面闭环改为「LLM 公开触发面不可达 + maintainer 触发按设计可达」；③ description 立场三处统一为「必须精确化补充稳定路径与负向触发边界」；④ §4.1 锚点 3 措辞精确化；⑤ §4.3 README 改为仓库级 maintainer 索引；⑥ F1 严重度标注为「P1（A 方案落地后关闭）」；⑦ §6 G1 拆 G1.a / G1.b 覆盖两条路径"
  - "r7 (2026-05-26): 根据文档审查修复 6 项问题：① 改为「决策记录 + 当前实现验证/补缺」，避免重复 plan；② 公开稳定路径统一为 profile-first / selected-batch，baseline-only 降为 Phase 2 repair fallback；③ 攻击面表述降级为公开入口不主动暴露 + maintainer context gate；④ `x-external-evals-root` 纳入验收；⑤ maintainer README 与当前项目级入口对齐；⑥ G2 缩窄到 Inputs / Stable Workflow 字段验收"
  - "r8 (2026-05-26): 移除 SKILL.md ≤90 行硬门槛，将 G4 改为结构完整、信息质量和公开面隔离优先，避免用过程性行数指标牺牲最终 skill 质量"
author: 矿工
tags: [skill, optimization, public-surface, project-standard-extractor, design-philosophy]
related:
  - BST-2026-05-25-002  # 目录结构优化（已落地，前置基础）
  - PLAN-2026-05-25-002 # refactor: skill-structure-optimization-plan
  - PLAN-2026-05-25-001 # fix: phase-2-dimension-framework-repair-plan
---

# project-standard-extractor 公开入口治理与安全收敛优化方案

> 这份 brainstorm 只回答一个问题：**SKILL.md 怎样才是「最佳」？**
> r5 的关键判断：**最佳 = 让 description 承诺的能力真正可达 + 公开面只暴露稳定能力 + 维护工具拆出 skill**。
> 三件事必须同时做；只做其中一两件就是次优。
> r7 状态校准：核心 A+C 已在当前源码中基本落地；本文后续用途从「生成全量实施 plan」改为「记录决策、校验现状、补齐验收缺口」。

---

## 0. r7 状态校准：A+C 已落地，后续转为验证与补缺

r1–r4 把 Q1 的「A 修 generation 让 baseline-only 工作」当作「需要打开 Phase 2 修复战线」的高成本方案，
所以推 B（同 skill 内剥离）或 C（描述降级 + maintainer 拆出）。

**读完代码后这个前提不成立**：

| 证据 | 文件位置 | 说明 |
|---|---|---|
| workflow 已经声明稳定公开路径不读取 activation-report | `references/workflow.md` | profile-first → selected-batch → generation(`phase1-selected-batch`) 已是公开路径 |
| generation 已支持 `phase1-selected-batch` 与 `phase2-dimension-aware` 两个输入剖面 | `references/agents/generation.md` | selected-batch 不要求 activation-report；Phase 2 才消费 activation-report |
| dimension-activator 已强制 baseline 维度写入 `dimensions[]` | `references/agents/dimension-activator.md` | baseline 维度来自 baseline-dimensions.yaml 全集，`state=baseline` |
| baseline-dimensions.yaml 预置了开箱即用的 default_content | `references/config/dimension-framework/baseline-dimensions.yaml` | 每个 D01–Dxx 维度含 `standard_section` / `pending_message` / `checklist_items` |
| maintainer 脚本已物理迁出 skill 包 | `tools/maintainer/project-standard-extractor/` | backup / force-rebuild validate 已在仓库根 maintainer 目录 |

**r7 复盘后的两层结论**：
1. `baseline-only` 是 Phase 2 dimension-aware / repair fallback 的验证场景，不应再写成 SKILL.md description 的公开稳定路径。
2. SKILL.md description 的两条公开稳定路径应统一为：`profile-first → batch-plan` 与 `selected-batch → draft standard / ai-rules / review-checklist`。

**当前后续路径**：
- 不再生成重复的全量实施 plan。
- 只做现状校验与补缺：SKILL frontmatter、G2/G6/G7 验收、maintainer context gate、包产物清单。
- 若校验发现当前源码与 r7 验收不一致，按小补丁修复，而不是重开 A/C 方案。

**估算成本（r6 校准）**：
- 仅 baseline 强制写入 + A0.1 修订（原 r5 假设的最小动作）：≤ 0.5 人日
- 加上 `phase1-selected-batch` 输入剖面（用户 r5 修订引入）：**真实成本 ≥ 2 人日**——需要重写 generation Sub-step A0、定义新剖面 input schema、决定 skeleton 选型、章节激活态标注、baseline 与 evidence 合并策略
- r6 接受 ≥ 2 人日的真实成本，因为 selected-batch 是 SKILL.md description 承诺中**用户最常触发**的路径；不修就让 description 持续撒谎

这组成本保留为历史决策依据；r7 不再把它解释为后续待实施工作量。

---

## 1. 三个根本问题（r5 重答）

### Q1. skill 的稳定承诺是什么？

r4 在「修源头」与「描述降级」之间选了后者。
r5 修正：**A 方案成本 ≤ 0.5 人日，描述降级是过早妥协**。

> r7 口径：skill 名字保持不变；description 保留直出 draft 规范承诺，**必须精确化补充**两条公开稳定路径（profile-first / selected-batch）与负向触发边界，让 LLM 触发更精准。baseline-only 只作为 Phase 2 repair fallback 验收，不写入公开稳定路径。

带来的后果：
- description 承诺的「standard-{sub_domain}.md / ai-rules.md / review-checklist.md」**真正可达**
- 触发精度根因消除（不再是「触发后告知 NOT_READY」）
- F1（description 与现实不一致）一次性解决

### Q2. 维护者能力是不是 skill 的一部分？

r4 推 C（maintainer 拆出 skill），r5 保留这一判断。

**理由更精简**：
- skill 的核心是「LLM 触发 → 一次性产出文档草稿」
- maintainer 工具（force-rebuild / restore / pin / unpin / list）的本质是**仓库自治理**——管理 backup、回滚、pin 历史版本
- 这些操作不依赖 LLM 推理，shell + Makefile 是更对的形态
- 拆出后 destructive 脚本不再进入可分发 skill 包；但公开入口仍必须避免广告 destructive 字段，`output_action != append` 仍需要 maintainer / repair-only 上下文门禁

> r5 仍选 **maintainer 拆出 skill**。但相比 r4 多补一条：**显式声明攻击面边界**（见 §4.3）。

### Q3. brainstorm 的边界？

r4 收回到 249 行是对的。r5 在 250 行内完成 A+C 复合方案的论证；命令、清单、伪代码全部留给 plan。

---

## 2. 现状基线（r7 校准）

### 已经做对的（来自 002）
- 顶层目录合规、SKILL.md 97 行、可打包、evals 已外迁
- 工具基线（quick_validate / package_skill）通过
- 当前源码已把 SKILL.md 收敛到公开 8 小节，把 maintainer 脚本迁到 `tools/maintainer/project-standard-extractor/`，并在 generation / dimension-activator 中落地输入剖面和 baseline 规则

### 残留关注点

| ID | 严重度 | 现象 | r7 处理 |
|---|---|---|---|
| F1 | P1（已落地，需回归验证）| description 承诺「直出 standard」曾与 generation 硬依赖 activation-report 不一致 | 以 G1.b 验证 selected-batch；baseline-only 仅保留为 G1.a repair fallback 验收 |
| F2 | P1（需门禁验证）| Phase 2 / `force-rebuild` 系列仍可在 maintainer references 和内部 contract 中出现 | 公开 Inputs / Stable Workflow 不暴露；`output_action != append` 增加 maintainer context gate |
| F3 | P1（已迁出，需包清单验证）| 包内曾含具备破坏性 `restore` 行为的 `backup.sh` | 脚本物理离开 skill 包；验证 package 产物不含 maintainer 脚本 |
| F4 | P2（已落地，需质量验证）| 入口缺独立可扫描的 8 小节 | 8 小节骨架 + 公开说明完整清晰，不用行数作为硬门槛 |
| F5 | P2 | dimension-activator 状态表占 12 行入口 | 下沉到 references/workflow.md |
| F6 | P2 | evals 外迁后无源级指针 | frontmatter `x-external-evals-root` + G6 验收 |
| F7 | P3 | `extraction_mode` 暴露 `full`，但 `full` blocked | 公开面只暴露 4 项 |

---

## 3. 方案对比（A+C 复合 vs 原 r4 C 单独）

| 维度 | r4 C 单独（描述降级 + maintainer 拆出） | **r5 A+C 复合（修源头 + maintainer 拆出）** |
|---|---|---|
| F1 是否真修 | **不修**，只用文案掩盖 | **真修**：generation 内部一致性 bug |
| description 是否需要改写 | 必须改（降级措辞） | 必须精确化补充两条稳定路径与负向触发边界（r6 立场，不降级承诺） |
| skill 命名 | 可能需要改（planner 取向） | 不变 |
| 用户触发后体验 | 拿到 plan 后被告知 NOT_READY | 拿到完整 draft 规范 |
| destructive 攻击面 | 拆 maintainer 后消失 | 同 |
| 实施成本 | 1.5 人日（迁移 + 文案改写） | 3.5 人日（A 方案含 phase1-selected-batch 剖面 ≥ 2 + maintainer 拆出 1 + 公开面治理 0.5） |
| 风险 | F1 永远存在；触发精度治标 | A 修复触动 dimension-activator + generation；需补单测 |
| 适用阶段 | 阻塞期临时方案 | **当前阶段最佳** |

**结论**：r5 改判 **A + C 复合方案**。
多花 2 人日（r6 校准成本）换 F1 真正解决 + selected-batch 公开路径稳定可用 + description 精确描述两条稳定路径，长期回报远大于成本。

**r7 补充**：该对比是历史决策依据，不再作为后续实施计划的待办清单。当前工作应转为验证已落地状态，并修复与验收原则不一致的窄缺口。

---

## 4. 推荐方案的设计骨架

### 4.1 A 方案验收锚点：selected-batch 公开路径 + baseline repair fallback

**验收锚点 1：`dimension-activator`**
- 强制规则：`baseline-dimensions.yaml` 中所有维度必须以 `state=baseline` 出现在输出 `dimensions[]` 中
- 这是 baseline 池的设计意图，r5 把它从「隐含约定」改为「显式契约」

**验收锚点 2：`generation.md` 输入剖面**
- 增加 `phase1-selected-batch` 剖面：不要求 activation-report，只消费单个 batch 的 `code_facts` / `classification` / `selected_batch_summary`
- `phase2-dimension-aware` 剖面才要求 activation-report，并按维度状态选择 skeleton / activation-state
- 这比只改 A0.1 更稳：selected-batch 的稳定公开路径不再被 Phase 2 blocked 管道牵连

**验收锚点 3：`generation.md:A0.1`**
- 第 3 条原文「`dimensions[]` 空集抛 `EMPTY_ACTIVATION_REPORT`」
- 保留空集硬失败作为「baseline 池强制写入契约被违反」的 fallback 防御，**正常路径不可达**
- 新增「`dimensions[]` 全为 candidate 时抛 `NO_DIMENSION_CAN_GENERATE`」覆盖 Phase 2 dimension-aware 在 candidate-only 情形下的失败模式
- 与 baseline 池强制写入契约（锚点 1）和 phase1-selected-batch 剖面（锚点 2）配套

**验收锚点 4：补回归**
- baseline-only 场景：Phase 2 repair fallback，仅 baseline 维度命中，无 activated/shallow
- 期望：generation 不崩溃，按 `baseline-dimensions.yaml.default_content` 渲染最小章节
- selected-batch 场景：无 activation-report，但有单个 batch 的 code_facts / classification
- 期望：生成 evidence-backed draft standard / ai-rules / review-checklist，不读取 dimension-activator

**不属于本次范围**：
- Phase 2 复杂功能（cross-project unified-activation-map / EA-Doc runtime / 证券 PoC）保持 blocked
- 不把 baseline-only 写成公开稳定路径；它只用于 Phase 2 repair fallback 验收

### 4.2 SKILL.md 收敛（公开面治理）

1. **description 必须精确化补充**（r6 立场，与 §0/§3 一致）：保留 draft standard / ai-rules / review-checklist 承诺；**必须**新增两条稳定路径（profile-first → batch-plan / selected-batch → draft 规范）与负向触发边界，避免 LLM 误触发或在 NOT_READY 路径上空转
2. **正文采用 8 小节骨架**：When To Use / When Not To Use / Inputs / Stable Workflow / Outputs / Safety Boundaries / Failure Modes / Maintainer References
3. **公开输入协议只保留**：`project_paths` / `output_dir` / `extraction_mode` / `selected_batch` / `run_mode`
4. **不暴露**：`output_action` / `domain` / `restore_from` / `keep`
5. **frontmatter 加** `x-external-evals-root: docs/evals/project-standard-extractor/`

### 4.3 maintainer 工具拆出 skill（C）

1. `tools/maintainer/project-standard-extractor/` 位于仓库根，不能在 skill 目录内。
2. 当前 maintainer 脚本位置：`tools/maintainer/project-standard-extractor/backup.sh` 与 `tools/maintainer/project-standard-extractor/force-rebuild-validate.sh`。
3. 包内对旧 `scripts/backup.sh` / `scripts/force-rebuild-validate.sh` 的硬编码引用必须为 0。
4. 当前入口 README 使用 `tools/maintainer/project-standard-extractor/README.md`，作为本 skill 的 maintainer 工具入口；仓库级 `tools/maintainer/README.md` 不作为本方案必需验收，等多个 skill 迁入后再补。
5. **路径约束（r5 显式声明）**：`tools/maintainer/` 必须在仓库根，不能放在 skill 目录内任何子层级；否则 `package_skill.py` 会通过 `rglob('*')` 把它打包，C 方案失效

### 4.4 references/workflow.md 二段化

新增 `## Maintainer / Repair-Only` 锚点，吸纳：
- Phase 2 blocked 状态长说明（**保留**：cross-project / EA-Doc / 证券 PoC 仍 blocked）
- `force-rebuild` / `restore` / `pin` / `unpin` / `list` 行为契约
- `backup.sh` 新位置（`tools/maintainer/project-standard-extractor/backup.sh`）与调用样例
- 外部 evals 索引指针

### 4.5 攻击面边界显式声明（r6 重写：诚实表述）

> r5 原版把闭环写成「destructive 行为不可达」，与代码现实不符——脚本只是搬家不是删除，
> 沿新路径 `tools/maintainer/project-standard-extractor/backup.sh` 仍可执行。
> r6 把闭环重表述为**两层触发面分离**：

**触发面 1：LLM 公开触发面（必须不主动暴露）**
- SKILL.md 的 `Inputs` / `Stable Workflow` 公开协议**不含** `output_action` / `domain` / `restore_from` / `keep` 字段
- 这只能降低普通触发概率，不能当成唯一授权边界；maintainer references 仍可能被读到
- 因此 `output_action != append` 必须要求显式 maintainer / repair-only 调用上下文；公开 profile-first / selected-batch 路径不得路由到 backup-manager
- **闭环判定**：SKILL.md `Inputs` 与 `Stable Workflow` 不出现 destructive 调用字段；intake 对 `output_action != append` 有 maintainer context gate（§6 G2/G7 验收）

**触发面 2：维护者手工触发面（按设计可达）**
- 维护者通过 `tools/maintainer/project-standard-extractor/backup.sh ...` 直接 invoke，或通过 Makefile target
- 这是预期行为：maintainer 工具就是给维护者用的；force-rebuild / restore 是仓库自治理操作
- 攻击面分析意义上仍是高权限路径，但它是显式授权的运维路径，不应由公开 skill 自动触发
- intake-and-scope.md Step 4.5 仍接受 `output_action != append` 作为 maintainer profile 调用（参见 §4.4 `references/workflow.md#maintainer--repair-only`），但必须带显式 maintainer / repair-only 上下文

**剩余攻击面（已审视并接受）**
- 用户/上游 caller 手填 `output_action: force-rebuild` 进入 intake：只有显式 maintainer / repair-only 上下文才接受；缺失上下文应拒绝为 `MAINTAINER_CONTEXT_REQUIRED`
- 包内对 `scripts/backup.sh` 旧路径硬编码引用如有遗漏，会抛 `BACKUP_SCRIPT_NOT_FOUND`：这是**引用改写不完整的 fallback 报错**，不是闭环主路径

**结论**：攻击面闭环不依赖 r3 的 intake gate / 调用上下文 flag；
依靠「公开 Inputs / Stable Workflow 不暴露 destructive 字段 + `output_action != append` maintainer context gate + 包内旧路径引用全改写 + 脚本物理迁出 skill 包」四件事配合。
**maintainer 触发按设计可达是 feature，不是 bug**。

### 4.6 不做的事

- 不重做 Phase 2 runtime（仅打开 baseline-only 最小路径）
- 不实现 `.skillignore`
- 不引入复杂 public-profile gate；只保留 `output_action != append` 的 maintainer context gate
- 不修改 `references/agents/*` 的执行契约 / 数据流（**例外允许**：A 方案对 dimension-activator + generation A0.1 的最小修订；改 destructive 引用字符串路径）
- 不实现 cross-project / EA-Doc / 证券 PoC（保持 blocked）
- 不改 skill 名（A 方案让原名承诺真正可达）

---

## 5. 风险与代价

| 风险 / 代价 | 缓解 |
|---|---|
| A 方案触动 dimension-activator + generation A0.1 + 新增 phase1-selected-batch 输入剖面（r6 修正）| 改动范围中等（≥ 2 人日）：需重写 generation Sub-step A0、定义新剖面 input schema、决定 skeleton 选型、章节激活态标注、baseline 与 evidence 合并策略；补 baseline-only 与 selected-batch 双场景单测；有 baseline-dimensions.yaml 现成 default_content 兜底 |
| baseline-only 产出质量较低（无代码 evidence） | 这是 baseline 池的设计目标本身——产出最小可用骨架；用户 expectations 已通过 `pending-confirmation.md` 与 `status: draft` 显式管理 |
| maintainer 拆出后路径错放回 skill 目录会失效 | §4.3 显式声明仓库根路径约束；plan 阶段验证 `package_skill.py` 产物清单不含 `backup.sh` |
| 包内 13+ 处硬编码引用穷举工作 | plan 阶段全量列出旧 `scripts/backup.sh` / `scripts/force-rebuild-validate.sh` 引用；CHANGELOG 记 user-visible |
| Phase 2 blocked 高级功能（cross-project / EA-Doc）仍不可用 | 显式保留 blocked 状态；用户预期通过 `BATCH_EXTRACTION_NOT_READY` 类 failure mode 管理 |

---

## 6. 验收原则

| # | 验收原则 |
|---|---|
| G1.a | Phase 2 repair fallback 的 **baseline-only 场景**可生成最小 draft（仅 baseline 维度命中、无 activated/shallow，generation 不崩溃，按 `baseline-dimensions.yaml.default_content` 渲染最小章节）|
| G1.b | description 承诺的输出在 **selected-batch 公开路径**下真正可生成（无 activation-report，但有单个 batch 的 code_facts / classification；phase1-selected-batch 输入剖面跑通，产出 evidence-backed draft）|
| G2 | SKILL.md 的 `Inputs` 与 `Stable Workflow` 中作为公开调用字段或公开步骤名出现的 destructive 字段为 0；`When Not To Use` / `Maintainer References` 可保留负向边界和 maintainer 指针 |
| G3 | `package_skill.py` 产物中不含 `backup.sh`；包内对旧 `scripts/backup.sh` 的硬编码引用为 0；intake 在缺脚本时返回明确错误 |
| G4 | SKILL.md 8 小节齐备；公开说明清晰完整，不为压缩行数牺牲触发边界、输入协议、安全边界或 maintainer 指针 |
| G5 | `references/workflow.md#maintainer--repair-only` 锚点存在，1 跳可达 `tools/maintainer/project-standard-extractor/README.md` 与外部 evals |
| G6 | SKILL.md frontmatter 含 `x-external-evals-root: docs/evals/project-standard-extractor/`，且该目录存在 |
| G7 | `output_action != append` 缺少 maintainer / repair-only 上下文时拒绝为 `MAINTAINER_CONTEXT_REQUIRED`；公开 profile-first / selected-batch 路径不得进入 backup-manager |
| 基线锁定 | plan 第一步跑 spec-skill-audit 写入 `.spec-first/audits/skill-audit/<ts>/baseline-pse-r6.json`；落地后不低于该基线、不出现新 P1 |

具体 regex / awk / 单测脚本留给 plan 阶段。

---

## 7. 后续路径

1. 不再进入 `/spec:plan` 生成重复实施计划；当前源码已包含 A+C 的主要落地点。
2. 直接进入验证 / 补缺：
   - **A 方案验证**：dimension-activator baseline 池强制写入契约 + generation `phase1-selected-batch` 输入剖面 + baseline-only repair fallback 与 selected-batch 双场景回归。
   - **C 方案验证**：`tools/maintainer/project-standard-extractor/` 路径、项目级 README、包产物清单不含 maintainer 脚本、旧 `scripts/*` 引用为 0。
   - **公开面治理验证**：SKILL.md 8 小节、输入协议精简、frontmatter `x-external-evals-root`、description 精确描述 profile-first / selected-batch 两条公开稳定路径。
   - **安全验证**：G2/G7，确认公开路径不会进入 backup-manager，maintainer 路径显式授权后才可达。
3. CHANGELOG.md 登记 user-visible 条目。
4. **不再有「独立 brainstorm」承接**——A 方案已并入本方案，r7 只保留验证与补缺。

---

## 附录：r1→r6 演化与 r6 关键修订

### 演化

| 版本 | 体量 | 关键决策 |
|---|---|---|
| r1 | 297 行 | 「目录合规 + 文案剥离」 |
| r2 | 432 行 | 引入结构化 regex / intake gate / backup.sh 完整迁移 |
| r3 | 456 行 | intake gate 改为调用上下文 flag |
| r4 | 249 行 | 减法重写；推 C 方案（描述降级 + maintainer 拆出） |
| r5 | 266 行 | 结合代码全面重审；改判 A+C 复合；用户后续修订引入 phase1-selected-batch 剖面 |
| r6 | 299 行 | 自审 7 项：成本上调至 3.5 人日 + 攻击面闭环诚实表述 + description 立场统一 + G1 拆 G1.a/G1.b |
| r7 | 299 行 | 审查修复 6 项：当前实现状态校准 + 公开路径口径统一 + maintainer context gate + G2/G6/G7 验收补齐 |
| **r8** | **本版** | **移除 SKILL.md 行数硬门槛**：G4 改为结构完整与信息质量优先 |

### r6 相对 r5 的关键修订

- ✅ **成本诚实校准**：A 方案含 phase1-selected-batch 剖面真实成本 ≥ 2 人日，总成本 3.5 人日（§0 / §3 / §5 同步）
- ✅ **攻击面闭环重表述**：从「destructive 不可达」改为「LLM 公开触发面不可达 + maintainer 触发按设计可达」；接受 maintainer 触发是 feature 而非 bug
- ✅ **description 立场统一**：§0 / §3 / §4.2 三处统一为「必须精确化补充两条稳定路径与负向触发边界」（严格版）
- ✅ **§4.1 锚点 3 措辞精确化**：承认 baseline 强制写入后空集分支正常路径不可达，作为 fallback 防御保留
- ✅ **§4.3 README 改为仓库级**：避免每个 skill 重复造索引
- ✅ **F1 严重度精确化**：标为「P1（A 方案落地后关闭）」
- ✅ **§6 G1 拆为 G1.a / G1.b**：覆盖 baseline-only 与 selected-batch 两条路径

### r7 相对 r6 的关键修订

- ✅ **现状漂移修复**：把后续路径从“生成 plan 再实施”改为“验证当前源码并补齐窄缺口”
- ✅ **稳定路径口径统一**：公开稳定路径只写 profile-first / selected-batch；baseline-only 降为 Phase 2 repair fallback
- ✅ **攻击面表述收敛**：不再声称“LLM 不会传字段”是硬安全边界，改为公开入口不主动暴露 + maintainer context gate
- ✅ **README 口径对齐当前源码**：使用 `tools/maintainer/project-standard-extractor/README.md` 作为当前入口，仓库级 README 延后到多 skill 场景
- ✅ **验收补齐**：新增 G6/G7，G2 缩窄到 `Inputs` / `Stable Workflow`

### r5 / r6 / r7 共同保留的 r1–r4 成果

- ✅ 8 小节骨架
- ✅ frontmatter `x-external-evals-root` 指针
- ✅ `references/workflow.md#maintainer--repair-only` 二段化
- ✅ maintainer 工具拆出 skill 的判断
- ✅ 基线锁定 + 验收原则不写命令

---

> 一句话总结（r7 校准）：
> **r7 = r6 决策的现状对齐版：A+C 主体已落地，公开稳定路径统一为 profile-first / selected-batch，baseline-only 只作 repair fallback，安全闭环新增 maintainer context gate 与 G2/G6/G7 验收。**
> 后续不再重复 plan，而是验证当前源码并补齐窄缺口。
