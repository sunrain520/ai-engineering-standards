---
name: industry-coexist-cases
description: 行业规范与端规范共存评估场景：AE21（行业规范不冲突覆盖端规范）
type: evals
phase: phase-2
ae: [AE21]
---

# Industry Coexist Cases

## ICC-001 — AE21: 行业规范与端规范共存，不冲突覆盖

**Given**

```yaml
project: /mock/kaz-mvp   # KMP+Clean APP + 证券后端
activated_end_standards:
  domain: 01-app-client
  rules:
    - id: EA-Client-01
      rule: "KMP shared 层禁止引入 Android/iOS 平台 SDK"
      status: owner-confirmed-active
    - id: EA-Client-05
      rule: "ViewModel 只能通过 UseCase 访问业务逻辑"
      status: draft
activated_industry_standards:
  domain: 09-industry
  rules:
    - id: SEC-01
      rule: "KYC/AML 校验必须在独立 account-service 模块中，禁止分散在 ViewModel"
      status: draft
    - id: SEC-05
      rule: "仓位风控引擎禁止被 UI 层直接调用"
      status: draft
```

**When**

merge-coordinator 执行跨域规范共存检查（01-app-client ↔ 09-industry）。

**Then**

行业规范与端规范**互相补充**，不重叠覆盖：

1. `SEC-01` 约束"KYC/AML 在 account-service"与 `EA-Client-01` 约束"KMP shared 禁止引入平台 SDK"
   - **无冲突**：两条规则作用于不同层（industry 规则约束模块职责，client 规则约束技术架构）
   - merge-coordinator 直接保留两条规则，写入各自 standard 文件，**不合并**

2. `SEC-05` 约束"风控引擎禁止被 UI 层直接调用"与 `EA-Client-05` 约束"ViewModel 只通过 UseCase"
   - **可能相关**但不冲突（EA-Client-05 的 UseCase 路径兼容 SEC-05 的风控隔离要求）
   - merge-coordinator 写入 `merge-suggestions.md`："SEC-05 与 EA-Client-05 有逻辑关联，建议 owner 评估是否可互相引用（not 合并）"
   - **不自动合并**，不改变任一规则的内容或状态

3. 没有任何行业规则被写入 `engineering-standards/01-app-client/` 目录（域边界不穿越）
4. 没有任何端规则被写入 `engineering-standards/09-industry/` 目录（反向同理）
5. `conflicts.md` 无条目（无真实冲突，只有关联建议）

**回归断言**

```bash
# SEC-01 在 09-industry，不在 01-app-client
[ -f engineering-standards/09-industry/01-securities-standard.md ]
grep -l "SEC-01" engineering-standards/01-app-client/ && echo "FAIL: cross-domain leak" || echo "OK"

# EA-Client-01 在 01-app-client，不在 09-industry
grep -l "EA-Client-01" engineering-standards/09-industry/ && echo "FAIL: cross-domain leak" || echo "OK"

# merge-suggestions 有关联提示但 conflicts 为空
grep -q "SEC-05\|EA-Client-05" merge-suggestions.md
wc -l < conflicts.md | awk '{if($1 <= 5) print "OK (minimal)"; else print "WARN: unexpected conflicts"}'
```
