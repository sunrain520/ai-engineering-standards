# Golden Sample Run

本样例用于证明 `project-standard-extractor` 的最小闭环可由 `SKILL.md` 入口驱动。样例内容为合成输入，不代表真实团队规则；真实运行必须替换为项目代码路径和实际 evidence。

## 1. 输入

```yaml
project_paths:
  - /repo/order-service
dev_domain: unknown
industry_domain: unknown
output_scope: full package
```

## 2. Intake and Scope

推断：

- `dev_domain`: Backend
- `sub_domains`: Java、API、Database
- `industry_domain`: securities candidate，因为路径和模块名出现 order / trade 语义
- `run_id`: `20260521-180000-backend`

需要确认：

1. 是否按 Backend 输出？
2. 是否生成独立行业待确认项？
3. 是否允许读取 `src/main/java`？
4. `.env`、`application-prod.yml` 只记录存在事实，不读取值。

## 3. Project Profile / Extraction Map / Batch Plan

因为输入是服务根目录且研发域未知，先进入 `profile-first`，不生成正式规范规则。

输出：

- `04-backend/20260521-180000-backend-project-profile.md`
- `04-backend/20260521-180000-backend-extraction-map.md`
- `04-backend/20260521-180000-backend-batch-plan.md`

可选 batch：

```yaml
batches:
  - batch_id: backend-java-api-order
    domain: backend
    sub_domain: java
    module: order
    task_type: api-development
    candidate_files:
      - path: order-service/src/main/java/.../OrderController.java
        reason: 订单查询 API 入口
        evidence_kind: positive
    excluded_paths:
      - path: order-service/src/main/resources/application-prod.yml
        reason: sensitive production config
    evidence_limit: 8
    rule_limit: 10
    status: ready
```

用户选择 `backend-java-api-order` 后，下一轮进入 `batch-extraction`。

## 4. Code Facts

写入 `04-backend/java/evidence/code-facts.md`:

```markdown
## EV-BE-001: Controller 只做请求接入

- batch_id: backend-java-api-order
- 来源项目：order-service
- 路径：order-service/src/main/java/.../OrderController.java
- 子领域：java
- 观察事实：Controller 接收 request，调用 OrderService，返回 Response DTO。
- 推导边界：仅证明订单查询接口存在该模式，不证明所有后端服务都一致。
- evidence_tier: single-project
- 置信度: medium
- 敏感信息处理：不涉及
- run_id: 20260521-180000-backend
- first_seen: 2026-05-21
- last_seen: 2026-05-21
- 关联规则: `04-backend/java/standard.md「P1 Controller 只负责请求接入和响应返回」`
```

## 5. Pattern Classification

```yaml
recommended:
  - EV-BE-001
forbidden: []
legacy-compatible: []
pending-confirmation:
  - 行业交易规则需要证券业务负责人确认
conflict: []
```

## 6. Rule Generation

写入 `04-backend/java/standard.md`:

```markdown
## P1 Controller 只负责请求接入和响应返回

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-21 · recommended_action: keep-draft

### 适用范围

- 后端 Java Spring Controller、Web 层入口、REST API。

### 强制规则

1. Controller 只负责参数接收、基础校验、调用 Service 和返回 Response DTO。
2. Controller 不直接访问数据库或外部服务。

### 禁止做法

Controller 不得直接访问 Repository / Mapper，不得直接返回 Entity。

### AI 生成代码要求

AI 新增接口时必须先检查是否已有 Service，不得在 Controller 中编写业务编排。

### Code Review 检查项

- [ ] Controller 是否直接访问 Repository / Mapper？
- [ ] Controller 是否直接返回 Entity？

### Evidence

- evidence_tier: single-project
- code-facts: `evidence/code-facts.md「EV-BE-001」`
```

真实路径只出现在 evidence，不出现在规则正文。规则不使用 Rule ID 与 HTML anchor。

## 7. AI Rules

`04-backend/java/ai-rules.md` §2 列出可执行清单:

- `04-backend/java/standard.md「P1 Controller 只负责请求接入和响应返回」`
  - 关键约束: Controller 不得调用 Repository / Mapper，不得返回 Entity
  - AI 自检必查项: Controller 是否仅做参数接收 / 校验 / Service 调用 / DTO 返回?

并提示:

- 状态：`status: draft`
- evidence_tier：`single-project`
- 需要后端负责人确认后才能由负责人手工改为 `status: active`

## 8. Review Checklist

`04-backend/java/review-checklist.md` §1 / §2 由 generation 从 standard.md 派生:

- [ ] `04-backend/java/standard.md「P1 Controller 只负责请求接入和响应返回」`
  - 检查点: Controller 是否只做请求接入 / 业务编排是否在 Service / 返回值是否为 Response DTO

## 9. Candidate Fast Index Artifacts

输出候选：

- `04-backend/temp/20260521-180000-backend-rules-index-candidate.json`
- `04-backend/temp/20260521-180000-backend-llms-candidate.txt`
- `04-backend/temp/20260521-180000-backend-ai-context-pack.md`

`rules-index` 候选条目使用 `title`、`domain`、`sub_domain`、`level`、`source_doc`、`section_title`、`evidence_doc`、`tags`，不使用 `rule_id` 或 `anchor`。

## 10. Quality Gate

```yaml
quality_gate_decision:
  source_doc: 04-backend/java/standard.md
  section_title: "P1 Controller 只负责请求接入和响应返回"
  target_state: draft
  recommended_action: keep-draft
  required_human_confirmation:
    - backend owner
```

行业交易规则因为没有行业负责人确认，进入 `pending-confirmation.md`。

## 11. Merge Coordinator

写入：

- `engineering-standards/04-backend/java/standard.md`
- `engineering-standards/04-backend/java/ai-rules.md`
- `engineering-standards/04-backend/java/review-checklist.md`
- `engineering-standards/04-backend/java/evidence/code-facts.md`
- `engineering-standards/04-backend/pending-confirmation.md`

不覆盖：

- 已有 `active` 规则
- 已有 `draft` 规则

## 12. 覆盖的验收示例

| 验收 | 证明 |
| --- | --- |
| AE1 输入引导 | 只给项目路径后推断研发域和行业场景 |
| AE2 团队级抽象与 evidence | 规则正文无路径，路径在 evidence |
| AE3 单项目高质量规则进入 draft | P1 规则带 evidence 进入 draft |
| AE4 多阶段 agent 编排 | profile-first -> batch-plan -> selected-batch facts -> classification -> generation -> review -> merge |
| AE5 高风险 draft 提示 | draft 输出 evidence_tier 和负责人确认项 |
| AE6 重复运行不覆盖 | Merge Coordinator append-only |
| AE7 二元组定位 | 规则统一以 `(source_doc, section_title)` 引用,不使用 Rule ID |
| AE8 上下文治理 | broad input 先输出 profile / map / batch plan,再选择单 batch |
| AE9 候选索引 | 输出 rules-index / llms / ai-context-pack candidate,不默认发布 |
