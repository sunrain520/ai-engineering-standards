# 规则生命周期

## 1. 持久化状态

| 状态 | 含义 | AI 使用方式 |
| --- | --- | --- |
| `draft` | 已有最小 evidence 或负责人确认，等待正式审核 | 可临时使用，必须展示 evidence tier 和未转 active 状态 |
| `active` | 领域负责人已确认的正式规则 | 默认执行 |
| `pending-confirmation` | 证据不足、冲突未解或需要负责人判断 | 不得作为强制规则执行 |
| `conflict` | 多项目事实或规则口径冲突 | 不得执行，等待合并决策 |
| `legacy-compatible` | 历史代码允许暂存，新增代码不得扩大 | 仅用于识别历史兼容边界 |
| `rejected` | 已被质量门禁或负责人拒绝 | 不得执行，不得继续传播 |

升级候选不是状态，只能在评审报告中表达为：

```yaml
recommended_action: consider promotion
```

## 2. 规则等级

| 等级 | 含义 | 最低证据要求 |
| --- | --- | --- |
| `P0` | 强制规则，违反会破坏架构、安全、数据或核心质量 | 真实代码证据或负责人确认，必须有 Review 检查项 |
| `P1` | 默认应遵守的团队标准 | 至少一类代码、文档或负责人确认来源 |
| `P2` | 推荐实践或改进方向 | 可来自架构建议，但必须标记为建议 |
| `FORBIDDEN` | 明确禁止 AI 或研发继续生成的写法 | 必须有反例、风险说明和替代做法 |
| `LEGACY` | 历史兼容说明 | 必须标明历史边界和禁止扩大范围 |

## 3. 来源类型

| `source_kind` | 含义 | 是否可进入默认 AI 执行路径 |
| --- | --- | --- |
| `extracted` | 从真实代码事实萃取 | 是 |
| `owner-confirmed` | 由领域负责人确认 | 是 |
| `template-placeholder` | 模板占位或行业共性建议 | 否 |

## 4. 证据等级

| `evidence_tier` | 含义 |
| --- | --- |
| `direct-code` | 有真实代码路径、调用链或模块事实 |
| `review-issue` | 来自真实 Code Review、线上问题或缺陷复盘 |
| `owner-confirmed` | 负责人确认但暂未补代码证据 |
| `advisory` | 建议或行业共性，不能作为强制规则 |
| `none` | 无证据，只能进入模板、示例或待确认 |

## 5. 写入规则

1. 新运行不得覆盖已有 `active` 或 `draft`。
2. 新证据追加到 `evidence/`。
3. 相近规则写入 `merge-suggestions.md`。
4. 冲突规则写入 `conflicts.md`。
5. 无证据规则写入 `pending-confirmation.md` 或模板区。
6. 敏感配置、密钥、token、生产凭据只记录脱敏存在事实，不记录原值。
