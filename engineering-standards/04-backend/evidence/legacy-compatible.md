---
doc_id: backend-evidence-legacy
title: Backend Legacy Compatible
domain: backend
sub_domains:
  - java-spring
doc_type: evidence-legacy
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
  - legacy-compatible
---

# Backend Legacy Compatible

## LEG-BE-1: FacadeImpl 直接注入 Mapper（历史写法）

- 关联 code-facts: `evidence/code-facts.md「EV-BE-2」`
- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- 历史背景: MemberStockDepositFacadeImpl 直接注入 MemberStockDepositMapper 和 MemberStockDepositItemMapper，在 apply() 方法内直接调用 mapper.insert()，绕过了 WriteService 层。这是早期写法，当时 WriteService 尚未建立。
- 兼容范围: 仅 stock/deposit 模块的 apply() 方法，其他新增写操作已改为通过 WriteService
- 截止时间: 待重构
- 不得扩散范围: 新增 Facade 方法不得直接注入 Mapper，必须通过 WriteService
- 支撑规则: `standard-java-spring.md「P1 Service 接口按读写分离命名，WriteService 方法加 @Transactional」`
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
