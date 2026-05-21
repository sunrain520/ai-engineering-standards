# 一致性检查清单

执行 `project-standard-extractor` 或修改本 Skill 后，至少检查以下事项。

## 1. 状态词汇

- [ ] 持久化状态只包含 `draft`、`active`、`pending-confirmation`、`conflict`、`legacy-compatible`、`rejected`。
- [ ] 升级候选只使用 `recommended_action: consider promotion`。
- [ ] 没有自动发布 `active` 的说法。

## 2. Evidence 边界

- [ ] 规则正文没有具体项目路径。
- [ ] 真实路径只出现在 `evidence/`。
- [ ] 无 evidence 内容没有进入 AI 默认执行路径。
- [ ] P0 / FORBIDDEN 规则有 evidence 和 Review 检查项。

## 3. 输出落点

- [ ] `pending-confirmation.md` 存在。
- [ ] `merge-suggestions.md` 存在。
- [ ] `conflicts.md` 存在。
- [ ] `evidence/code-facts.md` 存在。
- [ ] `evidence/positive-examples.md` 存在。
- [ ] `evidence/forbidden-examples.md` 存在。
- [ ] `evidence/legacy-compatible.md` 存在。

## 4. 安全

- [ ] evidence 没有 secret、token、private key。
- [ ] evidence 没有生产凭据或敏感配置值。
- [ ] 敏感文件只记录脱敏存在事实。

## 5. 建议搜索

```bash
rg -n 'promotion-candidate labels as states|old standalone review prompt|generated output only|mandatory architecture-owner review|no real evidence required|template rules as draft' engineering-standards docs
rg -n 'secret|token|private key|password' engineering-standards/*/evidence skills/project-standard-extractor/examples
```

命中不一定代表错误，但必须逐条确认是否为示例、禁止项或需要改写的旧口径。
