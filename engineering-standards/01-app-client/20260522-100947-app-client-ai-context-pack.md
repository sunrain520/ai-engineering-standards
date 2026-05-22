---
doc_id: "app-client-20260522-100947-app-client-ai-context-pack"
title: "App Client Multi Batch AI Context Pack"
domain: "app-client"
sub_domain: "common"
doc_type: "ai-context-pack"
version: "v0.1.0"
status: "draft"
owner: "TBD"
index_format: "engineering-standards-md-v1"
indexable: false
run_id: "20260522-100947-app-client"
tags:
  - "app-client"
  - "common"
  - "ai-context-pack"
---

# App Client Multi Batch AI Context Pack

## 1. 当前需求

使用 `project-standard-extractor` 从 `kaz-mvp` 的多个 ready batch 萃取 APP 客户端规范。

## 2. 任务识别

- domain: `app-client`
- sub_domain: `android`, `kmp-shared`, `module-boundary`, `build-governance`
- task_type: `app-bootstrap`, `base-fragment-ui-state`, `route-provider-and-login-entry`, `account-page-composition`, `clean-architecture-usecase-repository`, `dependency-version-local-fast-build`
- module: `app-kaz`, `core-ui-kit`, `trade-core`, `trade-account`, `trade-order`, `gradle-root`
- batch_id: `multi-batch`
- status: `candidate`

## 3. 命中规则

| source_doc | section_title | level | evidence_doc | tags |
| --- | --- | --- | --- | --- |
| `standard-module-boundary.md` | `P1 跨域协作必须通过 contract 稳定边界` | P1 | `evidence/code-facts.md` | `app-client`, `module-boundary`, `cross-module-contract` |
| `standard-android.md` | `P1 App 壳初始化必须区分宿主进程与子进程` | P1 | `evidence/code-facts.md` | `app-client`, `android`, `app-bootstrap` |
| `standard-android.md` | `P1 页面基类选择必须匹配页面状态复杂度` | P1 | `evidence/code-facts.md` | `app-client`, `android`, `ui-state` |
| `standard-kmp-shared.md` | `P1 KMP 业务能力必须保持 UseCase -> Repository 的依赖方向` | P1 | `evidence/code-facts.md` | `app-client`, `kmp-shared`, `clean-architecture` |
| `standard-build-governance.md` | `P1 本地工程替换必须集中在根 settings 治理` | P1 | `evidence/code-facts.md` | `app-client`, `build-governance`, `dependency-substitution` |

引用格式：

```text
standard-module-boundary.md「P1 跨域协作必须通过 contract 稳定边界」
```

## 4. 必须加载的规范

- `engineering-standards/01-app-client/standard-module-boundary.md`
- `engineering-standards/01-app-client/standard-android.md`
- `engineering-standards/01-app-client/standard-kmp-shared.md`
- `engineering-standards/01-app-client/standard-build-governance.md`
- `engineering-standards/01-app-client/ai-rules.md`
- `engineering-standards/01-app-client/review-checklist.md`
- `engineering-standards/01-app-client/evidence/code-facts.md`
- `engineering-standards/01-app-client/pending-confirmation.md`

## 5. 相关代码路径

- `contract/trade/build.gradle.kts`
- `contract/quotes/build.gradle.kts`
- `contract/platform/build.gradle.kts`
- `app-kaz/build.gradle`
- `app-kaz/src/main/AndroidManifest.xml`
- `app-kaz/src/main/java/com/huasheng/kaz/global/GlobalApplication.kt`
- `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/base/BaseFragment.kt`
- `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseLoadDataFragment.kt`
- `core/core-ui-kit/src/main/java/com/hstong/core/uikit/basefragment/baseload/BaseViewModel.kt`
- `feature/trade/trade-core/src/main/java/com/hstong/trade/core/router/TradeRouter.kt`
- `feature/trade/trade-account/src/main/java/com/hstong/trade/account/security/SecurityAccountFragment.kt`
- `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/usecase/GetAllOrdersUseCase.kt`
- `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/domain/repository/OrderRepository.kt`
- `submodules/biz-common/modules/trade/trade-order/src/commonMain/kotlin/com/hs/kmp/biz/securities/trade/order/presentation/all/AllOrdersPresenter.kt`
- `settings.gradle`
- `build.gradle`

## 6. 生成代码要求

- 必须通过 `contract`、路由契约或稳定接口处理跨业务域调用。
- 必须保持 `contract` 不依赖 `feature` 实现模块。
- 不得在 `contract` 中生成页面实现、复杂业务流程或内部状态管理代码。
- 命中 `pending-confirmation.md「PENDING-APP-1: contract 模块 UI 依赖是否应收敛」` 时，只能提示负责人确认。
- 命中 `standard-android.md`、`standard-kmp-shared.md`、`standard-build-governance.md` 的 draft 规则时，只能作为草案上下文使用，并在输出中标注 `draft` 与 `single-project evidence`。
- 命中 `pending-confirmation.md「PENDING-APP-2: core-ui-kit 是否应拆除对聚合 KMP 入口的直接依赖」` 或 `pending-confirmation.md「PENDING-APP-3: 账户容器是否允许直接注入 KMP UseCase」` 时，只能提示负责人确认。

## 7. 自检要求

生成后必须逐条引用命中的 `standard-*.md「section_title」` 输出遵守情况；draft 规则不得宣称为 active。
