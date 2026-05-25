# dependency-signal

多语言依赖 manifest 中的 artifact / package / module 命中判定。覆盖主流后端 / 前端 / 客户端 manifest。

## Input

```yaml
signal_id: <string>
dimension_id: <string>
type: dependency
repo_root: <abs path>
manifests:                   # 可选；默认全部
  - pom.xml
  - build.gradle
  - build.gradle.kts
  - package.json
  - requirements.txt
  - pyproject.toml
  - Pipfile
  - go.mod
  - Cargo.toml
  - Podfile
  - Package.swift
  - composer.json
  - Gemfile
patterns:                    # 必填；artifact/package 名子串或精确名
  - rocketmq-spring-boot-starter
  - org.apache.kafka
exact: false                 # 可选；默认子串匹配，true 则精确匹配 artifact 名
match_scope:                 # 可选；不同 manifest 的字段范围
  package_json: ["dependencies", "devDependencies", "peerDependencies"]
  pyproject: ["project.dependencies", "tool.poetry.dependencies"]
weight: 1
max_evidence: 20
```

## 判定逻辑

1. 自动发现 `repo_root` 下所有 monorepo 子模块的 manifest（多 `pom.xml` / 多 `package.json`）。
2. 按 manifest 类型解析：
   - `pom.xml` → `<dependency>/<artifactId>` + `<groupId>`。
   - `build.gradle` / `build.gradle.kts` → `implementation` / `api` / `compileOnly` / `runtimeOnly` 等声明的 artifact 坐标。
   - `package.json` → `match_scope` 指定字段（默认 dependencies + devDependencies + peerDependencies）。
   - `requirements.txt` / `Pipfile` / `pyproject.toml` → 包名（忽略版本约束）。
   - `go.mod` → `require` 块。
   - `Cargo.toml` → `[dependencies]` / `[dev-dependencies]` / `[build-dependencies]`。
   - `Podfile` / `Package.swift` → pod / package 名。
   - `composer.json` → `require` / `require-dev`。
   - `Gemfile` → `gem` 行。
3. 对每个解析出的 artifact 名，执行 substring（或 `exact: true` 时精确）匹配；命中即 evidence。
4. evidence：`file_path`（manifest 路径）+ `line`（声明行）+ `snippet`（artifact 名 / 行原文）。

## Output

```json
{
  "signal_id": "ea-backend-04-rocketmq-dep",
  "type": "dependency",
  "source": "dependency",
  "hit": true,
  "weight": 1,
  "evidence": [
    { "file_path": "pom.xml", "line": 73, "snippet": "<artifactId>rocketmq-spring-boot-starter</artifactId>", "source": "dependency" }
  ]
}
```

## 边界条件

- manifest 文件不存在 → 跳过该 manifest，不记 evidence；不抛 error。
- manifest 解析失败（损坏 / 非法 yaml/xml/json）→ `limitations: "manifest parse error: <path>"`，继续其他 manifest。
- 版本号不参与命中（artifact / package 名只看名）。
- monorepo 多 manifest 时，evidence 按文件路径字典序排列，截断到 max_evidence。
- TOML / YAML 多 inline table → 至少匹配 key 名；版本约束忽略。

## Test scenarios

- `pom.xml` 含 `<artifactId>rocketmq-spring-boot-starter</artifactId>`，pattern `rocketmq` → `hit: true`。
- `package.json` `dependencies` 含 `"@sentry/react": "^7.0"`，pattern `@sentry`、exact false → `hit: true`。
- `go.mod` 含 `github.com/IBM/sarama v1.40.0`，pattern `sarama`，exact false → `hit: true`。
- 项目无任何 manifest → `hit: false`，evidence 空，无 limitations。
- 多 manifest 命中超 max_evidence → 字典序截断 + `limitations` 标注。
