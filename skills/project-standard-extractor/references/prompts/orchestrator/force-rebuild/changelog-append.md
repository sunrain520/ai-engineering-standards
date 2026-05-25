# Changelog Append Helper

> U24 + U21 共用 helper。force-rebuild / restore success path 的最后一步:把单行条目追加到根 `CHANGELOG.md`。U21 phase 2 release 收尾也复用本 helper(扩展 `event_type`)。

## 设计原则

- **幂等 + 原子**:同一 `run_id` 重复调用不会重复追加;追加用 atomic write(临时文件 + `mv`),磁盘满 / 权限 / git 锁中断不会写半行。
- **格式与根 CHANGELOG 现行模式严格一致**:`- v<version> YYYY-MM-DD HH:MM:SS <operator>: <摘要> [(user-visible)]`
- **operator 来自 host developer profile**:不允许 LLM 自作主张写其他名字。
- **追加失败 = force-rebuild 失败**:helper 在 backup-manager step 10a 末段执行;失败立即返回错误码,触发 backup-manager step 10b atomic rollback。

## 入参

```yaml
event_type: force-rebuild | restore | phase-2-release    # U21 复用 phase-2-release
domain: 01-app-client                                     # event_type ∈ {force-rebuild, restore} 必填
backup_path: ".local-backups/01-app-client/20260525T130000Z/"  # force-rebuild 必填
restored_from_ts: "20260520T100000Z"                      # restore 必填
dimension_activation_report_summary:                      # force-rebuild 必填(摘要不超 200 字符)
  baseline: 12
  activated: 28
  candidate: 4
  pending: 7
  shallow: 3
run_id: "20260525T134800Z-01-app-client"
operator: "<host developer>"                              # 来自 .claude/spec-first/.developer 或 .codex/spec-first/.developer
user_visible: true                                         # force-rebuild / restore 默认 true(用户主动操作);phase-2-release 由用户明示
version: "0.1.0"                                          # 从根 CHANGELOG.md 头部条目继承,不自增
```

## host developer profile 读取顺序

1. `.claude/spec-first/.developer`(优先)
2. `.codex/spec-first/.developer`(次选)
3. 两者都不存在 → 返回 `OPERATOR_PROFILE_MISSING`,拒绝追加,触发 backup-manager 失败回滚
4. 文件存在但内容为空 / 仅空白 → 同 3
5. 文件包含 `name: <value>` YAML 行 → 取 `<value>`;仅纯字符串 → 整行 trim 当 operator

## 输出格式(写入 `CHANGELOG.md` 顶部 `## [Unreleased]` 节首行)

### force-rebuild

```
- v0.1.0 2026-05-25 13:48:00 矿工: project-standard-extractor force-rebuild 01-app-client,备份至 .local-backups/01-app-client/20260525T130000Z/;新激活 map 摘要 baseline=12 activated=28 candidate=4 pending=7 shallow=3 (user-visible)
```

### restore

```
- v0.1.0 2026-05-25 14:02:11 矿工: project-standard-extractor restore 01-app-client 至 backup 20260520T100000Z (user-visible)
```

### phase-2-release(U21 复用)

```
- v0.1.0 2026-05-25 23:50:00 矿工: project-standard-extractor phase 2 dimension framework 全量交付,U1–U27 完成 (user-visible)
```

## 严格执行顺序

1. **校验入参**:
   - `event_type` 在白名单
   - `event_type=force-rebuild` 必填 `domain` / `backup_path` / `dimension_activation_report_summary`
   - `event_type=restore` 必填 `domain` / `restored_from_ts`
   - `event_type=phase-2-release` 必填 `version`(默认从 CHANGELOG 头继承)
   - 任一未通过 → 返回 `INVALID_CHANGELOG_INPUT`,拒绝追加
2. **读 host developer profile** 取 operator(见上节);失败 → `OPERATOR_PROFILE_MISSING`
3. **生成 timestamp**:`date '+%Y-%m-%d %H:%M:%S'`(本地时区,与 root CHANGELOG 现有条目一致;**不**用 UTC,UTC 仅用于 backup_id)
4. **检查幂等**:grep `run_id` 在现有 `CHANGELOG.md` 已出现 → 跳过追加,返回 `success: true, skipped: true`(同次 retry 安全)
5. **构造新行**:按 §输出格式 选模板渲染;摘要超 200 字符截断 + `...`(避免单行过长)
6. **atomic write**:
   - 读 `CHANGELOG.md` 全文到内存
   - 在 `## [Unreleased]` 节标题后第一空行前插入新行
   - 写到临时文件 `CHANGELOG.md.tmp.<run_id>`
   - `mv CHANGELOG.md.tmp.<run_id> CHANGELOG.md`(POSIX atomic on same FS)
7. **可选 git add**:仅当 `run_mode=interactive` 且 `auto_stage=true`(默认 false)时 `git add CHANGELOG.md`;commit 仍由用户手动决定
8. **返回 success**:
   ```json
   { "success": true, "skipped": false, "appended_line": "<full line>", "operator": "<name>", "version": "0.1.0" }
   ```

## 失败模式

| failure_reason | 触发条件 | 处置 |
| --- | --- | --- |
| `INVALID_CHANGELOG_INPUT` | step 1 入参校验失败 | 返回错误,不写文件;不触发 rollback(intake-and-scope 阶段就该拦截) |
| `OPERATOR_PROFILE_MISSING` | step 2 两个 profile 都缺 / 内容空 | 返回错误;force-rebuild 路径下触发 backup-manager step 10b atomic rollback |
| `CHANGELOG_NOT_FOUND` | 根 `CHANGELOG.md` 不存在 | 返回错误;**不**自动创建(避免覆盖 git 仓库语义) |
| `UNRELEASED_SECTION_MISSING` | 文件存在但无 `## [Unreleased]` 节 | 返回错误;提示用户先在 CHANGELOG.md 头部加 `## [Unreleased]` |
| `ATOMIC_WRITE_FAILED` | 磁盘满 / 权限 / 跨文件系统 mv | 返回错误;触发 backup-manager step 10b |
| `RUN_ID_ALREADY_LOGGED` | step 4 grep 命中 | **不算失败**,返回 `success: true, skipped: true` |

## Self-check

- [ ] event_type / domain / backup_path / restored_from_ts 互斥校验通过
- [ ] operator 来自 host developer profile,**不**由 LLM 编造
- [ ] timestamp 用本地时区,format `YYYY-MM-DD HH:MM:SS`
- [ ] 摘要 ≤ 200 字符
- [ ] atomic write(tmp + mv),非 echo 直接 append
- [ ] 幂等:相同 run_id 第二次调用返回 skipped=true
- [ ] 追加失败 → 返回错误,**不**静默吞掉(force-rebuild 必须感知失败才能回滚)

## 调用方

- `references/agents/backup-manager.md` step 10a(force-rebuild success path):`event_type=force-rebuild`
- `references/agents/backup-manager.md` restore success path:`event_type=restore`
- U21 phase 2 release 收尾:`event_type=phase-2-release`,人工触发

## 跨 host 兼容

- Linux / macOS:`mv` POSIX atomic 同 FS;backup_dir 与 CHANGELOG 同根仓库根,跨 FS 风险低
- 跨 FS 部署(如 backup_dir 软链到 NAS):helper 不写 backup_dir,只改根 CHANGELOG.md,**不受影响**
- Windows / WSL:atomic rename 行为不同;但 spec-first init 当前只支持 Claude / Codex POSIX runtime,Windows 由 host 工具链自适配,本 helper 不做特化
