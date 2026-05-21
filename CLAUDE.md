<!-- spec-first:lang:start -->
## 语言与治理策略

**语言设置：** `Chinese / 中文`

- 默认用中文生成回复、状态更新、澄清、生成文档、需求/计划/任务、评审、总结、变更说明和 commit/PR 文案；用户明确要求翻译、双语或其他语言时例外。
- 输入、工具输出或引用材料可保留原文；新生成的说明和结论仍按语言设置输出。
- 代码标识符、命令、路径、配置键、环境变量、API/协议名保持原文；常见英文技术术语可混用。
- 新增代码注释使用中文，只说明非显然意图。

### Changelog
- 任何项目 source 新增、删除或修改，都必须同步更新根目录 `CHANGELOG.md`；记录格式以仓库现行格式为准。
- `作者` 使用当前 host developer profile：Codex 读 `.codex/spec-first/.developer`，Claude 读 `.claude/spec-first/.developer`；缺失时先运行 `spec-first init --codex|--claude -u <name> --lang <zh|en>`。
- 用户可见变更追加 `(user-visible)`；缺少对应记录时，拒绝生成 source 变更。
<!-- spec-first:lang:end -->

<!-- spec-first:bootstrap:start -->
## Workflow 入口治理

- 本 block 只做轻量 workflow entry context router；完整路由策略在 `skills/using-spec-first/SKILL.md`
- substantial work 前先判断是否进入公开 spec-first workflow；轻量问答和窄事实查询可直接回答；已在 workflow 或 bounded subagent 中时不重新分流
- 按当前意图选择一个入口；不要默认进入 `spec-brainstorm`，不要自动串联多个 workflow；用户询问下一步时，用 `using-spec-first` guide mode 推荐一个入口、一个理由、一个动作
- 父级多仓 workspace：只读代码问题可用 `workspace-graph-targets.v1` advisory facts；写入、修复、测试、review autofix 或 commit 前必须有明确 `target_repo` / per-child scope
- Runtime context 默认排除 `.spec-first/audits/**` 和 generated mirrors（`.claude/**`、`.codex/**`、`.agents/skills/**`）；只有 setup/update/runtime-drift/audit 等明确运行时任务按需读取
- Claude workflow 入口使用 `/spec:*`
- 不要把 `using-spec-first` 本身当作 command-backed workflow；不要直接暴露 internal-only skills，例如 `git-worktree`
- 常见入口锚点：环境/MCP→`/spec:mcp-setup`；graph readiness→`/spec:graph-bootstrap`；项目规范/胶水→`/spec:standards`；更新/runtime 修复→`/spec:update`；bug/失败→`/spec:debug`；代码/文档评审→`/spec:code-review`/`/spec:doc-review`；需求/计划/任务/执行→`/spec:brainstorm`/`/spec:plan`/`spec-write-tasks`/`/spec:work`；可度量优化→`/spec:optimize`
<!-- spec-first:bootstrap:end -->

<!-- spec-first:coding-guidelines:start -->
## 编码执行准则

### 1. 编码前思考

**不要假设。不要隐藏困惑。呈现权衡。**

LLM 经常默默选择一种解释然后执行。这个原则强制明确推理：

- 明确说明假设：如果不确定，询问而不是猜测。
- 呈现多种解释：当存在歧义时，不要默默选择。
- 适时提出异议：如果存在更简单的方法，说出来。
- 困惑时停下来：指出不清楚的地方并要求澄清。

### 2. 简洁优先

**用最少的代码解决问题。不要过度推测。**

对抗过度工程的倾向：

- 不要添加要求之外的功能。
- 不要为一次性代码创建抽象。
- 不要添加未要求的“灵活性”或“可配置性”。
- 不要为不可能发生的场景做错误处理。
- 如果 200 行代码可以写成 50 行，重写它。

检验标准：资深工程师会觉得这过于复杂吗？如果是，简化。

### 3. 精准修改

**只碰必须碰的。只清理自己造成的混乱。**

编辑已有代码时：
- 不要“改进”相邻的代码、注释或格式。
- 不要重构没坏的东西。
- 匹配现有风格，即使你更倾向于不同的写法。
- 如果注意到无关的死代码，提一下，不要删除它。

当你的改动产生孤儿代码时：
- 删除因你的改动而变得无用的导入 / 变量 / 函数。
- 不要删除预先存在的死代码，除非被要求。

检验标准：每一行修改都应该能直接追溯到用户的请求。

### 4. 目标驱动执行

**定义成功标准。循环直到验证通过。**

将指令式任务转化为可验证的目标：

- “添加验证” → “为无效输入编写测试，然后让它们通过”
- “修复 bug” → “编写重现 bug 的测试，然后让它通过”
- “重构 X” → “确保重构前后测试都能通过”

对于多步骤任务，说明一个简短的计划：
```
1. [步骤] → 验证: [检查]
2. [步骤] → 验证: [检查]
3. [步骤] → 验证: [检查]
```

强有力的成功标准让 LLM 能够独立循环执行。弱标准（“让它工作”）需要不断澄清。

### 5. 工具参数卫生

使用文件读取工具时，optional 参数不适用就省略：

- 读取 Markdown、文本、源码或配置文件时，不要传 PDF/page 分页参数。
- 不确定的 optional 参数不要传空字符串、空数组或占位值。
- 宿主文件读取工具读取文本文件时，只传文件路径和必要的范围参数；`pages` 等分页参数只用于真实 PDF/分页文档且不能是 `""`。
<!-- spec-first:coding-guidelines:end -->
