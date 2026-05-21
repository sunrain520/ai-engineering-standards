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
run_id: 20260521-180500-app-client
```

## 2. Code Facts

写入 `01-app-client/common/evidence/code-facts.md`(因为是跨 sub_domain 共性事实):

```markdown
## EV-APP-001: APP 规范要求 UI 薄、共享逻辑下沉 KMP

- 来源路径：engineering-standards/01-app-client/00-app-client-overview.md
- 子领域：common
- 观察事实：文档定义"共享逻辑放 KMP，平台逻辑放 ViewModel 或 Reactor，页面只负责渲染，数据访问统一走数据中台"。
- evidence_tier: cross-project
- 推导边界：来自现有规范文档，不是业务源码事实；可用于验证输出链路，后续仍需真实代码 evidence。
- 敏感信息处理：不涉及
- run_id: 20260521-180500-app-client
- first_seen: 2026-05-21
- last_seen: 2026-05-21
- 关联规则: `01-app-client/common/standard.md「P1 可跨端复用逻辑优先下沉 KMP」`
```

注意:此条 evidence 来源是 owner 已确认的规范文档,因此 evidence 元数据 `source_kind` 在规则侧记为 `owner-confirmed`,但 `evidence_tier` 记为 `cross-project`(规范文档跨多个 APP 项目落地)而非 `none`。

## 3. Rule

写入 `01-app-client/common/standard.md`:

```markdown
## P1 可跨端复用逻辑优先下沉 KMP

status: draft
level: P1
source_kind: owner-confirmed
evidence_tier: cross-project
risk_tag: medium
owner: TBD
last_reviewed: null
recommended_action: keep-draft
conflicts_with: []
superseded_by: null

### 规则

APP 端可跨 Android 和 iOS 复用的核心业务逻辑，应优先下沉到 KMP 共享层。平台层只保留 UI 状态组织、平台差异和交互绑定。

### AI 生成代码要求

AI 处理 APP 需求时，必须先判断逻辑是否可跨端复用；可复用逻辑不得在 Android 和 iOS 重复实现。

### Code Review 检查项

- [ ] 是否存在 Android / iOS 重复实现同一核心业务规则？
- [ ] 可复用逻辑是否已评估进入 KMP？
- [ ] 平台层是否只保留状态组织和 UI 渲染？

### Evidence

- evidence_tier: cross-project
- code-facts: `evidence/code-facts.md「EV-APP-001」`
```

## 4. AI Rules Entry

`01-app-client/common/ai-rules.md` §2 列出:

- `01-app-client/common/standard.md「P1 可跨端复用逻辑优先下沉 KMP」`
  - 关键约束: 跨端复用逻辑必须先评估 KMP,平台层不重复实现核心业务规则
  - AI 自检必查项: 当前需求是否可跨端? 是否已评估 KMP?

并提示:

- `status: draft`
- `source_kind: owner-confirmed`
- `evidence_tier: cross-project`
- 需要 APP 负责人补真实代码 evidence 后,由负责人手工改 `status: active`

## 5. Review Checklist Entry

`01-app-client/common/review-checklist.md` §1 / §2 由 generation 派生:

- [ ] `01-app-client/common/standard.md「P1 可跨端复用逻辑优先下沉 KMP」`
  - 检查点: 需求归属是否已判断 KMP / Android / iOS;跨端复用逻辑是否没有重复写在双端;数据访问是否仍通过 Repository / HSDataCenterKit

## 6. Negative Cases

### 无证据规则

候选：`APP 所有页面都必须使用某个具体 Loading 组件。`

处理：没有当前 evidence，进入 `pending-confirmation.md`(`PENDING-APP-001`),不得进入 `ai-rules.md`。

### 路径进入规则正文

错误：规则正文写入 `engineering-standards/01-app-client/00-app-client-overview.md`。

处理：Team Standard Reviewer 要求改写，路径只保留在 evidence。

### 重复运行

如果已有 `01-app-client/common/standard.md「P1 可跨端复用逻辑优先下沉 KMP」`:

- 不覆盖原规则。
- 新事实追加到 `evidence/code-facts.md`(同一 EV 条目编号 `last_seen` 更新,新事实另开 `EV-APP-002` 编号)。
- 差异写入 `merge-suggestions.md`。

### 敏感配置

如果输入路径包含 `.env` 或 `prod-config.yml`：

- 只记录"发现敏感配置文件路径"。
- 不读取和不复制任何值。

## 7. Merge Result

本 dogfood 证明以下产物可以被生成：

- `code-facts`
- evidence-backed `draft` rule(以二元组定位,**不使用 Rule ID**)
- `ai-rules` entry
- `review-checklist` entry
- review report
- merge suggestion / pending / conflict 处理策略
