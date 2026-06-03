---
doc_id: "app-client-security-compliance-standard-archived"
title: "APP 安全与合规规范（待 evidence 归档）"
domain: "app-client"
sub_domain: "security-compliance"
doc_type: "standard"
version: "v0.1.0"
status: "archived"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
coverage_state: "sanitized-build-signing-only"
tags:
  - "app-client"
  - "security-compliance"
  - "archived"
---

> 本次 `hszq-app` run 只记录发布签名变量的脱敏存在事实，相关待确认项见 `pending-confirmation.md`。本文其余安全合规内容仅作历史草案。

# APP 安全与合规规范

> 当前文档是 APP 安全与合规的萃取维度说明，状态为 structure-ready。具体强制规则必须由后续真实 evidence 或负责人确认补齐。

## 1. 适用范围

本规范覆盖 token、账号态、权限、隐私数据、交易/账户/订单等高风险业务、日志脱敏、截图/剪贴板/本地存储、网络安全和行业合规边界。

行业细则应与 `engineering-standards/09-industry/` 联动；没有行业负责人确认或真实 evidence 的内容不得升级为强制规则。

## 2. 萃取时应关注的 evidence

| 维度 | 候选代码信号 |
| --- | --- |
| 账号态与权限 | login/session/account manager、permission check、auth interceptor |
| 敏感数据 | token、手机号、证件、资金、持仓、订单、交易密码 |
| 本地存储 | MMKV、SharedPreferences、Keychain、database、cache file |
| 日志与埋点 | log、trace、analytics、crash、sensors |
| 安全能力 | SSL pinning、加密、root/jailbreak、screenshot protection |

## 3. 应沉淀的规则内容

1. token、账号态、交易凭证和隐私数据不得进入普通日志、埋点或崩溃附加信息。
2. 高风险业务入口必须校验登录态、权限、展业地和交易状态。
3. 本地缓存敏感数据必须说明存储位置、加密方式、清理时机和跨账号隔离。
4. 截图、剪贴板、分享、导出等用户数据外流场景必须有合规边界。
5. 行业高风险规则必须标注 evidence 或负责人确认来源。

## 4. AI 生成代码要求

1. AI 涉及账号、交易、资金、持仓、订单、隐私字段时必须输出安全影响说明。
2. AI 不得生成打印 token、手机号、证件号、交易参数或资金数据的日志。
3. AI 新增本地存储必须说明是否敏感、是否加密、何时清理。

## 5. Code Review 检查项

- [ ] 敏感字段是否脱敏或不采集。
- [ ] 高风险入口是否有登录态、权限和业务状态校验。
- [ ] 本地敏感数据是否有加密和清理策略。
- [ ] 日志/埋点/Crash 是否不含敏感原值。
- [ ] 行业规则是否有 owner-confirmed 或真实 evidence。
