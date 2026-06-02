# project-standard-extractor 30 分钟团队分享稿

## 1. 分享定位

主题：把真实代码变成 AI 可复用、Reviewer 可检查、owner 可治理的团队规范。

听众：核心研发、Reviewer、AI 重度使用者、规范 owner。

本场要让大家记住三句话：

1. 默认路径是一键 full-auto，但内部仍是 profile-first + 单 batch worker。
2. 只有 `auto-active` / `owner-confirmed-active` 进入 AI 默认执行路径。
3. owner 从“运行前逐 batch 选择”变成“运行后审查、否决、降级和确认”。

不展开：Phase 2 `dimension-activator`、force-rebuild、restore、pin/unpin/list、跨项目统一规范和行业 PoC。

## 2. 30 分钟结构

| 时间 | 模块 | 结论 |
| --- | --- | --- |
| 0-3 分钟 | AI 缺什么 | 缺团队真实上下文，不是缺通用最佳实践 |
| 3-7 分钟 | 一句话定位 | 从真实代码 evidence 萃取规范资产 |
| 7-14 分钟 | 默认 full-auto 路径 | profile-first 仍在内部，用户不用手动选 batch |
| 14-20 分钟 | 状态与消费 | auto-active / owner-confirmed-active 才默认执行 |
| 20-25 分钟 | owner 怎么治理 | owner queue、stale-auto-active、owner-rejected |
| 25-30 分钟 | 试点方式 | 选一个成熟模块跑，检查 usable_now 和 review summary |

## 3. 开场稿

```text
AI 现在能写很多代码，但它不知道我们团队这里应该怎么写。
通用最佳实践不等于团队规范，历史代码也不等于推荐写法。
project-standard-extractor 解决的是：把真实项目里的团队经验，变成 AI 可消费、Reviewer 可检查、owner 可治理的规范资产。
```

## 4. 一句话定位

```text
project-standard-extractor 是从真实项目代码萃取团队级研发规范的生产线。
用户只提供 project_paths，默认 full-auto 跑完 profile、queue、per-batch worker、quality gate、merge、lineage 和 review summary。
```

稳定产物：

- `standard-{sub_domain}.md`
- `ai-rules.md`
- `review-checklist.md`
- `evidence/*`
- `pending-confirmation.md`
- `merge-suggestions.md`
- `conflicts.md`
- `lineage-ledger.json`
- `owner-decision-queue.json`
- `temp/{run_id}-review-summary.md`

## 5. 默认路径

```text
project_paths
  -> profile-first
  -> ordered_batch_queue
  -> ready batch worker
  -> pending-confirmation low-confidence worker
  -> skipped/blocked coverage only
  -> review gate
  -> merge by target_state
  -> artifact validators
  -> review summary
```

要强调：

- full-auto 不是全仓一次性生成。
- 每个 worker 仍只处理一个 batch。
- pending-confirmation batch 可以自动执行，但只产出 low-confidence / pending 内容。
- skipped/blocked 不伪造规则，只进入 coverage report。
- Phase 1 不要求、不生成 `activation-report`。

## 6. 状态模型

| 状态 | AI 默认执行 | 说明 |
| --- | --- | --- |
| `auto-active` | 是 | 通过高置信自动升级闸 |
| `owner-confirmed-active` | 是 | owner 手动确认 |
| `draft` | 否 | 可参考，不是强制规则 |
| `pending-confirmation` | 否 | 证据不足、高风险或需确认 |
| `stale-auto-active` | 否 | 自动复检失效，已移出执行路径 |
| `owner-rejected` | 否 | owner 否决，终态 |
| `conflict` / `legacy-compatible` / `rejected` | 否 | 不进入默认执行 |

讲稿：

```text
auto-active 不是“AI 替团队拍板”，而是“这条规则在本仓 evidence 下足够代表当前项目实践，可以先进入默认执行路径，同时进入 owner queue 等待事后审查”。
```

## 7. Auto-active 闸

过闸必须同时满足：

- deterministic occurrence count 不低于 2。
- confidence high。
- 多文件/多角色覆盖。
- evidence 充分、结构完整、无未裁定 conflict。
- 未命中 `anti-pattern-blocklist.yaml`。
- 非 security/auth/cryptography/permission/compliance 等高风险域。

命中黑名单或高风险域，即使高频也进入 `pending-confirmation`。

## 8. Owner 如何参与

owner 不再需要运行前逐个挑 batch。full-auto 跑完后，owner 看：

- `temp/{run_id}-review-summary.md`
- `owner-decision-queue.json`
- `lineage-ledger.json`
- `pending-confirmation.md`
- `conflicts.md`
- `merge-suggestions.md`

owner 可以：

- 确认 auto-active，变成 `owner-confirmed-active`。
- 否决 auto-active，变成 `owner-rejected`。
- 降级为 draft 或 pending。
- 裁定 conflicts。
- 处理 `stale-auto-active`。

## 9. Coverage 话术

```text
coverage report 只承诺 profile 识别范围内的覆盖。
它会列出 blind spots：不可读路径、跳过目录、未解析模块。
所以“full-auto”不是“保证全仓无遗漏”，而是“把能识别、能验证、能追溯的部分自动跑完”。
```

如果新仓库 evidence 稀疏，`usable_now` 可能全是 no。这不是失败，而是告诉团队：当前代码还不足以产出默认强制规则。

## 10. FAQ

### Q1: 能不能直接给一个仓库生成全部规范？

可以给完整仓库路径，默认 full-auto 会跑 profile 和 queue。但“全部”指 profile 识别范围内的可执行 batch；blind spots 会在 coverage report 中列出。

### Q2: draft 能不能给 AI 用？

可以作为参考上下文，但不能作为默认强制规则。默认强制只使用 `auto-active` / `owner-confirmed-active`。

### Q3: auto-active 错了怎么办？

owner 标 `owner-rejected` 后，下次运行会移出默认执行路径。已按错误规则合并过的业务代码不会自动回滚，这是残余风险，需要团队自行处理。

### Q4: 为什么 Phase 1 不用 activation-report？

activation-report 属于 Phase 2 dimension-aware repair 路径。Phase 1 的生成、review、merge 都按 batch evidence 和 `target_state` 走，不合成假 report。

## 11. 试点建议

第一周做一个成熟模块试点：

1. 用完整仓库路径跑 full-auto。
2. 看 review summary 的 usable_now、coverage blind spots 和 owner queue。
3. 选择 1-3 条 auto-active 在一次 AI 开发或 Review 中验证。
4. 对不认可的规则标 owner-rejected 或降级。
5. 复跑一次，确认 owner-rejected / stale-auto-active 不再进入默认执行路径。
