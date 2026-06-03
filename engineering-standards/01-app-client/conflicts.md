---
doc_id: "app-client-conflicts"
title: "APP 客户端冲突记录"
domain: "app-client"
sub_domain: "common"
doc_type: "conflicts"
version: "v0.1.0"
status: "active"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: true
run_id: "20260602-193408-app-client"
tags:
  - "app-client"
  - "conflicts"
---

# APP 客户端冲突记录

本次覆盖重写未发现需要阻断写入的规则冲突。

## 当前冲突

- 暂无。

## 覆盖重写说明

用户明确要求直接覆盖重写当前存在的规范文档，因此本次未按 append-only 生成 `conflict` 项来保护旧正文。旧正文若需恢复，应通过 git 历史对比或 owner 决策重新纳入。
