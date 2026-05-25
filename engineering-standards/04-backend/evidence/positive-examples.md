---
doc_id: backend-evidence-positive
title: Backend Positive Examples
domain: backend
sub_domains:
  - java-spring
doc_type: evidence-positive
version: v0.1.0
status: draft
owner: TBD
index_format: engineering-standards-md-v1
indexable: true
run_id: 20260523-backend-java-spring
source_batches:
  - backend-java-spring-stock-deposit
tags:
  - backend
  - java-spring
  - evidence
  - positive-example
---

# Backend Positive Examples

## POS-BE-1: 写操作 Facade 事务 + 外部调用失败回滚

- 关联 code-facts: `evidence/code-facts.md「EV-BE-2」`
- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- 推荐模式: @Transactional + 外部 Dubbo 失败调 markRollbackOnly()
- 支撑规则: `standard-java-spring.md「P1 写操作 Facade 必须加 @Transactional 并在外部调用失败时显式回滚」`
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23

## POS-BE-2: MQ 发送注册 afterCommit 回调

- 关联 code-facts: `evidence/code-facts.md「EV-BE-3」`
- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- 推荐模式: publishAfterCommit(() -> mqProducer.publish(...))
- 支撑规则: `standard-java-spring.md「P1 MQ 发送必须注册 afterCommit 回调，不得在事务内同步发送」`
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23

## POS-BE-3: DO/Domain/Converter 三层分离

- 关联 code-facts: `evidence/code-facts.md「EV-BE-5」`
- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- 推荐模式: DO 含 @TableName 只在 server 内；Domain 无 DB 注解在 common 层；StockDepositConverter 静态方法做转换
- 支撑规则: `standard-java-spring.md「P1 DO 不出 server 模块边界，Domain 不含 DB 注解」`
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23

## POS-BE-4: Controller 薄层 + @UserActionLog + @RequiresPermissions

- 关联 code-facts: `evidence/code-facts.md「EV-BE-8」`
- batch_id: `backend-java-spring-controller`
- sub_domain: `java-spring`
- 推荐模式: @UserActionLog("描述") + @RequiresPermissions("CRM:TASK:XXX") + 只调 Facade + simpleSuccess/simpleError 封装响应
- 支撑规则: `standard-java-spring.md「P1 Controller 只做参数绑定和 Facade 调用，不写业务逻辑」`
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
