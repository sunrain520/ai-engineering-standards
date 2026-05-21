# AI 自检清单

AI 完成代码或文档生成后必须输出自检。

## 1. 规范引用

- [ ] 是否列出适用规则 ID？
- [ ] 是否说明规则状态：`active` / `draft` / `pending-confirmation` / `conflict`？
- [ ] 是否说明 evidence tier？

## 2. 架构边界

- [ ] 是否遵守对应研发域分层？
- [ ] 是否复用已有模块、组件、Repository、Service、UseCase？
- [ ] 是否没有绕过公共网络、缓存、日志、配置、安全体系？

## 3. 数据边界

- [ ] 是否没有让 DTO / Entity 进入不该进入的层？
- [ ] 是否通过 mapper / adapter / converter 隔离模型差异？
- [ ] 是否有异常、日志、兜底和必要测试？

## 4. 风险提示

- [ ] 是否提示 draft / high-risk 规则？
- [ ] 是否标记 pending / conflict 项？
- [ ] 是否列出需要负责人确认的事项？

## 5. 敏感信息

- [ ] 是否没有输出密钥、token、私钥、生产凭据或用户数据原文？
