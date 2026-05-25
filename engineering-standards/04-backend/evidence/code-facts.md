---
doc_id: backend-evidence-code-facts
title: Backend Code Facts
domain: backend
sub_domains:
  - java-spring
doc_type: evidence-code-facts
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
---

# Backend Code Facts

## EV-BE-1: Facade 方法首行记录关键入参日志

- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- path: `hs-kaz-crm-service/hs-kaz-crm-server/.../stock/deposit/facade/impl/MemberStockDepositFacadeImpl.java`
- observed_pattern: apply()、verifyPass()、reject()、complete()、updateApplyBrokerInfo() 等所有公开方法首行均调用 log.info，记录 memberId、market、assetAccountId、applyBy 等关键参数；枚举类型用 .getDescription() 转字符串。
- file_role: facade-impl
- evidence_tier: single-project
- 置信度: high
- 敏感信息处理: 不涉及
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
- 关联规则: `standard-java-spring.md「P1 Facade 方法首行必须记录关键入参日志」`

## EV-BE-2: 写操作 Facade 加 @Transactional，外部 Dubbo 失败调 markRollbackOnly()

- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- path: `hs-kaz-crm-service/hs-kaz-crm-server/.../stock/deposit/facade/impl/MemberStockDepositFacadeImpl.java`
- observed_pattern: apply()/@Transactional；crmTaskWriteService.createProcessV2() 失败后调 markRollbackOnly() 再 return error；verifyPass() 中 crmTaskWriteService.handle() 失败后同样调 markRollbackOnly()；reject() 中 crmTaskWriteService.reject() 失败后调 markRollbackOnly()。complete() 使用 TransactionTemplate 手动控制事务边界。
- file_role: facade-impl
- evidence_tier: single-project
- 置信度: high
- 敏感信息处理: 不涉及
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
- 关联规则: `standard-java-spring.md「P1 写操作 Facade 必须加 @Transactional 并在外部调用失败时显式回滚」`

## EV-BE-3: MQ 发送通过 publishAfterCommit() 注册 afterCommit 回调

- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- path: `hs-kaz-crm-service/hs-kaz-crm-server/.../stock/deposit/facade/impl/MemberStockDepositFacadeImpl.java`
- observed_pattern: apply() 末尾调用 publishAfterCommit(() -> stockTransferMqProducer.publishDepositApplied(...))；complete() 末尾同样调用 publishAfterCommit(() -> stockTransferMqProducer.publishDepositSucceeded(...))。publishAfterCommit() 内部通过 TransactionSynchronizationManager.registerSynchronization 注册 afterCommit 回调。MQ Producer 封装为独立 StockTransferMqProducer 类。
- file_role: facade-impl
- evidence_tier: single-project
- 置信度: high
- 敏感信息处理: 不涉及
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
- 关联规则: `standard-java-spring.md「P1 MQ 发送必须注册 afterCommit 回调，不得在事务内同步发送」`

## EV-BE-4: Service 接口按 ReadService/WriteService 分离，WriteService 加 @Transactional

- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- path: `hs-kaz-crm-service/hs-kaz-crm-common/.../stock/deposit/service/`
- observed_pattern: MemberStockDepositReadService（只读查询）、MemberStockDepositItemReadService、BrokerInfoReadService；MemberStockDepositItemWriteService（写操作）、BrokerInfoWriteService。ReadService 实现类无 @Transactional；WriteService 实现类写方法加 @Transactional(rollbackFor = Exception.class)。接口方法参数加 @NotNull/@Valid 约束。
- file_role: service-interface + service-impl
- evidence_tier: single-project
- 置信度: high
- 敏感信息处理: 不涉及
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
- 关联规则: `standard-java-spring.md「P1 Service 接口按读写分离命名，WriteService 方法加 @Transactional」`

## EV-BE-5: DO 只在 server 内，Domain 无 DB 注解，转换集中在 Converter

- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- path: `hs-kaz-crm-service/hs-kaz-crm-server/.../stock/deposit/domain/MemberStockDepositDO.java` + `hs-kaz-crm-common/.../stock/deposit/domain/MemberStockDeposit.java` + `hs-kaz-crm-server/.../stock/deposit/support/StockDepositConverter.java`
- observed_pattern: MemberStockDepositDO 含 @TableName/@TableId/@TableField，只在 server 模块内使用；MemberStockDeposit（Domain）无任何 DB 注解，在 common 模块定义用于跨服务传输；StockDepositConverter 是静态工具类，提供 toDepositDO()/toDomain()/toItemDO() 等静态方法，不注入 Spring。
- file_role: domain-object + converter
- evidence_tier: single-project
- 置信度: high
- 敏感信息处理: 不涉及
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
- 关联规则: `standard-java-spring.md「P1 DO 不出 server 模块边界，Domain 不含 DB 注解」`

## EV-BE-6: @DubboReference 全部加 check=false，调用结果判空后取数据

- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- path: `hs-kaz-crm-service/hs-kaz-crm-server/.../stock/deposit/facade/impl/MemberStockDepositFacadeImpl.java`
- observed_pattern: @DubboReference(check = false) 注入 CrmTaskReadService、CrmTaskWriteService、MemberAssetStreamReadService；@DubboReference(group = "hs-kaz-core-server", check = false) 注入 MemberExtReadService。所有外部调用结果均先判 null || !isSuccess() 再取数据。
- file_role: facade-impl
- evidence_tier: single-project
- 置信度: high
- 敏感信息处理: 不涉及
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
- 关联规则: `standard-java-spring.md「P1 @DubboReference 必须加 check=false，调用结果必须判空」`

## EV-BE-7: 错误返回统一用 result.withError(code, msg)，错误码格式 {域}.{操作}.{原因}

- batch_id: `backend-java-spring-stock-deposit`
- sub_domain: `java-spring`
- path: `hs-kaz-crm-service/hs-kaz-crm-server/.../stock/deposit/facade/impl/MemberStockDepositFacadeImpl.java`
- observed_pattern: 所有错误返回均用 result.withError(errorCode, errorMsg)；错误码如 stock.deposit.apply.param.empty、stock.deposit.market.not.support；外部调用失败时透传对方 errorCode/errorMsg；无 throw RuntimeException 写法。
- file_role: facade-impl
- evidence_tier: single-project
- 置信度: high
- 敏感信息处理: 不涉及
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
- 关联规则: `standard-java-spring.md「P1 统一用 result.withError(code, msg) 返回错误，不抛受检异常」`

## EV-BE-8: Controller 薄层模式，写操作加 @UserActionLog + @RequiresPermissions

- batch_id: `backend-java-spring-controller`
- sub_domain: `java-spring`
- path: `hs-kaz-crm-admin/src/main/java/.../controller/exchange/ExchangeFundsV3Controller.java` + `.../controller/member/StockDepositV2Controller.java` + `.../controller/money/DepositTaskController.java`
- observed_pattern: ExchangeFundsV3Controller 注释明确"薄层，仅负责 HTTP 参数绑定与响应封装，业务逻辑收敛在 Facade"；写操作方法加 @UserActionLog("描述") + @RequiresPermissions("CRM:TASK:XXX")；参数校验用 @Valid + BindingResult；StockDepositV2Controller.createProccess() 用 try-catch 捕获 IllegalArgumentException 和 Exception 做防御性处理。反例：DepositTaskController 直接注入 @DubboReference DepositTaskService，跳过 admin Facade 层（历史写法）。
- file_role: controller
- evidence_tier: single-project
- 置信度: high
- 敏感信息处理: 不涉及
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
- 关联规则: `standard-java-spring.md「P1 Controller 只做参数绑定和 Facade 调用，不写业务逻辑」`

## EV-BE-9: Mapper 复杂查询用 @Select 注解或 XML，多参数加 @Param

- batch_id: `backend-java-spring-mapper`
- sub_domain: `java-spring`
- path: `hs-kaz-crm-service/hs-kaz-crm-server/.../optional/mapper/MemberOptionalStockMapper.java` + `.../stock/deposit/mapper/MemberStockDepositMapper.java` + `.../resources/mapper/commission/MemberCommissionInfoMapper.xml`
- observed_pattern: MemberOptionalStockMapper 用 @Select text block 写简单单表查询（countDistinctStocks、queryDistinctStocksPage 等）；MemberStockDepositMapper 复杂查询（selectByCondition、pageReport 等）只声明接口方法，实现在 XML；多参数方法全部加 @Param 注解；XML Mapper 用 resultMap 处理字段映射（MemberCommissionInfoMapper.xml）。
- file_role: mapper
- evidence_tier: single-project
- 置信度: high
- 敏感信息处理: 不涉及
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
- 关联规则: `standard-java-spring.md「P2 Mapper 复杂查询用 @Select 注解或 XML，不在 Service 内拼 SQL」`

## EV-BE-10: @DubboReference group 值规律

- batch_id: `backend-java-spring-dubbo-group`
- sub_domain: `java-spring`
- path: 多个 FacadeImpl 和 ServiceImpl 文件（MemberStockDepositFacadeImpl、MemberStockDepositReadServiceImpl、MemberCreditLineApplyV2ReadServiceImpl、ExchangeFundsFacade 等）
- observed_pattern: 跨服务调用时 @DubboReference 指定 group，常见值：hs-kaz-core-server（KAZ 核心服务）、hs-appconfig-server（应用配置服务）、hs-kaz-userinfo-server（用户信息服务）、hs-marketing-channel-server-ksa（营销渠道服务）。服务端对应 @DubboService(group = "hs-kaz-core-server") 等。
- file_role: facade-impl + service-impl
- evidence_tier: single-project
- 置信度: high
- 敏感信息处理: 不涉及
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
- 关联规则: `standard-java-spring.md「P1 @DubboReference 指定 group 时必须与服务端 @DubboService(group=...) 一致」`

## EV-BE-10: @DubboReference group 值规律

- batch_id: `backend-java-spring-dubbo-group`
- sub_domain: `java-spring`
- path: 多个 FacadeImpl 和 ServiceImpl 文件（MemberStockDepositFacadeImpl、MemberStockDepositReadServiceImpl、MemberCreditLineApplyV2ReadServiceImpl、ExchangeFundsFacade 等）
- observed_pattern: 跨服务调用时 @DubboReference 指定 group，常见值：hs-kaz-core-server（KAZ 核心服务）、hs-appconfig-server（应用配置服务）、hs-kaz-userinfo-server（用户信息服务）、hs-marketing-channel-server-ksa（营销渠道服务）。服务端对应 @DubboService(group = "hs-kaz-core-server") 等。
- file_role: facade-impl + service-impl
- evidence_tier: single-project
- 置信度: high
- 敏感信息处理: 不涉及
- run_id: 20260523-backend-java-spring
- first_seen: 2026-05-23
- last_seen: 2026-05-23
- 关联规则: `standard-java-spring.md「P1 @DubboReference 指定 group 时必须与服务端 @DubboService(group=...) 一致」`
