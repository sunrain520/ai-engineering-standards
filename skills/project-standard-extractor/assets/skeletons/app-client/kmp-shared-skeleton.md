---
doc_id: "app-client-kmp-shared-standard"
title: "KMP Shared 开发规范（KMP × Clean Architecture）"
domain: "app-client"
sub_domain: "kmp-shared"
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
  - "kmp-shared"
  - "kotlin-multiplatform"
  - "clean-architecture"
---

# KMP Shared 开发规范（KMP × Clean Architecture）

<!-- 写作说明（生成时删除）
- 本骨架在通用 sub-domain-skeleton 12 节基础上嵌入 KMP × Clean Architecture 专属内容
- App 端整体架构 = Kotlin Multiplatform（commonMain/androidMain/iosMain 源集划分） + Clean Architecture（Presentation / Domain / Data 三层 + UseCase + Entity + Repository 抽象）
- §3 推荐目录必须同时呈现 Clean 三层 × KMP 源集的二维结构
- §4 分层规则必须包含 expect/actual 边界规则、Clean 三层依赖方向、Coroutines/Flow 跨端模式（origin AE17 强制 expect/actual 关键字必须出现）
- §8 平台差异必须列出 commonMain / androidMain / iosMain 三层关系
-->

## 1. 规范定位 [{{activation_state_section_1}}]

{{positioning_text}}

- 子领域：`kmp-shared`
- 端类型：`app-client`
- 架构组合：Kotlin Multiplatform × Clean Architecture（Presentation / Domain / Data + UseCase + Entity + Repository）
- 共享内核能力：Coroutines / Flow / kotlinx.serialization / Ktor / SQLDelight / Koin
- 激活态：`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载（commonMain）**

- **Domain 层**：Entity（领域实体）、UseCase（业务用例）、Repository / DataSource 接口、领域异常
- **Data 层**：Repository 实现、远端 / 本地 DataSource 实现、DTO ↔ Entity Mapper、网络协议、序列化、缓存策略
- **Presentation 层（共享部分）**：跨端共享 ViewModel / Presenter、UI State / UI Event 定义、可观测埋点契约

**不应承载**

- 平台 UI 渲染（Compose / SwiftUI 留在 androidMain / iosMain 平台壳）
- 平台 Permission 弹窗、系统服务调用
- 平台特有日志 / Crash SDK 直接绑定

**Clean 依赖方向铁律**

```text
Presentation → Domain ← Data
```

- Domain 层 **不得** 依赖 Presentation 与 Data 任何具体实现，仅通过 interface 暴露契约
- Data 层 **只能** 依赖 Domain（实现 Repository 接口），**禁止** 反向引用 Presentation
- Presentation 层通过 UseCase 调用 Domain，**禁止** 直接 import Data 层 class

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
shared/
├── src/
│   ├── commonMain/kotlin/
│   │   ├── domain/                — 领域层（无平台依赖）
│   │   │   ├── entity/            — Entity / Value Object
│   │   │   ├── usecase/           — UseCase / Interactor
│   │   │   ├── repository/        — Repository interface
│   │   │   └── exception/         — 领域异常 DomainException
│   │   ├── data/                  — 数据层
│   │   │   ├── repository/        — RepositoryImpl
│   │   │   ├── remote/            — Ktor API + DTO
│   │   │   ├── local/             — SQLDelight / DataStore
│   │   │   └── mapper/            — DTO ↔ Entity Mapper
│   │   └── presentation/          — 共享 Presentation
│   │       ├── viewmodel/         — Common*ViewModel
│   │       └── state/             — UiState / UiEvent
│   ├── commonTest/kotlin/         — 跨端单测（Domain / Data 优先）
│   ├── androidMain/kotlin/        — Android 专属 actual 实现（Bridge / Platform DataSource）
│   ├── iosMain/kotlin/            — iOS 专属 actual 实现（Bridge / Platform DataSource）
│   └── jvmMain/kotlin/            — JVM 专属 actual（可选）
└── build.gradle.kts               — KMP target 配置
```

## 4. 分层规则 [{{activation_state_section_4}}]

**Clean × KMP 二维矩阵**

| Clean 层 ＼ KMP 源集 | commonMain | androidMain（actual） | iosMain（actual） |
| --- | --- | --- | --- |
| Domain | Entity / UseCase / Repository interface（纯 Kotlin） | ❌ 不应出现 | ❌ 不应出现 |
| Data | RepositoryImpl / Mapper / 协议层 | actual DataSource（Room / SharedPrefs 桥） | actual DataSource（CoreData / Keychain 桥） |
| Presentation | Common*ViewModel / UiState / UiEvent | actual 平台桥（Dispatchers.Main / Lifecycle） | actual 平台桥（Dispatchers.Main / NSRunLoop） |

**expect / actual 边界规则**

```text
commonMain (expect 声明)
    ↓
androidMain (actual 实现)    iosMain (actual 实现)
```

1. `expect` 必须放在 `commonMain`，`actual` 必须在对应 platform source set，**禁止** 在 `commonMain` 写 `actual`。
2. `expect class` / `expect fun` 仅用于真正需要平台差异的能力（文件 IO、加密、平台时间）；可由 commonMain 全实现的能力 **禁止** 拆 `expect/actual`。
3. `expect` 必须有完整文档说明各平台 `actual` 的语义差异与异常约定。
4. `actual` 实现必须保持 `expect` 的契约语义（返回类型、抛出异常、线程语义）；若无法保证一致，必须在 `expect` 文档中明确平台分支。

**Coroutines / Flow 跨端模式**

| 层级 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| Domain（commonMain） | UseCase 编排、Flow / Result 返回 | 直接 import Dispatchers / 平台线程 API |
| Data（commonMain） | Repository 实现、缓存与远端编排 | 在 commonMain 直接调用平台 SDK |
| Presentation（commonMain） | ViewModel scope、UiState 暴露 | 直接调用平台 UI 线程 API |
| androidMain | Dispatchers.Main 绑定、Handler 桥接、Hilt 注入 | 在 actual 中嵌入 Android UI 框架代码 |
| iosMain | Dispatchers.Main 绑定 NSRunLoop、Combine 桥接 | 在 actual 中嵌入 SwiftUI 视图代码 |

## 5. 命名规范 [{{activation_state_section_5}}]

- expect 类 / 函数与对应 actual 同名：`expect class FileSystem` ↔ `actual class FileSystem`
- 平台特有桥接类后缀 `Bridge` / `Adapter`，如 `IosKeychainBridge`
- Clean 层后缀约定：
  - Entity：`*` （纯名词，如 `User`、`Order`）
  - UseCase：`*UseCase`（如 `LoginUseCase`、`FetchOrderListUseCase`）
  - Repository 接口：`*Repository`（在 `domain/repository/`）
  - Repository 实现：`*RepositoryImpl`（在 `data/repository/`）
  - Mapper：`*Mapper`；DTO：`*Dto`
- ViewModel 在 commonMain 用 `Common*ViewModel`，平台壳分别为 `Android*ViewModel` / `Ios*ViewModel`

## 6. 核心规则 [{{activation_state_section_6}}]

### P1 expect/actual 仅用于平台差异

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**适用范围**

- `shared/src/commonMain/**`、`shared/src/{android,ios}Main/**`

**强制规则**

1. 仅在能力存在真实平台差异（IO / 加密 / 时间 / 平台 SDK）时使用 `expect/actual`。
2. `expect` 必须 KDoc 说明各平台行为差异。

**禁止事项**

- 禁止在 `commonMain` 出现 `actual` 关键字。
- 禁止用 `expect/actual` 替代纯业务逻辑分发。

**正例**

```kotlin
// commonMain/Crypto.kt
expect class Crypto {
    fun sha256(input: ByteArray): ByteArray
}

// androidMain/Crypto.kt
actual class Crypto {
    actual fun sha256(input: ByteArray): ByteArray =
        java.security.MessageDigest.getInstance("SHA-256").digest(input)
}
```

**反例**

```kotlin
// 反例：commonMain 中混用 actual，平台分支泄露
expect fun log(tag: String, msg: String)
actual fun log(tag: String, msg: String) { println("[$tag] $msg") } // ❌ 应放 platform source set
```

**AI 生成代码要求**

1. AI 生成 KMP 共享层代码时，只在 `commonMain` 写 `expect`，`actual` 必须落到 `androidMain` / `iosMain`。

**Code Review 检查项**

- [ ] commonMain 中无 `actual` 关键字
- [ ] 每个 `expect` 都有 KDoc 描述平台差异

**Evidence**

- `evidence/code-facts.md「EV-CLIENT-{{N}}」`

### P0 Domain 层零外部依赖

> level: P0 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**适用范围**

- `shared/src/commonMain/kotlin/domain/**`

**强制规则**

1. Domain 层（Entity / UseCase / Repository interface）只允许依赖 kotlin stdlib、kotlinx.coroutines、kotlinx.datetime。
2. Repository / DataSource 必须以 interface 形式定义，实现放在 Data 层。
3. UseCase 输入输出使用 Entity 或 Value Object，**禁止** 接收 / 返回 DTO。

**禁止事项**

- 禁止 import `data.*`、`presentation.*`、`androidx.*`、`Foundation.*`、`UIKit.*`。
- 禁止在 Domain 中出现 Ktor / SQLDelight / Room / Retrofit / kotlinx.serialization 注解。
- 禁止 Domain 抛出 IO / Network / DB 框架异常，必须封装为 `DomainException` 子类。

**正例**

```kotlin
// commonMain/domain/usecase/LoginUseCase.kt
class LoginUseCase(private val repo: AuthRepository) {
    suspend operator fun invoke(username: String, password: String): Result<User> =
        repo.login(username, password)
}
```

**反例**

```kotlin
// 反例：UseCase 直接依赖 Ktor / DTO
class LoginUseCase(private val client: HttpClient) { // ❌ 应依赖 AuthRepository 接口
    suspend operator fun invoke(...): LoginResponseDto { ... }       // ❌ 返回 DTO 而非 Entity
}
```

**AI 生成代码要求**

1. AI 在 `domain/` 下生成代码时，import 仅允许来自 `kotlin.*` / `kotlinx.coroutines.*` / `kotlinx.datetime.*` / 同包 `domain.*`。
2. UseCase 必须以 `class XxxUseCase(private val repo: XxxRepository)` 形式呈现。

**Code Review 检查项**

- [ ] domain/ 下无 import `data.` / `presentation.` / 平台 SDK
- [ ] Repository 仅以 interface 出现在 domain/
- [ ] UseCase 输入输出皆为 Entity / Value Object

### P1 Data 层不得跨过 Domain 直连 Presentation

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**强制规则**

1. `data/repository/*RepositoryImpl` 必须实现 `domain/repository/*Repository` 接口。
2. DTO ↔ Entity 转换必须在 `data/mapper/*Mapper` 中完成；Mapper 接收 DTO，输出 Entity。
3. Data 层的所有出站接口（被外部调用的）只能是 Domain 层接口实现；不得新增 Data 层独有 public API 给 Presentation 直接消费。

**禁止事项**

- 禁止 `presentation/` 下 import `data.*`。
- 禁止 Data 层将 DTO 直接暴露给 Presentation。

### FORBIDDEN 平台 UI 框架进入 commonMain

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ **FORBIDDEN**：commonMain 不得 import Compose / SwiftUI / UIKit / Android Framework 任何 UI 类。

**反例**

```kotlin
// 反例：commonMain 引入 androidx.compose
import androidx.compose.runtime.Composable // ❌ 平台 UI 泄露至共享层
```

**AI 生成代码要求**

1. AI 不得在 `commonMain` 生成任何 `androidx.*` / `android.*` / `Foundation.*` / `UIKit.*` 类型。

### FORBIDDEN Presentation 越过 Domain 直接调用 Data

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ **FORBIDDEN**：`presentation/**` 下 import `data.repository.*` / `data.remote.*` / `data.local.*`。

**反例**

```kotlin
// 反例：ViewModel 直接 new RepositoryImpl
class CommonLoginViewModel(
    private val repo: AuthRepositoryImpl   // ❌ 应注入 AuthRepository 接口
) { ... }
```

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
平台壳 View（Compose / SwiftUI）
    ↓ collectAsState / @Published
平台壳 ViewModel（android/iosMain，绑定平台生命周期）
    ↓ 委托
Common*ViewModel（commonMain/presentation）
    ↓ 调用
UseCase（commonMain/domain/usecase）
    ↓ 调用
Repository interface（commonMain/domain/repository）
    ↓ 实现
RepositoryImpl（commonMain/data/repository）
    ↓ 调用
Remote / Local DataSource（commonMain/data + expect/actual）
    ↓ 平台分发
Ktor / SQLDelight / Keychain / SharedPreferences（platform actual）
```

## 8. 平台差异 [{{activation_state_section_8}}]

| 能力 | androidMain actual | iosMain actual | 备注 |
| --- | --- | --- | --- |
| 文件 IO | java.io / okio | NSFileManager / okio | 优先 okio |
| 主线程派发 | Dispatchers.Main（Android） | Dispatchers.Main（iOS NSRunLoop） | 由 Coroutines KMP runtime 提供 |
| 加密 | java.security | CommonCrypto / Security framework | 通过 expect 桥接 |
| 安全存储 | EncryptedSharedPreferences / DataStore | Keychain | 在 Data 层封装为 `SecureStorage` expect |
| DB | SQLDelight Android driver | SQLDelight Native driver | 在 Data 层 `data/local/` 中以 expect/actual 提供 driver |

## 9. 错误模型 [{{activation_state_section_9}}]

- Domain 层只抛出 `DomainException` 子类（`AuthException` / `NetworkException` / `CacheException` 等）
- Data 层负责将平台异常（`IOException` / `NSError` / `SQLException`）映射为 `DomainException`
- Presentation 层的 UiState 用 sealed class 表达，错误状态承载 `DomainException` 而非平台原始异常
- 禁止在 commonMain 直接抛出 `IOException` / `NSError` 类型

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成 KMP 共享层代码必须区分 commonMain / platform source set
- AI 在 `domain/` 下生成代码必须遵守"零外部依赖"P0 规则
- AI 生成 UseCase 必须以 Repository 接口注入，**禁止** 直接 new RepositoryImpl
- 跨平台数据传输优先使用 `data class` + kotlinx.serialization（仅 DTO 用，Entity 不放序列化注解）
- Coroutines 的 Dispatchers 取自 commonMain 抽象，**禁止** 直接写 `Dispatchers.Main.immediate`

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] commonMain 无平台 SDK import
- [ ] 每个 `expect` 都有对应 `actual`
- [ ] `domain/` 不依赖 `data/` 与 `presentation/`
- [ ] Repository 接口在 domain，实现在 data
- [ ] UseCase 输入输出皆为 Entity
- [ ] DTO ↔ Entity 转换全部走 Mapper
- [ ] Coroutines 使用统一 Dispatchers 抽象

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件（路径模式） | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-CLIENT-{{N}}` | `shared/src/**Main/**` | {{core_observation}} | {{confidence}} |
| `EV-CLIENT-{{N}}` | `shared/src/commonMain/kotlin/{domain,data,presentation}/**` | {{core_observation}} | {{confidence}} |
