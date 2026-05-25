#!/usr/bin/env bash
# project-standard-extractor backup helper
# 跨平台兼容: macOS BSD / GNU Linux / WSL
# 由 project-standard-extractor maintainer 流程调用,实现 cp -a 全量备份、sha256 fingerprint、--restore 拷回
#
# 用法:
#   tools/maintainer/project-standard-extractor/backup.sh --dry-run --domain=<domain>
#       计算 sha256 fingerprint + file_count + byte_count + exclude_patterns,不写盘
#   tools/maintainer/project-standard-extractor/backup.sh --domain=<domain> --target=<backup_dir>
#       全量备份(cp -a),写 manifest.json 必需字段到 stdout(JSON)
#   tools/maintainer/project-standard-extractor/backup.sh --restore --domain=<domain> --source=<backup_dir>
#       从 backup_dir 拷回 engineering-standards/<domain>/
#   tools/maintainer/project-standard-extractor/backup.sh --list --domain=<domain>
#       列出本工具目录 .local-backups/<domain>/ 下所有 backup(JSON 数组,字典序);老 backup 无 pin → 视为 false
#   tools/maintainer/project-standard-extractor/backup.sh --pin --domain=<domain> --backup-id=<UTC-ts>
#   tools/maintainer/project-standard-extractor/backup.sh --unpin --domain=<domain> --backup-id=<UTC-ts>
#       切换 manifest.json `pin: bool`;不计入 --keep=N 自动清理(老 backup 无 pin 视为 false 兼容)
#
# 注意:
# - 默认排除模式: evidence/raw-* / temp/ / .git
# - 不调用 head -n -N (macOS BSD 不支持负数语法)
# - sha256 同时支持 shasum -a 256 (BSD) 与 sha256sum (GNU)
# - JSON 读写依赖 python3(macOS / Linux 默认带);若缺,pin/unpin/list 报错

set -euo pipefail

# ---------- helper ----------
die() { echo "ERR: $*" >&2; exit 1; }

sha256_cmd() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum
  else
    die "no sha256 tool: install shasum or sha256sum"
  fi
}

# 仓库根: 调用方必须从仓库根执行
REPO_ROOT="$(pwd)"

# 默认排除模式 (与 manifest.exclude_patterns 同步)
EXCLUDE_PATTERNS=("evidence/raw-*" "temp" ".git")

# ---------- 计算 sha256 fingerprint ----------
# 对源目录排序后的 file list + content 计算 sha256
# find 排除 evidence/raw-* / temp/ / .git
compute_fingerprint() {
  local src="$1"
  if [ ! -d "$src" ]; then
    echo ""
    return
  fi
  (
    cd "$src"
    LC_ALL=C find . -type f \
      -not -path './evidence/raw-*' \
      -not -path './evidence/raw-*/*' \
      -not -path './temp' \
      -not -path './temp/*' \
      -not -path './.git' \
      -not -path './.git/*' \
      -not -name 'manifest.json' \
      -not -name 'manifest.json.sha256' \
      -not -name 'failure.log' \
      | LC_ALL=C sort
  ) | while read -r relpath; do
    echo "$relpath"
    cat "$src/$relpath" 2>/dev/null || true
  done | sha256_cmd | awk '{print $1}'
}

count_files() {
  local src="$1"
  if [ ! -d "$src" ]; then
    echo 0
    return
  fi
  (
    cd "$src"
    LC_ALL=C find . -type f \
      -not -path './evidence/raw-*' \
      -not -path './evidence/raw-*/*' \
      -not -path './temp' \
      -not -path './temp/*' \
      -not -path './.git' \
      -not -path './.git/*' \
      -not -name 'manifest.json' \
      -not -name 'manifest.json.sha256' \
      -not -name 'failure.log' \
      | wc -l | tr -d ' '
  )
}

count_bytes() {
  local src="$1"
  if [ ! -d "$src" ]; then
    echo 0
    return
  fi
  # 跨平台: 用 wc -c (POSIX) 累加
  local total=0
  while IFS= read -r f; do
    local size
    size=$(wc -c <"$src/$f" 2>/dev/null | tr -d ' ' || echo 0)
    total=$((total + size))
  done < <(
    cd "$src"
    LC_ALL=C find . -type f \
      -not -path './evidence/raw-*' \
      -not -path './evidence/raw-*/*' \
      -not -path './temp' \
      -not -path './temp/*' \
      -not -path './.git' \
      -not -path './.git/*' \
      -not -name 'manifest.json' \
      -not -name 'manifest.json.sha256' \
      -not -name 'failure.log'
  )
  echo "$total"
}

# ---------- argparse ----------
MODE=""
DOMAIN=""
TARGET=""
SOURCE=""
BACKUP_ID=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) MODE="dry-run" ;;
    --restore) MODE="restore" ;;
    --list) MODE="list" ;;
    --pin) MODE="pin" ;;
    --unpin) MODE="unpin" ;;
    --domain=*) DOMAIN="${arg#--domain=}" ;;
    --target=*) TARGET="${arg#--target=}" ;;
    --source=*) SOURCE="${arg#--source=}" ;;
    --backup-id=*) BACKUP_ID="${arg#--backup-id=}" ;;
    *) die "unknown arg: $arg" ;;
  esac
done

[ -z "$MODE" ] && MODE="backup"
[ -z "$DOMAIN" ] && die "--domain=<domain> required"

SRC_DIR="$REPO_ROOT/engineering-standards/$DOMAIN"
BACKUPS_DIR="$REPO_ROOT/tools/maintainer/project-standard-extractor/.local-backups/$DOMAIN"

# 路径穿越校验:domain 不得含 .. / 绝对路径 / 反斜杠
case "$DOMAIN" in
  *..*|/*|*\\*|*\ *) die "invalid --domain (forbidden chars): $DOMAIN" ;;
esac
case "$DOMAIN" in
  [0-9][0-9]-[a-z0-9-]*) ;;
  *) die "invalid --domain format: $DOMAIN" ;;
esac

validate_backup_id() {
  local id="$1"
  case "$id" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z) ;;
    *) die "invalid --backup-id format (expected YYYYMMDDTHHMMSSZ): $id" ;;
  esac
}

validate_manifest_file() {
  local manifest="$1"
  local schema="$REPO_ROOT/skills/project-standard-extractor/references/config/backup/manifest-schema.json"
  [ -f "$manifest" ] || die "manifest.json missing: $manifest"
  command -v python3 >/dev/null 2>&1 || die "python3 required for manifest validation"
  python3 - "$manifest" "$schema" <<'PY'
import json, sys
try:
    import jsonschema
except ImportError:
    print("python jsonschema required for manifest validation", file=sys.stderr)
    sys.exit(2)
manifest_path, schema_path = sys.argv[1], sys.argv[2]
with open(manifest_path, 'r', encoding='utf-8') as f:
    manifest = json.load(f)
with open(schema_path, 'r', encoding='utf-8') as f:
    schema = json.load(f)
jsonschema.validate(manifest, schema)
PY
}

validate_manifest_hash() {
  local manifest="$1"
  local hash_file="$manifest.sha256"
  [ -f "$hash_file" ] || die "manifest.json.sha256 missing: $hash_file"
  local expected
  local actual
  expected=$(awk '{print $1; exit}' "$hash_file" | tr -d '[:space:]')
  actual=$(sha256_cmd <"$manifest" | awk '{print $1}')
  [ -n "$expected" ] || die "manifest.json.sha256 empty: $hash_file"
  [ "$expected" = "$actual" ] || die "manifest.json.sha256 mismatch: $manifest"
}

restore_manifest_stats() {
  local manifest="$1"
  local expected_domain="$2"
  local expected_backup_id="$3"
  python3 - "$manifest" "$expected_domain" "$expected_backup_id" <<'PY'
import json, sys

manifest_path, expected_domain, expected_backup_id = sys.argv[1:4]
with open(manifest_path, 'r', encoding='utf-8') as f:
    manifest = json.load(f)

errors = []
if manifest.get("domain") != expected_domain:
    errors.append(f"domain mismatch: manifest={manifest.get('domain')} arg={expected_domain}")
if manifest.get("backup_id") != expected_backup_id:
    errors.append(f"backup_id mismatch: manifest={manifest.get('backup_id')} source={expected_backup_id}")

stats = manifest.get("stats") or {}
required = ["file_count", "byte_count", "sha256_fingerprint"]
missing = [key for key in required if key not in stats]
if missing:
    errors.append("stats missing: " + ",".join(missing))

if errors:
    print("; ".join(errors), file=sys.stderr)
    sys.exit(1)

print(f"{stats['file_count']}|{stats['byte_count']}|{stats['sha256_fingerprint']}")
PY
}

LOCK_DIR="$BACKUPS_DIR/.lock"
lock_acquired=0
acquire_lock() {
  mkdir -p "$BACKUPS_DIR"
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    lock_acquired=1
    printf '%s\n' "$$" > "$LOCK_DIR/pid"
  else
    die "domain lock held: $LOCK_DIR"
  fi
}
release_lock() {
  if [ "$lock_acquired" -eq 1 ]; then
    rm -f "$LOCK_DIR/pid"
    rmdir "$LOCK_DIR" 2>/dev/null || true
  fi
}
trap release_lock EXIT INT TERM

# ---------- mode dispatch ----------
case "$MODE" in
  dry-run)
    [ ! -d "$SRC_DIR" ] && die "source not found: $SRC_DIR"
    fp=$(compute_fingerprint "$SRC_DIR")
    fc=$(count_files "$SRC_DIR")
    bc=$(count_bytes "$SRC_DIR")
    cat <<EOF
{
  "mode": "dry-run",
  "domain": "$DOMAIN",
  "source": "$SRC_DIR",
  "sha256_fingerprint": "$fp",
  "file_count": $fc,
  "byte_count": $bc,
  "exclude_patterns": ["evidence/raw-*", "temp/", ".git"]
}
EOF
    ;;

  backup)
    [ -z "$TARGET" ] && die "--target=<backup_dir> required for backup mode"
    [ ! -d "$SRC_DIR" ] && die "source not found: $SRC_DIR"
    PAYLOAD_DIR="$TARGET/payload"
    mkdir -p "$PAYLOAD_DIR"

    # cp -a 跨平台保留 mode/timestamps;rsync 也可,但 cp -a 依赖更少
    # 用 rsync 排除模式更直观,这里用 find + cpio 兜底跨平台
    if command -v rsync >/dev/null 2>&1; then
      rsync -a \
        --exclude='evidence/raw-*' \
        --exclude='temp/' \
        --exclude='.git/' \
        "$SRC_DIR/" "$PAYLOAD_DIR/"
    else
      # fallback: 用 find + cpio
      (
        cd "$SRC_DIR"
        LC_ALL=C find . -type f \
          -not -path './evidence/raw-*' \
          -not -path './evidence/raw-*/*' \
          -not -path './temp' \
          -not -path './temp/*' \
          -not -path './.git' \
          -not -path './.git/*' \
          | cpio -pdm "$PAYLOAD_DIR" 2>/dev/null
      )
    fi

    fp=$(compute_fingerprint "$SRC_DIR")
    fc=$(count_files "$SRC_DIR")
    bc=$(count_bytes "$SRC_DIR")
    porcelain=$(git -C "$REPO_ROOT" status --porcelain --ignored=no "engineering-standards/$DOMAIN/" 2>/dev/null || true)

    cat <<EOF
{
  "mode": "backup",
  "domain": "$DOMAIN",
  "source": "$SRC_DIR",
  "target": "$TARGET",
  "sha256_fingerprint": "$fp",
  "file_count": $fc,
  "byte_count": $bc,
  "exclude_patterns": ["evidence/raw-*", "temp/", ".git"],
  "porcelain_at_backup": $(printf '%s' "$porcelain" | python3 -c 'import sys, json; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '""')
}
EOF
    ;;

  restore)
    [ -z "$SOURCE" ] && die "--source=<backup_dir> required for restore mode"
    [ ! -d "$SOURCE" ] && die "backup not found: $SOURCE"
    MANIFEST="$SOURCE/manifest.json"
    SOURCE_BACKUP_ID=$(basename "$SOURCE")
    validate_backup_id "$SOURCE_BACKUP_ID"
    validate_manifest_file "$MANIFEST"
    validate_manifest_hash "$MANIFEST"
    RESTORE_STATS=$(restore_manifest_stats "$MANIFEST" "$DOMAIN" "$SOURCE_BACKUP_ID") || die "restore manifest invalid: $MANIFEST"
    IFS='|' read -r EXPECTED_FILE_COUNT EXPECTED_BYTE_COUNT EXPECTED_FINGERPRINT <<EOF
$RESTORE_STATS
EOF
    if [ -d "$SOURCE/payload" ]; then
      RESTORE_SOURCE="$SOURCE/payload"
    else
      RESTORE_SOURCE="$SOURCE"
    fi

    src_file_count=$(count_files "$RESTORE_SOURCE")
    src_byte_count=$(count_bytes "$RESTORE_SOURCE")
    src_fingerprint=$(compute_fingerprint "$RESTORE_SOURCE")
    if [ "$src_file_count" -ne "$EXPECTED_FILE_COUNT" ] || \
       [ "$src_byte_count" -ne "$EXPECTED_BYTE_COUNT" ] || \
       [ "$src_fingerprint" != "$EXPECTED_FINGERPRINT" ]; then
      die "restore verify failed before copy: backup stats mismatch (files=$src_file_count/$EXPECTED_FILE_COUNT, bytes=$src_byte_count/$EXPECTED_BYTE_COUNT, sha256=$src_fingerprint/$EXPECTED_FINGERPRINT)"
    fi

    # 拷回前先 atomic rename 当前目录为 .pre-restore-<now>
    NOW=$(date -u +%Y%m%dT%H%M%SZ)
    PRE_RESTORE="$REPO_ROOT/engineering-standards/${DOMAIN}.pre-restore-$NOW"
    PRE_RESTORE_CREATED=0
    rollback_restore() {
      local reason="$1"
      rm -rf "$SRC_DIR"
      if [ "$PRE_RESTORE_CREATED" -eq 1 ] && [ -d "$PRE_RESTORE" ]; then
        mv "$PRE_RESTORE" "$SRC_DIR"
      fi
      die "$reason"
    }
    if [ -d "$SRC_DIR" ]; then
      mv "$SRC_DIR" "$PRE_RESTORE"
      PRE_RESTORE_CREATED=1
    fi
    mkdir -p "$SRC_DIR"

    if command -v rsync >/dev/null 2>&1; then
      if ! rsync -a \
        --exclude='manifest.json' \
        --exclude='manifest.json.sha256' \
        --exclude='failure.log' \
        "$RESTORE_SOURCE/" "$SRC_DIR/"; then
        rollback_restore "restore copy failed: rsync"
      fi
    else
      if ! (
        cd "$RESTORE_SOURCE"
        LC_ALL=C find . -type f \
          -not -name 'manifest.json' \
          -not -name 'manifest.json.sha256' \
          -not -name 'failure.log' \
          | cpio -pdm "$SRC_DIR" 2>/dev/null
      ); then
        rollback_restore "restore copy failed: cpio"
      fi
    fi

    fc_after=$(count_files "$SRC_DIR")
    bc_after=$(count_bytes "$SRC_DIR")
    fp_after=$(compute_fingerprint "$SRC_DIR")

    if [ "$fc_after" -ne "$EXPECTED_FILE_COUNT" ] || \
       [ "$bc_after" -ne "$EXPECTED_BYTE_COUNT" ] || \
       [ "$fp_after" != "$EXPECTED_FINGERPRINT" ]; then
      rollback_restore "restore verify failed after copy: stats mismatch (files=$fc_after/$EXPECTED_FILE_COUNT, bytes=$bc_after/$EXPECTED_BYTE_COUNT, sha256=$fp_after/$EXPECTED_FINGERPRINT)"
    fi

    if [ "$PRE_RESTORE_CREATED" -eq 1 ]; then
      rm -rf "$PRE_RESTORE"
    fi

    cat <<EOF
{
  "mode": "restore",
  "domain": "$DOMAIN",
  "source": "$SOURCE",
  "target": "$SRC_DIR",
  "file_count": $fc_after,
  "byte_count": $bc_after,
  "sha256_fingerprint": "$fp_after"
}
EOF
    ;;

  list)
    [ ! -d "$BACKUPS_DIR" ] && { echo '[]'; exit 0; }
    command -v python3 >/dev/null 2>&1 || die "python3 required for list mode"

    # 收集 backup_id 字典序;每个 backup_id 取 manifest.json 关键字段
    BACKUP_IDS=$(LC_ALL=C find "$BACKUPS_DIR" -mindepth 1 -maxdepth 1 -type d \
                   -not -name '.lock' -not -name '*.tmp' \
                   -exec basename {} \; 2>/dev/null | LC_ALL=C sort)

    python3 - "$BACKUPS_DIR" <<'PY'
import json, os, sys
backups_dir = sys.argv[1]
out = []
for name in sorted(os.listdir(backups_dir)):
    if name.startswith('.') or name.endswith('.tmp'):
        continue
    path = os.path.join(backups_dir, name)
    if not os.path.isdir(path):
        continue
    manifest = os.path.join(path, 'manifest.json')
    item = {
        "backup_id": name,
        "created_at": None,
        "git_head": None,
        "git_branch": None,
        "pin": False,
        "byte_count": None,
        "operator": None,
        "missing_manifest": True
    }
    if os.path.isfile(manifest):
        try:
            with open(manifest, 'r', encoding='utf-8') as f:
                m = json.load(f)
            item["missing_manifest"] = False
            item["created_at"] = m.get("created_at")
            gh = m.get("git_head") or {}
            item["git_head"] = gh.get("sha")
            item["git_branch"] = gh.get("branch")
            item["pin"] = bool(m.get("pin", False))
            stats = m.get("stats") or {}
            item["byte_count"] = stats.get("byte_count")
            item["operator"] = m.get("operator")
        except (json.JSONDecodeError, OSError):
            pass
    out.append(item)
print(json.dumps(out, ensure_ascii=False, indent=2))
PY
    ;;

  pin|unpin)
    [ -z "$BACKUP_ID" ] && die "--backup-id=<UTC-ts> required for $MODE mode"
    validate_backup_id "$BACKUP_ID"
    case "$BACKUP_ID" in
      *..*|/*|*\\*|*\ *) die "invalid --backup-id (forbidden chars): $BACKUP_ID" ;;
    esac
    acquire_lock
    BK_DIR="$BACKUPS_DIR/$BACKUP_ID"
    MANIFEST="$BK_DIR/manifest.json"
    [ ! -d "$BK_DIR" ] && die "backup not found: $BK_DIR"
    [ ! -f "$MANIFEST" ] && die "manifest.json missing: $MANIFEST"
    command -v python3 >/dev/null 2>&1 || die "python3 required for $MODE mode"

    PIN_VALUE="false"
    [ "$MODE" = "pin" ] && PIN_VALUE="true"

    # atomic 改写 manifest.json:tmp file → mv；写前写后都按 manifest schema 校验
    TMP="$MANIFEST.tmp.$$"
    SCHEMA_PATH="$REPO_ROOT/skills/project-standard-extractor/references/config/backup/manifest-schema.json"
    python3 - "$MANIFEST" "$TMP" "$PIN_VALUE" "$SCHEMA_PATH" <<'PY'
import json, sys
src, tmp, pin_val, schema_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
try:
    import jsonschema
except ImportError:
    print("python jsonschema required for manifest validation", file=sys.stderr)
    sys.exit(2)
with open(src, 'r', encoding='utf-8') as f:
    m = json.load(f)
with open(schema_path, 'r', encoding='utf-8') as f:
    schema = json.load(f)
# 老备份可能缺 pin；写前先按 false 归一化，再做 schema 校验。
if "pin" not in m:
    m["pin"] = False
jsonschema.validate(m, schema)
m["pin"] = (pin_val == "true")
jsonschema.validate(m, schema)
with open(tmp, 'w', encoding='utf-8') as f:
    json.dump(m, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
    mv "$TMP" "$MANIFEST"

    # 重新计算 manifest.json.sha256
    (cd "$BK_DIR" && sha256_cmd <manifest.json | awk '{print $1}' > manifest.json.sha256)

    cat <<EOF
{
  "mode": "$MODE",
  "domain": "$DOMAIN",
  "backup_id": "$BACKUP_ID",
  "pin": $PIN_VALUE
}
EOF
    ;;

  *)
    die "unknown mode: $MODE"
    ;;
esac
