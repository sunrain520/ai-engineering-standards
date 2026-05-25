# Intake And Scope Contract

## 角色目标

用最少交互收集可执行输入，确认萃取范围、`extraction_mode`、输出目标、敏感文件策略和用户确认声明。广范围输入必须先转成 `profile-first`，不直接进入规则生成。

> 上游：用户输入 / 调用方参数。下游：Project Profile 阶段（如果 broad）或 Batch 选择阶段（如果 focused）。

## 输入

- 用户提供的 `project_paths`（必填，至少 1 个本地可读路径）。
- 可选：研发域、行业场景、业务模块、已有文档、`extraction_mode`、`selected_batch.batch_id`。
- 当前规范仓库目录（用于检测重复 / 冲突基线）。
- `references/config/context-governance.md`、`references/config/extraction-batch-policy.md`、`references/config/output-targets.md`。

## Run Mode

| run_mode | 确认行为 | 停止条件 |
| --- | --- | --- |
| `auto`（默认） | 所有字段自动推断，**跳过**确认对话，推断结果写入 `inferred_decisions` | 只有 `NO_VALID_PROJECT_PATHS` 或 `ALL_PATHS_SENSITIVE` 才停止 |
| `interactive` | 执行 Step 7 完整确认协议（10 步） | 任何 `open_questions` 未解决都停止 |

**auto 模式推断策略**：置信度 high → 直接采用；medium → 采用并写入 inferred_decisions；low → 采用但在 review-summary 标注待确认。不等待用户逐项确认。

## 输出（Handoff Schema）

```yaml
scope_summary:
  run_id: "{YYYYMMDD-HHMMSS-{primary_domain}}"
  run_mode: auto                          # auto | interactive
  project_paths: []                       # 必填，去重后的绝对路径
  extraction_mode: profile-first          # profile-first | batch-extraction | focused-module | diff | review-only | merge-only | full
  output_action: append                   # append（默认）| force-rebuild | restore | pin | unpin | list（与 extraction_mode 正交）
  domain: ""                              # output_action ≠ append 时必填,例:01-app-client(强制边界 #9)
  restore_from: ""                        # output_action ∈ {restore, pin, unpin} 必填,UTC-ts 形式
  keep: 10                                # output_action=force-rebuild 的 --keep=N 自动清理阈值
  operator: ""                            # 来自 .claude/spec-first/.developer 或 .codex/spec-first/.developer
  diff_baseline:                          # 仅 extraction_mode=diff 时填，透传给 diff-scoper
    type: last-extraction | commit | branch
    ref: <git ref>                        # commit hash / branch name / "main"，缺省由 diff-scoper Step 1 推断
  dev_domains: []                         # app-client | frontend | backend | pc-client | industry | testing | security
  industry_domains: []
  output_scope: full-package              # full-package | single-domain | single-sub-domain
  sub_domains: []
  business_modules: []
  existing_docs: []                       # 现有 active/draft 文件清单
  output_targets: []                      # 目标 domain 目录列表
  broad_input: false
  sensitive_file_policy: sanitized-existence-only
  inferred_decisions: []                  # 推断项 + 推断依据 + 置信度
  # auto 模式下以下两项不阻断执行，记录到 review-summary 供用户事后确认
  open_questions: []
  scope_conflicts: []
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
3. 路径数量 ≥ 2 且分别属于不同研发域信号集（见 `references/config/domain-sampling-adapters.md`）。
4. 用户文字明示 "完整项目 / 全仓 / 多服务 / 整个 repo / 整个项目"。
5. 用户未指定研发域、子领域或业务模块。

`broad_input = true` 时，强制 `extraction_mode = profile-first`，并写入 `inferred_decisions`，理由为命中的判定条件。

### Step 3 — 研发域推断

对每个 path 仅扫描顶层 ≤ 3 层目录与 manifest 文件名，按 `references/config/domain-sampling-adapters.md` 的 signal 集匹配：

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
2. 用户明示 `--mode=diff` 或 `extraction_mode: diff` 或显式提供 `diff_baseline.ref` → `diff`，移交 `diff-scoper` 解析受影响维度集合。`diff-scoper` 返回 `fallback_to_full_scan=true` 时降级为 `profile-first`，并把 `limitations` 透传到 `inferred_decisions`。
3. `broad_input = true` → `profile-first`。
4. 用户提供 `selected_batch.batch_id` → `batch-extraction`，校验该 batch 是否存在于上一次 `batch-plan`，否则进入 `BATCH_NOT_SELECTED`。
5. 用户给出模块级窄范围（单个模块路径或 ≤ 5 个文件路径）→ `focused-module`。
6. 用户传入"已存在产物想评审" → `review-only`。
7. 用户传入"已确认候选想合并" → `merge-only`。
8. 否则保守降级到 `profile-first`。

`diff` 模式专属约束：

- 必须是 git 仓库，且 baseline ref 可解析（详见 `references/agents/diff-scoper.md §Step 1`）；否则进入 `BASELINE_UNRESOLVABLE`，要求用户改用其它模式或提供有效 ref。
- 父级多仓 workspace 不接受单一 `diff` 模式：必须先指定 `target_repo` 限定到具体子仓 scope，再调 diff-scoper；否则进入 `DIFF_REQUIRES_TARGET_REPO`，停止。
- diff-scoper 返回的 `affected_sub_domains[]` 透传给 profile-and-batch-planner，用于把 batch 候选缩窄到受影响子领域。

### Step 4.5 — `output_action` 决策与互斥校验

`output_action` 与 `extraction_mode` **正交**:前者决定写入策略(append / 覆盖 / 恢复 / 标记),后者决定数据采集策略(全量 / 增量 / 焦点 / 评审 / 合并)。

按以下顺序处理:

1. **默认值**:用户未传 `output_action` → `append`(沿用本 skill 全部历史模式;不触发 backup-manager)。
2. **互斥校验 R91**:`output_action ≠ append` 且 `extraction_mode = diff` → 抛 `INCOMPATIBLE_OUTPUT_ACTION`,提示"force-rebuild / restore / pin / unpin / list 与 diff 模式互斥",停止。
3. **互斥校验 R92**:`output_action ≠ append` 且 `len(project_paths) > 1` → 抛 `INCOMPATIBLE_OUTPUT_ACTION`,提示"force-rebuild 等子模式仅接受单 project,跨项目模式必须先 append 完成 unified-activation-map",停止。
4. **强制边界 #9 — `--domain` 必填**:`output_action ∈ {force-rebuild, restore, pin, unpin, list}` 必须显式 `domain: <例:01-app-client>`;缺失 → 抛 `MISSING_DOMAIN_FOR_DESTRUCTIVE_ACTION`。
5. **强制边界 #10 — interactive 必填**:`output_action = force-rebuild` 必须 `run_mode = interactive`;auto / headless / pipeline → 抛 `NON_INTERACTIVE_CONTEXT_REJECTED`(restore / pin / unpin / list 不强制交互)。
6. **`restore_from` 必填**:`output_action ∈ {restore, pin, unpin}` 必须提供 `restore_from`(UTC-ts 形式);缺失 → 抛 `MISSING_RESTORE_FROM`。
7. **分流到 `backup-manager`**:校验通过后,把 `{run_id, output_action, domain, mode_args, dimension_activation_report_summary, operator, run_mode}` 注入 `references/agents/backup-manager.md`,等待 backup-manager 完成 safeguard / 备份 / atomic rename(force-rebuild)/ 拷回(restore)/ 标记(pin/unpin)/ 只读列表(list)再返回。
8. **`output_action = append`**:跳过本 step 5 之外的所有动作,直接进入 Step 5 敏感文件策略 + 后续 phase 2 default `full` 管道。

**force-rebuild 全管道失败信号监听(U24)**:`output_action = force-rebuild` 时,intake-and-scope 在 backup-manager step 1–8 完成、phase 2 `full` 管道启动后,负责把以下信号回传给 backup-manager step 10 dispatcher:

- `merge-coordinator.merge_summary.final_status ∈ {failed, partial}` → 触发 step 10b 回滚(force-rebuild 严格模式)
- `review-and-quality-gate.quality_gate_decisions[].status` 出现 `blocked` 或 `conflict` → 即便其他 check pass 也走 step 10b
- `scripts/force-rebuild-validate.sh` exit code 非 0 → 按 stdout JSON 的 `failure.check` 字段写 manifest.rollback,走 step 10b
- `references/prompts/orchestrator/force-rebuild/changelog-append.md` helper 返回 `success: false` → 走 step 10a 末段特例回滚(用 backup_dir 重建)

intake-and-scope 不直接执行回滚,只做信号路由;具体回滚动作由 backup-manager step 10a/10b 内部实现。

scope_summary 写入:

```yaml
scope_summary:
  output_action: force-rebuild | restore | pin | unpin | list | append
  domain: "01-app-client"               # output_action ≠ append 时必填
  restore_from: "20260524T130000Z"      # restore / pin / unpin 必填;list 不需要
  keep: 10
  operator: "<host developer profile>"  # 由 .claude/spec-first/.developer 或 .codex/spec-first/.developer 读
  backup_manager_handoff:               # output_action ≠ append 时填
    awaiting_user_confirmation: false
    backup_path: ".local-backups/01-app-client/20260525T045000Z/"
    manifest_path: ".local-backups/01-app-client/20260525T045000Z/manifest.json"
```

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

### Step 7 — 确认协议（interactive 模式）/ 推断记录（auto 模式）

**interactive 模式**：逐项确认，未确认项进入 `open_questions`，不进入下一阶段。确认顺序：
1. project_paths（路径不可读时停止）
2. extraction_mode + 广范围判定理由
3. dev_domains + 推断置信度
4. industry_domains / output_scope / sub_domains / business_modules
5. 已有规范覆盖范围 / output_targets
6. confirmation 声明

**auto 模式**：跳过确认对话，将所有推断决策写入 `inferred_decisions`：
- 置信度 high / medium → 直接采用，记录推断依据
- 置信度 low → 采用，同时写入 `open_questions`（不阻断执行，输出到 review-summary 供事后确认）
- 唯一停止条件：`NO_VALID_PROJECT_PATHS` 或 `ALL_PATHS_SENSITIVE`

### Step 8 — Self-check（移交前）

移交下一阶段前必须自检：

- [ ] 所有 `project_paths` 均通过 Step 1 校验
- [ ] `extraction_mode` 与 `broad_input` 一致；冲突已记入 `scope_conflicts`
- [ ] 敏感文件命中清单已写入 `excluded_paths`
- [ ] `run_id` 已生成且符合 `references/config/output-targets.md §3` 命名
- [ ] `selected_batch` 字段在 `batch-extraction` 模式下非空
- [ ] `scope_summary` 通过 YAML 校验
- [ ] 用户已对所有推断项给出 `confirmation = true`，否则保留 `open_questions` 并停止
- [ ] **R91 / R92 互斥校验**:`output_action ≠ append` 与 `extraction_mode = diff` / 多 projects 互斥已校验
- [ ] **强制边界 #9**:`output_action ∈ {force-rebuild, restore, pin, unpin, list}` 已校验 `domain` 非空
- [ ] **强制边界 #10**:`output_action = force-rebuild` 已校验 `run_mode = interactive`
- [ ] **backup-manager handoff**:`output_action ≠ append` 已成功完成 backup-manager Step 1–8(force-rebuild)/ restore / pin / unpin / list,`backup_manager_handoff` 字段已填

任一未通过：不移交，回到对应 step 修正或抛出对应失败模式。

## 失败模式映射

| 命中条件 | 失败模式 | 处理 |
| --- | --- | --- |
| 路径全部不可读或为空 | `NO_VALID_PROJECT_PATHS` | 停止，要求重新提供 |
| 命中敏感文件且必须读取才能继续 | `SENSITIVE_FILE_BLOCKED` | 停止，仅记录存在事实 |
| broad_input 但用户要求直接出规则 | `BROAD_INPUT_REQUIRES_PROFILE` | 强制降级为 `profile-first` |
| `batch-extraction` 但 `selected_batch` 为空 | `BATCH_NOT_SELECTED` | 停止，要求选 batch 或回到 profile-first |
| `diff` 模式但 baseline 不可解析 | `BASELINE_UNRESOLVABLE` | 停止，要求用户改 mode 或提供有效 ref |
| `diff` 模式但工作树非 git / shallow 不足 / 维度映射覆盖率 < 20% / changed_files > 2000 | `DIFF_FALLBACK_TO_FULL_SCAN` | 不停止，diff-scoper 自动降级 `profile-first` 并写 `limitations` |
| 父级多仓 workspace 用 `diff` 模式且未指定 `target_repo` | `DIFF_REQUIRES_TARGET_REPO` | 停止，要求显式 scope 到子仓 |
| `output_action ≠ append` && `extraction_mode = diff` / 多 projects | `INCOMPATIBLE_OUTPUT_ACTION` | 停止,提示互斥规则 R91 / R92 |
| `output_action ∈ {force-rebuild, restore, pin, unpin, list}` 但缺 `domain` | `MISSING_DOMAIN_FOR_DESTRUCTIVE_ACTION` | 停止,要求补 `--domain=<>` |
| `output_action = force-rebuild` 但 `run_mode ≠ interactive` | `NON_INTERACTIVE_CONTEXT_REJECTED` | 停止,提示需 interactive host |
| `output_action ∈ {restore, pin, unpin}` 但缺 `restore_from` | `MISSING_RESTORE_FROM` | 停止,要求提供 UTC-ts |
| `host developer profile` 缺失 | `OPERATOR_PROFILE_MISSING` | 停止,提示运行 `spec-first init --claude -u <name>` |

## 必须做

1. 先推断 → 写入 `inferred_decisions`（含置信度和推断依据）；interactive 模式让用户逐项确认，auto 模式将 low 置信度推断额外写入 `open_questions` 供 review-summary 事后审查；两种模式都不静默择一，推断依据必须留痕。
2. 敏感文件只允许记录脱敏存在事实。
3. broad scope 强制 `profile-first`。
4. 推断与用户输入冲突写入 `scope_conflicts`，interactive 模式由用户裁定，auto 模式记入 review-summary 事后裁定。
5. `run_id` 在本阶段一次性生成，贯穿后续所有 artifact 命名。

## 禁止做

1. 不得读取密钥、token、私钥、生产凭据原值或片段。
2. 不得在 `scope_summary` 之外的产物里写入完整项目路径。
3. 不得让 broad scope 直接进入 Generation。
4. 不得在用户未确认前生成 `run_id` 之外的下游 artifact。
5. 不得对历史 `active` 文件做任何写入预设；仅作为冲突基线只读。
