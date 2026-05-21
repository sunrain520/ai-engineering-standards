# Domain Sampling Adapters

adapter 只负责帮助 `profile-first` 选择代表性文件候选，不分叉主 workflow。所有 domain 仍走同一条 `project-profile -> extraction-map -> batch-plan -> selected-batch facts` 流程。

## 1. APP

信号：

- `build.gradle.kts`
- `commonMain` / `androidMain` / `iosMain`
- `ViewModel`、`UiState`、`Repository`
- iOS `Reactor` / `Action` / `Mutation` / `State`

代表性候选：

- KMP shared usecase / repository / mapper。
- Android ViewModel / Fragment / Activity / UI state。
- iOS Reactor / ViewController / network adapter。
- DataCenter / Repository 接入点。

排除：

- build output。
- generated sources。
- vendor / Pods / Gradle cache。
- secret / prod config。

## 2. Backend

信号：

- `pom.xml` / `build.gradle` / `src/main/java`
- `Controller` / `Service` / `Repository` / `Mapper`
- `DTO` / `Request` / `Response`
- `job` / `consumer` / `producer`

代表性候选：

- API Controller + Service + DTO 闭环。
- 写操作 transaction / idempotency 路径。
- Mapper / Repository 数据访问路径。
- MQ / job 入口和错误处理。

排除：

- target / build / generated。
- 数据库 dump。
- 生产配置和密钥。
- 第三方 SDK 源码。

## 3. Frontend

信号：

- `package.json`
- `src/components`
- `vite` / `next` / `webpack`
- route / page / store / api client。

代表性候选：

- page / route 入口。
- form / table / permission 组件。
- API client / type definition。
- state management 和 error handling。

排除：

- `node_modules`
- dist / build。
- lockfile 之外的 vendored 包。
- env secrets。

## 4. PC

信号：

- Electron / desktop entry。
- `ipcMain` / `ipcRenderer`。
- local storage / update / native bridge。

代表性候选：

- 主进程入口。
- renderer 页面入口。
- IPC contract。
- 本地存储、更新和错误处理路径。

排除：

- packaged app output。
- native binary。
- generated preload bundle。
- signing credentials。

## 5. Industry

信号：

- trade / quote / account / order / risk / compliance。
- 行业术语或监管流程。
- 已有负责人确认文档。

代表性候选：

- 业务流程入口。
- 风控 / 合规校验点。
- 订单 / 账户 / 交易状态流转。
- owner-confirmed 文档或审计证据。

排除：

- 客户数据。
- 生产凭据。
- 未脱敏日志。
- 无负责人确认的行业通用猜测。
