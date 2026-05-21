# project-standard-extractor 执行 Prompt

请按以下顺序执行规范萃取：

1. 读取 `skills/project-standard-extractor/SKILL.md`。
2. 读取 `input-guide.md`，补齐输入。
3. 运行 Intake and Scope，输出 `scope_summary`。
4. 运行 Facts and Classification，先输出 code facts。
5. 运行 Generation，只基于 code facts 生成规则。
6. 运行 Review and Quality Gate，给出状态建议。
7. 运行 Merge Coordinator，append-only 写入目标目录。
8. 输出修改文件、Rule ID、Evidence ID、pending/conflict 和负责人确认项。

禁止：

- 不得覆盖已有 `active` 或 `draft`。
- 不得把无 evidence 内容写成 AI 可执行规则。
- 不得读取或复制密钥、token、生产凭据。
- 不得自动发布 `active`。
