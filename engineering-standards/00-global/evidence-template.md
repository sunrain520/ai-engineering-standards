# Evidence 模板

## 1. Code Facts

```markdown
## EV-{DOMAIN}-{NUMBER}: {事实标题}

- 来源项目：
- 研发域：
- 子领域：
- 观察到的代码路径：
- 观察事实：
- 推导边界：
- 不确定点：
- 敏感信息处理：已脱敏 / 不涉及 / 仅记录存在
```

## 2. Positive Examples

```markdown
## POS-{DOMAIN}-{NUMBER}: {正例标题}

- Evidence ID:
- 路径：
- 推荐模式：
- 可提炼规则：
- 适用范围：
```

## 3. Forbidden Examples

```markdown
## NEG-{DOMAIN}-{NUMBER}: {反例标题}

- Evidence ID:
- 路径：
- 问题：
- 风险：
- 替代做法：
- 是否为历史兼容：
```

## 4. Legacy Compatible

```markdown
## LEGACY-{DOMAIN}-{NUMBER}: {历史兼容标题}

- 路径：
- 历史原因：
- 允许保留范围：
- 新代码禁止事项：
- 迁移建议：
```

## 5. 安全边界

Evidence 不得包含：

1. 密钥、token、私钥、证书原文。
2. 生产环境账号、密码、域名凭据。
3. 用户隐私数据、交易数据、资金数据原文。
4. 可直接复用的内部敏感配置值。
