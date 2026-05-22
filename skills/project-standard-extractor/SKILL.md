---
name: project-standard-extractor
description: 从真实项目代码路径中萃取团队级研发规范，输出可直接复用的 Markdown 规范文档。给代码路径，自动分析并生成像 02-android-standard.md 这样的规范文档。
---

# Project Standard Extractor

当此 Skill 被调用时，立即执行以下步骤，不询问用户任何问题（除非路径不可读）。

---

## 执行步骤

### Step 1 — 解析输入

从用户消息中提取：
- `project_paths`：一个或多个本地项目路径（必填）
- `output_dir`：输出目录（可选，默认 `engineering-standards/{domain}/`）
- `domain`：研发域（可选，留空则自动推断）

路径不可读时停止并说明原因，其余情况直接继续。

---

### Step 2 — 扫描项目结构（轻量，≤3层）

只读以下内容，不读业务源码：
- 根目录 manifest（`package.json`、`pom.xml`、`build.gradle.kts`、`go.mod`、`Cargo.toml` 等）
- 顶层目录名
- `README.md` 前 30 行
- `.gitignore`（了解构建产物边界）

从扫描结果推断：
- `domain`（app-client / frontend / backend / pc-client / industry / testing / security）
- `sub_domain` 列表（android / kmp-shared / ios / react / java-spring / golang 等）
- 技术栈信号

---

### Step 3 — 为每个 sub_domain 读取代表性代码文件

按以下优先级选取文件（每个 sub_domain 读 15-25 个文件）：

| 优先级 | 说明 | 典型文件 |
| --- | --- | --- |
| P0 入口层 | 最顶层使用模式 | Fragment/ViewController/Controller/Page/Handler |
| P1 核心层 | 核心业务逻辑 | ViewModel/Reactor/Service/UseCase |
| P2 数据层 | 数据访问和契约 | Repository/Mapper/DTO/Store/Schema |
| P3 反例 | 已知反范式代码 | 任何明显违反架构的文件 |
| P4 配置 | 技术栈声明 | build.gradle/package.json/tsconfig |

各领域代表性文件参考：

| domain/sub_domain | P0 | P1 | P2 |
| --- | --- | --- | --- |
| app-client/android | Fragment, Activity | ViewModel, BaseVM | Repository, DTO, Mapper |
| app-client/kmp-shared | UseCase | Presenter, RepositoryImpl | DomainModel, Mapper |
| app-client/ios | ViewController | Reactor | State, Action |
| frontend/react | Page, Route | Component, Hook | Store, API Client, Type |
| backend/java-spring | Controller | Service | Repository, Mapper, DTO |
| backend/golang | Handler/Router | Service | Repository, Model |
| pc-client/electron | Main Process 入口 | IPC Handler | Preload, Renderer |

排除：`build/`、`dist/`、`node_modules/`、`Pods/`、`target/`、`.git/`、密钥/凭据文件。

---

### Step 4 — 分析代码，理解架构

读完代码后，在内部回答：

1. **这个 sub_domain 的分层结构是什么？** 有哪些角色，依赖方向如何？
2. **团队真实遵循的规律是什么？** 哪些模式在多个文件中重复出现？
3. **有哪些明显的反范式？** 哪些写法被避开或应该被禁止？
4. **技术栈是什么？** 用了哪些框架和库？

---

### Step 5 — 为每个 sub_domain 生成规范文档

按 `templates/standard-template.md` 的结构写 `standard-{sub_domain}.md`：

**文档结构**（参考 `02-android-standard.md`、`01-kmp-shared-layer-standard.md`）：

```
Front Matter（YAML，见模板）
# {Sub-domain} 开发规范
## 1. 技术栈与工程约束
## 2. 分层职责（ASCII图 + 责任矩阵表格）
## 3. {角色A} 规范（强制规则 / 推荐规则 / 禁止事项 / 正例代码 / 反例代码）
## 4. {角色B} 规范
...
## N. 目录与命名规范（如有 evidence）
## N+1. AI 生成规则
## N+2. Review 检查项
```

**写作要求**：
- 代码示例直接内联（正例+反例），基于真实读取的代码，路径脱敏
- 强制规则用 numbered list，禁止事项用 bullet
- 每条规则说明**怎么做**，不只是"应该"
- 节数由代码 evidence 决定，没有 evidence 的节不写
- 不写行业通用常识，只写团队代码中真实体现的规律

**Front Matter 状态**：`status: active`（直接可用）

---

### Step 6 — 生成 AI Rules 和 Review Checklist

从各 `standard-{sub_domain}.md` 的 AI 生成规则和 Review 检查项节汇总：

- `ai-rules.md`：所有 sub_domain 的 AI 约束汇总
- `review-checklist.md`：所有 sub_domain 的检查项汇总

格式参考 `10-app-ai-rules.md`、`11-code-review-checklist.md`。

---

### Step 7 — 输出完成摘要

列出：
- 生成的文件列表
- 每份文档覆盖的 sub_domain 和主要章节
- 没有足够 evidence 跳过的内容（如有）
- 建议用户补充的内容（如有）

---

## 强制边界

1. 规范正文不写具体项目路径，路径只用于读取代码，不出现在输出文档中。
2. 不读取密钥、token、生产凭据、`.env` 文件原值。
3. 没有代码 evidence 的规则不写进文档（写进摘要的"建议补充"）。
4. 输出文档 `status: draft`；`active` 只能由领域负责人确认后手动升级。
5. 不覆盖已有文档，已存在的 `standard-{sub_domain}.md` 追加缺失章节。

---

## 输出文件

写入 `output_dir`（默认 `engineering-standards/{domain}/`）：

- `standard-{sub_domain}.md` — 每个 sub_domain 一份完整规范
- `ai-rules.md` — AI 编码规则汇总
- `review-checklist.md` — Review 检查项汇总
