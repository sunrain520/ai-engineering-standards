---
doc_id: "frontend-sdk-standard"
title: "前端 SDK / 库开发规范"
domain: "frontend"
sub_domain: "sdk"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["frontend", "sdk", "library"]
---

# 前端 SDK / 库开发规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`sdk`(对外发布的 npm 库 / JS SDK)
- 端类型:`frontend`
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:稳定 API、类型声明、Tree-shaking、版本兼容。
**不应承载**:业务页面、内部状态管理对外暴露。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
sdk/
├── src/
│   ├── index.ts                 — 入口
│   ├── core/
│   ├── adapters/                — 平台适配
│   └── types/
├── package.json                 — main / module / types / exports
├── rollup.config.ts             — 或 tsup.config.ts
└── README.md                    — 包含 install + quick start
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| 公共 API | 稳定函数 / 类签名 | 引入实验性 API |
| Adapter | 浏览器 / Node / RN 适配 | 业务规则 |
| Internal | 不导出的工具 | 出现在 `index.ts` |

## 5. 命名规范 [{{activation_state_section_5}}]

- 公共 API 使用动词 + 名词:`createClient`、`subscribeOrders`
- 类型从 `types/` 导出,前缀 `T*` 或同名

## 6. 核心规则 [{{activation_state_section_6}}]

### P1 package.json 必须配置 exports / types / module

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

**强制规则**:`exports` map 同时包含 `import` / `require` / `types`;`sideEffects` 显式声明以保 tree-shaking。

### FORBIDDEN 默认导出业务侧 React 组件

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft

> ⛔ **FORBIDDEN**:SDK 默认导出复杂 React 组件 + 默认样式,必须将 UI 与逻辑拆为可选 entry。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
调用方 → 公共 API → Internal Service → Adapter → 平台 / 网络
```

## 8. 平台差异 [{{activation_state_section_8}}]

| 平台 | 差异 | 处理 |
| --- | --- | --- |
| 浏览器 | DOM / fetch | adapter-browser |
| Node | http / fs | adapter-node |
| RN | AsyncStorage / fetch polyfill | adapter-rn |

## 9. 错误模型 [{{activation_state_section_9}}]

- 自定义 `SdkError` 子类,带 `code` 字段,文档明确错误码列表
- 不抛裸 `Error("string")`

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成公共 API 必须先在 `index.ts` 显式 `export`
- 类型 `.d.ts` 自动生成,禁止手写
- 新增依赖必须列入 `peerDependencies` 评估清单

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] package.json 含 main/module/types/exports/sideEffects
- [ ] 公共 API 100% 类型化
- [ ] semver 标记符合变更类型

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-FE-{{N}}` | `sdk/src/**` | {{core_observation}} | {{confidence}} |
