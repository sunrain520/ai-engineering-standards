---
doc_id: "app-client-build-governance-standard"
title: "APP Build Governance 团队规范"
domain: "app-client"
sub_domain: "build-governance"
doc_type: "standard"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "build-governance"
  - "standard"
  - "ai-coding"
---

# APP Build Governance 团队规范

本文件从 `hszq-app` 的 Gradle 根工程、主应用模块、`hszq-version` 插件和多业务模块构建脚本萃取。规则只对本仓库当前证据范围内的 Android App 端生效；跨仓推广前需要补充第二项目 evidence。

## 技术栈

- Gradle Groovy 根工程，Android Gradle Plugin 8.11.0，Kotlin Gradle Plugin 2.2.0。
- 根工程通过 `includeBuild 'hszq-version'` 接入内部版本插件，并通过 `hszq.version.Deps` 管理内部基础库和业务库坐标。
- 主应用模块 `huasheng-stock` 统一承载应用插件、渠道、签名、buildTypes、AOP、埋点和主包依赖。
- 业务模块默认是 `com.android.library`，按模块引入 `Deps.Business.*`、`Deps.Lib.*` 或少量本地 `project()` 依赖。

## 分层图

```text
settings.gradle
  -> includeBuild hszq-version
  -> include only active local modules

build.gradle
  -> plugin versions / repositories / hszq-version plugin

hszq-version
  -> Deps.Lib / Deps.Business / forceList

huasheng-stock
  -> app plugin / buildTypes / flavors / signing / app dependency graph

feature modules
  -> com.android.library + app-common.gradle + Deps.*
```

## P1 依赖版本和强制依赖必须通过 hszq-version 集中治理

> level: P1 · status: auto-active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 6 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

`hszq-app` 的业务模块大量通过 `Deps.Business.*` 和 `Deps.Lib.*` 引用内部模块与基础库，版本插件中还提供 `Deps.modify()` 和 `forceList` 来覆盖 SNAPSHOT、强制统一底层库版本。若新增模块绕过 `hszq-version` 在业务 `build.gradle` 里直接写内部坐标，依赖版本会在主包、业务模块和本地调试之间分叉，排查冲突时无法从一个入口确认真实依赖来源。

### 适用范围

- 研发域：`app-client`
- 子领域：`build-governance`
- 适用场景：新增内部库依赖、升级业务模块版本、临时替换 SNAPSHOT、强制依赖收敛。

### 推荐做法

1. 内部基础库和业务库版本应优先声明在 `hszq-version` 的 `Deps.Lib` 或 `Deps.Business`。
2. 需要临时替换或强制统一的依赖应进入 `Deps.modify()` 或 `forceList`，并在变更说明中写明原因。
3. 业务模块 `build.gradle` 应引用 `Deps.*` 常量，不应重复硬编码同一内部坐标。

### 禁止做法

1. 禁止在多个业务模块中复制同一内部 Maven 坐标和版本号。
2. 禁止把临时 SNAPSHOT 替换散落在具体 feature 模块里。

### 正例

```gradle
dependencies {
    implementation Deps.Business.quotes_common
    implementation Deps.Lib.common
}
```

### 反例

```gradle
dependencies {
    implementation "com.hstong.temp:quotes-common:1.2.3-SNAPSHOT" // 禁止散落硬编码
}
```

### AI 生成代码要求

1. AI 新增内部依赖时，必须先检查 `hszq-version` 是否已有 `Deps.*` 常量。
2. AI 不得在业务模块中直接发明内部 Maven 坐标版本。
3. AI 修改 `forceList` 时，必须说明强制依赖的冲突来源和退出条件。

### Code Review 检查项

- [ ] 新增内部依赖来自 `Deps.Lib` 或 `Deps.Business`。
- [ ] 临时 SNAPSHOT 或强制依赖集中在 `hszq-version`，没有散落到 feature 模块。
- [ ] 变更说明写明依赖替换原因和后续收敛条件。

### Evidence

- `evidence/code-facts.md「EV-APP-1」`
- `evidence/code-facts.md「EV-APP-2」`
- `evidence/code-facts.md「EV-APP-3」`

## P1 本地模块激活必须只改 settings.gradle 的 include 边界

> level: P1 · status: auto-active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 4 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

当前根 `settings.gradle` 只激活 `huasheng-stock` 和 `hszq-version`，大量业务模块以注释形式保留。与此同时，主应用和 `app-core` 通过 `Deps.Business.*` 使用已发布模块。这个结构说明：默认构建以 Maven 产物为主，本地源码模块只在明确需要联调时加入。若新增本地调试时直接改业务依赖或让主包同时依赖 Maven 与本地工程，构建图会出现双来源，容易产生类重复、资源冲突和联调结果不可复现。

### 适用范围

- 本地模块联调、业务模块源码化、Maven 产物替换、Gradle sync 配置。

### 推荐做法

1. 需要本地源码参与构建时，应在根 `settings.gradle` 激活对应 `include`。
2. 本地模块激活后，应检查主包或聚合模块是否仍通过 `Deps.Business.*` 引入同名产物。
3. 联调结束后，应恢复默认 Maven 产物路径，避免长期扩大本地构建面。

### 禁止做法

1. 禁止在业务模块中用零散 `project()` 替换 Maven 坐标而不调整根 include 边界。
2. 禁止同一业务能力同时从本地工程和 Maven 产物进入主包。

### AI 生成代码要求

1. AI 需要启用本地模块时，必须修改根 `settings.gradle` 的 include 边界，并同步说明影响的模块。
2. AI 不得在 feature `build.gradle` 中临时硬改同名业务模块来源。

### Code Review 检查项

- [ ] 本地模块激活只通过根 `settings.gradle` 管理。
- [ ] 同名业务模块没有本地工程和 Maven 产物双来源。
- [ ] 联调变更包含恢复默认构建路径的说明。

### Evidence

- `evidence/code-facts.md「EV-APP-4」`
- `evidence/code-facts.md「EV-APP-5」`

## P2 应用级插件、渠道、签名和埋点只放在主应用模块

> level: P2 · status: auto-active · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: auto-activate · confidence_tier: high · authority_scope: this-repo · upgrade_mode: auto-active · deterministic_occurrence_count: 5 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

`huasheng-stock` 是唯一稳定应用壳，集中配置 `com.android.application`、AGConnect、Google Services、Sensors、Bonree、Android AOP、Manifest exported check、buildTypes、渠道和签名变量。业务模块则以 `com.android.library` 和 `app-common.gradle` 复用通用 Android 配置。把应用级插件下沉到 feature 会让 feature 编译语义接近小 App，导致渠道、签名、manifest 占位符和埋点配置分散，最终主包集成时难以判断哪个模块改动了产物行为。

### 适用范围

- 主应用模块、渠道构建、签名、埋点插件、AOP、Manifest 检查、业务 library 模块。

### 推荐做法

1. 应用级 Gradle 插件和产物语义配置应放在 `huasheng-stock`。
2. 业务模块保持 `com.android.library`，只通过公共脚本接收通用 Android 配置。
3. 新增影响 APK 产物的配置时，应先判断它属于主包语义还是库模块语义。

### 禁止做法

1. 禁止在普通业务模块里复制主应用的渠道、签名、埋点或 AOP 全局配置。
2. 禁止让 feature 模块通过构建脚本改变 release 主包语义。

### AI 生成代码要求

1. AI 新增渠道、签名、埋点、AOP 或 manifest 全局配置时，必须落在主应用模块或公共构建脚本。
2. AI 不得把 `com.android.application` 当作业务模块的默认插件。

### Code Review 检查项

- [ ] 业务模块仍是 `com.android.library`。
- [ ] 应用级插件和 release 语义没有被复制到 feature 模块。
- [ ] 新增构建配置明确说明影响主包还是库模块。

### Evidence

- `evidence/code-facts.md「EV-APP-6」`
- `evidence/code-facts.md「EV-APP-7」`
- `evidence/code-facts.md「EV-APP-8」`

## P1 发布签名和生产配置只能通过变量注入，不能写入规范或源码正文

> level: P1 · status: pending-confirmation · source_kind: extracted · evidence_tier: sanitized-existence · risk_tag: high · owner: TBD · last_reviewed: 2026-06-02 · recommended_action: move-to-pending · confidence_tier: low · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: 1 · last_evidence_confirmed_run: 20260602-193408-app-client

### 说明

主应用签名配置通过 `RELEASE_KEY_ALIAS`、`RELEASE_KEY_PASSWORD`、`RELEASE_STORE_FILE` 和 `RELEASE_STORE_PASSWORD` 变量引用，没有在已读取构建脚本中暴露明文值。该事实涉及发布安全边界，只能作为脱敏存在事实记录，不能自动升级为默认执行规则；负责人需要确认变量来源、CI 注入方式和本地配置边界后，才能决定是否发布为强制规范。

### 适用范围

- 发布签名、CI 变量、生产配置、渠道打包、敏感构建参数。

### 推荐做法

1. 发布签名和生产配置应使用变量或本地未入库配置注入。
2. 规范、README、示例代码和 AI 输出不得包含签名口令、store 文件真实路径或生产密钥。
3. 如需说明签名配置，只允许写变量名和脱敏存在事实。

### 禁止做法

1. 禁止把签名口令、生产 URL、token 或证书路径原值写入规范正文。
2. 禁止让 AI 通过读取敏感配置来补全构建说明。

### AI 生成代码要求

1. AI 遇到签名、证书、token 或生产配置时，只能记录脱敏存在事实。
2. AI 不得要求用户粘贴或提交敏感原值。

### Code Review 检查项

- [ ] 构建说明只出现变量名或脱敏事实，没有敏感原值。
- [ ] 发布签名配置来源经过负责人或 CI 维护者确认。

### Evidence

- `evidence/code-facts.md「EV-APP-9」`
