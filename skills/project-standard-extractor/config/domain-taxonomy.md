# Domain Taxonomy

## 1. 研发域

| domain | 说明 | 输出目录 |
| --- | --- | --- |
| `app-client` | APP 客户端，含 KMP、Android、iOS、数据中台、多展业地 | `engineering-standards/01-app-client/` |
| `pc-client` | PC 客户端，含 Mac、Windows、跨平台公共层 | `engineering-standards/02-pc-client/` |
| `frontend` | H5、Admin、组件、API、状态、权限、类型 | `engineering-standards/03-frontend/` |
| `backend` | Java、Python、API、数据库、缓存、MQ、任务 | `engineering-standards/04-backend/` |
| `testing` | 单测、集成测试、E2E、质量门禁 | `engineering-standards/05-testing/` |
| `release` | 发版、灰度、回滚、变更治理 | `engineering-standards/06-release/` |
| `security` | 安全、权限、数据保护、敏感信息处理 | `engineering-standards/07-security/` |
| `ai-coding` | AI 输入、输出、自检和评审规则 | `engineering-standards/08-ai-coding/` |
| `industry` | 证券、信贷、银行等跨研发域行业规则 | `engineering-standards/09-industry/` |

## 2. 子领域矩阵

### APP

- KMP Shared Layer
- Android MVVM / BaseVM / HSLoadData
- iOS ReactorKit
- HSDataCenterKit
- 多展业地
- UI Component
- Testing
- Performance

### Frontend

- H5
- Admin
- Components
- API Client
- State
- Permission
- Types

### Backend

- Java
- Python
- API
- Database
- Cache
- MQ
- Jobs
- Observability

### Industry

- Securities
- Credit
- Banking
- Risk Control
- Compliance
- Transaction Safety

## 3. 子领域状态

每个子领域必须标记一种状态：

- `evidence-backed`：已有真实 evidence。
- `pending-confirmation`：等待负责人确认。
- `no-evidence`：暂无证据，不输出 AI 可执行规则。
- `out-of-scope`：本次不覆盖。
