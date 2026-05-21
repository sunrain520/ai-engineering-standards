# 安装与使用边界

## 1. 第一阶段边界

第一阶段交付 `project-standard-extractor` 的 source package。它可以被用户复制到 AI 宿主、作为上下文引用，或由 agent 按 `SKILL.md` 手动执行。

第一阶段不做：

- 自动安装到 `.agents/skills/`、`.codex/skills/`、`.claude/skills/`。
- 自动同步 runtime mirror。
- 自动注册 CLI。
- 自动写 CI。
- 自动发布规则为 `active`。

## 2. 推荐使用方式

在当前规范仓库中使用：

```text
读取 skills/project-standard-extractor/SKILL.md
按 input-guide.md 补齐输入
按 workflow.md 顺序执行
使用 templates/ 写入目标目录
使用 quality-gate.md 做状态建议
```

在其他 AI 宿主中使用：

1. 复制整个 `project-standard-extractor/` 目录。
2. 将 `SKILL.md` 注册为宿主支持的 Skill 或作为系统上下文引用。
3. 保持 `config/`、`agents/`、`templates/`、`prompts/` 相对路径不变。
4. 每次运行前读取目标仓库的 `AGENTS.md`、`README.md`、已有规范目录和 changelog 要求。

## 3. 验收方式

第一阶段是否可用，不靠安装命令证明，而靠：

- `examples/golden-sample-run.md`
- `examples/thin-dogfood-run.md`
- `examples/consistency-checklist.md`

这三类文档证明 Skill 能从入口跑到输出，并且不会绕过 evidence、覆盖已有规则或泄露敏感信息。
