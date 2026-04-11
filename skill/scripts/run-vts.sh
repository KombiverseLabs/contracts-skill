#!/usr/bin/env bash
set -euo pipefail

# Run verification tests (VTs) defined in CONTRACT.yaml files and report results.
# Output format is compatible with Agent Arena's metrics.vt_results.
#
# Requires: jq (for safe JSON output)
#
# Usage:
#   ./run-vts.sh --path . --output json
#   ./run-vts.sh --path . --module auth --update-yaml

ROOT="."
OUTPUT="console"
MODULE=""
UPDATE_YAML=false
REGISTRY=""

usage() {
  cat <<'EOF'
Usage:
  ./run-vts.sh [--path .] [--module name] [--registry path] [--update-yaml] [--output console|json|cvr]

Options:
  --path         Project root (default: .)
  --module       Run VTs only for a specific module
  --registry     Path to registry.yaml
  --update-yaml  Update CONTRACT.yaml status after running VTs
  --output       Output format: console (default), json, or cvr (Contract Verification Report)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) ROOT="$2"; shift 2 ;;
    --module) MODULE="$2"; shift 2 ;;
    --registry) REGISTRY="$2"; shift 2 ;;
    --update-yaml) UPDATE_YAML=true; shift ;;
    --output) OUTPUT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

ROOT_ABS="$(cd "$ROOT" && pwd)"
VT_TIMEOUT=120  # seconds per VT command

# Verify jq is available (required for safe JSON output)
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not found in PATH. Install jq first." >&2
  exit 1
fi

# Find CONTRACT.yaml files
find_yamls() {
  local reg="${REGISTRY:-$ROOT_ABS/.contracts/registry.yaml}"
  if [[ -f "$reg" ]]; then
    # Extract paths from registry
    grep -oP 'path:\s*"\K[^"]+' "$reg" 2>/dev/null | while read -r p; do
      local yf="$ROOT_ABS/$p/CONTRACT.yaml"
      [[ -f "$yf" ]] && echo "$yf"
    done
  fi

  # Fallback: recursive scan
  find "$ROOT_ABS" -name 'CONTRACT.yaml' \
    -not -path '*/node_modules/*' \
    -not -path '*/.git/*' \
    -not -path '*/dist/*' \
    -not -path '*/build/*' 2>/dev/null || true
}

# Extract a yaml field value after a VT id marker
get_vt_field() {
  local yaml_content="$1" vt_id="$2" field="$3"
  echo "$yaml_content" | awk -v id="$vt_id" -v fld="$field" '
    /- id:/ { current_id = $0; gsub(/.*"/, "", current_id); gsub(/".*/, "", current_id) }
    current_id == id && $0 ~ fld":" {
      val = $0; sub(/.*:[ \t]*/, "", val); gsub(/^"/, "", val); gsub(/"$/, "", val);
      print val; exit
    }
  '
}

# Run a single VT with timeout
run_vt() {
  local cmd="$1" assertion_type="$2" expected="$3" workdir="$4"
  local start_ms exit_code=0 stdout="" timed_out=false

  start_ms=$(date +%s%3N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1000))')

  # Use timeout command if available, otherwise fall back to direct exec
  if command -v timeout >/dev/null 2>&1; then
    stdout=$(cd "$workdir" && timeout "${VT_TIMEOUT}s" bash -c "$cmd" 2>&1) || exit_code=$?
    # timeout returns 124 on timeout
    if [[ $exit_code -eq 124 ]]; then
      timed_out=true
    fi
  else
    stdout=$(cd "$workdir" && bash -c "$cmd" 2>&1) || exit_code=$?
  fi

  local end_ms
  end_ms=$(date +%s%3N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1000))')
  local duration=$(( end_ms - start_ms ))

  local status="failing" matched="false" details=""

  if $timed_out; then
    status="failing"; matched="false"
    details="Command timed out after ${VT_TIMEOUT}s"
  else
    case "$assertion_type" in
      exit_code)
        if [[ $exit_code -eq 0 ]]; then
          status="passing"; matched="true"
        fi
        details="Exit code: $exit_code"
        ;;
      content)
        if echo "$stdout" | grep -qF "$expected"; then
          status="passing"; matched="true"; details="Content match found"
        else
          details="Expected content not found in output"
        fi
        ;;
      regex)
        if echo "$stdout" | grep -qE "$expected"; then
          status="passing"; matched="true"; details="Regex match found"
        else
          details="Regex pattern not matched"
        fi
        ;;
      *)
        if [[ $exit_code -eq 0 ]]; then
          status="passing"; matched="true"
        fi
        details="Exit code: $exit_code (unknown assertion_type: $assertion_type)"
        ;;
    esac
  fi

  echo "$status|$matched|$duration|$details"
}

# Collect unique yaml files
mapfile -t YAML_FILES < <(find_yamls | sort -u)

if [[ ${#YAML_FILES[@]} -eq 0 ]]; then
  if [[ "$OUTPUT" == "json" ]]; then
    echo '[]'
  else
    echo "No CONTRACT.yaml files found." >&2
  fi
  exit 0
fi

# Process each yaml
JSON_MODULES=()

for yf in "${YAML_FILES[@]}"; do
  yaml_content="$(cat "$yf")"
  workdir="$(dirname "$yf")"

  # Extract module name and path
  mod_name="$(echo "$yaml_content" | grep -m1 'name:' | sed 's/.*name:\s*"\?\([^"]*\)"\?.*/\1/')"
  mod_path="$(echo "$yaml_content" | awk '/^module:/{found=1} found && /path:/{gsub(/.*path:\s*"?/,""); gsub(/"?.*/,""); print; exit}')"

  # Filter by module
  if [[ -n "$MODULE" && "$mod_name" != "$MODULE" && "$mod_path" != "$MODULE" ]]; then
    continue
  fi

  # Extract VT IDs
  vt_ids=()
  while IFS= read -r line; do
    id="$(echo "$line" | sed 's/.*"\(.*\)".*/\1/')"
    [[ -n "$id" ]] && vt_ids+=("$id")
  done < <(echo "$yaml_content" | grep -E '^\s+-\s+id:' || true)

  if [[ ${#vt_ids[@]} -eq 0 ]]; then
    continue
  fi

  # Run each VT
  VT_RESULTS=()
  for vt_id in "${vt_ids[@]}"; do
    vt_name="$(get_vt_field "$yaml_content" "$vt_id" "name")"
    vt_cmd="$(get_vt_field "$yaml_content" "$vt_id" "test_command")"
    vt_assert="$(get_vt_field "$yaml_content" "$vt_id" "assertion_type")"
    vt_expected="$(get_vt_field "$yaml_content" "$vt_id" "expected_output")"

    if [[ -z "$vt_cmd" ]]; then
      VT_RESULTS+=("$(jq -nc --arg id "$vt_id" --arg name "$vt_name" \
        '{id:$id, name:$name, status:"skipped", assertion_matched:false, duration_ms:0, details:"No test_command defined"}')")
      continue
    fi

    result="$(run_vt "$vt_cmd" "${vt_assert:-exit_code}" "$vt_expected" "$workdir")"
    IFS='|' read -r r_status r_matched r_duration r_details <<< "$result"

    # Convert matched string to boolean for jq
    local matched_bool="false"
    [[ "$r_matched" == "true" ]] && matched_bool="true"

    VT_RESULTS+=("$(jq -nc \
      --arg id "$vt_id" \
      --arg name "$vt_name" \
      --arg status "$r_status" \
      --argjson matched "$matched_bool" \
      --argjson duration "${r_duration:-0}" \
      --arg details "$r_details" \
      '{id:$id, name:$name, status:$status, assertion_matched:$matched, duration_ms:$duration, details:$details}')")

    # Update YAML in-place if requested
    if $UPDATE_YAML && [[ "$r_status" != "skipped" ]]; then
      now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      lr="$([ "$r_status" = "passing" ] && echo "pass" || echo "fail")"
      # Escape VT ID for sed regex safety
      local escaped_id
      escaped_id="$(printf '%s\n' "$vt_id" | sed 's/[[\.*^$/]/\\&/g')"
      sed -i.bak -E "/id:\s*\"$escaped_id\"/,/id:|^[a-z]/ {
        s/(status:\s*).*/\1$r_status/
        s/(last_run:\s*).*/\1\"$now\"/
        s/(last_result:\s*).*/\1$lr/
      }" "$yf"
      rm -f "${yf}.bak"
    fi
  done

  # Build module JSON with jq
  local vt_json_array
  vt_json_array="$(printf '%s\n' "${VT_RESULTS[@]}" | jq -sc '.')"
  JSON_MODULES+=("$(jq -nc --arg mod "$mod_name" --arg path "$mod_path" --argjson vts "$vt_json_array" \
    '{module:$mod, path:$path, vt_results:$vts}')")
done

# Output
if [[ "$OUTPUT" == "json" ]]; then
  printf '%s\n' "${JSON_MODULES[@]}" | jq -sc '.'
elif [[ "$OUTPUT" == "cvr" ]]; then
  # Contract Verification Report — one per module
  cvr_array="[]"
  for entry in "${JSON_MODULES[@]}"; do
    mod_name="$(echo "$entry" | jq -r '.module')"
    mod_path="$(echo "$entry" | jq -r '.path')"
    vt_results="$(echo "$entry" | jq '.vt_results')"

    # Find the CONTRACT.yaml for this module
    contract_dir=""
    for yf in "${YAML_FILES[@]}"; do
      yf_dir="$(dirname "$yf")"
      if echo "$yf_dir" | grep -q "$mod_path" 2>/dev/null; then
        contract_dir="$yf_dir"
        break
      fi
    done

    # Compute contract hash
    contract_hash=""
    contract_title=""
    contract_md_path="${contract_dir}/CONTRACT.md"
    if [[ -f "$contract_md_path" ]]; then
      # Normalize line endings and SHA256
      contract_hash="sha256:$(tr -d '\r' < "$contract_md_path" | sha256sum | cut -d' ' -f1)"
      contract_title="$(head -1 "$contract_md_path" | sed 's/^# *//')"
    fi

    # Read drift from YAML
    drift_status="missing_yaml"
    source_hash=""
    yaml_path="${contract_dir}/CONTRACT.yaml"
    if [[ -f "$yaml_path" ]]; then
      drift_status="ok"
      source_hash="$(grep -oP 'source_hash:\s*"?\K[^"]+' "$yaml_path" 2>/dev/null || true)"
      if [[ -n "$source_hash" && -n "$contract_hash" && "$source_hash" != "$contract_hash" ]]; then
        drift_status="mismatch"
      elif [[ -z "$source_hash" ]]; then
        drift_status="missing_source_hash"
      fi
    fi

    # Count VT statuses
    passing="$(echo "$vt_results" | jq '[.[] | select(.status=="passing")] | length')"
    failing="$(echo "$vt_results" | jq '[.[] | select(.status=="failing")] | length')"
    skipped="$(echo "$vt_results" | jq '[.[] | select(.status=="skipped")] | length')"
    total="$(echo "$vt_results" | jq 'length')"

    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    cvr="$(jq -nc \
      --arg sv "1.0" \
      --arg cpath "$mod_path" \
      --arg chash "$contract_hash" \
      --arg ctitle "$contract_title" \
      --arg dstatus "$drift_status" \
      --arg shash "$source_hash" \
      --arg chash2 "$contract_hash" \
      --argjson total "$total" \
      --argjson passing "$passing" \
      --argjson failing "$failing" \
      --argjson skipped "$skipped" \
      --argjson results "$vt_results" \
      --arg gat "$now" \
      --arg gby "contracts-skill/run-vts.sh" \
      '{
        schema_version: $sv,
        contract: {path: $cpath, hash: $chash, title: $ctitle},
        drift: {status: $dstatus, source_hash: $shash, computed_hash: $chash2},
        verification_tests: {total: $total, passing: $passing, failing: $failing, skipped: $skipped, results: $results},
        generated_at: $gat,
        generated_by: $gby
      }')"

    cvr_array="$(echo "$cvr_array" | jq --argjson c "$cvr" '. + [$c]')"
  done

  # Output single CVR or array
  count="$(echo "$cvr_array" | jq 'length')"
  if [[ "$count" -eq 1 ]]; then
    echo "$cvr_array" | jq '.[0]'
  else
    echo "$cvr_array" | jq '.'
  fi
else
  if [[ ${#JSON_MODULES[@]} -eq 0 ]]; then
    echo "No VTs found to run." >&2
    exit 0
  fi

  echo "Verification Test Results:"
  echo ""
  for entry in "${JSON_MODULES[@]}"; do
    mod="$(echo "$entry" | jq -r '.module')"
    echo "  $mod:"
    echo "$entry" | jq -r '.vt_results[] | "    \(.id): \(.status) (\(.duration_ms)ms) - \(.details)"'
    echo ""
  done
fi
