---
doc_id: "app-client-build-dependency-standard-archived"
title: "APP 构建与依赖治理规范（已归档）"
domain: "app-client"
sub_domain: "build-governance"
doc_type: "standard"
version: "v0.1.0"
status: "archived"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
superseded_by: "standard-build-governance.md"
tags:
  - "app-client"
  - "build-governance"
  - "archived"
---

> ⚠️ **本文件已归档**：内容由 `standard-build-governance.md` 取代（采用 inline 元数据 + Developer Guide 风格）。本文件保留只为历史回溯。

# APP 构建与依赖治理规范

> 当前文档是 APP 构建与依赖治理的编号入口。已有 `standard-build-governance.md` 提供单项目 evidence-backed draft 增量，升级 active 前仍需负责人确认。

## 1. 适用范围

本规范覆盖 Gradle、KMP build、Android/iOS 依赖、插件版本、本地替换、构建提速、模块依赖收敛和 contract 轻量化治理。

当前已有 evidence-backed 萃取产物：`standard-build-governance.md`。本文件作为编号入口，后续应把构建治理规则逐步收敛到本维度下。

## 2. 萃取时应关注的 evidence

| 维度 | 候选代码信号 |
| --- | --- |
| 根工程治理 | `settings.gradle`、`settings.gradle.kts`、dependency substitution、included build |
| 插件与版本 | root `build.gradle`、version catalog、内部版本插件 |
| 模块依赖 | feature/core/contract build.gradle、KMP module dependencies |
| 本地提速 | debug gate、skip tasks、local build flags、CI branch |
| 依赖风险 | UI 依赖进入 contract、重复依赖、重型 SDK、动态版本 |

## 3. 应沉淀的规则内容

1. 本地工程替换、included build 和版本插件必须集中治理，不能散落在业务模块。
2. `contract` 模块必须保持依赖轻量，不能引入 UI、页面框架或业务实现依赖。
3. 新增 SDK 或重型依赖必须说明用途、初始化时机、包体/启动影响和替代方案。
4. 本地提速策略必须可关闭、可区分 CI，并不能绕过发布质量门禁。
5. KMP 依赖应保持 source set 边界清晰，commonMain 不依赖平台 UI。

## 4. AI 生成代码要求

1. AI 修改构建文件前必须判断修改属于根治理、模块依赖还是本地调试。
2. AI 不得在业务模块临时硬编码版本、仓库地址或 Maven 替换。
3. AI 新增依赖必须输出影响范围和是否进入 contract/KMP commonMain。

## 5. Code Review 检查项

- [ ] 构建治理是否集中在根工程或约定插件。
- [ ] 新增依赖是否破坏模块边界。
- [ ] contract 是否保持轻量。
- [ ] 本地提速是否不会影响 CI/发布。
- [ ] KMP source set 依赖是否符合平台边界。
