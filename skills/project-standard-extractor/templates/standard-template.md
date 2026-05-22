---
doc_id: "{domain}-{sub_domain}-standard"
title: "{Sub-domain} 开发规范"
domain: "{domain}"
sub_domain: "{sub_domain}"
doc_type: "standard"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
source_batch: "{batch_id}"
evidence_tier: "{direct-code|cross-project|single-project|inferred}"
last_reviewed: null
tags:
  - "{domain}"
  - "{sub_domain}"
  - "standard"
  - "ai-coding"
---

# {Sub-domain} 开发规范

> **draft** · evidence_tier: {tier} · source: `{batch_id}` · owner: TBD
> 本文件基于真实代码 evidence 萃取，未经领域负责人确认前不得作为强制执行依据。

<!-- ───────────────────────────────────────────────
 Generation Agent 使用说明（写入文档时删除此注释块）

 本模板适用于所有研发域。按 domain/sub_domain 替换章节名和示例：

 domain=app-client, sub_domain=android
   §2 分层：Activity/Fragment → ViewModel/BaseVM → UseCase → Repository → DataCenter
   角色节：UI层 / 状态层 / 业务层 / 数据访问层

 domain=app-client, sub_domain=kmp-shared
   §2 分层：Domain(UseCase/Repository接口) → Data(RepositoryImpl/Mapper/DTO) → Infra(网络/缓存/DB)
   角色节：UseCase / Repository / Mapper / Domain Model

 domain=app-client, sub_domain=ios
   §2 分层：ViewController → Reactor(Action/Mutation/State) → KMP UseCase → DataCenter
   角色节：ViewController / Reactor / State

 domain=frontend, sub_domain=react / vue / next
   §2 分层：Page/Route → Components → State/Store → API Client → Types
   角色节：Page / Component / Store / API Client

 domain=backend, sub_domain=java-spring / golang / python
   §2 分层：Controller → Service → Repository/Mapper → DTO → 外部系统
   角色节：Controller / Service / Repository / DTO / Error Handling

 domain=pc-client, sub_domain=electron
   §2 分层：Main Process → IPC(ipcMain/ipcRenderer) → Renderer → Local Storage
   角色节：主进程 / IPC契约 / Renderer

 domain=testing, sub_domain=unit / integration / e2e
   §2 分层：测试策略 → 单测 → 集成 → E2E → 覆盖率门禁
   角色节：Mock策略 / 测试命名 / 断言规范

 domain=security
   §2 分层：输入校验 → 认证/授权 → 数据脱敏 → 审计日志
   角色节：按安全控制点分节

 domain=industry (需 owner-confirmed)
   §2 分层：业务流程 → 风控校验 → 状态流转 → 合规记录
   角色节：按业务角色分节；无 owner 确认不得生成 FORBIDDEN 标注

 通用原则：
 - §3—§N 数量由 evidence 决定，不要凑节
 - 代码示例语言跟随 sub_domain（Kotlin/Swift/TypeScript/Java/Python/Go 等）
 - 没有代码 evidence 的章节不写或标记 pending
──────────────────────────────────────────────── -->

---

## 1. 技术栈与工程约束

> 填写该 sub_domain 实际使用的框架、库、模式和工程约束。对照代码 import 和 build 脚本，只写团队真实在用的。

- {框架/库名称}：{一行说明用途}
- {框架/库名称}：{一行说明用途}
- {构建/工具约束}：{一行说明}

---

## 2. 分层职责

> 画出该 sub_domain 的层级/角色关系。用 ASCII 图 + 责任矩阵表格。

```text
{Layer A / Role A}
    ↓
{Layer B / Role B}
    ↓
{Layer C / Role C}
    ↓
{Infrastructure}
```

| 层级 / 角色 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| {Layer A} | {职责描述} | {不能做的事} |
| {Layer B} | {职责描述} | {不能做的事} |
| {Layer C} | {职责描述} | {不能做的事} |

---

## 3. {Layer A / Role A} 规范

> 针对该层/角色写具体规则。每节结构：强制规则 → 推荐规则 → 禁止事项 → 正例代码 → 反例代码。

### 强制规则

1. {规则}
2. {规则}
3. {规则}

### 推荐规则

1. {规则}
2. {规则}

### 禁止事项

- 禁止 {行为}，原因：{简短说明}
- 禁止 {行为}，原因：{简短说明}

> ⛔ **FORBIDDEN（有直接负例 evidence）**：{具体禁止写法}。见 `evidence/forbidden-examples.md「NEG-{DOMAIN}-{N}」`

### 正例

```{language}
// 正例：{说明为什么正确}
{代码片段，基于真实 evidence，路径脱敏}
```

### 反例

```{language}
// 反例：{说明为什么错误，应该怎么改}
{代码片段，基于真实 evidence，路径脱敏}
```

---

## 4. {Layer B / Role B} 规范

### 强制规则

1. {规则}
2. {规则}

### 推荐规则

1. {规则}

### 禁止事项

- 禁止 {行为}

### 正例

```{language}
// 正例：{说明}
```

### 反例

```{language}
// 反例：{说明}
```

---

## {N}. {根据 sub_domain 继续增加角色/层级节，数量不限}

> 规则不够不要凑。没有 evidence 的角色/层级留到下次 batch 补充。

---

## {N+1}. 目录与命名规范

> 如果 evidence 中有命名规范或目录结构，在这里写。否则删除本节。

```text
{module-name}/
├── {directory}/
│   ├── {ClassName}.{ext}      — {说明}
│   └── {ClassName}.{ext}      — {说明}
└── {directory}/
```

命名规则：

- {类型} 使用 {命名模式}，例如：`{示例}`
- {类型} 使用 {命名模式}，例如：`{示例}`

---

## {N+2}. AI 生成代码规则

> AI 生成或修改本 sub_domain 代码时必须遵守的约束。用 numbered list，每条必须可验证。

AI 生成代码前必须判断：

1. 当前需求属于哪个层级/角色（参考§2 分层职责）
2. {sub_domain 特有的判断点，例如：是否已有可复用的 UseCase/Repository/组件}
3. {判断点}

必须遵守：

1. {约束，对应§3-N 的强制规则}
2. {约束}
3. {约束}

禁止生成：

- {禁止行为，对应§3-N 的禁止事项}
- {禁止行为}
- {禁止行为}

---

## {N+3}. Code Review 检查项

> 按维度分组，每条必须可 pass/fail 判断。reviewer 看代码就能得出结论，不依赖口头解释。

### 架构合规

- {检查项}
- {检查项}

### {Layer A / Role A} 合规

- {检查项}
- {检查项}

### {Layer B / Role B} 合规

- {检查项}
- {检查项}

### AI 生成代码专项

- AI 生成的代码是否先输出了层级归属判断
- AI 生成的代码是否复用了已有 {UseCase/Repository/组件 等}
- AI 生成的代码是否符合本文档§{N+2}的约束
- AI 生成的代码是否包含禁止事项

---

## Evidence 参考

> 本文件规则基于以下代码 evidence，详情见 `evidence/` 目录。无 evidence 的候选规则在 `pending-confirmation.md`。

| evidence_id | 来源文件（路径模式） | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| EV-{DOMAIN}-{N} | `{path-pattern}` | {一行观察} | high/medium/low |
| POS-{DOMAIN}-{N} | `{path-pattern}` | {正例说明} | high/medium/low |
| NEG-{DOMAIN}-{N} | `{path-pattern}` | {反例说明} | high/medium/low |
