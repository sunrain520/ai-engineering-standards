# AI 辅助研发工程规范用户手册

## 1. 手册目标

本文面向第一次使用 `AI Engineering Standards` 的研发、Reviewer、架构师和 AI 辅助研发使用者，解释这个仓库能解决什么问题、应该从哪里开始、如何使用 `project-standard-extractor` 萃取规范，以及如何消费输出产物。

本手册不替代技术方案。技术方案用于解释系统如何设计；本手册只回答实际使用问题：

- 我应该看哪些入口。
- 我需要准备哪些输入。
- 如何从真实项目生成规范草案。
- 产物分别给谁使用。
- 哪些内容可以进入 AI 默认上下文。
- 哪些内容必须等待负责人确认。

## 2. 产品定位

`AI Engineering Standards` 是部门级研发工程规范仓库。它不是通用编码规范合集，也不是单个项目的代码说明书，而是一套把团队真实代码经验转化为工程标准的资产体系。

它的核心交付包括：

| 资产 | 作用 |
| --- | --- |
| `engineering-standards/` | 按研发域沉淀团队规范、AI Rules、Review Checklist 和 evidence |
| `skills/project-standard-extractor/` | 从真实项目代码萃取团队规范的 Skill 源包 |
| `docs/01-版本路线/` | 产品背景、定位和演进方向 |
| `docs/02-技术方案/` | 第一阶段技术方案、Skill 建设方案和质量要求 |
| `docs/03-用户手册/` | 面向使用者的操作说明 |

第一阶段重点是 `project-standard-extractor`：从真实项目代码中提取代码事实，再生成团队级规范草案、AI Coding Rules、Review Checklist、evidence、待确认项、合并建议和冲突记录。

## 3. 适用角色

| 角色 | 典型用途 |
| --- | --- |
| 研发人员 | 查询团队推荐写法、禁止写法、目录和分层约束 |
| 新人 | 快速理解项目结构、模块边界和常见历史坑 |
| AI 使用者 | 把 AI Rules、Review Checklist 和相关规范作为 AI 编码上下文 |
| Reviewer | 使用 Review Checklist 统一检查标准 |
| 领域负责人 | 审核 `draft` / `pending-confirmation`，决定是否升级为 `active` |
| 规范维护者 | 执行规范萃取、合并候选产物、维护 changelog 和索引候选 |

## 4. 第一次使用从哪里开始

优先阅读以下入口：

| 目标 | 入口 |
| --- | --- |
| 了解仓库整体结构 | 根目录 `README.md` |
| 了解规范资产 | `engineering-standards/README.md` |
| 了解 Skill 怎么用 | `skills/project-standard-extractor/usage-guide.md` |
| 执行规范萃取 | `skills/project-standard-extractor/SKILL.md` |
| 查看完整阶段流程 | `skills/project-standard-extractor/workflow.md` |
| 查看输入项含义 | `skills/project-standard-extractor/input-guide.md` |
| 查看输出位置 | `skills/project-standard-extractor/config/output-targets.md` |
| 了解状态门禁 | `engineering-standards/00-global/rule-lifecycle.md` |

如果只是使用现有规范，不需要执行萃取，直接从 `engineering-standards/README.md` 进入对应研发域即可。

如果要从真实项目沉淀新规范，从 `skills/project-standard-extractor/usage-guide.md` 开始。

## 5. 使用前准备

执行规范萃取前，需要准备：

| 输入 | 是否必需 | 说明 |
| --- | --- | --- |
| `project_paths` | 必需 | 一个或多个真实项目路径，可以是仓库根、模块目录或服务目录 |
| `extraction_mode` | 可选 | 未提供时由 Skill 推断，广范围输入默认 `profile-first` |
| 研发域 | 可选 | APP、PC、Frontend、Backend、Industry、Cross-domain |
| 行业场景 | 可选 | none、securities、credit、banking、payment、insurance、other |
| 输出范围 | 可选 | 默认由萃取模式决定 |
| 子领域 / 技术栈 | 可选 | 如 KMP、Android、iOS、Frontend components、Backend API |
| 业务模块 | 可选 | 如交易、行情、用户、账户、订单、风控 |
| 已有规范或文档 | 可选 | 用于避免重复生成和识别冲突 |
| 质量关注点 | 可选 | 如架构分层、安全合规、测试、AI 生成质量 |

写入前需要确认：

```text
我确认这些路径可用于规范萃取；完整或大范围输入先进入 profile-first；正式萃取只处理选定 batch；敏感配置只允许脱敏记录；生成结果只能作为 draft 或 pending-confirmation，active 需要负责人确认。
```

## 6. 安装与测试 Skill

当前第一阶段 `project-standard-extractor` 是 Skill source package，不是自动注册的 CLI。安装的核心动作是复制整个 `skills/project-standard-extractor/` 目录，或在本仓库直接引用执行。

### 6.1 本仓库直接测试

不需要安装。在本仓库的 AI 会话里输入：

```text
读取 skills/project-standard-extractor/SKILL.md，
按 workflow.md 执行一次 dry run。
请先读取 examples/golden-sample-run.md 和 examples/thin-dogfood-run.md，
说明 intake → project-profile → extraction-map → batch-plan → selected-batch facts → classification → generation → review → merge
每阶段会产生什么产物，以及真实运行还需要哪些输入。
```

这适合验证 Skill 入口、阶段流程和边界，不会扫描真实业务项目。

### 6.2 安装到 Claude Code

```bash
cp -r /Users/kuang/xiaobu/ai-engineering-standards/skills/project-standard-extractor ~/.claude/skills/
```

复制后新开或重载 Claude Code 会话，输入：

```text
用 project-standard-extractor 萃取规范。
project_paths:
  - <你的项目路径>
extraction_mode: profile-first
```

必须复制整个 `project-standard-extractor/` 目录，不能只复制 `SKILL.md`，否则 `config/`、`agents/`、`templates/`、`prompts/` 的相对引用会断。

### 6.3 安装到 Codex

```bash
mkdir -p ~/.codex/skills
cp -r /Users/kuang/xiaobu/ai-engineering-standards/skills/project-standard-extractor ~/.codex/skills/
```

然后在 Codex 会话里输入：

```text
使用 project-standard-extractor。
project_paths:
  - <你的项目路径>
extraction_mode: profile-first
```

其他宿主也按同样原则处理：复制整个目录，并保持内部相对路径不变。

### 6.4 推荐测试流程

先做 dry run，不给真实项目路径：

```text
读取 skills/project-standard-extractor/examples/golden-sample-run.md，
按 project-standard-extractor 的 SKILL.md 检查这个样例是否符合工作流边界。
只输出每阶段输入、输出、停止条件和不会做什么。
```

再用一个真实项目做 `profile-first`：

```yaml
project_paths:
  - /path/to/target-repo
extraction_mode: profile-first
output_scope: profile only + extraction map only + batch plan only
```

期望结果：只生成或说明 `project-profile`、`extraction-map`、`batch-plan`，不能直接生成 `standard-{sub_domain}.md`。

最后选择一个 batch 做正式萃取：

```yaml
project_paths:
  - /path/to/target-repo
extraction_mode: batch-extraction
selected_batch:
  batch_id: <batch-plan 里的 batch_id>
  source_batch_plan: <batch-plan 文档路径>
```

期望结果：只读取该 batch 的代表性文件，先输出 `code-facts`，再生成 `draft` 规则、AI Rules、Review Checklist、evidence 和候选索引产物。

### 6.5 测试通过标准

一次测试至少确认：

- `SKILL.md` 能作为唯一入口被识别。
- 完整仓库输入会进入 `profile-first`，不会直接生成正式规则。
- 正式萃取必须选择一个 batch。
- 规则能追溯到 `code-facts` 或负责人确认。
- 不读取密钥、token、私钥、生产凭据原值。
- 不覆盖已有 `active` 或 `draft`。
- 输出规则默认是 `draft`，不会自动发布为 `active`。
- 候选 `rules-index` / `llms` / `ai-context-pack` 不会默认覆盖正式文件。

## 7. 规范萃取的推荐流程

### 7.1 完整项目或多服务输入

当输入是完整仓库、完整项目、多服务、多端或未知研发域时，必须先运行 `profile-first`。

可直接在本仓库的 AI 会话中输入：

```text
读取 skills/project-standard-extractor/SKILL.md，按 workflow.md 执行萃取。
project_paths:
  - <项目1的本地路径>
  - <项目2的本地路径>
extraction_mode: profile-first
```

`profile-first` 只输出：

- `{run_id}-project-profile.md`
- `{run_id}-extraction-map.md`
- `{run_id}-batch-plan.md`
- 代表性文件候选
- 需要确认的问题

它不会生成正式规范规则。

### 7.2 选择一个 batch 后正式萃取

拿到 batch plan 后，从中选择一个 batch，再启动 `batch-extraction`：

```yaml
project_paths:
  - <项目路径>
extraction_mode: batch-extraction
selected_batch:
  batch_id: <来自 batch-plan 的 batch_id>
  source_batch_plan: <batch-plan 文档路径>
```

一次正式萃取只能处理一个 batch。需要处理多个 batch 时，分多次运行。

### 7.3 已经是小模块范围

如果输入已经是明确的小模块，可以使用 `focused-module`：

```yaml
project_paths:
  - <模块路径>
extraction_mode: focused-module
domain: Backend
sub_domain: API
module: order
```

即使是 `focused-module`，仍然必须保留 evidence 边界、敏感文件处理和质量门禁。

### 7.4 只评审或只合并

已有萃取产物时，可使用：

| 模式 | 用途 |
| --- | --- |
| `review-only` | 只评审规则、evidence 和候选索引，不新增规则 |
| `merge-only` | 只对已确认候选做 append-only 合并 |

## 8. 产物怎么读

`project-standard-extractor` 默认写入 `engineering-standards/<domain>/`。

| 产物 | 读者 | 用途 |
| --- | --- | --- |
| `overview.md` | 所有人 | 对该研发域规范做总览 |
| `{run_id}-project-profile.md` | 规范维护者 | 记录项目画像、候选模块和敏感边界 |
| `{run_id}-extraction-map.md` | 规范维护者 | 展示可萃取区域和证据候选 |
| `{run_id}-batch-plan.md` | 规范维护者 | 选择正式萃取 batch |
| `standard-{sub_domain}.md` | 研发 / AI / Reviewer | 团队级规范主文档 |
| `standard-common.md` | 研发 / AI / Reviewer | 跨子领域共性规则 |
| `ai-rules.md` | AI 使用者 | 可复制给 AI 的执行规则视图 |
| `review-checklist.md` | Reviewer | 代码评审检查项 |
| `evidence/code-facts.md` | 维护者 / Reviewer | 代码事实和推导边界 |
| `evidence/positive-examples.md` | 研发 / AI | 推荐写法证据 |
| `evidence/forbidden-examples.md` | 研发 / AI / Reviewer | 禁止写法证据 |
| `evidence/legacy-compatible.md` | 研发 / Reviewer | 历史兼容写法说明 |
| `pending-confirmation.md` | 领域负责人 | 证据不足或需要确认的候选 |
| `merge-suggestions.md` | 规范维护者 | 相近规则合并建议 |
| `conflicts.md` | 领域负责人 | 规则或事实冲突 |
| `{run_id}-rules-index-candidate.json` | 规范维护者 | 规则索引候选 |
| `{run_id}-llms-candidate.txt` | 规范维护者 | AI 入口地图候选 |
| `{run_id}-ai-context-pack.md` | AI 使用者 / 维护者 | 运行级 AI 上下文候选 |

## 9. 如何用于 AI 编码和 Review

### 9.1 给 AI 编码使用

推荐输入顺序：

1. 当前需求或任务说明。
2. 对应研发域的 `overview.md`。
3. 对应 `standard-{sub_domain}.md` 或 `standard-common.md`。
4. `ai-rules.md`。
5. 与本次任务相关的 `review-checklist.md` 条目。
6. 必要时补充 `evidence/positive-examples.md` 或 `evidence/forbidden-examples.md`。

只允许把 `active` 规则作为默认强约束。`draft` 可以作为建议使用，但需要提示 AI 不得把它当成最终规范。`pending-confirmation` 只能作为待确认背景，不应进入默认执行路径。

### 9.2 给 Code Review 使用

Reviewer 应优先查看：

1. 本次变更所属研发域和子领域的 `standard-{sub_domain}.md`。
2. `review-checklist.md`。
3. 与争议点相关的 evidence。
4. `conflicts.md` 和 `pending-confirmation.md` 中是否存在未解决事项。

评审结论应引用规则标题二元组：

```text
{source_doc}「{section_title}」
```

不要引用 Rule ID 或 HTML anchor；第一阶段不使用这两类定位方式。

## 10. 状态和发布边界

规则状态必须区分：

| 状态 | 含义 | 是否可默认给 AI 执行 |
| --- | --- | --- |
| `active` | 领域负责人确认后的正式规则 | 可以 |
| `draft` | 有 evidence 支撑但尚未确认 | 谨慎使用，必须标注 |
| `pending-confirmation` | 证据不足或需要负责人判断 | 不可以 |
| `conflict` | 与现有规则或事实冲突 | 不可以 |
| `legacy-compatible` | 仅解释历史兼容写法 | 不作为新代码推荐 |

`project-standard-extractor` 不能自动把规则发布为 `active`。升级 `active` 必须由领域负责人确认。

## 11. 不能做什么

第一阶段明确不做：

- 不自动安装到 Codex、Claude Code 或其他宿主 runtime。
- 不注册 CLI。
- 不写 CI。
- 不自动发布正式 `.index/rules-index.json` 或根 `llms.txt`。
- 不从完整仓库直接生成正式规则。
- 不一次处理多个 batch。
- 不覆盖已有 `active` 或 `draft`。
- 不读取或复制密钥、token、私钥、生产凭据原值。
- 不把行业通用最佳实践直接写成团队规则。
- 不修改业务代码。

## 12. 常见问题

### 12.1 只给一个项目根目录可以开始吗

可以，但会默认进入 `profile-first`。这一步只生成项目画像、extraction map 和 batch plan，不生成正式规范规则。

### 12.2 为什么不能直接从完整仓库生成规则

完整仓库里通常混有推荐写法、历史兼容、临时方案和反例。直接生成规则容易把历史包袱标准化。必须先通过 project profile 和 batch plan 压缩范围，再选择一个 batch 提取代表性 evidence。

### 12.3 没有负责人确认能不能给 AI 用

只能谨慎使用 `draft`，并明确告诉 AI 这是候选规则。`pending-confirmation` 和 `conflict` 不应进入 AI 默认执行路径。

### 12.4 候选索引文件能不能直接覆盖正式索引

不能。`rules-index-candidate.json`、`llms-candidate.txt`、`ai-context-pack.md` 默认都是候选产物。发布正式 `.index/rules-index.json` 或根 `llms.txt` 需要用户明确确认。

### 12.5 发现已有规则相近怎么办

不要覆盖旧规则。把相近项写入 `merge-suggestions.md`，由维护者或负责人决定是否合并。

### 12.6 发现新事实和旧规则冲突怎么办

写入 `conflicts.md`，不要自动覆盖旧规则，也不要把冲突规则发布给 AI 默认执行。

### 12.7 规则标题应该怎么引用

使用 `{source_doc}「{section_title}」` 二元组。规则 H2 标题必须以 `P0 / P1 / P2 / FORBIDDEN ` 开头，并与索引里的 `section_title` 字面一致。

## 13. 一次有效运行的完成标准

一次规范萃取完成后，应能回答：

- 本次 `extraction_mode` 是什么。
- 是否选定了唯一 batch。
- 读取了哪些代表性 evidence。
- 排除了哪些路径和敏感文件。
- 新增或候选规则在哪里。
- 每条规则能否追溯到 `code-facts` 或负责人确认。
- Quality Gate 给出的状态建议是什么。
- 是否产生 `pending-confirmation` 或 `conflicts`。
- 候选索引产物是否仍是 candidate。
- 哪些事项需要负责人确认。

如果这些问题无法回答，本次运行不应视为完成。

## 14. 推荐使用话术

### 14.1 生成项目画像和 batch plan

```text
读取 skills/project-standard-extractor/SKILL.md，按 workflow.md 执行 profile-first。
project_paths:
  - <项目路径>
domain: <可选>
industry: <可选>
output_scope: profile only + extraction map only + batch plan only
```

### 14.2 选择 batch 正式萃取

```text
继续使用 project-standard-extractor 执行 batch-extraction。
selected_batch:
  batch_id: <batch_id>
  source_batch_plan: <batch-plan 路径>
请只读取该 batch 的 candidate_files 和必要邻近文件，先输出 code-facts，再生成 draft 规则、AI Rules、Review Checklist、evidence 和候选索引产物。
```

### 14.3 让 AI 根据规范开发

```text
请基于以下规范完成开发，并在输出中说明对应的自检结果：
1. <domain>/overview.md
2. <domain>/standard-<sub_domain>.md
3. <domain>/ai-rules.md
4. <domain>/review-checklist.md

只把 active 规则作为强约束；draft 规则仅作为候选建议；pending-confirmation 和 conflict 不得作为执行依据。
```

### 14.4 做代码评审

```text
请按 <domain>/review-checklist.md 和相关 standard 文档审查当前 diff。
发现问题时使用 {source_doc}「{section_title}」引用规则。
如果规则处于 draft、pending-confirmation 或 conflict，请在结论中标注状态，不要当作已发布强约束。
```

## 15. 维护要求

维护规范资产时必须遵守：

- 每次 source 变更同步更新根目录 `CHANGELOG.md`。
- 用户可见变更追加 `(user-visible)`。
- 新 Markdown 规范产物必须使用 `engineering-standards-md-v1` Front Matter。
- 规则不得使用 Rule ID 或 HTML anchor。
- 规则正文不得写真实项目路径；真实路径只放在 evidence。
- 所有合并动作必须 append-only。
- `active` 升级必须有人类负责人确认。
