# file-existence-signal

文件 / 目录 / glob 路径存在性判定。轻量、确定性高，适合识别"骨架级"信号（如 `migrations/` 目录存在 → 命中数据库迁移维度）。

## Input

```yaml
signal_id: <string>
dimension_id: <string>
type: file_existence
repo_root: <abs path>
paths:                       # 必填，至少 1 条；支持 glob
  - "migrations/**"
  - "src/main/resources/db/migration/V*.sql"
match_mode: any | all        # 可选；默认 any
weight: 1
max_evidence: 20
```

## 判定逻辑

1. 在 `repo_root` 下展开每个 glob，过滤 `node_modules` / `.git` / `build` / `dist` / `vendor` / `target` / `.gradle`。
2. `match_mode: any` → 任一 path 命中即 `hit: true`；`match_mode: all` → 全部命中才 `hit: true`。
3. 命中的实际文件 / 目录路径写入 evidence；目录命中时 `line: null` + `snippet` 留空。
4. 命中数量超 `max_evidence` 时按字典序保留前 N。

## Output

```json
{
  "signal_id": "ea-backend-02-migrations-dir",
  "type": "file_existence",
  "source": "file_existence",
  "hit": true,
  "weight": 1,
  "evidence": [
    { "file_path": "src/main/resources/db/migration/V001__init.sql", "line": null, "snippet": "", "source": "file_existence" }
  ]
}
```

## 边界条件

- 软连接默认跟随；循环链接跳过且记录 `limitations`。
- 大量命中（> 1000 文件）按字典序截断；`limitations: "truncated to <N>"`。
- 路径越界（绝对路径超出 `repo_root`）拒绝，记录 `limitations`。
- 大小写：默认 case-sensitive（macOS APFS 仍执行字符串比较）。

## Test scenarios

- 项目根含 `migrations/`，paths `migrations/**` → `hit: true` + 该目录下文件 evidence。
- 项目无 `pom.xml`、paths `pom.xml`、match_mode `all` → `hit: false`。
- 项目同时含 `Info.plist` 与 `AndroidManifest.xml`，paths 二者 + match_mode `all` → `hit: true`（双端项目）。
- glob 命中文件超 max_evidence → `limitations` 标注截断。
