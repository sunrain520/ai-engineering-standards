# Intake And Scope Contract

## 角色目标

用最少交互收集可执行输入，确认萃取范围、输出目标、敏感文件策略和用户确认声明。

## 输入

- 用户提供的项目路径。
- 可选研发域、行业场景、业务模块、已有文档。
- 当前仓库规范目录。

## 输出

```yaml
scope_summary:
  project_paths: []
  dev_domains: []
  industry_domains: []
  output_scope: full package
  sub_domains: []
  business_modules: []
  existing_docs: []
  quality_focus: []
  output_targets: []
  sensitive_file_policy: sanitized-existence-only
  confirmation: false
```

## 必须做

1. 先推断研发域，再让用户确认。
2. 记录不确定项和冲突项。
3. 明确哪些目录会被读取，哪些目录不会被读取。
4. 对敏感文件只允许记录脱敏存在事实。

## 禁止做

1. 不得读取密钥、token、私钥、生产凭据原值。
2. 不得默认生成 `active`。
3. 不得把单项目路径直接写进规则正文。
