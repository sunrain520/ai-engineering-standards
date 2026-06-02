# project-standard-extractor 设计与内部解读

## 1. 定位

`project-standard-extractor` 是一条从真实项目代码萃取团队级研发规范的生产线。新版公开稳定路径默认 full-auto：用户提供 `project_paths` 后，系统内部完成 profile-first、ordered queue、逐 batch worker、quality gate、append-only merge、lineage 和 owner queue。

核心设计不是“让 AI 一次读完整仓库”，而是“让 orchestrator 自动串行执行多个单 batch worker”。

## 2. 三条设计哲学

| 哲学 | 含义 |
| --- | --- |
| Reverse Standardization | 规范从真实代码 evidence 生长出来 |
| Evidence-first | 每条规则必须可追溯到 code facts / examples / owner decision |
| Governed Automation | 自动跑完整队列，但状态、lineage、owner queue 保持可审计和可撤销 |

## 3. 分层

```text
Layer A: Phase 1 public full-auto
  intake -> profile -> ordered queue -> per-batch worker -> review -> merge

Layer B: Phase 2 repair-only
  dimension-activator -> activation-report.v1 -> Gate B -> overview §9

Layer C: maintainer tools
  force-rebuild / restore / pin / unpin / list / backup-manager
```

普通用户只走 Layer A。Layer B/C 中的字段不能反向泄漏到公开输入。

## 4. 为什么 full-auto 仍然安全

full-auto 的边界在三个地方：

1. profile-first 只产出可执行 queue 和 coverage，不直接把完整仓库塞给 generation。
2. 每个 worker 只消费一个 batch 的 `candidate_files`。
3. merge 按 `target_state` 写入，所有派生视图都记录 lineage 和 owner queue。

因此，full-auto 是“自动遍历受控 batch”，不是“无边界全仓推断”。

## 5. 状态机

| 状态 | 进入 AI 默认执行 | 退出 |
| --- | --- | --- |
| `auto-active` | 是 | owner 否决或自动复检降级 |
| `owner-confirmed-active` | 是 | owner 决策 |
| `draft` | 否 | 可被后续 run 或 owner 升级 |
| `pending-confirmation` | 否 | owner 裁定或补 evidence |
| `stale-auto-active` | 否 | owner 裁定 |
| `owner-rejected` | 否 | 终态 |

`auto-active` 必须带 `authority_scope: this-repo` 和 `upgrade_mode: auto-active`。它不是团队永久承诺，而是可审计、可撤销的默认执行候选。

## 6. Auto-active 闸

BR-016/BR-017 的工程意义是防止“频繁坏味道”变成强制规范。自动升级必须使用确定性 occurrence，不允许 LLM 自评：

- `deterministic_occurrence_count >= 2`。
- 多文件/多角色覆盖。
- confidence high。
- evidence 充分、结构完整。
- 无未裁定 conflict。
- 未命中 `anti-pattern-blocklist.yaml`。
- 非高风险域。

高风险域包括 security、auth、cryptography、permission、compliance、privacy、pii、payment 等。

## 7. Lineage 与 owner queue

Lineage ledger 记录：

- evidence id。
- `source_doc` + `section_title`。
- derived view type。
- gate result。
- upgrade mode。
- deterministic occurrence count。
- criteria snapshot。

Owner queue 记录：

- auto-active 待审项。
- pending / conflict 待裁定项。
- stale-auto-active 复检失效项。
- owner-rejected 终态项。

这两个文件让“自动进入默认执行路径”有撤销链，而不是一次性发布。

## 8. Phase 1 / Phase 2 分流

Phase 1 缺失 `activation_report` 是正常情况。review 只跑 Gate A 与结构/运行策略；merge 直接按 `target_state` 路由。

Phase 2 才读取 `activation-report.v1`、执行 Gate B、持久化 `evidence/dimension-activation-report.json` 并维护 overview §9 未激活维度地图。

Phase 1 产物中出现 `activation-report.json` 是错误，应由 validator BLOCK。

## 9. 增量与撤销

重复运行时，merge 使用 existing index 对齐 `(source_doc, section_title)`：

- 等价规则追加 evidence。
- evidence 变化标 `evidence-changed`。
- pending 升 standard 时旧条目标 `superseded_by`。
- active/draft 与新 evidence 不一致时写 owner 待办，不自动改写。
- auto-active 复检失败时标 `stale-auto-active` 并移出默认执行路径。

## 10. Validator

两类 validator 分工：

- `public-surface-validate.sh`: 检查公开文案、入口、eval、Phase1/Phase2 边界和旧口径漂移。
- `artifact-contract-validate.sh`: 检查 machine-readable artifact contract、doc_type/status 枚举、lineage/owner queue、candidate/formal 边界。

语义质量仍由 eval 和人工 review 保障；validator 不宣称能证明规则“正确”。
