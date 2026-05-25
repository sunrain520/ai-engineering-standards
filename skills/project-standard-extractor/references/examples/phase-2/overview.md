---
name: phase-2-examples-readme
description: Phase 2 examples 目录索引：证券 PoC / force-rebuild / 增量模式 / 跨项目对比四类典型使用故事
type: examples-index
phase: phase-2
---

# Phase 2 Walkthrough Examples

本目录收录 Phase 2 维度框架（U1–U27）的典型使用故事，供第一次使用的工程师参考。
每个文件完整展示"输入参数 → 阶段执行 → 产物 → 验证"闭环。

## 文件清单

| 文件 | 场景 | 关键能力验证 | 推荐阅读顺序 |
| --- | --- | --- | --- |
| `golden-sample-securities-run.md` | 证券子领域 16 维 PoC（synthetic-poc） | 三态激活 + 维度激活报告 + GitNexus fallback | ① 先读 |
| `force-rebuild-walkthrough.md` | force-rebuild 端到端（safeguard + atomic rollback） | 备份 + 重生 + 校验 + CHANGELOG | ② 可选 |
| `incremental-mode-walkthrough.md` | diff 模式：小范围变更后只重评受影响维度 | 增量模式 + Diff Scoper + evolution.transitions | ③ 推荐 |
| `cross-project-walkthrough.md` | 跨项目对比：3 个后端项目合并统一规范 | unified-activation-map + 跨项目升级 + 冲突归并 | ④ 进阶 |

## Phase 2 使用故事

### 故事 1：接入新行业子领域（证券 PoC）

**场景**：团队刚接到一个证券经纪平台项目，需要快速了解 16 个行业维度哪些已有 evidence、哪些还是候选。

**推荐流程**：

```
读取 golden-sample-securities-run.md，
了解 intake → profile → dimension-activator → generation → review → merge 完整闭环；
注意 synthetic-poc 的边界（不是真实 evidence）；
接入真实项目后参考 §15 局限性与下一步 重跑。
```

**产物核心**：
- `01-securities-standard.md`（16 维骨架 + 三态状态）
- `evidence/dimension-activation-report.json`（activation-report.v1）
- `overview.md`（未激活维度地图）

---

### 故事 2：日常迭代后更新规范（增量模式）

**场景**：上周刚合并了 Android Feature 模块的大范围重构，想确认规范是否需要更新，但不想重跑全量。

**推荐流程**：

```
读取 incremental-mode-walkthrough.md，
了解 extraction_mode=diff 如何只重评变更文件相关维度；
关注 evolution.transitions[]——只有状态变更的维度才写入。
```

**产物核心**：
- 更新后的 `standard-android.md`（受影响章节）
- `dimension-activation-report.json` 的 `evolution.transitions[]`

---

### 故事 3：多项目协同，建统一规范基线（跨项目对比）

**场景**：3 个后端微服务项目各自萃取了激活状态，现在需要合并成一份统一的后端规范基线，并标注每条规则来自哪个项目。

**推荐流程**：

```
读取 cross-project-walkthrough.md，
了解 unified-activation-map 如何"只升不降"合并，
以及冲突归并到 merge-suggestions.md / conflicts.md 的决策树。
```

**产物核心**：
- `unified-activation-map.json`
- `04-backend/standard.md`（三项目合并版）
- `merge-suggestions.md` / `conflicts.md`

---

## 与 Phase 1 样例的关系

| 样例 | Phase | 关注点 |
| --- | --- | --- |
| `../golden-sample-run.md` | Phase 1 | 基础 intake → generation → merge 闭环 |
| `../thin-dogfood-run.md` | Phase 1 | profile-first 轻量画像模式 |
| `../consistency-checklist.md` | Phase 1 | 产物一致性 self-check |
| **本目录** | **Phase 2** | **维度框架 + 三态激活 + 行业子领域** |
