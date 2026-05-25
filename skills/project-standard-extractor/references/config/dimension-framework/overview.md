# Dimension Framework 配置目录

本目录承载 project-standard-extractor Phase 2 维度框架（dimension framework）的 machine-readable 配置：维度池 / 激活规则 / 深度指标 / 激活报告 schema。

## 文件清单

| 文件 | 作用 | 落地 unit |
| --- | --- | --- |
| `schema.json` | 维度池 fixture 通用 JSON Schema（layer / dimensions / 字段约束） | U1 |
| `baseline-dimensions.yaml` | 跨端 baseline 维度池（D01/D02/D06/D09/D11/D12，origin R52 强制 6 项） | U1 |
| `dimensions-app-client.yaml` | 客户端扩展维度池（EA-Client-01~08；KMP/Android/iOS 子领域） | U1 |
| `dimensions-frontend.yaml` | 前端扩展维度池（EA-Web-01~11；H5/Admin/SDK 子领域） | U1 |
| `dimensions-backend.yaml` | 后端扩展维度池（EA-Backend-01~10；Java/Python/Go/Node 子领域） | U1 |
| `dimensions-industry.yaml` | 行业通用维度池（IND-01~06；金融/电商/教育/医疗/政企/SaaS 子领域） | U1 |
| `dimensions-industry-securities.yaml` | 证券子领域维度池（SEC-01~10 + XSEC-01~06，共 16 维） | U1 |
| `depth-indicator.yaml` | 各维度产出最低深度门槛（rules/evidence/示例数） | U1 |
| `activation-rules-app-client.yaml` | 客户端 activation 规则（signals + combination + threshold） | U3（待落地） |
| `activation-rules-frontend.yaml` | 前端 activation 规则 | U3（待落地） |
| `activation-rules-backend.yaml` | 后端 activation 规则 | U3（待落地） |
| `activation-rules-industry.yaml` | 行业 activation 规则（含证券） | U3（待落地） |
| `activation-report-schema.json` | 激活报告输出 schema（per-run 持久化） | U17（待落地） |

## 使用约定

- **维度池只描述维度本身**：name / core_concerns / must_check_items / owner_phase / activation_signal_hints。
- **激活逻辑独立**：每个维度具体由哪些 signal 命中、采用 any/all/weighted 组合、阈值多少，统一写在 `activation-rules-{end}.yaml`，便于端 adapter 内部独立维护。
- **三态默认**：baseline 维度 `state_default = baseline`（无 signal 命中亦必出 pending 占位）；扩展 / 行业维度 `state_default = candidate`（命中后变 activated，未命中保留在 dimension-coverage-map.md）。
- **深度门槛**：每个 activated 维度按 `depth-indicator.yaml` 提供的 baseline 或端 / 行业 override 校验最低产出量；不达标由 review-and-quality-gate 阶段拦截或降级。
- **跨维度引用**：`cross_dimensions` 字段不参与 activation，仅供 review 阶段做交叉一致性检查。

## Schema 校验

所有 `*.yaml` 维度池文件必须通过 `schema.json` 校验。`baseline-dimensions.yaml` 还要求 `dimensions` 字段同时出现 D01/D02/D06/D09/D11/D12 六个 key（origin R52 与 AE8 强制约束）。

## 下游消费方

| 消费方 | 用途 |
| --- | --- |
| `references/agents/dimension-activator.md`（U5） | 加载 baseline + per-end + activation-rules，输出 `activation-report.json` |
| `references/agents/profile-and-batch-planner.md`（U7） | 读取激活后的维度集合，规划 batch 调度 |
| `references/agents/generation.md` 内 4 personas（U8） | 按子领域骨架在每个维度内产出 rules + evidence |
| `references/agents/review-and-quality-gate.md`（U9） | 对照 `depth-indicator.yaml` 双门禁校验 |
| `references/agents/merge-coordinator.md`（U10） | 三态汇总写入 `dimension-coverage-map.md` |

详见 `skills/project-standard-extractor/SKILL.md` 与 `references/workflow.md` 的 Phase 2 章节。
