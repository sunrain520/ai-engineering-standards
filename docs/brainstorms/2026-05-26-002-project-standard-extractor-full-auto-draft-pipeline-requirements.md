---
date: 2026-05-26
topic: project-standard-extractor-full-auto-draft-pipeline
spec_id: 2026-05-26-002-project-standard-extractor-full-auto-draft-pipeline
---

# project-standard-extractor Full-auto Draft Pipeline 需求

## Summary

本文定义 `project-standard-extractor` 的全流程自动化目标：用户提供一个仓库后，Skill 自动完成画像、batch 排序、逐 batch 萃取、质量门禁、冲突归并和候选索引生成，产出完整可审查的 draft 规范资产。`active` 发布仍由 owner 批准，LLM 的专业判断用于提升 draft 质量，不直接替代团队规范承诺。

---

## Problem Frame

当前稳定路径要求完整仓库先 `profile-first`，再由人选择单个 ready batch 执行 `batch-extraction`。这个路径质量边界清晰，但对核心研发推广来说，中途人工选择 batch 会打断自动化体验，也无法满足“给一个仓库，自动生成完整候选规范”的产品预期。

用户明确希望使用最好的模型，让专业 LLM 负责全流程判断和生成。这个目标成立，但核心挑战不是 LLM 会不会写规范，而是 LLM 会不会把局部事实、历史包袱、偶然写法或低证据推断错误升级为团队规范。因此新能力必须把自动化重点放在 draft 生产、证据分级、冲突显性化、质量门禁和 owner approval queue 上，而不是自动发布 `active`。

全流程自动化应改变人工参与位置：从“中途挑 batch 和驱动每一步”后移为“最终确认哪些高价值 draft 可以升级 active”。这样既能获得自动化效率，又保留团队规范治理边界。

---

## Actors

- A1. Skill 使用者：提供目标仓库，希望一次运行获得完整 draft 规范资产。
- A2. Full-auto pipeline：自动完成仓库画像、batch 排序、逐 batch 萃取、质量门禁和归并输出。
- A3. 专业 LLM：承担事实归纳、规则抽象、反例识别、冲突分析和规范文本生成。
- A4. 规范 owner：审查 high-confidence draft、pending 和 conflict，决定是否升级 `active`。
- A5. Reviewer / AI 重度使用者：消费 `ai-rules`、`review-checklist` 和 active 规则，反馈规范是否降低返工和 Review 成本。

---

## Key Flows

- F1. 全仓 draft 自动生成
  - **Trigger:** A1 提供一个完整仓库并请求自动生成规范。
  - **Actors:** A1, A2, A3
  - **Steps:** pipeline 先做仓库画像，再生成自动排序的 ready batch 队列；随后按队列逐 batch 萃取 evidence、生成 draft、执行质量门禁；最后汇总所有 batch 的规范、AI Rules、Review Checklist、pending、conflicts 和候选索引。
  - **Outcome:** 生成完整 draft 规范资产和运行级 review summary，全程不要求用户中途选择 batch。
  - **Covered by:** R1, R2, R3, R4, R12

- F2. 质量分层与风险显性化
  - **Trigger:** 某个 batch 生成候选规则。
  - **Actors:** A2, A3
  - **Steps:** pipeline 对每条候选规则检查 evidence、代表性、可执行性、可评审性、legacy 风险、冲突风险和敏感信息风险；根据结果分流为 high-confidence draft、low-coverage draft、pending-confirmation、conflict 或 rejected。
  - **Outcome:** 低质量或高风险规则不会混入默认可执行上下文。
  - **Covered by:** R5, R6, R7, R8, R9, R10, R11

- F3. owner approval queue
  - **Trigger:** 全仓 draft 生成完成。
  - **Actors:** A2, A4
  - **Steps:** pipeline 将候选规则按优先级、置信度、风险和推荐动作整理为审批队列；owner 优先审查高价值规则，再处理 pending 和 conflict。
  - **Outcome:** owner 能快速决定哪些 draft 升级 active，哪些保持 pending、conflict 或 rejected。
  - **Covered by:** R13, R14, R15

- F4. 使用反馈与质量闭环
  - **Trigger:** active 规则进入一次真实 AI 开发或 Review。
  - **Actors:** A4, A5
  - **Steps:** AI 使用者和 Reviewer 记录规则是否减少返工、是否减少重复解释、是否出现误导；这些反馈作为后续重新萃取或 owner 决策的输入。
  - **Outcome:** 规范质量由生成数量转向真实使用效果。
  - **Covered by:** R16, R17, R18

---

## Requirements

**Full-auto draft pipeline**

- R1. Skill 必须支持从完整单仓库输入启动全流程自动化 draft 生成，运行过程中不要求用户手动选择单个 batch。
- R2. pipeline 必须先完成仓库画像和 batch 规划，再进入逐 batch 萃取；不得直接把完整仓库作为一个无边界上下文生成规范。
- R3. pipeline 必须只自动执行 ready batch，并把 pending、skipped 或 blocked batch 记录到 review summary，而不是强行萃取。
- R4. pipeline 必须按排序队列逐 batch 执行，单个 batch 失败、证据不足或冲突时不得污染其他 batch 的结论。

**专业 LLM 判断边界**

- R5. 专业 LLM 可以负责事实归纳、规则抽象、反例识别、legacy 判断、冲突分析和规范文案生成，但每个判断都必须保留 evidence 或推断依据。
- R6. pipeline 必须区分 recommended、forbidden、legacy、pending、conflict 和 rejected，不能只根据代码存在性生成推荐规范。
- R7. pipeline 必须识别代表性风险，包括历史兼容模块、迁移过渡代码、临时方案、低维护模块和单点样例过度泛化。
- R8. pipeline 必须对每条规则给出质量分层，至少包括 high-confidence draft、low-coverage draft、pending-confirmation、conflict 和 rejected。

**规范质量门禁**

- R9. 每条 draft 规则必须通过 evidence gate；没有可追溯 evidence 的内容只能进入 pending 或 rejected。
- R10. 每条 draft 规则必须通过 AI 可执行性 gate；不可执行、过度抽象或含糊表达不能进入 high-confidence draft。
- R11. 每条 draft 规则必须通过 Review 可检查性 gate；Reviewer 无法二值判断的内容不能进入 high-confidence draft。
- R12. pipeline 必须对跨 batch 相似规则做去重或合并建议，对相反规则写入 conflict，不得静默选择一边。

**输出与审批体验**

- R13. 全自动运行的所有新规范默认状态必须是 `draft`，不得自动发布 `active`。
- R14. pipeline 必须生成 owner approval queue，按优先级展示建议升级、保持 draft、移入 pending、标记 conflict 或 rejected 的候选项。
- R15. 候选索引和 AI 上下文包必须保持 candidate 状态，不能自动覆盖正式索引或默认强约束入口。

**质量评估与反馈**

- R16. 成功标准必须以规范质量和使用效果为核心，而不是生成文件数量或规则数量。
- R17. pipeline 必须输出质量摘要，覆盖 high-confidence draft 数量、pending 数量、conflict 数量、rejected 数量、主要风险和需要 owner 决策的问题。
- R18. 后续评估必须覆盖真实使用反馈，包括 AI 生成代码返工是否减少、Review 重复解释是否减少、规则误导是否出现。

---

## Acceptance Examples

- AE1. **Covers R1, R2, R3, R13.** Given 使用者提供一个完整仓库，when 启动 full-auto draft pipeline，then Skill 先生成画像和 batch 队列，再自动执行 ready batch，最终产出 draft 规范资产，且没有任何新规则被自动发布为 `active`。
- AE2. **Covers R6, R7, R8, R9.** Given 某个模块是历史迁移代码且只有单点样例，when pipeline 分析该 batch，then 相关候选规则不得进入 high-confidence draft，必须进入 legacy、pending 或 rejected，并说明证据不足或代表性风险。
- AE3. **Covers R10, R11.** Given LLM 生成的规则包含“合理拆分”“尽量保持清晰”等不可检查表达，when 执行质量门禁，then 该规则不能进入 high-confidence draft，必须要求改写为 AI 可执行、Reviewer 可判断的规则，或降级为 pending。
- AE4. **Covers R12, R14.** Given 两个 ready batch 对同一场景抽象出相反规则，when pipeline 做跨 batch 汇总，then 该问题必须进入 conflict 和 owner approval queue，不得自动选一边覆盖另一边。
- AE5. **Covers R14, R15.** Given 全自动运行生成候选索引和 AI 上下文包，when 运行完成，then 这些产物只能作为候选审查材料，owner 未批准前不得覆盖正式索引或进入默认强约束入口。
- AE6. **Covers R16, R17, R18.** Given 一次全自动运行生成了大量 draft 规则，when 评估运行效果，then 不能只按规则数量判定成功，必须同时查看 high-confidence 比例、pending/conflict/rejected 分布，以及真实 AI 开发和 Review 反馈。

---

## Success Criteria

- 使用者可以提供一个完整单仓库并获得完整 draft 规范资产，不需要中途手动选择 batch。
- 生成结果能明确区分 high-confidence draft、low-coverage draft、pending、conflict 和 rejected。
- 每条可进入 high-confidence draft 的规则都有代表性 evidence，且 AI 能执行、Reviewer 能检查。
- owner approval queue 能让负责人优先处理最有价值、风险最低的候选规则。
- 全自动生成不会自动发布 `active`，不会覆盖正式索引，不会把 pending/conflict 混入默认强约束。
- 下游 `$spec-plan` 不需要再发明产品边界、状态分层、质量门禁或成功标准。

---

## Scope Boundaries

- V1 聚焦单仓库 full-auto draft pipeline，不要求同时发布多仓库统一规范能力。
- V1 不把 `force-rebuild`、`restore`、`pin`、`unpin`、`list` 作为主线能力。
- V1 不允许 LLM 直接发布全部 `active` 正式规范。
- V1 不以生成规则数量作为主要成功指标。
- V1 不取消 evidence、质量门禁、冲突记录和 owner approval。
- V1 不要求一次解决所有行业高风险规范；行业、安全、合规类内容可以更保守地进入 pending。

---

## Key Decisions

- 决定采用“全自动生成 draft，owner 批准 active”的边界：这样既满足自动化体验，又保留团队规范承诺机制。
- 决定将人工参与后移到 owner approval queue：中途不再要求用户选择 batch，但最终审批仍由人负责。
- 决定把质量目标定义为“少而硬”：每条规范必须有代表性 evidence，AI 能执行，Reviewer 能检查，owner 能决策。
- 决定不把强模型能力等同于发布权限：最好的模型用于提升分析和生成质量，不用于绕过治理。
- 决定将冲突显性化优先于自动仲裁：跨 batch 冲突必须进入 owner 决策，而不是被 LLM 静默合并。

---

## Dependencies / Assumptions

- 目标运行环境能使用足够强的 LLM，并能承受全仓自动分析所需的上下文、时间和成本。
- 目标仓库路径可读，敏感文件可以被识别并跳过或脱敏记录。
- batch 规划、evidence 分类、质量门禁和 review summary 已有基础契约，可在规划阶段决定如何扩展为 full-auto draft pipeline。
- owner 愿意在生成后承担审批职责，否则 full-auto draft 只能停留为候选资产。
- 真实质量提升需要后续通过 AI 开发任务和 Review 场景验证，不能只依赖一次离线生成结果。

---

## Outstanding Questions

### Deferred to Planning

- [Affects R1, R4][Technical] full-auto 运行应如何控制最大 batch 数、上下文预算、失败重试和运行时间。
- [Affects R5, R8][Technical] 质量分层的置信度计算应如何组合 evidence tier、batch 代表性、LLM 判断和 reviewer persona 结果。
- [Affects R12, R14][Technical] 跨 batch 去重、合并建议和冲突归并的具体规则应如何设计，避免重复规则膨胀。
- [Affects R16, R18][Needs research] golden evals 应覆盖哪些真实项目、历史坑、legacy 样例和冲突样例，才能证明规范质量提升。
- [Affects R17][Technical] review summary 和 owner approval queue 的具体呈现格式由计划阶段确定。
