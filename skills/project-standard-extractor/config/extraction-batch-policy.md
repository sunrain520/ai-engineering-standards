# Extraction Batch Policy

batch 是正式规范萃取的最小执行边界。所有 `batch-extraction` 都必须从 `batch-plan` 中选择一个 batch 后再读取 evidence。

## 1. Batch 字段

```yaml
batch_id: backend-java-api-order
domain: backend
sub_domain: java-spring
module: order
task_type: api-development
doc_mode: guide              # guide（默认，综合开发指南）| catalog（规则条目注册表，特殊场景）
candidate_files:
  - path: /repo/order-service/src/main/java/.../OrderController.java
    reason: Controller entry for order query API
    evidence_kind: positive
excluded_paths:
  - path: /repo/order-service/src/main/resources/application-prod.yml
    reason: sensitive production config
evidence_limit: 25           # guide 模式默认 25；catalog 模式默认 8
stop_conditions:
  - no representative files
  - only inferred evidence
  - sensitive files are required to continue
  - evidence_limit reached
status: ready
```

## 2. `doc_mode` 说明

| doc_mode | 用途 | evidence_limit | 产出格式 |
| --- | --- | --- | --- |
| `guide`（默认） | 综合编写开发者工作手册，覆盖完整 sub_domain | **25**（可在 batch 中调高至 40） | 按 standard-template.md 的 Developer Guide 结构 |
| `catalog` | 仅追加单条规则到已有规范，用于小范围补充 | 8 | 按旧格式，每条规则独立 YAML 块（仅在 guide 文档已存在时使用） |

**`guide` 模式下需要读更多文件的原因**：

一份合格的 Developer Guide 需要覆盖 sub_domain 所有关键角色/层级。以 Android 为例：
- Activity/Fragment（UI 层）
- ViewModel/BaseVM（状态层）
- UseCase/Repository（业务层）
- HSLoadData（加载态框架）
- 命名规范（来自多个文件的命名模式）

仅读 8 个文件只能覆盖 1-2 个角色，无法写出完整指南。25 个文件可以覆盖 3-5 个角色，基本完整。

## 3. 状态

| status | 含义 | 后续动作 |
| --- | --- | --- |
| `ready` | 有代表性候选文件，可进入正式萃取 | 用户选择后执行 |
| `pending-confirmation` | 候选方向存在，但证据或负责人确认不足 | 先补输入或负责人确认 |
| `skipped` | 没有代表性 evidence 或超出范围 | 不生成规则 |
| `blocked` | 敏感、权限或读取边界阻塞 | 停止并说明原因 |

## 4. 生成规则

1. 一个 batch 对应一个明确的 `domain + sub_domain + module/task_type`。
2. `candidate_files` 是代表性候选，**guide 模式应包含 sub_domain 的多个角色/层级代表文件**，不仅仅是一个模块。
3. `excluded_paths` 必须记录敏感目录、生成物、依赖目录、构建产物和超出范围路径。
4. `evidence_limit` 必须显式写出；guide 模式建议 **20-30**。
5. batch 不得通过"common"吞掉多个独立子领域；跨子领域共性应单独建 `sub_domain: common` batch。
6. **guide 模式的 candidate_files 应该横跨 sub_domain 的主要角色**，例如：
   - Android guide：Controller/Fragment + ViewModel + UseCase + Repository + UiState
   - KMP guide：UseCase + Repository + Presenter + DomainModel + Mapper
   - iOS guide：ViewController + Reactor + State + KMP adapter

## 5. 停止条件

命中以下任一情况时停止该 batch：

- 没有代表性文件候选。
- 候选文件全部属于同一角色（不够覆盖 sub_domain 的主要层级）。
- 继续萃取需要读取敏感文件原值。
- evidence 数量超过 `evidence_limit`。
- 需要跨 batch 才能成立。

停止后可写入 `pending-confirmation` 或 `skipped`，不得把不完整结论写入 AI 默认执行路径。

## 6. Guide 模式 candidate_files 选取策略（全领域通用）

选取 `candidate_files` 时，优先按**覆盖层级**思考，而不是"哪个文件最典型"。每个优先级至少选 1-2 个文件，总数控制在 `evidence_limit` 内。

**通用优先级框架**：

| 层级优先级 | 通用说明 | 典型 evidence_kind |
| --- | --- | --- |
| P0：入口层 | 展示该 sub_domain 最顶层使用模式的文件 | positive |
| P1：核心业务层 | 承载核心业务逻辑或状态的角色文件 | positive |
| P2：数据/契约层 | 数据访问、类型定义、契约文件 | positive |
| P3：反例/遗留 | 已知反范式或历史兼容代码 | negative / legacy |
| P4：配置/构建 | 技术栈声明、构建脚本、依赖清单 | positive |

**各领域 candidate_files 选取示例**：

| domain / sub_domain | P0 入口层 | P1 核心层 | P2 数据/契约层 | P4 配置层 |
| --- | --- | --- | --- | --- |
| app-client / android | Fragment, Activity | ViewModel, BaseVM | Repository, DTO, Mapper | build.gradle |
| app-client / kmp-shared | UseCase | Presenter, RepositoryImpl | DomainModel, Mapper, DTO | settings.gradle.kts |
| app-client / ios | ViewController | Reactor | State, Action, Mutation | Package.swift |
| frontend / react | Page, Route | Component, Hook | Store, API Client, Type | package.json, tsconfig |
| frontend / vue | Page, View | Component, Composable | Store(Pinia), API, Type | vite.config.ts |
| backend / java-spring | Controller | Service | Repository, Mapper, DTO | pom.xml, application.yml |
| backend / golang | Handler/Router | Service | Repository, Model | go.mod, config.go |
| backend / python | Router/View | Service | Repository, Schema | pyproject.toml |
| pc-client / electron | Main Process 入口 | IPC Handler | Preload, Renderer 入口 | package.json |
| testing | Test 入口类 | Mock 策略文件 | Fixture, Factory | build 测试配置 |
| security | Auth Middleware | Permission Checker | Validator, Audit Logger | security config |
| industry | 业务流程入口 | 风控/合规校验点 | 状态流转定义 | owner-confirmed 文档 |
