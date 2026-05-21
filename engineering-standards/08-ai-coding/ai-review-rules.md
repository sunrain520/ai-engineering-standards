# AI 生成内容评审规则

本文件用于 reviewer 检查 AI 生成内容是否符合团队规范工程要求。

## 1. 必拦问题

以下问题必须拦截：

1. AI 执行了 `pending-confirmation` 或 `conflict` 规则。
2. AI 把无 evidence 模板内容当作强制团队标准。
3. AI 在规则正文中写入具体项目路径。
4. AI 绕过既有公共能力或重复实现核心逻辑。
5. AI 输出敏感配置、密钥、token、生产凭据原值。
6. AI 自动把 `draft` 升级为 `active`。

## 2. 应要求补充

1. 缺少适用规则 ID。
2. 缺少自检清单。
3. 缺少测试或验证说明。
4. 未说明 draft / high-risk warning。
5. 未说明不确定点和负责人确认项。

## 3. 反哺规范

同类 AI 问题反复出现时，应写入对应 domain 的：

- `pending-confirmation.md`
- `merge-suggestions.md`
- `conflicts.md`
- `evidence/forbidden-examples.md`
