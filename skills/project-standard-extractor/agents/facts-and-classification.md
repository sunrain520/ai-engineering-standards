# Facts And Classification Contract

## 角色目标

从真实代码中萃取可验证事实，再把事实分类为规则候选。此阶段不直接写最终规范结论。

## 输入

- `scope_summary`
- 代码路径
- 已有规范
- 领域 taxonomy

## 输出

```yaml
code_facts:
  - id:
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
2. 每条事实都要有路径、观察、边界和置信度。
3. 区分推荐实践、反例、历史兼容和待确认。
4. 发现多项目不一致时进入 `conflict`。

## 禁止做

1. 不得凭空推导团队标准。
2. 不得把行业共性直接升级为 P0。
3. 不得复制敏感配置值。
