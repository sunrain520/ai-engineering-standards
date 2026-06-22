---
doc_id: backend-java-spring-standard
domain: backend
sub_domain: java-spring
doc_type: standard
index_format: engineering-standards-md-v1
generated_by_run: 20260604-020908-backend-java-spring-e76b1da
---

# java-spring 后端开发规范

## 适用范围

本规范适用于 `backend/java-spring` 抽取目标，由源码 evidence 和质量门禁派生。

## 规则

### backend-java-layering-001. Controller 不得直接访问 Mapper / Repository

- Status: auto-active
- Level: P1
- Risk: medium
- Rule: Controller 层只负责协议适配、参数接收和响应封装，业务编排与数据访问必须下沉到 Service 或更低层。
- Must: Controller must delegate business orchestration to Service or ApplicationService.
- Must Not: Controller must not call Mapper or Repository directly.
- Evidence:
  - FACT-BE-JAVA-0074: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/base/LoginLogoutController.java:25 (sha256:600ca48a2415986c24ea57aa3a597ae947ed4b0ce4078fc4531d1c93964501f9)
  - FACT-BE-JAVA-0077: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/ChannelCommissionController.java:30 (sha256:600ca48a2415986c24ea57aa3a597ae947ed4b0ce4078fc4531d1c93964501f9)
  - FACT-BE-JAVA-0084: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/CommissionFeeCodeController.java:62 (sha256:600ca48a2415986c24ea57aa3a597ae947ed4b0ce4078fc4531d1c93964501f9)
  - FACT-BE-JAVA-0095: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/CommissionPlanController.java:33 (sha256:600ca48a2415986c24ea57aa3a597ae947ed4b0ce4078fc4531d1c93964501f9)
  - FACT-BE-JAVA-0101: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/MemberCommissionController.java:39 (sha256:600ca48a2415986c24ea57aa3a597ae947ed4b0ce4078fc4531d1c93964501f9)
  - FACT-BE-JAVA-0110: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/MemberCommissionPlanLogController.java:24 (sha256:600ca48a2415986c24ea57aa3a597ae947ed4b0ce4078fc4531d1c93964501f9)
  - FACT-BE-JAVA-0113: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/MemberStepChargeApplyController.java:33 (sha256:600ca48a2415986c24ea57aa3a597ae947ed4b0ce4078fc4531d1c93964501f9)
  - FACT-BE-JAVA-0119: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/common/AttachmentController.java:42 (sha256:30ac9efe3c23e826380a75d9390c8256cfd59112d694b75137cd0307289ed709)
  - FACT-BE-JAVA-0001: hs-kaz-bss-service/hs-kaz-bss-server/src/main/java/com/huasheng/bss/admin/server/gsc/dc/facade/CustomerHistoryAssetQueryFacade.java:24 (sha256:f76d53d23446399cfd441b4e34fb78054db3b62c1f998cb0191a98a286a31bf8)
  - FACT-BE-JAVA-0002: hs-kaz-bss-service/hs-kaz-bss-server/src/main/java/com/huasheng/bss/admin/server/gsc/dc/facade/CustomerHistoryHoldingQueryFacade.java:28 (sha256:f76d53d23446399cfd441b4e34fb78054db3b62c1f998cb0191a98a286a31bf8)
  - FACT-BE-JAVA-0003: hs-kaz-bss-service/hs-kaz-bss-server/src/main/java/com/huasheng/bss/admin/server/gsc/dc/facade/CustomerHistoryPenaltyQueryFacade.java:24 (sha256:f76d53d23446399cfd441b4e34fb78054db3b62c1f998cb0191a98a286a31bf8)
  - FACT-BE-JAVA-0004: hs-kaz-bss-service/hs-kaz-bss-server/src/main/java/com/huasheng/bss/admin/server/gsc/service/impl/adviser/GscAdviserClientServiceImpl.java:34 (sha256:bd2d1559e1c59ce7ba3f488737211134095837bbf45da0d63a18b2f10d13cf18)

### backend-java-api-002. Spring API 必须通过明确映射注解暴露

- Status: pending-confirmation
- Level: P1
- Risk: high
- Rule: 新增 Java Spring HTTP API 时，Controller 必须使用明确的 Spring MVC 映射注解描述入口。
- Must: Controller endpoints must use Spring MVC mapping annotations.
- Must Not: Do not expose HTTP behavior without a controller mapping annotation.
- Evidence:
  - FACT-BE-JAVA-0074: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/base/LoginLogoutController.java:25 (sha256:600ca48a2415986c24ea57aa3a597ae947ed4b0ce4078fc4531d1c93964501f9)
  - FACT-BE-JAVA-0075: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/base/LoginLogoutController.java:53 (sha256:d6b6acedd496bd51022557852cdf96a4e9e5bff8a8ef96b9a4b162e911fc9668)
  - FACT-BE-JAVA-0076: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/base/LoginLogoutController.java:75 (sha256:483055918c801924508d0028b2ac28e13ae4d2d5685669e2977bab9c769dc1b1)
  - FACT-BE-JAVA-0077: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/ChannelCommissionController.java:30 (sha256:600ca48a2415986c24ea57aa3a597ae947ed4b0ce4078fc4531d1c93964501f9)
  - FACT-BE-JAVA-0078: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/ChannelCommissionController.java:31 (sha256:dc04287ebb9519ca075aaac6fe2572e7c98040e03a9203282343593c2a43f92a)
  - FACT-BE-JAVA-0079: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/ChannelCommissionController.java:40 (sha256:1729b576f2f61e7e041f9ca935d571b825e350ab2e0f79e9e2eaf1bfe9d78a9f)
  - FACT-BE-JAVA-0080: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/ChannelCommissionController.java:49 (sha256:ce2ad6546ca1a828790aae4f77f0a3b0f45a8beecc8ec2c4552117ab4614c8e1)
  - FACT-BE-JAVA-0081: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/ChannelCommissionController.java:60 (sha256:d9475a90a678b7018d6d97a2c81ca369764a84a8bf31b4ffa5430d8579990abb)
  - FACT-BE-JAVA-0082: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/ChannelCommissionController.java:74 (sha256:fa3421f68d55947831dfaa208d2c8c0ce6f411d9277073409089530043e7da40)
  - FACT-BE-JAVA-0083: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/ChannelCommissionController.java:85 (sha256:d4fe9612d284fda8906e79be92d18a372491aa87e23027aecf37399f3150f7f5)
  - FACT-BE-JAVA-0084: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/CommissionFeeCodeController.java:62 (sha256:600ca48a2415986c24ea57aa3a597ae947ed4b0ce4078fc4531d1c93964501f9)
  - FACT-BE-JAVA-0085: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/controller/commission/CommissionFeeCodeController.java:63 (sha256:10800119e81fdc8fec184cdbd9439e1eb7cdad5d52d0d14716e0440329dbcb90)

### backend-java-exception-003. 异常处理应进入统一处理组件

- Status: auto-active
- Level: P1
- Risk: medium
- Rule: Java Spring 服务应通过 ControllerAdvice 或 ExceptionHandler 集中处理接口异常。
- Must: API exceptions should be handled by centralized Spring exception handling components.
- Must Not: Do not scatter unrelated generic exception handling across controllers.
- Evidence:
  - FACT-BE-JAVA-0073: hs-kaz-crm-admin/src/main/java/com/huasheng/crm/proccess/admin/config/common/AdminResultReqIdAdvice.java:33 (sha256:667a15215db98a556e8c432cda20867fffb784d649318a59dbb9bfed997d7586)
  - FACT-BE-JAVA-1170: hs-kaz-crm-web/src/main/java/com/huasheng/crm/web/config/acvice/OpeningValidationAdvice.java:30 (sha256:a8df28df7a40e8a67d3562930b633cdd0675b0837d0869356f00fde9ab81d736)
  - FACT-BE-JAVA-1171: hs-kaz-crm-web/src/main/java/com/huasheng/crm/web/config/acvice/OpeningValidationAdvice.java:33 (sha256:1aad3b983c66caa24e7233493715d8a26c1ed8bb57746ce31cc2bbf87843409c)
  - FACT-BE-JAVA-1172: hs-kaz-crm-web/src/main/java/com/huasheng/crm/web/config/acvice/OpeningValidationAdvice.java:48 (sha256:75042e4cb2e11a5118996ebaa2f6e3d452f6566de1ebe78160343bbd5af8d16c)
