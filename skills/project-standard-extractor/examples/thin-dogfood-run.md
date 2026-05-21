# Thin Dogfood Run

本 dogfood 使用当前仓库的低风险子目录作为 fixture：

```text
engineering-standards/01-app-client/
```

该目录不是业务源码，但包含已确认的 APP 规范文档。此 dogfood 的目标是验证 workflow 产物链路和安全边界，不声称完成真实业务代码萃取。

## 1. 输入

```yaml
project_paths:
  - engineering-standards/01-app-client/
dev_domain: APP
industry_domain: none
output_scope: full package
sub_domains:
  - KMP
  - Android
  - iOS
  - DataCenter
```

## 2. Code Facts

```markdown
## EV-APP-001: APP 规范要求 UI 薄、共享逻辑下沉 KMP

- 来源路径：engineering-standards/01-app-client/00-app-client-overview.md
- 观察事实：文档定义“共享逻辑放 KMP，平台逻辑放 ViewModel 或 Reactor，页面只负责渲染，数据访问统一走数据中台”。
- evidence_tier：owner-confirmed
- 推导边界：这是现有规范文档事实，不是业务源码事实；可用于验证输出链路，后续仍需真实代码 evidence。
- 敏感信息处理：不涉及。
```

## 3. Rule

```markdown
## STD-APP-ARCH-P1-001: 可跨端复用逻辑优先下沉 KMP

status: draft
level: P1
source_kind: owner-confirmed
evidence_tier: owner-confirmed

### 规则

APP 端可跨 Android 和 iOS 复用的核心业务逻辑，应优先下沉到 KMP 共享层。平台层只保留 UI 状态组织、平台差异和交互绑定。

### AI 生成代码要求

AI 处理 APP 需求时，必须先判断逻辑是否可跨端复用；可复用逻辑不得在 Android 和 iOS 重复实现。

### Code Review 检查项

- [ ] 是否存在 Android / iOS 重复实现同一核心业务规则？
- [ ] 可复用逻辑是否已评估进入 KMP？
- [ ] 平台层是否只保留状态组织和 UI 渲染？
```

## 4. AI Rules Entry

AI 可临时使用该规则，但必须提示：

- `status: draft`
- `source_kind: owner-confirmed`
- `evidence_tier: owner-confirmed`
- 需要 APP 负责人补真实代码 evidence 后再考虑升级 `active`

## 5. Review Checklist Entry

- [ ] 需求归属是否已判断 KMP / Android / iOS？
- [ ] 跨端复用逻辑是否没有重复写在双端？
- [ ] 数据访问是否仍通过 Repository / HSDataCenterKit？

## 6. Negative Cases

### 无证据规则

候选：`APP 所有页面都必须使用某个具体 Loading 组件。`

处理：没有当前 evidence，进入 `pending-confirmation.md`，不得进入 `ai-rules.md`。

### 路径进入规则正文

错误：规则正文写入 `engineering-standards/01-app-client/00-app-client-overview.md`。

处理：Team Standard Reviewer 要求改写，路径只保留在 evidence。

### 重复运行

如果已有 `STD-APP-ARCH-P1-001`：

- 不覆盖原规则。
- 新事实追加到 `evidence/code-facts.md`。
- 差异写入 `merge-suggestions.md`。

### 敏感配置

如果输入路径包含 `.env` 或 `prod-config.yml`：

- 只记录“发现敏感配置文件路径”。
- 不读取和不复制任何值。

## 7. Merge Result

本 dogfood 证明以下产物可以被生成：

- `code-facts`
- evidence-backed `draft` rule
- `ai-rules` entry
- `review-checklist` entry
- review report
- merge suggestion / pending / conflict 处理策略
