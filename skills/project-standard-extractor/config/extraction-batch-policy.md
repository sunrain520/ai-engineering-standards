# Extraction Batch Policy

batch 是正式规范萃取的最小执行边界。所有 `batch-extraction` 都必须从 `batch-plan` 中选择一个 batch 后再读取 evidence。

## 1. Batch 字段

```yaml
batch_id: backend-java-api-order
domain: backend
sub_domain: java
module: order
task_type: api-development
candidate_files:
  - path: /repo/order-service/src/main/java/.../OrderController.java
    reason: Controller entry for order query API
    evidence_kind: positive
excluded_paths:
  - path: /repo/order-service/src/main/resources/application-prod.yml
    reason: sensitive production config
evidence_limit: 8
rule_limit: 10
stop_conditions:
  - no representative files
  - only inferred evidence
  - sensitive files are required to continue
status: ready
```

## 2. 状态

| status | 含义 | 后续动作 |
| --- | --- | --- |
| `ready` | 有代表性候选文件，可进入正式萃取 | 用户选择后执行 |
| `pending-confirmation` | 候选方向存在，但证据或负责人确认不足 | 先补输入或负责人确认 |
| `skipped` | 没有代表性 evidence 或超出范围 | 不生成规则 |
| `blocked` | 敏感、权限或读取边界阻塞 | 停止并说明原因 |

## 3. 生成规则

1. 一个 batch 对应一个明确的 `domain + sub_domain + module/task_type`。
2. `candidate_files` 是代表性候选，不是完整文件清单。
3. `excluded_paths` 必须记录敏感目录、生成物、依赖目录、构建产物和超出范围路径。
4. `evidence_limit` 和 `rule_limit` 必须显式写出。
5. batch 不得通过“common”吞掉多个独立子领域；跨子领域共性应单独建 `sub_domain: common` batch。

## 4. 停止条件

命中以下任一情况时停止该 batch：

- 没有代表性文件候选。
- 只有单点事实，却试图生成 P0 / FORBIDDEN。
- 继续萃取需要读取敏感文件原值。
- 候选规则数量超过 `rule_limit`。
- evidence 数量超过 `evidence_limit`。
- 需要跨 batch 才能成立。

停止后可写入 `pending-confirmation` 或 `skipped`，不得把不完整结论写入 AI 默认执行路径。
