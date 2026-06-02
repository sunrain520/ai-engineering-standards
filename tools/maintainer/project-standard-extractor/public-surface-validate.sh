#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"

if [[ -z "$REPO_ROOT" ]]; then
  echo "FAIL repo-root: cannot resolve git repository root" >&2
  exit 2
fi

cd "$REPO_ROOT" || exit 2

failures=0
passes=0
degraded=0

pass() {
  passes=$((passes + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf 'FAIL %s\n' "$1"
}

degrade() {
  degraded=$((degraded + 1))
  printf 'DEGRADED %s\n' "$1"
}

require_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass "file exists: $path"
  else
    fail "missing file: $path"
  fi
}

contains() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if grep -Eq "$pattern" "$path"; then
    pass "$label"
  else
    fail "$label"
  fi
}

not_contains_text() {
  local text="$1"
  local pattern="$2"
  local label="$3"
  if printf '%s\n' "$text" | grep -Eq "$pattern"; then
    fail "$label"
  else
    pass "$label"
  fi
}

not_contains_file() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if grep -Eq "$pattern" "$path"; then
    fail "$label"
  else
    pass "$label"
  fi
}

SKILL="skills/project-standard-extractor/SKILL.md"
WORKFLOW="skills/project-standard-extractor/references/workflow.md"
INTAKE="skills/project-standard-extractor/references/agents/intake-and-scope.md"
PLANNER="skills/project-standard-extractor/references/agents/profile-and-batch-planner.md"
FACTS="skills/project-standard-extractor/references/agents/facts-and-classification.md"
GENERATION="skills/project-standard-extractor/references/agents/generation.md"
REVIEW="skills/project-standard-extractor/references/agents/review-and-quality-gate.md"
MERGE="skills/project-standard-extractor/references/agents/merge-coordinator.md"
DIMENSION="skills/project-standard-extractor/references/agents/dimension-activator.md"
FRONTMATTER="skills/project-standard-extractor/references/config/frontmatter-format.md"
OUTPUT_TARGETS="skills/project-standard-extractor/references/config/output-targets.md"
ARTIFACT_CONTRACT="skills/project-standard-extractor/references/config/output-artifact-contract.json"
ANTI_PATTERN="skills/project-standard-extractor/references/config/anti-pattern-blocklist.yaml"
LINEAGE_TEMPLATE="skills/project-standard-extractor/assets/lineage-ledger-template.json"
OWNER_QUEUE_TEMPLATE="skills/project-standard-extractor/assets/owner-decision-queue-template.json"
RULES_INDEX_TEMPLATE="skills/project-standard-extractor/assets/rules-index-template.json"
EXTERNAL_EVALS="docs/evals/project-standard-extractor"
LOCAL_EVALS="skills/project-standard-extractor/evals"
MAINTAINER_DIR="tools/maintainer/project-standard-extractor"
ARTIFACT_VALIDATOR="$MAINTAINER_DIR/artifact-contract-validate.sh"
ARTIFACT_FIXTURES="$EXTERNAL_EVALS/fixtures/artifact-contract"

for path in \
  "$SKILL" \
    "$WORKFLOW" \
    "$INTAKE" \
    "$PLANNER" \
    "$FACTS" \
    "$GENERATION" \
    "$REVIEW" \
    "$MERGE" \
    "$DIMENSION" \
    "$FRONTMATTER" \
    "$OUTPUT_TARGETS" \
    "$ARTIFACT_CONTRACT" \
    "$ANTI_PATTERN" \
    "$LINEAGE_TEMPLATE" \
    "$OWNER_QUEUE_TEMPLATE" \
    "$RULES_INDEX_TEMPLATE" \
    "$ARTIFACT_VALIDATOR" \
    "$EXTERNAL_EVALS/README.md" \
    "$EXTERNAL_EVALS/trigger-cases.md" \
    "$EXTERNAL_EVALS/boundary-cases.md" \
    "$EXTERNAL_EVALS/failure-cases.md" \
    "$EXTERNAL_EVALS/expected-behavior.md" \
    "$EXTERNAL_EVALS/artifact-contract-cases.md" \
    "$ARTIFACT_FIXTURES/README.md" \
    "$ARTIFACT_FIXTURES/valid-phase1/standard-api.md" \
    "$ARTIFACT_FIXTURES/valid-phase1/owner-decision-queue.json" \
    "$ARTIFACT_FIXTURES/valid-phase1/temp/20260602-valid-phase1-rules-index-candidate.json" \
    "$ARTIFACT_FIXTURES/valid-phase2/evidence/dimension-activation-report.json" \
    "$ARTIFACT_FIXTURES/valid-phase2/temp/20260602-valid-phase2-activation-report.json" \
    "$ARTIFACT_FIXTURES/invalid-phase1-activation-leak/temp/20260602-invalid-phase1-activation-report.json" \
    "$EXTERNAL_EVALS/dimension-framework/three-state-cases.md" \
  "$LOCAL_EVALS/trigger-cases.md" \
  "$LOCAL_EVALS/failure-cases.md" \
  "$LOCAL_EVALS/expected-behavior.md" \
  "$LOCAL_EVALS/boundary-cases.md" \
  "$MAINTAINER_DIR/README.md"; do
  require_file "$path"
done

contains "$SKILL" '^x-external-evals-root: docs/evals/project-standard-extractor/$' "SKILL frontmatter points to external eval root"

for heading in \
  '## When To Use' \
  '## When Not To Use' \
  '## Inputs' \
  '## Workflow' \
  '## Outputs' \
  '## Safety Boundaries' \
  '## Failure Modes' \
  '## Maintainer References'; do
  contains "$SKILL" "^${heading}$" "SKILL required section: $heading"
done

input_contract="$(
  awk '
    /^## Inputs$/ { in_inputs=1; next }
    in_inputs && /^## / { exit }
    in_inputs && /^```yaml$/ { in_code=1; next }
    in_inputs && in_code && /^```$/ { exit }
    in_inputs && in_code { print }
  ' "$SKILL"
)"

stable_steps="$(
  awk '
    /^稳定公开路径：$/ { in_steps=1; next }
    in_steps && /^Phase 2 / { exit }
    in_steps { print }
  ' "$SKILL"
)"

if [[ -n "$input_contract" ]]; then
  pass "public Inputs code block extracted"
else
  fail "public Inputs code block extracted"
fi

if [[ -n "$stable_steps" ]]; then
  pass "stable public workflow steps extracted"
else
  fail "stable public workflow steps extracted"
fi

not_contains_text "$input_contract" '^[[:space:]]*(output_action|domain|restore_from|keep|full)[[:space:]]*:' "public Inputs do not expose destructive/internal fields"
not_contains_text "$stable_steps" '(output_action|restore_from|backup-manager|backup\.sh|extraction_mode=full)' "stable public workflow steps do not route to maintainer/destructive fields"
not_contains_text "$stable_steps" 'stop-for-batch-selection|未选择 batch 前不得|选择单个 batch 后才|只输出 `project-profile`、`extraction-map` 和 `batch-plan`' "stable public workflow does not stop for manual batch selection"

if command -v rg >/dev/null 2>&1; then
  stale_public_refs="$(
    rg -n '未选择 batch 前不得|选择单个 batch 后才|不得自动发布 active|自动运行只输出 draft|status: active|promote-to-active|draft-only' \
      "$SKILL" "$WORKFLOW" "$PLANNER" "$FACTS" "$GENERATION" "$REVIEW" "$MERGE" "$FRONTMATTER" "$OUTPUT_TARGETS" \
      "$EXTERNAL_EVALS" "$LOCAL_EVALS" 2>/dev/null || true
  )"
else
  stale_public_refs="$(
    grep -RInE '未选择 batch 前不得|选择单个 batch 后才|不得自动发布 active|自动运行只输出 draft|status: active|promote-to-active|draft-only' \
      "$SKILL" "$WORKFLOW" "$PLANNER" "$FACTS" "$GENERATION" "$REVIEW" "$MERGE" "$FRONTMATTER" "$OUTPUT_TARGETS" \
      "$EXTERNAL_EVALS" "$LOCAL_EVALS" 2>/dev/null || true
  )"
fi
if [[ -n "$stale_public_refs" ]]; then
  printf '%s\n' "$stale_public_refs"
  fail "stale manual-batch/draft-only/legacy-active public wording is absent"
else
  pass "stale manual-batch/draft-only/legacy-active public wording is absent"
fi

  contains "$SKILL" '默认 full-auto' "SKILL describes full-auto as default"
  contains "$SKILL" 'ordered_batch_queue' "SKILL mentions ordered_batch_queue"
  contains "$SKILL" 'auto-active' "SKILL exposes auto-active lifecycle"
  contains "$WORKFLOW" 'ordered_batch_queue' "workflow stable path builds ordered batch queue"
  contains "$WORKFLOW" 'loop\(each ready or pending-confirmation batch\)' "workflow loops ready and pending batches"
  contains "$WORKFLOW" '不读取 `dimension-activator`，不要求也不生成 `activation-report`' "workflow excludes activation-report from stable path"
  contains "$WORKFLOW" 'phase1 run 的 `temp/` 中出现 `activation-report\.json`，视为 validator BLOCK' "workflow blocks phase1 activation-report leakage"
  contains "$GENERATION" '`phase1-selected-batch`' "generation defines phase1-selected-batch profile"
  contains "$GENERATION" '不要求 `activation-report`' "generation selected-batch does not require activation-report"
  contains "$PLANNER" '`ready` 和 `pending-confirmation` 均进入 `ordered_batch_queue`' "planner queues ready and pending-confirmation batches"
  contains "$PLANNER" '`coverage_report`' "planner outputs coverage_report"
  contains "$FACTS" '`pending-confirmation` 仅允许在 full-auto low-confidence worker' "facts allows pending batch in full-auto low-confidence worker"
  contains "$REVIEW" '`review_profile == phase1-full-auto`' "review has phase1-full-auto self-check"
  contains "$REVIEW" 'Gate B 未执行' "review skips Gate B in phase1"
  contains "$REVIEW" 'deterministic_occurrence_count' "review requires deterministic occurrence count for auto-active"
  contains "$REVIEW" 'anti-pattern-blocklist\.yaml' "review references anti-pattern blocklist"
  contains "$MERGE" '直接按 `quality_gate_decisions\[\]\.target_state` 写入' "merge phase1 routes by target_state"
  contains "$MERGE" '不得生成、复制、持久化 `activation-report\.json`' "merge blocks phase1 activation-report generation"
  contains "$MERGE" 'lineage-ledger\.json' "merge writes lineage ledger"
  contains "$MERGE" 'owner-decision-queue\.json' "merge writes owner decision queue"
  contains "$MERGE" 'stale-auto-active' "merge supports stale auto-active"
  contains "$MERGE" 'owner-rejected' "merge supports owner-rejected"
  contains "$FRONTMATTER" '`auto-active`' "frontmatter defines auto-active status"
  contains "$FRONTMATTER" '`owner-confirmed-active`' "frontmatter defines owner-confirmed-active status"
  contains "$FRONTMATTER" '`stale-auto-active`' "frontmatter defines stale-auto-active status"
  contains "$FRONTMATTER" '`owner-rejected`' "frontmatter defines owner-rejected status"
  contains "$FRONTMATTER" '`deterministic_occurrence_count`' "frontmatter defines deterministic occurrence count"
  contains "$FRONTMATTER" '`authority_scope`' "frontmatter defines authority_scope"
  contains "$FRONTMATTER" '`upgrade_mode`' "frontmatter defines upgrade_mode"
  contains "$OUTPUT_TARGETS" 'AI 默认执行路径只加载 `status ∈ \{auto-active, owner-confirmed-active\}`' "output targets define AI executable statuses"
  contains "$DIMENSION" 'baseline-dimensions\.yaml` 全集必须始终写入 `dimensions\[\]`' "dimension activator keeps baseline dimensions in dimensions[]"

  contains "$EXTERNAL_EVALS/trigger-cases.md" 'ordered_batch_queue' "external trigger eval covers ordered queue"
  contains "$EXTERNAL_EVALS/trigger-cases.md" 'full-auto' "external trigger eval covers full-auto default"
  contains "$EXTERNAL_EVALS/trigger-cases.md" 'generation_profile: phase1-selected-batch' "external trigger eval covers selected-batch profile"
  contains "$EXTERNAL_EVALS/trigger-cases.md" '不要求 `activation-report`，不读取 `dimension-activator`' "external trigger eval blocks activation-report in selected-batch"
  contains "$EXTERNAL_EVALS/expected-behavior.md" 'AE-17' "expected behavior covers AE-17 auto-active gate"
  contains "$EXTERNAL_EVALS/expected-behavior.md" 'AE-18' "expected behavior covers AE-18 owner rejection/stale exit"
contains "$EXTERNAL_EVALS/failure-cases.md" 'AUTO_ACTIVE_ANTI_PATTERN_BLOCKED' "failure eval covers anti-pattern blocked auto-active"
contains "$EXTERNAL_EVALS/failure-cases.md" 'AUTO_ACTIVE_HIGH_RISK_DOMAIN' "failure eval covers high-risk domain auto-active block"
contains "$EXTERNAL_EVALS/artifact-contract-cases.md" 'LINEAGE_INCOMPLETE' "artifact contract eval covers incomplete lineage"
contains "$EXTERNAL_EVALS/artifact-contract-cases.md" 'PHASE1_ACTIVATION_REPORT_LEAK' "artifact contract eval covers phase1 activation-report leak"
contains "$EXTERNAL_EVALS/artifact-contract-cases.md" 'owner_queue_action' "artifact contract eval covers owner_queue_action"
contains "$EXTERNAL_EVALS/artifact-contract-cases.md" 'rules\[\]' "artifact contract eval covers canonical rules[] candidate"
contains "$EXTERNAL_EVALS/artifact-contract-cases.md" 'evidence/dimension-activation-report\.json' "artifact contract eval covers phase2 persisted activation report"
contains "$EXTERNAL_EVALS/artifact-contract-cases.md" 'llms-candidate\.txt' "artifact contract eval covers llms candidate boundary"
for ae in AE-01 AE-02 AE-03 AE-04 AE-05 AE-06 AE-07 AE-08 AE-09 AE-10 AE-11 AE-12 AE-13 AE-14 AE-15 AE-16 AE-17 AE-18; do
  contains "$EXTERNAL_EVALS/README.md" "$ae" "external eval README maps $ae"
done
contains "$EXTERNAL_EVALS/README.md" "$ARTIFACT_FIXTURES/valid-phase1 $ARTIFACT_FIXTURES/valid-phase2" "external eval README documents passing artifact fixtures"
contains "$EXTERNAL_EVALS/README.md" "$ARTIFACT_FIXTURES/invalid-phase1-activation-leak" "external eval README documents failing artifact fixture"
contains "$ARTIFACT_FIXTURES/README.md" 'PHASE1_ACTIVATION_REPORT_LEAK' "artifact fixture README documents required negative signal"
contains "$EXTERNAL_EVALS/dimension-framework/three-state-cases.md" 'baseline-only repair fallback 可生成最小 draft' "external eval covers baseline-only repair fallback"
contains "$EXTERNAL_EVALS/dimension-framework/three-state-cases.md" '不抛 `EMPTY_ACTIVATION_REPORT`' "baseline fallback does not throw EMPTY_ACTIVATION_REPORT"
contains "$EXTERNAL_EVALS/dimension-framework/three-state-cases.md" '不抛 `NO_DIMENSION_CAN_GENERATE`' "baseline fallback does not throw NO_DIMENSION_CAN_GENERATE"

contains "$INTAKE" 'maintainer_context: false' "intake schema defaults maintainer_context=false"
contains "$INTAKE" 'MAINTAINER_CONTEXT_REQUIRED' "intake maps missing maintainer context to MAINTAINER_CONTEXT_REQUIRED"
contains "$EXTERNAL_EVALS/failure-cases.md" 'MAINTAINER_CONTEXT_REQUIRED' "external failure eval covers maintainer context gate"

contains "$ARTIFACT_CONTRACT" '"owner_queue_actions"' "artifact contract defines owner queue action enum"
contains "$ARTIFACT_CONTRACT" '"owner_queue_action_by_status"' "artifact contract maps owner queue actions by status"
contains "$ARTIFACT_CONTRACT" '"rules_index_candidate_required_fields"' "artifact contract defines rules-index candidate required fields"
contains "$OWNER_QUEUE_TEMPLATE" '"owner_queue_action"' "owner queue template uses owner_queue_action"
not_contains_file "$OWNER_QUEUE_TEMPLATE" '"recommended_action"' "owner queue template does not use rule recommended_action"
contains "$RULES_INDEX_TEMPLATE" '"rules"' "rules-index template uses canonical rules array"
not_contains_file "$RULES_INDEX_TEMPLATE" '"(sections|activation_report_ref|rule_id|anchor)"' "rules-index template has no legacy candidate fields"
contains "$GENERATION" '`rules-index-candidate\.json\.rules\[\]`' "generation documents canonical rules-index candidate array"
contains "$GENERATION" 'Phase 1 不含 activation 字段' "generation blocks phase1 activation fields in candidate index"
contains "$REVIEW" 'Phase 1.*不得.*activation map|Phase 1.*不.*activation-report' "review keeps phase1 activation boundary"
contains "$MERGE" 'overview\.md` §9' "merge writes overview.md section 9"
contains "$MERGE" 'activation_report_path' "merge summary records persisted activation report path"
contains "$OUTPUT_TARGETS" 'owner_queue_action' "output targets distinguish owner queue action from rule recommended_action"

for file in "$GENERATION" "$REVIEW" "$MERGE" "$OUTPUT_TARGETS" "$EXTERNAL_EVALS/README.md" "$EXTERNAL_EVALS/artifact-contract-cases.md"; do
  not_contains_file "$file" 'standard-overview|overview-\{domain\}|merge-to-active|confirm-pending|review-owner-rejected' "stale artifact/status wording absent: $file"
done

contains "$EXTERNAL_EVALS/README.md" '完整 eval source-of-truth' "external eval README declares source-of-truth"
for file in "$LOCAL_EVALS"/*.md; do
  contains "$file" 'package-local smoke subset only' "local eval declares smoke subset: $file"
  contains "$file" 'docs/evals/project-standard-extractor/' "local eval points to external source-of-truth: $file"
done

if [[ -e "skills/project-standard-extractor/scripts/backup.sh" || -e "skills/project-standard-extractor/scripts/force-rebuild-validate.sh" ]]; then
  fail "old skill-local maintainer scripts are absent"
else
  pass "old skill-local maintainer scripts are absent"
fi

if command -v rg >/dev/null 2>&1; then
  old_refs="$(
    rg -n 'skills/project-standard-extractor/scripts/(backup|force-rebuild-validate)\.sh|scripts/(backup|force-rebuild-validate)\.sh' \
      skills/project-standard-extractor "$EXTERNAL_EVALS" "$MAINTAINER_DIR" 2>/dev/null \
      | grep -v 'public-surface-validate\.sh' || true
  )"
else
  old_refs="$(
    grep -RInE 'skills/project-standard-extractor/scripts/(backup|force-rebuild-validate)\.sh|scripts/(backup|force-rebuild-validate)\.sh' \
      skills/project-standard-extractor "$EXTERNAL_EVALS" "$MAINTAINER_DIR" 2>/dev/null \
      | grep -v 'public-surface-validate\.sh' || true
  )"
fi
if [[ -n "$old_refs" ]]; then
  printf '%s\n' "$old_refs"
  fail "old skill-local maintainer script references are absent from active package/eval/maintainer docs"
else
  pass "old skill-local maintainer script references are absent from active package/eval/maintainer docs"
fi

if [[ -f "package_skill.py" || -f "quick_validate.py" ]]; then
  pass "canonical package validation tooling is present"
else
  degrade "canonical package validation tooling unavailable: package_skill.py / quick_validate.py not found"
fi

printf '\nSummary: %d pass, %d degraded, %d fail\n' "$passes" "$degraded" "$failures"

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
