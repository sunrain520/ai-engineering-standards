---
name: doc-source-scanner
description: 文档源扫描 agent——递归扫描 project_paths 内文档文件，识别 doc_type，输出 evidence/knowledge/doc-inventory.json，供 dimension-activator 消费 EA-Doc-* 维度信号
role: source-scanner
phase: phase-2
input_from: intake-and-scope
output_to: facts-and-classification
---

# Doc-Source-Scanner Agent

## 角色定义

负责在 facts-and-classification 阶段之前，针对 EA-Doc 维度组扫描项目文档文件，产出 `evidence/knowledge/doc-inventory.json`（schema: doc-inventory.v1），供 dimension-activator 消费 `type: doc-content` 信号。

与代码信号扫描**并行**，不替代。

## 输入契约

```yaml
inputs:
  scope_summary:
    project_paths: [string]         # 来自 intake-and-scope
    doc_paths: [string]             # 可选，用户通过 SKILL.md 调用协议传入（Wiki/Confluence 离线导出）
  sensitive_file_policy:            # 继承 intake-and-scope Step 5 规则
    exclude_patterns:
      - "**/secrets/**"
      - "**/credentials/**"
      - "**/.env*"
      - "**/node_modules/**"
      - "**/dist/**"
      - "**/build/**"
      - "**/target/**"
      - "**/.git/**"
```

## 扫描范围

```
target_extensions:
  - "*.md" / "*.mdx" / "*.rst"                       # 文档 markdown
  - "openapi*.{yaml,json}" / "swagger*.{yaml,json}"   # API 契约
  - "*.graphql" / "schema.graphql"                    # GraphQL schema
  - "CONTRIBUTING.md" / "STYLE.md"                    # 规范文件

root_directories:
  - <project_path>/docs/
  - <project_path>/doc/
  - <project_path>/openapi/
  - <project_path>/api/
  - <doc_path>/  （用户离线注入目录，如存在）
  - 项目根级别已知文件（CONTRIBUTING.md / README.md / STYLE.md）
```

## 扫描步骤

1. **初始化**：读取 scope_summary.project_paths + scope_summary.doc_paths（可选）
2. **文件枚举**：递归 find，排除 sensitive_file_policy 中的 exclude_patterns
3. **文件分类**（按优先级）：
   - `decision`：路径含 `/adr/` / `/decisions/` / `/rfc/`，或 H1 heading 含 `ADR-` / `RFC-` 前缀
   - `api`：文件名含 `openapi` / `swagger`，或 yaml 顶级含 `openapi:` / `paths:`，或 `.graphql` 后缀
   - `glossary`：文件名含 `glossary` / `terms` / `ubiquitous-language`，或 H1 含"术语表"/"glossary"
   - `domain-model`：文件名含 `domain-model` / `ddd` / `bounded-context`，或 H1 含"领域模型"
   - `standard`：文件名为 `CONTRIBUTING.md` / `STYLE.md` / `docs/conventions*` / `docs/guidelines*`
   - `unknown`：其余文档文件（记录存在事实但不激活任何 EA-Doc 维度）
4. **heading_signature 提取**：读取文档前 20 行，提取 `#` 开头的标题（最多 5 条，不读全文）
5. **敏感内容保护**：仅记录文件元数据（path / doc_type / size / heading_signature），**不读取** heading 以外的内容；heading 内出现疑似密钥段时（长度 > 20 字符 + 含大写字母 + 数字混合）跳过该 heading

## 输出：evidence/knowledge/doc-inventory.json

```json
{
  "schema": "doc-inventory.v1",
  "scanned_at": "{{iso_timestamp}}",
  "run_id": "{{run_id}}",
  "total_docs": 0,
  "doc_paths_injected": [],
  "docs": [
    {
      "file_path": "docs/glossary.md",
      "doc_type": "glossary",
      "size_bytes": 4200,
      "heading_signature": ["# 业务术语表", "## 交易术语", "## 账户术语"],
      "last_modified": "2026-05-25T08:00:00Z",
      "source": "in-repo"
    },
    {
      "file_path": "docs/adr/0001-use-kmp.md",
      "doc_type": "decision",
      "size_bytes": 2100,
      "heading_signature": ["# ADR-0001 采用 KMP 共享层", "## 状态", "## 背景"],
      "last_modified": "2026-04-10T10:00:00Z",
      "source": "in-repo"
    }
  ]
}
```

`source` 枚举：`in-repo`（项目内） / `wiki-export`（用户注入 Wiki 导出） / `confluence-export`（Confluence 导出）

## 与 facts-and-classification 的接口

doc-source-scanner 完成后将 doc-inventory.json 路径写入 session context，由 facts-and-classification 读取并追加 `doc_facts[]` 字段到 batch_facts 输出。

```yaml
# facts-and-classification 输出扩展
batch_facts:
  code_facts: [...]         # 既有字段
  doc_facts:                # 新增字段（doc-source-scanner 产出）
    - dimension: EA-Doc-Glossary
      doc_type: glossary
      file_path: docs/glossary.md
      heading_count: 3
      signal_ids: [SIG-DOC-GLOSSARY-001]
      depth_contribution: 0.5
```

## 异常处理

| 情况 | 处理 |
| --- | --- |
| project_paths 无任何文档文件 | `total_docs: 0`；EA-Doc-* 5 维全 candidate；在 open_questions 中提示 |
| doc_paths 不存在或权限不足 | 跳过该路径；写 `warnings: [{"type": "doc_paths_inaccessible", ...}]` |
| 单文件读取失败 | 记录 `read_error: true`，不中止整体扫描 |
| heading 内发现疑似密钥 | 跳过该 heading；写 `{redacted: true, reason: "possible-secret"}` |

## 与 force-rebuild 协同

`evidence/knowledge/` 子目录纳入 `tools/maintainer/project-standard-extractor/backup.sh` 的备份范围（已在 exclude_patterns 中只排除 `evidence/raw-*`，knowledge/ 子目录被包含在 cp -a 范围内）。
