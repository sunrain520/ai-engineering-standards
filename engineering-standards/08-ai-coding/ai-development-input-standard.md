# AI 辅助开发标准输入

每次使用 AI 辅助需求开发前，应尽量提供以下输入。

## 1. 必填输入

```markdown
当前需求：

当前研发域：

当前子领域：

相关代码路径：

相关规范：
- engineering-standards/00-global/rule-lifecycle.md
- engineering-standards/{domain}/...
```

## 2. 推荐输入

- 业务模块。
- 接口文档或数据模型。
- 设计稿或交互说明。
- 已有正例路径。
- 已有反例或历史兼容路径。
- 行业、合规、安全关注点。

## 3. AI 必须先输出

1. 需求归属判断。
2. 可复用能力。
3. 应遵守规则定位（`{source_doc}「{section_title}」`）。
4. draft / pending / conflict 风险。
5. 修改文件列表。
6. 实现方案。
7. 测试方案。
8. 自检清单。

## 4. 禁止

AI 不得：

1. 跳过规范和 evidence。
2. 执行 `pending-confirmation` 或 `conflict` 规则。
3. 把无证据模板内容当作团队标准。
4. 输出包含密钥、token、生产凭据或敏感配置原值的内容。
