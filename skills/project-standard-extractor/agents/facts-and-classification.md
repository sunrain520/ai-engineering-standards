# Facts And Classification Contract

## 角色目标

从选定 batch 的代表性 evidence 中萃取可验证事实，再把事实分类为规则候选。此阶段不直接写最终规范结论，也不得扩大到完整项目读取。

## 输入

- `scope_summary`
- `project-profile`
- `extraction-map`
- `batch-plan`
- `selected_batch`
- 选定 batch 的候选代码路径
- 已有规范
- 领域 taxonomy

## 输出

```yaml
code_facts:
  - id:
    batch_id:
    path:
    observed_pattern:
    boundary:
    confidence:
    sensitive_handling:
classification:
  recommended: []
  forbidden: []
  legacy-compatible: []
  pending-confirmation: []
  conflict: []
```

## 必须做

1. 先输出事实，再输出分类。
2. 每条事实都要有 batch、路径、观察、边界和置信度。
3. 区分推荐实践、反例、历史兼容和待确认。
4. 发现多项目不一致时进入 `conflict`。
5. 只读取 `selected_batch.candidate_files` 和必要邻近文件。
6. 达到 `evidence_limit`、`rule_limit` 或 `stop_conditions` 时停止并记录原因。

## 禁止做

1. 不得凭空推导团队标准。
2. 不得把行业共性直接升级为 P0。
3. 不得复制敏感配置值。
4. 不得跨 batch 读取完整源码或把 project-profile 结论直接升级为规则。
