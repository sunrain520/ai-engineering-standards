---
name: orchestration-cases
description: 编排容错评估场景：AE16（quality-gate 通过门槛）/ AE19（quality-gate FAIL → 不进 merge）/ AE20（merge-coordinator 三态汇总）
type: evals
phase: phase-2
ae: [AE16, AE19, AE20]
---

# Orchestration Cases

## ORC-001 — AE16: quality-gate 通过路径必须基于真实或批准脱敏 evidence

**Given**

```yaml
domain: 09-industry
evidence_tier: real-evidence
generated_artifacts:
  - 01-securities-standard.md
  - evidence/dimension-activation-report.json
quality_gate_checklist:
  A1_structure_complete: true     # 16 维章节均存在
  A2_state_consistent: true       # activation-report.json 与 standard.md 状态一致
  A3_evidence_tier_labeled: true  # frontmatter 含 real-evidence 或 approved-redacted evidence_tier
  A4_pending_refs_valid: true     # pending-confirmation.md 引用正确
  A5_candidate_hints_present: true  # candidate 维度均有升级条件
  B_coverage_rate: 1.0            # 16/16
  B_avg_depth_score: 0.72
```

**When**

review-and-quality-gate agent 执行双门禁（门禁 A + 门禁 B）评估。

**Then**

- 门禁 A：全部 5 项通过 → A 门禁 PASS
- 门禁 B：覆盖率 100% + 深度分满足阈值 → B 门禁 PASS
- 总裁决：`quality_gate_result = "PASS"`
- merge-coordinator **被允许继续**执行合并
- `quality-gate-result.md` 记录详细评分，含 `evidence_tier = real-evidence` 或 approved-redacted evidence 来源

**反例**

- 若 `evidence_tier = synthetic-poc`，总裁决必须是 `NOT_EVIDENCE` 或 `BLOCKED`，不得进入 merge。

**回归断言**

```bash
grep -q "quality_gate_result.*PASS\|PASS" quality-gate-result.md
# merge 不被阻塞
grep -qv "BLOCKED\|FAIL" quality-gate-result.md
# synthetic-poc 反例必须被拦截
grep -q "synthetic-poc.*NOT_EVIDENCE\\|NOT_EVIDENCE" synthetic-quality-gate-result.md
```

---

## ORC-002 — AE19: quality-gate FAIL → 不进 merge

**Given**

```yaml
generated_artifacts:
  - broken-securities-standard.md
quality_gate_checklist:
  A1_structure_complete: false    # SEC-07 章节缺失
  A2_state_consistent: false      # SEC-03 在 standard.md 为 activated，但 activation-report.json 为 baseline
  A3_evidence_tier_labeled: true
```

**When**

review-and-quality-gate agent 执行门禁 A 评估，发现 A1 / A2 失败。

**Then**

- 门禁 A：A1 FAIL + A2 FAIL → 总裁决 `quality_gate_result = "FAIL"`
- merge-coordinator **不执行**任何合并操作（不写 standard.md / not update evidence/）
- `quality-gate-result.md` 记录失败项清单：
  - `A1 FAIL: SEC-07 章节缺失`
  - `A2 FAIL: SEC-03 状态不一致（standard=activated vs report=baseline）`
- 用户收到提示：需修复上述问题后重跑 review 阶段
- 原有 `01-securities-standard.md`（如已存在）**不被覆盖**

**回归断言**

```bash
grep -q "FAIL" quality-gate-result.md
grep -q "A1.*FAIL\|SEC-07" quality-gate-result.md
grep -q "A2.*FAIL\|SEC-03" quality-gate-result.md
# 确认 merge 未执行（target 文件 mtime 未变）
# 或 merge-coordinator output 含 SKIP/BLOCKED
```

---

## ORC-003 — AE20: merge-coordinator 三态汇总正确

**Given**

```yaml
domain: 09-industry
existing_files:
  standard.md: status=draft     # 已存在占位文件
  overview.md: status=no-evidence-placeholder
new_generation:
  01-securities-standard.md:    # 新产物（全新文件）
    status: draft
    activation_states:
      SEC-01: activated
      SEC-09: candidate
  evidence/dimension-activation-report.json: NEW
merge_policy:
  existing_active: never_overwrite    # 无 active 文件,跳过
  existing_draft: suggest_merge       # standard.md 有 draft,生成 merge-suggestions.md
  new_file: create                    # 01-securities-standard.md 直接创建
  conflicts: record_in_conflicts_md
```

**When**

merge-coordinator 执行三态汇总合并。

**Then**

- `01-securities-standard.md` → 直接 CREATE（无冲突）
- `evidence/dimension-activation-report.json` → 直接 CREATE（新文件）
- `standard.md`（旧占位）→ 生成 `merge-suggestions.md` 条目，建议将旧占位内容替换为新 PoC；**不自动覆盖**
- `merge-suggestions.md` 中出现"建议合并 standard.md 与 01-securities-standard.md 占位内容"
- `conflicts.md` 无新条目（新文件无既有规则冲突）
- 未激活维度地图写入 `overview.md`（更新现有文件，不冲突）

**回归断言**

```bash
[ -f engineering-standards/09-industry/01-securities-standard.md ]
[ -f engineering-standards/09-industry/evidence/dimension-activation-report.json ]
grep -q "standard.md\|merge" merge-suggestions.md
grep -qv "SEC-" conflicts.md   # conflicts.md 无新维度冲突条目
```
