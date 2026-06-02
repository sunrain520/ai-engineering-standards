---
doc_id: "app-client-android-standard"
title: "Android 开发规范（KMP × Clean Architecture 平台壳）"
domain: "app-client"
sub_domain: "android"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags:
  - "app-client"
  - "android"
  - "kmp-platform"
  - "clean-architecture"
---

# Android 开发规范（KMP × Clean Architecture 平台壳）

<!-- 写作说明（生成时删除）
- 本骨架在 sub-domain-skeleton 12 节基础上嵌入 Android 平台壳 + Clean Architecture 接入内容
- App 端整体架构 = KMP（commonMain 共享 Domain/Data/Presentation） × Clean（依赖方向 Presentation→Domain←Data）
- Android 子域只承担 Clean 中的"Presentation 平台壳"+"Data 层 actual 实现"，Domain 完整下沉到 KMP shared
- §4 / §6 必须涵盖：Compose vs XML 选型、Hilt/Dagger 提供 Clean 装配、ProGuard/R8 规则、AndroidManifest 权限治理
-->

## 1. 规范定位 [{{activation_state_section_1}}]

{{positioning_text}}

- 子领域：`android`
- 架构组合：作为 KMP 平台壳承载 Clean Architecture 的 Presentation 平台层 + Data 层 actual 桥接
- 平台壳职责：UI 渲染、平台 Permission、系统服务、Hilt 装配、KMP 共享层 actual 实现
- 激活态：`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载（Android 模块）**

- **Presentation 平台壳**：Compose / Fragment 视图、Android `ViewModel`（`androidx.lifecycle.ViewModel`，委托给 KMP 共享 `Common*ViewModel`）
- **Data 层 actual 实现**：Room / DataStore / SharedPreferences / EncryptedSharedPreferences、Android 网络框架适配、Keystore Bridge
- Activity / Fragment 生命周期治理与导航（Navigation Component / Compose Navigation）
- Hilt / Dagger 依赖注入：将 KMP shared 的 UseCase / Repository 装配进 Android Activity / ViewModel 作用域
- 平台 Permission、Notification、WorkManager 后台任务
- ProGuard / R8 keep 规则

**不应承载**

- 跨端业务逻辑（必须放 KMP `commonMain/domain/`）
- 网络协议解析（由 KMP shared 的 Data 层承担）
- 跨端 UseCase / Entity 重新定义（直接 import shared 模块）

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
app/                                — Android 平台壳模块
├── src/main/
│   ├── kotlin/
│   │   ├── ui/                     — Presentation 平台壳
│   │   │   ├── screen/             — Compose Screen（按特性切分）
│   │   │   ├── component/          — 通用 Compose 组件
│   │   │   └── viewmodel/          — Android*ViewModel（委托 Common*ViewModel）
│   │   ├── di/                     — Hilt Module（装配 KMP UseCase / Repository）
│   │   │   ├── DomainModule.kt     — 提供 UseCase
│   │   │   ├── DataModule.kt       — 提供 Repository / DataSource
│   │   │   └── PlatformModule.kt   — Android 专属 Bridge / Storage
│   │   ├── navigation/             — Navigation Graph
│   │   └── platform/               — KMP shared 的 androidMain actual 桥接
│   ├── res/
│   ├── AndroidManifest.xml
│   └── proguard-rules.pro
└── build.gradle.kts                — implementation(project(":shared"))
```

## 4. 分层规则 [{{activation_state_section_4}}]

**Clean × Android 平台壳映射**

| Clean 层 | Android 模块归属 | 主要类型 | 禁止事项 |
| --- | --- | --- | --- |
| Presentation（平台壳） | `app/ui/` | Composable Screen、Android*ViewModel | 持有 Activity / View 引用、直接调用 Repository |
| Presentation（共享） | KMP `commonMain/presentation/` | Common*ViewModel | 在 Android 模块中重新实现 |
| Domain | KMP `commonMain/domain/` | UseCase / Entity / Repository interface | 在 Android 模块中重新实现 |
| Data（接口实现） | KMP `commonMain/data/` | RepositoryImpl / Mapper | 在 Android 模块中重新实现 |
| Data（actual） | `app/platform/` 或 KMP `androidMain/` | Room / DataStore / Keystore Bridge | 包含业务逻辑 |
| DI 装配 | `app/di/` | Hilt Module | 在 ViewModel 中手动 new 依赖 |

**Compose vs XML 选型**

- 新模块默认 Jetpack Compose；XML 仅在与历史 View 复用、AndroidView 互操作时使用。
- 共用主题/样式从 Compose Material3 + Theme 派生，**禁止** 同屏混用 XML Theme + Compose MaterialTheme。

**Hilt / Dagger 装配 Clean Architecture**

- Activity / Fragment 使用 `@AndroidEntryPoint`，ViewModel 使用 `@HiltViewModel`。
- `DomainModule` `@Provides` 提供 UseCase（依赖 Repository 接口）。
- `DataModule` `@Provides` 将 KMP `RepositoryImpl` 绑定到 `domain.Repository` 接口。
- `PlatformModule` `@Provides` 提供 Android actual 实现（Room、DataStore、Keystore）。
- 网络 / DataStore / 数据库的 Module 必须 `@InstallIn(SingletonComponent::class)`。
- **禁止** 在 ViewModel 构造函数中接收 `Activity` / `Context` 类型的非应用级 Context。

**Android*ViewModel 与 Common*ViewModel 关系**

```text
Android*ViewModel (androidx.lifecycle.ViewModel)
    └─ 持有 Common*ViewModel (KMP commonMain/presentation/)
       └─ 调用 UseCase (KMP commonMain/domain/)
          └─ 调用 Repository (KMP commonMain/domain/repository/)
             └─ 由 Hilt 注入 RepositoryImpl (KMP commonMain/data/)
```

## 5. 命名规范 [{{activation_state_section_5}}]

- Composable 函数 PascalCase 且首字母大写：`UserProfileScreen`
- Android ViewModel：`Android*ViewModel`（如 `AndroidLoginViewModel`），与 KMP shared `CommonLoginViewModel` 一一对应
- Repository / UseCase 命名沿用 KMP shared 约定（`*Repository` 接口、`*RepositoryImpl` 实现、`*UseCase`）
- Hilt Module `*Module`；Qualifier `*Qualifier`
- Bridge 类后缀 `*Bridge` / `*Adapter`（如 `AndroidKeystoreBridge`）

## 6. 核心规则 [{{activation_state_section_6}}]

### P0 业务逻辑必须落在 KMP shared，不在 Android 模块复刻

> level: P0 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**适用范围**

- `app/src/main/**`

**强制规则**

1. UseCase / Entity / Repository interface 全部位于 KMP shared `commonMain/domain/`，Android 模块仅 import 与装配。
2. 业务校验、状态机、领域计算 **禁止** 在 Android `ViewModel` / Composable 中实现，必须委托 UseCase。
3. Android `ViewModel` 仅做：生命周期适配、KMP `Common*ViewModel` 委托、Compose State 暴露。

**禁止事项**

- 禁止在 Android 模块新建 `domain/` 包重新定义 Entity / UseCase。
- 禁止在 Composable / Fragment 中写 if-else 业务分支决策，应放 UseCase。

**反例**

```kotlin
// 反例：在 Android Composable 中写业务校验
@Composable
fun LoginScreen() {
    if (username.length < 6 || !password.matches(PASSWORD_REGEX)) { // ❌ 业务校验应在 UseCase
        // ...
    }
}
```

### P1 ViewModel 不持有 View / Activity 引用

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**强制规则**

1. ViewModel 仅依赖 application-scoped Context 或纯领域接口（UseCase）。
2. UI 状态通过 `StateFlow` / `SharedFlow` 暴露，Composable 通过 `collectAsStateWithLifecycle` 订阅。
3. Android `ViewModel` 注入 KMP `Common*ViewModel` 或 UseCase，**禁止** 注入 RepositoryImpl 具体类型。

**禁止事项**

- 禁止在 ViewModel 构造函数注入 Activity / Fragment Context。
- 禁止 ViewModel 直接 import KMP `data.*` 包内类型。

### P1 Hilt 装配必须按 Clean 三层组织

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**强制规则**

1. `app/di/` 至少拆分 `DomainModule` / `DataModule` / `PlatformModule` 三个 Hilt Module。
2. `DataModule` 用 `@Binds` 将 `RepositoryImpl` 绑定到 `Repository` 接口。
3. `PlatformModule` 提供 Room / DataStore / Keystore 等 Android 原生依赖。

**正例**

```kotlin
@Module
@InstallIn(SingletonComponent::class)
abstract class DataModule {
    @Binds abstract fun bindAuthRepository(impl: AuthRepositoryImpl): AuthRepository
}

@Module
@InstallIn(SingletonComponent::class)
object DomainModule {
    @Provides fun provideLoginUseCase(repo: AuthRepository) = LoginUseCase(repo)
}
```

### FORBIDDEN ProGuard 关闭混淆

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ **FORBIDDEN**：Release build `minifyEnabled false` 或 `proguard-rules.pro` 中 `-dontobfuscate` 全量保留。

**反例**

```kotlin
android {
    buildTypes {
        release {
            isMinifyEnabled = false // ❌ release 必须开启 R8/ProGuard
        }
    }
}
```

### FORBIDDEN Android 模块直接 import KMP data 包

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ **FORBIDDEN**：`app/ui/**`、`app/navigation/**` 下 import `data.repository.*` / `data.remote.*` / `data.local.*`，必须经 Domain 接口或 Hilt 注入。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
Composable
    ↓ collectAsStateWithLifecycle
Android*ViewModel（platform 壳）
    ↓ 委托
Common*ViewModel（KMP commonMain/presentation/）
    ↓ 调用
UseCase（KMP commonMain/domain/）
    ↓ 调用
Repository interface（KMP commonMain/domain/repository/）
    ↓ 由 Hilt @Binds 绑定
RepositoryImpl（KMP commonMain/data/）
    ↓ 调用
DataSource expect ↔ androidMain actual（Room / DataStore / Keystore）
```

## 8. 平台差异 [{{activation_state_section_8}}]

- 与 iOS 的差异由 KMP shared 抽象，详见 `standard-kmp-shared.md「§4 分层规则」`
- Android 专属：Foreground Service、WorkManager、PendingIntent、Notification Channel、Storage Access Framework

## 9. 错误模型 [{{activation_state_section_9}}]

- Compose 屏幕错误用 sealed `UiState.Error` 表达，**禁止** 在 Composable 内 try/catch 业务异常
- KMP shared 抛出的 `DomainException` 在 Android `ViewModel` 中映射为 `UiState.Error(message, retryable)`
- 平台 SDK 异常需在 `app/platform/` 桥接层（KMP shared 的 androidMain actual）捕获并转换为 `DomainException`

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成 Composable 必须 `@Composable` 标注且函数首字母大写
- AI 生成 Android ViewModel 必须 `@HiltViewModel` + 构造注入 UseCase 或 Common*ViewModel
- AI **不得** 在 Android 模块内复刻 Domain 层（UseCase / Entity / Repository interface），必须 import KMP shared
- AI 生成的 Hilt Module 必须按 Domain / Data / Platform 三层切分文件
- ProGuard / R8 规则修改必须列出影响范围

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] release build minifyEnabled = true
- [ ] ViewModel 不持有 Activity 引用
- [ ] AndroidManifest 权限均有运行时 Permission 流程
- [ ] `app/` 内无重新定义的 UseCase / Entity / Repository interface
- [ ] Hilt Module 至少切分 Domain / Data / Platform
- [ ] Android ViewModel 仅依赖 UseCase / Common*ViewModel，不依赖 RepositoryImpl

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-CLIENT-{{N}}` | `app/src/main/**` | {{core_observation}} | {{confidence}} |
| `EV-CLIENT-{{N}}` | `app/src/main/**/di/**` | {{core_observation}} | {{confidence}} |
