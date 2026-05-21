# {Domain} Code Review Checklist

## 1. 架构合规

- [ ] 是否遵守本研发域分层？
- [ ] 是否复用已有能力？
- [ ] 是否没有重复实现核心业务规则？

## 2. 规则状态

- [ ] 是否只按 `active` 或 evidence-backed `draft` 检查？
- [ ] 是否没有把 `pending-confirmation` 当作强制规则？
- [ ] 是否没有扩大 `legacy-compatible` 的历史写法？

## 3. AI 生成质量

- [ ] 是否引用适用规则 ID？
- [ ] 是否输出 draft / high-risk warning？
- [ ] 是否完成自检？

## 4. Evidence

- [ ] P0 / FORBIDDEN 是否有真实 evidence？
- [ ] 规则正文是否没有具体路径？
- [ ] evidence 是否无敏感信息原值？
