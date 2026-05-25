# grep-signal

字符串 / 正则在仓库内文件中的命中判定。配合 `ripgrep`（首选）或等效工具实现。

## Input

```yaml
signal_id: <string>          # 必填，唯一
dimension_id: <string>       # 必填，归属维度
type: grep                   # 固定
repo_root: <abs path>        # 必填
patterns:                    # 必填，至少 1 条
  - "@KafkaListener"
  - "@RocketMQMessageListener"
include_paths:               # 可选；默认全仓库
  - "src/**/*.java"
exclude_paths:               # 可选；常用：node_modules / build / dist / .git / vendor / target / .gradle
  - "**/build/**"
case_insensitive: false      # 可选；默认 false
weight: 1                    # 可选；默认 1
max_evidence: 20             # 可选；默认 20
```

## 判定逻辑

1. 在 `include_paths` 下用 `rg -nF`（fixed string）或 `rg -nE`（regex；按 `patterns` 是否含正则元字符自动选择）扫描，遵循 `exclude_paths`、二进制跳过、大文件跳过。
2. 任一 pattern 命中即 `hit: true`，多个 pattern OR 关系。
3. 收集 evidence：每条 `file_path`（相对 `repo_root`）+ `line`（行号）+ `snippet`（命中行截断 200 字符）；去重（同 file:line 多 pattern 命中归并为一条）。
4. evidence 数量超 `max_evidence` 时，按 `file_path` 字典序保留前 N。

## Output

```json
{
  "signal_id": "ea-backend-04-mq-annotations",
  "type": "grep",
  "source": "grep",
  "hit": true,
  "weight": 1,
  "evidence": [
    { "file_path": "src/main/java/com/example/mq/OrderListener.java", "line": 21, "snippet": "@KafkaListener(topics = \"order-events\")", "source": "grep" }
  ]
}
```

无命中时：

```json
{ "signal_id": "...", "type": "grep", "source": "grep", "hit": false, "weight": 1, "evidence": [] }
```

## 边界条件

- pattern 含正则特殊字符且未声明 regex 模式时，按 fixed string 处理（避免误命中）；如确需正则，在 `patterns` 数组同位置以 `regex:` 前缀声明（例：`regex:^@(Kafka|RocketMQ).*Listener`）。
- `case_insensitive: true` 在 fixed 与 regex 两路均生效。
- 命中后立即可短路退出（任一 pattern hit 即 `hit: true`）；为收集证据全量扫描后再截断。
- ripgrep 不可用时降级为 `git ls-files | xargs grep`，`limitations` 字段记录降级原因。

## Test scenarios

- 给定 `src/main/java/com/example/mq/OrderListener.java` 含 `@KafkaListener(topics="order-events")`，pattern `@KafkaListener` 命中 → `hit: true` + 该文件 evidence。
- 仅 `node_modules/` 下命中、`exclude_paths` 含 `node_modules/**` → `hit: false`。
- `case_insensitive: true` + pattern `kafka` 命中 `Kafka` 大小写 → `hit: true`。
- 大文件（> 5 MB）跳过；`limitations` 列出文件路径。
