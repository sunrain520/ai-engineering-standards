# APP 代码开发规范萃取流程

## 1. 目标

本流程用于从真实 APP 项目代码中萃取团队级开发规范，并输出编号化 `00-xx` APP 规范文档、AI Coding Rules、Review Checklist 和 evidence。

萃取目标不是总结某个项目，而是把可复用的工程经验沉淀为团队规则。

## 2. 维度矩阵

| 编号文档 | 萃取维度 | 主要 evidence |
| --- | --- | --- |
| `00-app-client-overview.md` | APP 总览、架构目标、文档导航 | README、架构文档、模块树、已有 owner-confirmed 规范 |
| `01-kmp-shared-layer-standard.md` | KMP 共享层 | UseCase、Repository、Presenter、Domain Model、Mapper、source set |
| `02-android-standard.md` | Android 平台层 | Activity/Fragment、ViewModel/BaseVM、UiState、HSLoadData |
| `03-ios-standard.md` | iOS 平台层 | ViewController、Reactor、Action/Mutation/State、KMP adapter |
| `04-data-center-standard.md` | 数据访问与缓存 | Repository、HSDataCenterKit、Network、Cache、DB、DTO Mapper |
| `05-module-standard.md` | 模块边界 | feature、contract、router、provider、module build file |
| `06-multi-market-standard.md` | 多展业地 | market config、feature flag、theme、language、strategy |
| `07-ui-component-standard.md` | UI 与组件 | component、theme、resource、empty/error/loading view |
| `08-testing-standard.md` | 测试 | commonTest、ViewModel test、Reactor test、mock、fixture |
| `09-performance-standard.md` | 性能与稳定性 | startup、page render、list、network、cache、memory |
| `12-state-error-standard.md` | 状态与错误处理 | UiState、State、ErrorModel、retry、fallback |
| `13-navigation-routing-standard.md` | 路由与页面协作 | Router、DeepLink、contract、provider、route params |
| `14-build-dependency-standard.md` | 构建与依赖治理 | Gradle、KMP build、included build、dependencies |
| `15-security-compliance-standard.md` | 安全与合规 | auth、token、privacy、local storage、log masking |
| `16-observability-standard.md` | 日志、埋点与可观测性 | log、analytics、crash、trace、performance metrics |

`10-app-ai-rules.md` 和 `11-code-review-checklist.md` 是派生视图：应从上述规范中抽取 AI 可执行规则和 Review 检查项，不单独发明新规则。

## 3. 执行步骤

1. **Profile-first**：先扫描项目结构、manifest、README、模块树和敏感路径，输出 project profile、extraction map、batch plan。
2. **按维度建 batch**：每个 batch 对应一个明确维度，例如 `module-boundary`、`android-state`、`kmp-repository`、`build-governance`。
3. **先 facts 后规则**：读取 batch 的代表性文件，先输出 `code_facts`，再分类为 recommended / forbidden / legacy / pending / conflict。
4. **写入编号文档**：规则进入对应 `00-xx` 文档；真实路径和正反例进入 `evidence/`。
5. **派生 AI 与 Review**：把可执行规则同步到 `10-app-ai-rules.md`，把检查项同步到 `11-code-review-checklist.md`。
6. **质量门禁**：检查 evidence、团队级抽象、AI 可执行性、Review 可检查性、冲突和行业风险。
7. **人工确认**：自动萃取输出保持 draft；领域负责人确认后再升级 active。

## 4. 每个 batch 的最低完成标准

1. 至少覆盖该维度的 3 类角色文件；单一文件或单一角色只能进入 pending。
2. 每条 recommended / forbidden 规则必须能追溯到 `EV/POS/NEG/LEG-*`。
3. FORBIDDEN 必须有直接负例或明确风险事实。
4. 规则正文不得包含真实绝对路径；路径只写入 evidence。
5. 生成内容必须同时给出 AI 生成代码要求和 Code Review 检查项。

## 5. 输出边界

1. `standard-*` 萃取产物可以作为 evidence-backed 规则来源，但稳定入口应逐步收敛到编号化 `00-xx` 文档。
2. 无 evidence 或负责人确认的内容不得进入 AI 默认执行路径。
3. 与已有 active 规则冲突的新结论写入 `conflicts.md`，不得覆盖原规则。
4. 相近规则写入 `merge-suggestions.md`，由负责人决定是否合并。
