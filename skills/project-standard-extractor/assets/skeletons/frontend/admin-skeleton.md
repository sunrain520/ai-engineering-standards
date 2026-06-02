---
doc_id: "frontend-admin-standard"
title: "管理后台开发规范"
domain: "frontend"
sub_domain: "admin"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["frontend", "admin", "dashboard"]
---

# 管理后台开发规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`admin`(内部 / 运营后台)
- 端类型:`frontend`
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:权限模型、复杂表单、数据表格、批量操作、审计日志展示。
**不应承载**:对外 C 端营销页、SDK 发布。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
src/
├── pages/
├── components/
├── layouts/                     — 主框架 / 侧边栏
├── auth/                        — 权限、菜单
├── api/                         — RPC / REST 封装
└── utils/
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| Layout | 侧边栏、顶栏、面包屑 | 业务请求 |
| Page | 业务页面容器、路由载荷 | 直接渲染原子 UI |
| Component | 表格、表单、Modal | 直接调用 API |
| API | 接口封装、错误统一 | 业务逻辑 |
| Auth | 权限判定、菜单生成 | 渲染 UI |

## 5. 命名规范 [{{activation_state_section_5}}]

- 页面组件:`*Page` 或 `*View`
- 表格列定义:`*Columns`,表单 schema:`*Schema`
- 权限点:`PERM_<DOMAIN>_<ACTION>`

## 6. 核心规则 [{{activation_state_section_6}}]

### P1 权限按钮 / 路由必须双层校验

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**强制规则**:前端按权限点渲染按钮 / 菜单,后端 API 必须二次校验;前端权限缺失视为 UX 兜底,**不可** 作为唯一防线。

### FORBIDDEN 表格直渲未分页全量数据

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ **FORBIDDEN**:列表页直接 fetch 全量并 `<Table dataSource={all} />`,必须服务端分页 + 虚拟滚动。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
Page → Hook(useTable / useForm) → API → Server
```

## 8. 平台差异 [{{activation_state_section_8}}]

- 桌面浏览器为主;若需移动端访问,使用响应式 layout 而非新建移动专用页

## 9. 错误模型 [{{activation_state_section_9}}]

- 全局拦截 401 / 403 → 跳登录或权限不足页
- 表单校验失败聚焦首个错误字段

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成表格必须使用项目内 Pro Table 封装,禁止裸 `<table>` + 手写分页
- AI 生成表单必须使用统一 schema,字段校验从 schema 推导

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] 列表分页参数 + 虚拟滚动
- [ ] 权限点前端 + 后端双层校验
- [ ] Modal / Drawer 关闭后清理订阅

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-FE-{{N}}` | `src/pages/**` | {{core_observation}} | {{confidence}} |
