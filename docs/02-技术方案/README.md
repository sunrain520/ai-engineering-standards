# 部门级 AI 辅助研发规范工程完整技术方案

## 文档状态

本文档保留 `engineering-standards` 的完整建设蓝图，用于说明最终形态、资产范围和演进方向。

第一阶段实际落地基线以 [第一阶段技术方案.md](./第一阶段技术方案.md) 为准；凡是第一阶段定位、交付清单、Skill 范围或技术路线与本文档存在差异时，优先采用第一阶段技术方案。

[一期方案.md](./一期方案.md) 保留为轻量索引和规则工程设计参考，其中 `llms.txt`、`rules-index.json`、Rule ID 和 Front Matter 等内容作为后续增强能力，不再作为第一阶段主交付。

## 当前第一阶段实施入口

- [第一阶段技术方案.md](./第一阶段技术方案.md)：第一阶段范围和落地基线。
- [skill建设.md](./skill建设.md)：`project-standard-extractor` Skill 建设细节。
- [高质量萃取.md](./高质量萃取.md)：规范质量门禁参考。
- [当前代码与规范产物分析.md](./当前代码与规范产物分析.md)：当前仓库 source assets、Skill 执行流程和各研发域规范产物状态分析。
- [../plans/2026-05-21-001-feat-project-standard-extractor-plan.md](../plans/2026-05-21-001-feat-project-standard-extractor-plan.md)：当前执行计划。

实际源资产已迁移到：

```text
skills/project-standard-extractor/
```

## 方案名称

```text
engineering-standards
```

中文名：

```text
部门级研发工程规范
```

方案定位：

> 基于现有优秀代码和真实研发习惯，建设一套面向 AI 辅助研发的部门级研发规范工程，使 AI 能够按照团队架构、目录结构、编码风格、模块边界和质量要求辅助完成需求开发。

---

# 一、完整蓝图建设目标

## 1. 核心目标

第一版本不追求覆盖所有规范，而是优先解决 AI 辅助研发中的关键问题：

```text
1. AI 不知道代码应该写在哪里
2. AI 不知道各端应该遵守什么架构
3. AI 不知道哪些代码可以复用
4. AI 不知道哪些逻辑应该下沉共享层
5. AI 不知道哪些写法是团队禁止的
6. AI 生成代码后缺少统一自检标准
7. Code Review 缺少可引用的规范依据
```

完整蓝图的核心目标是形成：

```text
统一规范仓库
+ 各端开发规范
+ AI Coding Rules
+ 正反例代码
+ Review Checklist
+ Prompt 模板
+ 落地流程
```

---

## 2. 完整蓝图不做什么

第一版暂时不做过度平台化。

```text
1. 不做复杂规范管理平台
2. 不做全量历史代码整改
3. 不追求所有规则自动化扫描
4. 不一次性覆盖所有边缘场景
5. 不强制推翻现有历史实现
6. 不把所有老代码写法都沉淀为规范
```

完整蓝图的重点是：

> **先把“推荐写法、禁止写法、AI 生成规则、Review 检查项”沉淀清楚。**

---

# 二、总体技术架构

## 1. 规范工程总体架构

```text
┌─────────────────────────────────────────────────────────────┐
│                    研发规范输入源                            │
│                                                             │
│  现有代码仓库     Feishu知识库      架构文档      Review经验   │
│  Android/iOS     项目结项报告      技术方案      AI出错案例   │
│  H5/Admin        会议纪要          业务流程      线上问题     │
│  Java/Python     复用说明          模块说明      质量问题     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    规范萃取与治理层                          │
│                                                             │
│  代码事实提取  →  推荐模式识别  →  反例识别  →  人工评审       │
│                                                             │
│  规则分级：P0 强制 / P1 推荐 / P2 建议 / Legacy 历史兼容       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    规范资产仓库                              │
│                                                             │
│  engineering-standards                                      │
│  ├── 全局规范                                                │
│  ├── APP客户端规范                                           │
│  ├── PC客户端规范                                            │
│  ├── 前端规范                                                │
│  ├── 后端规范                                                │
│  ├── AI Coding Rules                                        │
│  ├── Prompt模板                                              │
│  ├── Code Review Checklist                                  │
│  └── 正例 / 反例代码                                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    AI 辅助研发执行层                         │
│                                                             │
│  Cursor / Codex / Claude Code / Copilot / 内部AI平台          │
│                                                             │
│  输入：需求 + 相关代码 + 当前端规范 + 模块规范 + AI Rules      │
│  输出：设计说明 + 代码修改 + 测试用例 + 自检清单               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    质量闭环层                                │
│                                                             │
│  AI自检  →  Code Review  →  Lint/CI  →  问题沉淀  →  规范迭代 │
└─────────────────────────────────────────────────────────────┘
```

---

# 三、Git 工程设计

## 1. 仓库命名

```text
engineering-standards
```

## 2. 仓库定位

```text
部门级研发工程规范仓库，用于沉淀各端开发规范、架构约束、AI Coding Rules、Code Review Checklist、Prompt 模板和工程最佳实践。
```

---

## 3. 完整蓝图目录结构

以下目录是完整形态参考，不是第一期必须一次性交付的范围。第一期最终目录以 [一期方案.md](./一期方案.md) 的轻量结构为准。

```text
engineering-standards/
├── README.md
├── CHANGELOG.md
├── CODEOWNERS
├── CONTRIBUTING.md
├── VERSION.md
│
├── 00-global/
│   ├── 00-standard-positioning.md
│   ├── 01-ai-coding-contract.md
│   ├── 02-common-architecture.md
│   ├── 03-naming-convention.md
│   ├── 04-api-contract.md
│   ├── 05-error-handling.md
│   ├── 06-logging-standard.md
│   ├── 07-testing-standard.md
│   ├── 08-security-standard.md
│   └── 09-review-checklist.md
│
├── 01-app-client/
│   ├── 00-app-client-overview.md
│   ├── 01-kmp-shared-layer-standard.md
│   ├── 02-android-standard.md
│   ├── 03-ios-standard.md
│   ├── 04-data-center-standard.md
│   ├── 05-module-standard.md
│   ├── 06-multi-market-standard.md
│   ├── 07-ui-component-standard.md
│   ├── 08-testing-standard.md
│   ├── 09-performance-standard.md
│   ├── 10-app-ai-rules.md
│   ├── 11-app-review-checklist.md
│   └── examples/
│       ├── kmp/
│       ├── android/
│       ├── ios/
│       ├── data-center/
│       └── multi-market/
│
├── 02-pc-client/
│   ├── 00-pc-client-overview.md
│   ├── 01-mac-standard.md
│   ├── 02-windows-standard.md
│   ├── 03-cross-platform-standard.md
│   ├── 04-platform-adapter-standard.md
│   ├── 05-pc-ai-rules.md
│   ├── 06-pc-review-checklist.md
│   └── examples/
│
├── 03-frontend/
│   ├── 00-frontend-overview.md
│   ├── 01-h5-standard.md
│   ├── 02-admin-standard.md
│   ├── 03-component-standard.md
│   ├── 04-state-management-standard.md
│   ├── 05-api-standard.md
│   ├── 06-frontend-ai-rules.md
│   ├── 07-frontend-review-checklist.md
│   └── examples/
│
├── 04-backend/
│   ├── 00-backend-overview.md
│   ├── 01-java-standard.md
│   ├── 02-python-standard.md
│   ├── 03-api-design-standard.md
│   ├── 04-domain-model-standard.md
│   ├── 05-database-standard.md
│   ├── 06-backend-ai-rules.md
│   ├── 07-backend-review-checklist.md
│   └── examples/
│
├── 05-testing/
│   ├── 01-unit-testing-standard.md
│   ├── 02-integration-testing-standard.md
│   ├── 03-e2e-testing-standard.md
│   ├── 04-ai-generated-test-standard.md
│   └── examples/
│
├── 06-prompts/
│   ├── 01-code-standard-extraction-prompt.md
│   ├── 02-requirement-to-code-prompt.md
│   ├── 03-code-review-prompt.md
│   ├── 04-refactor-prompt.md
│   ├── 05-test-generation-prompt.md
│   └── 06-ai-self-check-prompt.md
│
├── 07-ai-integration/
│   ├── AGENTS.md
│   ├── cursor-rules.md
│   ├── codex-guide.md
│   ├── claude-code-guide.md
│   ├── copilot-guide.md
│   └── context-pack-template.md
│
├── 08-templates/
│   ├── standard-template.md
│   ├── ai-rules-template.md
│   ├── module-standard-template.md
│   ├── review-checklist-template.md
│   ├── positive-example-template.md
│   └── negative-example-template.md
│
└── 09-governance/
    ├── 01-standard-release-process.md
    ├── 02-rule-change-process.md
    ├── 03-ai-error-case-process.md
    ├── 04-owner-and-reviewer.md
    └── 05-metrics.md
```

---

# 四、完整蓝图规范资产设计

完整蓝图需要产出五类核心资产。

```text
1. 人读版规范
2. AI 执行版规则
3. 模块级规范
4. 正反例代码
5. Review Checklist
```

---

## 1. 人读版规范

用于研发人员、新人、架构师阅读。

示例：

```text
01-app-client/02-android-standard.md
04-backend/01-java-standard.md
03-frontend/02-admin-standard.md
```

内容结构统一：

```markdown
# xxx 开发规范

## 1. 适用范围

## 2. 技术栈

## 3. 架构原则

## 4. 推荐目录结构

## 5. 分层职责

## 6. 命名规范

## 7. 数据流转规范

## 8. 异常处理规范

## 9. 日志 / 埋点规范

## 10. 测试规范

## 11. 性能与安全要求

## 12. 禁止事项

## 13. 正例

## 14. 反例

## 15. AI 生成代码要求

## 16. Code Review Checklist
```

---

## 2. AI 执行版规则

用于 AI 工具加载。

示例：

```text
01-app-client/10-app-ai-rules.md
04-backend/06-backend-ai-rules.md
03-frontend/06-frontend-ai-rules.md
```

写法必须更直接：

```markdown
# APP AI Coding Rules

## 1. 你必须遵守

## 2. 你不得生成

## 3. 生成代码前必须检查

## 4. 生成代码时必须遵守

## 5. 生成代码后必须自检

## 6. 当前端特殊规则

## 7. 当前模块特殊规则
```

AI 规则要使用强命令，不写模糊建议。

错误写法：

```text
建议尽量复用已有组件。
```

正确写法：

```text
生成代码前必须检查当前模块是否已有相同组件。
如果已有组件，必须复用。
除非需求明确要求，否则不得新建重复组件。
```

---

## 3. 模块级规范

每个核心业务模块建议都有自己的轻量规范。

例如：

```text
trade/module-standard.md
quote/module-standard.md
account/module-standard.md
user/module-standard.md
order/module-standard.md
```

模板：

```markdown
# 交易模块规范

## 1. 模块职责

## 2. 核心业务流程

## 3. 核心领域对象

## 4. 主要代码目录

## 5. 数据访问入口

## 6. 状态流转

## 7. 异常处理

## 8. 日志 / 埋点

## 9. 多展业地差异

## 10. 可复用能力

## 11. 禁止事项

## 12. AI 生成代码注意事项

## 13. 正例代码路径

## 14. 反例代码路径
```

模块级规范解决的是：

> **AI 不知道代码应该写在哪个模块、调用哪个已有能力的问题。**

---

## 4. 正例与反例

完整蓝图每个端至少沉淀：

```text
3 个正例
3 个反例
```

正例包括：

```text
1. 一个标准页面开发示例
2. 一个标准接口调用示例
3. 一个标准异常 / 状态处理示例
```

反例包括：

```text
1. UI 层直接请求网络
2. 直接使用 DTO 渲染页面
3. 重复实现已有模块能力
4. Controller 直接访问 Mapper
5. 页面中硬编码展业地逻辑
```

正反例格式：

```markdown
# 正例：Android 页面通过 ViewModel 调用 KMP UseCase

## 适用场景

## 推荐原因

## 代码路径

## 核心代码

## AI 学习点

## Review 检查点
```

```markdown
# 反例：Activity 直接发起网络请求

## 问题场景

## 违反规则

## 风险说明

## 错误代码

## 正确改法

## AI 禁止生成说明
```

---

## 5. Review Checklist

每个端独立一份。

例如 APP：

```markdown
# APP Code Review Checklist

## 1. 架构合规

- 是否遵守 KMP + Clean Architecture？
- 可跨端复用逻辑是否下沉 KMP？
- Android / iOS 是否重复实现核心业务规则？
- UI 层是否保持轻量？
- 是否绕过 HSDataCenterKit？

## 2. 数据流合规

- DTO 是否经过 Mapper？
- UI 是否只依赖 UI State / State？
- Repository 是否职责清晰？
- 缓存策略是否明确？

## 3. 多展业地合规

- 差异是否配置化？
- 是否存在硬编码展业地判断？
- 是否影响已有展业地？

## 4. 质量合规

- 是否有异常兜底？
- 是否有必要日志？
- 是否有埋点？
- 是否有测试？
```

---

# 五、规则分级设计

完整蓝图规则必须分级，避免所有规则都一样重要。

## 1. 规则级别

| 级别 | 含义 | 处理方式 |
| --- | --- | --- |
| P0 | 强制规则 | 新代码必须遵守，AI 不得违反 |
| P1 | 推荐规则 | 默认遵守，特殊情况需说明 |
| P2 | 建议规则 | 持续优化，不强制阻断 |
| Legacy | 历史兼容 | 仅解释历史代码，不推荐新代码使用 |
| Forbidden | 禁止规则 | 明确不得生成，不得新增 |

---

## 2. 规则编号

建议使用统一编号。

```text
STD-{端}-{模块}-{级别}-{序号}
```

示例：

```text
STD-APP-KMP-P0-001
STD-APP-ANDROID-P0-002
STD-APP-IOS-P0-003
STD-BE-JAVA-P0-001
STD-FE-ADMIN-P1-004
```

---

## 3. 单条规则模板

```markdown
# STD-APP-KMP-P0-001：跨端业务逻辑必须优先下沉 KMP

## 规则级别
P0 强制

## 适用范围
APP 客户端，Android / iOS 双端共用业务逻辑。

## 规则说明
凡是交易、行情、账户、用户等可跨端复用的业务规则，必须优先放入 KMP commonMain。

## 推荐写法
- 业务规则放入 commonMain/domain/usecase
- Repository 接口放 domain
- Repository 实现放 data
- Android / iOS 只负责状态转换和 UI 渲染

## 禁止写法
- Android 和 iOS 分别重复实现同一套业务规则
- 在 Activity / ViewController 中实现核心业务判断

## AI 生成代码要求
生成代码前必须判断当前逻辑是否可跨端复用。
如果可跨端复用，必须优先生成 KMP commonMain 实现。

## Code Review 检查项
- 是否存在双端重复业务规则？
- 是否应该下沉 KMP？
- 是否误把业务规则写在平台 UI 层？
```

---

# 六、各端规范重点

## 1. APP 客户端规范重点

APP 是完整蓝图的重点，因为你们当前有：

```text
KMP
Android Jetpack MVVM
HSLoadData + BaseVM
iOS ReactorKit
HSDataCenterKit
多展业地配置化
```

APP 重点规则：

```text
1. 可跨端业务逻辑优先下沉 KMP
2. Android / iOS 不得重复实现核心业务规则
3. Android 页面状态通过 ViewModel / UiState 收敛
4. iOS 遵循 ReactorKit Action → Mutation → State
5. 数据访问统一走 Repository / HSDataCenterKit
6. DTO 必须通过 Mapper 转换为 Domain Model
7. UI 不得直接依赖后端 DTO
8. 多展业地差异优先配置化
9. 展业地逻辑不得硬编码在页面层
10. 交易、账户、订单类逻辑必须有异常兜底和日志
```

APP 规范目录：

```text
01-app-client/
├── 00-app-client-overview.md
├── 01-kmp-shared-layer-standard.md
├── 02-android-standard.md
├── 03-ios-standard.md
├── 04-data-center-standard.md
├── 05-module-standard.md
├── 06-multi-market-standard.md
├── 10-app-ai-rules.md
└── 11-app-review-checklist.md
```

---

## 2. 前端规范重点

覆盖 H5 和 Admin。

前端重点：

```text
1. 页面目录结构
2. 组件拆分规则
3. API 请求封装
4. Request / Response 类型定义
5. 状态管理
6. 表单 / 表格 / 弹窗模式
7. 权限控制
8. 国际化
9. 样式规范
10. AI 不得重复造组件
```

前端 AI 规则示例：

```text
1. 不允许在页面组件中直接裸写 request。
2. 新增接口必须定义 Request / Response 类型。
3. 复杂页面必须拆分 page / components / hooks / api / types。
4. 不允许使用 any 绕过类型定义。
5. 不允许重复实现已有公共组件。
```

---

## 3. 后端规范重点

覆盖 Java 和 Python。

Java 重点：

```text
1. Controller / Application / Domain / Infrastructure 分层
2. DTO / Request / Response / Entity / VO 转换
3. Controller 不写业务逻辑
4. Controller 不直接访问 Mapper
5. Service 不直接返回 Entity
6. 事务边界
7. 幂等设计
8. 错误码
9. 日志
10. 单测
```

Python 重点：

```text
1. 包结构
2. 类型注解
3. Service / Repository 分层
4. 配置管理
5. 日志
6. 异常
7. 任务脚本入口
8. 数据模型
9. 测试
10. 依赖管理
```

---

## 4. PC 客户端规范重点

覆盖 Mac / Windows。

PC 重点：

```text
1. 跨平台公共层
2. 平台适配层
3. UI 层
4. 系统能力调用
5. 本地缓存
6. 文件系统
7. IPC / 进程通信
8. 日志
9. 崩溃处理
10. 升级机制
```

PC AI 规则示例：

```text
1. 平台相关能力必须放在 platform adapter 层。
2. 不允许业务层直接调用 macOS / Windows 原生 API。
3. 跨平台逻辑优先写在 common 层。
4. 新增系统能力必须同时说明 Mac / Windows 实现和降级策略。
```

---

# 七、规范萃取流程设计

完整蓝图不是靠架构师凭空写，而是从现有代码中萃取。第一阶段对外只保留一个 `project-standard-extractor` Skill，由它内部编排多个 agent 完成事实提取、端规范生成、行业规范生成、AI Rules、Review Checklist、evidence 写入和分面评审。

## 1. 萃取流程

```text
选择样本代码
    ↓
AI 提取代码事实
    ↓
Evidence / Code Facts / Pattern Classifier 统一证据口径
    ↓
APP / 前端 / 后端 / 行业专项 agent 识别推荐模式 / 反例模式
    ↓
沉淀 draft 规范草稿
    ↓
Evidence / Team Standard / AI Executability / Checklist / Conflict / Industry Risk 分面评审
    ↓
Quality Gate 汇总
    ↓
Merge Coordinator 写入 draft / pending / conflict / legacy-compatible
    ↓
端负责人确认后 draft -> active
```

---

## 2. 每端样本选择标准

每个端至少选择：

```text
1. 2 个高质量业务模块
2. 1 个复杂页面
3. 1 个数据请求模块
4. 1 个异常 / 状态处理模块
5. 1 个历史反例模块
```

APP 端建议选择：

```text
1. 一个交易模块
2. 一个行情模块
3. 一个账户模块
4. 一个配置更新模块
5. 一个多展业地适配模块
```

后端建议选择：

```text
1. 一个核心查询接口
2. 一个核心写操作接口
3. 一个事务类模块
4. 一个 MQ / 定时任务模块
5. 一个历史坏味道模块
```

前端建议选择：

```text
1. 一个标准列表页
2. 一个复杂表单页
3. 一个弹窗 / 抽屉交互页
4. 一个 API 封装模块
5. 一个公共组件模块
```

---

## 3. 代码事实提取 Prompt

放入：

```text
06-prompts/01-code-standard-extraction-prompt.md
```

内容：

```markdown
你是资深研发架构师和代码规范专家。

我会提供当前项目中的真实代码，请你不要直接重构代码，而是从代码中萃取当前团队事实上的开发模式。

请按以下维度分析：

1. 项目目录结构
2. 文件命名规则
3. 类 / 函数 / 变量命名规则
4. 分层架构
5. 模块职责边界
6. 数据流转方式
7. API 调用方式
8. 状态管理方式
9. 异常处理方式
10. 日志 / 埋点方式
11. 测试方式
12. 可复用模式
13. 不一致写法
14. 疑似坏味道
15. 适合沉淀为规范的规则
16. 不建议继续沿用的历史写法

输出要求：

- 先输出代码事实，不要直接下结论。
- 每个结论必须给出代码依据。
- 每条候选规范必须包含：规则、适用范围、正例、反例、AI 生成代码要求、Review 检查项。
- 请特别识别哪些规则适合写入 AI Coding Rules。
```

---

# 八、AI 辅助研发接入方案

## 1. AI Context Pack

每次 AI 辅助开发，统一输入上下文包。

```text
AI Context Pack
├── 需求说明
├── 当前端类型
├── 当前业务模块
├── 相关代码路径
├── 接口文档
├── 设计稿 / 交互说明
├── 全局规范
├── 端规范
├── 模块规范
├── AI Rules
├── 正例代码
├── 禁止事项
└── 自检清单
```

模板文件：

```text
07-ai-integration/context-pack-template.md
```

---

## 2. AI 开发 Prompt 模板

```markdown
你是当前项目的资深研发工程师。

你必须严格遵守以下规范：

1. 全局研发规范：
{global_rules}

2. 当前端开发规范：
{platform_rules}

3. 当前模块规范：
{module_rules}

4. AI Coding Rules：
{ai_rules}

5. 相关代码：
{related_code}

6. 当前需求：
{requirement}

请先输出：

1. 需求归属判断
2. 当前需求涉及哪些模块
3. 哪些能力可以复用
4. 哪些文件需要修改
5. 是否需要新增文件
6. 是否存在架构风险
7. 是否存在多端 / 多展业地影响

然后再输出代码实现方案。

生成代码时必须遵守：

- 不得破坏既有分层
- 不得重复实现已有能力
- 不得绕过公共网络、缓存、日志、配置体系
- 不得让 UI 直接依赖 DTO
- 不得硬编码展业地逻辑
- 不得省略异常处理
- 不得省略必要测试

最后必须输出自检清单。
```

---

## 3. AI 自检模板

```markdown
# AI 生成代码自检结果

## 1. 架构合规

- 是否遵守当前端分层架构：
- 是否复用已有模块能力：
- 是否新增重复逻辑：
- 是否存在跨层调用：

## 2. 数据流合规

- DTO 是否经过转换：
- UI 是否直接依赖后端 DTO：
- 数据访问是否走统一入口：
- 缓存策略是否明确：

## 3. 异常与日志

- 是否处理异常：
- 是否有用户可理解的错误提示：
- 是否有必要日志：
- 是否有兜底逻辑：

## 4. 测试

- 是否补充单测：
- 是否覆盖异常场景：
- 是否覆盖边界条件：

## 5. 风险

- 兼容性风险：
- 性能风险：
- 安全风险：
- 多展业地风险：
- 待人工确认事项：
```

---

# 九、AI 工具接入设计

## 1. 仓库根目录 AGENTS.md

业务代码仓库根目录建议放一个 `AGENTS.md`。

```markdown
# AGENTS.md

你在本仓库中生成代码时，必须遵守部门级研发工程规范。

请按以下顺序读取规范：

1. engineering-standards/00-global/01-ai-coding-contract.md
2. 当前端对应的 AI Rules
3. 当前模块 module-standard.md
4. 当前项目已有代码
5. 当前需求说明

如果规范与用户临时要求冲突，必须先指出冲突，不得直接破坏规范。

生成代码后必须输出自检清单。
```

---

## 2. Cursor 规则

```text
.cursor/rules/
├── global.mdc
├── app-client.mdc
├── backend-java.mdc
├── frontend.mdc
└── testing.mdc
```

第一期可以先手工同步核心规则，后续再脚本化生成。

---

## 3. Codex / Claude Code 接入

建议在业务代码仓库内放：

```text
AGENTS.md
CLAUDE.md
CODEX.md
```

内容都指向统一规范仓库。

```markdown
当前项目必须遵守 engineering-standards 中的规范。
开发 APP 客户端时，优先读取：
- 00-global/01-ai-coding-contract.md
- 01-app-client/10-app-ai-rules.md
- 当前模块 module-standard.md
```

---

# 十、Review 与发布流程

## 1. 规范变更流程

```text
提出规范变更
    ↓
创建 MR
    ↓
端负责人评审
    ↓
高风险规则按需升级架构 / 行业 / 安全负责人确认
    ↓
试运行
    ↓
合入 main
    ↓
更新 CHANGELOG
    ↓
通知各组
```

---

## 2. 分支策略

```text
main              稳定发布版本
develop           规范草稿集成
feature/xxx       单个规范新增
fix/xxx           规范修正
release/v1.0.0    版本发布
```

---

## 3. 版本号

```text
v1.0.0  第一版正式发布
v1.1.0  增加新端或新模块规范
v1.1.1  修正描述或示例
v2.0.0  规范结构重大调整
```

---

## 4. CODEOWNERS

```text
/00-global/        @architecture-team
/01-app-client/    @app-architecture-owner @android-owner @ios-owner
/02-pc-client/     @pc-owner
/03-frontend/      @frontend-owner
/04-backend/       @backend-owner
/06-prompts/       @ai-engineering-owner
/07-ai-integration/ @ai-engineering-owner
```

---

# 十一、完整蓝图实施计划

## 阶段一：规范工程初始化

产出：

```text
1. 创建 engineering-standards 仓库
2. 初始化目录结构
3. 编写 README
4. 编写第一版规范定位
5. 编写统一模板
6. 编写 AI Coding Contract
```

关键文件：

```text
README.md
00-global/00-standard-positioning.md
00-global/01-ai-coding-contract.md
08-templates/
```

---

## 阶段二：各端规范萃取

每个端负责人从现有代码中选择样本。

产出：

```text
1. APP 客户端规范
2. 前端规范
3. 后端规范
4. PC 客户端规范
5. 每端 3 个正例
6. 每端 3 个反例
```

APP 优先级最高。

---

## 阶段三：AI Rules 编写

把人读版规范压缩为 AI 可执行规则。

产出：

```text
1. app-ai-rules.md
2. backend-ai-rules.md
3. frontend-ai-rules.md
4. pc-ai-rules.md
5. ai-self-check-prompt.md
6. requirement-to-code-prompt.md
```

---

## 阶段四：试点接入

选择 2 到 3 个真实需求试点。

建议试点：

```text
1. 一个 APP 页面需求
2. 一个后端接口需求
3. 一个 Admin 页面需求
```

评估 AI 生成质量：

```text
1. 是否放对目录
2. 是否遵守分层
3. 是否复用已有代码
4. 是否生成重复逻辑
5. 是否处理异常
6. 是否通过 Review
7. 是否减少人工返工
```

---

## 阶段五：发布完整版本

发布内容：

```text
1. engineering-standards v1.0.0
2. 各端规范
3. AI Rules
4. Prompt 模板
5. Review Checklist
6. 正反例示例
7. 试点总结
```

---

# 十二、完整蓝图验收标准

## 1. 工程验收

```text
1. Git 仓库创建完成
2. 目录结构完整
3. README 完整
4. 各端规范文件存在
5. AI Rules 文件存在
6. Prompt 模板存在
7. Review Checklist 存在
8. 正反例示例存在
```

---

## 2. 内容验收

```text
1. 每端至少 20 条核心规则
2. 每端至少 10 条 P0 强制规则
3. 每端至少 3 个正例
4. 每端至少 3 个反例
5. 每条核心规则包含 AI 生成要求
6. 每条 P0 规则有 Review 检查项
7. APP 端覆盖 KMP / Android / iOS / HSDataCenterKit / 多展业地
8. 后端覆盖分层 / DTO / 事务 / 异常 / 日志
9. 前端覆盖组件 / API / 状态 / 权限 / 类型
10. PC 覆盖跨平台 / 平台适配 / 系统能力封装
```

---

## 3. AI 试点验收

```text
1. AI 能根据规范判断代码应该放在哪一层
2. AI 能识别是否应复用已有模块
3. AI 能输出修改文件列表
4. AI 能遵守端内状态管理方式
5. AI 能避免 UI 直接请求网络
6. AI 能避免 DTO 直接进入 UI
7. AI 能输出自检清单
8. AI 生成代码经 Review 后严重架构问题明显减少
```

---

# 十三、关键文档样例

## 1. README.md 示例

```markdown
# engineering-standards

部门级研发工程规范仓库。

本仓库用于沉淀：

1. 各端开发规范
2. 架构约束
3. AI Coding Rules
4. Code Review Checklist
5. Prompt 模板
6. 正例 / 反例代码
7. 工程最佳实践

## 使用方式

研发人员在开发新需求前，应阅读对应端规范和模块规范。

AI 工具在生成代码前，应加载：

1. 00-global/01-ai-coding-contract.md
2. 当前端 AI Rules
3. 当前模块 module-standard.md
4. 相关正例代码

## 规范分级

- P0：强制规则
- P1：推荐规则
- P2：建议规则
- Legacy：历史兼容
- Forbidden：禁止规则
```

---

## 2. AI Coding Contract 示例

```markdown
# AI Coding Contract

你是当前项目的资深研发工程师。

你生成代码时必须遵守：

1. 不得破坏既有架构分层。
2. 不得重复实现已有模块能力。
3. 不得绕过公共网络、缓存、日志、配置体系。
4. 不得让 UI 直接依赖后端 DTO。
5. 不得在 Controller / View / Activity / ViewController 中写复杂业务逻辑。
6. 不得硬编码展业地差异。
7. 不得引入未经确认的新依赖。
8. 不得省略异常处理。
9. 不得省略必要测试。
10. 生成代码后必须输出自检清单。
```

---

# 十四、风险与应对

## 风险一：规范太大，团队不愿意看

应对：

```text
1. 人读版可以详细
2. AI Rules 必须短
3. P0 强制规则控制在 10 到 20 条
4. 每端提供一页版 Quick Start
```

---

## 风险二：从历史代码萃取出错误规范

应对：

```text
1. 区分推荐模式和历史兼容模式
2. 所有规则必须经端负责人确认
3. 反例必须明确标注
4. 不把“存在过的写法”等同于“推荐写法”
```

---

## 风险三：AI 仍然不遵守规范

应对：

```text
1. 把规则写成命令式
2. 减少模糊表达
3. 增加正反例
4. 在 Prompt 中要求先判断再编码
5. 每次 AI 出错后沉淀为新规则
```

---

## 风险四：规范无法落地到 Review

应对：

```text
1. 每条 P0 规则都配 Review 检查项
2. PR 模板引用 Checklist
3. 端负责人 Review 时必须引用规则编号
4. 后续逐步接入 Lint / CI
```

---

# 十五、完整蓝图下的可交付清单

如果采用完整蓝图推进，可以参考以下可交付清单；第一期轻量交付以 [一期方案.md](./一期方案.md) 的 `Markdown + Front Matter + Rule ID + rules-index.json + llms.txt` 闭环为准。

```text
engineering-standards/
├── README.md
├── CHANGELOG.md
│
├── 00-global/
│   ├── 00-standard-positioning.md
│   ├── 01-ai-coding-contract.md
│   └── 09-review-checklist.md
│
├── 01-app-client/
│   ├── 00-app-client-overview.md
│   ├── 01-kmp-shared-layer-standard.md
│   ├── 02-android-standard.md
│   ├── 03-ios-standard.md
│   ├── 04-data-center-standard.md
│   ├── 06-multi-market-standard.md
│   ├── 10-app-ai-rules.md
│   └── 11-app-review-checklist.md
│
├── 03-frontend/
│   ├── 00-frontend-overview.md
│   ├── 01-h5-standard.md
│   ├── 02-admin-standard.md
│   ├── 06-frontend-ai-rules.md
│   └── 07-frontend-review-checklist.md
│
├── 04-backend/
│   ├── 00-backend-overview.md
│   ├── 01-java-standard.md
│   ├── 02-python-standard.md
│   ├── 06-backend-ai-rules.md
│   └── 07-backend-review-checklist.md
│
├── 06-prompts/
│   ├── 01-code-standard-extraction-prompt.md
│   ├── 02-requirement-to-code-prompt.md
│   ├── 03-code-review-prompt.md
│   └── 06-ai-self-check-prompt.md
│
└── 08-templates/
    ├── standard-template.md
    ├── ai-rules-template.md
    ├── module-standard-template.md
    └── review-checklist-template.md
```

---

# 十六、最终结论

完整技术方案的核心不是“写规范文档”，而是建设一个可逐步演进的 **AI 辅助研发规范工程**。

它包含：

```text
1. 一个 Git 规范仓库
2. 一套统一目录结构
3. 一套规则分级体系
4. 一套各端开发规范
5. 一套 AI Coding Rules
6. 一套 Prompt 模板
7. 一套正反例机制
8. 一套 Code Review Checklist
9. 一套规范变更流程
10. 一套 AI 出错反哺机制
```

最终目标是：

> **让 AI 从“会写代码”升级为“按团队架构和质量标准写代码”。**
