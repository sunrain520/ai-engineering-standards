---
doc_id: backend-pending-confirmation
title: Backend 待确认规则
domain: backend
sub_domain: common
doc_type: pending-confirmation
version: v0.1.0
status: pending
owner: TBD
index_format: engineering-standards-md-v1
indexable: false
run_id: 20260523-backend-java-spring
tags:
  - backend
  - pending-confirmation
---

# Backend 待确认规则

本文件记录 backend 规范萃取中证据不足、需要后端负责人确认或需要多服务对齐的规则候选。这里的内容不得被 AI 当作强制规范执行。

## PENDING-BE-1: Controller 层规范（hs-kaz-crm-admin）

- 状态: 待确认
- 拟定规则正文标题: `P1 Controller 只调 Facade，不写业务逻辑`
- 无法生成原因: 本次 batch 只覆盖 hs-kaz-crm-service 的 stock/deposit 模块，未读取 hs-kaz-crm-admin 的 Controller 源码
- 升级条件: 读取 hs-kaz-crm-admin 至少 3 个 Controller 文件，确认 Controller 只做参数绑定和 Facade 调用的模式在多个文件中一致

## PENDING-BE-2: Mapper 层规范（复杂查询写法）

- 状态: 已升级为规则
- 拟定规则正文标题: `P2 复杂查询用 @Select 注解或 XML，不在 Service 内拼 SQL`
- 无法生成原因: 本次 batch 读取的 Mapper 文件（MemberStockDepositMapper、MemberStockDepositItemMapper）主要是 BaseMapper 继承，未见复杂查询写法
- 升级结果: 已升级为 `standard-java-spring.md「P2 Mapper 复杂查询用 @Select 注解或 XML，不在 Service 内拼 SQL」`

## PENDING-BE-3: 跨服务调用 group 规范

- 状态: 已升级为规则
- 拟定规则正文标题: `P1 跨服务 @DubboReference 指定 group 时必须与服务端 @DubboService(group=...) 一致`
- 无法生成原因: 仅在 MemberStockDepositFacadeImpl 中见到 group = "hs-kaz-core-server"，单文件 evidence，置信度 medium
- 升级结果: 已升级为 `standard-java-spring.md「P1 @DubboReference 指定 group 时必须与服务端 @DubboService(group=...) 一致」`
