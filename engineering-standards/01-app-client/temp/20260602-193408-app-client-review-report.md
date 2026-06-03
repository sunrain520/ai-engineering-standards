---
doc_id: "app-client-20260602-193408-review-report"
title: "hszq-app Quality Gate Report"
domain: "app-client"
sub_domain: "common"
doc_type: "review-report"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "review-report"
  - "hszq-app"
---

# hszq-app Quality Gate Report

| Gate | 结果 | 说明 |
| --- | --- | --- |
| Evidence | PASS | 30 条 code facts、14 条 positive examples、5 条 forbidden examples、3 条 legacy-compatible facts |
| Team abstraction | PASS | 规则正文不写目标项目绝对路径，路径集中在 evidence |
| AI executability | PASS | auto-active 进入 ai-rules.md；pending 只作为 warning |
| Reviewability | PASS | review-checklist.md 条目可 yes/no 判定 |
| High-risk handling | PASS | 签名变量注入保持 pending/security-review |
| Blind spots | PASS | KMP shared 源码内部规范因缺少 submodule 未强制声明 |

## Review note

用户要求覆盖重写当前规范文档，因此本次未按 append-only 保留旧正文为 active；旧编号文档已降级为归档/待 evidence 入口。
