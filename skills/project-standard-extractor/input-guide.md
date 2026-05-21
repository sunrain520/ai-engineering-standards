# 交互式输入引导

本文件定义 `project-standard-extractor` 的输入顺序。目标是让用户用最少输入启动萃取，同时把完整项目 / 完整仓库 / 多服务路径先压缩为可执行 batch，避免 AI 写出泛化规范。

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
- 完整仓库、多服务、未知域或 broad scope 默认进入 `profile-first`。

### Step 2：萃取模式

可选，未提供时由 Skill 推断。

```text
extraction_mode: profile-first
```

可选值：

- `profile-first`：只输出项目画像、extraction map、batch plan 和代表性文件候选，不生成正式规范规则。
- `batch-extraction`：用户已选择一个 batch，允许读取该 batch 的代表性 evidence 并生成规范候选。
- `focused-module`：用户输入已经是模块级窄范围，可跳过 broad profile，但仍要记录上下文预算。
- `review-only`：只评审已有萃取产物。
- `merge-only`：只做 append-only 合并。

默认规则：

- 完整项目 / 完整仓库 / 多服务 / 多端 / 未知域 / broad scope → `profile-first`。
- 已提供 `selected_batch` → `batch-extraction`。
- 单模块、单任务、明确技术栈且范围很小 → 可选 `focused-module`。

### Step 3：研发域

推荐从代码结构推断，再让用户确认。

可选值：

- APP
- PC
- Frontend
- Backend
- Industry
- Cross-domain

### Step 4：行业场景

行业不是第一输入项，先由项目和研发域推断，再确认是否生成独立行业规范。

可选值：

- none
- securities
- credit
- banking
- payment
- insurance
- other

### Step 5：输出范围

可选值：

- profile only
- extraction map only
- batch plan only
- standard only
- ai-rules only
- review-checklist only
- evidence only
- fast-index candidates only
- full package

默认：

- `profile-first`：`profile only` + `extraction map only` + `batch plan only`
- `batch-extraction` / `focused-module`：`full package`

### Step 6：子领域

按研发域选择：

- APP：KMP、Android、iOS、DataCenter、多展业地、UI、Testing、Performance。
- PC：Electron、Desktop UI、IPC、local storage、update、performance。
- Frontend：H5、Admin、components、API、state、permission、types。
- Backend：Java、Python、API、database、cache、MQ、jobs。
- Industry：securities、credit、banking、risk、compliance。

### Step 7：业务模块

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

### Step 8：选定 batch

`batch-extraction` 必填。来自上一轮 `batch-plan`。

```yaml
selected_batch:
  batch_id: backend-java-api-order
  source_batch_plan: engineering-standards/04-backend/20260521-180000-backend-batch-plan.md
```

要求：

- 一次正式萃取只能选择一个 batch。
- 如果 batch 没有代表性文件候选，保持 `pending-confirmation` / `skipped`，不得生成规则。
- 如需处理多个 batch，分多次运行。

### Step 9：正反例候选

可选。用户可以提供推荐代码路径、反例路径或历史兼容路径。未提供时，Skill 只能从选定 batch 的代表性文件候选中识别。

### Step 10：已有规范或文档

可选。用于避免重复生成和识别已有 `active` 规则。

### Step 11：质量关注点

可选：

- 架构分层
- 数据模型
- 状态管理
- 复用边界
- 安全合规
- 性能稳定性
- 测试
- AI 生成质量
- 上下文治理
- 快速索引命中质量

### Step 12：输出目标

默认写入 `engineering-standards/` 对应目录。也可指定只输出到草稿目录或对话中。

profile-first 产物默认写入：

- `{domain}/{run_id}-project-profile.md`
- `{domain}/{run_id}-extraction-map.md`
- `{domain}/{run_id}-batch-plan.md`

fast-index 候选产物默认写入：

- `{domain}/{run_id}-rules-index-candidate.json`
- `{domain}/{run_id}-llms-candidate.txt`
- `{domain}/{run_id}-ai-context-pack.md`

### Step 13：确认声明

写入前需要确认：

```text
我确认这些路径可用于规范萃取；完整或大范围输入先进入 profile-first；正式萃取只处理选定 batch；敏感配置只允许脱敏记录；生成结果只能作为 draft 或 pending-confirmation，active 需要负责人确认。
```

## 2. 自动推断规则

| 信号 | 推断 |
| --- | --- |
| `build.gradle.kts`、`commonMain`、`androidMain`、`iosMain` | APP / KMP |
| `package.json`、`src/components`、`vite`、`next` | Frontend |
| `pom.xml`、`build.gradle`、`src/main/java` | Backend / Java |
| `requirements.txt`、`pyproject.toml`、`src/*.py` | Backend / Python |
| `electron`、`ipcMain`、`ipcRenderer`、`desktop` | PC |
| `trade`、`quote`、`account`、`order` | 证券或交易相关业务模块 |

自动推断只能作为候选，不能替代用户确认。

## 3. batch 选择提示

当 `profile-first` 完成后，Skill 应展示 batch plan 摘要并要求用户选择：

```text
可选 batch:
1. backend-java-api-order — 订单 API / Controller / Service / DTO
2. backend-java-database-order — 订单数据库访问 / transaction / mapper
3. industry-securities-order — 证券订单行业规则候选
```

用户选择一个 batch 后，下一轮才进入 `batch-extraction`。
