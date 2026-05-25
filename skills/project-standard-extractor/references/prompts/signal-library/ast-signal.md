# ast-signal

基于抽象语法树的 pattern 匹配，命中精度高于 grep（如区分 `@Composable` 函数定义与字符串中的 `@Composable`）。**默认实现：ast-grep**（spec-first 已集成）。

## Input

```yaml
signal_id: <string>
dimension_id: <string>
type: ast
repo_root: <abs path>
language: kotlin | swift | java | typescript | javascript | python | go | rust   # 必填
ast_pattern: |
  @Composable
  fun $NAME($$$ARGS) { $$$ }
include_paths:
  - "**/*.kt"
exclude_paths:
  - "**/build/**"
weight: 1
max_evidence: 20
```

## 判定逻辑

1. 调用 `ast-grep --lang <language> --pattern '<ast_pattern>'`，按 `include_paths` / `exclude_paths` 过滤。
2. 至少 1 条匹配 → `hit: true`；evidence 取前 `max_evidence` 条。
3. evidence 字段：`file_path` / `line`（节点起始行）/ `snippet`（命中节点源码截断 200 字符）。
4. ast-grep 不可用或语言不支持时降级为 `grep-signal`（同 patterns 集合）；`fallback: "grep"` + `limitations: "ast-grep <reason>"`。

## Output（schema 同 README）

示例：

```json
{
  "signal_id": "ea-client-08-compose-composable",
  "type": "ast",
  "source": "ast",
  "hit": true,
  "weight": 2,
  "evidence": [
    { "file_path": "feature/order/ui/OrderScreen.kt", "line": 18, "snippet": "@Composable\nfun OrderScreen(state: OrderState) { ... }", "source": "ast" }
  ]
}
```

## 边界条件

- 语言不在 ast-grep 支持矩阵内（如 Dart / Lua / Erlang）时，必须在 `limitations` 字段声明并降级为 grep；不允许静默失败。
- ast_pattern 解析失败 → `hit: false` + `limitations: "ast pattern parse error: ..."`。
- 语法错误的源文件 ast-grep 跳过（warning 不计入 evidence）。
- 二进制 / 大文件 / 路径越界规则同 grep-signal。

## Test scenarios

- Compose Kotlin 文件含 `@Composable fun XXX(...)` 函数定义 → `hit: true`。
- iOS Swift 文件含 `struct OrderView: View { ... }` 结构体 → 用 `language: swift` + 对应 ast_pattern 命中。
- 字符串字面量 `"@Composable"` 不应误命中（与 grep 区别）。
- ast-grep 未安装 → fallback grep + `limitations` 写明降级原因。
