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

SKILL="skills/project-standard-extractor/SKILL.md"
WORKFLOW="skills/project-standard-extractor/references/workflow.md"
INTAKE="skills/project-standard-extractor/references/agents/intake-and-scope.md"
GENERATION="skills/project-standard-extractor/references/agents/generation.md"
DIMENSION="skills/project-standard-extractor/references/agents/dimension-activator.md"
EXTERNAL_EVALS="docs/evals/project-standard-extractor"
LOCAL_EVALS="skills/project-standard-extractor/evals"
MAINTAINER_DIR="tools/maintainer/project-standard-extractor"

for path in \
  "$SKILL" \
  "$WORKFLOW" \
  "$INTAKE" \
  "$GENERATION" \
  "$DIMENSION" \
  "$EXTERNAL_EVALS/README.md" \
  "$EXTERNAL_EVALS/trigger-cases.md" \
  "$EXTERNAL_EVALS/failure-cases.md" \
  "$EXTERNAL_EVALS/expected-behavior.md" \
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

contains "$WORKFLOW" 'generation\(generation_profile: phase1-selected-batch\)' "workflow stable path uses phase1-selected-batch"
contains "$WORKFLOW" '不读取 `dimension-activator`，不要求 `activation-report`' "workflow excludes activation-report from stable path"
contains "$GENERATION" '`phase1-selected-batch`' "generation defines phase1-selected-batch profile"
contains "$GENERATION" '不要求 `activation-report`' "generation selected-batch does not require activation-report"
contains "$DIMENSION" 'baseline-dimensions\.yaml` 全集必须始终写入 `dimensions\[\]`' "dimension activator keeps baseline dimensions in dimensions[]"

contains "$EXTERNAL_EVALS/trigger-cases.md" 'generation_profile: phase1-selected-batch' "external trigger eval covers selected-batch profile"
contains "$EXTERNAL_EVALS/trigger-cases.md" '不要求 `activation-report`，不读取 `dimension-activator`' "external trigger eval blocks activation-report in selected-batch"
contains "$EXTERNAL_EVALS/dimension-framework/three-state-cases.md" 'baseline-only repair fallback 可生成最小 draft' "external eval covers baseline-only repair fallback"
contains "$EXTERNAL_EVALS/dimension-framework/three-state-cases.md" '不抛 `EMPTY_ACTIVATION_REPORT`' "baseline fallback does not throw EMPTY_ACTIVATION_REPORT"
contains "$EXTERNAL_EVALS/dimension-framework/three-state-cases.md" '不抛 `NO_DIMENSION_CAN_GENERATE`' "baseline fallback does not throw NO_DIMENSION_CAN_GENERATE"

contains "$INTAKE" 'maintainer_context: false' "intake schema defaults maintainer_context=false"
contains "$INTAKE" 'MAINTAINER_CONTEXT_REQUIRED' "intake maps missing maintainer context to MAINTAINER_CONTEXT_REQUIRED"
contains "$EXTERNAL_EVALS/failure-cases.md" 'MAINTAINER_CONTEXT_REQUIRED' "external failure eval covers maintainer context gate"

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
