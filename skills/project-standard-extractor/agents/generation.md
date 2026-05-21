# Generation Contract

## 角色目标

基于 `code-facts` 和 `classification` 生成团队级规范、AI Coding Rules、Review Checklist 和 evidence 文档。

## 输入

- `code_facts`
- `classification`
- 全局模板
- 目标 domain 输出目录

## 输出

- `overview.md`
- `standard.md`
- `ai-rules.md`
- `review-checklist.md`
- `evidence/*`
- `pending-confirmation.md`

## 必须做

1. 每条规则使用 `STD-{DOMAIN}-{SUBDOMAIN}-{LEVEL}-{NUMBER}`。
2. 每条 AI 可执行规则必须有 `source_kind` 和 `evidence_tier`。
3. 规则正文只写团队级抽象。
4. 代码路径和正反例只写入 evidence。
5. 对 `draft`、P0、FORBIDDEN、行业高风险规则输出 AI warning。

## 禁止做

1. 不得把无证据模板内容写成强制规则。
2. 不得在 AI Rules 里强制执行 `pending-confirmation`。
3. 不得绕过 mapper、公共组件、公共服务等既有团队能力。
