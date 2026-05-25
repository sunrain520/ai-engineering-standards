---
doc_id: backend-java-spring-standard
title: Java Spring 后端开发规范
domain: backend
sub_domain: java-spring
doc_type: standard
version: v0.1.0
status: draft
owner: TBD
source_batch: backend-java-spring-stock-deposit
evidence_tier: single-project
last_reviewed: 2026-05-23
tags:
  - backend
  - java-spring
  - dubbo
  - mybatis-plus
---

# Java Spring 后端开发规范

本文件从 hs-kaz-crm-service 的 stock/deposit 模块萃取，当前为单项目 evidence-backed draft。跨项目推广或升级为 active 前，需要后端负责人确认。

## 1. 技术栈与工程约束

- Spring Boot：服务启动与自动配置基础
- Apache Dubbo 3.x：服务间 RPC 通信（@DubboService / @DubboReference）
- MyBatis-Plus：ORM，BaseMapper<DO> 提供基础 CRUD
- aicai-appmodel：统一结果类型（BaseResult / ModelResult<T> / PageResult<T>）
- hs-lagom-framework：华盛内部基础框架，封装 MQ、Result 等
- Maven 多模块：*-common（接口契约）+ *-server（实现）双模块结构
- Lombok @Slf4j：日志
- Apache Commons：CollectionUtils / StringUtils 等工具

## 2. 分层职责



| 层级 | 核心职责 | 禁止事项 |
| --- | --- | --- |
| Facade（common 接口 + server 实现） | 业务编排：参数校验 → 查前置数据 → 调 Service → 调外部 Dubbo → 发 MQ | 不直接操作 Mapper；不写 SQL |
| ReadService | 只读查询，返回 ModelResult/PageResult | 不做写操作；不加 @Transactional |
| WriteService | 单一聚合根写操作 | 不调用其他服务 Facade；不跨模块调 Mapper |
| Mapper | DB 访问，继承 BaseMapper<DO> | 不接受 Domain/DTO 入参；不写业务逻辑 |
| DO | 数据库映射 | 不出 server 模块边界 |
| Domain | 跨服务传输 | 不含 @TableName/@TableField 等 DB 注解 |
| Converter | DO ↔ Domain/DTO 转换 | 不注入 Spring Bean；不含业务规则 |

## 3. Facade 层规范

### P1 Facade 方法首行必须记录关键入参日志

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-23 · recommended_action: keep-draft

**适用范围**

- 所有 @DubboService FacadeImpl 的公开方法。

**强制规则**

1. 方法首行调用 `log.info("方法名, 关键参数:{}", value)`，记录能定位问题的最小参数集（memberId、业务 ID、操作人等）。
2. 枚举类型参数用 `.getDescription()` 或 `.name()` 转字符串，不直接打印枚举对象。

**正例**

```java
@Override
@Transactional(rollbackFor = Exception.class)
public ModelResult<Long> apply(StockDepositApplyDto applyDto, List<StockDepositItemApplyDto> itemListDto, String applyBy) {
    log.info("后台发起转入股票申请，memberId:{}, market:{}, assetAccountId:{}, applyBy:{}",
            applyDto == null ? null : applyDto.getMemberId(),
            applyDto == null || applyDto.getMarket() == null ? null : applyDto.getMarket().getDescription(),
            applyDto == null ? null : applyDto.getAssetAccountId(), applyBy);
    // ...
}
```

**反例**

```java
// 禁止：无入参日志，出问题无法定位
public ModelResult<Long> apply(StockDepositApplyDto applyDto, ...) {
    ModelResult<Long> result = new ModelResult<>();
    if (applyDto == null) { ... }
    // ...
}
```

**AI 生成代码要求**

1. AI 新增 Facade 方法时，必须在方法首行加 log.info，记录 memberId 和业务关键参数。
2. AI 不得省略日志行，即使方法逻辑简单。

**Code Review 检查项**

- [ ] Facade 公开方法首行有 log.info，包含 memberId 或业务 ID。
- [ ] 枚举参数用 getDescription()/name() 转字符串后打印。

**Evidence**

- `evidence/code-facts.md「EV-BE-1」`

---

### P1 写操作 Facade 必须加 @Transactional 并在外部调用失败时显式回滚

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: high · owner: TBD · last_reviewed: 2026-05-23 · recommended_action: keep-draft

**适用范围**

- 所有包含 DB 写操作的 Facade 方法。

**强制规则**

1. 写操作 Facade 方法加 `@Transactional(rollbackFor = Exception.class)`。
2. 事务内调用外部 Dubbo 服务失败时，必须调用 `markRollbackOnly()` 或 `status.setRollbackOnly()` 显式回滚本地事务，不能只 return error。
3. 需要在事务外调用外部服务时（如 `complete()` 先调外部再写 DB），用 `TransactionTemplate` 手动控制事务边界。

**正例**

```java
@Override
@Transactional(rollbackFor = Exception.class)
public ModelResult<Long> apply(StockDepositApplyDto applyDto, ...) {
    // 写 DB
    memberStockDepositMapper.insert(depositDO);
    // 调外部 Dubbo，失败必须回滚
    Result<ProcessInfo> processResult = crmTaskWriteService.createProcessV2(...);
    if (processResult == null || !processResult.isSuccess()) {
        markRollbackOnly();  // 显式回滚
        return result.withError(...);
    }
    return result.withModel(depositDO.getId());
}
```

**反例**

```java
// 禁止：外部调用失败只 return error，没有回滚本地事务
@Transactional(rollbackFor = Exception.class)
public ModelResult<Long> apply(...) {
    memberStockDepositMapper.insert(depositDO);
    Result<ProcessInfo> processResult = crmTaskWriteService.createProcessV2(...);
    if (!processResult.isSuccess()) {
        return result.withError(...);  // 本地事务未回滚，数据不一致
    }
    return result.withModel(depositDO.getId());
}
```

**AI 生成代码要求**

1. AI 新增写操作 Facade 方法时，必须加 @Transactional(rollbackFor = Exception.class)。
2. AI 在事务内调用外部 Dubbo 失败时，必须在 return error 前调用 markRollbackOnly()。
3. AI 不得在事务内同步发 MQ（见 P1 MQ 规范）。

**Code Review 检查项**

- [ ] 写操作 Facade 方法有 @Transactional(rollbackFor = Exception.class)。
- [ ] 事务内外部 Dubbo 调用失败有 markRollbackOnly() 或 status.setRollbackOnly()。
- [ ] 没有在事务内同步发 MQ。

**Evidence**

- `evidence/code-facts.md「EV-BE-2」`
- `evidence/positive-examples.md「POS-BE-1」`
- `evidence/forbidden-examples.md「NEG-BE-1」`

---

### P1 MQ 发送必须注册 afterCommit 回调，不得在事务内同步发送

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: high · owner: TBD · last_reviewed: 2026-05-23 · recommended_action: keep-draft

**适用范围**

- 所有在事务方法内发送 MQ 消息的场景。

**强制规则**

1. 事务内 MQ 发送必须通过 `TransactionSynchronizationManager.registerSynchronization` 注册 `afterCommit` 回调，或使用封装好的 `publishAfterCommit()` 工具方法。
2. MQ Producer 封装为独立 `*MqProducer` 类，不在 Facade 内直接调 MQ SDK。

**正例**

```java
// 事务提交后发 MQ
publishAfterCommit(() -> stockTransferMqProducer.publishDepositApplied(depositDO.getId(), depositDO.getMemberId(), firstTransfer));

// publishAfterCommit 实现
private void publishAfterCommit(Runnable action) {
    TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
        @Override
        public void afterCommit() {
            action.run();
        }
    });
}
```

**反例**

```java
// 禁止：事务内同步发 MQ，消息可能先于数据库提交到达消费者
@Transactional(rollbackFor = Exception.class)
public ModelResult<Long> apply(...) {
    memberStockDepositMapper.insert(depositDO);
    stockTransferMqProducer.publishDepositApplied(depositDO.getId(), ...);  // 禁止
    return result.withModel(depositDO.getId());
}
```

**AI 生成代码要求**

1. AI 在事务方法内新增 MQ 发送时，必须使用 publishAfterCommit() 或等价的 afterCommit 回调。
2. AI 不得在 @Transactional 方法内直接调用 MqProducer 方法。

**Code Review 检查项**

- [ ] 事务方法内 MQ 发送通过 afterCommit 回调执行。
- [ ] MQ 发送封装在独立 *MqProducer 类，不直接调 SDK。

**Evidence**

- `evidence/code-facts.md「EV-BE-3」`
- `evidence/positive-examples.md「POS-BE-2」`

## 4. Service 层规范

### P1 Service 接口按读写分离命名，WriteService 方法加 @Transactional

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-23 · recommended_action: keep-draft

**适用范围**

- 所有 *-common 模块的 Service 接口定义。

**强制规则**

1. 读服务接口命名为 `{业务}ReadService`，写服务接口命名为 `{业务}WriteService`。
2. WriteService 实现类的写方法加 `@Transactional(rollbackFor = Exception.class)`。
3. ReadService 实现类不加 `@Transactional`，不做写操作。
4. Service 接口方法参数加 `@NotNull`/`@Valid` 约束，不在实现类内手写 null 判断。

**正例**

```java
// common 层接口
public interface MemberStockDepositReadService {
    ModelResult<MemberStockDeposit> queryById(@NotNull Long id);
    ModelResult<List<MemberStockDeposit>> queryTodayCompleteByDate(
        @NotNull Long memberId, @NotNull StockMarketType market,
        @NotNull LocalDateTime beginDate, @NotNull LocalDateTime endDate);
}

// server 层实现
@Service
public class MemberStockDepositReadServiceImpl implements MemberStockDepositReadService {
    @Resource
    private MemberStockDepositMapper memberStockDepositMapper;

    @Override
    public ModelResult<MemberStockDeposit> queryById(Long id) {
        ModelResult<MemberStockDeposit> result = new ModelResult<>();
        MemberStockDepositDO depositDO = memberStockDepositMapper.selectById(id);
        if (depositDO == null) {
            return result.withModel(null);
        }
        return result.withModel(StockDepositConverter.toDomain(depositDO));
    }
}
```

**反例**

```java
// 禁止：读写混在一个 Service 接口
public interface MemberStockDepositService {
    MemberStockDeposit queryById(Long id);
    void save(MemberStockDeposit deposit);  // 读写混合
}
```

**AI 生成代码要求**

1. AI 新增 Service 接口时，必须按读写分离命名为 ReadService/WriteService。
2. AI 新增 WriteService 实现方法时，必须加 @Transactional(rollbackFor = Exception.class)。
3. AI 不得在 ReadService 实现内写 DB。

**Code Review 检查项**

- [ ] Service 接口按 ReadService/WriteService 分离命名。
- [ ] WriteService 实现的写方法有 @Transactional(rollbackFor = Exception.class)。
- [ ] ReadService 实现无写操作，无 @Transactional。

**Evidence**

- `evidence/code-facts.md「EV-BE-4」`

## 5. 数据对象分层规范

### P1 DO 不出 server 模块边界，Domain 不含 DB 注解

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-23 · recommended_action: keep-draft

**适用范围**

- 所有 *-server 模块的 DO 类和 *-common 模块的 Domain 类。

**强制规则**

1. DO（数据库映射对象）只在 server 模块内部流转，不作为 Facade 接口参数或返回值。
2. Domain（领域对象）在 common 模块定义，用于跨服务传输，不含 `@TableName`/`@TableField` 等 MyBatis-Plus 注解。
3. DO → Domain 的转换由 `*Converter` 静态工具类完成，不在 Service/Facade 内散落转换逻辑。
4. Converter 类使用静态方法，不注入 Spring Bean，不含业务规则。

**正例**

```java
// DO：只在 server 内部
@Data
@TableName("member_stock_deposit")
public class MemberStockDepositDO {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long memberId;
    // ...
}

// Domain：common 层，无 DB 注解
@Data
public class MemberStockDeposit implements Serializable {
    private Long id;
    private Long memberId;
    // ...
}

// Converter：静态工具类
public class StockDepositConverter {
    public static MemberStockDeposit toDomain(MemberStockDepositDO depositDO) { ... }
    public static MemberStockDepositDO toDepositDO(StockDepositApplyDto dto, String applyBy) { ... }
}
```

**反例**

```java
// 禁止：DO 作为 Facade 接口返回值
public interface MemberStockDepositFacade {
    ModelResult<MemberStockDepositDO> queryById(Long id);  // 禁止，DO 不出 server
}

// 禁止：Domain 含 DB 注解
@Data
@TableName("member_stock_deposit")  // 禁止
public class MemberStockDeposit {
    @TableId  // 禁止
    private Long id;
}
```

**AI 生成代码要求**

1. AI 新增 Facade 接口方法时，返回值必须用 Domain 或 DTO，不得用 DO。
2. AI 新增 Domain 类时，不得加 @TableName/@TableField/@TableId 等 MyBatis-Plus 注解。
3. AI 新增 DO → Domain 转换时，必须放在 *Converter 静态方法内。

**Code Review 检查项**

- [ ] Facade 接口参数和返回值无 DO 类型。
- [ ] Domain 类无 @TableName/@TableField/@TableId 注解。
- [ ] DO ↔ Domain 转换集中在 *Converter 静态方法，不散落在 Service/Facade 内。

**Evidence**

- `evidence/code-facts.md「EV-BE-5」`
- `evidence/positive-examples.md「POS-BE-3」`
- `evidence/forbidden-examples.md「NEG-BE-2」`

## 6. 外部 Dubbo 调用规范

### P1 @DubboReference 必须加 check=false，调用结果必须判空

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: high · owner: TBD · last_reviewed: 2026-05-23 · recommended_action: keep-draft

**适用范围**

- 所有 @DubboReference 注入的外部服务调用。

**强制规则**

1. `@DubboReference` 必须加 `check = false`，避免启动时因依赖服务未就绪失败。
2. 跨服务调用指定 `group` 时必须与服务端 `@DubboService(group=...)` 一致。
3. 外部 Dubbo 调用结果必须判空再取数据：`if (result == null || !result.isSuccess())`。
4. 不得直接 `.getData()` / `.getModel()` 而不先判空。

**正例**

```java
@DubboReference(check = false)
private CrmTaskWriteService crmTaskWriteService;

@DubboReference(group = "hs-kaz-core-server", check = false)
private MemberExtReadService memberExtReadService;

// 调用时判空
Result<TaskTransferInfo> taskResult = crmTaskReadService.queryTask(taskId);
if (taskResult == null || !taskResult.isSuccess() || taskResult.getData() == null) {
    return failResult(result, taskResult, "task.query.fail", "查询任务失败");
}
TaskTransferInfo task = taskResult.getData();
```

**反例**

```java
// 禁止：不加 check=false
@DubboReference
private CrmTaskWriteService crmTaskWriteService;

// 禁止：不判空直接取数据
Result<TaskTransferInfo> taskResult = crmTaskReadService.queryTask(taskId);
TaskTransferInfo task = taskResult.getData();  // NPE 风险
```

**AI 生成代码要求**

1. AI 新增 @DubboReference 时，必须加 check = false。
2. AI 调用外部 Dubbo 服务后，必须先判 result == null || !result.isSuccess() 再取数据。

**Code Review 检查项**

- [ ] 所有 @DubboReference 有 check = false。
- [ ] 外部 Dubbo 调用结果判空后再取 getData()/getModel()。

**Evidence**

- `evidence/code-facts.md「EV-BE-6」`

## 7. 错误处理规范

### P1 统一用 result.withError(code, msg) 返回错误，不抛受检异常

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-23 · recommended_action: keep-draft

**适用范围**

- 所有 Facade 和 Service 方法的错误返回。

**强制规则**

1. 所有方法返回 `BaseResult` / `ModelResult<T>` / `PageResult<T>`，不抛受检异常。
2. 错误码格式：`{业务域}.{操作}.{原因}`，例如 `stock.deposit.apply.param.empty`。
3. 外部 Dubbo 调用失败时，透传对方的 errorCode 和 errorMsg，不自造新错误码。
4. 不得用 `try-catch` 吞掉异常后返回成功。

**正例**

```java
// 参数校验
if (applyDto == null) {
    return result.withError("stock.deposit.apply.param.empty", "转入股票申请参数不能为空");
}
// 透传外部错误
ModelResult<BrokerInfo> brokerResult = brokerInfoReadService.queryById(applyDto.getBrokerId());
if (!brokerResult.isSuccess()) {
    return result.withError(brokerResult.getErrorCode(), brokerResult.getErrorMsg());
}
```

**反例**

```java
// 禁止：抛 RuntimeException
if (applyDto == null) {
    throw new RuntimeException("参数不能为空");
}
// 禁止：吞异常返回成功
try {
    memberStockDepositMapper.insert(depositDO);
} catch (Exception e) {
    log.error("insert error", e);
    return result;  // 吞掉异常，返回成功
}
```

**AI 生成代码要求**

1. AI 新增错误返回时，必须用 result.withError(code, msg)，不得 throw RuntimeException。
2. AI 错误码必须遵循 {业务域}.{操作}.{原因} 格式。
3. AI 不得用 try-catch 吞掉异常后返回成功。

**Code Review 检查项**

- [ ] 方法错误返回用 result.withError()，无 throw RuntimeException。
- [ ] 错误码格式符合 {业务域}.{操作}.{原因}。
- [ ] 无 try-catch 吞异常后返回成功的写法。

**Evidence**

- `evidence/code-facts.md「EV-BE-7」`

## 8. 目录与命名规范

```text
*-common/src/main/java/com/huasheng/{domain}/common/{业务模块}/
├── facade/
│   └── {业务}Facade.java          — Dubbo 服务接口
├── service/
│   ├── {业务}ReadService.java     — 读服务接口
│   └── {业务}WriteService.java    — 写服务接口
├── domain/
│   └── {业务}.java                — 领域对象（无 DB 注解）
├── dto/
│   ├── {业务}{动作}Dto.java       — 入参 DTO
│   └── {业务}QueryDto.java        — 查询 DTO
└── type/
    └── {业务}Status.java          — 业务枚举

*-server/src/main/java/com/huasheng/{domain}/server/{业务模块}/
├── facade/impl/
│   └── {业务}FacadeImpl.java      — @DubboService 实现
├── service/impl/
│   ├── {业务}ReadServiceImpl.java
│   └── {业务}WriteServiceImpl.java
├── mapper/
│   └── {业务}Mapper.java          — MyBatis-Plus Mapper
├── domain/
│   └── {业务}DO.java              — DB 映射对象
└── support/
    ├── {业务}Converter.java       — 静态转换工具
    └── {业务}*Tool.java           — 业务工具类
```

命名规则：

- 读服务接口：`{业务}ReadService`，例如：`MemberStockDepositReadService`
- 写服务接口：`{业务}WriteService`，例如：`MemberStockDepositItemWriteService`
- Facade 接口：`{业务}Facade`，例如：`MemberStockDepositFacade`
- Facade 实现：`{业务}FacadeImpl`，例如：`MemberStockDepositFacadeImpl`
- DB 对象：`{业务}DO`，例如：`MemberStockDepositDO`
- 领域对象：`{业务}`（无后缀），例如：`MemberStockDeposit`
- 入参 DTO：`{业务}{动作}Dto`，例如：`StockDepositApplyDto`
- MQ Producer：`{业务}MqProducer`，例如：`StockTransferMqProducer`
- 转换工具：`{业务}Converter`，例如：`StockDepositConverter`

## 9. AI 生成规则

> 本节是各规则节 `AI 生成代码要求` 的汇总视图，不新创内容。

AI 生成 Java Spring 后端代码时必须遵守：

1. 新增 Facade 方法首行加 log.info，记录 memberId 和业务关键参数。
2. 写操作 Facade 方法加 @Transactional(rollbackFor = Exception.class)。
3. 事务内外部 Dubbo 调用失败必须 markRollbackOnly()，不能只 return error。
4. 事务内 MQ 发送必须用 publishAfterCommit() 或 afterCommit 回调，不得同步发送。
5. Service 接口按 ReadService/WriteService 分离命名，WriteService 方法加 @Transactional。
6. DO 不出 server 模块，Facade 接口参数和返回值用 Domain 或 DTO。
7. Domain 类不含 @TableName/@TableField/@TableId 注解。
8. DO ↔ Domain 转换集中在 *Converter 静态方法。
9. @DubboReference 必须加 check = false。
10. 外部 Dubbo 调用结果判空后再取 getData()/getModel()。
11. 错误返回用 result.withError(code, msg)，错误码格式 {业务域}.{操作}.{原因}。

禁止 AI 生成：

- Facade 方法无入参日志
- 写操作 Facade 无 @Transactional
- 事务内外部调用失败无 markRollbackOnly()
- 事务内同步发 MQ
- DO 作为 Facade 接口参数或返回值
- Domain 含 DB 注解
- @DubboReference 无 check = false
- 外部 Dubbo 调用不判空直接取数据
- throw RuntimeException 代替 result.withError()

## 10. Code Review 检查项

> 本节是各规则节 `Code Review 检查项` 的汇总视图，不新创内容。

- [ ] Facade 公开方法首行有 log.info，包含 memberId 或业务 ID
- [ ] 写操作 Facade 方法有 @Transactional(rollbackFor = Exception.class)
- [ ] 事务内外部 Dubbo 调用失败有 markRollbackOnly() 或 status.setRollbackOnly()
- [ ] 事务内 MQ 发送通过 afterCommit 回调执行
- [ ] Service 接口按 ReadService/WriteService 分离命名
- [ ] WriteService 实现的写方法有 @Transactional(rollbackFor = Exception.class)
- [ ] Facade 接口参数和返回值无 DO 类型
- [ ] Domain 类无 @TableName/@TableField/@TableId 注解
- [ ] DO ↔ Domain 转换集中在 *Converter 静态方法
- [ ] 所有 @DubboReference 有 check = false
- [ ] 外部 Dubbo 调用结果判空后再取 getData()/getModel()
- [ ] 错误返回用 result.withError()，无 throw RuntimeException
- [ ] 错误码格式符合 {业务域}.{操作}.{原因}


## 11. Controller 层规范（hs-kaz-crm-admin）

### P1 Controller 只做参数绑定和 Facade 调用，不写业务逻辑

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-23 · recommended_action: keep-draft

**适用范围**

- hs-kaz-crm-admin 所有 Controller 类。

**强制规则**

1. Controller 只做：HTTP 参数绑定、`@Valid` 校验、调用 Facade/Service、封装响应返回。
2. 写操作方法加 `@UserActionLog("操作描述")` 记录操作日志。
3. 写操作方法加 `@RequiresPermissions("CRM:TASK:XXX")` 做权限校验。
4. 参数校验失败（`BindingResult.hasErrors()`）直接返回错误，不进入业务逻辑。
5. Controller 内可用 try-catch 捕获 `IllegalArgumentException` 和 `Exception` 做防御性处理，但不写业务规则。

**推荐规则**

1. 新增 Controller 优先用 `@RestController` + 返回 `Result<T>`（新风格），而非 `@Controller` + `Map<String, Object>`（旧风格）。
2. Request → DTO 转换用 `BeanUtils.copyProperties(request, dto)` 或手动赋值，不在 Controller 内写转换逻辑。

**禁止事项**

- 禁止在 Controller 内写 `if/else` 业务判断
- 禁止在 Controller 内直接注入 Mapper 或 Repository
- 禁止在 Controller 内写 `@Transactional`
- 禁止在 Controller 内直接注入 `@DubboReference` 跨服务调用（应通过 admin Facade 层）

**正例**

```java
/**
 * 货币兑换控制器（薄层）。
 * 仅负责 HTTP 参数绑定与响应封装，业务逻辑收敛在 ExchangeFundsFacade。
 */
@Slf4j
@Controller
@RequestMapping(value = "/exchange-v3")
public class ExchangeFundsV3Controller {

    @Autowired
    private ExchangeFundsFacade exchangeFundsFacade;

    @UserActionLog("客户主页-服务记录-发起换汇")
    @RequestMapping(value = "/{memberId}/create")
    @ResponseBody
    @RequiresPermissions("CRM:TASK:EXCHANGE:FUNDS")
    public Map<String, Object> createProccessForExchange(@ModelAttribute ExchangeApplyDto applyDto, ...) {
        BaseResult rs = exchangeFundsFacade.createExchange(applyDto, ...);
        if (!rs.isSuccess()) return simpleError(rs.getErrorMsg());
        return simpleSuccess();
    }
}
```

**反例**

```java
// 禁止：Controller 直接注入 @DubboReference，跳过 admin Facade 层
@RestController
@RequestMapping("/money/deposit")
public class DepositTaskController {

    @DubboReference(check = false)
    private DepositTaskService depositTaskService;  // 历史写法，新代码禁止

    @PostMapping("/create")
    public Result<Long> create(@RequestBody @Valid DepositTaskCreateRequest request) {
        // 直接调 Dubbo Service，绕过 admin Facade 层
        return depositTaskService.create(command);
    }
}
```

**AI 生成代码要求**

1. AI 新增 Controller 方法时，写操作必须加 `@UserActionLog` 和 `@RequiresPermissions`。
2. AI 不得在 Controller 内注入 `@DubboReference`，必须通过 admin Facade 层。
3. AI 不得在 Controller 内写业务判断逻辑。

**Code Review 检查项**

- [ ] Controller 方法只调 Facade，无业务逻辑，无直接 Mapper/DubboReference 注入。
- [ ] 写操作方法有 `@UserActionLog` 和 `@RequiresPermissions`。
- [ ] 参数校验用 `@Valid` + `BindingResult`，校验失败直接返回错误。

**Evidence**

- `evidence/code-facts.md「EV-BE-8」`
- `evidence/positive-examples.md「POS-BE-4」`
- `evidence/forbidden-examples.md「NEG-BE-3」`


### P2 Mapper 复杂查询用 @Select 注解或 XML，不在 Service 内拼 SQL

> level: P2 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: low · owner: TBD · last_reviewed: 2026-05-23 · recommended_action: keep-draft

**适用范围**

- 所有 *-server 模块的 Mapper 接口，超出 MyBatis-Plus BaseMapper 基础 CRUD 的查询。

**强制规则**

1. 简单单表查询（无 JOIN、无 resultMap）用 `@Select` 注解，支持 Java 15+ text block 多行写法。
2. 复杂查询（多表 JOIN、自定义 resultMap、动态 SQL）写 XML Mapper，放在 `src/main/resources/mapper/{模块}/` 目录。
3. Mapper 方法参数超过 1 个时用 `@Param` 注解命名，不依赖参数顺序。
4. 分页查询方法接受 `DataPage<T>` 参数，不在 Mapper 内计算 offset。

**禁止事项**

- 禁止在 Service/Facade 内拼接 SQL 字符串
- 禁止在 Mapper 方法内写业务逻辑
- 禁止 Mapper 方法返回 Domain 对象（应返回 DO，由 Converter 转换）

**正例**

```java
// 简单查询用 @Select text block
@Select("""
        select count(distinct stock_code, data_type)
        from member_optional_stock
        """)
long countDistinctStocks();

// 多参数用 @Param
List<MemberStockDepositDO> selectByCondition(
    @Param("memberId") Long memberId,
    @Param("status") Integer status,
    @Param("market") Integer market,
    @Param("beginDate") LocalDateTime beginDate,
    @Param("endDate") LocalDateTime endDate);

// 复杂 resultMap 用 XML
// MemberCommissionInfoMapper.xml
<select id="getFeeCodeAndCommissionInfoByMemberId" resultMap="FeeCodeAndCommissionInfoVoMap">
    select fee_code, expired_date
    from member_commission_info
    where member_id = #{memberId} and deleted = 0
    limit 1
</select>
```

**AI 生成代码要求**

1. AI 新增简单单表查询时，用 @Select text block，不写 XML。
2. AI 新增多表 JOIN 或 resultMap 查询时，写 XML Mapper。
3. AI 不得在 Service 内拼 SQL 字符串。
4. AI 多参数 Mapper 方法必须加 @Param 注解。

**Code Review 检查项**

- [ ] 简单查询用 @Select，复杂查询用 XML，无在 Service 内拼 SQL。
- [ ] 多参数 Mapper 方法有 @Param 注解。
- [ ] Mapper 方法返回 DO，不返回 Domain。

**Evidence**

- `evidence/code-facts.md「EV-BE-9」`


### P1 @DubboReference 指定 group 时必须与服务端 @DubboService(group=...) 一致

> level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: high · owner: TBD · last_reviewed: 2026-05-23 · recommended_action: keep-draft

**适用范围**

- 所有跨服务 @DubboReference 调用，特别是调用非 CRM 内部服务时。

**强制规则**

1. 调用外部服务时，`@DubboReference` 的 `group` 值必须与目标服务的 `@DubboService(group=...)` 完全一致。
2. 常见 group 值（来自代码 evidence）：
   - `hs-kaz-core-server`：KAZ 核心服务（Member、MemberExt 等）
   - `hs-appconfig-server`：应用配置服务（AppConfig、营业日等）
   - `hs-kaz-userinfo-server`：用户信息服务
   - `hs-marketing-channel-server-ksa`：营销渠道服务（KSA 展业地）
3. group 值不确定时，查目标服务的 `@DubboService` 注解，不猜测。

**禁止事项**

- 禁止 group 值拼写错误或与服务端不一致（会导致服务发现失败，启动时因 check=false 不报错，运行时才失败）

**正例**

```java
// 调用 KAZ 核心服务
@DubboReference(group = "hs-kaz-core-server", check = false)
private MemberExtReadService memberExtReadService;

// 调用应用配置服务
@DubboReference(group = "hs-appconfig-server", check = false)
private AppConfigReadService appConfigReadService;
```

**AI 生成代码要求**

1. AI 新增 @DubboReference 调用外部服务时，必须确认 group 值与目标服务 @DubboService 一致。
2. AI 不得猜测 group 值，应查目标服务代码确认。

**Code Review 检查项**

- [ ] @DubboReference 的 group 值与目标服务 @DubboService(group=...) 一致。
- [ ] 新增外部服务调用有确认 group 值的说明或注释。

**Evidence**

- `evidence/code-facts.md「EV-BE-10」`

## Evidence 参考

| evidence_id | 来源文件（路径模式） | 核心观察 | 置信度 |
| --- | --- | --- | --- |
| `EV-BE-1` | `*/stock/deposit/facade/impl/MemberStockDepositFacadeImpl.java` | 所有 Facade 方法首行有 log.info 记录关键入参 | high |
| `EV-BE-2` | `*/stock/deposit/facade/impl/MemberStockDepositFacadeImpl.java` | 写操作加 @Transactional，外部 Dubbo 失败调 markRollbackOnly() | high |
| `EV-BE-3` | `*/stock/deposit/facade/impl/MemberStockDepositFacadeImpl.java` | MQ 发送通过 publishAfterCommit() 注册 afterCommit 回调 | high |
| `EV-BE-4` | `*/stock/deposit/service/` | Service 接口按 ReadService/WriteService 分离，WriteService 加 @Transactional | high |
| `EV-BE-5` | `*/stock/deposit/domain/` + `*/stock/deposit/support/StockDepositConverter.java` | DO 只在 server 内，Domain 无 DB 注解，转换集中在 Converter | high |
| `EV-BE-6` | `*/stock/deposit/facade/impl/MemberStockDepositFacadeImpl.java` | @DubboReference 全部加 check=false，调用结果判空后取数据 | high |
| `EV-BE-7` | `*/stock/deposit/facade/impl/MemberStockDepositFacadeImpl.java` | 错误返回统一用 result.withError(code, msg)，错误码格式 {域}.{操作}.{原因} | high |
| `EV-BE-8` | `*/controller/exchange/ExchangeFundsV3Controller.java` + `*/controller/member/StockDepositV2Controller.java` + `*/controller/money/DepositTaskController.java` | Controller 薄层：只调 Facade，写操作加 @UserActionLog + @RequiresPermissions；DepositTaskController 直接注入 @DubboReference 是历史反例 | high |
| `EV-BE-9` | `*/optional/mapper/MemberOptionalStockMapper.java` + `*/stock/deposit/mapper/MemberStockDepositMapper.java` + `*/resources/mapper/commission/MemberCommissionInfoMapper.xml` | 简单查询用 @Select text block，复杂 resultMap 用 XML，多参数加 @Param | high |
| `EV-BE-10` | 多个 FacadeImpl 和 ServiceImpl 文件 | @DubboReference group 值规律：hs-kaz-core-server / hs-appconfig-server / hs-kaz-userinfo-server / hs-marketing-channel-server-ksa | high |
