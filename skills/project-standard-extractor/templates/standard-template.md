---
doc_id: "{domain}-{sub_domain}-standard"
title: "{Sub-domain} 开发规范"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "standard"
version: "v0.1.0"
status: "active"
owner: "TBD"
source_batch: "{batch_id}"
evidence_tier: "{direct-code|cross-project|single-project}"
last_reviewed: "{YYYY-MM-DD}"
tags:
  - "{domain}"
  - "{sub_domain}"
---

# {Sub-domain} 开发规范

<!-- 写作说明（生成时删除此注释）
目标：让新同事第一天接手就能看懂、能用。
结构：技术栈 → 分层图 → 各角色规则（强制/推荐/禁止+代码示例）→ AI规则 → Review检查项
风格：参考 02-android-standard.md、01-kmp-shared-layer-standard.md
     - 纯 Markdown，无额外 YAML 块
     - 代码示例内联，正例+反例并排
     - 强制规则用 numbered list，禁止用 bullet
     - 节数由 evidence 决定，不够不要凑
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

强制规则：

1. {规则}
2. {规则}

推荐规则：

1. {规则}

禁止事项：

- 禁止 {行为}
- 禁止 {行为}

正例：

```{language}
// 正例：{说明为什么正确}
{代码片段，基于真实 evidence，路径脱敏}
```

反例：

```{language}
// 反例：{说明错误原因和改法}
{代码片段}
```

## 4. {角色/层级 B} 规范

强制规则：

1. {规则}

推荐规则：

1. {规则}

禁止事项：

- 禁止 {行为}

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

AI 生成 {sub_domain} 代码时必须遵守：

1. {约束，对应上方强制规则}
2. {约束}
3. {约束}

禁止 AI 生成：

- {禁止行为}
- {禁止行为}

## {N+2}. Review 检查项

- {检查项，reviewer 看代码即可判断 pass/fail}
- {检查项}
- {检查项}
