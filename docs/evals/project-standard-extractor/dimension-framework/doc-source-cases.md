---
name: doc-source-cases
description: EA-Doc 维度组评估场景（8 场景 A~H）：全 doc 项目/无 doc 项目/Wiki 注入/敏感排除/副产物质量/与代码维度协同/force-rebuild 协同/跨项目合并
type: evals
phase: phase-2
ae: [EA-Doc]
---

# Doc-Source Cases

## DSC-A — 场景 A: 全 doc 项目（4 维 activated + 1 维 candidate）

**Given**

```yaml
project_path: /mock/full-doc-project
doc_structure:
  - docs/glossary.md              # SIG-DOC-GLOSSARY-001 weight=2
  - docs/adr/0001-use-kmp.md      # SIG-DOC-ADR-001 weight=2
  - openapi.yaml                   # SIG-DOC-API-001 weight=2
  - CONTRIBUTING.md                # SIG-DOC-STD-001 weight=2
  # 无 docs/domain-model.md
```

**When**

doc-source-scanner 扫描项目，dimension-activator 判定 EA-Doc-* 5 维。

**Then**

| 维度 | 预期 state | 依据 |
| --- | --- | --- |
| EA-Doc-Glossary | activated | glossary.md weight=2 ≥ threshold |
| EA-Doc-DomainModel | candidate | 无 domain-model 文件 |
| EA-Doc-Standard | activated | CONTRIBUTING.md weight=2 ≥ threshold |
| EA-Doc-API | activated | openapi.yaml weight=2 ≥ threshold |
| EA-Doc-Decision | activated | ADR 文件 weight=2 ≥ threshold |

- `evidence/knowledge/doc-inventory.json` 存在，`total_docs ≥ 4`
- 未激活维度地图含 EA-Doc-DomainModel，升级条件：提供 `docs/domain-model.md`

**回归断言**

```bash
jq '[.dimensions[] | select(.dimension_id | startswith("EA-Doc"))] | length' report.json | grep -q "^5$"
jq '.dimensions[] | select(.dimension_id=="EA-Doc-DomainModel") | .state' report.json | grep -q "candidate"
jq '.dimensions[] | select(.dimension_id=="EA-Doc-API") | .state' report.json | grep -q "activated"
```

---

## DSC-B — 场景 B: 无 doc 项目（5 维全 candidate，EA-Doc-Decision 为 baseline 兜底）

**Given**

```yaml
project_path: /mock/no-doc-project
doc_structure: []     # 只有源码，无任何 markdown
```

**When**

doc-source-scanner 扫描，无信号命中。

**Then**

- EA-Doc-Glossary / EA-Doc-DomainModel / EA-Doc-Standard / EA-Doc-API → `candidate`
- EA-Doc-Decision → `baseline`（high_risk_fallback 触发）
- `total_docs = 0`
- 未激活维度地图列出 5 项（4 candidate + 1 baseline）
- 开放问题中提示："未发现任何文档文件，建议在 docs/ 目录或通过 doc_paths[] 注入 Wiki 导出"

**回归断言**

```bash
jq '.dimensions[] | select(.dimension_id=="EA-Doc-Decision") | .state' report.json | grep -q "baseline"
jq '[.dimensions[] | select(.dimension_id | startswith("EA-Doc")) | select(.state=="candidate")] | length' report.json | grep -q "^4$"
[ $(jq '.total_docs' evidence/knowledge/doc-inventory.json) -eq 0 ]
```

---

## DSC-C — 场景 C: Wiki/Confluence 离线注入

**Given**

```yaml
project_path: /mock/project-c
doc_paths: ["/mock/project-c/.local-docs/wiki-export-20260525"]
wiki_export_structure:
  - .local-docs/wiki-export-20260525/glossary.md     # frontmatter: source=wiki-export
  - .local-docs/wiki-export-20260525/domain-model.md # frontmatter: source=wiki-export
```

**When**

doc-source-scanner 扫描 project_paths + doc_paths 并集，识别 `source: wiki-export` frontmatter。

**Then**

- EA-Doc-Glossary → `activated`（wiki-export 触发 SIG-DOC-GLOSSARY-003 weight=2）
- EA-Doc-DomainModel → `activated`（wiki-export 触发 SIG-DOC-DOMAIN-001 weight=2）
- `doc-inventory.json` 中相关条目 `source = "wiki-export"`
- 产出 `evidence/knowledge/wiki-snapshot-20260525.md`（留痕）

**回归断言**

```bash
jq '.docs[] | select(.source=="wiki-export") | .doc_type' evidence/knowledge/doc-inventory.json | grep -q "glossary"
[ -f evidence/knowledge/wiki-snapshot-20260525.md ]
jq '.dimensions[] | select(.dimension_id=="EA-Doc-DomainModel") | .state' report.json | grep -q "activated"
```

---

## DSC-D — 场景 D: 敏感文档排除

**Given**

```yaml
project_path: /mock/project-d
doc_structure:
  - docs/secrets/api-keys.md        # 敏感路径
  - docs/glossary.md                # 正常文档
```

**When**

doc-source-scanner 扫描，`docs/secrets/api-keys.md` 命中 sensitive_file_policy。

**Then**

- `docs/secrets/api-keys.md` 不读取内容，只记录 `{file_path: "...", read_blocked: true, reason: "sensitive-path-pattern"}`
- `docs/glossary.md` 正常处理，EA-Doc-Glossary 信号命中
- 不中止整体扫描

**回归断言**

```bash
jq '.docs[] | select(.file_path | contains("api-keys")) | .read_blocked' doc-inventory.json | grep -q "true"
jq '.dimensions[] | select(.dimension_id=="EA-Doc-Glossary") | .state' report.json | grep -q "activated"
```

---

## DSC-E — 场景 E: 副产物质量验证

**Given**

```yaml
project_path: /mock/project-e
doc_structure:
  - docs/glossary.md   # 含 10 条术语，每条有定义
  - docs/adr/0001-chose-kmp.md
  - openapi.yaml       # 含 5 个端点
```

**When**

generation agent 产出 `evidence/knowledge/` 副产物。

**Then**

- `evidence/knowledge/glossary.md`：含 ≥ 5 条术语条目，每条含 `term` + `definition` + `source: file_path:line`
- `evidence/knowledge/decisions-summary.md`：含 1 条决策摘要，含编号 + 标题 + 状态（不重写原文）
- `evidence/knowledge/api-contract.md`：含 ≥ 3 条端点，每条含 Method + 路径 + 简述

**回归断言**

```bash
grep -c "^| " evidence/knowledge/glossary.md | awk '$1>=5{print "OK"}'
grep -c "| ADR\|0001" evidence/knowledge/decisions-summary.md | awk '$1>=1{print "OK"}'
grep -c "GET\|POST\|PUT\|DELETE" evidence/knowledge/api-contract.md | awk '$1>=3{print "OK"}'
```

---

## DSC-F — 场景 F: 与代码维度协同（EA-Doc-API + EA-Backend-02）

**Given**

```yaml
project_path: /mock/project-f
activated_code_dimensions:
  EA-Backend-02: activated    # 代码维度 API 契约
activated_doc_dimensions:
  EA-Doc-API: activated       # 文档维度 OpenAPI
```

**When**

merge-coordinator 执行 EA-Doc-API 与 EA-Backend-02 协同检查。

**Then**

- 两个维度规则**不重叠覆盖**（不产生相同内容的两条规则）
- `merge-suggestions.md` 中写入：`"EA-Doc-API 与 EA-Backend-02 有逻辑关联：建议 owner 确认 OpenAPI 文档端点覆盖率与代码 Controller 一致"`
- `conflicts.md` 无冲突条目
- 两章节各自独立：EA-Doc-API §记录 OpenAPI 文档端点清单；EA-Backend-02 §约束代码层 API 设计规范

**回归断言**

```bash
grep -q "EA-Doc-API\|EA-Backend-02" merge-suggestions.md
wc -l < conflicts.md | awk '{if($1<=5)print "OK"}'
```

---

## DSC-G — 场景 G: force-rebuild + EA-Doc 协同

**Given**

```yaml
output_action: force-rebuild
domain: 01-app-client
extraction_mode: full
doc_structure:
  - docs/glossary.md
  - docs/adr/0001-use-kmp.md
```

**When**

force-rebuild 执行：备份 → 重生 → 校验 + 4 项确定性 check。

**Then**

- `evidence/knowledge/` 目录纳入备份范围（`backup.sh --domain=01-app-client` 的 cp -a 包含 knowledge/）
- `scripts/backup.sh --dry-run --domain=01-app-client` 输出的 `file_count` 包含 knowledge/*.md
- 重生后 `evidence/knowledge/glossary.md` 存在（重跑 doc-source-scanner 重新产出）
- sha256 fingerprint 一致（重生产物字节级与备份相同 schema）

**回归断言**

```bash
scripts/backup.sh --dry-run --domain=01-app-client | jq '.file_count' | awk '$1>=1{print "OK"}'
[ -f .local-backups/01-app-client/*/knowledge/glossary.md ] || echo "WARN: knowledge not in backup"
```

---

## DSC-H — 场景 H: 跨项目对比 + EA-Doc-Glossary 术语合并

**Given**

```yaml
project_paths:
  - /mock/project-a    # glossary.md 含术语 "委托" = "买卖请求"
  - /mock/project-b    # glossary.md 含术语 "委托" = "Order"（中英文名不同）
  - /mock/project-c    # 无 glossary
```

**When**

cross-project-aggregator 合并 EA-Doc-Glossary 的 evidence/knowledge/glossary.md。

**Then**

- project-a / project-b 均 activated → unified EA-Doc-Glossary = activated（只升不降）
- `evidence/knowledge/glossary-unified.md` 中"委托"条目含**差异标注**：
  ```
  | 委托 | project-a: 买卖请求 | project-b: Order | 需要 owner 统一命名 |
  ```
- project-c 无贡献，不影响 unified 状态
- 差异条目写入 `merge-suggestions.md`

**回归断言**

```bash
grep -q "委托" evidence/knowledge/glossary-unified.md
grep -q "差异\|mismatch\|project-a\|project-b" evidence/knowledge/glossary-unified.md
grep -q "EA-Doc-Glossary" merge-suggestions.md
```
