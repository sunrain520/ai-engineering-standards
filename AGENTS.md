<!-- spec-first:lang:start -->
## 语言与治理策略

**语言设置：** `Chinese / 中文`

- 默认用中文生成回复、状态更新、澄清、生成文档、需求/计划/任务、评审、总结、变更说明和 commit/PR 文案；用户明确要求翻译、双语或其他语言时例外。
- 输入、工具输出或引用材料可保留原文；新生成的说明和结论仍按语言设置输出。
- 代码标识符、命令、路径、配置键、环境变量、API/协议名保持原文；常见英文技术术语可混用。
- 新增代码注释使用中文，只说明非显然意图。

### Changelog
- 任何项目 source 新增/删除/修改都必须同步更新根目录 `CHANGELOG.md`；记录格式以仓库现行为准。
- `作者` 读全局 developer profile `~/.spec-first/.developer`；取不到时回退 git 提交身份或留空，不阻断变更。
- 用户可见变更追加 `(user-visible)`；缺少 changelog 记录时拒绝生成 source 变更。
<!-- spec-first:lang:end -->

<!-- spec-first:bootstrap:start -->
## Workflow 入口治理

- 本 block 是 using-spec-first 的最小入口锚点(随会话启动注入,启动即在场);完整路由表、边界细节和例外仍在 `skills/using-spec-first/SKILL.md`
- **何时进入 workflow**:substantial work（需要工程闭环的非平凡/有风险编辑、启动 implementation/debug/review/plan/setup/update/optimization/知识沉淀、运行改状态命令、架构/prompt/workflow/contract 决策、durable knowledge 增删）前先判断是否进入公开 spec-first workflow
- **何时直接做**:轻量事实问答、当前上下文解释、窄定位查询（where is X used）、当前对话/用户给定单文档整理、明确单点低风险小改动可直接回答、bounded read 或正常执行;小改动仍遵守 CHANGELOG、最窄验证和 source/runtime 边界;workflow-first 不等于 brainstorming-first
- **何时不重新分流**:已在公开 workflow 内（按其 SKILL 继续,仅在用户改目标/显式 handoff/明显越界时重路由）或作为 bounded subagent/worker 被派遣（完成 bounded 任务即可,不重启路由)
- **如何路由**:意图优先于关键词与主题域;用户显式调用当前 host 公开 workflow 时优先尊重;否则只选一个入口并说明一个理由,不默认进入 `spec-brainstorm`,不自动串联多个 workflow
- **常见入口锚点**:setup/runtime→`$spec-mcp-setup` 或终端 `spec-first update`;失败→`$spec-debug`;评审→`$spec-code-review`/`$spec-doc-review`;定义→`$spec-ideate`/`$spec-brainstorm`/`$spec-prd`;优化→`$spec-optimize`;计划/执行→`$spec-plan`/`$spec-work`;知识→`$spec-compound`/`$spec-compound-refresh`;完整 map 查 SKILL
- 用户可见输出语言以本文件的 `spec-first:lang` managed block 为准；skill/agent/template 原文语言和当前会话惯性不得覆盖该策略，除非用户明确要求其他语言
- 父级多仓 workspace：写入、修复、测试、review autofix 或 commit 前必须有明确 `target_repo` / per-child scope；只读定位也应使用 bounded direct reads 并说明目标 repo 假设
- Runtime context 默认排除 `.spec-first/audits/**`、`.spec-first/governance/**` 和 generated mirrors（`.claude/**`、`.codex/**`、`.agents/skills/**`）;只有 setup/update/runtime-drift/audit/governance-health 等明确运行时任务按需读取
- 架构/prompt/workflow/contract 或 source/runtime 判断前按需读取 `docs/10-prompt/结构化项目角色契约.md`;scripts/tools 只产 deterministic facts,LLM 做语义路由判断
- **反合理化红旗**(出现这些念头即停):「先改个文件就好」→ 明确小改动可直接做;规模/风险不明、根因未定或触及架构/contract/多文件时先路由;「只是个快速架构/prompt 改动」→ 架构/prompt/workflow/contract 改动算 substantial;「得先看一堆文件再决定」→ 只做最小事实核查,已清晰则直接路由;「该评审但我口头答就行」→ 评审目标具体时用 code-review/doc-review;「helper skill 存在所以该暴露」→ 只有公开 workflow 是用户入口,internal helper 隐藏
- Codex workflow 入口使用 `$spec-*`
- 不要把 `using-spec-first` 写成 `/spec:*` 或 command-backed workflow；不要直接暴露 internal-only skills,例如 `git-worktree`
- Codex：进入公开 `$spec-*` 前可 best-effort 运行 `spec-first startup-reminder --codex`；失败/空输出不阻塞，只提示在终端运行 `spec-first update`，bounded subagents、leaf reviewers、worker agents 不运行
- Codex：公开 `$spec-*` 调用只授权 workflow 本身，不自动授权 `spawn_agent`；例如 `$spec-doc-review` 缺少 subagents/personas/delegated/parallel 明示授权时走 documented fallback 并记录 `dispatch_authorization_missing`，需要多 persona/subagent review 时请在请求中明说 `subagents`/`personas`
<!-- spec-first:bootstrap:end -->
