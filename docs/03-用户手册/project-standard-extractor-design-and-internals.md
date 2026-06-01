# project-standard-extractor 设计与内部解读

> 面向团队核心研发与架构师的深度分享内容稿。
> 视角：Skill 开发者→团队核心人员，覆盖**为什么这样设计、内部怎么跑、外部怎么用**。
> 与同目录的 `project-standard-extractor-sharing-script.md`（30 分钟使用者话术稿）和 `project-standard-extractor-execution-analysis.md`（执行流程上帝视角）互补：本稿更接近一次「内部技术分享 + 设计辩护」，强调 Skill 内部决策为什么是这样、未来会往哪里走，而不是单纯的使用步骤。

## 0. 怎么用这份稿子

| 场景 | 推荐读法 |
| --- | --- |
| 60-90 分钟内部技术分享 | 整篇照讲，章节本身就是演讲节奏 |
| 30 分钟核心组分享 | 只讲第 2、3、6、7、9 章；第 4、5 章作为附图带过 |
| 新维护者交接 | 重点读第 4、5、6、12 章 |
| 试点立项材料 | 摘 1、2、3、13 章给决策者 |

阅读约定：
- ASCII 图全部按当前 source-of-truth（`SKILL.md` / `references/workflow.md` / `references/agents/*.md` / `references/quality-gate.md`）画，不引入未实现能力。
- 引用文件按 `path:line` 形式，读者可直接定位。
- 出现 `Phase 2 / repair-only / maintainer-only` 字样的段落，全部代表当前**不在公开稳定路径**上的能力，只为讲清边界，不作为可发布功能宣传。

## 1. 一段话定位

```text
project-standard-extractor 是一条把真实代码反向萃取为团队级研发规范的生产线：
先 profile-first 画像，再选一个 ready batch 做 evidence-backed 萃取，
所有自动产出默认是 draft，只有人确认后的 active 才进入 AI 默认强约束。
```

这条定位句里有三个隐含立场，本稿后面会反复展开：
1. **反向萃取**——规范从代码生长出来，不是从空白文档凭空写出来。
2. **Evidence-first**——任何规则都必须能回到具体 evidence；没有 evidence 的不写规则。
3. **克制路径**——不一键全仓、不自动发布、不覆盖已有规则、不替团队做承诺。

## 2. 问题源头：为什么要造这个 Skill

### 2.1 真实痛点画像

我们重度使用 AI 辅助开发后，遇到的不是「AI 不会写」，而是这四个慢性病：

1. **AI 不知道我们这个团队此刻应该怎么写。** 通用最佳实践和我们的分层、状态机、命名、目录、错误处理习惯不一致。
2. **历史代码污染了 AI 的判断。** 仓库里既有当前推荐写法，也有迁移残留、临时方案、反例，AI 难以分辨。
3. **Reviewer 在每个 PR 里反复解释同一类规则。** 这些解释没有沉淀成下一次可复用的上下文。
4. **现有文档站不住脚。** 写的人的共识 ≠ 代码里的共识；过期文档反而误导 AI。

### 2.2 为什么不靠人手写规范

我们曾经的本能反应是「那就写一份团队规范文档」。这条路过去几年在多数团队都没真正成功，原因可以总结成三句话：

```text
规范的真相往往沉在代码里，不在文档里。
让人凭空把它写出来，会写成自己的偏好或互联网最佳实践。
写完之后没有 evidence 链路，没人愿意去维护。
```

### 2.3 为什么不靠模型直接做

让 LLM 去读完仓库再给规则，看似可行，但有两个硬伤：

- **历史包袱被标准化。** 模型分辨不清「存在过」和「应该这样」。
- **结论没有 evidence 边界。** 模型给出的规则没办法被 Reviewer 和 owner 复核。

所以问题被重新定义成：

```text
让 AI 做事实整理（哪些代码这样写、哪些 Reviewer 会挡），
让人做规范承诺（这条是不是团队应该坚持的写法）。
```

`project-standard-extractor` 就是对这条分工的工具化。

## 3. 三条设计哲学

下面是动笔写 SKILL 之前定下来、后来一直没动摇的三条主轴。

### 3.1 反向萃取（Reverse Standardization）

正向写规范是「我觉得团队应该这样写」；反向萃取是「这些模块当前就是这样写的，我们要不要把它升格为约束」。

- **正向**：从一份 PPT 或 wiki 出发，规范越写越像「应该」，离落地代码越远。
- **反向**：从 git 树和真实模块出发，规范天然带 evidence；冲突可以指着代码讨论。

反向萃取的代价是**接受规范的成色受代码成色决定**：选错代表性模块，规范就会失真。这正是为什么我们不能让 Skill 自动选模块，必须由人挑 batch。

### 3.2 Evidence-first

`project-standard-extractor` 的运行单元不是「规则」，而是「evidence + 由它派生出来的候选规则」。

```text
代码事实(code-facts)
   ├── 推荐写法证据(positive-examples)
   ├── 历史兼容证据(legacy-compatible)
   └── 反例证据(forbidden-examples)
                 │
                 ▼
        candidate rule
                 │
        Quality Gate 决议
                 │
        ┌────────┴────────────┐
        keep-draft       move-to-pending
                              │
                              ▼
                          owner 决策
                              │
                              ▼
                    手动升级为 active
```

设计推论：
- 不允许「无 evidence 的规则」进入产物。
- 一旦 evidence 链断裂（找不到来源、引用了脱敏内容、跨 batch 借证据），规则必须降级或挪进 `pending-confirmation.md`。
- 派生视图（`ai-rules.md` / `review-checklist.md`）**不新增独立规则**，全部从 `standard-{sub_domain}.md` 派生，避免「AI 看到的」和「Reviewer 看到的」漂移。

### 3.3 克制路径（Public Surface Discipline）

公开入口的字段比内部能力少很多，这是有意为之的：

```yaml
# SKILL.md 公开稳定字段（skills/project-standard-extractor/SKILL.md:28-36）
project_paths: [...]
output_dir: ""
extraction_mode: ""           # profile-first | batch-extraction | focused-module
selected_batch:
  batch_id: ""
run_mode: auto                # auto | interactive
```

公开入口**故意不暴露**：`output_action`、`domain`、`restore_from`、`keep`、`full`。这些字段在内部维护者契约里存在，但一旦放进公开入口，就会鼓励错误用法（覆盖规范、跳过 profile、强制全量）。这也是后面「Phase 2 / 维护者工具不在公开 surface」的根因。

## 4. 系统总览：三层分层

很多人第一次看 `references/` 下文件会被各种 agent 名字震到，其实这个 Skill 一直只有三层：

```text
┌─────────────────────────────────────────────────┐
│ Layer A · 公开稳定路径(Phase 1)                 │  ← 普通用户唯一可用
│   intake → profile-first → stop → batch-extraction│
│   generation_profile = phase1-selected-batch     │
│   draft-only / append-only                       │
├─────────────────────────────────────────────────┤
│ Layer B · Phase 2 repair-only                    │  ← blocked / 仅修复验证
│   doc-source-scanner / dimension-activator       │
│   activation-report.v1 / cross-project / EA-Doc │
│   securities PoC                                 │
├─────────────────────────────────────────────────┤
│ Layer C · Maintainer 工具(仓库根 tools/)         │  ← 维护者手动调用
│   force-rebuild / restore / pin / unpin / list   │
│   backup-manager 脚本                            │
└─────────────────────────────────────────────────┘
```

讲分享的时候必须强调：**Layer A 之外的内容，今天的稳定路径不会跑，也不会要求用户提供它的输入**。听众如果只能记住一句话，应该是这一句。

## 5. 公开入口与契约设计

### 5.1 输入 surface

`SKILL.md` 把输入字段缩到只剩 5 个，其中：
- `project_paths`：唯一必填字段，承担「告诉系统在哪萃取」。
- `extraction_mode`：可省略；广范围输入会被 Intake 强制改写成 `profile-first`。
- `selected_batch.batch_id`：第二轮才填，上一轮 batch-plan 选出来的单个 ready batch。
- `run_mode`：`auto` 默认；`interactive` 在关键决策点暂停等确认。
- `output_dir`：默认 `engineering-standards/{domain}/`，不需要用户管。

设计意图：**输入越少，误用越少**。当字段从 5 个膨胀到 15 个时，Skill 的"不会做什么"边界会迅速崩坏。

### 5.2 输出 surface

输出可以分成三类：

| 类别 | 路径示例 | 是否进 AI 默认上下文 |
| --- | --- | --- |
| 运行级 handoff | `temp/{run_id}-project-profile.md` 等 | 否（不发布、不索引）|
| 规范资产 | `engineering-standards/{domain}/standard-{sub_domain}.md` 等 | active 才进入 |
| 候选索引 | `temp/{run_id}-rules-index-candidate.json` / `llms-candidate.txt` / `ai-context-pack.md` | 不直接覆盖正式索引 |

候选索引和正式 `.index/rules-index.json` / 根 `llms.txt` 之间隔了一道**显式发布**：候选只能作为审查材料，发布要走人工动作。这是把「自动萃取」和「上线」严格分离的关键栏杆。

### 5.3 状态机

| 状态 | 含义 | AI 强约束 | 谁能改 |
| --- | --- | --- | --- |
| `active` | owner 确认的正式规则 | ✅ | 领域负责人 |
| `draft` | evidence 充分但未确认 | ❌（仅候选建议） | owner 升级 |
| `pending-confirmation` | evidence 不足或要拍板 | ❌ | owner 处置 |
| `conflict` | 与已有规则冲突 | ❌ | owner 仲裁 |
| `legacy-compatible` | 仅解释历史兼容 | ❌（不推荐新代码照抄）| 维护者归档 |

`candidate` 不是规则状态，它属于候选索引或 Phase 2 repair-only 中的激活态命名，不可与 `active` / `draft` 混用。这条容易讲错，分享时建议在状态表上方再口头强调一遍。

## 6. 执行逻辑深度展开

下面用一张端到端图先定锚，再逐阶段拆。

```text
project_paths
   │
   ▼
[1] intake-and-scope
       └─ scope_summary, run_id, sensitive-redaction-list
   │
   ▼
[2] profile-and-batch-planner
       ├─ temp/{run_id}-project-profile.md
       ├─ temp/{run_id}-extraction-map.md
       └─ temp/{run_id}-batch-plan.md
   │
   ▼
[3] stop-for-batch-selection
       └─ 用户必须选定 1 个 status: ready 的 batch
   │
   ▼
[4] facts-and-classification (selected batch only)
       ├─ signal_hits[]
       ├─ doc_facts[]            (脱敏)
       ├─ fact_candidates[]
       └─ classification_candidates
   │
   ▼
[5] generation (generation_profile = phase1-selected-batch)
       A0 input-profile-loader
       A  evidence-writer        → evidence/*.md
       B  developer-guide-author → standard-{sub_domain}.md / pending-confirmation.md
       C  derivative-generator   → ai-rules.md / review-checklist.md
       D  index-and-pack         → temp/{run_id}-*-candidate.{json,txt,md}
   │
   ▼
[6] review-and-quality-gate
       Gate A · Content Gate (R41–R46)
       Gate B · Activation Gate (R53, Phase 2 repair-only 才生效)
   │
   ▼
[7] merge-coordinator
       ├─ keep-draft        → standard / ai-rules / review-checklist append-only
       ├─ move-to-pending   → pending-confirmation.md
       ├─ mark-conflict     → conflicts.md
       └─ similar-existing  → merge-suggestions.md
```

### 6.1 Intake：把模糊输入变成可执行 scope

职责：路径校验、敏感隔离、研发域推断、广范围判定。

最关键的一条：**只要输入是仓库根、多 manifest、多服务、多端、未指定范围，就强制改写成 `profile-first`**。这条规则把「广范围 → 直接出规则」这条最危险的路径在入口就堵死。

设计取舍：研发域、子领域、模块由 Intake 从路径和说明推断；公开入口**不接受用户传 `domain`**。这是为了避免使用者用一个错误的 domain 把规则塞进无关目录。推断结果不确定时，写入 `inferred_decisions` 或 `pending-confirmation`。

### 6.2 Profile And Batch Planner：用最少代价压缩判断空间

这一步只做轻量目录扫描（`<= 3` 层、`<= 15` 个 manifest / README / `.gitignore`），不读业务代码全文。它的任务是回答：

```text
- 这个仓库里值得萃取的区域有哪些？
- 哪些区域和敏感配置混在一起，必须排除？
- 把可萃取区域切成 batch，每个 batch 的 evidence 边界是什么？
```

输出的 `batch-plan.md` 把决策权交还给人：每个 batch 标注 `status: ready / blocked / needs-confirmation`，候选文件列出来，排除路径列出来。**Skill 不会替人选 batch**——这是这一阶段最克制的设计。

### 6.3 Stop For Batch Selection：故意中断

这是整条流水线唯一的「故意停顿」。设计上它不是失败，是产线设计：

```text
profile-first 完成 → 一定停下来
   ↑
   不存在「直接出规则」的捷径
```

只有当用户明确传入 `selected_batch.batch_id`，且该 batch 在上一轮 plan 里是 `ready`，才进入下一阶段。否则触发 `BATCH_NOT_SELECTED` 失败。

把这一停顿讲给团队听时，建议把它包装成「以人为中心」的设计：**Skill 不替团队 commit 边界**。

### 6.4 Facts And Classification：只允许在 batch 内取证

这一步只能从 `selected_batch.candidate_files` 里抽事实。跨 batch 拿证据会触发 `BATCH_BOUNDARY_LEAK`，整条 run 失败。

输出有四块：
- `signal_hits[]`：grep / ast / file_existence / dependency / gitnexus / doc-content 的命中。
- `doc_facts[]`：经过脱敏的文档事实，唯一来源是 `doc-source-scanner`。
- `fact_candidates[]`：描述性事实，**不是规则**。
- `classification_candidates`：把材料分入 recommended / forbidden / legacy / pending / conflict 五桶。

注意：稳定路径不调用 `dimension-activator`，也不计算 `baseline / activated / pending-confirmation / shallow / candidate` 等维度状态。这些维度状态属于 Phase 2 repair-only 管道，普通运行根本碰不到。

### 6.5 Generation：四个子阶段严格排序

`generation_profile = phase1-selected-batch` 强制锁定子阶段顺序：

```text
A0 Input Profile Loader        ← 检查 selected_batch_summary / code_facts / classification 是否齐全
   │
A  Evidence Writer              ← 先写 evidence，再讲规则
   │
B  Developer Guide Author       ← 写 standard-{sub_domain}.md，必要时落 pending-confirmation
   │
C  Derivative Generator         ← ai-rules.md / review-checklist.md（不新增独立规则）
   │
D  Index & Pack Aggregator      ← rules-index-candidate / llms-candidate / ai-context-pack
```

设计意图：
- **先 evidence 后规则**：杜绝「先有结论再找证据」的逆向写作。
- **派生视图不新增规则**：保证 AI 看到的、Reviewer 看到的、规范文档讲的，是同一组事实。
- **候选索引产物始终是 candidate**：让发布动作永远显式。

### 6.6 Review And Quality Gate：双层门禁

`references/quality-gate.md:1-30` 把质量门禁画成双层：

```text
Gate A · Content Gate (R41–R46) — 评审"规则内容是否合格"
   ├─ Evidence 可追溯
   ├─ 团队级抽象
   ├─ AI 可执行
   ├─ Review 可二值判断
   ├─ 冲突识别
   ├─ 行业 / 安全 / 合规风险
   ├─ 正反例完整
   ├─ 数量与覆盖度
   └─ 人工确认要求
任一 BLOCK → 拒绝进入 draft

Gate B · Activation Gate (R53) — 仅 Phase 2 repair-only 生效
   ├─ baseline / activated / candidate / shallow 与内容决议是否一致
任一冲突 → 强制改判（pending → move-to-pending；shallow → keep-draft-low-coverage）
```

稳定路径上 Gate B **不会触发**，因为它依赖 `activation-report.v1`，而 Phase 2 当前 blocked。普通运行只跑 Gate A。

### 6.7 Merge Coordinator：append-only 是底线

合并阶段的硬约束：

| 决议 | 落点 | 写法 |
| --- | --- | --- |
| keep-draft | `standard-{sub_domain}.md` / `ai-rules.md` / `review-checklist.md` / `evidence/*` | append-only |
| keep-draft-low-coverage | 同上 | append-only，附 `low-coverage` 标记 |
| move-to-pending | `pending-confirmation.md` | append-only |
| mark-conflict | `conflicts.md` | append-only |
| similar-existing | `merge-suggestions.md` | append-only |
| candidate artifacts | `temp/{run_id}-*-candidate.{json,txt,md}` | 候选，不发布 |

**不覆盖任何已有 active / draft**。这是自我演进的安全栏杆：错误规则可以被新规则补充、被 conflict 暴露、被 owner 决策替换，但不会被静默改写。

## 7. 关键设计取舍辩护

这一章是给爱挑战的工程师准备的：每个克制设计都附「不这样会怎样」。

### 7.1 为什么 profile-first 不能跳过

正方论点：「我已经知道这个仓库长什么样了，给我直接出规则吧。」

反方论点：
- 仓库里同时存在推荐写法、历史兼容、临时方案和反例。
- 没有 batch plan，evidence 边界无人把关，Reviewer 无法复核。
- 一旦规则错误进入 active，会被后续 AI 反复放大。

工程妥协：`focused-module` 模式允许在已经明确小范围时跳过画像，但仍然必须保留 evidence 边界、敏感隔离和 Quality Gate。

### 7.2 为什么一次只跑一个 batch

把它放到信息论视角：每多并发一个 batch，evidence 与规则之间的对应关系就指数级模糊。考虑：
- 单 batch：每条规则可以指着 N 个具体文件，Reviewer 能在 5 分钟内判断「这是不是当前推荐写法」。
- 多 batch 并发：规则和文件的多对多关系彻底丧失。

这条限制对维护者偶尔显得「啰嗦」，但试点期间它把审查成本压在线性，让 owner 真的能看完。

### 7.3 为什么默认 draft，不自动 active

active 一旦进入 AI 默认上下文，会改变后续所有自动生成代码的取向。我们不接受「错了再改」，因为 AI 自我放大效应让回滚成本远高于事前审查。所以：

- 自动产线只能写 draft / pending / conflict。
- active 必须由领域负责人手动升级。
- 升级动作不通过这条 Skill，只能在规范资产仓库里显式提交。

### 7.4 为什么坚持 append-only

很多人第一直觉是「重新跑应该覆盖旧产物」。append-only 的好处：

- 规则演进有 git history，可以解释每条 active 何时确认、为什么改。
- 新事实不会静默替换旧事实，冲突显式落到 `conflicts.md`。
- 即使一次萃取整体不可用，旧规则不受污染。

代价：merge-suggestions 和 conflicts 文件会增长。我们认为这个代价比「静默改写」低得多。

### 7.5 为什么把 generation_profile 拆成两个

`phase1-selected-batch`（稳定）和 `phase2-dimension-aware`（repair-only）两条 generation 路径在源码里并列存在。这种二选一的并列设计，把「实验路径」和「生产路径」物理隔离：

- 普通运行 100% 走 phase1-selected-batch，永远不读 `activation-report`。
- Phase 2 修复验证可以单独激活 phase2-dimension-aware，不会污染稳定路径。

代价是代码里多了一些条件分支，但它换来了一条简单的口头承诺：「Phase 2 没有上线之前，普通规范萃取的行为完全不受影响」。

### 7.6 为什么 maintainer 工具放仓库根，不放进 skill 包

`tools/maintainer/project-standard-extractor/` 在仓库根，不在 `skills/project-standard-extractor/` 里。这是一个看起来微小但很关键的物理隔离：

- skill 包是会被复制到 `~/.claude/skills/` 或 `~/.codex/skills/` 的。
- 维护者脚本（force-rebuild / restore / backup）不应该跟着 skill 一起被分发到使用者环境。
- 把它放在仓库根，使用者复制 skill 包时根本拿不到这些脚本。

讲分享时这点可以一笔带过，但它对「防止误用」非常重要。

## 8. 三类使用方式

### 8.1 普通研发：把规范当 AI 上下文

推荐顺序（也写在 `AI辅助研发工程规范用户手册.md` 第 9 章里）：

```text
任务说明
  → engineering-standards/<domain>/overview.md
  → engineering-standards/<domain>/standard-<sub_domain>.md
  → engineering-standards/<domain>/ai-rules.md
  → engineering-standards/<domain>/review-checklist.md
  → 必要的 evidence/positive-examples.md / forbidden-examples.md
```

提示词要点：
- 明确区分 active / draft / pending；只把 active 当强约束。
- 让 AI 在与规范冲突时**先指出冲突，不要自行覆盖规范**。
- 不要把候选 `ai-context-pack.md` 一股脑塞进上下文，它是审查材料，不是默认上下文。

### 8.2 Reviewer：把规范当判断依据

引用格式约定：

```text
{source_doc}「{section_title}」
```

不使用 Rule ID 或 HTML anchor。理由：标题是源文档的一部分，标题改了规则也改了；anchor 不稳定。

Review 时建议先看：
1. 本次 diff 所属研发域的 `standard-{sub_domain}.md`。
2. `review-checklist.md`。
3. 与争议点相关的 evidence。
4. `conflicts.md` / `pending-confirmation.md` 是否有未解决项目。

讲分享时可以丢一句立场：

```text
我们希望 Review 里少一点"我觉得这样不好"，多一点"这条和规范的某条规则冲突"。
这样 AI 下一次能学到同一条约束，而不是每个 PR 重新解释。
```

### 8.3 模块 Owner：判断 draft 能否升级 active

owner 看 draft 的四个角度：

1. **代表性**：evidence 来自当前推荐模块，不是历史包袱。
2. **抽象度**：规则是团队级约束，不是单文件说明。
3. **可执行性**：AI 能按这条规则生成代码。
4. **可评审性**：Reviewer 能用这条规则做二值判断。

不应升级 active 的信号：
- 出现「尽量 / 适当 / 合理」这类不可检查的措辞。
- 只有一个孤立样例，缺乏代表性。
- 实际是在描述当前实现，而不是约束未来写法。
- 与已有 active 冲突却没有 owner 仲裁。
- 必须依赖业务上下文判断，不能成为通用工程约束。

### 8.4 维护者：边界守门

维护者要守的不是产物质量（那是 owner 的事），而是契约边界：

- 公开入口字段不允许扩张（特别是不要把 `output_action` 暴露出去）。
- 所有合并都是 append-only。
- 候选索引不进入正式 `.index/rules-index.json` / 根 `llms.txt`。
- Phase 2 / cross-project / EA-Doc / securities PoC / force-rebuild 系列**不进入用户文档**作为可用能力。
- CHANGELOG 同步更新，user-visible 变更追加 `(user-visible)`。

## 9. AI 提示词组合范式

这一章给团队一个可复制的模板，避免每个人自己拼上下文。

### 9.1 编码任务模板

```text
请基于以下团队规范完成开发，并在输出末尾说明对应自检结果：

1. engineering-standards/<domain>/overview.md
2. engineering-standards/<domain>/standard-<sub_domain>.md
3. engineering-standards/<domain>/ai-rules.md
4. engineering-standards/<domain>/review-checklist.md

约束：
- 只把 active 规则作为强约束。
- draft 规则仅作为候选建议；输出时用 [draft] 标注。
- pending-confirmation / conflict 不得作为执行依据。
- 如果需求与规范冲突，先在回复开头列出冲突，不要自行覆盖规范。
```

### 9.2 评审任务模板

```text
请按 engineering-standards/<domain>/review-checklist.md 和相关 standard 文档审查以下 diff：

<贴 diff 或描述变更>

约束：
- 引用规则使用 {source_doc}「{section_title}」二元组。
- 命中 draft / pending / conflict 时在结论中标注状态，不要当作已发布强约束。
- 如果发现新的 forbidden 写法但规范里没有，先列为「建议沉淀」，不要直接当作违规。
```

### 9.3 不推荐写法

```text
这是萃取产物，全部按里面说的执行。
```

原因：
- 不区分 active / draft / pending / conflict，AI 倾向于把所有材料当指令。
- 候选索引（`ai-context-pack.md`、`llms-candidate.txt`）会被错误地当成规范来源。
- 一次错误萃取会被反复放大。

## 10. 现场演示设计

30-90 分钟分享场景下，演示要被严格控时（建议 5-8 分钟）。

### 10.1 演示路径

| 时间 | 画面 | 讲什么 |
| --- | --- | --- |
| 0-1 | `SKILL.md` 头部 | 公开字段只有 5 个；强调"公开入口很窄是有意为之" |
| 1-2 | `temp/{run_id}-project-profile.md` 样例 | 第一步只画像，没有规则 |
| 2-3 | `temp/{run_id}-batch-plan.md` 样例 | 人选 batch，不是 AI 跑到底 |
| 3-4 | `evidence/code-facts.md` + `evidence/positive-examples.md` | 规则先有事实，事实指向具体文件 |
| 4-5 | `standard-{sub_domain}.md` draft | 规则带状态标记，引用 evidence |
| 5-6 | `pending-confirmation.md` / `conflicts.md` | 谨慎兜底；owner 才能拍板 |
| 6-7 | `ai-rules.md` + 提示词模板 | 派生视图，不新增规则 |
| 7-8 | `review-checklist.md` + Review 引用范式 | 为什么是 `{source_doc}「{section_title}」` |

### 10.2 演示忌讳

- 不现场对一个真实大仓做 batch-extraction（时间不可控、扫描有不确定性）。
- 不展示 maintainer / repair-only 字段当成普通输入。
- 不把 draft 直接塞进 AI 默认提示词不标状态。
- 不让讨论跑偏成「这个工具能不能替代 Review」。

### 10.3 演示收口

```text
这套流程的重点不是让 AI 直接给答案，而是让 AI 给出可审查、可确认、可沉淀的候选规范。
真正决定规范成色的，是我们核心研发对代表性模块的判断和对 draft 的态度。
```

## 11. Q&A 预案（开发者视角答疑）

下面这 10 个问题都偏「设计辩护」，与 sharing-script 里更偏使用者的 FAQ 互补。

### Q1：你为什么不直接做一个一键全仓生成正式规范的开关？

短答：那条路质量底线托不住。

长答：错误规则一旦进入 AI 默认上下文，回滚成本远高于事前审查；profile-first 和单 batch 是把审查成本压在线性的工程妥协。

### Q2：扫描成本看起来很高，能不能加缓存？

可以，但缓存层只能对 evidence 做，不能对 draft 做。draft 必须每次重算才能反映最新代码事实。Phase 2 修复验证里我们已经在试 `signal_scan.v1` 缓存，但稳定路径不发布。

### Q3：Quality Gate 那么多 persona，会不会过度评审？

不会。Gate A 9 项门禁里至少 6 项是机器可判（evidence 链断、跨 batch、AI 不可执行表达、checklist 不可二值、含真实路径、行业声明过度）。剩余 3 项才需要人介入：人工确认、行业风险背景、和已有规则的语义冲突。

### Q4：和 spec-first 工作流是什么关系？

spec-first 管的是「需求 → 计划 → 任务 → 执行 → review」整条链路，project-standard-extractor 是其中「让 AI 拥有团队上下文」的一块基础设施。spec-first 的 `/spec:code-review` 和 `/spec:work` 都可以消费萃取产物。

### Q5：为什么 ai-rules 不允许有自己独立的规则？

因为派生视图一旦能新增规则，AI 看到的规范、Reviewer 看到的规范、文档里讲的规范就会三套漂移。我们宁可规则少一点也要保持单一来源。

### Q6：candidate 索引产物到底什么时候能升级成正式索引？

需要满足三件事：
1. 至少一个 `domain` 下的 `standard-{sub_domain}.md` 全部进入 active。
2. 维护者人工审核 candidate 内容，确认 schema 与正式索引兼容。
3. 显式发布动作落到仓库根 `.index/rules-index.json` 和 `llms.txt`。

这条路径目前没有自动化，故意保持手动，避免「萃取-发布」一气呵成造成的污染。

### Q7：append-only 文件是不是会越来越长？

会。我们对策：
- `standard-{sub_domain}.md` 章节按 `{source_doc}「{section_title}」` 去重，相同标题只追加 evidence。
- `pending-confirmation.md` / `conflicts.md` / `merge-suggestions.md` 是工作流文件，处理完以后由维护者按时间窗归档。
- 真正失控时，maintainer 工具有 `restore` / `backup` 兜底，但这是 repair-only 入口。

### Q8：Phase 2 维度框架未来想做成什么样？

定位是「在画像里识别该领域的常见维度（架构 / 测试 / 安全 / 性能 / AI 上下文等）并各自激活」。现在 blocked 的原因不是设计问题，而是 N-01/N-02/N-03 + force-rebuild safety + 最终 eval 还没全部通过。在解锁前不发布。

### Q9：跨项目（cross-project aggregator）和 EA-Doc 呢？

cross-project 用来把多个项目的 per-project activation report 合并成部门级视图；EA-Doc 用来把架构文档作为额外的事实来源。两者都依赖 Phase 2 维度框架先打通，时间表要等 Phase 2 解锁后再排。

### Q10：怎么衡量这套东西真有用？

不是看产物数量。我们关注：
- 同一类问题在 Review 里被反复解释的次数是否下降。
- AI 生成代码的 Review 返工率是否下降。
- draft → active 的升级比例和升级所需时间。
- forbidden evidence 是否真的拦下了线上反模式。
- 新人或跨模块开发找到「该怎么写」的成本。

## 12. 演进路线

```text
当前(Phase 1 稳定路径)
   ├─ profile-first / batch-extraction
   ├─ Quality Gate · Gate A
   └─ append-only / draft-only

短期 — 在不破坏稳定路径前提下打磨
   ├─ batch-plan 推断质量提升
   ├─ Quality Gate · Gate A 机器化覆盖率提升
   └─ ai-context-pack 候选审查工具

中期 — Phase 2 维度框架解锁
   ├─ N-01 / N-02 / N-03 通过
   ├─ force-rebuild safety 通过
   ├─ 最终 eval 通过
   ├─ dimension-activator 公开
   └─ generation_profile = phase2-dimension-aware 公开

长期 — 跨项目与跨研发域
   ├─ cross-project aggregator
   ├─ EA-Doc 文档事实来源
   └─ 行业规范 PoC(securities 等)
```

讲分享时，建议把这张图当「我们现在在哪 / 我们不打算许诺什么」的边界图，不要承诺时间。

## 13. 共建邀约与试点

这一章把听众从「使用者」转成「共建者」。

### 13.1 谁做什么

| 角色 | 试点期责任 |
| --- | --- |
| Skill 维护者（我） | 跑稳定路径、解释产物边界、收集反馈、维护 CHANGELOG |
| 模块 owner | 选代表性 batch、判断 draft、决定 active 升级 |
| Reviewer 代表 | 用 `review-checklist.md` 做一次真实 PR 评审，反馈是否减少重复解释 |
| AI 重度使用者 | 用 active 规则跑一次真实开发任务，反馈是否减少返工 |

### 13.2 试点行动建议（7 天）

```text
Day 1   核心研发各推荐 1 个代表性模块，标注哪些代码只是历史兼容 / 反例
Day 2-3 维护者对推荐模块跑 profile-first → 选 batch → batch-extraction
        产出 evidence + draft standard / ai-rules / review-checklist
Day 4   owner 走查 draft，决定哪些升级 active、哪些进 pending
Day 5   AI 重度使用者用 active 规则跑一次真实开发任务
Day 6   Reviewer 代表用 review-checklist 走一次真实 PR
Day 7   汇总反馈，决定下一个试点模块
```

### 13.3 试点验收标准

- 至少产出一个可审查的 `standard-{sub_domain}.md` draft。
- 每条候选规则都能追溯到 evidence。
- 至少明确一条 `active` / `pending` / `conflict` 决议。
- 至少一次 AI 开发任务消费 active 规则。
- Reviewer 反馈是否减少重复解释。

### 13.4 不要追求的事

- 不追求一次全量覆盖。
- 不追求 draft → active 升级率 100%。
- 不追求 candidate 索引立即发布。
- 不追求 Phase 2 / cross-project 在试点期就上线。

## 14. 讲者备忘清单

上台前自检：

- 公开稳定路径只有 `profile-first → 选 batch → batch-extraction`；忘了什么都不能忘这条。
- `draft` 与 `active` 的边界要反复说，至少三次。
- Phase 2 / force-rebuild / restore / pin / unpin / list 全部不作为今天的可用能力，被追问时回到「这是后续 repair / maintainer 主题，今天不展开」。
- 准备一组真实的 profile / batch-plan / standard / ai-rules / review-checklist 样例，避免现场扫真实大仓。
- 准备一个开放问题：「你愿意推荐哪个模块作为代表性 batch？为什么」——把听众拉进共建。

现场最容易失焦的点和拉回话术：

| 失焦点 | 拉回话术 |
| --- | --- |
| 讨论模型能力强弱 | 今天重点不是模型强弱，而是团队上下文怎样资产化 |
| 追问全仓自动生成 | 稳定路径先保证可信，不做无边界全量自动发布 |
| 追问 Phase 2 / force-rebuild | 这是维护者或 repair 主题，今天只讲当前可稳定复用路径 |
| 把 draft 当规范 | draft 是候选；active 才是团队承诺 |
| 想让 AI 替代 Review | AI 整理事实，核心研发做规范判断 |

收口三句：

```text
1) AI 辅助开发要继续提升，关键不是让模型知道更多通用知识，而是让它理解我们团队真实的工程约束。
2) project-standard-extractor 故意克制：先 profile-first，再选一个 ready batch，再生成 evidence-backed draft，最后由团队确认 active。
3) 这件事必须有核心研发参与。AI 可以整理事实，但只有我们能决定哪条规则应该进入 AI 默认上下文。
```

## 附录 A · 来源文件索引

读者按这个顺序看，可以独立验证本稿每个判断：

| 主题 | 文件 |
| --- | --- |
| 公开触发面 | `skills/project-standard-extractor/SKILL.md` |
| 稳定路径 + Phase 2 / repair-only 边界 | `skills/project-standard-extractor/references/workflow.md` |
| 阶段契约 | `skills/project-standard-extractor/references/agents/*.md` |
| 输出位置 | `skills/project-standard-extractor/references/config/output-targets.md` |
| Quality Gate | `skills/project-standard-extractor/references/quality-gate.md` |
| 用户手册 | `docs/03-用户手册/AI辅助研发工程规范用户手册.md` |
| 执行逻辑分析 | `docs/03-用户手册/project-standard-extractor-execution-analysis.md` |
| 30 分钟话术稿 | `docs/03-用户手册/project-standard-extractor-sharing-script.md` |
| 维护者工具 | `tools/maintainer/project-standard-extractor/README.md` |

权威顺序：`SKILL.md` 决定公开触发面；`references/workflow.md` 决定稳定路径与 repair-only 边界；阶段 agent 契约只解释该阶段内部 handoff。当三者描述出现差异时按这个顺序裁定。

## 附录 B · 一页备忘（可截图）

```text
公开稳定路径
  profile-first  →  选 1 个 ready batch  →  batch-extraction
                     ↑
              人挑 batch，不是 AI 一路跑

公开输入字段（只有 5 个）
  project_paths · output_dir · extraction_mode
  selected_batch.batch_id · run_mode

公开输出（按消费方式）
  运行级 handoff   temp/{run_id}-*.md      （不进 AI 默认上下文）
  规范资产         engineering-standards/  （active 才进 AI 强约束）
  候选索引         temp/{run_id}-*-candidate.* （审查材料，不发布）

规则状态
  active           → AI 默认强约束，owner 确认
  draft            → 候选建议，需要 owner 升级
  pending / conflict / legacy-compatible → 不进 AI 默认执行路径

不做的事
  不一键全仓出规则 · 不自动发布 active · 不覆盖 active / draft
  不读取敏感原值  · 不暴露 maintainer / repair-only 入口
```

## 附录 C · 产物目录结构

权威定义在 `skills/project-standard-extractor/references/config/output-targets.md`，下面这张图按当前 source-of-truth 加上仓库实地布局（参考 `engineering-standards/01-app-client/`）整理。

### C.1 顶层目录树

```text
engineering-standards/                       ← 输出根（SKILL.md 默认 output_dir）
└── {domain}/                                ← 一个研发域一个目录（实地可能加编号前缀，如 01-app-client、04-backend）
    │
    ├── overview.md                          ← 该研发域总览（人工或维护者维护）
    ├── README.md                            ← 入口说明
    │
    ├── standard-{sub_domain}.md             ← 子领域规范主文档（每个 sub_domain 一份）
    ├── standard-common.md                   ← 跨子领域共性规则
    │
    ├── ai-rules.md                          ← 派生视图：AI 可执行约束（每个 domain 一份）
    ├── review-checklist.md                  ← 派生视图：Review 检查项（每个 domain 一份）
    │
    ├── pending-confirmation.md              ← 证据不足 / 待 owner 确认（append-only）
    ├── merge-suggestions.md                 ← 与已有规则相近、建议合并（append-only）
    ├── conflicts.md                         ← 与已有 active/draft 冲突（append-only）
    │
    ├── evidence/                            ← evidence 目录（规则的事实底座）
    │   ├── README.md
    │   ├── code-facts.md                    ← 代码事实与推导边界
    │   ├── positive-examples.md             ← 推荐写法证据
    │   ├── forbidden-examples.md            ← 反例 / 禁止写法证据
    │   └── legacy-compatible.md             ← 历史兼容写法说明
    │
    ├── examples/                            ← 示例代码片段
    │   └── README.md
    │
    ├── rule-state-decision/                 ← 规则状态决策记录（draft → active 等）
    │   └── {slug}.md                        ← 一条规则一份，indexable: false
    │
    ├── temp/                                ← 运行级 handoff & 候选索引（按 run_id 命名）
    │   ├── {run_id}-project-profile.md
    │   ├── {run_id}-extraction-map.md
    │   ├── {run_id}-batch-plan.md
    │   ├── {run_id}-review-report.md
    │   ├── {run_id}-review-summary.md
    │   ├── {run_id}-ai-context-pack.md
    │   ├── {run_id}-rules-index-candidate.json
    │   └── {run_id}-llms-candidate.txt
    │
    ├── rules-index.json                     ← 正式索引（必须显式发布，不自动覆盖）
    └── llms.txt                             ← 正式 AI 入口地图（必须显式发布）
```

### C.2 按消费方式分四类

| 类别 | 路径 | 是否进 AI 默认上下文 | append-only |
| --- | --- | --- | --- |
| 规范资产（owner 确认后可作为强约束） | `standard-{sub_domain}.md` / `standard-common.md` / `ai-rules.md` / `review-checklist.md` / `evidence/*` | active 才进 | ✅ |
| 工作流文件（待处置） | `pending-confirmation.md` / `merge-suggestions.md` / `conflicts.md` | ❌ | ✅ |
| 运行级 handoff（一次萃取的过程产物） | `temp/{run_id}-*.md` | ❌（默认 `indexable: false`） | run_id 文件不重写 |
| 候选索引（审查材料） | `temp/{run_id}-rules-index-candidate.json` / `temp/{run_id}-llms-candidate.txt` / `temp/{run_id}-ai-context-pack.md` | ❌ | 候选不发布 |
| 正式索引（显式发布动作） | `engineering-standards/{domain}/rules-index.json` / `llms.txt` / 仓库根 `.index/rules-index.json` 与根 `llms.txt` | ✅ | 显式审核后写入 |

### C.3 命名规则

- `{domain}`：由 Intake 推断，例如 `app-client` / `pc-client` / `frontend` / `backend` / `industry`；实地目录可能加编号前缀（`01-app-client`）。
- `{sub_domain}`：研发域下的子领域，例如 `android` / `kmp-shared` / `module-boundary`。
- `{run_id}`：`YYYYMMDD-HHMMSS-{domain}`，Intake 阶段生成，贯穿整次萃取，run 内所有 handoff 与候选索引文件共享同一前缀。
- `{slug}`：从规则 `section_title` 派生——去掉 `P0/P1/P2/FORBIDDEN ` 前缀，转 kebab-case，去除非 `[a-z0-9-]` 字符，截到 60 字符。

### C.4 一次萃取的实际产物示意

来自 `engineering-standards/01-app-client/temp/`：

```text
20260522-100947-app-client-project-profile.md
20260522-100947-app-client-extraction-map.md
20260522-100947-app-client-batch-plan.md
20260522-100947-app-client-review-report.md
20260522-100947-app-client-review-summary.md
20260522-100947-app-client-ai-context-pack.md
20260522-100947-app-client-rules-index-candidate.json
20260522-100947-app-client-llms-candidate.txt
```

同一次 run 的所有 handoff 与候选索引文件共享同一个 run_id 前缀，便于追溯和归档。

### C.5 关键边界与质量约束

- `standard-{sub_domain}.md` 单文件超过 **1500 行** 时，`merge-coordinator` 会输出 ⚠️ 拆分建议（按 task_type 进一步拆分）。
- 所有规范资产文件都要带 `engineering-standards-md-v1` Front Matter，`doc_id` 稳定不变，重复运行不得改写。
- 规则 H2 标题必须以 `P0 / P1 / P2 / FORBIDDEN ` 开头，且与 `rules-index.json.section_title` 字面一致；**不生成 Rule ID 或 HTML anchor**。
- `temp/` 下的 handoff 文件默认 `indexable: false`，不进入 AI 快速索引。
- `rules-index-candidate.json` / `llms-candidate.txt` 永远是候选；发布到 `engineering-standards/{domain}/rules-index.json` / `llms.txt` 或仓库根 `.index/rules-index.json` / 根 `llms.txt` 必须由用户显式确认，Skill 自动运行不会写正式索引。
- `rule-state-decision/{slug}.md` 是规则状态变化（如 draft → active）的人工决策记录，由维护者维护，不属于 Skill 自动产物。

### C.6 用一句话记住

```text
engineering-standards/{domain}/  下的文件默认是 append-only 规范资产；
temp/{run_id}-*  下的文件是过程产物和候选材料，永远不进 AI 默认上下文；
rules-index.json / llms.txt 必须显式发布，Skill 不替团队按下发布键。
```
