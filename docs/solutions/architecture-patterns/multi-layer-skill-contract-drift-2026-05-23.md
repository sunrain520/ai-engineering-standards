---
title: AI Skill 多层契约文档需收敛到单一权威源
date: 2026-05-23
category: architecture-patterns
module: skills/project-standard-extractor
problem_type: architecture_pattern
component: tooling
severity: high
applies_when:
  - 设计或维护包含多层文档(入口 SKILL.md / 编排 workflow.md / 阶段 agents/ / 执行 prompts/ / 范例 templates/ + examples/)的 Skill source package
  - 重构 Skill 风格契约(如规则元数据格式、Front Matter schema、阶段产物)时只动一层而忘了其他层
  - 发现 Skill 实际产物与某一层契约不一致,但又能在另一层找到匹配的契约依据
  - 评估"prompts/templates/examples 是否可以与 agents/ 自由发散"
tags:
  - skill-design
  - contract-consistency
  - documentation-drift
  - llm-routing
  - spec-first
---

# AI Skill 多层契约文档需收敛到单一权威源

## Context

`project-standard-extractor` Skill 在演进过程中积累了 6 层文档:`SKILL.md`(对外入口) / `workflow.md`(总编排) / `agents/{stage}.md`(6 个阶段契约) / `prompts/{stage}.md`(9 个执行 prompt) / `templates/*.md`(20 份模板) / `examples/*.md`(2 份样例) + `evals/*.md`(回归用例)。

某次重构试图把"规则元数据"从"catalog 风格(每条规则后跟整块 ```yaml ... ``` 元数据)"切到"guide 风格(规则节用 inline blockquote 元数据行)",但只在 `agents/generation.md` 的"禁止做"中加了一条"不得写规则条目注册表风格",**没有同步动 prompts/rule-generation.md、templates/standard-template.md、examples/golden-sample-run.md**。

结果:LLM 跑这个 Skill 时,prompt 层(执行视角)、template 层(范例视角)、example 层(教学视角)都在告诉它"用 catalog 风格";agent 层(架构视角)在告诉它"禁止 catalog 风格"。两条契约共存等于没有契约。**实际产物 4 份 standard-*.md 共 18 处规则节全部回到了 catalog 风格** — 说明运行时 LLM 优先采纳了 prompts/templates/examples 描述,绕开了 agents/ 层的禁止条款。

同期存在的其他漂移:
- `SKILL.md`(7 步轻量流程) vs `workflow.md`(6-agent 编排管道):同 Skill 两套不兼容流程
- `SKILL.md` 写 `status: active(直接可用)`,而 `agents/generation.md` 明令"自动运行不得发布 active"
- `agents/intake-and-scope.md` 的"必须做 1: 先推断 → 再让用户确认 → 再下一步;不静默择一"与 `workflow.md` Auto 模式"自动遍历所有 batch,无中途停顿"直接矛盾
- `evals/boundary-cases.md BC-006`"要求一次只选 1 个 batch"与 Auto 模式"按队列顺序执行多个 batch"措辞冲突

## Guidance

**为多层文档 Skill 建立单一权威源协议**:

1. **指定权威层**:契约性最强的一层(通常是 `agents/{stage}.md`)是该 Skill 的 single source of truth。其他层只能引用、不能新写规则。
2. **定义引用关系**:
   - `SKILL.md` 是路由入口,只做输入校验、模式选择、把执行权交给 workflow,不展开任何阶段细节
   - `prompts/{stage}.md` 是 LLM 执行时的提示语,内容应与对应 `agents/{stage}.md` 契约 1:1 派生,**禁止补字段、禁止换格式**
   - `templates/*.md` 是产物范例,应是按 agents 契约填出的"会通过 Self-check 的样品",而非另一套口径
   - `examples/*.md` 是教学样例,内容必须与产物范例同风格
   - `evals/*.md` 是回归用例,期望必须严格匹配 agents 契约的"必须做/禁止做"清单
3. **加自动化防线**:在 `agents/{stage}.md` 写 Self-check 时,把"格式契约"也列为强制项(例如"每个规则节使用 inline blockquote 元数据行,**没有任何整块 yaml**")。在 `agents/review-and-quality-gate.md` 的 persona 检查清单加同名 BLOCK 条款。这两道门让运行时即便 prompt/template 层退化也能被拦截。
4. **加一致性脚本**:`examples/consistency-checklist.md` 建议 `rg` 命令扫描已知漂移模式(例如 `rg -nP '^\`\`\`yaml\s*$' engineering-standards/*/standard-*.md`),在每次 source 改动后跑一遍。
5. **重构契约时按"prompts → templates → examples → agents → SKILL.md"链式同步**:任意一层的契约描述变了,沿链全检一次,不要只动表面层。

## Why This Matters

LLM 加载 Skill 时按相对重要性读不同层文件,**没有一个统一权威**就会出现两种失败:

| 失败模式 | 表现 | 后果 |
|---|---|---|
| **静默选择最容易遵守的契约** | LLM 读到 prompts 描述 catalog,直接照做,跳过 agents 禁止 | 产物风格与最新设计意图相反 |
| **半合规** | LLM 部分遵守 agents,部分遵守 prompts | 产物里既有 inline 元数据又有 yaml 块,reviewer 无法用 grep 一致性检查 |

更隐蔽的代价是:**Skill 容易写得多,难写得对**。封装 Skill 的门槛只有 5 分钟,封装垃圾的门槛也只有 5 分钟。多层文档共存时,每多一层就多一处可能漂移的契约源,而 Skill 的"为什么存在"和"如何不出垃圾"两个问题需要靠这些层一致协同回答 — 任意一层失声或矛盾,整个 Skill 的可靠性就会崩。

具体到本次教训:产物 catalog 风格的全面回退说明,**只在最权威的 agents 层加禁止条款是不够的** — 必须连同 prompts/templates/examples 的描述一并改写,并且加 Self-check + persona BLOCK 形成运行时双重保险。

## When to Apply

- 当 Skill source package 包含多层文档(SKILL/workflow/agents/prompts/templates/examples 等),且任意一层独立维护
- 当发现 Skill 产物与"最新契约"不一致,但回查发现某一层旧契约还在
- 当用户报告"Skill 有时候按这种方式生成,有时候按另一种" — 几乎都是多层契约漂移所致
- 当为 Skill 加新阶段或改风格 — 在动手前先列出"涉及哪几层文件",而不是只改最上层入口

## Examples

**反例**:只动 `agents/generation.md`

```markdown
# agents/generation.md  禁止做
1. 不得写"规则条目注册表"风格(每条规则一个 YAML 块)——这是本次重写的核心改变。
```

但保留 prompts/rule-generation.md、templates/standard-template.md、examples/golden-sample-run.md 都还在用 catalog 风格示例。

→ 实际运行结果:产物 4 份 standard-*.md 共 18 处规则节全部回到 catalog 风格。

**正例**:链式同步 + 双层防线

1. **prompts/rule-generation.md** 重写为 inline 元数据格式,字段顺序锁定:
   ```markdown
   每条规则必须包含:
   1. H2 标题(`## P0|P1|P2|FORBIDDEN {规则标题}`)
   2. inline 元数据行(紧跟 H2,blockquote 单行,使用 ` · ` 分隔):
      > level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-22 · recommended_action: keep-draft
   ...
   不允许把 inline 行改成多行 yaml 块。
   ```

2. **templates/standard-template.md** 范例同步改 inline:
   ```markdown
   ## P1 KMP 业务能力必须保持 UseCase → Repository 的依赖方向

   > level: P1 · status: draft · source_kind: extracted · evidence_tier: single-project · risk_tag: medium · owner: TBD · last_reviewed: 2026-05-22 · recommended_action: keep-draft

   ### 适用范围
   ...
   ```

3. **agents/generation.md** Self-check 加格式 + 字段全集两条:
   ```markdown
   - [ ] 每个规则节(P0/P1/P2/FORBIDDEN H2/H3)紧跟标题都有 inline 元数据 blockquote 单行,没有任何 ```yaml ... ``` 整块元数据
   - [ ] inline 元数据行字段完整:必含 level/status/source_kind/evidence_tier/risk_tag/owner/last_reviewed/recommended_action 共 8 项
   ```

4. **agents/review-and-quality-gate.md** P2 persona 加 BLOCK + WARN:
   ```markdown
   - [ ] 规则节使用 inline blockquote 元数据行;禁止整块 yaml 元数据 → 若发现 yaml 块 → BLOCK
   - [ ] inline 元数据行字段全集到齐(8 项必含) → 若缺字段 → WARN
   ```

5. **examples/golden-sample-run.md / thin-dogfood-run.md** 改为新格式样例。

6. **examples/consistency-checklist.md** 加 rg 检查:
   ```bash
   rg -nP '^\`\`\`yaml\s*$' engineering-standards/*/standard-*.md  # 应为 0
   rg -nP '^> level: ' engineering-standards/*/standard-*.md       # 应等于规则数
   ```

7. 用脚本批量重写历史产物(本次 4 份文件 18 处规则节,由 Python 替换脚本一次完成)。

→ 改完跑一致性检查:残留 yaml 块 = 0,inline 元数据行 = 18,catalog/doc_mode 残留 = 0,旧 doc_id 命名残留 = 0。

## Related

- 本仓库 `skills/project-standard-extractor/agents/generation.md` Self-check + 禁止做条款
- 本仓库 `skills/project-standard-extractor/agents/review-and-quality-gate.md` P2 persona
- 本仓库 `skills/project-standard-extractor/examples/consistency-checklist.md` 一致性检查 rg 模式
- 本仓库 `CHANGELOG.md` 2026-05-23 01:30:58 与 2026-05-23 03:04:42 两条变更记录
