---
doc_id: "app-client-build-governance-standard"
title: "APP Build Governance 团队规范"
domain: "app-client"
sub_domain: "build-governance"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "build-governance"
  - "standard"
  - "ai-coding"
---

# APP Build Governance 团队规范

本文件从 `kaz-mvp` 的 Gradle versioning / local fast build batch 萃取，当前为单项目 evidence-backed `draft`。跨项目推广或升级为 `active` 前，需要 APP 构建治理负责人确认。

## 技术栈

- Gradle Groovy 根工程 + Kotlin DSL KMP 子工程。
- Android Gradle Plugin 8.11.0、Kotlin 2.2.0、Java/Kotlin target 17。
- `includeBuild 'hszq-version'` 提供内部版本插件。
- 根工程使用 dependency substitution 支持本地模块替换 Maven 产物。

## 分层图

```text
settings.gradle
  -> dependencySubstitution / includeBuild
build.gradle
  -> plugin versions / repositories / local fast build gate
hszq-version
  -> com.hstong.base.hszq-version plugin
app / feature / core modules
```

## P1 本地工程替换必须集中在根 settings 治理

```yaml
status: draft
level: P1
source_kind: extracted
evidence_tier: single-project
risk_tag: medium
owner: TBD
last_reviewed: "2026-05-22"
recommended_action: keep-draft
conflicts_with: []
superseded_by: null
```

### 适用范围

- 本地联调、Maven 产物替换、included build、跨模块依赖调试。

### 推荐做法

1. 本地调试需要替换 Maven 产物时，应在根 `settings.gradle` 的 dependency substitution 中集中配置。
2. 替换规则应以 `findProject` 等存在性判断保护，避免缺少本地工程时破坏构建。
3. 内部版本插件应通过 included build 或明确插件坐标接入，避免在业务模块散落版本常量。

### AI 生成代码要求

1. AI 新增本地替换规则时，必须放在根 settings 的统一治理区域。
2. AI 不得在业务模块 build.gradle 中临时硬编码 Maven 坐标替换。

### Code Review 检查项

- [ ] 本地替换规则集中、可关闭，并带存在性判断。
- [ ] 新增 included build 有明确插件或模块边界说明。

### Evidence

- `evidence/code-facts.md「EV-APP-20」`
- `evidence/code-facts.md「EV-APP-22」`

## P2 快速构建开关只能跳过校验任务，不能改变产物语义

```yaml
status: draft
level: P2
source_kind: extracted
evidence_tier: single-project
risk_tag: medium
owner: TBD
last_reviewed: "2026-05-22"
recommended_action: keep-draft
conflicts_with: []
superseded_by: null
```

### 适用范围

- 本地快速构建、lint/test/check/androidTest/jacoco/kover 任务治理。

### 推荐做法

1. 快速构建开关只应用于本地提速场景，默认关闭。
2. 允许跳过 lint、test、check、androidTest、connected、jacoco、kover 等校验任务。
3. 不得通过快速构建开关改变源码、资源、依赖解析或 release 产物语义。
4. CI 或发布路径应显式关闭快速构建开关。

### AI 生成代码要求

1. AI 新增构建提速能力时，必须说明影响的任务类型。
2. AI 不得把快速构建开关用于跳过打包必需任务或改变 release 行为。

### Code Review 检查项

- [ ] 快速构建开关默认关闭。
- [ ] 被跳过任务只属于校验类任务。
- [ ] 发布路径没有依赖快速构建开关。

### Evidence

- `evidence/code-facts.md「EV-APP-21」`

## AI 规则

- 本地 Maven 产物替换统一写在根 settings。
- 新增 included build 或内部插件时必须说明职责边界。
- 快速构建开关只跳过校验任务，不改变产物语义。

## Review 检查项

- [ ] 本地替换规则有存在性保护。
- [ ] 快速构建开关默认关闭且不影响 release 产物语义。
- [ ] 构建脚本没有复制敏感凭据原值。
