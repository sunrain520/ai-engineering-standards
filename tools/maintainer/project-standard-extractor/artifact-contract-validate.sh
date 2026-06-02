#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"

if [[ -z "$REPO_ROOT" ]]; then
  echo "BLOCK repo-root: cannot resolve git repository root" >&2
  exit 2
fi

cd "$REPO_ROOT" || exit 2

passes=0
warnings=0
blocks=0

pass() {
  passes=$((passes + 1))
  printf 'PASS %s\n' "$1"
}

warn() {
  warnings=$((warnings + 1))
  printf 'WARN %s\n' "$1"
}

block() {
  blocks=$((blocks + 1))
  printf 'BLOCK %s\n' "$1"
}

require_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass "file exists: $path"
  else
    block "missing file: $path"
  fi
}

contains() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if grep -Eq "$pattern" "$path"; then
    pass "$label"
  else
    block "$label"
  fi
}

not_contains() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if grep -Eq "$pattern" "$path"; then
    block "$label"
  else
    pass "$label"
  fi
}

compare_lists() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if diff -u "$expected" "$actual" >/dev/null; then
    pass "$label"
  else
    printf 'Expected vs actual diff for %s:\n' "$label"
    diff -u "$expected" "$actual" || true
    block "$label"
  fi
}

front_matter_value() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm=1; next }
    in_fm && $0 == "---" { exit }
    in_fm {
      pattern="^" key ":[[:space:]]*"
      if ($0 ~ pattern) {
        sub(pattern, "")
        gsub(/^"/, "")
        gsub(/"$/, "")
        print
        exit
      }
    }
  ' "$file"
}

expected_indexable_for_doc_type() {
  case "$1" in
    project-profile|extraction-map|batch-plan|ai-context-pack|review-report|rule-state-decision)
      printf 'false\n'
      ;;
    *)
      printf 'true\n'
      ;;
  esac
}

is_contract_rule_status() {
  local status="$1"
  jq -e --arg status "$status" '.rule_statuses | index($status)' "$CONTRACT" >/dev/null
}

is_contract_recommended_action() {
  local action="$1"
  jq -e --arg action "$action" '.recommended_actions | index($action)' "$CONTRACT" >/dev/null
}

is_contract_owner_queue_action_for_status() {
  local status="$1"
  local action="$2"
  jq -e --arg status "$status" --arg action "$action" \
    '.owner_queue_action_by_status[$status] // [] | index($action)' "$CONTRACT" >/dev/null
}

is_high_risk_sub_domain() {
  local sub_domain="$1"
  [[ "$sub_domain" =~ (^|[-_])(security|auth|authentication|authorization|cryptography|crypto|permission|compliance|privacy|pii|payment|finance)([-_]|$) ]]
}

validate_markdown_contract() {
  local md="$1"
  if awk 'NR==1 && /^---$/ { found=1 } END { exit found ? 0 : 1 }' "$md"; then
    pass "markdown has front matter: $md"
  else
    block "markdown missing front matter: $md"
    return
  fi

  local doc_type
  doc_type="$(front_matter_value "$md" "doc_type")"
  if [[ -z "$doc_type" ]]; then
    block "markdown missing doc_type: $md"
  elif jq -e --arg dt "$doc_type" '.markdown_doc_types | index($dt)' "$CONTRACT" >/dev/null; then
    pass "markdown doc_type valid: $md"
  else
    block "markdown doc_type invalid: $md -> $doc_type"
  fi

  local index_format
  index_format="$(front_matter_value "$md" "index_format")"
  if [[ "$index_format" == "engineering-standards-md-v1" ]]; then
    pass "markdown index_format valid: $md"
  else
    block "markdown index_format invalid or missing: $md -> ${index_format:-<missing>}"
  fi

  local indexable
  indexable="$(front_matter_value "$md" "indexable")"
  if [[ "$indexable" != "true" && "$indexable" != "false" ]]; then
    block "markdown indexable invalid or missing: $md -> ${indexable:-<missing>}"
  elif [[ -n "$doc_type" ]]; then
    local expected_indexable
    expected_indexable="$(expected_indexable_for_doc_type "$doc_type")"
    if [[ "$indexable" == "$expected_indexable" ]]; then
      pass "markdown indexable matches doc_type: $md"
    else
      block "markdown indexable mismatch: $md doc_type=$doc_type indexable=$indexable expected=$expected_indexable"
    fi
  fi
}

validate_standard_rule_metadata() {
  local md="$1"
  local metadata_tmp="$2"
  local found=0

  while IFS=$'\t' read -r section_title metadata_line; do
    [[ -z "$section_title" ]] && continue
    found=1
    printf '%s\t%s\n' "$md" "$section_title" >> "$metadata_tmp/headings.tsv"

    if [[ -z "$metadata_line" || "$metadata_line" != "> level:"* ]]; then
      block "rule metadata missing inline blockquote: $md -> $section_title"
      continue
    fi

    local missing_field=0
    while IFS= read -r field; do
      if [[ "$metadata_line" == *"$field:"* ]]; then
        :
      else
        block "rule metadata missing field $field: $md -> $section_title"
        missing_field=1
      fi
    done < <(jq -r '.rule_required_fields[]' "$CONTRACT")

    if [[ "$missing_field" -eq 0 ]]; then
      pass "rule metadata required fields present: $md -> $section_title"
    fi

    local status
    status="$(printf '%s\n' "$metadata_line" | sed -n 's/.*status: \([^ ·]*\).*/\1/p')"
    if [[ -z "$status" ]]; then
      block "rule metadata status missing: $md -> $section_title"
    elif is_contract_rule_status "$status"; then
      pass "rule metadata status valid: $md -> $section_title"
    else
      block "rule metadata status invalid: $md -> $section_title -> $status"
    fi

    local recommended_action
    recommended_action="$(printf '%s\n' "$metadata_line" | sed -n 's/.*recommended_action: \([^ ·]*\).*/\1/p')"
    if [[ -z "$recommended_action" ]]; then
      block "rule metadata recommended_action missing: $md -> $section_title"
    elif is_contract_recommended_action "$recommended_action"; then
      pass "rule metadata recommended_action valid: $md -> $section_title"
    else
      block "rule metadata recommended_action invalid: $md -> $section_title -> $recommended_action"
    fi

    if [[ "$status" == "auto-active" ]]; then
      local sub_domain
      sub_domain="$(front_matter_value "$md" "sub_domain")"
      if is_high_risk_sub_domain "$sub_domain"; then
        block "AUTO_ACTIVE_HIGH_RISK_DOMAIN auto-active rule in high-risk sub_domain: $md -> $section_title -> $sub_domain"
      fi

      if [[ "$metadata_line" == *"authority_scope: this-repo"* && "$metadata_line" == *"upgrade_mode: auto-active"* ]]; then
        pass "auto-active metadata has authority and upgrade mode: $md -> $section_title"
      else
        block "auto-active metadata missing authority_scope/upgrade_mode: $md -> $section_title"
      fi
      if printf '%s\n' "$metadata_line" | grep -Eq 'deterministic_occurrence_count: ([2-9]|[1-9][0-9]+)([^0-9]|$)'; then
        pass "auto-active metadata has deterministic occurrence count: $md -> $section_title"
      else
        block "auto-active metadata missing deterministic occurrence count >= 2: $md -> $section_title"
      fi
    fi
  done < <(
    awk '
      /^#{2,3} (P0|P1|P2|FORBIDDEN) / {
        section=$0
        sub(/^#{2,3} /, "", section)
        metadata=""
        if ((getline line) > 0) {
          if (line == "") { (getline line) > 0 ? 1 : 1 }
          metadata=line
        }
        print section "\t" metadata
      }
    ' "$md"
  )

  if [[ "$found" -eq 1 ]]; then
    pass "standard rule headings scanned: $md"
  fi
}

section_exists_in_source_doc() {
  local domain_dir="$1"
  local source_doc="$2"
  local section_title="$3"
  local source_path="$domain_dir/$source_doc"
  [[ -f "$source_path" ]] || return 1
  grep -Fxq "## $section_title" "$source_path" || grep -Fxq "### $section_title" "$source_path"
}

collect_standard_headings_as_lineage_locators() {
  local locator_tmp="$1"
  if [[ -s "$locator_tmp/headings.tsv" ]]; then
    while IFS=$'\t' read -r source_path section_title; do
      [[ -z "$source_path" || -z "$section_title" ]] && continue
      printf '%s\t%s\tstandard\n' "$(basename "$source_path")" "$section_title" >> "$locator_tmp/derived-locators.tsv"
    done < "$locator_tmp/headings.tsv"
  fi
}

require_domain_file() {
  local domain_dir="$1"
  local relative_path="$2"
  if [[ -f "$domain_dir/$relative_path" ]]; then
    pass "required artifact exists: $domain_dir/$relative_path"
  else
    block "required artifact missing: $domain_dir/$relative_path"
  fi
}

require_domain_match() {
  local domain_dir="$1"
  local pattern="$2"
  local label="$3"
  if find "$domain_dir" -type f -path "$domain_dir/$pattern" -print -quit | grep -q .; then
    pass "$label: $domain_dir/$pattern"
  else
    block "$label missing: $domain_dir/$pattern"
  fi
}

validate_required_artifacts() {
  local domain_dir="$1"

  require_domain_file "$domain_dir" "overview.md"
  require_domain_file "$domain_dir" "ai-rules.md"
  require_domain_file "$domain_dir" "review-checklist.md"
  require_domain_file "$domain_dir" "pending-confirmation.md"
  require_domain_file "$domain_dir" "merge-suggestions.md"
  require_domain_file "$domain_dir" "conflicts.md"
  require_domain_file "$domain_dir" "lineage-ledger.json"
  require_domain_file "$domain_dir" "owner-decision-queue.json"

  if find "$domain_dir" -maxdepth 1 -type f \( -name 'standard-*.md' -o -name 'standard.md' \) -print -quit | grep -q .; then
    pass "required standard artifact exists: $domain_dir/standard-*.md"
  else
    block "required standard artifact missing: $domain_dir/standard-*.md"
  fi

  require_domain_match "$domain_dir" "temp/*-rules-index-candidate.json" "required rules-index candidate exists"
  require_domain_match "$domain_dir" "temp/*-llms-candidate.txt" "required llms candidate exists"
  require_domain_match "$domain_dir" "temp/*-ai-context-pack.md" "required ai-context-pack exists"
}

validate_activation_report_boundaries() {
  local domain_dir="$1"
  local has_phase1_marker=0
  if grep -RIl 'phase1-full-auto\|phase1-selected-batch' "$domain_dir/temp" >/dev/null 2>&1; then
    has_phase1_marker=1
  fi

  if find "$domain_dir" -path '*/temp/*activation-report.json' -print -quit | grep -q .; then
    if [[ "$has_phase1_marker" -eq 1 ]]; then
      block "PHASE1_ACTIVATION_REPORT_LEAK phase1 temp directory must not contain activation-report.json: $domain_dir"
    else
      pass "phase2 temp activation-report detected: $domain_dir"
    fi
  else
    pass "no temp activation-report leakage detected: $domain_dir"
  fi

  while IFS= read -r report; do
    case "$(basename "$report")" in
      dimension-activation-report.json)
        if jq -e '.schema == "activation-report.v1"' "$report" >/dev/null; then
          pass "phase2 persisted activation-report schema valid: $report"
        else
          block "phase2 persisted activation-report schema invalid: $report"
        fi
        ;;
      *)
        block "PHASE1_ACTIVATION_REPORT_LEAK activation-report must not be persisted under evidence/: $report"
        ;;
    esac
  done < <(find "$domain_dir" -path '*/evidence/*activation-report.json' -type f)
}

validate_rules_index_file() {
  local json_file="$1"
  local domain_dir="$2"
  local locator_tmp="$3"

  if jq -e '.index_format == "engineering-standards-rules-index-v1"' "$json_file" >/dev/null; then
    pass "rules-index index_format valid: $json_file"
  else
    block "rules-index index_format invalid: $json_file"
  fi

  if [[ "$json_file" == */temp/*-rules-index-candidate.json ]]; then
    if jq -e '.candidate == true' "$json_file" >/dev/null; then
      pass "rules-index candidate flag valid: $json_file"
    else
      block "rules-index candidate flag missing: $json_file"
    fi
    if jq -e 'has("activation_report_ref") or has("sections")' "$json_file" >/dev/null; then
      block "rules-index candidate uses legacy activation/sections shape: $json_file"
    else
      pass "rules-index candidate uses canonical rules[] shape: $json_file"
    fi
  elif jq -e '.candidate == true' "$json_file" >/dev/null 2>&1; then
    block "formal rules-index must not be candidate: $json_file"
  fi

  if grep -Eq '"(rule_id|anchor)"' "$json_file"; then
    block "rules-index contains forbidden rule_id/anchor: $json_file"
  else
    pass "rules-index has no rule_id or anchor: $json_file"
  fi

  if jq -e '.rules | type == "array"' "$json_file" >/dev/null; then
    pass "rules-index rules array present: $json_file"
  else
    block "rules-index rules array missing: $json_file"
    return
  fi

  if [[ "$json_file" == */temp/*-rules-index-candidate.json ]]; then
    while IFS=$'\t' read -r section_title level missing_fields tags_type tags_len; do
      if [[ "$missing_fields" != "-" ]]; then
        block "rules-index candidate entry missing required fields: $json_file -> ${section_title:-<missing>} -> $missing_fields"
      else
        pass "rules-index candidate required fields present: $json_file -> $section_title"
      fi

      if [[ "$tags_type" == "array" && "$tags_len" =~ ^[1-9][0-9]*$ ]]; then
        pass "rules-index candidate tags valid: $json_file -> $section_title"
      else
        block "rules-index candidate tags invalid: $json_file -> $section_title"
      fi

      if [[ -n "$level" && -n "$section_title" && "$section_title" == "$level "* ]]; then
        pass "rules-index candidate level matches section_title: $json_file -> $section_title"
      else
        block "rules-index candidate level mismatch: $json_file -> ${section_title:-<missing>} level=${level:-<missing>}"
      fi
    done < <(
      jq -r '
        .rules[]? as $rule
        | . as $root
        | ($root.rules_index_candidate_required_fields // []) as $noop
        | [
            ($rule.section_title // ""),
            ($rule.level // ""),
            ([
              "title",
              "domain",
              "sub_domain",
              "level",
              "status",
              "source_doc",
              "section_title",
              "evidence_doc",
              "authority_scope",
              "upgrade_mode",
              "tags"
            ] | map(
              . as $field
              | select(
                  (($rule | has($field)) | not)
                  or ($field != "tags" and (($rule[$field] | tostring) == ""))
                  or ($field == "tags" and (($rule.tags | type) != "array" or ($rule.tags | length) == 0))
                )
            ) | join(",") | if . == "" then "-" else . end),
            ($rule.tags | type),
            (($rule.tags // []) | length)
          ] | @tsv
      ' "$json_file"
    )
  fi

  while IFS=$'\t' read -r source_doc section_title status authority_scope upgrade_mode; do
    if [[ -z "$source_doc" || -z "$section_title" ]]; then
      block "rules-index entry missing source_doc or section_title: $json_file"
      continue
    fi

    printf '%s\t%s\trules-index\n' "$source_doc" "$section_title" >> "$locator_tmp/derived-locators.tsv"

    if [[ "$section_title" =~ $SECTION_TITLE_REGEX ]]; then
      pass "rules-index section_title format valid: $json_file -> $section_title"
    else
      block "rules-index section_title format invalid: $json_file -> $section_title"
    fi

    if is_contract_rule_status "$status"; then
      pass "rules-index status valid: $json_file -> $section_title"
    else
      block "rules-index status invalid: $json_file -> $section_title -> ${status:-<missing>}"
    fi

    if section_exists_in_source_doc "$domain_dir" "$source_doc" "$section_title"; then
      pass "rules-index section_title exists in source_doc: $json_file -> $section_title"
    else
      block "rules-index section_title missing from source_doc: $json_file -> ${source_doc}「${section_title}」"
    fi

    if [[ "$status" == "auto-active" ]]; then
      if [[ "$authority_scope" == "this-repo" && "$upgrade_mode" == "auto-active" ]]; then
        pass "rules-index auto-active authority fields valid: $json_file -> $section_title"
      else
        block "rules-index auto-active authority fields invalid: $json_file -> $section_title"
      fi
    fi
  done < <(jq -r '.rules[]? | [.source_doc, .section_title, .status, (.authority_scope // ""), (.upgrade_mode // "")] | @tsv' "$json_file")
}

collect_derived_markdown_locators() {
  local md="$1"
  local view_type="$2"
  local locator_tmp="$3"
  sed -n \
    -e 's/.*`\([^`「]*\)「\([^」]*\)」`.*/\1	\2/p' \
    -e 's/.*[[:space:]`]\([^`[:space:]「]*\.md\)「\([^」]*\)」.*/\1	\2/p' \
    "$md" | while IFS=$'\t' read -r source_doc section_title; do
    [[ -z "$source_doc" || -z "$section_title" ]] && continue
    if [[ "$section_title" =~ $SECTION_TITLE_REGEX ]]; then
      printf '%s\t%s\t%s\n' "$source_doc" "$section_title" "$view_type" >> "$locator_tmp/derived-locators.tsv"
    fi
  done
}

validate_owner_queue() {
  local domain_dir="$1"
  local owner_queue="$domain_dir/owner-decision-queue.json"

  if [[ ! -f "$owner_queue" ]]; then
    block "owner-decision-queue.json missing: $domain_dir"
    return
  fi

  if jq -e '.schema == "project-standard-extractor-owner-decision-queue.v1" and (.items | type == "array")' "$owner_queue" >/dev/null; then
    pass "owner decision queue schema valid: $owner_queue"
  else
    block "owner decision queue schema invalid: $owner_queue"
    return
  fi

  while IFS=$'\t' read -r locator current_status owner_queue_action has_rule_recommended_action evidence_count risk_tags_type has_blocking_reason requires_security_review; do
    if [[ "$has_rule_recommended_action" == "true" ]]; then
      block "owner queue must use owner_queue_action, not rule recommended_action: $owner_queue -> ${locator:-<missing>}"
    fi

    if [[ -z "$locator" || -z "$current_status" || -z "$owner_queue_action" ]]; then
      block "owner queue item missing locator/current_status/owner_queue_action: $owner_queue"
      continue
    fi

    if is_contract_rule_status "$current_status"; then
      pass "owner queue current_status valid: $owner_queue -> $locator"
    else
      block "owner queue current_status invalid: $owner_queue -> $locator -> $current_status"
    fi

    if is_contract_owner_queue_action_for_status "$current_status" "$owner_queue_action"; then
      pass "owner queue action valid for status: $owner_queue -> $locator"
    else
      block "owner queue action invalid for status: $owner_queue -> $locator -> $current_status/$owner_queue_action"
    fi

    if [[ "$evidence_count" =~ ^[1-9][0-9]*$ ]]; then
      pass "owner queue evidence_ids present: $owner_queue -> $locator"
    else
      block "owner queue evidence_ids missing: $owner_queue -> $locator"
    fi

    if [[ "$risk_tags_type" == "array" ]]; then
      pass "owner queue risk_tags array present: $owner_queue -> $locator"
    else
      block "owner queue risk_tags must be array: $owner_queue -> $locator"
    fi

    if [[ "$has_blocking_reason" == "true" ]]; then
      pass "owner queue blocking_reason field present: $owner_queue -> $locator"
    else
      block "owner queue blocking_reason field missing: $owner_queue -> $locator"
    fi

    if [[ "$requires_security_review" != "true" && "$requires_security_review" != "false" ]]; then
      block "owner queue requires_security_review must be boolean: $owner_queue -> $locator"
    fi
  done < <(
    jq -r '.items[]? | [
      (.locator // ""),
      (.current_status // ""),
      (.owner_queue_action // ""),
      (has("recommended_action") | tostring),
      ((.evidence_ids // []) | length),
      (.risk_tags | type),
      (has("blocking_reason") | tostring),
      (.requires_security_review | tostring)
    ] | @tsv' "$owner_queue"
  )
}

validate_lineage_ledger() {
  local domain_dir="$1"
  local locator_tmp="$2"
  local lineage="$domain_dir/lineage-ledger.json"

  collect_standard_headings_as_lineage_locators "$locator_tmp"

  if [[ ! -f "$lineage" ]]; then
    if [[ -s "$locator_tmp/derived-locators.tsv" ]]; then
      block "ORPHAN_RULE lineage-ledger.json missing while derived locators exist: $domain_dir"
    else
      warn "lineage-ledger.json not found and no derived locators detected: $domain_dir"
    fi
    return
  fi

  if jq -e '.schema == "project-standard-extractor-lineage-ledger.v1" and (.edges | type == "array")' "$lineage" >/dev/null; then
    pass "lineage ledger schema valid: $lineage"
  else
    block "lineage ledger schema invalid: $lineage"
    return
  fi

  while IFS=$'\t' read -r source_doc section_title derived_view_type missing_fields; do
    if [[ -n "$missing_fields" ]]; then
      block "LINEAGE_INCOMPLETE missing required edge field: $lineage -> ${source_doc}「${section_title}」/$derived_view_type -> $missing_fields"
    else
      pass "lineage required fields present: $lineage -> ${source_doc}「${section_title}」/$derived_view_type"
    fi
  done < <(
    jq -r '
      [
        "evidence_id",
        "source_doc",
        "section_title",
        "derived_view_type",
        "gate_result",
        "upgrade_mode",
        "deterministic_occurrence_count",
        "authority_scope",
        "last_evidence_confirmed_run"
      ] as $fields
      | .edges[]? as $edge
      | [
          ($edge.source_doc // ""),
          ($edge.section_title // ""),
          ($edge.derived_view_type // ""),
          ($fields | map(. as $field | select(($edge | has($field)) | not)) | join(","))
        ] | @tsv
    ' "$lineage"
  )

  while IFS=$'\t' read -r evidence_id source_doc section_title derived_view_type gate_result upgrade_mode occurrence_count authority_scope criteria_snapshot_type anti_pattern_result high_risk_domain; do
    if [[ -z "$evidence_id" || -z "$source_doc" || -z "$section_title" || -z "$derived_view_type" || -z "$gate_result" ]]; then
      block "LINEAGE_INCOMPLETE missing required edge field: $lineage -> ${source_doc}「${section_title}」/$derived_view_type"
      continue
    fi

    if [[ "$gate_result" == "auto-active" ]]; then
      if [[ "$upgrade_mode" != "auto-active" || "$authority_scope" != "this-repo" || "$criteria_snapshot_type" != "object" ]]; then
        block "AUTO_ACTIVE_LINEAGE_INCOMPLETE missing upgrade/authority/criteria snapshot: $lineage -> ${source_doc}「${section_title}」"
      elif [[ "$occurrence_count" =~ ^([2-9]|[1-9][0-9]+)$ ]]; then
        pass "auto-active lineage criteria complete: $lineage -> ${source_doc}「${section_title}」"
      else
        block "AUTO_ACTIVE_LINEAGE_INCOMPLETE missing deterministic occurrence count >= 2: $lineage -> ${source_doc}「${section_title}」"
      fi

      if [[ "$anti_pattern_result" == "not-hit" || "$anti_pattern_result" == "none" || "$anti_pattern_result" == "false" ]]; then
        pass "auto-active lineage anti-pattern result clear: $lineage -> ${source_doc}「${section_title}」"
      else
        block "AUTO_ACTIVE_ANTI_PATTERN_BLOCKED lineage shows anti-pattern hit: $lineage -> ${source_doc}「${section_title}」 -> ${anti_pattern_result:-<missing>}"
      fi

      if [[ "$high_risk_domain" == "true" ]]; then
        block "AUTO_ACTIVE_HIGH_RISK_DOMAIN lineage marks high-risk domain: $lineage -> ${source_doc}「${section_title}」"
      else
        pass "auto-active lineage high-risk result clear: $lineage -> ${source_doc}「${section_title}」"
      fi
    fi
  done < <(
    jq -r '.edges[]? | [
      (.evidence_id // ""),
      (.source_doc // ""),
      (.section_title // ""),
      (.derived_view_type // ""),
      (.gate_result // ""),
      (.upgrade_mode // ""),
      (.deterministic_occurrence_count // ""),
      (.authority_scope // ""),
      (.criteria_snapshot | type),
      (.criteria_snapshot.anti_pattern_blocklist // "none"),
      (.criteria_snapshot.high_risk_domain // false)
    ] | @tsv' "$lineage"
  )

  if [[ -s "$locator_tmp/derived-locators.tsv" ]]; then
    while IFS=$'\t' read -r source_doc section_title derived_view_type; do
      if jq -e --arg source "$source_doc" --arg section "$section_title" --arg view "$derived_view_type" \
        '.edges[]? | select(.source_doc == $source and .section_title == $section and .derived_view_type == $view)' "$lineage" >/dev/null; then
        pass "lineage covers derived locator: $derived_view_type -> ${source_doc}「${section_title}」"
      else
        block "ORPHAN_RULE missing lineage edge: $derived_view_type -> ${source_doc}「${section_title}」"
      fi
    done < <(sort -u "$locator_tmp/derived-locators.tsv")
  fi
}

CONTRACT="skills/project-standard-extractor/references/config/output-artifact-contract.json"
SECTION_TITLE_REGEX=$(jq -r '.locator_contract.section_title_regex // "^(P0|P1|P2|FORBIDDEN) .+"' "$CONTRACT")
FRONTMATTER="skills/project-standard-extractor/references/config/frontmatter-format.md"
OUTPUT_TARGETS="skills/project-standard-extractor/references/config/output-targets.md"
REVIEW_AGENT="skills/project-standard-extractor/references/agents/review-and-quality-gate.md"
MERGE_AGENT="skills/project-standard-extractor/references/agents/merge-coordinator.md"
RULES_INDEX_TEMPLATE="skills/project-standard-extractor/assets/rules-index-template.json"
LINEAGE_TEMPLATE="skills/project-standard-extractor/assets/lineage-ledger-template.json"
OWNER_QUEUE_TEMPLATE="skills/project-standard-extractor/assets/owner-decision-queue-template.json"
ANTI_PATTERN="skills/project-standard-extractor/references/config/anti-pattern-blocklist.yaml"

for path in \
  "$CONTRACT" \
  "$FRONTMATTER" \
  "$OUTPUT_TARGETS" \
  "$REVIEW_AGENT" \
  "$MERGE_AGENT" \
  "$RULES_INDEX_TEMPLATE" \
  "$LINEAGE_TEMPLATE" \
  "$OWNER_QUEUE_TEMPLATE" \
  "$ANTI_PATTERN"; do
  require_file "$path"
done

if ! command -v jq >/dev/null 2>&1; then
  block "jq is required for artifact contract validation"
  printf '\nSummary: %d pass, %d warn, %d block\n' "$passes" "$warnings" "$blocks"
  exit 1
fi

if jq -e '.schema == "project-standard-extractor-output-artifact-contract.v1"' "$CONTRACT" >/dev/null; then
  pass "artifact contract schema is v1"
else
  block "artifact contract schema is v1"
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

jq -r '.markdown_doc_types[]' "$CONTRACT" | sort > "$tmp_dir/contract-doc-types"
awk '
  /^## 3\. doc_type/ { section=1; next }
  section && /^```text$/ { code=1; next }
  section && code && /^```$/ { exit }
  section && code && NF { print }
' "$FRONTMATTER" | sort > "$tmp_dir/frontmatter-doc-types"
compare_lists "$tmp_dir/contract-doc-types" "$tmp_dir/frontmatter-doc-types" "doc_type enum matches contract"

jq -r '.rule_statuses[]' "$CONTRACT" | sort > "$tmp_dir/contract-rule-statuses"
awk '
  /^### 4\.2 / { section=1; next }
  section && /^#### 4\.2\.1/ { exit }
  section && /^\| `/ {
    value=$2
    gsub(/`/, "", value)
    if (value != "取值") print value
  }
' "$FRONTMATTER" | sort > "$tmp_dir/frontmatter-rule-statuses"
compare_lists "$tmp_dir/contract-rule-statuses" "$tmp_dir/frontmatter-rule-statuses" "rule status enum matches contract"

jq -r '.recommended_actions[]' "$CONTRACT" | sort > "$tmp_dir/contract-recommended-actions"
awk '
  /^### 4\.7 / { section=1; next }
  section && /^## / { exit }
  section && /^\| `/ {
    value=$2
    gsub(/`/, "", value)
    if (value != "取值") print value
  }
' "$FRONTMATTER" | sort > "$tmp_dir/frontmatter-recommended-actions"
compare_lists "$tmp_dir/contract-recommended-actions" "$tmp_dir/frontmatter-recommended-actions" "recommended_action enum matches contract"

while IFS= read -r field; do
  contains "$FRONTMATTER" "$field" "frontmatter documents rule field: $field"
done < <(jq -r '.rule_required_fields[]' "$CONTRACT")

contains "$OUTPUT_TARGETS" 'output-artifact-contract\.json' "output targets reference machine contract"
contains "$OUTPUT_TARGETS" 'lineage-ledger\.json' "output targets include lineage ledger"
contains "$OUTPUT_TARGETS" 'owner-decision-queue\.json' "output targets include owner decision queue"
contains "$OUTPUT_TARGETS" 'auto-active' "output targets include auto-active status"
contains "$OUTPUT_TARGETS" 'owner-confirmed-active' "output targets include owner-confirmed-active status"

contains "$REVIEW_AGENT" 'phase1-full-auto' "review agent has phase1-full-auto profile"
contains "$REVIEW_AGENT" 'phase1-not-applicable' "review agent marks activation gate not applicable for phase1"
contains "$REVIEW_AGENT" 'deterministic_occurrence_count' "review agent requires deterministic occurrence count"
contains "$REVIEW_AGENT" 'anti-pattern-blocklist\.yaml' "review agent references anti-pattern blocklist"

contains "$MERGE_AGENT" 'ACTIVATION_REPORT_MISSING_WITHOUT_PHASE1' "merge agent rejects missing activation report outside phase1"
contains "$MERGE_AGENT" '不得生成、复制、持久化 `activation-report\.json`' "merge agent blocks phase1 activation-report leakage"
contains "$MERGE_AGENT" 'target_state' "merge agent routes phase1 by target_state"
contains "$MERGE_AGENT" 'lineage-ledger\.json' "merge agent writes lineage ledger"
contains "$MERGE_AGENT" 'owner-decision-queue\.json' "merge agent writes owner decision queue"
contains "$MERGE_AGENT" 'stale-auto-active' "merge agent supports stale auto-active exit"
contains "$MERGE_AGENT" 'owner-rejected' "merge agent supports owner rejection exit"

not_contains "$RULES_INDEX_TEMPLATE" '"(rule_id|anchor)"' "rules-index template has no rule_id or anchor"
contains "$RULES_INDEX_TEMPLATE" '"section_title"' "rules-index template uses section_title locator"
contains "$RULES_INDEX_TEMPLATE" '"status"' "rules-index template includes status"
contains "$LINEAGE_TEMPLATE" '"deterministic_occurrence_count"' "lineage template includes deterministic occurrence count"
contains "$OWNER_QUEUE_TEMPLATE" '"current_status"' "owner queue template includes current_status"

validate_domain_dir() {
  local domain_dir="$1"
  if [[ ! -d "$domain_dir" ]]; then
    warn "domain directory not found, skipped generated artifact checks: $domain_dir"
    return
  fi

  local domain_tmp="$tmp_dir/domain-$(basename "$domain_dir")"
  mkdir -p "$domain_tmp"
  : > "$domain_tmp/headings.tsv"
  : > "$domain_tmp/derived-locators.tsv"

  validate_required_artifacts "$domain_dir"
  validate_activation_report_boundaries "$domain_dir"

  while IFS= read -r md; do
    validate_markdown_contract "$md"

    case "$(basename "$md")" in
      standard-*.md|standard.md)
        validate_standard_rule_metadata "$md" "$domain_tmp"
        ;;
      ai-rules.md)
        collect_derived_markdown_locators "$md" "ai-rules" "$domain_tmp"
        ;;
      review-checklist.md)
        collect_derived_markdown_locators "$md" "review-checklist" "$domain_tmp"
        ;;
      pending-confirmation.md)
        collect_derived_markdown_locators "$md" "pending" "$domain_tmp"
        ;;
      conflicts.md)
        collect_derived_markdown_locators "$md" "conflict" "$domain_tmp"
        ;;
    esac
  done < <(find "$domain_dir" -type f -name '*.md')

  while IFS= read -r json_file; do
    validate_rules_index_file "$json_file" "$domain_dir" "$domain_tmp"
  done < <(find "$domain_dir" -type f \( -name '*rules-index-candidate.json' -o -path '*/.index/rules-index.json' \))

  if find "$domain_dir" -type f -name '*rules-index-candidate.json' ! -path '*/temp/*' -print -quit | grep -q .; then
    block "candidate rules-index must stay under temp/: $domain_dir"
  else
    pass "candidate rules-index files stay under temp: $domain_dir"
  fi

  if find "$domain_dir" -type f -name '*llms-candidate.txt' ! -path '*/temp/*' -print -quit | grep -q .; then
    block "candidate llms files must stay under temp/: $domain_dir"
  else
    pass "candidate llms files stay under temp: $domain_dir"
  fi

  if [[ -f "$domain_dir/llms.txt" ]] && grep -Eq '^candidate:[[:space:]]*true|llms candidate' "$domain_dir/llms.txt"; then
    block "llms candidate must not overwrite formal llms.txt: $domain_dir/llms.txt"
  else
    pass "formal llms.txt is not a candidate overwrite: $domain_dir"
  fi

  validate_owner_queue "$domain_dir"
  validate_lineage_ledger "$domain_dir" "$domain_tmp"
}

if [[ $# -gt 0 ]]; then
  for domain_dir in "$@"; do
    validate_domain_dir "$domain_dir"
  done
else
  warn "no generated domain directory provided; ran source contract checks only"
fi

printf '\nSummary: %d pass, %d warn, %d block\n' "$passes" "$warnings" "$blocks"

if [[ "$blocks" -gt 0 ]]; then
  exit 1
fi
