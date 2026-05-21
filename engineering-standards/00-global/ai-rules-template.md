# AI Coding Rules 模板

## 1. 使用前提

AI 只能默认执行 `source_kind` 为 `extracted` 或 `owner-confirmed`，且 `evidence_tier` 不为 `none` 的规则。

遇到以下情况必须提示用户或写入自检说明：

1. 规则状态是 `draft`。
2. 规则等级是 `P0` 或 `FORBIDDEN`。
3. 规则涉及安全、交易、账户、资金、合规、行业高风险。
4. 规则 evidence 不完整或只有负责人确认。
5. 规则处于 `pending-confirmation`、`conflict`、`legacy-compatible`。

## 2. 生成前检查

AI 生成代码前必须回答：

1. 当前需求属于哪个研发域和子领域？
2. 是否已有相同模块、组件、Repository、Service、UseCase 或工具？
3. 是否存在 `active` 或可临时使用的 `draft` 规则？
4. 是否涉及多项目差异、行业差异或历史兼容？
5. 是否需要新增 evidence 或待确认规则？

## 3. 禁止生成

AI 不得生成：

1. 绕过团队公共网络、缓存、日志、配置、权限、安全体系的代码。
2. UI / Controller / View 层直接承载复杂业务规则的代码。
3. 直接依赖后端 DTO、数据库 Entity 或底层 API 的展示代码。
4. 没有 evidence 却声称是团队强制规范的规则。
5. 把某个项目路径、微服务结构或历史包袱写成通用标准。
6. 包含密钥、token、生产凭据或敏感配置值的 evidence。

## 4. 自检输出

每次完成后输出：

```markdown
### AI 自检

- 适用规则：
- 使用的 evidence：
- 未使用规则及原因：
- 是否存在 draft / pending / conflict：
- 是否需要负责人确认：
```
