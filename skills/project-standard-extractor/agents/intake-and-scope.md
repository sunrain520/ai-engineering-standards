# Intake And Scope Contract

## 角色目标

用最少交互收集可执行输入，确认萃取范围、`extraction_mode`、输出目标、敏感文件策略和用户确认声明。广范围输入必须先转成 `profile-first`，不直接进入规则生成。

> 上游：用户输入 / 调用方参数。下游：Project Profile 阶段（如果 broad）或 Batch 选择阶段（如果 focused）。

## 输入

- 用户提供的 `project_paths`（必填，至少 1 个本地可读路径）。
- 可选：研发域、行业场景、业务模块、已有文档、`extraction_mode`、`selected_batch.batch_id`。
- 当前规范仓库目录（用于检测重复 / 冲突基线）。
- `config/context-governance.md`、`config/extraction-batch-policy.md`、`config/output-targets.md`。

## 输出（Handoff Schema）

```yaml
scope_summary:
  run_id: "{YYYYMMDD-HHMMSS-{primary_domain}}"
  project_paths: []                       # 必填，去重后的绝对路径
  extraction_mode: profile-first          # profile-first | batch-extraction | focused-module | review-only | merge-only
  dev_domains: []                         # app-client | frontend | backend | pc | industry
  industry_domains: []
  output_scope: full-package              # full-package | single-domain | single-sub-domain
  sub_domains: []
  business_modules: []
  existing_docs: []                       # 现有 active/draft 文件清单（如有）
  quality_focus: []                       # 用户关注的质量维度
  output_targets: []                      # 目标 domain 目录列表
  broad_input: false
  selected_batch: null                    # batch-extraction 模式下必填
  sensitive_file_policy: sanitized-existence-only
  confirmation: false
  inferred_decisions: []                  # 推断项 + 推断依据 + 是否已被用户确认
  open_questions: []                      # 阻塞执行的待确认项
  scope_conflicts: []                     # 推断与用户输入冲突项
```

## 执行步骤

### Step 1 — 路径与可读性校验

1. 对每个 `project_path` 检查存在性、可读性、是否在用户授权范围。
2. 路径不可读或为空：抛出 `NO_VALID_PROJECT_PATHS`，停止。
3. 路径去重，记录每个路径的顶层目录名、是否包含 `.git`、是否包含多服务子目录。

### Step 2 — 输入规模与广范围判定

按以下任一条件判定 `broad_input = true`：

1. 任一路径为 git 仓库根（含 `.git/`）。
2. 任一路径下存在 ≥ 2 个独立 manifest（`package.json` / `pom.xml` / `build.gradle.kts` / `Cargo.toml` / `go.mod` 等）。
3. 路径数量 ≥ 2 且分别属于不同研发域信号集（见 `config/domain-sampling-adapters.md`）。
4. 用户文字明示 "完整项目 / 全仓 / 多服务 / 整个 repo / 整个项目"。
5. 用户未指定研发域、子领域或业务模块。

`broad_input = true` 时，强制 `extraction_mode = profile-first`，并写入 `inferred_decisions`，理由为命中的判定条件。

### Step 3 — 研发域推断

对每个 path 仅扫描顶层 ≤ 3 层目录与 manifest 文件名，按 `config/domain-sampling-adapters.md` 的 signal 集匹配：

| 命中信号 | 推断 domain |
| --- | --- |
| `build.gradle.kts` + `commonMain/` 或 iOS 工程文件 | app-client |
| `package.json` + `next.config` / `vite.config` / `webpack.config` | frontend |
| `pom.xml` 或 `build.gradle` + `Controller` / `Service` / `Mapper` 命名 | backend |
| `electron-builder` / `ipcMain` 引用 | pc |
| 行业术语命中 + 已有 owner-confirmed 文档 | industry |

多个信号同时命中：分别记录候选 domain 与置信度，让用户选择，不静默择一。

### Step 4 — `extraction_mode` 决策

按优先级套用：

1. 用户明示模式 → 采用，但仍执行 Step 2 的广范围判定；冲突进入 `scope_conflicts`，等待用户确认。
2. `broad_input = true` → `profile-first`。
3. 用户提供 `selected_batch.batch_id` → `batch-extraction`，校验该 batch 是否存在于上一次 `batch-plan`，否则进入 `BATCH_NOT_SELECTED`。
4. 用户给出模块级窄范围（单个模块路径或 ≤ 5 个文件路径）→ `focused-module`。
5. 用户传入"已存在产物想评审" → `review-only`。
6. 用户传入"已确认候选想合并" → `merge-only`。
7. 否则保守降级到 `profile-first`。

### Step 5 — 敏感文件策略

按以下命名 / 内容信号识别敏感文件，命中即归入 `excluded_paths`，仅记录脱敏存在事实，**不读取内容**：

| 类别 | 命中模式（不区分大小写） |
| --- | --- |
| 密钥 / 凭据 | `*.key`、`*.pem`、`*.p12`、`*.keystore`、`id_rsa*`、`id_ed25519*`、`*credentials*`、`*secret*` |
| 环境配置 | `.env`、`.env.*`、`application-prod*`、`application-secret*`、`config.prod.*`、`*.tfvars` |
| Token / SDK | `*token*`、`*api[-_]?key*`、`firebase-adminsdk*.json`、`google-services-prod.json` |
| 用户数据 | `*user*.csv`、`*export*.json`、含 PII 字段的 dump 目录 |
| 构建产物 | `dist/`、`build/`、`target/`、`out/`、`node_modules/`、`Pods/`、`vendor/` |

策略表：

```yaml
sensitive_file_policy: sanitized-existence-only
rules:
  - pattern: 上表条目
    action: record-existence
    record_fields: [path_class, exists, owner_hint]
    forbidden: [read, copy, paraphrase, partial-quote]
```

如果继续萃取必须读取敏感文件原值，停止并抛出 `SENSITIVE_FILE_BLOCKED`。

### Step 6 — 输出范围与已有规范探测

1. 在 `engineering-standards/` 下匹配候选 domain 目录，列出其中已有 `standard.md` / `ai-rules.md` 的 `(source_doc, section_title)` 列表，作为冲突检测基线写入 `existing_docs`。
2. 输出范围由用户指定；用户未指定时按推断 domain 缩窄到 `single-domain` 或 `single-sub-domain`，避免一次萃取覆盖多个 domain。

### Step 7 — 确认协议

每个推断项 / 决策项必须形成一个**可单选 / 可一键确认**的待确认条目，按以下顺序与用户交互（已提供过的项跳过）：

1. project_paths（如有路径不可读，先停在这里）
2. extraction_mode + 广范围判定理由
3. dev_domains + 推断置信度
4. industry_domains
5. output_scope
6. sub_domains
7. business_modules
8. selected_batch（仅 `batch-extraction`）
9. 已有规范覆盖范围
10. quality_focus
11. output_targets
12. confirmation 声明

未确认项进入 `open_questions`，**不进入下一阶段**。

### Step 8 — Self-check（移交前）

移交下一阶段前必须自检：

- [ ] 所有 `project_paths` 均通过 Step 1 校验
- [ ] `extraction_mode` 与 `broad_input` 一致；冲突已记入 `scope_conflicts`
- [ ] 敏感文件命中清单已写入 `excluded_paths`
- [ ] `run_id` 已生成且符合 `config/output-targets.md §3` 命名
- [ ] `selected_batch` 字段在 `batch-extraction` 模式下非空
- [ ] `scope_summary` 通过 YAML 校验
- [ ] 用户已对所有推断项给出 `confirmation = true`，否则保留 `open_questions` 并停止

任一未通过：不移交，回到对应 step 修正或抛出对应失败模式。

## 失败模式映射

| 命中条件 | 失败模式 | 处理 |
| --- | --- | --- |
| 路径全部不可读或为空 | `NO_VALID_PROJECT_PATHS` | 停止，要求重新提供 |
| 命中敏感文件且必须读取才能继续 | `SENSITIVE_FILE_BLOCKED` | 停止，仅记录存在事实 |
| broad_input 但用户要求直接出规则 | `BROAD_INPUT_REQUIRES_PROFILE` | 强制降级为 `profile-first` |
| `batch-extraction` 但 `selected_batch` 为空 | `BATCH_NOT_SELECTED` | 停止，要求选 batch 或回到 profile-first |

## 必须做

1. 先推断 → 再让用户确认 → 再下一步；不静默择一。
2. 敏感文件只允许记录脱敏存在事实。
3. broad scope 强制 `profile-first`。
4. 推断与用户输入冲突写入 `scope_conflicts`，由用户裁定。
5. `run_id` 在本阶段一次性生成，贯穿后续所有 artifact 命名。

## 禁止做

1. 不得读取密钥、token、私钥、生产凭据原值或片段。
2. 不得在 `scope_summary` 之外的产物里写入完整项目路径。
3. 不得让 broad scope 直接进入 Generation。
4. 不得在用户未确认前生成 `run_id` 之外的下游 artifact。
5. 不得对历史 `active` 文件做任何写入预设；仅作为冲突基线只读。
