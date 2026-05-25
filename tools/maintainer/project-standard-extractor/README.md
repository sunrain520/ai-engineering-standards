# project-standard-extractor Maintainer Tools

本目录保存 `project-standard-extractor` 的维护者工具。它们是仓库治理资产，不属于可分发 skill 包，也不应由普通 skill 触发路径自动调用。

## 使用边界

- 从仓库根目录执行脚本。
- 只在 Phase 2 repair / force-rebuild 验证任务中使用。
- 普通规范萃取只使用 `skills/project-standard-extractor/SKILL.md` 公开入口，不调用本目录脚本。
- 真实恢复或覆盖类操作必须先确认 git 工作树和目标 `engineering-standards/<domain>/` 范围。

## 命令

```bash
tools/maintainer/project-standard-extractor/backup.sh --dry-run --domain=<domain>
tools/maintainer/project-standard-extractor/backup.sh --domain=<domain> --target=<backup_dir>
tools/maintainer/project-standard-extractor/backup.sh --restore --domain=<domain> --source=<backup_dir>
tools/maintainer/project-standard-extractor/backup.sh --list --domain=<domain>
tools/maintainer/project-standard-extractor/backup.sh --pin --domain=<domain> --backup-id=<UTC-ts>
tools/maintainer/project-standard-extractor/backup.sh --unpin --domain=<domain> --backup-id=<UTC-ts>

tools/maintainer/project-standard-extractor/force-rebuild-validate.sh --domain=<domain> --backup-dir=<backup_dir>
```

## 本地产物

备份默认写入：

```text
tools/maintainer/project-standard-extractor/.local-backups/<domain>/<UTC-ts>/
```

该目录是本地运行产物，不进入版本控制。
