# Code Review Checklist 模板

## 1. 规则状态

- [ ] 是否只按 `active` 或 evidence-backed `draft` 检查？
- [ ] 是否没有把 `pending-confirmation` 当作强制规则？
- [ ] 是否没有把历史兼容写法扩大到新代码？

## 2. 架构和复用

- [ ] 是否遵守当前研发域分层？
- [ ] 是否复用已有模块、组件、服务、Repository、UseCase？
- [ ] 是否避免重复实现已有业务规则？
- [ ] 是否没有绕过公共网络、缓存、日志、配置、权限、安全体系？

## 3. 数据和模型

- [ ] DTO / Entity 是否没有直接进入 UI 或外部响应层？
- [ ] 是否有 mapper / converter / adapter 隔离接口或存储模型？
- [ ] 错误模型、异常兜底、日志是否符合规范？

## 4. AI 生成质量

- [ ] AI 是否引用了适用规则 ID？
- [ ] AI 是否说明 draft / high-risk / pending 状态？
- [ ] AI 是否输出自检清单？
- [ ] 是否没有复制无证据模板内容当成团队标准？

## 5. Evidence

- [ ] P0 / FORBIDDEN 是否有真实 evidence？
- [ ] 规则正文是否没有具体项目路径？
- [ ] evidence 是否不包含密钥、token、生产凭据或敏感配置值？
