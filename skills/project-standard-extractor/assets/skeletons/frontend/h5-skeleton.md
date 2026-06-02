---
doc_id: "frontend-h5-standard"
title: "H5 / 移动端 Web 开发规范"
domain: "frontend"
sub_domain: "h5"
doc_type: "standard"
version: "v0.1.0"
status: "draft"
owner: "TBD"
source_batch: "{{batch_id}}"
evidence_tier: "{{evidence_tier}}"
last_reviewed: "{{last_reviewed}}"
run_id: "{{run_id}}"
activation_state: "{{activation_state}}"
tags: ["frontend", "h5", "mobile-web"]
---

# H5 / 移动端 Web 开发规范

## 1. 规范定位 [{{activation_state_section_1}}]

- 子领域:`h5`(移动端 Webview / 浏览器场景)
- 端类型:`frontend`
- 激活态:`{{activation_state}}`

## 2. 职责边界 [{{activation_state_section_2}}]

**应承载**:viewport / 移动手势 / JSBridge 通信 / 弱网降级 / 首屏性能。
**不应承载**:管理后台桌面交互、Node SSR 业务逻辑。

## 3. 推荐目录 [{{activation_state_section_3}}]

```text
src/
├── pages/                       — 路由 + 屏幕级容器
├── components/                  — 通用组件
├── bridge/                      — JSBridge / WeixinJSBridge 封装
├── hooks/
└── utils/
```

## 4. 分层规则 [{{activation_state_section_4}}]

| 层级 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| View(JSX/TSX) | 渲染、交互 | 直接 fetch / localStorage 写入 |
| Hook | 业务逻辑、状态获取 | 持有 DOM 引用 |
| Bridge | JSBridge 调用封装 | 业务规则混入 |
| Service | 网络 / 存储抽象 | 与 UI 框架强耦合 |

## 5. 命名规范 [{{activation_state_section_5}}]

- 组件 PascalCase:`OrderDetailPanel`
- Hook `use*` 前缀:`useOrderDetail`
- Bridge 方法 camelCase:`callNativeShare`

## 6. 核心规则 [{{activation_state_section_6}}]

### P1 viewport 配置 [{{activation_state}}]

> level: P1 · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: medium · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

**强制规则**:`<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">`,iOS 安全区使用 `env(safe-area-inset-*)`。

### FORBIDDEN 直接污染 window 全局

> level: FORBIDDEN · status: draft · source_kind: extracted · evidence_tier: {{evidence_tier}} · risk_tag: high · owner: TBD · last_reviewed: {{last_reviewed}} · recommended_action: keep-draft · confidence_tier: normal · authority_scope: none · upgrade_mode: none · deterministic_occurrence_count: null · last_evidence_confirmed_run: null

> ⛔ **FORBIDDEN**:`window.__xxx = ...` 直接挂业务对象。所有 JSBridge 必须经统一 `bridge/` 命名空间封装。

## 7. 数据流链路 [{{activation_state_section_7}}]

```text
View → Hook → Service / Bridge → 网络 / Native
```

## 8. 平台差异 [{{activation_state_section_8}}]

| 容器 | 差异 | 处理 |
| --- | --- | --- |
| 微信浏览器 | WeixinJSBridge 注入时机 | `WeixinJSBridgeReady` 监听 |
| iOS WKWebView | 安全区 / 100vh bug | `env(safe-area-inset-*)` + viewport-fit=cover |
| Android WebView | input 弹键盘 viewport | resize 监听适配 |

## 9. 错误模型 [{{activation_state_section_9}}]

- 网络错误统一 `ApiError` 类型;Toast / 重试由 Hook 决定
- JSBridge 调用失败必须在 Bridge 封装中重试 + 上报

## 10. AI 生成要求 [{{activation_state_section_10}}]

- AI 生成 H5 代码必须使用 viewport meta 标准模板
- localStorage / sessionStorage 必须捕获 QuotaExceededError
- 不得引入桌面专用控件库

## 11. Review 检查项 [{{activation_state_section_11}}]

- [ ] viewport meta 满足 viewport-fit=cover
- [ ] JSBridge 全部经 `bridge/` 封装
- [ ] 无 window 全局污染

## 12. Evidence 参考 [{{activation_state_section_12}}]

| evidence_id | 来源文件 | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-FE-{{N}}` | `src/**/*.tsx` | {{core_observation}} | {{confidence}} |
