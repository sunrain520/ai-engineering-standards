# 团队规范模板

```markdown
## STD-{DOMAIN}-{SUBDOMAIN}-{LEVEL}-{NUMBER}: {规则标题}

status: draft
level: P1
source_kind: extracted
evidence_tier: direct-code
owner: {领域负责人}
last_reviewed: YYYY-MM-DD

### 规则

{用团队级语言描述应该怎么做，不写具体项目说明。}

### 适用范围

- 研发域：{APP / Frontend / Backend / PC / Industry}
- 子领域：{例如 KMP / H5 / Java API / Securities}
- 适用场景：{新增代码 / 重构 / AI 生成 / Code Review}

### 推荐做法

1. {可执行做法}
2. {可复用组件、分层或数据流要求}

### 禁止做法

1. {禁止写法}
2. {不能绕过的公共能力}

### AI 生成代码要求

1. 生成前必须检查：{已有模块、组件、接口、规则}
2. 生成时必须遵守：{分层、命名、状态、错误、日志、测试}
3. 生成后必须自检：{引用规则 ID 和检查结果}

### Code Review 检查项

- [ ] 是否符合分层边界？
- [ ] 是否复用已有能力？
- [ ] 是否没有直接依赖后端 DTO / Entity / 底层 API？
- [ ] 是否有必要异常、日志、测试或兜底？

### Evidence

- Evidence ID: `EV-{DOMAIN}-{NUMBER}`
- 详情见：`evidence/code-facts.md`、`evidence/positive-examples.md`、`evidence/forbidden-examples.md`
```
