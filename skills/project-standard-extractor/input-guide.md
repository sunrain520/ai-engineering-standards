# 交互式输入引导

本文件定义 `project-standard-extractor` 的输入顺序。目标是让用户用最少输入启动萃取，同时保留足够上下文避免 AI 写出泛化规范。

## 1. 输入顺序

### Step 1：项目路径

必填。

```text
project_paths:
- /path/to/project-a
- /path/to/project-b
```

要求：

- 可以是仓库根目录、模块目录或服务目录。
- 多项目输入用于提炼团队共性。
- 路径内敏感配置只记录存在事实。

### Step 2：研发域

推荐从代码结构推断，再让用户确认。

可选值：

- APP
- PC
- Frontend
- Backend
- Industry
- Cross-domain

### Step 3：行业场景

行业不是第一输入项，先由项目和研发域推断，再确认是否生成独立行业规范。

可选值：

- none
- securities
- credit
- banking
- payment
- insurance
- other

### Step 4：输出范围

可选值：

- standard only
- ai-rules only
- review-checklist only
- evidence only
- full package

默认：`full package`。

### Step 5：子领域

按研发域选择：

- APP：KMP、Android、iOS、DataCenter、多展业地、UI、Testing、Performance。
- Frontend：H5、Admin、components、API、state、permission、types。
- Backend：Java、Python、API、database、cache、MQ、jobs。
- Industry：securities、credit、banking、risk、compliance。

### Step 6：业务模块

例如：

- 交易
- 行情
- 用户
- 账户
- 搜索
- 推送
- 配置
- 订单
- 风控

### Step 7：正反例候选

可选。用户可以提供推荐代码路径、反例路径或历史兼容路径。未提供时，Skill 从代码事实中识别候选。

### Step 8：已有规范或文档

可选。用于避免重复生成和识别已有 `active` 规则。

### Step 9：质量关注点

可选：

- 架构分层
- 数据模型
- 状态管理
- 复用边界
- 安全合规
- 性能稳定性
- 测试
- AI 生成质量

### Step 10：输出目标

默认写入 `engineering-standards/` 对应目录。也可指定只输出到草稿目录或对话中。

### Step 11：确认声明

写入前需要确认：

```text
我确认这些路径可用于规范萃取；敏感配置只允许脱敏记录；生成结果只能作为 draft 或 pending-confirmation，active 需要负责人确认。
```

## 2. 自动推断规则

| 信号 | 推断 |
| --- | --- |
| `build.gradle.kts`、`commonMain`、`androidMain`、`iosMain` | APP / KMP |
| `package.json`、`src/components`、`vite`、`next` | Frontend |
| `pom.xml`、`build.gradle`、`src/main/java` | Backend / Java |
| `requirements.txt`、`pyproject.toml`、`src/*.py` | Backend / Python |
| `trade`、`quote`、`account`、`order` | 证券或交易相关业务模块 |

自动推断只能作为候选，不能替代用户确认。
