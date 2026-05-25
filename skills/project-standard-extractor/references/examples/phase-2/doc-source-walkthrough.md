---
name: doc-source-walkthrough
description: EA-Doc 维度组端到端 walkthrough：含 CONTRIBUTING.md + ADR + OpenAPI + Wiki 离线注入的证券后端项目，演示文档源萃取闭环
type: example
phase: phase-2
domain: 04-backend
---

# Doc-Source Walkthrough — EA-Doc 维度组

> **场景**：证券后端项目 `broker-backend`，代码维度已完成萃取（EA-Backend-01~10 全 activated）。
> 团队 Wiki 有术语表和 Bounded Context 文档，项目内有 OpenAPI + ADR + CONTRIBUTING。
> 本次追加 EA-Doc 维度组萃取，不重跑代码维度。

---

## 一、输入参数

```yaml
project_paths:
  - /local/broker-backend
doc_paths:
  - /local/broker-backend/.local-docs/wiki-export-20260525    # Wiki 离线注入
extraction_mode: diff      # 代码维度不重跑，只跑 doc 维度（diff scope 自动推断为全 EA-Doc-* 5 维首次运行）
domain: 04-backend
run_mode: interactive
```

---

## 二、Phase 1: Intake & Scope

**doc_paths 检测**：

```
检测到 doc_paths[] 输入:
  /local/broker-backend/.local-docs/wiki-export-20260525
  → 识别为 Wiki 离线导出（frontmatter source=wiki-export）
  → 目录大小: 2.4MB, 23 个 markdown 文件

代码维度（已有 activation-report.json）: 跳过重评（extraction_mode=diff, EA-Doc-* 为新增维度）
EA-Doc 维度: 全部首次运行，视为全量扫描
```

---

## 三、Phase 2: Doc-Source-Scanner

**扫描日志**：

```
扫描路径:
  /local/broker-backend/docs/         → 12 个文件
  /local/broker-backend/openapi/      → 1 个文件 (openapi.yaml)
  /local/broker-backend/CONTRIBUTING.md
  /local/broker-backend/.local-docs/wiki-export-20260525/  → 23 个文件

分类结果:
  glossary:     2 个（docs/glossary.md + wiki-export/glossary.md）
  api:          1 个（openapi/openapi.yaml）
  standard:     1 个（CONTRIBUTING.md）
  decision:     5 个（docs/adr/0001~0005.md）
  domain-model: 1 个（wiki-export/bounded-context.md）
  unknown:      26 个（README、设计文档等，不触发信号）

敏感文件排除: docs/internal/api-keys-deprecated.md → read_blocked=true
```

**产出**：

```json
// evidence/knowledge/doc-inventory.json（节选）
{
  "schema": "doc-inventory.v1",
  "total_docs": 36,
  "docs": [
    { "file_path": "docs/glossary.md", "doc_type": "glossary", "source": "in-repo", "heading_signature": ["# 证券业务术语表"] },
    { "file_path": ".local-docs/wiki-export-20260525/glossary.md", "doc_type": "glossary", "source": "wiki-export", "heading_signature": ["# 核心业务术语"] },
    { "file_path": "openapi/openapi.yaml", "doc_type": "api", "source": "in-repo" },
    { "file_path": "CONTRIBUTING.md", "doc_type": "standard", "source": "in-repo" },
    { "file_path": "docs/adr/0001-use-spring-boot.md", "doc_type": "decision", "source": "in-repo" }
  ]
}
```

---

## 四、Phase 2: Dimension Activator（EA-Doc 5 维）

| 维度 | 命中信号 | weight 合计 / threshold | state |
| --- | --- | --- | --- |
| EA-Doc-Glossary | SIG-DOC-GLOSSARY-001(w=2) + SIG-DOC-GLOSSARY-003(w=2, wiki) | 4 / threshold=2 | **activated** |
| EA-Doc-DomainModel | SIG-DOC-DOMAIN-001(w=2, wiki bounded-context.md) | 2 / threshold=2 | **activated** |
| EA-Doc-Standard | SIG-DOC-STD-001(w=2, CONTRIBUTING.md) | 2 / threshold=2 | **activated** |
| EA-Doc-API | SIG-DOC-API-001(w=2, openapi.yaml) | 2 / threshold=2 | **activated** |
| EA-Doc-Decision | SIG-DOC-ADR-001(w=2, 5 个 ADR) | 10 / threshold=2 | **activated** |

**三态分布**：5/5 activated（无 candidate / baseline）

---

## 五、Phase 3: Generation（EA-Doc 章节 + 副产物）

### §EA-Doc-Glossary（生成正文节选）

```markdown
## §EA-Doc-Glossary 业务术语表 [activated]

### 核心术语（来源: docs/glossary.md + wiki-export/glossary.md）

| 术语 | 定义 | 来源 |
| --- | --- | --- |
| 委托 (Order) | 买方或卖方向经纪商提交的买卖请求，含价格/数量/方向 | docs/glossary.md:12 |
| 成交 (Trade) | 委托被市场撮合成功后产生的交易记录 | wiki-export/glossary.md:8 |
| 持仓 (Position) | 当前持有某证券的数量及成本均价 | docs/glossary.md:28 |
| 保证金 (Margin) | 用于支持杠杆仓位的质押资产 | wiki-export/glossary.md:35 |
| ...（详见 evidence/knowledge/glossary.md）
```

### 副产物产出

| 文件 | 内容摘要 |
| --- | --- |
| `evidence/knowledge/glossary.md` | 20 条术语（docs + wiki 合并，含来源标注） |
| `evidence/knowledge/domain-model.md` | 5 个核心实体（Order/Account/Portfolio/Position/Risk） + BC 边界 |
| `evidence/knowledge/decisions-summary.md` | 5 条 ADR 摘要（编号+标题+状态，不重写原文） |
| `evidence/knowledge/api-contract.md` | 28 个端点（GET/POST/PUT/DELETE）+ 请求/响应摘要 |
| `evidence/knowledge/wiki-snapshot-20260525.md` | Wiki 注入留痕（23 个文件，导出时间，source 字段） |

---

## 六、与代码维度的协同

**EA-Doc-API（activated）与 EA-Backend-02（activated）共存**：

```
merge-coordinator 决策:
  EA-Doc-API §: 记录 openapi.yaml 中 28 个已文档化端点清单
  EA-Backend-02 §: 约束代码层 API 设计规范（命名/版本/幂等性等）
  
  merge-suggestions.md 新增:
  "EA-Doc-API 与 EA-Backend-02 关联：openapi.yaml 覆盖率应 ≥ 所有
   Controller @GetMapping/@PostMapping 端点，建议 owner 验证一致性"
  
  conflicts.md: 无冲突（两者作用层不同）
```

---

## 七、Quality Gate & Merge

```
门禁 A（最低发布）:
  ✅ A1 EA-Doc 5 维章节均存在
  ✅ A2 三态一致（5/5 activated）
  ✅ A3 evidence_tier 标注正确
  ✅ A4 敏感文件排除记录在 doc-inventory.json
  ✅ A5 副产物齐全（5 个 evidence/knowledge/*.md）

门禁 B（深度）:
  avg depth_score = 0.76 ✅（含 wiki 加成）
  
结论: PASS → 进 merge
```

---

## 八、产物总结

```
新增/更新:
  engineering-standards/04-backend/standard.md
    （追加 §EA-Doc-Glossary / §EA-Doc-DomainModel / §EA-Doc-Standard
             §EA-Doc-API / §EA-Doc-Decision 五节）
  engineering-standards/04-backend/evidence/knowledge/
    ├── doc-inventory.json        （doc-inventory.v1）
    ├── glossary.md               （20 条术语）
    ├── domain-model.md           （5 实体 + BC）
    ├── decisions-summary.md      （5 条 ADR 摘要）
    ├── api-contract.md           （28 个端点）
    └── wiki-snapshot-20260525.md （Wiki 注入留痕）
  engineering-standards/04-backend/merge-suggestions.md
    （EA-Doc-API ↔ EA-Backend-02 关联建议）
```

---

## 九、关键学习点

1. **doc_paths[] = 扩大 evidence 范围**：Wiki/Confluence 导出与代码库文档合并扫描，不需要修改代码
2. **副产物 ≠ 规范规则**：`evidence/knowledge/glossary.md` 是事实记录，规范规则在 `standard.md §EA-Doc-Glossary` 中
3. **与代码维度并行，不替代**：EA-Doc-API 不替代 EA-Backend-02，二者互补
4. **敏感文件排除透明**：`doc-inventory.json` 中 `read_blocked=true` 记录排除事实，不隐藏
5. **Wiki 注入留痕**：`wiki-snapshot-20260525.md` 确保历史导出可追溯，下次重跑时不会遗漏
