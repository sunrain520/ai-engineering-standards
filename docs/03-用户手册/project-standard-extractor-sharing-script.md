# project-standard-extractor 30 分钟团队分享稿

## 1. 分享定位

**主题：** 把真实代码变成 AI 可复用的团队规范：`project-standard-extractor` 的使用路径、设计取舍和共建机制。

**听众：** 部门核心研发人员。大家已经重度使用 AI 辅助开发，关心的是：怎样让 AI 更懂团队代码、怎样降低 Review 反复解释成本、怎样把项目经验变成可复用上下文。

**建议时长：** 30 分钟。

**分享目标：**

1. 会用：知道什么时候用 `project-standard-extractor`，以及稳定路径怎么跑。
2. 会判断：知道哪些产物能进 AI 默认上下文，哪些必须先 owner 确认。
3. 会共建：明确核心研发如何提供代表性模块、确认 draft、沉淀 active 规则。

## 2. 30 分钟结构

| 时间 | 模块 | 重点 |
| --- | --- | --- |
| 0-3 分钟 | 开场：AI 开发真正缺什么 | 不是缺模型，而是缺团队上下文 |
| 3-7 分钟 | Skill 定位 | 从真实代码萃取 evidence-backed draft，不是生成通用最佳实践 |
| 7-15 分钟 | 稳定使用路径 | `profile-first -> 选一个 ready batch -> batch-extraction` |
| 15-20 分钟 | 产物如何进入 AI / Review | `standard`、`ai-rules`、`review-checklist`、evidence、pending/conflict |
| 20-25 分钟 | 关键设计取舍 | profile-first、单 batch、draft-only、append-only、repair-only 边界 |
| 25-28 分钟 | 核心研发怎么共建 | 提供代表性模块、判断规则有效性、确认 active |
| 28-30 分钟 | 收口和试点行动 | 选一个模块跑通闭环 |

如果现场时间紧，优先保留 7-25 分钟内容；开场和 Q&A 可以压缩。

## 3. 开场稿：从 AI 开发痛点切入

大家现在都在重度使用 AI 辅助开发。我们遇到的问题通常不是“AI 不会写代码”，而是它不懂我们团队的真实上下文。

AI 经常会写出三类代码：

- 看起来符合行业最佳实践，但不符合我们项目结构。
- 单文件里能跑，但破坏了团队已有分层、命名、依赖和 Review 习惯。
- 参考了项目里的历史代码，却分不清哪些是推荐写法、哪些是历史兼容或反例。

所以真正稀缺的不是再写一份通用规范，而是把真实代码里的团队经验整理成 AI 可消费、Reviewer 可执行、负责人可确认的规范资产。

`project-standard-extractor` 要解决的就是这个问题：从真实项目 evidence 里生成团队规范草案，再通过 owner 确认变成 active 规则，最终进入 AI 编码和 Review 的默认上下文。

今天我不把它当一个“文档生成工具”来讲，而是把它当作一条规范资产生产线来讲。

## 4. 一句话定位

`project-standard-extractor` 是一个从真实项目代码中萃取团队级研发规范的 Skill。

它的稳定产出不是直接发布的最终规范，而是：

- evidence-backed draft standard
- AI Coding Rules
- Review Checklist
- code facts / positive / forbidden / legacy evidence
- pending-confirmation
- merge-suggestions
- conflicts
- 候选索引产物

它不是：

- 代码评审工具
- 业务代码修改工具
- 通用最佳实践生成器
- 一键全仓生成正式规范的工具
- 自动发布 active 规则的工具

这句话非常关键：**它生成 draft，团队确认后才可能变成 active。**

## 5. 稳定使用路径

当前公开稳定路径只有两步。

```text
Step 1: profile-first
  输入 project_paths
  输出 project-profile / extraction-map / batch-plan
  停止，等待选择 batch

Step 2: batch-extraction
  输入 project_paths + selected_batch.batch_id
  只读取这个 batch 的 evidence
  输出 draft standard / ai-rules / review-checklist / evidence / pending / conflicts
```

### 5.1 第一步：profile-first

当输入是完整仓库、完整项目、多服务、多端，或者范围还不清楚时，必须先跑 `profile-first`。

```yaml
project_paths:
  - /path/to/project
extraction_mode: profile-first
```

这一步只做轻量画像，输出：

| 产物 | 作用 |
| --- | --- |
| `temp/{run_id}-project-profile.md` | 项目画像、技术栈、候选模块、敏感边界 |
| `temp/{run_id}-extraction-map.md` | 哪些区域可萃取、对应哪些 evidence 信号 |
| `temp/{run_id}-batch-plan.md` | 可以正式萃取的 batch 列表 |

强调一下：这一步不会生成正式规范规则。

### 5.2 第二步：选择一个 ready batch

拿到 batch plan 后，我们只选一个 `ready` batch 继续。

```yaml
project_paths:
  - /path/to/project
extraction_mode: batch-extraction
selected_batch:
  batch_id: <batch-plan 里的 ready batch id>
```

为什么一次只跑一个 batch？

因为完整仓库里混着推荐写法、历史兼容、临时方案和反例。一次读太宽，AI 很容易把历史包袱标准化。单 batch 的好处是 evidence 边界清楚，后续 Review 也能判断这条规则到底从哪里来。

### 5.3 batch-extraction 产物

选定 batch 后，Skill 会做三件事：

1. 整理 `code-facts` 和分类：recommended / forbidden / legacy / pending / conflict。
2. 生成 `standard-{sub_domain}.md`、`ai-rules.md`、`review-checklist.md`。
3. 把证据不足、相近规则和冲突分别写入 `pending-confirmation.md`、`merge-suggestions.md`、`conflicts.md`。

稳定路径里的生成 profile 是：

```text
generation_profile: phase1-selected-batch
```

这意味着它不读取 `dimension-activator`，不要求 `activation-report`，也不会启动 Phase 2 repair-only 管道。

## 6. 产物如何服务 AI 开发

对重度 AI 使用者来说，产物可以分成三层。

### 6.1 第一层：给 AI 的直接上下文

| 产物 | 用法 |
| --- | --- |
| `standard-{sub_domain}.md` | 告诉 AI 当前子领域的团队结构、分层职责、推荐和禁止写法 |
| `ai-rules.md` | 给 AI 的可执行约束视图 |
| `review-checklist.md` | 让 AI 先按 Review 规则自检 |

推荐给 AI 的提示方式：

```text
请基于以下规范完成开发：
1. <domain>/standard-<sub_domain>.md
2. <domain>/ai-rules.md
3. <domain>/review-checklist.md

只把 active 规则作为强约束；
draft 规则仅作为候选建议；
pending-confirmation 和 conflict 不得作为执行依据。
```

### 6.2 第二层：给 Reviewer 的判断依据

| 产物 | 用法 |
| --- | --- |
| `evidence/code-facts.md` | 看规则是否真有代码事实支撑 |
| `evidence/positive-examples.md` | 看推荐写法来自哪里 |
| `evidence/forbidden-examples.md` | 看反例和风险 |
| `review-summary.md` | 看本次萃取有哪些风险和待确认项 |

Reviewer 不需要相信 AI 的结论，只需要沿着 evidence 链路判断规则是否成立。

### 6.3 第三层：不能进默认上下文的内容

| 状态 / 产物 | 边界 |
| --- | --- |
| `draft` | 可作候选建议，但不能当团队强制规则 |
| `pending-confirmation` | 需要 owner 判断，不进 AI 默认执行路径 |
| `conflict` | 与已有规则冲突，不进 AI 默认执行路径 |
| `legacy-compatible` | 解释历史兼容，不作为新代码推荐 |
| `rules-index-candidate.json` / `llms-candidate.txt` | 候选索引，不能覆盖正式索引 |

这套边界解决一个核心问题：AI 可以更懂团队，但不能越过团队确认机制。

## 7. 关键设计取舍

### 7.1 profile-first：先判断范围，再写规则

我们不允许完整仓库直接出规则。原因是核心研发最清楚：项目里的“存在”不等于“推荐”。很多历史代码能跑，但不代表新代码应该照抄。

`profile-first` 的价值是先把项目拆成可评估的 batch，让人决定哪个 batch 真的有代表性。

### 7.2 单 batch：保证 evidence 边界可审查

单 batch 是为了控制上下文污染。

如果一次读完整项目，生成出来的规范很难回答：

- 这条规则来自哪个模块？
- 它是不是推荐写法？
- 有没有把历史兼容当成新规范？
- Reviewer 怎么复核？

单 batch 可以让每条规则都能回到具体 evidence。

### 7.3 draft-only：AI 不替团队做承诺

AI 可以帮助整理事实，但不能替团队做规范承诺。

所以自动输出默认是 `draft`。只有 owner 确认后，规则才能升级为 `active`，进入 AI 和 Review 的默认强约束。

### 7.4 append-only：不覆盖已有规范

新萃取不会覆盖已有 active / draft。

它只会：

- 追加 evidence
- 追加 draft
- 写 merge suggestions
- 写 conflicts

这保证规范演进是可追溯的。

### 7.5 repair-only：高风险能力不放到公开入口

Phase 2 `dimension-activator`、cross-project、EA-Doc、securities PoC，以及 `force-rebuild` / `restore` / `pin` / `unpin` / `list`，当前都是 `blocked / repair-only` 或 maintainer-only。

普通使用者记住一句话就够了：

```text
稳定路径 = profile-first -> 选一个 ready batch -> batch-extraction
```

## 8. 核心研发怎么参与共建

这场分享的听众不是普通使用者，而是部门核心研发。我们参与共建的价值不只是“会用”，而是帮助它产出可信规范。

### 8.1 提供代表性模块

核心研发最知道哪些模块代表团队当前推荐写法。

试点时我们需要大家帮忙判断：

- 哪些模块适合做第一批 batch。
- 哪些模块只是历史兼容，不适合直接萃取。
- 哪些反例值得沉淀成 forbidden evidence。

### 8.2 判断 draft 是否能升级 active

Skill 生成 draft 后，核心研发需要看三件事：

- 规则是不是团队级抽象，而不是单项目说明。
- 规则是不是足够明确，AI 能执行，Reviewer 能检查。
- evidence 是否足够支撑这条规则。

### 8.3 把规范反馈进 AI 工作流

确认后的 active 规则应该进入两个地方：

- AI 编码提示：作为默认强约束。
- Code Review：作为检查项和引用依据。

目标不是多一批文档，而是让 AI 的输出质量和 Review 的一致性都变好。

## 9. 现场演示建议

30 分钟分享不建议现场跑真实大仓，时间不可控。建议做 dry run 或展示已有样例。

### 9.1 演示脚本

```text
读取 skills/project-standard-extractor/SKILL.md，
按 references/workflow.md 做一次 dry run。
请先读取 references/examples/golden-sample-run.md，
说明每阶段输入、输出、停止条件和不会做什么。
```

### 9.2 演示重点

演示时只强调五件事：

1. 完整仓库输入先 `profile-first`。
2. `profile-first` 只产出 profile / extraction-map / batch-plan。
3. 选一个 ready batch 后才生成 draft。
4. draft 不能直接当 active。
5. pending / conflict 不能进入 AI 默认执行路径。

## 10. 常见问题预案

### Q1: 我们能不能直接从一个成熟项目生成完整规范？

不能作为稳定路径这么做。成熟项目里也有历史包袱和局部妥协。先 `profile-first`，再选代表性 batch，规范质量会更高。

### Q2: draft 能不能先给 AI 用？

可以作为候选建议，但提示里必须说清楚：draft 不是强制规则。默认强约束只使用 active。

### Q3: AI rules 和 standard 有什么区别？

`standard-{sub_domain}.md` 是完整开发指南，给人和 AI 都能读。`ai-rules.md` 是从 standard 派生出的 AI 执行约束，不新增独立规则。

### Q4: 如果 generated draft 和已有 active 冲突怎么办？

写入 `conflicts.md`，不覆盖旧规则。owner 决定保留旧规则、采纳新规则，或者合并改写。

### Q5: Phase 2 维度框架什么时候能用？

等 repair 验证通过。当前不能把它当普通稳定能力使用。现在对团队最有价值的是先把 Phase 1 稳定链路跑通。

## 11. 30 分钟收口稿

最后我用三句话收口。

第一，AI 辅助开发要继续提升，核心不是让模型知道更多行业常识，而是让它知道我们团队真实的工程约束。

第二，`project-standard-extractor` 的稳定路径很克制：先画像，再选一个 batch，再生成 evidence-backed draft，最后由团队确认 active。

第三，这件事需要核心研发参与。我们要一起决定哪些代码代表团队推荐写法，哪些 draft 可以进入 active，哪些规则应该进入 AI 默认上下文。

会后我建议我们先选一个代表性模块试点，不追求一次全量覆盖，只追求跑通闭环：

```text
profile-first
  -> 选一个 ready batch
  -> 生成 draft + evidence + ai-rules + review-checklist
  -> owner 确认
  -> active 规则进入 AI / Review 默认上下文
```

## 12. 会后行动

建议会后明确三个动作：

1. 选一个大家认可的代表性模块。
2. 指定一个 owner 负责确认 draft。
3. 用一次真实 AI 开发任务验证：active 规则是否能减少返工和 Review 沟通。

可以发给团队的行动话术：

```text
这周先用 project-standard-extractor 跑一个代表性模块。
目标不是生成全量规范，而是验证一条链路：
真实代码 evidence -> draft 规则 -> owner 确认 -> active 规则进入 AI 编码和 Review。
```

