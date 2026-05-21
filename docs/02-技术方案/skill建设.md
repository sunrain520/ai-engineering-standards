# `project-standard-extractor` Skill 最终完整技术方案

## 一、Skill 定位

Skill 名称：

```text
project-standard-extractor
```

中文名：

```text
项目研发规范自动萃取器
```

核心定位：

> 输入一个或多个真实项目路径、研发域和行业场景，Skill 以 workflow orchestrator 方式调度多个专业 agent，从真实工程实践中萃取团队级规范，并直接写入正式规范目录，初始状态为 `draft`。

第一阶段对外只暴露这一个 Skill，不拆成 APP / 前端 / 后端 / 行业多个入口。它不是简单总结代码，也不是一个单体大 Prompt，而是要完成：

```text
交互式输入引导
→ 任务拆解和 agent 调度
→ 代码事实提取
→ 推荐模式识别
→ 禁止模式识别
→ 历史兼容识别
→ 规范模板补全
→ AI Rules 生成
→ Review Checklist 生成
→ evidence 独立写入
→ 多 agent 分面评审
→ Quality Gate 汇总
→ Merge Coordinator 写入 draft / pending / conflict / legacy-compatible
```

最终目标：

> **把项目中的隐性研发经验，自动沉淀为部门级 engineering-standards 规范资产。**

---

# 二、输入与输出

## 1. 输入参数

第一阶段以交互式引导输入为主，不要求用户一次性填写完整 CLI 参数。推荐输入顺序：

```text
1. project_paths           一个或多个本地项目文件夹路径
2. dev_domain              研发域
3. industry_domain         行业场景
4. target_scope            输出范围
5. sub_domains             技术栈 / 子领域
6. business_modules        业务模块
7. positive_candidates     正例候选路径
8. negative_candidates     反例候选路径
9. legacy_candidates       历史兼容候选路径
10. existing_docs          已有规范、架构文档、Review 记录
11. quality_focus          本次萃取重点
12. output_target          规范写入目标目录
13. confirmation           用户确认启动萃取
```

未来可补 CLI 形态，但 CLI 只是交互式 workflow 的自动化入口，不改变上述信息模型。示例：

```bash
project-standard-extractor run \
  --project-path /Users/team/workspace/order-service \
  --dev-domain java \
  --industry securities \
  --standards-repo-path /Users/team/engineering-standards \
  --output-path /Users/team/engineering-standards/04-backend \
  --mode draft
```

---

## 2. dev_domain 枚举

```text
app-client
kmp
android
ios
frontend
h5
admin
backend
java
python
pc-client
mac
windows
```

推荐理解：

```text
backend = 后端通用分析
java    = backend 通用分析 + Java 专项分析
python  = backend 通用分析 + Python 专项分析

app-client = APP 通用分析
android    = APP 通用分析 + Android 专项分析
ios        = APP 通用分析 + iOS 专项分析
kmp        = APP 通用分析 + KMP 专项分析

frontend = 前端通用分析
h5       = frontend 通用分析 + H5 专项分析
admin    = frontend 通用分析 + Admin 专项分析
```

---

## 3. 输出文件

Skill 直接写入正式规范目录，初始状态为 `draft`。写入时不得覆盖已有 `active`，默认也不得覆盖已有 `draft`；新规则追加为 `draft`，语义相近内容进入 merge suggestions，冲突内容进入 pending conflict。

```text
{domain-output-dir}/
├── overview.md
├── standard.md
├── ai-rules.md
├── review-checklist.md
├── examples/
├── evidence/
│   ├── code-facts.md
│   ├── positive-examples.md
│   ├── forbidden-examples.md
│   └── legacy-compatible.md
├── pending-confirmation.md
├── merge-suggestions.md
└── conflicts.md
```

核心产物说明：

| 文件 / 目录 | 作用 |
| --- | --- |
| `overview.md` | 研发域概览、适用范围、架构目标 |
| `standard.md` | 人读版规范草稿，规则状态初始为 `draft` |
| `ai-rules.md` | AI 执行版规则，标注高风险 draft 提示 |
| `review-checklist.md` | Review 检查清单，引用 Rule ID |
| `examples/` | 正例、反例和历史兼容示例 |
| `evidence/` | 独立证据目录，保存代码事实和真实路径 |
| `pending-confirmation.md` | 证据不足或需负责人确认的规则 |
| `merge-suggestions.md` | 与已有规范语义相近的合并建议 |
| `conflicts.md` | 与已有 active / draft 冲突的规则 |

`rules.generated.json`、`.index/rules-index.json`、`llms.txt` 属于后续索引增强能力，第一阶段只保留兼容设计，不作为主交付。

---

# 三、运行模式

## 1. analyze 模式

只分析项目，不生成规范。

```bash
project-standard-extractor run \
  --project-path ./order-service \
  --dev-domain java \
  --mode analyze
```

输出：

```text
evidence/code-facts.md
pending-confirmation.md
```

适合第一次了解项目。

---

## 2. draft 模式

生成规范草稿。

```bash
project-standard-extractor run \
  --project-path ./order-service \
  --dev-domain java \
  --mode draft
```

输出：

```text
standard.md
ai-rules.md
review-checklist.md
evidence/
merge-suggestions.md
conflicts.md
```

适合各端负责人生成第一版规范。

---

## 3. update 模式

基于已有规范进行补充。

```bash
project-standard-extractor run \
  --project-path ./order-service \
  --dev-domain java \
  --standards-repo-path ./engineering-standards \
  --mode update
```

输出：

```text
merge-suggestions.md
conflicts.md
新增 draft 规则
新增 evidence
```

适合后续迭代规范。

---

## 4. review 模式

检查现有规范与项目代码是否一致。

```bash
project-standard-extractor run \
  --project-path ./order-service \
  --dev-domain java \
  --standards-repo-path ./engineering-standards \
  --mode review
```

输出：

```text
standard-review-report.md
```

用于发现：

```text
代码中有但规范未沉淀的模式
规范中写了但项目没有体现的规则
规范与真实代码冲突的地方
历史代码中的不合规点
draft -> active 前需要补充的证据
```

---

# 四、整体处理流程

```text
输入项目目录 + dev_domain + industry_domain
        ↓
项目文件扫描
        ↓
技术栈识别
        ↓
文件分类与过滤
        ↓
代表性代码样本选择
        ↓
代码事实提取
        ↓
推荐 / 禁止 / 历史模式分类
        ↓
规则候选生成
        ↓
规范模板补全
        ↓
AI Rules 生成
        ↓
Review Checklist 生成
        ↓
evidence 独立写入
        ↓
多 agent 分面评审
        ↓
Quality Gate 汇总
        ↓
Merge Coordinator 写入 draft / pending / conflict / legacy-compatible
```

---

# 五、Skill 内部 agent 设计

第一阶段内部采用混合 agent 模型，保证“证据口径统一 + 领域萃取专业 + 评审分面明确”。

| 类型 | Agent | 职责 |
| --- | --- | --- |
| 通用阶段 | Intake | 交互式引导输入，确认萃取边界 |
| 通用阶段 | Project Profiler | 识别项目类型、技术栈、模块边界 |
| 通用阶段 | Evidence Collector | 收集正例、反例、历史兼容和路径证据 |
| 通用阶段 | Code Facts | 只输出代码事实，不直接生成规范 |
| 通用阶段 | Pattern Classifier | 分类推荐、禁止、历史兼容、待确认模式 |
| 专项生成 | APP / Frontend / Backend Standard | 生成端规范草稿 |
| 专项生成 | Industry Standard | 生成独立行业规范草稿 |
| 专项生成 | AI Rules | 生成 AI 可执行规则 |
| 专项生成 | Review Checklist | 生成人工评审清单 |
| 证据输出 | Evidence Writer | 写入独立 evidence |
| 分面评审 | Evidence Auditor | 检查证据是否真实充分 |
| 分面评审 | Team Standard Reviewer | 检查是否抽象为团队级规范 |
| 分面评审 | AI Executability Reviewer | 检查 AI 是否能执行和自检 |
| 分面评审 | Review Checklist Reviewer | 检查 Review 是否能判断 |
| 分面评审 | Conflict Reviewer | 检查重复和冲突规则 |
| 分面评审 | Industry Risk Reviewer | 检查行业规则是否过度推断 |
| 汇总写入 | Quality Gate | 汇总分面评审结果 |
| 汇总写入 | Merge Coordinator | 写入 draft、pending、conflict、legacy-compatible |

---

# 六、Skill 内部目录结构

```text
project-standard-extractor/
├── SKILL.md
├── README.md
│
├── config/
│   ├── domains.yaml
│   ├── ignore.yaml
│   ├── file-types.yaml
│   └── rule-id.yaml
│
├── analyzers/
│   ├── project-scanner.ts
│   ├── tech-stack-detector.ts
│   ├── file-classifier.ts
│   ├── sample-selector.ts
│   ├── code-facts-extractor.ts
│   ├── document-extractor.ts
│   └── test-extractor.ts
│
├── extractors/
│   ├── backend-extractor.md
│   ├── java-extractor.md
│   ├── python-extractor.md
│   ├── app-client-extractor.md
│   ├── kmp-extractor.md
│   ├── android-extractor.md
│   ├── ios-extractor.md
│   ├── frontend-extractor.md
│   ├── h5-extractor.md
│   └── admin-extractor.md
│
├── prompts/
│   ├── 01-project-profile.md
│   ├── 02-code-facts-extraction.md
│   ├── 03-pattern-classification.md
│   ├── 04-rule-generation.md
│   ├── 05-standard-generation.md
│   ├── 06-ai-rules-generation.md
│   └── 07-review-checklist-generation.md
│
├── templates/
│   ├── standard-template.md
│   ├── ai-rules-template.md
│   ├── review-checklist-template.md
│   ├── rule-template.md
│   └── analysis-report-template.md
│
└── output/
```

---

# 七、文件扫描与过滤

## 1. 默认忽略目录

Skill 必须先排除构建产物、依赖目录和临时文件。

```text
.git/
.idea/
.vscode/
node_modules/
build/
dist/
target/
.gradle/
Pods/
DerivedData/
coverage/
logs/
tmp/
.cache/
```

---

## 2. 默认忽略文件

```text
*.lock
*.min.js
*.map
*.class
*.jar
*.zip
*.tar
*.gz
*.png
*.jpg
*.jpeg
*.gif
*.mp4
*.mov
```

---

## 3. 敏感文件处理

以下文件默认不读取正文，只记录存在：

```text
.env
.env.*
*.keystore
*.jks
*.pem
*.key
secrets.*
credentials.*
local.properties
application-prod.yml
application-prod.yaml
```

原则：

> **Skill 只分析工程结构和规范信息，不采集密钥、Token、证书、账号密码。**

---

# 八、技术栈识别

## 1. Java 后端识别

识别依据：

```text
pom.xml
build.gradle
settings.gradle
src/main/java
@RestController
@Controller
@Service
@Repository
@Mapper
@Entity
DTO / VO / Request / Response
```

识别结果示例：

```json
{
  "domain": "backend",
  "sub_domain": "java",
  "frameworks": ["spring-boot", "mybatis"],
  "build_tools": ["maven"],
  "test_frameworks": ["junit", "mockito"]
}
```

---

## 2. Python 后端识别

识别依据：

```text
pyproject.toml
requirements.txt
setup.py
main.py
app/
routers/
services/
repositories/
schemas/
models/
tests/
FastAPI
Flask
Django
Pydantic
pytest
```

识别结果示例：

```json
{
  "domain": "backend",
  "sub_domain": "python",
  "frameworks": ["fastapi", "pydantic"],
  "test_frameworks": ["pytest"],
  "tools": ["ruff", "mypy"]
}
```

---

## 3. APP 客户端识别

识别依据：

```text
build.gradle
settings.gradle
commonMain
androidMain
iosMain
KMP
ViewModel
LiveData
Flow
ReactorKit
Action
Mutation
State
HSDataCenterKit
```

识别结果示例：

```json
{
  "domain": "app-client",
  "sub_domains": ["kmp", "android", "ios"],
  "frameworks": ["kmp", "jetpack-mvvm", "reactorkit"],
  "data_layer": ["HSDataCenterKit"]
}
```

---

## 4. 前端识别

识别依据：

```text
package.json
vite.config.ts
webpack.config.js
tsconfig.json
src/pages
src/components
src/api
src/store
React
Vue
TypeScript
```

识别结果示例：

```json
{
  "domain": "frontend",
  "sub_domain": "admin",
  "frameworks": ["react", "typescript", "vite"],
  "tools": ["eslint", "prettier"]
}
```

---

# 九、代表性样本选择

Skill 不应该全量读取所有代码，而是自动选择高价值样本。

## 1. 样本选择原则

优先选择：

```text
1. 文件结构完整的模块
2. 调用链清晰的业务闭环
3. 最近维护的代码
4. 命名较规范的代码
5. 有测试覆盖的代码
6. 被多个地方复用的代码
7. 体现核心架构模式的代码
```

---

## 2. 后端 Java 样本

优先选择：

```text
Controller
Service
Repository / Mapper
DTO / VO / Request / Response
Entity
Exception
ErrorCode
Config
Test
```

标准链路：

```text
Controller → Service → Repository / Mapper → Entity
Request → DTO / Command → Domain / Entity → Response
```

---

## 3. Python 样本

优先选择：

```text
router
service
repository
schema
model
client
task
exception
config
tests
```

标准链路：

```text
router → service → repository
Pydantic Schema → Domain Model / ORM Model → Response Schema
```

---

## 4. APP 样本

优先选择：

```text
KMP commonMain/domain
KMP commonMain/data
Repository
UseCase
DTO Mapper
Android ViewModel
Android UiState
iOS Reactor
Action / Mutation / State
HSDataCenterKit 调用
多展业地配置
```

---

## 5. 前端样本

优先选择：

```text
pages
components
hooks / composables
api
types
store
router
permission
i18n
form
table
modal
```

---

# 十、代码事实提取

Skill 第一轮必须先提取事实，不直接生成规范。

## 1. 事实提取维度

```text
1. 目录结构事实
2. 文件命名事实
3. 类 / 函数 / 变量命名事实
4. 分层架构事实
5. 模块职责事实
6. 数据流转事实
7. API 调用事实
8. 状态管理事实
9. 异常处理事实
10. 日志 / 埋点事实
11. 配置管理事实
12. 测试事实
13. 复用模式事实
14. 不一致写法事实
15. 疑似坏味道事实
```

---

## 2. code-facts.md 输出格式

```markdown
# 代码事实提取结果

## 1. 项目画像

- 项目类型：
- 技术栈：
- 构建工具：
- 测试框架：
- 核心模块：

## 2. 目录结构事实

### 事实

项目中后端接口主要位于：

- src/main/java/com/xxx/controller
- src/main/java/com/xxx/service
- src/main/java/com/xxx/mapper
- src/main/java/com/xxx/dto

### 证据

- src/main/java/com/xxx/order/OrderController.java
- src/main/java/com/xxx/order/OrderService.java
- src/main/java/com/xxx/order/OrderMapper.java

### 初步判断

项目采用 Controller / Service / Mapper 分层模式。

## 3. 命名事实

## 4. 分层事实

## 5. 数据流转事实

## 6. 异常处理事实

## 7. 日志事实

## 8. 测试事实

## 9. 不一致点

## 10. 疑似坏味道
```

---

# 十一、模式分类

从代码事实中分类出四种模式。

```text
推荐模式
禁止模式
历史兼容模式
待人工确认模式
```

---

## 1. 推荐模式

符合团队目标、代码质量较高、适合 AI 模仿。

示例：

```text
Controller 只调用 Service
接口返回 Response DTO
ViewModel 统一收敛页面状态
KMP commonMain 承载跨端业务逻辑
前端 API 统一封装在 api 目录
```

---

## 2. 禁止模式

明确不希望 AI 继续生成。

示例：

```text
Controller 直接访问 Mapper
UI 层直接请求网络
DTO 直接进入 UI
页面中硬编码展业地 if/else
前端页面中裸写 request
```

---

## 3. 历史兼容模式

历史代码中存在，但不推荐新代码继续使用。

示例：

```text
旧 Service 直接返回 Entity
旧页面使用多个零散 LiveData
旧 Admin 页面未拆分 components / hooks / api
```

---

## 4. 待人工确认模式

证据不足或团队内部可能存在争议。

示例：

```text
某个模块是否应下沉 KMP
某个业务差异是否应该策略化
某个异常体系是否是推荐规范
```

---

# 十二、规则生成

## 1. 规则生成原则

每条规则必须满足：

```text
1. 来源于真实代码事实
2. 有明确适用范围
3. 有明确推荐写法
4. 有明确禁止写法
5. 有 AI 生成代码要求
6. 有 Code Review 检查项
7. 有规则级别
8. 有 Rule ID
```

---

## 2. 规则模板

```markdown
<a id="STD-BE-JAVA-P0-001"></a>

## STD-BE-JAVA-P0-001：Controller 不得写业务逻辑

### 规则说明

Controller 只负责参数接收、参数校验和结果返回，不得承载复杂业务逻辑。

### 推荐写法

- Controller 接收 Request。
- Controller 调用 Service。
- Controller 返回 Response。
- 复杂业务编排放入 Service。

### 禁止写法

- Controller 直接访问 Mapper。
- Controller 直接操作 Entity。
- Controller 中编写复杂业务判断。

### AI 生成代码要求

1. 生成接口时必须创建 Request / Response。
2. 业务逻辑必须放入 Service。
3. 不得在 Controller 中直接访问 Mapper。
4. 不得直接返回 Entity。

### Code Review 检查项

- Controller 是否存在复杂业务逻辑？
- Controller 是否直接访问 Mapper？
- Controller 是否直接返回 Entity？
```

---

## 3. Rule ID 规则

```text
STD-{DOMAIN}-{SUB_DOMAIN}-{LEVEL}-{NUMBER}
```

示例：

```text
STD-BE-JAVA-P0-001
STD-BE-PY-P0-001
STD-APP-KMP-P0-001
STD-APP-ANDROID-P0-001
STD-FE-ADMIN-P0-001
```

---

# 十三、规则索引增量兼容设计

规则索引增量是后续 AI 快速索引能力，不是第一阶段主交付。第一阶段可先用 Markdown frontmatter、Rule ID 和 evidence 目录承载状态；需要工具化索引时，再生成规则增量 JSON。

```json
{
  "version": "v1.0.0",
  "generated_at": "2026-05-21T00:00:00+08:00",
  "source_project": "order-service",
  "dev_domain": "java",
  "rules": [
    {
      "rule_id": "STD-BE-JAVA-P0-001",
      "title": "Controller 不得写业务逻辑",
      "domain": "backend",
      "sub_domain": "java",
      "level": "P0",
      "source_doc": "04-backend/02-java/java-standard.md",
      "anchor": "#STD-BE-JAVA-P0-001",
      "confidence": "high",
      "evidence_count": 8,
      "evidence_ref": "04-backend/evidence/code-facts.md#STD-BE-JAVA-P0-001",
      "risk_level": "high",
      "review_required": true,
      "tags": [
        "backend",
        "java",
        "controller",
        "service"
      ]
    }
  ]
}
```

规则升级为 `active` 后，再考虑进入：

```text
engineering-standards/.index/rules-index.json
```

---

# 十四、Prompt 链设计

Skill 内部采用多步 Prompt，而不是一轮生成全部内容。

## Prompt 1：项目画像

```markdown
你是资深研发架构师。

请基于以下项目文件索引，识别项目类型、技术栈、主要模块、目录结构和潜在架构模式。

不要生成规范，只输出项目画像。

输出：
1. 项目类型
2. 技术栈
3. 主要模块
4. 主要目录
5. 架构模式推断
6. 需要重点分析的文件
7. 不确定事项
```

---

## Prompt 2：代码事实提取

```markdown
你是代码规范萃取专家。

请基于给定代码片段和文件路径，提取代码事实，不要直接生成规范。

必须输出：
1. 目录结构事实
2. 命名事实
3. 分层事实
4. 数据流事实
5. 状态管理事实
6. 异常处理事实
7. 日志 / 埋点事实
8. 测试事实
9. 复用模式
10. 不一致点
11. 疑似坏味道

每个事实必须带文件路径证据。
```

---

## Prompt 3：模式分类

```markdown
你是研发规范治理专家。

请将代码事实分类为：

1. 推荐模式
2. 禁止模式
3. 历史兼容模式
4. 待人工确认模式

分类时必须说明理由和证据。

禁止把历史代码中存在的写法直接视为推荐规范。
```

---

## Prompt 4：规则生成

```markdown
你是部门级研发规范专家。

请基于推荐模式和禁止模式生成规范规则。

每条规则必须包含：

1. Rule ID
2. 规则标题
3. 规则级别
4. 适用范围
5. 规则说明
6. 推荐写法
7. 禁止写法
8. AI 生成代码要求
9. Code Review 检查项
10. 证据索引
11. 置信度
12. 风险级别

只生成有证据支撑的规则。
```

---

## Prompt 5：规范文档生成

```markdown
你是技术规范文档专家。

请将已确认的规则填充到指定开发端规范模板中。

要求：
1. 保留模板结构
2. 优先填充有证据支撑的内容
3. 对证据不足的部分标记“待人工确认”
4. 不编造项目不存在的技术栈
5. 输出适合团队评审的规范草稿
```

---

## Prompt 6：AI Rules 生成

```markdown
你是 AI Coding Rules 专家。

请将人读版规范压缩为 AI 可执行规则。

要求：
1. 使用命令式表达
2. 使用“必须 / 不得 / 禁止 / 生成前先检查”
3. 不写模糊建议
4. 控制长度
5. 优先保留 P0 和 FORBIDDEN 规则
6. 输出适合 Cursor / Codex / Claude Code 使用的规则文件
```

---

## Prompt 7：Review Checklist 生成

```markdown
你是资深 Code Reviewer。

请基于规范规则生成 Code Review Checklist。

要求：
1. 按架构、数据流、异常、日志、测试、性能、安全分类
2. 每个检查项尽量可判断
3. P0 规则必须有检查项
4. 检查项可以引用 Rule ID
```

---

# 十五、各端专项萃取重点

## 1. Java 后端

重点分析：

```text
Controller / Service / Repository / Mapper 分层
Request / Response / DTO / Entity / VO 转换
事务边界
异常体系
错误码
日志规范
幂等设计
缓存
MQ / 定时任务
测试
```

优先生成规则：

```text
Controller 不得写业务逻辑
Controller 不得直接访问 Mapper
不得直接返回 Entity
接口必须定义 Request / Response
写操作必须考虑事务
状态变更必须考虑幂等
异常必须转换为统一错误码
关键业务流程必须有日志
```

---

## 2. Python 后端

重点分析：

```text
router / service / repository 分层
Pydantic Schema
ORM Model
类型注解
配置管理
异常处理
日志
异步 async / await
任务脚本
pytest
```

优先生成规则：

```text
router 不得写复杂业务逻辑
接口必须使用 Schema 定义入参出参
不得直接返回 ORM Model
核心函数必须有类型注解
外部服务调用必须封装 Client
配置不得硬编码
核心逻辑必须有 pytest
```

---

## 3. APP KMP

重点分析：

```text
commonMain
androidMain
iosMain
domain
data
repository
usecase
dto
mapper
error model
commonTest
```

优先生成规则：

```text
可跨端复用逻辑优先放 commonMain
commonMain 不得依赖平台 UI API
Repository 接口放 domain
Repository 实现放 data
DTO 必须通过 Mapper 转换
核心逻辑必须可单测
```

---

## 4. Android

重点分析：

```text
Activity / Fragment
ViewModel / BaseVM
HSLoadData
UiState
LiveData / Flow
Repository / UseCase 调用
Loading / Error / Empty / Success
```

优先生成规则：

```text
Activity / Fragment 不得直接请求网络
页面状态必须通过 ViewModel 收敛
新增页面必须定义 UiState
必须处理 Loading / Error / Empty / Success
优先复用 BaseVM / HSLoadData
```

---

## 5. iOS

重点分析：

```text
ViewController
ReactorKit
Action
Mutation
State
Service
KMP 调用
Closure weak self
错误展示
```

优先生成规则：

```text
ViewController 只负责 UI 绑定和事件转发
用户行为必须通过 Action
状态变化必须通过 Mutation
页面状态必须由 State 统一表达
不得在 ViewController 中直接请求网络
Closure 必须注意 weak self
```

---

## 6. 前端 H5 / Admin

重点分析：

```text
pages
components
hooks / composables
api
types
store
router
permission
i18n
form
table
modal
```

优先生成规则：

```text
页面不得直接裸写 request
API 必须统一封装
Request / Response 必须定义类型
复杂页面必须拆分 page / components / hooks / api / types
不得使用 any 绕过类型定义
不得重复实现已有公共组件
权限判断必须复用统一权限体系
国际化文案不得硬编码
```

---

# 十六、标准输出文档模板

## 1. standard.md

```markdown
---
doc_id: java-standard
title: Java 后端开发规范草稿
domain: backend
sub_domain: java
doc_type: standard
version: v1.0.0
status: draft
owner: backend-team
tags:
  - backend
  - java
  - ai-coding
---

# Java 后端开发规范草稿

## 1. 适用范围

## 2. 技术栈识别结果

## 3. 项目目录结构

## 4. 分层架构

## 5. 数据流转规范

## 6. 异常处理规范

## 7. 日志规范

## 8. 测试规范

## 9. 禁止事项

## 10. 核心规则

<a id="STD-BE-JAVA-P0-001"></a>

## STD-BE-JAVA-P0-001：Controller 不得写业务逻辑

### 规则说明

### 推荐写法

### 禁止写法

### AI 生成代码要求

### Code Review 检查项

### 证据索引

### 置信度

### 风险级别

## 11. 待人工确认事项
```

---

## 2. ai-rules.md

```markdown
---
doc_id: java-ai-rules
title: Java 后端 AI Coding Rules 草稿
domain: backend
sub_domain: java
doc_type: ai-rules
version: v1.0.0
status: draft
owner: backend-team
tags:
  - backend
  - java
  - ai-coding
---

# Java 后端 AI Coding Rules 草稿

## 1. 生成代码前必须检查

1. 当前需求属于哪个业务模块。
2. 是否已有相同接口或服务能力。
3. 是否需要新增 Request / Response。
4. 是否涉及事务、幂等、异常、日志、测试。

## 2. 你必须遵守

1. Controller 不得写业务逻辑。
2. Controller 不得直接访问 Mapper。
3. 不得直接返回 Entity。
4. 业务逻辑必须放入 Service。
5. 接口必须定义 Request / Response。

## 3. 你不得生成

1. Controller 中直接访问数据库的代码。
2. Controller 中编写复杂业务判断的代码。
3. 直接返回 Entity 给前端的代码。
4. 缺少异常处理和日志的核心流程代码。

## 4. 生成代码后必须自检

必须引用 Rule ID 输出自检结果。
```

---

## 3. review-checklist.md

```markdown
# Java 后端 Code Review Checklist 草稿

## 1. 架构合规

- 是否违反 STD-BE-JAVA-P0-001：Controller 不得写业务逻辑？
- 是否违反 STD-BE-JAVA-P0-002：Controller 不得直接访问 Mapper？
- 是否存在跨层调用？

## 2. 数据流合规

- 是否直接返回 Entity？
- 是否定义 Request / Response？
- DTO 转换是否清晰？

## 3. 异常与日志

- 是否统一异常转换？
- 是否有关键业务日志？
- 是否存在吞异常？

## 4. 测试

- 是否补充单测？
- 是否覆盖异常分支？
- 是否覆盖边界条件？
```

---

# 十七、与 engineering-standards 集成

Skill 直接写入正式规范目录，但所有新增或更新内容初始状态必须是 `draft`。它不得覆盖已有 `active`，默认也不得覆盖已有 `draft`；重复运行只追加新证据、新 draft、合并建议和冲突待确认。

## 1. 推荐状态流转流程

```text
Skill 写入 draft
        ↓
端负责人 Review
        ↓
高风险规则按需升级架构 / 行业 / 安全负责人确认
        ↓
人工调整规则级别和表述
        ↓
通过项 draft -> active
        ↓
未通过项保留 pending / conflict / legacy-compatible / rejected
        ↓
记录 CHANGELOG
```

---

## 2. 合入建议文件

Skill 输出 `merge-suggestions.md`：

```markdown
# 合入建议

## 建议处理文件

- 04-backend/02-java/java-standard.md
- 04-backend/02-java/java-ai-rules.md
- 04-backend/02-java/java-review-checklist.md

## 新增规则

- STD-BE-JAVA-P0-001：Controller 不得写业务逻辑
- STD-BE-JAVA-P0-002：Controller 不得直接访问 Mapper

## 建议人工确认

1. 是否将 Service 分为 ApplicationService / DomainService？
2. 当前项目中的 Legacy Controller 是否标记为历史兼容？
3. 是否将事务规则提升为 P0？
```

---

# 十八、AI 快速索引设计

Skill 生成的规则最终进入：

```text
engineering-standards/.index/rules-index.json
```

AI 使用时按以下流程索引：

```text
用户需求
  ↓
识别 domain / sub_domain / task tags
  ↓
读取 engineering-standards/llms.txt
  ↓
读取 engineering-standards/.index/rules-index.json
  ↓
过滤 P0 / FORBIDDEN 规则
  ↓
加载对应 standard.md 和 ai-rules.md
  ↓
生成 AI Context Pack
  ↓
生成代码
  ↓
引用 Rule ID 自检
```

---

# 十九、质量控制机制

## 1. 规则置信度

Skill 生成规则时必须给置信度。

```text
high      多处代码一致，且有文档或测试支撑
medium    有代码证据，但样本较少
low       推断成分较高，必须人工确认
```

---

## 2. 规则准入标准

进入正式规范前建议满足：

```text
P0 规则：
- 至少有明确正向代码证据，或明确反例证据
- 具备 AI 生成代码要求
- 具备 Code Review 检查项

P1 规则：
- 至少有一个代码或文档证据
- 适合团队默认遵守

LEGACY：
- 历史代码存在
- 不推荐新代码继续使用

FORBIDDEN：
- 已确认会破坏架构或质量
- AI 不得生成
```

---

## 3. 防止误判

Skill 必须遵守：

```text
1. 不把历史代码默认当成推荐规范。
2. 不把少量偶然写法提升为 P0。
3. 不编造项目不存在的技术栈。
4. 不把行业通用最佳实践强行套进项目。
5. 证据不足时标记为“待人工确认”。
```

---

# 二十、V1 最小实现范围

第一版 Skill 只需要实现：

```text
1. 本地目录扫描
2. 文件过滤
3. 技术栈识别
4. 样本选择
5. 代码事实提取
6. 模式分类
7. 规范草稿写入 draft
8. AI Rules 生成
9. Review Checklist 生成
10. evidence 独立写入
11. 多 agent 分面评审
12. Quality Gate 汇总和 Merge Coordinator 写入
```

第一版不做：

```text
1. 完整 AST 依赖图
2. 自动 MR
3. 自动覆盖 active 规范
4. 向量数据库
5. 规范平台
6. 复杂 CI
7. 全量代码质量扫描
```

---

# 二十一、V2 演进方向

V1 稳定后，再考虑：

```text
1. AST 级别依赖分析
2. 规则与代码一致性扫描
3. 自动生成 standard.patch.md
4. 自动创建 MR
5. 自动生成 rules-index.json 合入补丁
6. 接入 CI
7. 接入向量库检索正反例
8. 生成项目级 AGENTS.md
9. 生成 Cursor / Codex / Claude Code 规则文件
10. 规范覆盖率分析
```

---

# 二十二、最终效果

以 Java 后端项目为例，Skill 跑完后能输出：

```text
识别到：
- 项目是 Java Spring Boot 后端
- 使用 Controller / Service / Mapper 分层
- 接口存在 Request / Response
- 部分老接口直接返回 Entity
- 异常体系存在统一 ErrorCode
- 单测覆盖不足

生成：
- Java 后端开发规范草稿
- Java AI Coding Rules 草稿
- Java Code Review Checklist 草稿
- 推荐规则：
  - Controller 不得写业务逻辑
  - Controller 不得直接访问 Mapper
  - 不得直接返回 Entity
  - 接口必须定义 Request / Response
- 历史兼容：
  - 老接口直接返回 Entity
- 待人工确认：
  - 是否强制所有写操作补充幂等键
```

以 APP 项目为例，Skill 跑完后能输出：

```text
识别到：
- 项目使用 KMP
- Android 使用 ViewModel / BaseVM / HSLoadData
- iOS 使用 ReactorKit
- 数据访问存在 HSDataCenterKit
- 部分业务逻辑已下沉 commonMain
- 部分页面存在平台重复实现

生成：
- APP 客户端规范草稿
- KMP 共享层规则
- Android AI Rules
- iOS AI Rules
- 数据中台规范建议
- 多展业地配置化规则建议
```

---

# 二十三、最终结论

`project-standard-extractor` Skill 的最终设计是：

```text
输入：
一个或多个项目本地文件夹 + 研发域 + 行业场景

处理：
交互式引导 → 扫描项目 → 识别技术栈 → 选择样本 → 提取代码事实 → 分类模式 → 生成规则 → 分面评审 → 写入 draft

输出：
规范草稿 + AI Rules + Review Checklist + evidence + merge suggestions + conflicts
```

它和 `engineering-standards` 的关系是：

```text
project-standard-extractor 负责从项目中萃取规范
engineering-standards 负责沉淀和发布规范
rules-index.json 负责让 AI 快速索引规范
llms.txt 负责让 AI 找到规范入口
```

一句话总结：

> **这个 Skill 是 engineering-standards 的规范生产工具，用来把真实项目代码中的优秀实践，自动转化为 AI 可执行、团队可维护、Review 可引用的研发规范资产。**
