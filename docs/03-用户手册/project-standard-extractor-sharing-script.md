# project-standard-extractor 30 分钟团队分享稿

## 1. 分享定位

**主题：** 把真实代码变成 AI 可复用的团队规范：`project-standard-extractor` 的稳定路径、设计取舍和共建机制。

**听众：** 部门核心研发人员。大家已经重度使用 AI 辅助开发，关心的不是“AI 会不会写代码”，而是：

- AI 为什么总是缺少团队上下文。
- 怎样让 AI 遵守我们真实项目里的架构、分层、命名和 Review 习惯。
- 怎样减少 Reviewer 反复解释同一类问题的成本。
- 怎样把项目经验从口头共识变成可复用、可审查、可演进的规范资产。

**分享时长：** 30 分钟。

**讲者目标：**

1. 让大家理解这个 Skill 的核心价值：不是生成文档，而是建设 AI 可复用的团队上下文。
2. 让大家记住稳定路径：`profile-first -> 选一个 ready batch -> batch-extraction`。
3. 让大家清楚产物边界：`active` 才能作为强约束，`draft` 只是候选，`pending-confirmation` / `conflict` 不能进入 AI 默认执行路径。
4. 让核心研发知道自己怎么参与：选代表性模块、判断 draft、确认 active、验证 AI 开发效果。

**不展开的内容：**

- 不讲 Phase 2 `dimension-activator` 的实现细节。
- 不讲 `force-rebuild` / `restore` / `pin` / `unpin` / `list` 等维护者或 repair-only 能力。
- 不把它包装成一键全仓生成正式规范的能力。
- 不现场承诺跨项目、行业 PoC 或 EA-Doc 已是普通用户稳定路径。

**本场成功标准：**

分享结束后，核心研发能用一句话复述：

```text
project-standard-extractor 先从真实代码做 profile-first，选一个 ready batch 后生成 evidence-backed draft；只有 owner 确认后的 active 规则，才能进入 AI 编码和 Review 的默认强约束。
```

## 2. 30 分钟结构

| 时间 | 模块 | 讲者目标 | 听众应带走的结论 |
| --- | --- | --- | --- |
| 0-3 分钟 | 开场：AI 开发真正缺什么 | 建立共鸣，指出“缺团队上下文” | 问题不是模型能力，而是团队约束没有资产化 |
| 3-7 分钟 | 一句话定位 | 讲清它是什么、不是什么 | 从真实代码萃取 evidence-backed draft，不是生成通用最佳实践 |
| 7-15 分钟 | 稳定使用路径 | 讲清怎么安全使用 | `profile-first -> 单 ready batch -> batch-extraction` |
| 15-20 分钟 | 产物如何进入 AI / Review | 讲清产物消费方式 | `standard` / `ai-rules` / `review-checklist` 给 AI 和 Reviewer，evidence 给判断 |
| 20-25 分钟 | 关键设计取舍 | 解释为什么路径这么克制 | profile-first、单 batch、draft-only、append-only 都是为了防止错误规则进入默认上下文 |
| 25-28 分钟 | 核心研发怎么共建 | 把听众从“使用者”转成“规则 owner” | 代表性模块、draft 判断、active 确认、试点验证都需要核心研发参与 |
| 28-30 分钟 | 收口和会后行动 | 明确下一步 | 先选一个模块跑通闭环，不追求一次全量覆盖 |

**时间压缩策略：**

- 如果只有 20 分钟，保留第 3-8 章，压缩 FAQ。
- 如果讨论很热，优先让讨论发生在“代表性模块怎么选”和“draft 怎么升级 active”，不要陷入 Phase 2 或维护者工具细节。
- 如果有人追问全量自动化，回到一句话：稳定路径先服务可信规范资产，不服务无边界的全仓自动生成。

## 3. 开场稿：从 AI 开发痛点切入

可以直接这样开场：

```text
大家现在应该都有一个共同感受：AI 辅助开发已经不是新鲜事了。
它能写代码、能补测试、能解释 diff，也能根据上下文做相当复杂的改动。

但真正卡住我们效率的，往往不是 AI 不会写代码，而是它不知道“我们团队这里应该怎么写”。
```

接着给三个常见场景：

1. AI 写出行业最佳实践，但不符合我们项目的分层和模块边界。
2. AI 参考了仓库里的历史代码，却不知道哪些是推荐写法、哪些是历史兼容、哪些其实是反例。
3. Reviewer 在 PR 里反复解释同一类规则，比如依赖方向、状态流转、异常处理、命名边界、配置安全，但这些解释没有沉淀成下一次 AI 可直接使用的上下文。

然后转入核心判断：

```text
所以我们缺的不是再写一份“通用编码规范”。
通用规范网上很多，模型本身也知道很多。

我们真正缺的是团队上下文：哪些代码代表当前推荐写法，哪些只是历史包袱，哪些写法 Reviewer 一定会挡住，哪些规则已经被负责人确认。
```

强调这句话：

```text
project-standard-extractor 要解决的，就是把真实代码里的团队经验，变成 AI 可消费、Reviewer 可检查、负责人可确认的规范资产。
```

讲者提醒：

- 这里不要急着讲输入参数。
- 先让大家认同“AI 缺团队上下文”这个问题。
- 对核心研发来说，最有说服力的不是“这个 Skill 能生成文档”，而是“它能减少 AI 胡乱套用历史代码、减少 Review 重复沟通”。

## 4. 一句话定位

一句话版本：

```text
project-standard-extractor 是一条从真实项目代码萃取团队级研发规范的生产线。
它自动生成的是 evidence-backed draft，不自动发布 active。
```

展开讲：

它的稳定产出包括：

- `standard-{sub_domain}.md`：面向人和 AI 的团队开发规范草案。
- `ai-rules.md`：从 standard 派生出的 AI 可执行约束。
- `review-checklist.md`：从 standard 派生出的 Review 检查项。
- `evidence/code-facts.md`：规则背后的代码事实。
- `evidence/positive-examples.md`：推荐写法证据。
- `evidence/forbidden-examples.md`：禁止写法或风险证据。
- `pending-confirmation.md`：证据不足或需要 owner 判断的候选项。
- `merge-suggestions.md`：与已有规则相近、建议合并的内容。
- `conflicts.md`：与已有 active / draft 冲突的内容。
- 候选索引产物：`rules-index-candidate.json`、`llms-candidate.txt`、`ai-context-pack.md`。

它明确不是：

- 代码评审工具。
- 业务代码修改工具。
- 通用最佳实践生成器。
- 一键全仓生成正式规范的工具。
- 自动发布 `active` 规则的工具。
- 维护者 repair 工具的普通入口。

可以举一个抽象例子：

```text
比如一个 Android/KMP 模块里，多个新近模块都使用 Presenter 工厂方法、StateMapper 和 ViewBinding 来组织状态与视图。
Skill 可以把这些事实整理成 code-facts，再生成一条 draft 规范：
新模块应保持宿主 Fragment 只做编排，状态转换收敛到 StateMapper，Presenter 通过工厂方法构建。

但它不会自己宣布这条就是团队正式规范。
核心研发要看 evidence 是否代表当前推荐写法，确认后才能把它升级成 active。
```

这一章要让听众记住的句子：

```text
AI 负责整理事实，人负责做规范承诺。
```

## 5. 稳定使用路径

这一章是分享主体。建议用一张流程图讲完：

```text
project_paths
  |
  v
profile-first
  |
  +--> project-profile
  +--> extraction-map
  +--> batch-plan
  |
  v
选择 1 个 status: ready 的 batch
  |
  v
batch-extraction
  |
  +--> code-facts / classification
  +--> draft standard / ai-rules / review-checklist
  +--> evidence / pending / conflicts / merge-suggestions
```

### 5.1 第一步：profile-first

讲稿：

```text
当输入是完整仓库、完整项目、多服务、多端，或者我们还不确定范围时，第一步必须是 profile-first。
它只做轻量画像，不直接生成正式规范。
```

稳定输入：

```yaml
project_paths:
  - /path/to/project
extraction_mode: profile-first
```

这一步输出：

| 产物 | 作用 | 讲解重点 |
| --- | --- | --- |
| `temp/{run_id}-project-profile.md` | 项目画像 | 技术栈、目录结构、候选模块、敏感边界 |
| `temp/{run_id}-extraction-map.md` | 萃取地图 | 哪些区域可能有规范 evidence |
| `temp/{run_id}-batch-plan.md` | batch 计划 | 哪些 batch 可以正式萃取，哪些需要跳过或确认 |

强调：

```text
profile-first 的完成点不是“生成规范”，而是“让人选择哪个 batch 有代表性”。
```

### 5.2 第二步：选择一个 ready batch

讲稿：

```text
拿到 batch-plan 后，不是让 AI 自动全量跑下去，而是由人选择一个 status: ready 的 batch。
这个选择很关键，因为它决定了后续 evidence 的边界。
```

稳定输入：

```yaml
project_paths:
  - /path/to/project
extraction_mode: batch-extraction
selected_batch:
  batch_id: <batch-plan 里的 ready batch id>
```

为什么一次只选一个 batch：

- 一个仓库里同时存在推荐写法、历史兼容、临时方案和反例。
- 读太宽会让 AI 把“存在过的写法”误当成“推荐写法”。
- 单 batch 能让每条规则回到具体 evidence，Reviewer 才能审查。
- 单 batch 的结论更容易由 owner 确认或否决。

可以直接说：

```text
我们宁愿慢一点，也不要把不可信的规则放进 AI 默认上下文。
```

### 5.3 batch-extraction 做什么

选定 batch 后，Skill 做三件事：

1. 只读取这个 batch 的 candidate files 和必要邻近文件。
2. 生成 `code-facts`，并把材料分类为 recommended / forbidden / legacy / pending / conflict。
3. 基于 evidence 生成 draft standard、AI Rules、Review Checklist 和候选索引。

稳定路径里的生成 profile 是：

```text
generation_profile: phase1-selected-batch
```

这句话的含义要讲清楚：

- 不读取 `dimension-activator`。
- 不要求 `activation-report`。
- 不启动 Phase 2 repair-only 管道。
- 不把 cross-project、EA-Doc、securities PoC 当普通稳定能力。
- 不执行 `force-rebuild` / `restore` / `pin` / `unpin` / `list`。

### 5.4 公开稳定字段

为了避免大家误用，可以展示一页“能传什么，不能传什么”。

稳定字段：

```yaml
project_paths:
  - /path/to/project
output_dir: ""
extraction_mode: ""      # profile-first | batch-extraction | focused-module
selected_batch:
  batch_id: ""
run_mode: auto           # auto | interactive
```

补一句避免误解：

```text
focused-module 是已明确小模块范围时的窄范围模式，不是本场分享的主线。
只要输入是完整仓库、多服务、多端或范围不清，仍然先走 profile-first。
```

普通公开入口不要传：

- `output_action`
- `domain`
- `restore_from`
- `keep`
- `full`

讲者解释：

```text
这些字段不是给普通规范萃取用的公开 API。
我们分享时要避免把内部 repair 或 maintainer 契约讲成普通使用方式。
```

## 6. 产物如何服务 AI 开发

这一章的重点不是列文件名，而是讲清产物怎么进入真实 AI 工作流。

### 6.1 给 AI 的直接上下文

推荐给 AI 的上下文顺序：

1. 当前需求或任务说明。
2. 对应研发域的 `overview.md`。
3. 对应 `standard-{sub_domain}.md` 或 `standard-common.md`。
4. `ai-rules.md`。
5. 与本次任务相关的 `review-checklist.md`。
6. 必要时补充 positive / forbidden evidence。

可以给团队一个可复制提示词：

```text
请基于以下团队规范完成开发：
1. <domain>/overview.md
2. <domain>/standard-<sub_domain>.md
3. <domain>/ai-rules.md
4. <domain>/review-checklist.md

只把 active 规则作为强约束；
draft 规则仅作为候选建议；
pending-confirmation 和 conflict 不得作为执行依据；
如果你认为需求与规范冲突，先指出冲突，不要自行覆盖规范。
```

不推荐的提示方式：

```text
这里有一批萃取结果，你全部按里面说的写。
```

原因：

- 这会把 draft、pending、conflict 混在一起。
- AI 会倾向于把所有上下文都当作可执行指令。
- 最后会把“待确认事实”变成“默认规范”。

### 6.2 给 Reviewer 的判断依据

Reviewer 的消费方式不是“相信 AI 生成的规范”，而是沿 evidence 链路判断。

| 产物 | Reviewer 看什么 |
| --- | --- |
| `standard-{sub_domain}.md` | 规则是否表达清晰、是否团队级抽象 |
| `review-checklist.md` | 检查项是否可二值判断 |
| `evidence/code-facts.md` | 是否有事实支撑 |
| `evidence/positive-examples.md` | 推荐写法来自哪里 |
| `evidence/forbidden-examples.md` | 反例是否成立 |
| `pending-confirmation.md` | 哪些内容不能直接采纳 |
| `conflicts.md` | 哪些内容需要 owner 仲裁 |

建议 Review 引用格式：

```text
{source_doc}「{section_title}」
```

讲稿：

```text
以后 Review 里我们希望少一点“我觉得这样不好”，多一点“这条和团队规范的某个规则冲突”。
这样 AI 下次也能学到同一条约束，而不是每个 PR 都重新解释。
```

### 6.3 产物状态边界

必须讲清这张表：

| 状态 / 产物 | 能不能作为 AI 默认强约束 | 处理方式 |
| --- | --- | --- |
| `active` | 可以 | 默认进入 AI 编码和 Review |
| `draft` | 不可以 | 作为候选建议，等待 owner 确认 |
| `pending-confirmation` | 不可以 | 需要负责人判断 |
| `conflict` | 不可以 | 进入冲突处理，不进入默认执行路径 |
| `legacy-compatible` | 不可以 | 解释历史兼容，不推荐新代码照抄 |
| `rules-index-candidate.json` / `llms-candidate.txt` | 不可以直接覆盖正式索引 | 只作为候选索引审查材料 |

这一章的核心句：

```text
让 AI 更懂团队，不等于让 AI 越过团队确认机制。
```

## 7. 关键设计取舍

核心研发通常会问“为什么不能更自动一点”。这一章要解释：克制不是能力不足，而是为了防止错误规则进入团队默认上下文。

### 7.1 profile-first：先判断范围，再写规则

设计取舍：

```text
完整仓库不能直接出规则，必须先 profile-first。
```

原因：

- 仓库里的“存在”不等于“推荐”。
- 目录结构、模块成熟度和历史债务需要先被识别。
- 敏感路径和不可读材料需要先被隔离。
- batch plan 能把人类判断放到规则生成之前。

如果不这么做：

- AI 可能把历史兼容代码写成新规范。
- 规则会失去来源边界，Reviewer 很难复核。
- owner 很难判断哪部分该确认、哪部分该退回。

### 7.2 单 batch：保证 evidence 边界可审查

设计取舍：

```text
正式萃取一次只处理一个 ready batch。
```

原因：

- 单 batch 能让规则回到具体代码证据。
- 单 batch 更容易判断“这是不是当前推荐写法”。
- 单 batch 更适合小步试点和 owner 确认。

如果不这么做：

- 多个模块的局部约定会互相污染。
- 不同年代、不同风格、不同负责人留下的代码会被混成一条规则。
- 规则看似全面，实际无法落地。

### 7.3 draft-only：AI 不替团队做承诺

设计取舍：

```text
自动输出默认是 draft，不自动发布 active。
```

原因：

- AI 可以整理事实，但不能替团队承诺规范。
- 规范一旦进入 AI 默认上下文，会影响后续所有生成代码。
- active 需要明确 owner 和确认过程。

如果不这么做：

- 一次错误萃取会被后续 AI 反复放大。
- Reviewer 会被迫反驳“AI 说这是规范”。
- 团队规范的权威性会下降。

### 7.4 append-only：不覆盖已有规范

设计取舍：

```text
新萃取只追加 draft、evidence、merge suggestions 和 conflicts，不覆盖已有 active / draft。
```

原因：

- 规范演进需要可追溯。
- 旧规则和新事实的冲突需要显式暴露。
- 合并和升级应该由 owner 决定。

如果不这么做：

- 历史规范会被静默改写。
- 团队无法解释某条规则什么时候、为什么变化。
- active 规则的稳定性会被破坏。

### 7.5 repair-only：高风险能力不放进普通入口

设计取舍：

```text
Phase 2、force-rebuild、restore、pin、unpin、list 等能力不作为普通稳定路径分享。
```

原因：

- 这些能力涉及更复杂的状态、备份、恢复、跨项目或维度判断。
- 当前普通使用者最需要的是可信的 Phase 1 规范萃取闭环。
- 分享时提前暴露高风险能力，会让使用预期跑偏。

如果有人追问，可以回答：

```text
这些能力可以作为后续维护者或 repair 主题单独讲。
今天我们只讲团队当前可稳定复用的路径。
```

## 8. 核心研发怎么参与共建

这一章要把听众从“工具使用者”转成“规范共建者”。

### 8.1 选代表性模块

核心研发最知道哪些代码代表当前推荐写法。试点时需要大家提供三类判断：

| 判断 | 问题 |
| --- | --- |
| 推荐样本 | 哪些模块能代表当前主流架构和编码方式 |
| 历史兼容 | 哪些模块能跑但不该作为新代码范式 |
| 反例沉淀 | 哪些写法 Reviewer 会挡，适合沉淀成 forbidden evidence |

选择标准：

- 最近仍在维护。
- 负责人认可其结构。
- 不是迁移过渡或临时方案。
- 有足够代码事实支撑，而不是只有口头约定。
- 能覆盖一个明确子领域，不要一开始就跨太多边界。

### 8.2 判断 draft 是否能升级 active

draft 升级 active 前，核心研发至少看四件事：

1. **代表性：** evidence 是否来自当前推荐模块，而不是历史包袱。
2. **抽象度：** 规则是否是团队级约束，而不是单文件说明。
3. **可执行性：** AI 能不能按这条规则写代码。
4. **可评审性：** Reviewer 能不能用这条规则做二值判断。

一个 draft 不应该升级 active 的信号：

- 规则里出现“尽量”“适当”“合理”等无法检查的表达。
- 只有一个孤立样例，没有足够代表性。
- 规则其实是在描述当前实现，而不是约束未来写法。
- 与已有 active 冲突，但没有 owner 仲裁。
- 需要业务语境才能判断，无法变成通用工程约束。

### 8.3 把 active 反馈进 AI 工作流

active 规则确认后，要进入两个默认路径：

- AI 编码：作为提示词和上下文包里的强约束。
- Code Review：作为 checklist 和评审引用依据。

目标不是多一批文档，而是形成闭环：

```text
真实代码 evidence
  -> draft 规范
  -> owner 确认 active
  -> AI 按 active 生成代码
  -> Reviewer 按 active 检查
  -> 新的反例或共识继续沉淀
```

### 8.4 试点角色分工

建议试点时明确四个角色：

| 角色 | 责任 |
| --- | --- |
| 分享者 / Skill 维护者 | 跑 `profile-first` 和 `batch-extraction`，解释产物边界 |
| 模块 owner | 选择代表性 batch，判断 draft 是否能升级 |
| Reviewer 代表 | 检查 checklist 是否真的能用于 Review |
| AI 重度使用者 | 用 active 规则跑一次真实 AI 开发任务，反馈是否减少返工 |

试点不要追求覆盖率，先追求一条链路跑通。

## 9. 现场演示建议

30 分钟分享不建议现场跑真实大仓，时间不可控。建议展示一次准备好的 dry run 或样例产物。

### 9.1 5 分钟演示结构

| 时间 | 画面 | 讲什么 |
| --- | --- | --- |
| 0-1 分钟 | `SKILL.md` 输入契约 | 公开字段很少，核心是 `project_paths`、`extraction_mode`、`selected_batch.batch_id` |
| 1-2 分钟 | `project-profile.md` / `extraction-map.md` | 第一步只画像，不生成规则 |
| 2-3 分钟 | `batch-plan.md` | 人选择一个 ready batch |
| 3-4 分钟 | `code-facts` + evidence | 规则先有事实，不先写结论 |
| 4-5 分钟 | `standard` / `ai-rules` / `review-checklist` / `pending` / `conflicts` | draft 可以被审查，不能自动当 active |

### 9.2 演示台词

```text
这一步我不现场扫一个大仓，因为真实扫描受项目体量、文件权限和上下文窗口影响。
我们看一组准备好的产物。

先看 profile-first：它只告诉我们这个项目有哪些候选模块、哪些路径不能碰、哪些 batch 可能 ready。
注意这里还没有生成团队规范。

然后我们选一个 ready batch。
选 batch 是人类判断，不是 AI 自己一路跑到底。

进入 batch-extraction 后，先看 code-facts，再看 standard 和 ai-rules。
如果大家发现某条规则证据不足，它应该进 pending-confirmation；
如果它和已有规则冲突，它应该进 conflicts；
只有 owner 确认后，才可能变成 active。
```

### 9.3 演示不要做什么

- 不要现场承诺“给我一个仓库，马上生成全部正式规范”。
- 不要把 `draft` 拷进 AI 默认提示词后不标状态。
- 不要展示维护者 repair-only 字段作为普通输入。
- 不要让讨论转成“这个工具能不能替代 Review”。

演示收口句：

```text
这套流程的重点不是让 AI 直接给答案，而是让 AI 给出可审查、可确认、可沉淀的候选规范。
```

## 10. 常见问题预案

### Q1: 能不能直接从一个成熟项目生成完整规范？

不能作为稳定路径这么做。成熟项目里也有历史包袱、迁移残留和局部妥协。先 `profile-first`，再选代表性 batch，规范质量和可审查性都会更高。

### Q2: draft 能不能先给 AI 用？

可以作为候选建议，但必须明确告诉 AI：`draft` 不是强制规则。默认强约束只使用 `active`。`pending-confirmation` 和 `conflict` 不应进入默认执行路径。

### Q3: `ai-rules.md` 和 `standard-{sub_domain}.md` 有什么区别？

`standard-{sub_domain}.md` 是完整开发指南，解释背景、职责、推荐和禁止写法。`ai-rules.md` 是从 standard 派生出的 AI 执行约束，不新增独立规则。二者冲突时，以 standard 和规则状态为准。

### Q4: 如果 generated draft 和已有 active 冲突怎么办？

写入 `conflicts.md`，不覆盖旧规则。owner 决定保留旧规则、采纳新规则，或合并改写。冲突未解决前，不进入 AI 默认执行路径。

### Q5: 为什么不直接用团队现有文档做 AI 上下文？

现有文档当然要用，但很多团队经验只存在于真实代码和 Review 习惯里。`project-standard-extractor` 的价值是把代码事实、推荐样例、反例和待确认项一起拉出来，让规则有 evidence，而不是只复制已有文档。

### Q6: 这会不会替代 Reviewer？

不会。它减少 Reviewer 重复解释规则的成本，但不替代判断。尤其是 `draft -> active`、冲突仲裁和代表性模块选择，都必须由核心研发或 owner 决定。

### Q7: 如果 AI 萃取错了怎么办？

错误不应该进入 active。稳定路径通过三层兜底降低风险：单 batch 控制 evidence 边界，draft-only 防止自动发布，append-only 防止覆盖已有规则。错误规则应留在 draft、pending 或 conflicts 中等待处理。

### Q8: Phase 2 维度框架什么时候能用？

等 repair 验证和公开契约收敛后再作为单独主题讲。当前团队试点只使用稳定路径：`profile-first -> ready batch -> batch-extraction`。

### Q9: 规则会不会过期？

会，所以 active 不是永久真理。后续如果代码和架构演进，新 evidence 可以追加为 draft 或 conflict，由 owner 决定是否更新 active。append-only 的价值就是让变化可追溯。

### Q10: 怎么衡量这个试点有没有价值？

不要只看生成了多少文档。更有价值的指标是：

- AI 生成代码的返工是否减少。
- Review 中重复解释的问题是否减少。
- 新人或跨模块开发时找规范的成本是否降低。
- draft 升级 active 的比例和质量是否可接受。
- forbidden evidence 是否真正拦截了高频问题。

## 11. 30 分钟收口稿

可以直接照读：

```text
最后我用三句话收口。

第一，AI 辅助开发要继续提升，关键不是让模型知道更多通用知识，而是让它理解我们团队真实的工程约束。

第二，project-standard-extractor 的稳定路径非常克制：先 profile-first，再选一个 ready batch，再生成 evidence-backed draft，最后由团队确认 active。

第三，这件事必须有核心研发参与。AI 可以整理事实，但只有我们能判断哪些代码代表推荐写法，哪些 draft 能成为团队承诺，哪些规则应该进入 AI 默认上下文。
```

然后给行动闭环：

```text
会后我们不追求一次全量覆盖。
先选一个大家认可的代表性模块，跑通一条闭环：

profile-first
  -> 选一个 ready batch
  -> 生成 draft + evidence + ai-rules + review-checklist
  -> owner 确认 active
  -> 用一次真实 AI 开发任务验证效果
```

最后一句：

```text
如果这条链路跑通，我们得到的不是一份文档，而是一套能持续喂给 AI、能支撑 Review、能随项目演进的团队工程上下文。
```

## 12. 会后行动

建议会后明确 7 天内的三个动作：

1. **第 1 天：选模块。** 由核心研发推荐 1 个代表性模块，说明为什么它代表当前推荐写法。
2. **第 2-3 天：跑萃取。** 使用稳定路径生成 profile、batch plan 和一个 batch 的 draft 产物。
3. **第 4-7 天：验证闭环。** owner 确认 1-3 条 active 规则，并在一次真实 AI 开发或 Review 中使用。

试点验收标准：

- 至少产出一个可审查的 `standard-{sub_domain}.md` draft。
- 每条候选规则能追溯到 evidence。
- 至少明确一条 `active` / `pending` / `conflict` 判断。
- 至少在一次 AI 开发任务中使用 active 规则。
- 收集一次 Reviewer 反馈：这条规则是否减少了重复解释。

可以发给团队的行动话术：

```text
这周先用 project-standard-extractor 跑一个代表性模块。
目标不是生成全量规范，而是验证一条链路：
真实代码 evidence -> draft 规则 -> owner 确认 -> active 规则进入 AI 编码和 Review。

请大家各自推荐一个“能代表当前推荐写法”的模块，并标注哪些代码只是历史兼容或反例。
```

## 13. 讲者备忘清单

上台前确认：

- 分享只讲稳定公开路径，不讲 repair-only 作为普通能力。
- `draft` 和 `active` 的边界要反复强调。
- 不承诺一键全仓生成正式规范。
- 准备一组已经生成好的 profile / batch-plan / standard / ai-rules / review-checklist 示例。
- 准备一个“代表性模块怎么选”的现场问题，引导核心研发参与。

现场最容易失焦的点和拉回话术：

| 失焦点 | 拉回话术 |
| --- | --- |
| 讨论模型能力强弱 | 今天重点不是模型强弱，而是团队上下文怎样资产化 |
| 追问全仓自动生成 | 稳定路径先保证可信，不做无边界全量自动发布 |
| 追问 Phase 2 / force-rebuild | 这是维护者或 repair 主题，今天只讲当前可稳定复用路径 |
| 把 draft 当规范 | draft 是候选，active 才是团队承诺 |
| 想让 AI 替代 Review | AI 整理事实，核心研发做规范判断 |
