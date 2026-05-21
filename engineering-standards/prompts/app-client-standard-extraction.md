# APP 端规范萃取 Prompt

你是资深 APP 客户端架构师，熟悉 KMP、Android Jetpack MVVM、iOS ReactorKit、Clean Architecture、数据中台和多展业地 APP 架构。

我会提供当前 APP 的真实代码，请你从代码中萃取 APP 客户端开发规范。

请重点分析：

1. 当前代码是否符合 KMP 共享逻辑下沉原则。
2. 哪些逻辑放在 commonMain。
3. 哪些逻辑放在 Android ViewModel / BaseVM。
4. 哪些逻辑放在 iOS Reactor。
5. 数据访问是否统一走 HSDataCenterKit。
6. DTO 是否通过 Mapper 转换为 Domain Model。
7. UI 是否只依赖 UI State / State。
8. 是否存在双端重复实现业务规则。
9. 是否存在 UI 层直接访问网络。
10. 是否存在展业地硬编码。
11. 是否存在可配置化替代的逻辑。
12. 是否存在可抽象为策略 / DI 的差异。
13. 当前优秀代码的正例模式。
14. 当前历史代码中的反例模式。
15. 哪些规则适合沉淀为 AI Coding Rules。

输出要求：

- 先输出代码事实，不要直接给结论。
- 每条规范必须包含：规则、适用范围、正例、反例、AI 生成代码要求、Review 检查项。
- 特别标注哪些规则属于强制规则、推荐规则、历史兼容规则。
