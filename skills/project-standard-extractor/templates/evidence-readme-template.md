---
doc_id: "{domain}-evidence-readme"
title: "{Domain} Evidence 索引"
domain: "{domain}"
sub_domain: "common"
doc_type: "overview"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
tags:
  - "{domain}"
  - "common"
  - "evidence"
---

# {Domain} Evidence 索引

> 本目录承载 `project-standard-extractor` 萃取出的代码事实、正反例与历史兼容事实,是 `standard.md` 规则的**唯一**真实路径来源。规则正文不得复制本目录中的具体路径。

## 1. 文件清单

| 文件 | doc_type | 用途 |
| --- | --- | --- |
| `code-facts.md` | `evidence-code-facts` | 真实代码事实(`EV-{DOMAIN}-{NUMBER}`) |
| `positive-examples.md` | `evidence-positive` | 推荐写法事实(`POS-{DOMAIN}-{NUMBER}`) |
| `forbidden-examples.md` | `evidence-forbidden` | 反例事实(`NEG-{DOMAIN}-{NUMBER}`) |
| `legacy-compatible.md` | `evidence-legacy` | 历史兼容事实(`LEG-{DOMAIN}-{NUMBER}`) |

## 2. 颗粒度

- 默认按 `sub_domain` 拆分。每个 sub_domain 各有一组 4 文件,`doc_id` 形如 `{domain}-{sub_domain}-evidence-{kind}`。
- 一个 evidence 条目只属于一个 sub_domain;跨 sub_domain 共性事实写入 `sub_domain: "common"` 的 evidence 文件,需在 SKILL 维护方书面记录(参见 `SKILL.md §强制边界` 的 evidence 颗粒度条款)。

## 3. 引用规约

- 规则引用 evidence: `evidence/{kind}.md「{条目编号}」`
- evidence 引用规则: `{source_doc}「{section_title}」`(规则不使用 Rule ID)

## 4. 安全

- 不记录密钥、token、私钥、生产凭据原值;仅记录脱敏存在事实。
- 路径只允许出现在本目录文件中,`standard.md` / `ai-rules.md` / `review-checklist.md` 内不得出现。

## 5. Append-only

- 同一条目追加新观察(`last_seen` / 来源项目),不重写。
- 失效条目标 `deprecated: true` + 备注,不删除。
