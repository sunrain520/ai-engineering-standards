---
doc_id: backend-evidence-forbidden
title: Backend Forbidden Examples
domain: backend
sub_domains:
  - java-spring
doc_type: evidence-forbidden
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
  - forbidden-example
---

# Backend Forbidden Examples

## NEG-BE-1: 事务内外部调用失败未回滚

- 关联 code-facts: `evidence/code-facts.md「EV-BE-2」`
- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- 问题: 写操作 Facade 事务内调用外部 Dubbo 失败，只 return error 未调 markRollbackOnly()，导致本地 DB 写入未回滚
- 风险: 数据不一致，DB 有记录但外部任务未创建
- 替代做法: 外部调用失败后先调 markRollbackOnly() 再 return error
- 支撑规则: `standard-java-spring.md「P1 写操作 Facade 必须加 @Transactional 并在外部调用失败时显式回滚」`
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23

## NEG-BE-2: DO 作为 Facade 接口返回值

- 关联 code-facts: `evidence/code-facts.md「EV-BE-5」`
- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- 问题: Facade 接口方法返回 DO 类型，导致 server 内部 DB 结构泄漏到 common 层，调用方依赖 DB 字段
- 风险: DB 表结构变更会破坏所有调用方；DO 含 @TableName 等注解不应出现在 common 层
- 替代做法: Facade 接口返回 Domain 对象，在 FacadeImpl 内用 Converter 转换
- 支撑规则: `standard-java-spring.md「P1 DO 不出 server 模块边界，Domain 不含 DB 注解」`
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23

## NEG-BE-3: Controller 直接注入 @DubboReference 跳过 admin Facade 层

- 关联 code-facts: `evidence/code-facts.md「EV-BE-8」`
- batch_id: `backend-java-spring-controller`
- sub_domain: `java-spring`
- 问题: DepositTaskController 直接注入 @DubboReference DepositTaskService，跳过 admin Facade 层，Controller 直接调 Dubbo Service
- 风险: Controller 承担了本应在 admin Facade 层做的业务编排；Controller 与 Dubbo 服务强耦合，难以复用和测试
- 替代做法: 新增 DepositTaskAdminFacade，Controller 只调 Facade，Facade 内调 Dubbo Service
- 支撑规则: `standard-java-spring.md「P1 Controller 只做参数绑定和 Facade 调用，不写业务逻辑」`
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
