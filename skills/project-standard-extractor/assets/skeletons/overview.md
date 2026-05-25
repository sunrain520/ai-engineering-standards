# 文件骨架模板池

本目录提供 Phase 2 维度框架在 generation 阶段使用的 **统一文件骨架** 与 **子领域骨架**。所有骨架基于 `assets/standard-template.md` / `assets/overview-template.md` 的占位符风格 (`{{var}}`) 与 metadata blockquote 写法,在其上扩展三态激活标记与子领域专属章节占位。

## 目录结构

```text
assets/skeletons/
├── overview.md                        # 本文件
├── overview-skeleton.md               # 端级 overview 骨架(必含 §未激活维度地图)
├── sub-domain-skeleton.md             # 子领域统一骨架(R51 §1–§12)
├── cross-cutting-skeleton.md          # 横切维度骨架(R55 §3 必含「统一要求」列)
├── app-client/                       # 主架构: KMP × Clean Architecture(commonMain 内 domain/data/presentation)
│   ├── kmp-shared-skeleton.md         # KMP shared(§4 含 expect/actual + Clean 三层)
│   ├── android-skeleton.md            # Android 平台壳 + Hilt 装配 Domain/Data/Platform 三 Module
│   ├── ios-skeleton.md                # iOS 平台壳 + DependencyContainer + FlowBridge
│   └── hybrid-bridge-skeleton.md      # 跨端 Hybrid: H5 / RN 桥接(bundle 多入口 / TurboModule / NativeBridge)
├── frontend/
│   ├── h5-skeleton.md
│   ├── admin-skeleton.md
│   └── sdk-skeleton.md
├── backend/
│   ├── java-skeleton.md
│   ├── python-skeleton.md
│   ├── go-skeleton.md
│   └── node-skeleton.md
└── industry/
    ├── securities-skeleton.md         # SEC-01~10 + XSEC-01~06 全部章节占位
    ├── finance-skeleton.md
    ├── ecommerce-skeleton.md
    ├── education-skeleton.md
    ├── healthcare-skeleton.md
    ├── government-skeleton.md
    └── saas-skeleton.md
```

## 激活态标注约定

每个章节标题旁带 `[{{activation_state}}]` 占位符,由 generation agent 在落盘时替换为以下值之一:

| 状态 | 含义 | 输出形态 |
| --- | --- | --- |
| `baseline` | 端级基线维度,默认必出 | `[baseline]` |
| `activated` | 命中激活信号,直接从代码 evidence 萃取 | `[activated]` |
| `candidate` | 未命中信号,仅在 `未激活维度地图` 列出 | `[candidate]`(章节正文留空白占位) |
| `pending-confirmation` | 命中但 evidence 不足,需 owner 确认 | `[pending]` |
| `shallow` | 命中但深度核验失败(规则数 / 正反例 / evidence 比例不达阈值) | `[shallow]` |

`candidate` 状态仅出现在 overview-skeleton 的「未激活维度地图」节,子领域 skeleton 的章节默认仅落 `baseline` / `activated` / `pending` / `shallow`。

## 占位符语法

- `{{var}}`:运行时由 agent 替换的变量(如 `{{run_id}}`、`{{end_type}}`、`{{sub_domain}}`)
- `{section}`:模板自身的语义占位(沿用 standard-template.md 风格,生成时替换为真实章节标题或文本)
- `<!-- 写作说明 -->`:模板内注释,落盘时由 generation agent 全部删除

## 使用规则

1. 任何端 / 子领域 generation 必须从相应 skeleton 派生,**不允许** 凭空构造章节顺序。
2. `[{{activation_state}}]` 占位符在落盘前必须替换为具体状态;未替换视为 review 阻断项。
3. 状态为 `candidate` 的章节正文留空(只保留章节标题 + 触发条件说明),完整 candidate 列表落到 overview 的「未激活维度地图」。
4. 子领域骨架必须保留通用骨架的全部 12 个 R51 章节;子领域专属内容只能 **嵌入** 章节内,不得替换或删除整章。
5. 跨文档引用统一使用 `{source_doc}「{section_title}」` 二元组,**不使用 Rule ID**。

## 与 standard-template.md 的关系

`standard-template.md` 是 **规则节级别** 的最小单元(P0/P1/FORBIDDEN 单条规则的写法),本目录骨架在其之上提供 **文档级章节框架**;两者协作:

- skeleton 决定 § 顺序、子章节占位、激活态标注;
- standard-template 决定每条规则节的 metadata blockquote、正反例块、AI 要求、Review 检查项写法。

## 验证项

- skeleton 中所有 `{{var}}` 占位符必须在 generation agent 替换表中存在;
- `overview-skeleton.md` 必须包含「未激活维度地图」章节(grep 验证);
- `sub-domain-skeleton.md` 必须包含 R51 §1–§12 全部 12 个章节标题;
- `cross-cutting-skeleton.md` §3 必须包含「统一要求」列;
- `industry/securities-skeleton.md` 必须包含 SEC-01~10 与 XSEC-01~06 全部 16 维占位章节;
- `app-client/kmp-shared-skeleton.md` §4 必须包含 `expect` / `actual` 关键字;
- `app-client/{kmp-shared,android,ios}-skeleton.md` 必须包含 Clean 关键字 `Domain` / `UseCase` / `Entity` / `Repository`;
- `app-client/hybrid-bridge-skeleton.md` 必须包含三大抽象关键字: `bundle` 多入口 / `TurboModule` / `NativeBridge`,且 §6 至少包含 1 条 P0(JS 调用经 Bridge 收口) + 1 条 FORBIDDEN(任意 native 反射 / 跳过签名)。
