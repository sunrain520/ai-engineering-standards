# Signal Library Prompts

5 类激活信号判定 prompt，由 `references/agents/dimension-activator.md`（U5）按 `references/config/dimension-framework/activation-rules-{end}.yaml` 规则调用。

## 统一输入 / 输出

**Input（共有字段）**：
- `signal_id`：在 activation-rules 中唯一定位的 signal 标识，便于回填。
- `dimension_id`：归属维度，仅用于关联，不参与判定。
- `repo_root`：项目根绝对路径。
- 其余字段按 signal 类型扩展（pattern / paths / manifests / weight 等）。

**Output（共有字段）**：

```json
{
  "signal_id": "<同 input>",
  "type": "grep | ast | file_existence | dependency | gitnexus",
  "source": "grep | ast | file_existence | dependency | gitnexus",
  "hit": true,
  "weight": 1,
  "evidence": [
    { "file_path": "<相对仓库根>", "line": 42, "snippet": "<截断 200 字符内>", "source": "grep | ast | file_existence | dependency | gitnexus" }
  ],
  "limitations": "可选；signal 降级、超时、规则不适用等说明",
  "fallback": "可选；当主路径失败时实际采用的降级路径"
}
```

- `hit`：单个 signal 命中判定结果。**signal hit 不等于 dimension activated**——activation 由 `dimension-activator` agent 按 `combination = any | all | weighted` 与 threshold 聚合。
- `weight`：默认 1；`weighted` 组合下 activation-rules 可覆盖。
- `evidence`：命中证据片段；同一 signal 可有多条；`source` 必须写真实来源，GitNexus graph 路径写 `gitnexus`，fallback 路径写 `file_existence` / `grep` / `ast` / `dependency`；snippet 必须截断（<200 字符）避免 leak。
- `limitations / fallback`：用于 review 与 audit；degrade 不抛 error。

## 5 类 signal 文件

| 文件 | type | 用途 |
| --- | --- | --- |
| `grep-signal.md` | grep | 字符串/正则在指定路径下的命中（默认全仓库） |
| `ast-signal.md` | ast | ast-grep 抽象语法树模式匹配（语言敏感、低误判） |
| `file-existence-signal.md` | file_existence | 路径或 glob 是否存在（目录、配置、骨架文件） |
| `dependency-signal.md` | dependency | 多语言 manifest 依赖声明匹配（pom.xml / build.gradle / package.json / requirements.txt / go.mod / Cargo.toml / Podfile / composer.json） |
| `gitnexus-signal.md` | gitnexus | 优先查询 `.spec-first/graph/graph-facts.json`；不可用降级为 file_existence + grep |

## 边界条件统一约定

- **超时**：单 signal 限时 30s；超时返回 `hit: false` + `limitations: "timeout"`。
- **路径越界**：所有 file_path 必须在 `repo_root` 内；越界判定为 invalid，跳过。
- **二进制文件**：忽略；不在 evidence 中。
- **大文件**：单文件 > 5MB 跳过；记录到 `limitations`。
- **采样上限**：单 signal evidence 最多 20 条；超出时按文件路径字典序保留前 20。
- **大小写**：除明确说明外，pattern 默认大小写敏感；signal 配置可声明 `case_insensitive: true`。
