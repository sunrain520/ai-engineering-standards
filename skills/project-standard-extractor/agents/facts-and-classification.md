# Facts And Classification Contract

## 角色目标

从选定 batch 的代表性候选文件中萃取**可验证事实**，再把事实分类为规则候选。此阶段不直接写最终规范结论——先有事实，才有规则。分类永远不得产生新事实。

> 上游：`profile-and-batch-planner`（batch-plan + 选定 batch_id）。下游：`generation`（code_facts + classification）。

## 输入

```yaml
inputs:
  scope_summary:              # 来自 intake-and-scope
  profile_doc:                # {run_id}-project-profile.md
  extraction_map:             # {run_id}-extraction-map.md
  batch_plan:                 # {run_id}-batch-plan.md
  selected_batch_id:          # 用户或调用方选定的 batch_id（必填）
  existing_standards:         # 现有 active/draft 规范文件清单（用于冲突检测）
  domain_taxonomy:            # config/domain-taxonomy.md
```

## 输出（Handoff Schema）

```yaml
code_facts:
  batch_id: ""
  batch_domain: ""
  batch_sub_domain: ""
  facts:
    - id: "EV-{DOMAIN}-{NUMBER}"
      path: ""                  # 仅相对路径
      observed_pattern: ""      # 描述性事实，不含规范结论
      file_role: ""             # controller / service / dto / config / test / etc.
      evidence_kind: ""         # positive / negative / legacy / unknown
      occurrences: 0            # 在候选文件集里发现几处
      boundary: ""              # 推导边界：仅本文件 / 本模块 / 跨多文件
      confidence: ""            # high / medium / low
      sensitive_handling: ""    # sanitized / none
      inferred_from: ""         # 若是推断而非直接观测，说明依据
  stop_conditions_hit: []
  unread_candidates: []       # 因预算耗尽未读的候选文件

classification:
  recommended: []             # 事实 id 列表 + 简短理由
  forbidden: []
  legacy_compatible: []
  pending_confirmation: []
  conflict: []                # 与已有规范冲突的事实 id + 冲突文档 (source_doc, section_title)
```

## 执行步骤

### Step 1 — 选定 batch 验证

1. 在 `batch_plan` 中定位 `selected_batch_id`；若不存在，抛出 `BATCH_NOT_SELECTED`。
2. 确认 batch `status == ready`；若为 `pending-confirmation / skipped / blocked`，停止并说明原因。
3. 读取 batch 的 `candidate_files`、`excluded_paths`、`evidence_limit`、`rule_limit`、`stop_conditions`。

### Step 2 — 候选文件抽样读取（按预算顺序）

**读取顺序**（先高价值，后补充）：

1. **P0 候选**：文件名 / 角色命中 `Controller`、`ViewModel`、`Reactor`、`UseCase`、`Service`（顶层逻辑入口）。
2. **P1 候选**：`DTO`、`Request`、`Response`、`Mapper`（数据契约）。
3. **P2 候选**：`test`、`spec` 目录内对应 P0 / P1 文件的测试文件（反例与覆盖验证）。
4. **补充候选**：`config`、`job`、`consumer` 等按需补读，直到触达 `evidence_limit`。

每次读取前检查：路径是否在 `excluded_paths` → 是则跳过，记录 `unread_candidates`。

**预算门禁**：命中 `evidence_limit` 时停止读取，写入 `stop_conditions_hit: evidence_limit`，不扩大到全项目。

### Step 3 — 事实萃取（先输出，不分类）

对每个读取的文件，按以下维度萃取事实：

**事实萃取维度**（每条事实回答 1 个维度）：

| 维度 | 问法 | 示例 |
| --- | --- | --- |
| **命名规范** | 这类文件的命名模式是什么？ | Controller 以动词 + 名词结构命名 |
| **包结构** | 模块 / 包如何分层？ | controller / service / dto / repository 四层 |
| **职责边界** | 某类角色做了什么 / 不做什么？ | Service 不直接返回 HTTP status |
| **依赖方向** | 依赖谁，被谁依赖？ | Controller → Service；不绕过 Service 直调 Repository |
| **错误处理** | 错误如何被捕获、传播、返回？ | 统一 @ExceptionHandler；不在 Controller 内 try-catch 业务异常 |
| **接口契约** | 入参/出参 / 状态码约定 | 统一 BaseResponse<T> 包装 |
| **测试模式** | 测试粒度、命名、mock 策略 | @SpringBootTest 集成测试 vs @MockBean 单测 |
| **安全 / 合规** | 鉴权、权限校验位置 | @PreAuthorize 在 Controller 层 |
| **并发 / 事务** | 事务注解位置和传播策略 | @Transactional 只在 Service 层 |
| **反例** | 这个文件犯了什么反范式？ | Service 内直接 new dao 绕过 Spring |

**萃取规则**：

- 每条事实必须是**描述性**（观察到了什么），不是**规范性**（应该怎么做）。
  - ❌ "应该使用统一 BaseResponse" → 这是规则，不是事实
  - ✅ "3 个文件中 OrderController、PayController 均使用 BaseResponse，UserController 使用裸 Map" → 事实
- `occurrences >= 2`：才能记为 `high confidence` 事实。
- `occurrences == 1`：`medium confidence`，写入 `boundary: single-file`。
- 仅从 README / profile 推断但无代码验证：`low confidence`，写入 `inferred_from`。

**敏感信息处理**：

命中 `intake-and-scope` 的敏感文件列表时，只记录：

```yaml
sensitive_handling: sanitized
path: "{path_class}/{directory_name}/"
observed_pattern: "存在生产配置文件，内容已跳过"
```

### Step 4 — 全部事实输出后再分类

**严格工序**：先完成 Step 3 的全部 `code_facts` 输出，再进入分类。**分类阶段不得新增事实**。

**分类阈值**：

| 分类桶 | 进入条件 |
| --- | --- |
| `recommended` | confidence >= medium AND occurrences >= 2 AND 正向实践 AND 无已有规范冲突 |
| `forbidden` | confidence >= high AND occurrences >= 2 AND 反向实践（明确的反范式）AND 有负例证据 |
| `legacy_compatible` | 旧写法，在 ≥ 2 个文件共存，没有明确要迁移的计划；AI 不应复制但不算错 |
| `pending_confirmation` | confidence == low OR occurrences == 1 OR 仅从推断推导 OR 需要 owner 确认 |
| `conflict` | 与已有 `active` 或 `draft` 规范语义矛盾 |

**forbidden 额外门禁**（P0/FORBIDDEN 必须满足所有 3 项）：

1. 有直接负例代码（不仅推断）
2. confidence: high
3. 不是因为"没见过正确做法"，而是"见到了明确错误做法"

不满足 3 项 → 自动降为 `pending_confirmation`。

### Step 5 — 跨项目一致性检测

如果 `profile_doc` 包含多个项目路径：

1. 对相同 `domain / sub_domain / task_type` 对比不同项目的同一维度事实。
2. 若多个项目**一致**（≥ 2 项目相同模式），`confidence` 升级为 `cross_project`，`evidence_tier` 为 `cross-project`。
3. 若项目间**不一致**，进入 `conflict` 分类桶，写入两边的 evidence id 作为对比证据。
4. 单项目事实最高为 `single-project` evidence tier，即使 confidence: high。

### Step 6 — 规则数量检查

统计 `recommended + forbidden + legacy_compatible` 数量：

- 超过 `rule_limit`：把超出的候选降级到 `pending_confirmation`，记录 `stop_conditions_hit: rule_limit`。
- 优先保留 `forbidden` > `recommended` > `legacy_compatible`。

### Step 7 — Self-check（移交前）

- [ ] 所有 facts 先于分类输出（工序验证）
- [ ] 分类阶段没有新增 fact id（不在 code_facts 列表里的 id 不得出现在分类里）
- [ ] 每条 `forbidden` 分类都有 `confidence: high` 和直接负例 evidence
- [ ] 没有 `confidence: low` 的事实进入 `recommended` 或 `forbidden`（必须在 `pending_confirmation`）
- [ ] `occurrences >= 2` 的验证已在 `boundary` 字段说明
- [ ] 所有 `conflict` 分类项都有 `(source_doc, section_title)` 指向具体已有规范
- [ ] 未读文件列在 `unread_candidates`，原因明确
- [ ] 没有读取任何敏感文件内容（只有 `sanitized` 记录）
- [ ] `stop_conditions_hit` 已记录（若触达任一预算）

## 失败模式映射

| 命中条件 | 处理 |
| --- | --- |
| `selected_batch_id` 不存在或状态非 ready | `BATCH_NOT_SELECTED`；停止，要求选择有效 batch |
| 候选文件全部不可读 | `NO_REPRESENTATIVE_EVIDENCE`；标记 batch 为 skipped；不生成分类 |
| 继续读取需要读敏感文件 | `SENSITIVE_FILE_BLOCKED`；停止读取；记录存在事实 |
| 事实全部来自推断 / 无直接代码 | 所有分类进入 `pending_confirmation`；不生成 AI 可执行规则 |
| 超出 evidence_limit | 记录 stop_condition；已有事实正常输出；不强行继续 |

## 必须做

1. **先事实，再分类**——工序不可倒置。
2. 每条事实都有 batch、路径（相对）、观察、边界、置信度和敏感处理声明。
3. `forbidden / P0` 候选必须有直接负例代码，不得只靠推断。
4. 跨项目事实做一致性对比，不一致的进入 `conflict`。
5. 预算耗尽时停止，不扩大。

## 禁止做

1. 不得凭空推导团队标准（没有代码 evidence 的结论不得进入 recommended / forbidden）。
2. 不得把行业共性直接升级为 `forbidden` 或 P0。
3. 不得复制敏感配置值或原始 secret。
4. 不得跨 batch 读取（selected_batch 以外的 candidate_files 不得读取）。
5. 不得在分类阶段新增事实（事实列表锁定后只能分类，不能追加）。
