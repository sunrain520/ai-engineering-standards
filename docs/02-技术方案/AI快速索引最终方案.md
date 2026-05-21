# AI 如何快速索引 engineering-standards

核心思路是：

> **不要让 AI 每次全文扫描所有 Markdown，而是让 AI 先读入口文件，再查规则索引，最后只加载当前任务相关规范。**

第一版推荐采用：

```text
llms.txt
+ rules-index.json
+ AI Rules
+ 当前端 standard.md
+ 当前模块 module-standard.md
```

---

# 一、AI 快速索引的核心流程

AI 每次处理需求时，按下面流程走。

```text
用户需求
  ↓
识别研发域：app-client / frontend / backend / pc-client
  ↓
识别技术栈：java / python / android / ios / kmp / h5 / admin
  ↓
读取 llms.txt 找到规范入口
  ↓
读取 .index/rules-index.json
  ↓
按 domain / sub_domain / level / tags 过滤规则
  ↓
加载对应 standard.md 和 ai-rules.md
  ↓
生成代码
  ↓
自检时引用 Rule ID
```

一句话：

> **llms.txt 负责告诉 AI 去哪里找，rules-index.json 负责告诉 AI 哪些规则相关。**

---

# 二、AI 不应该怎么做

不要这样做：

```text
AI 每次把整个 engineering-standards 仓库全部读一遍
```

问题是：

```text
1. 上下文太大
2. 读取慢
3. 规则容易互相干扰
4. 当前任务不需要的规范会污染判断
5. AI 不知道哪些规则优先级最高
```

正确方式是：

```text
只加载当前任务相关的最小规范集
```

---

# 三、AI 快速索引依赖的两个关键文件

## 1. llms.txt：AI 入口地图

`llms.txt` 是 AI 的入口文件。

它告诉 AI：

```text
当前仓库是什么
有哪些规范域
每个端应该优先读哪些文件
不同任务应该加载哪些规范
```

示例：

```markdown
# engineering-standards

部门级研发工程规范仓库。

AI 生成代码前，应优先读取：

1. 00-global/01-ai-coding-contract.md
2. 当前研发领域 overview
3. 当前技术栈 standard
4. 当前技术栈 ai-rules
5. 当前模块 module-standard.md

## Backend

- 04-backend/00-backend-overview.md
- 04-backend/01-backend-common-standard.md
- 04-backend/02-java/java-standard.md
- 04-backend/02-java/java-ai-rules.md
- 04-backend/03-python/python-standard.md
- 04-backend/03-python/python-ai-rules.md

## APP Client

- 01-app-client/00-app-client-overview.md
- 01-app-client/01-kmp/kmp-standard.md
- 01-app-client/01-kmp/kmp-ai-rules.md
- 01-app-client/02-android/android-standard.md
- 01-app-client/02-android/android-ai-rules.md
- 01-app-client/03-ios/ios-standard.md
- 01-app-client/03-ios/ios-ai-rules.md

## Index

- .index/rules-index.json
```

作用：

```text
llms.txt = AI 规范仓库导航页
```

---

## 2. rules-index.json：规则索引表

`rules-index.json` 是 AI 快速检索规则的核心。

示例：

```json
{
  "version": "v1.0.0",
  "generated_at": "2026-05-21T00:00:00+08:00",
  "rules": [
    {
      "rule_id": "STD-BE-JAVA-P0-001",
      "title": "Controller 不得写业务逻辑",
      "domain": "backend",
      "sub_domain": "java",
      "level": "P0",
      "source_doc": "04-backend/02-java/java-standard.md",
      "anchor": "#STD-BE-JAVA-P0-001",
      "tags": [
        "backend",
        "java",
        "controller",
        "service"
      ]
    },
    {
      "rule_id": "STD-APP-ANDROID-P0-001",
      "title": "Activity 和 Fragment 不得直接发起网络请求",
      "domain": "app-client",
      "sub_domain": "android",
      "level": "P0",
      "source_doc": "01-app-client/02-android/android-standard.md",
      "anchor": "#STD-APP-ANDROID-P0-001",
      "tags": [
        "app",
        "android",
        "network",
        "viewmodel"
      ]
    }
  ]
}
```

作用：

```text
rules-index.json = AI 规则检索表
```

---

# 四、AI 索引时的匹配条件

AI 应该按五类条件过滤规则。

## 1. 按研发域过滤

例如用户说：

```text
新增一个 Java 后端接口
```

AI 判断：

```json
{
  "domain": "backend"
}
```

---

## 2. 按技术栈过滤

继续判断：

```json
{
  "sub_domain": "java"
}
```

---

## 3. 按规则级别过滤

优先加载：

```json
{
  "level": ["P0", "FORBIDDEN"]
}
```

第一版建议 AI 默认只强加载：

```text
P0 强制规则
FORBIDDEN 禁止规则
```

P1 / P2 可以按需加载。

---

## 4. 按任务标签过滤

例如新增接口，匹配：

```json
{
  "tags": ["api", "controller", "dto", "service"]
}
```

例如 Android 页面开发，匹配：

```json
{
  "tags": ["android", "viewmodel", "ui-state", "network"]
}
```

## 5. 任务类型与标签词表

V1 使用固定标签词表，避免 AI 临时发明同义标签导致规则无法命中。

| task_type | 推荐 tags |
| --- | --- |
| api-development | `api`, `controller`, `service`, `dto`, `error-code`, `logging` |
| write-operation | `api`, `transaction`, `idempotency`, `error-code`, `logging`, `test` |
| page-development | `page`, `component`, `state`, `api`, `error-handling`, `i18n` |
| android-page | `android`, `viewmodel`, `ui-state`, `network`, `data-center` |
| ios-page | `ios`, `reactorkit`, `action`, `mutation`, `state`, `network` |
| kmp-shared-logic | `kmp`, `commonMain`, `repository`, `usecase`, `mapper`, `test` |
| frontend-form | `frontend`, `form`, `validation`, `api`, `types`, `i18n` |
| frontend-table | `frontend`, `table`, `api`, `types`, `permission`, `component` |

同义词统一规则：

```text
request / http / fetch → api
vm / view-model → viewmodel
uiState / ui_state → ui-state
dto / response / request → dto
error / exception → error-handling
auth / permission / acl → permission
```

---

# 五、AI 快速索引算法

可以设计成这个逻辑。

```text
输入：用户需求 + 开发端 dev_domain + 项目代码路径

Step 1：识别任务类型
- 是 APP？
- 是后端？
- 是前端？
- 是 PC？

Step 2：识别技术栈
- Java / Python？
- Android / iOS / KMP？
- H5 / Admin？

Step 3：读取 llms.txt
- 找到对应规范入口文件

Step 4：读取 rules-index.json
- 过滤 domain
- 过滤 sub_domain
- 优先过滤 P0 / FORBIDDEN
- 根据任务关键词匹配 tags

Step 5：加载规范文件
- global ai-coding-contract
- 当前领域 overview
- 当前技术栈 standard
- 当前技术栈 ai-rules
- 命中的规则 source_doc

Step 6：构造 AI Context Pack
- 需求说明
- 相关代码
- 命中规则
- 必读规范
- 禁止事项
- 自检要求

Step 7：生成代码并自检
- 自检必须引用 Rule ID
```

---

# 六、Java 后端示例

用户需求：

```text
帮我新增一个订单查询接口
```

AI 判断：

```json
{
  "domain": "backend",
  "sub_domain": "java",
  "task": "api-development",
  "tags": ["api", "controller", "service", "dto"]
}
```

AI 从 `rules-index.json` 命中：

```text
STD-BE-JAVA-P0-001：Controller 不得写业务逻辑
STD-BE-JAVA-P0-002：Controller 不得直接访问 Mapper
STD-BE-JAVA-P0-003：不得直接返回 Entity
STD-BE-API-P0-001：接口必须定义 Request / Response
STD-BE-JAVA-P0-004：异常必须转换为统一错误码
```

AI 加载：

```text
00-global/01-ai-coding-contract.md
04-backend/00-backend-overview.md
04-backend/01-backend-common-standard.md
04-backend/02-java/java-standard.md
04-backend/02-java/java-ai-rules.md
04-backend/04-api-design/api-design-standard.md
```

AI 生成代码前先输出：

```markdown
## 需求归属判断

- 研发域：backend
- 技术栈：java
- 任务类型：新增后端接口
- 涉及模块：order

## 命中规则

- STD-BE-JAVA-P0-001：Controller 不得写业务逻辑
- STD-BE-JAVA-P0-002：Controller 不得直接访问 Mapper
- STD-BE-JAVA-P0-003：不得直接返回 Entity
- STD-BE-API-P0-001：接口必须定义 Request / Response
```

---

# 七、Android 示例

用户需求：

```text
帮我实现订单详情页
```

AI 判断：

```json
{
  "domain": "app-client",
  "sub_domain": "android",
  "task": "page-development",
  "tags": ["android", "viewmodel", "ui-state", "network", "data-center"]
}
```

AI 命中规则：

```text
STD-APP-ANDROID-P0-001：Activity 和 Fragment 不得直接发起网络请求
STD-APP-ANDROID-P0-002：页面状态必须通过 ViewModel 收敛
STD-APP-ANDROID-P0-003：新增页面必须处理 Loading / Error / Empty / Success
STD-APP-KMP-P0-001：可跨端复用逻辑优先下沉 KMP
STD-APP-DATA-P0-001：数据访问必须通过 Repository / HSDataCenterKit
```

AI 加载：

```text
00-global/01-ai-coding-contract.md
01-app-client/00-app-client-overview.md
01-app-client/02-android/android-standard.md
01-app-client/02-android/android-ai-rules.md
01-app-client/01-kmp/kmp-standard.md
01-app-client/04-data-center/data-center-standard.md
```

AI 生成前先判断：

```markdown
## 架构归属判断

- UI 渲染：Android Activity / Fragment
- 状态管理：ViewModel / UiState
- 数据访问：Repository / HSDataCenterKit
- 可复用业务逻辑：优先判断是否应下沉 KMP
```

---

# 八、AI Context Pack 模板

AI 快速索引完成后，最终应该形成一个上下文包。

```markdown
# AI Context Pack

## 1. 当前需求

{用户需求}

## 2. 任务识别

- domain: backend
- sub_domain: java
- task_type: api-development
- module: order

## 3. 必须遵守的规则

- STD-BE-JAVA-P0-001：Controller 不得写业务逻辑
- STD-BE-JAVA-P0-002：Controller 不得直接访问 Mapper
- STD-BE-JAVA-P0-003：不得直接返回 Entity
- STD-BE-API-P0-001：接口必须定义 Request / Response

## 4. 必须加载的规范

- 00-global/01-ai-coding-contract.md
- 04-backend/01-backend-common-standard.md
- 04-backend/02-java/java-standard.md
- 04-backend/02-java/java-ai-rules.md

## 5. 相关代码路径

{相关代码路径}

## 6. 生成代码要求

- 必须遵守命中规则
- 必须优先复用已有代码
- 必须输出修改文件列表
- 必须输出自检结果

## 7. 自检要求

生成代码后必须引用 Rule ID 完成自检。
```

---

# 九、业务代码仓库里如何接入

在每个业务项目根目录放一个 `AGENTS.md`。

```markdown
# AGENTS.md

本项目使用部门级研发规范仓库：

engineering-standards

AI 生成代码前必须：

1. 读取 engineering-standards/llms.txt
2. 根据当前任务识别 domain 和 sub_domain
3. 查询 engineering-standards/.index/rules-index.json
4. 加载 P0 和 FORBIDDEN 规则
5. 加载当前技术栈 standard.md 和 ai-rules.md
6. 生成代码后引用 Rule ID 输出自检结果

禁止：

- 不读取规范直接生成代码
- 违反 P0 规则
- 生成 FORBIDDEN 规则禁止的代码
```

这样 Cursor、Codex、Claude Code 这类工具进入项目后，会先看到项目级规则。

---

# 十、AI 快速索引的最小实现

第一版不需要复杂搜索系统。

只需要三个文件：

```text
llms.txt
.index/rules-index.json
AGENTS.md
```

其中：

```text
llms.txt：规范仓库入口
rules-index.json：规则索引
AGENTS.md：业务仓库接入说明
```

---

# 十一、rules-index.json 如何帮助 AI

AI 可以用它做四件事。

## 1. 快速过滤

不用全文读所有规范。

```json
{
  "domain": "backend",
  "sub_domain": "java",
  "level": "P0"
}
```

---

## 2. 快速定位文档

每条规则都有来源文件：

```json
{
  "source_doc": "04-backend/02-java/java-standard.md"
}
```

AI 可以直接加载相关文档。

---

## 3. 快速引用规则

Code Review 或 AI 自检可以引用：

```text
违反 STD-BE-JAVA-P0-001：Controller 不得写业务逻辑
```

---

## 4. 快速生成自检清单

AI 可以根据命中的 P0 规则生成自检项。

例如：

```markdown
## 自检结果

- STD-BE-JAVA-P0-001：Controller 不得写业务逻辑
  结果：已遵守，Controller 仅负责参数接收和返回。

- STD-BE-JAVA-P0-002：Controller 不得直接访问 Mapper
  结果：已遵守，数据访问通过 Service / Repository 完成。

- STD-BE-JAVA-P0-003：不得直接返回 Entity
  结果：已遵守，接口返回 Response DTO。
```

---

# 十二、是否需要向量库？

第一版不需要。

原因：

```text
1. 规范数量还不大
2. 目录结构清晰
3. rules-index.json 已经能解决精准索引
4. AI 开发更需要确定性规则，不是模糊相似搜索
5. 向量库会增加部署和维护成本
```

什么时候考虑向量库？

```text
1. 规范超过数百篇
2. 正反例代码非常多
3. 需要自然语言问答式检索
4. 多项目、多部门共用规范
5. 需要结合代码库自动召回示例
```

所以 V1：

```text
不用向量库
```

V2 / V3 再考虑。

---

# 十三、AI 快速索引最终方案

最终可以定义为：

```text
AI 快速索引 = llms.txt 入口导航 + rules-index.json 精准过滤 + standard.md / ai-rules.md 最小加载 + Rule ID 自检引用
```

完整链路：

```text
需求输入
  ↓
识别 domain / sub_domain / task tags
  ↓
读取 llms.txt
  ↓
过滤 rules-index.json
  ↓
加载 P0 / FORBIDDEN 规则
  ↓
加载相关 standard.md / ai-rules.md
  ↓
生成 AI Context Pack
  ↓
生成代码
  ↓
引用 Rule ID 自检
```

一句话总结：

> **AI 快速索引不是靠全文阅读，而是靠“任务识别 + 规则索引 + 最小规范加载 + Rule ID 自检”形成高效闭环。**
