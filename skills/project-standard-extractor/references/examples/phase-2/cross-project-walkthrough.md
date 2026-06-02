---
name: cross-project-walkthrough
description: 跨项目对比 walkthrough：3 个后端微服务项目合并统一规范，演示 unified-activation-map 只升不降 + 冲突归并决策
type: example
phase: phase-2
extraction_mode: full
domain: 04-backend
---

# Cross-Project Walkthrough

> **场景**：团队有 3 个后端微服务项目（order-service / account-service / risk-service），各自独立运作。
> 现在需要产出一份统一的后端规范基线，标注每条规则来自哪个项目，并解决潜在规则冲突。

---

## 一、输入参数

```yaml
project_paths:
  - /local/order-service           # Java Spring Boot 订单服务
  - /local/account-service         # Java Spring Boot 账户服务（含 KYC/AML）
  - /local/risk-service            # Java Spring Boot 风控引擎
extraction_mode: full
domain: 04-backend
sub_domain: java-spring
cross_project_mode: unified        # 启用跨项目合并
run_mode: interactive
```

---

## 二、Phase 1: Per-Project Profile

**project-a（order-service）**：
- 架构标签：[spring-boot, layered, jpa, kafka]
- 代码规模：~180 Java 文件

**project-b（account-service）**：
- 架构标签：[spring-boot, layered, kyc-aml, security]
- 代码规模：~140 Java 文件

**project-c（risk-service）**：
- 架构标签：[spring-boot, event-driven, risk-engine, position-limit]
- 代码规模：~95 Java 文件

---

## 三、Phase 2: Per-Project Dimension Activation

### project-a（order-service）激活结果

| 维度 | state | depth_score | 主要信号 |
| --- | --- | --- | --- |
| EA-Backend-01 分层架构 | activated | 0.82 | Controller / Service / Repository 三层分离 |
| EA-Backend-02 API 契约 | activated | 0.79 | OpenAPI 注解 + DTO 分离 |
| EA-Backend-03 异常处理 | baseline | 0.45 | GlobalExceptionHandler 存在但无链路 |
| EA-Backend-04 MQ 异步 | activated | 0.75 | KafkaProducer / KafkaConsumer 双信号 |
| EA-Backend-05 事务边界 | activated | 0.71 | @Transactional 注解密度高 |
| EA-Backend-06 鉴权 | candidate | — | 无 Spring Security 配置 |
| EA-Backend-07 日志规范 | baseline | 0.52 | SLF4J 存在但无 traceId |
| EA-Backend-08 数据访问 | activated | 0.78 | JPA + QueryDSL 双信号 |
| EA-Backend-09 限流 | candidate | — | 无限流模块 |
| EA-Backend-10 配置管理 | activated | 0.68 | Spring Config + 多环境 profiles |

### project-b（account-service）激活结果

| 维度 | state | depth_score | 主要信号 |
| --- | --- | --- | --- |
| EA-Backend-01 | activated | 0.85 | 同上 + Domain 层分离更清晰 |
| EA-Backend-02 | activated | 0.74 | — |
| EA-Backend-03 | **activated** | 0.73 | 含 ErrorCode 枚举 + 链路追踪 |
| EA-Backend-04 | baseline | 0.41 | 无 Kafka（account 服务纯 REST） |
| EA-Backend-05 | activated | 0.80 | — |
| EA-Backend-06 | **activated** | 0.83 | Spring Security + JWT + RBAC |
| EA-Backend-07 | **activated** | 0.76 | MDC traceId 注入 |
| EA-Backend-08 | activated | 0.70 | — |
| EA-Backend-09 | baseline | 0.48 | Bucket4j 限流但仅 1 处 |
| EA-Backend-10 | activated | 0.72 | — |

### project-c（risk-service）激活结果

| 维度 | state | depth_score | 主要信号 |
| --- | --- | --- | --- |
| EA-Backend-01 | activated | 0.78 | — |
| EA-Backend-02 | baseline | 0.50 | 无 OpenAPI，只有 Swagger 注解 |
| EA-Backend-03 | activated | 0.69 | — |
| EA-Backend-04 | activated | 0.80 | RocketMQ（与 a 不同的 MQ 技术栈） |
| EA-Backend-05 | activated | 0.75 | — |
| EA-Backend-06 | candidate | — | 内网服务，无鉴权 |
| EA-Backend-07 | activated | 0.74 | — |
| EA-Backend-08 | activated | 0.73 | — |
| EA-Backend-09 | **activated** | 0.82 | Sentinel 双信号（限流 + 熔断） |
| EA-Backend-10 | activated | 0.76 | — |

---

## 四、Phase 2: Cross-Project Aggregator — unified-activation-map 合并

**合并规则：同维度取最高状态；状态相同取最高 depth_score；有冲突写 `conflict_hint`**

| 维度 | a | b | c | unified | evidence_source | conflict |
| --- | --- | --- | --- | --- | --- | --- |
| EA-Backend-01 | activated | activated | activated | **activated** | [a,b,c] | — |
| EA-Backend-02 | activated | activated | baseline | **activated** | [a,b] | — |
| EA-Backend-03 | baseline | activated | activated | **activated** | [b,c] | — |
| EA-Backend-04 | activated | baseline | activated | **activated** | [a,c] | ⚠️ Kafka vs RocketMQ |
| EA-Backend-05 | activated | activated | activated | **activated** | [a,b,c] | — |
| EA-Backend-06 | candidate | activated | candidate | **activated** | [b] | ⚠️ 内网服务无鉴权 |
| EA-Backend-07 | baseline | activated | activated | **activated** | [b,c] | — |
| EA-Backend-08 | activated | activated | activated | **activated** | [a,b,c] | — |
| EA-Backend-09 | candidate | baseline | activated | **activated** | [c] | ⚠️ 3 项目技术栈不同 |
| EA-Backend-10 | activated | activated | activated | **activated** | [a,b,c] | — |

**unified 结果**：10 维全部 `activated`（跨项目合并后无 baseline/candidate）

---

## 五、冲突归并处理

### 冲突 C1：EA-Backend-04 MQ 技术栈（Kafka vs RocketMQ）

**conflict_hint**：
```
project-a 使用 Kafka，project-c 使用 RocketMQ。
unified 激活状态仍为 activated（两者均有充足 evidence），
但规则正文应写"MQ 技术栈选型由各服务自主决定，不强制统一；
跨服务通信接口必须遵循 topic/event 命名规范（见 EA-Backend-04 §2）"。
```

写入 `merge-suggestions.md`：
```
EA-Backend-04 MQ 规范建议：
  - 统一规则：message contract 格式（Avro/Protobuf）
  - 各服务可选：Kafka / RocketMQ / Pulsar
  - 禁止规则：MQ topic 命名含业务领域前缀（order.* / account.* / risk.*）
```

### 冲突 C2：EA-Backend-06 鉴权（内网服务 risk-service 无鉴权）

**conflict_hint**：
```
risk-service 为内网服务，未配置 Spring Security。
建议规则分层：
  1. 外网/半信任服务（order/account）：JWT + RBAC 强制
  2. 纯内网服务（risk）：服务网格 mTLS 替代，或网络隔离 + 访问白名单
  不应强制内网服务使用相同鉴权方案。
```

写入 `conflicts.md`：
```
EA-Backend-06 鉴权规则冲突：
  - b（account-service）: Spring Security + JWT （activated）
  - c（risk-service）: 无鉴权（candidate）
  - 建议 owner 确认内网服务鉴权策略后拆分为两条规则
```

---

## 六、Phase 3: Generation（跨项目合并版）

generation agent 产出：

| 文件 | 说明 |
| --- | --- |
| `04-backend/standard.md` | 10 维全 activated，含 `evidence_source` 标注（哪些维度来自哪个项目） |
| `04-backend/evidence/dimension-activation-report.json` | `cross_project.enabled=true / project_count=3 / unified_map` |
| `04-backend/merge-suggestions.md` | EA-Backend-04 / EA-Backend-06 分层建议 |
| `04-backend/conflicts.md` | EA-Backend-06 鉴权冲突待 owner 决策 |

---

## 七、Quality Gate & Merge

- 门禁 A：10 维章节全存在 ✅ / 状态一致 ✅ / evidence_tier 标注 ✅ → PASS
- 门禁 B：覆盖率 100% ✅ / avg depth_score 0.73 ✅ → PASS
- merge-coordinator：直接写入 `04-backend/`（无既有 owner-confirmed-active / legacy active 规则，无覆盖风险）

---

## 八、产物总结

```
created / updated:
  engineering-standards/04-backend/standard.md
    （10 维全 activated，含 evidence_source；EA-Backend-04 / EA-Backend-06 含 conflict_hint）
  engineering-standards/04-backend/evidence/dimension-activation-report.json
    （cross_project.enabled=true，3 project 合并）
  engineering-standards/04-backend/merge-suggestions.md
    （MQ 技术栈分层建议）
  engineering-standards/04-backend/conflicts.md
    （EA-Backend-06 鉴权冲突，待 owner 决策）
```

---

## 九、关键学习点

1. **unified-activation-map 只升不降**：risk-service 的 EA-Backend-06 candidate 不会把 account-service 的 activated 降级
2. **技术栈差异 ≠ 冲突**：Kafka vs RocketMQ 是选型差异，应写分层规则，不应强制统一
3. **内网服务鉴权是真实冲突**：不能用单一规则覆盖外网/内网，需要 owner 拆分规则
4. **evidence_source 追踪**：产物规范能溯源到具体项目，有利于后续维护
