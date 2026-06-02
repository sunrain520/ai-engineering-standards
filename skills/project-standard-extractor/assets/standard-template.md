---
doc_id: "{domain}-{sub_domain}-standard"
title: "{Sub-domain} 开发规范"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{batch_id}"
evidence_tier: "{direct-code|cross-project|single-project|inferred|none}"
last_reviewed: "{YYYY-MM-DD}"
tags:
  - "{domain}"
  - "{sub_domain}"
---

# {Sub-domain} 开发规范

<!-- 写作说明（生成时删除此注释）
目标：让新同事第一天接手就能看懂、能用。
结构：技术栈 → 分层图 → 各角色规则（说明/适用范围/强制/推荐/禁止 + 代码示例）→ AI 规则 → Review 检查项 → Evidence 参考
风格：开发者工作手册（Guide），不是规则注册表（Catalog）；对齐阿里《Java开发手册》：约束分级 + 说明(why) + 正例/反例 + 可二值检查
  - 每条规则 H2 后跟一行 inline 元数据 blockquote，**禁止**整块 yaml
  - 每条规则有「说明」段讲 why（对齐阿里「说明:」），不只讲 what
  - 代码示例内联，正例（脱敏泛化的通用示例，用 OrderService/UserRepository 等通用名，**不含项目路径**，守 BR-008）+ 反例（FORBIDDEN 必配）
  - 强制规则用 numbered list，禁止用 bullet
  - 节数由 evidence 决定，不够不要凑
	自动运行下规则可写 status: auto-active 或 draft：auto-active 只能由高置信闸产生；owner-confirmed-active 只能由负责人手工确认。
-->

## 1. 技术栈与工程约束

<!-- 从 build 脚本和 import 语句提取，只写团队真实在用的 -->

- {框架/库}：{一行说明用途}
- {框架/库}：{一行说明用途}

## 2. 分层职责

```text
{Layer A}
    ↓
{Layer B}
    ↓
{Layer C}
    ↓
{Infrastructure}
```

| 层级 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| {Layer A} | {职责} | {不能做的} |
| {Layer B} | {职责} | {不能做的} |
| {Layer C} | {职责} | {不能做的} |

## 3. {角色/层级 A} 规范

### P1 {规则标题}

> level: P1 · status: {auto-active|draft|pending-confirmation} · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: {YYYY-MM-DD} · recommended_action: {auto-activate|keep-draft|move-to-pending} · confidence_tier: {high|normal|low} · authority_scope: {this-repo|none} · upgrade_mode: {auto-active|none} · deterministic_occurrence_count: {N|null} · last_evidence_confirmed_run: {run_id|null}

**说明**

- {为什么需要这条规则：背后的原理、动机或它要防止的具体问题。对齐阿里手册「说明:」——讲清 why，让读者和 AI 不只知道做什么，还知道为什么，减少误用。基于 evidence 观察，不空泛。}

**适用范围**

- {该规则适用的文件、模块或场景}

**强制规则**

1. {规则，说明怎么做}
2. {规则}

**禁止事项**

- 禁止 {行为}

**正例**

```{language}
// 正例：{说明为什么正确}
{代码片段，基于真实 evidence，路径脱敏}
```

**反例**

```{language}
// 反例：{说明错误原因和改法}
{代码片段}
```

**AI 生成代码要求**

1. {正向约束}
2. {正向约束}

**Code Review 检查项**

- [ ] {可二值判断的检查项}

**Evidence**

- `evidence/code-facts.md「EV-{DOMAIN}-{N}」`
- `evidence/positive-examples.md「POS-{DOMAIN}-{N}」`

### FORBIDDEN {规则标题}

> level: FORBIDDEN · status: {auto-active|draft|pending-confirmation} · source_kind: extracted · evidence_tier: single-project · risk_tag: high · owner: TBD · last_reviewed: {YYYY-MM-DD} · recommended_action: {auto-activate|keep-draft|move-to-pending} · confidence_tier: {high|normal|low} · authority_scope: {this-repo|none} · upgrade_mode: {auto-active|none} · deterministic_occurrence_count: {N|null} · last_evidence_confirmed_run: {run_id|null}

> ⛔ **FORBIDDEN**：{具体禁止写法，一句话}。负例见 `evidence/forbidden-examples.md「NEG-{DOMAIN}-{N}」`

**说明**

- {为什么禁止：这个反范式会导致什么具体后果/风险。基于 evidence，讲清危害。}

**适用范围**

- {场景}

**禁止事项**

- 禁止 {具体反范式}

**反例**

```{language}
// 反例：{说明为何禁止}
{代码片段}
```

**AI 生成代码要求**

1. AI 不得生成 {该反范式}。

**Code Review 检查项**

- [ ] {pass/fail 判断}

**Evidence**

- `evidence/forbidden-examples.md「NEG-{DOMAIN}-{N}」`

## 4. {角色/层级 B} 规范

<!-- 重复 §3 结构，按 evidence 数量决定规则节数 -->

## {N}. 目录与命名规范

<!-- 如果 evidence 中有命名规范，写此节；否则删除 -->

```text
{module}/
├── {dir}/
│   ├── {ClassName}.{ext}    — {说明}
│   └── {ClassName}.{ext}    — {说明}
```

命名规则：

- {类型} 使用 {命名模式}，例如：`{示例}`

## {N+1}. AI 生成规则

> 本节是各规则节 `AI 生成代码要求` 的汇总视图，不新创内容；规则修改请改对应规则节。

AI 生成 {sub_domain} 代码时必须遵守：

1. {从规则节 AI 要求摘要而来}
2. {摘要}

禁止 AI 生成：

- {从规则节禁止事项摘要}
- {摘要}

## {N+2}. Code Review 检查项

> 本节是各规则节 `Code Review 检查项` 的汇总视图，不新创内容。

- [ ] {汇总检查项}
- [ ] {汇总检查项}

## Evidence 参考

| evidence_id | 来源文件（路径模式） | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-{DOMAIN}-{N}` | `{path-pattern}` | {一句话核心观察} | high / medium / low |
