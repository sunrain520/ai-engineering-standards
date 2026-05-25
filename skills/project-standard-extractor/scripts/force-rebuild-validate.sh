#!/usr/bin/env bash
# project-standard-extractor force-rebuild 确定性校验脚本
# 由 U24 Step 10 调用,4 项校验全部通过 → success path;任一失败 → backup-manager 触发 atomic rollback
#
# 用法:
#   scripts/force-rebuild-validate.sh --domain=<domain> --backup-dir=<backup_dir>
#
# 输出: stdout JSON
#   { "valid": true,  "checks": { ... } }            # 全过
#   { "valid": false, "checks": { ... }, "failure": { "check": "char_ratio", "expected": ">=0.6", "actual": "0.42" } }  # 任一不过
#
# 退出码: 0=valid, 1=invalid, 2=runtime error
#
# 4 项校验(顺序执行,任一失败立即退出):
#   (a) 字符数比对: 新产物 standard*.md 总字符 / 备份同名文件总字符 ≥ 0.6
#   (b) schema 校验: evidence/dimension-activation-report.json 通过 ajv (若 ajv 不可用,降级到 python jsonschema)
#   (c) 非空规则节: 至少一个 standard*.md 含 inline blockquote 元数据 (grep '^> level:')
#   (d) Quality Gate: review 输出 quality_gate_decisions: 段内 status: blocked/conflict 0 命中

set -euo pipefail

die() { echo "ERR: $*" >&2; exit 2; }
fail() {
  local check="$1"
  local expected="$2"
  local actual="$3"
  cat <<EOF
{
  "valid": false,
  "checks": $CHECKS_JSON,
  "failure": {
    "check": "$check",
    "expected": "$expected",
    "actual": "$actual"
  }
}
EOF
  exit 1
}

DOMAIN=""
BACKUP_DIR=""

for arg in "$@"; do
  case "$arg" in
    --domain=*) DOMAIN="${arg#--domain=}" ;;
    --backup-dir=*) BACKUP_DIR="${arg#--backup-dir=}" ;;
    *) die "unknown arg: $arg" ;;
  esac
done

[ -z "$DOMAIN" ] && die "--domain=<domain> required"
[ -z "$BACKUP_DIR" ] && die "--backup-dir=<backup_dir> required"

REPO_ROOT="$(pwd)"
NEW_DIR="$REPO_ROOT/engineering-standards/$DOMAIN"

[ ! -d "$NEW_DIR" ] && die "new dir not found: $NEW_DIR"
[ ! -d "$BACKUP_DIR" ] && die "backup dir not found: $BACKUP_DIR"

# 累计 checks 详情
CHECKS_JSON='{}'

# ---------- check (a) 字符数比对 ----------
count_chars() {
  local dir="$1"
  local total=0
  while IFS= read -r f; do
    local sz
    sz=$(wc -c <"$f" 2>/dev/null | tr -d ' ' || echo 0)
    total=$((total + sz))
  done < <(LC_ALL=C find "$dir" -type f \( -name 'standard-*.md' -o -name 'standard*.md' \) 2>/dev/null | LC_ALL=C sort)
  echo "$total"
}

OLD_DIR="$BACKUP_DIR"
if [ -d "$BACKUP_DIR/payload" ]; then
  OLD_DIR="$BACKUP_DIR/payload"
fi

NEW_CHARS=$(count_chars "$NEW_DIR")
OLD_CHARS=$(count_chars "$OLD_DIR")

# 计算比率: NEW/OLD; OLD=0 时跳过(全新 domain 首次重生)
if [ "$OLD_CHARS" -gt 0 ]; then
  # bash 不支持浮点,用整数比例: ratio = NEW * 100 / OLD,要求 ≥ 60
  RATIO=$((NEW_CHARS * 100 / OLD_CHARS))
  if [ "$RATIO" -lt 60 ]; then
    CHECKS_JSON="{\"a_char_ratio\": {\"new_chars\": $NEW_CHARS, \"old_chars\": $OLD_CHARS, \"old_dir\": \"$OLD_DIR\", \"ratio_percent\": $RATIO}}"
    fail "char_ratio" ">=60" "${RATIO}%"
  fi
  CHECK_A="{\"new_chars\": $NEW_CHARS, \"old_chars\": $OLD_CHARS, \"old_dir\": \"$OLD_DIR\", \"ratio_percent\": $RATIO, \"pass\": true}"
else
  CHECK_A="{\"new_chars\": $NEW_CHARS, \"old_chars\": 0, \"old_dir\": \"$OLD_DIR\", \"ratio_percent\": null, \"pass\": true, \"note\": \"first-rebuild-skip\"}"
fi

# ---------- check (b) activation-report.json schema valid ----------
REPORT_JSON="$NEW_DIR/evidence/dimension-activation-report.json"
SCHEMA_JSON="$REPO_ROOT/skills/project-standard-extractor/references/config/dimension-framework/activation-report-schema.json"

if [ ! -f "$REPORT_JSON" ]; then
  CHECKS_JSON="{\"a_char_ratio\": $CHECK_A, \"b_activation_report_schema\": {\"path\": \"$REPORT_JSON\", \"exists\": false}}"
  fail "activation_report_schema" "exists" "missing"
fi

CHECK_B='{"path": "'"$REPORT_JSON"'", "exists": true, "validated_by": null, "pass": true}'

if command -v ajv >/dev/null 2>&1 && [ -f "$SCHEMA_JSON" ]; then
  if ajv validate -s "$SCHEMA_JSON" -d "$REPORT_JSON" >/dev/null 2>&1; then
    CHECK_B='{"path": "'"$REPORT_JSON"'", "exists": true, "validated_by": "ajv", "pass": true}'
  else
    CHECKS_JSON="{\"a_char_ratio\": $CHECK_A, \"b_activation_report_schema\": {\"path\": \"$REPORT_JSON\", \"exists\": true, \"validated_by\": \"ajv\", \"pass\": false}}"
    fail "activation_report_schema" "ajv valid" "ajv reject"
  fi
elif command -v python3 >/dev/null 2>&1; then
  # python jsonschema 降级；缺少 schema 校验器时视为 runtime error，不允许退化为 JSON parse success
  if python3 -c "
import json, sys
try:
    import jsonschema
except ImportError:
    print('python jsonschema not installed', file=sys.stderr); sys.exit(2)
try:
    with open('$REPORT_JSON') as f:
        report = json.load(f)
except Exception as e:
    print(f'parse error: {e}', file=sys.stderr); sys.exit(1)
try:
    if '$SCHEMA_JSON' and __import__('os').path.isfile('$SCHEMA_JSON'):
        with open('$SCHEMA_JSON') as f:
            schema = json.load(f)
        jsonschema.validate(report, schema)
    sys.exit(0)
except jsonschema.ValidationError as e:
    print(f'schema error: {e.message}', file=sys.stderr); sys.exit(1)
" 2>/dev/null; then
    CHECK_B='{"path": "'"$REPORT_JSON"'", "exists": true, "validated_by": "python-jsonschema", "pass": true}'
  else
    rc=$?
    if [ "$rc" -eq 2 ]; then
      die "activation report schema validator unavailable (install ajv or python jsonschema)"
    else
      CHECKS_JSON="{\"a_char_ratio\": $CHECK_A, \"b_activation_report_schema\": {\"path\": \"$REPORT_JSON\", \"validated_by\": \"python-jsonschema\", \"pass\": false}}"
      fail "activation_report_schema" "schema valid" "schema reject"
    fi
  fi
else
  die "activation report schema validator unavailable (install ajv or python3 jsonschema)"
fi

# ---------- check (c) 非空规则节 ----------
RULE_HITS=0
while IFS= read -r f; do
  if grep -q '^> level:' "$f" 2>/dev/null; then
    RULE_HITS=$((RULE_HITS + 1))
  fi
done < <(LC_ALL=C find "$NEW_DIR" -type f \( -name 'standard-*.md' -o -name 'standard*.md' \) 2>/dev/null | LC_ALL=C sort)

if [ "$RULE_HITS" -eq 0 ]; then
  CHECKS_JSON="{\"a_char_ratio\": $CHECK_A, \"b_activation_report_schema\": $CHECK_B, \"c_non_empty_rules\": {\"files_with_rules\": 0, \"pass\": false}}"
  fail "non_empty_rules" ">=1 standard file with > level:" "0 files matched"
fi
CHECK_C="{\"files_with_rules\": $RULE_HITS, \"pass\": true}"

# ---------- check (d) Quality Gate grep ----------
# 找 review summary, 检查 quality_gate_decisions: 段内 status: blocked/conflict 命中数
RUN_ID_HINT=$(basename "$BACKUP_DIR")
REVIEW_DIR="$NEW_DIR/temp"
REVIEW_FILE=""
if [ -d "$REVIEW_DIR" ]; then
  REVIEW_FILE=$(LC_ALL=C find "$REVIEW_DIR" -type f -name '*review-summary*.md' 2>/dev/null | LC_ALL=C sort -r | head -n 1)
fi

if [ -z "$REVIEW_FILE" ] || [ ! -f "$REVIEW_FILE" ]; then
  CHECKS_JSON="{\"a_char_ratio\": $CHECK_A, \"b_activation_report_schema\": $CHECK_B, \"c_non_empty_rules\": $CHECK_C, \"d_quality_gate\": {\"review_file\": null, \"pass\": false}}"
  fail "quality_gate" "review-summary.md exists" "missing"
fi

# grep quality_gate_decisions: 段
if ! grep -q 'quality_gate_decisions:' "$REVIEW_FILE"; then
  CHECKS_JSON="{\"a_char_ratio\": $CHECK_A, \"b_activation_report_schema\": $CHECK_B, \"c_non_empty_rules\": $CHECK_C, \"d_quality_gate\": {\"review_file\": \"$REVIEW_FILE\", \"has_section\": false, \"pass\": false}}"
  fail "quality_gate" "quality_gate_decisions: section" "section missing"
fi

# count blocked/conflict (status: blocked / status: conflict)
BLOCKED_COUNT=$(grep -cE '^[[:space:]]*status:[[:space:]]*(blocked|conflict)' "$REVIEW_FILE" || true)
BLOCKED_COUNT=${BLOCKED_COUNT:-0}
if [ "$BLOCKED_COUNT" -gt 0 ]; then
  CHECKS_JSON="{\"a_char_ratio\": $CHECK_A, \"b_activation_report_schema\": $CHECK_B, \"c_non_empty_rules\": $CHECK_C, \"d_quality_gate\": {\"review_file\": \"$REVIEW_FILE\", \"blocked_or_conflict_count\": $BLOCKED_COUNT, \"pass\": false}}"
  fail "quality_gate" "0 blocked/conflict" "$BLOCKED_COUNT hits"
fi
CHECK_D="{\"review_file\": \"$REVIEW_FILE\", \"blocked_or_conflict_count\": 0, \"pass\": true}"

# ---------- 全部通过 ----------
CHECKS_JSON="{\"a_char_ratio\": $CHECK_A, \"b_activation_report_schema\": $CHECK_B, \"c_non_empty_rules\": $CHECK_C, \"d_quality_gate\": $CHECK_D}"
cat <<EOF
{
  "valid": true,
  "checks": $CHECKS_JSON
}
EOF
exit 0
