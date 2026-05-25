# Backup Manager Inline Prompt

> 本 prompt 是 `references/agents/backup-manager.md` 的轻量内嵌版本,供 force-rebuild orchestrator 在 step 1–8 / restore / pin / unpin 等子模式下提示 LLM 执行确定性步骤。详细决策算法、字段、失败模式仍以 `references/agents/backup-manager.md` 为单一权威源。

## 入参

```yaml
run_id: <UTC-ts>-<domain>
output_action: force-rebuild | restore | pin | unpin | list
domain: <01-app-client | 02-frontend | ...>
mode_args:
  extraction_mode: full
  restore_from: <UTC-ts>      # restore / pin / unpin 必填
  keep: 10
operator: <host developer>
run_mode: interactive
```

## 严格执行顺序(force-rebuild)

1. **取 lock** — `mkdir skills/project-standard-extractor/.local-backups/<domain>/.lock`,失败 → 拒绝
2. **safeguard 1** — `git status --porcelain --ignored=no engineering-standards/<domain>/` 必须空;非 git / shallow 拒绝
3. **safeguard 2 dry-run** — `scripts/backup.sh --dry-run --domain=<domain>`,记录 sha256 / file_count / byte_count / porcelain snapshot 到内存
4. **safeguard 3 等用户输入** — 必须本轮显式 `confirm <domain>`(全字 case-sensitive);通过后**复检 sha256 + porcelain**
5. **mkdir backup_dir** — `.local-backups/<domain>/<UTC-ts>/`(`<UTC-ts>` = `date -u +%Y%m%dT%H%M%SZ`)
6. **cp -a / rsync** — `scripts/backup.sh --domain=<domain> --target=<backup_dir>`
7. **写 manifest.json** — 用 `assets/backup-manifest-template.json` 骨架补全字段;ajv 校验 `references/config/backup/manifest-schema.json` valid
8. **atomic rename** — `mv engineering-standards/<domain> engineering-standards/<domain>.broken-<ts>`(`<ts>` = `<UTC-ts>`)
9. **`--keep=N` 清理** — 列 `.local-backups/<domain>/` 按 backup_id 字典序,跳过 `pin: true`,删除超出 N 个的最旧份
10. **交还重生** — 返回 `{ success: true, action_taken: backup-and-rename, ... }`,intake-and-scope 转入 phase 2 `full` 管道

> Step 10a / 10b 由 U24 重生流程触发(force-rebuild-validate.sh 通过 / 失败),本 inline prompt 不直接处理。

## 失败模式(canonical 来源 `references/agents/backup-manager.md §失败模式`)

| failure_reason | 短描述 |
| --- | --- |
| `ANOTHER_FORCE_REBUILD_IN_PROGRESS` | step 1 atomic lock 取不到 |
| `NOT_A_GIT_REPO` / `SHALLOW_CLONE_REJECTED` | step 2 仓库形态拒绝 |
| `WORKTREE_DIRTY` | step 2 净 git 失败 |
| `USER_DID_NOT_CONFIRM` / `NON_INTERACTIVE_CONTEXT_REJECTED` | step 4 确认环节失败 |
| `WORKTREE_CHANGED_DURING_CONFIRMATION` | step 4 复检 sha256 / porcelain 失败(TOCTOU) |
| `MANIFEST_SCHEMA_INVALID` | step 7 ajv 校验失败 |
| `ATOMIC_RENAME_FAILED` | step 8 mv 跨文件系统 / 权限 |

## 子模式速查

### restore(`output_action=restore --restore=<ts>`)

1. 取 lock
2. ajv 校验 `.local-backups/<domain>/<ts>/manifest.json` + `manifest.json.sha256` + manifest domain / backup_id 身份
3. `scripts/backup.sh --restore --domain=<domain> --source=<backup_dir>`
4. 脚本内部执行 `.pre-restore-<now>` atomic rename,并校验 file_count / byte_count / sha256_fingerprint;失败由脚本反向 mv
5. changelog-append 追加恢复条目
6. 释放 lock

### pin(`output_action=pin --restore=<ts>`)

1. 取 lock
2. 读 `.local-backups/<domain>/<ts>/manifest.json`,把 `pin` 字段改 true,ajv valid 后写回
3. 释放 lock

### unpin(`output_action=unpin --restore=<ts>`)

1. 取 lock
2. 读 `.local-backups/<domain>/<ts>/manifest.json`,把 `pin` 字段改 false
3. 释放 lock

## Self-check(每次执行前)

- [ ] lock / 净 git / dry-run / confirm / 复检 / cp / atomic rename 顺序未颠倒
- [ ] manifest.json 通过 ajv valid
- [ ] operator 来自 host developer profile
- [ ] failure path 反向 rename 用内存 run_id 持有的 manifest 路径
- [ ] `--keep=N` 用 backup_id 字典序 + skip pinned,**不**用 `head -n -N`
- [ ] non-interactive context 直接拒绝
