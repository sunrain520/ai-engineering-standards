---
doc_id: "app-client-ios-standard"
title: "iOS 开发规范（KMP × Clean Architecture 平台壳）"
domain: "app-client"
sub_domain: "ios"
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
  - "ios"
  - "kmp-platform"
  - "clean-architecture"
---

# iOS 开发规范（KMP × Clean Architecture 平台壳）

<!-- 写作说明（生成时删除）
- 本骨架在 sub-domain-skeleton 12 节基础上嵌入 iOS 平台壳 + Clean Architecture 接入内容
- App 端整体架构 = KMP（commonMain 共享 Domain/Data/Presentation） × Clean（依赖方向 Presentation→Domain←Data）
- iOS 子域只承担 Clean 中的"Presentation 平台壳"+"Data 层 actual 实现"，Domain 完整下沉到 KMP shared
- §4 / §6 必须涵盖：SwiftUI vs UIKit 选型、Combine / async-await 模式、Privacy Manifest、ATS 配置、KMP Bridge
-->

## 1. 规范定位 [{{activation_state_section_1}}]

{{positioning_text}}

- 子领域：`ios`
- 架构组合：作为 KMP 平台壳承载 Clean Architecture 的 Presentation 平台层 + Data 层 actual 桥接
- 平台壳职责：SwiftUI / UIKit 渲染、Permission、Notification、KMP shared `actual` Bridging
- 激活态：`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载（iOS 模块）**

- **Presentation 平台壳**：SwiftUI View / UIViewController、`*ViewModel: ObservableObject`（委托给 KMP `Common*ViewModel`）
- **Data 层 actual 实现**：Keychain / CoreData / UserDefaults Bridge、APNs / Background Tasks 适配
- SwiftUI / UIKit 视图层与 NavigationStack / NavigationCoordinator
- Combine / async-await 桥接 KMP Flow / suspend
- Privacy Manifest（`PrivacyInfo.xcprivacy`）、ATS / Info.plist 配置
- 平台 SDK 封装（Keychain / APNs / HealthKit 等）

**不应承载**

- 跨端业务逻辑（必须放 KMP `commonMain/domain/`）
- 网络协议解析（由 KMP shared 的 Data 层承担）
- 跨端 UseCase / Entity 重新定义（直接通过 `Shared` framework import）

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
ios/                                — iOS 平台壳模块
├── App/
│   ├── Presentation/               — Clean Presentation 平台壳
│   │   ├── Views/                  — SwiftUI View
│   │   ├── ViewModels/             — *ViewModel: ObservableObject（委托 Common*ViewModel）
│   │   └── Components/             — 通用 SwiftUI 组件
│   ├── Bridges/                    — KMP shared actual / Combine 桥接
│   │   ├── KeychainBridge.swift
│   │   ├── FlowBridge.swift        — Kotlin Flow ↔ Combine / AsyncSequence
│   │   └── DependencyContainer.swift — 装配 UseCase / Repository
│   ├── Resources/
│   │   ├── Info.plist
│   │   └── PrivacyInfo.xcprivacy
│   └── App.swift
└── Project.xcodeproj
```

## 4. 分层规则 [{{activation_state_section_4}}]

**Clean × iOS 平台壳映射**

| Clean 层 | iOS 模块归属 | 主要类型 | 禁止事项 |
| --- | --- | --- | --- |
| Presentation（平台壳） | `ios/App/Presentation/` | SwiftUI View、`*ViewModel: ObservableObject` | 直接调用 Repository、持有 ViewController 强引用 |
| Presentation（共享） | KMP `commonMain/presentation/` | Common*ViewModel | 在 iOS 模块中重新实现 |
| Domain | KMP `commonMain/domain/` | UseCase / Entity / Repository interface | 在 iOS 模块中用 Swift 重新定义 |
| Data（接口实现） | KMP `commonMain/data/` | RepositoryImpl / Mapper | 在 iOS 模块中重新实现 |
| Data（actual） | `ios/App/Bridges/` 或 KMP `iosMain/` | Keychain / CoreData Bridge | 包含业务逻辑 |
| DI 装配 | `ios/App/Bridges/DependencyContainer.swift` | 手写容器或 Resolver | 在 View 中直接 new RepositoryImpl |

**SwiftUI vs UIKit 选型**

- 新屏默认 SwiftUI；UIKit 仅用于 SwiftUI 不支持的高级控件（高度自定义动画、复杂 collection）。
- 跨屏共享样式必须落在 SwiftUI 的 `ViewModifier` 或 UIKit Theme；**禁止** 同屏混用 `Color(uiColor:)` 与硬编码 hex。

**Combine / async-await 模式（KMP 桥接）**

- KMP `Flow` ↔ Swift：通过 `FlowBridge` 转 `AsyncSequence` 或 Combine Publisher，**禁止** 在 SwiftUI View 中直接订阅 KMP Flow。
- KMP `suspend fun` ↔ Swift：通过 KMP-NativeCoroutines 或自写 `Task { try await ... }` 桥接。
- ViewModel 状态发布优先 `@Published` + Combine。

**Swift ViewModel 与 Common*ViewModel 关系**

```text
SwiftUI View
    ↓ @ObservedObject / @StateObject
SwiftViewModel: ObservableObject (@MainActor)
    └─ 持有 Common*ViewModel (KMP commonMain/presentation/)
       └─ 调用 UseCase (KMP commonMain/domain/)
          └─ 调用 Repository (KMP commonMain/domain/repository/)
             └─ 由 DependencyContainer 注入 RepositoryImpl (KMP commonMain/data/)
```

## 5. 命名规范 [{{activation_state_section_5}}]

- View 后缀 `*View`，Swift ViewModel 后缀 `*ViewModel`，与 KMP `Common*ViewModel` 一一对应
- Bridge 类后缀 `*Bridge`（如 `KeychainBridge` / `FlowBridge`）
- Clean 层命名沿用 KMP shared 约定：UseCase / Entity / Repository / RepositoryImpl 直接通过 `Shared` framework import
- 全局协议前缀 `App` 或领域名（如 `AuthService`）

## 6. 核心规则 [{{activation_state_section_6}}]

### P0 业务逻辑必须落在 KMP shared，不在 iOS 模块复刻

> level: P0 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

**适用范围**

- `ios/App/Presentation/**`、`ios/App/Bridges/**`

**强制规则**

1. UseCase / Entity / Repository interface 全部位于 KMP shared `commonMain/domain/`，iOS 模块仅 import 与装配。
2. 业务校验、状态机、领域计算 **禁止** 在 SwiftUI View / Swift ViewModel 中实现，必须委托 KMP UseCase。
3. Swift ViewModel 仅做：`@Published` 状态适配、KMP `Common*ViewModel` 委托、Flow → Combine 桥接。

**禁止事项**

- 禁止在 iOS 模块新建 Swift `Domain/` 目录重新定义 Entity / UseCase。
- 禁止在 SwiftUI View 中写 if-else 业务分支决策，应放 UseCase。

**反例**

```swift
// 反例：在 SwiftUI View 中写业务校验
struct LoginView: View {
    var body: some View {
        Button("登录") {
            if username.count < 6 || !password.matches(PASSWORD_REGEX) { // ❌ 应在 UseCase
                // ...
            }
        }
    }
}
```

### P1 ViewModel 必须 @MainActor

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

**强制规则**

1. `@MainActor class XxxViewModel: ObservableObject`，`@Published` 属性变更必须在主线程。
2. async 任务通过 `Task {}` 启动，跨 actor 调用使用 `await`。
3. 调用 KMP suspend fun 时必须用 `Task { try await ... }` 包装，**禁止** 阻塞主线程。

### P1 KMP Flow ↔ Combine 必须经 Bridge

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

**强制规则**

1. 不在 SwiftUI View 中直接调用 KMP Flow `collect`，必须通过 `FlowBridge` 或 KMP-NativeCoroutines 转换为 `AsyncSequence` / Publisher。
2. Bridge 必须在 ViewModel 销毁时正确取消订阅（`store: AnyCancellable` / `Task` 持有）。

**正例**

```swift
@MainActor
final class LoginViewModel: ObservableObject {
    @Published private(set) var state: UiState = .idle
    private let common: CommonLoginViewModel        // KMP shared
    private var stateTask: Task<Void, Never>?

    func observe() {
        stateTask = Task { [weak self] in
            for await uiState in common.state.asAsyncSequence() {
                self?.state = uiState.toSwift()
            }
        }
    }

    deinit { stateTask?.cancel() }
}
```

### FORBIDDEN Privacy Manifest 缺失

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

> ⛔ **FORBIDDEN**：发布到 App Store 的 build 缺少 `PrivacyInfo.xcprivacy` 或未声明 required reason API 使用。

### FORBIDDEN iOS 模块直接 import KMP data 包类型

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

> ⛔ **FORBIDDEN**：SwiftUI View 与 Swift ViewModel 不得直接 import / 引用 KMP `data.repository.*RepositoryImpl` / `data.remote.*` / `data.local.*` 类型，必须经由 Domain 接口或 DependencyContainer 注入。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
SwiftUI View
    ↓ @ObservedObject / @StateObject
Swift ViewModel (@MainActor, ObservableObject)
    ↓ 委托
Common*ViewModel（KMP commonMain/presentation/）
    ↓ 调用
UseCase（KMP commonMain/domain/）
    ↓ 调用
Repository interface（KMP commonMain/domain/repository/）
    ↓ 由 DependencyContainer 注入
RepositoryImpl（KMP commonMain/data/）
    ↓ 调用
DataSource expect ↔ iosMain actual（Keychain / CoreData / NSURLSession Bridge）
```

## 8. 平台差异 [{{activation_state_section_8}}]

- 与 Android 的差异由 KMP shared 抽象；iOS 专属：Keychain、APNs、Background Tasks、StoreKit 2、CloudKit
- Flow ↔ Combine 桥接策略需在 `FlowBridge` 中统一收口

## 9. 错误模型 [{{activation_state_section_9}}]

- 错误类型用 Swift `enum: Error`，通过 `Result<Success, Failure>` 或 `throws` 暴露
- KMP shared 抛出的 `DomainException` 在 `*Bridge` 层映射为 Swift `enum: Error`
- SwiftUI View 通过 `UiState.error` 渲染错误，**禁止** 在 View 内直接 try/catch 业务异常

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成 SwiftUI View 必须明确 `body` 类型与 `@StateObject` / `@ObservedObject` 选型
- AI 生成 Swift ViewModel 必须 `@MainActor` + `ObservableObject`，构造注入 KMP UseCase 或 `Common*ViewModel`
- AI **不得** 在 iOS 模块内复刻 Domain 层（UseCase / Entity / Repository interface），必须通过 `Shared` framework 引用
- async 函数必须标注 `throws` 边界
- KMP Flow 订阅必须经 Bridge，禁止 View 内直接 collect
- Privacy Manifest 中新增 API 使用必须填写 reason code

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] ViewModel @MainActor 标注
- [ ] PrivacyInfo.xcprivacy 包含全部 required reason API
- [ ] Info.plist 权限文案非占位
- [ ] iOS 模块内无 Swift 重新定义的 UseCase / Entity / Repository interface
- [ ] Flow 订阅全部经 `FlowBridge` 或 KMP-NativeCoroutines
- [ ] Swift ViewModel 仅依赖 UseCase / Common*ViewModel，不依赖 RepositoryImpl

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-CLIENT-{{N}}` | `ios/App/**` | {{core_observation}} | {{confidence}} |
| `EV-CLIENT-{{N}}` | `ios/App/Bridges/**` | {{core_observation}} | {{confidence}} |
