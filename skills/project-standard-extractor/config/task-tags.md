# Task Tags

固定任务标签用于生成 `rules-index` 候选和 AI Context Pack。不要临时发明同义标签；先归一化到下表。

## 1. task_type 词表

| task_type | 推荐 tags |
| --- | --- |
| `api-development` | `api`, `controller`, `service`, `dto`, `error-code`, `logging` |
| `write-operation` | `api`, `transaction`, `idempotency`, `error-code`, `logging`, `test` |
| `page-development` | `page`, `component`, `state`, `api`, `error-handling`, `i18n` |
| `android-page` | `android`, `viewmodel`, `ui-state`, `network`, `data-center` |
| `ios-page` | `ios`, `reactorkit`, `action`, `mutation`, `state`, `network` |
| `kmp-shared-logic` | `kmp`, `commonMain`, `repository`, `usecase`, `mapper`, `test` |
| `frontend-form` | `frontend`, `form`, `validation`, `api`, `types`, `i18n` |
| `frontend-table` | `frontend`, `table`, `api`, `types`, `permission`, `component` |
| `pc-ipc` | `pc`, `electron`, `ipc`, `preload`, `permission`, `error-handling` |
| `industry-risk` | `industry`, `risk`, `compliance`, `order`, `audit`, `owner-confirmed` |

## 2. 同义词归一化

```text
request / http / fetch -> api
vm / view-model -> viewmodel
uiState / ui_state -> ui-state
dto / response / request -> dto
error / exception -> error-handling
auth / permission / acl -> permission
desktop / electron-app -> pc
regulation / compliance-check -> compliance
```

## 3. 使用规则

1. `rules-index` 候选中的 `tags` 必须来自本文件或明确的 domain/sub_domain 名称。
2. AI Context Pack 的任务识别必须输出 `task_type` 和归一化后的 `tags`。
3. 如果无法归一化，记录为 `pending-confirmation`，不要发明新标签。
