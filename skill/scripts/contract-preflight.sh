#!/usr/bin/env bash
set -euo pipefail

# Contract preflight (POSIX-ish)
# Finds nearest CONTRACT.md for given files or current git diff and prints MUST/MUST NOT.

ROOT="."
OUTPUT="console"
CHANGED=false
FILES=()

usage() {
  cat <<'EOF'
Usage:
  ./contract-preflight.sh --path . [--changed] [--file path]... [--output console|json]

Examples:
  ./contract-preflight.sh --path . --changed
  ./contract-preflight.sh --path . --file src/core/auth/index.ts
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) ROOT="$2"; shift 2 ;;
    --changed) CHANGED=true; shift ;;
    --file) FILES+=("$2"); shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

ROOT_ABS="$(cd "$ROOT" && pwd)"

if $CHANGED; then
  if ! command -v git >/dev/null 2>&1; then
    echo "--changed requires git in PATH" >&2
    exit 1
  fi
  mapfile -t U < <(git diff --name-only)
  mapfile -t S < <(git diff --name-only --cached)
  FILES=("${U[@]}" "${S[@]}")
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
  if [[ "$OUTPUT" == "json" ]]; then
    printf '{"root":"%s","modules":[],"note":"No input files provided"}\n' "$ROOT_ABS"
  else
    echo "No input files provided. Use --file or --changed." >&2
  fi
  exit 0
fi

find_contract_dir() {
  local start="$1"
  local cur
  cur="$(cd "$start" 2>/dev/null && pwd || true)"
  while [[ -n "$cur" ]]; do
    # stop above root
    case "$cur" in
      "$ROOT_ABS"* ) : ;;
      * ) echo ""; return 0 ;;
    esac

    if [[ -f "$cur/CONTRACT.md" ]]; then
      echo "$cur"; return 0
    fi

    local parent
    parent="$(dirname "$cur")"
    if [[ "$parent" == "$cur" ]]; then
      echo ""; return 0
    fi
    cur="$parent"
  done
  echo ""
}

# Build unique contract dirs
declare -A SEEN=()
DIRS=()
for f in "${FILES[@]}"; do
  p="$f"
  [[ "$p" = /* ]] || p="$ROOT_ABS/$p"
  d="$(dirname "$p")"
  cdir="$(find_contract_dir "$d")"
  if [[ -n "$cdir" && -z "${SEEN[$cdir]+x}" ]]; then
    SEEN[$cdir]=1
    DIRS+=("$cdir")
  fi
done

if [[ "$OUTPUT" == "json" ]]; then
  # minimal JSON; constraints extraction is best-effort
  echo '{'
  echo "  \"root\": \"$ROOT_ABS\","
  echo '  "modules": ['
  first=true
  for cdir in "${DIRS[@]}"; do
    rel="${cdir#"$ROOT_ABS"/}"
    name="$(grep -m1 '^# ' "$cdir/CONTRACT.md" | sed 's/^# //')"
    must="$(awk 'BEGIN{in=0} /^##[[:space:]]+Constraints/{in=1;next} /^##[[:space:]]+/{in=0} in && $0 ~ /^- MUST:/{sub(/^- MUST:[[:space:]]*/,"",$0); print $0}' "$cdir/CONTRACT.md" | sed 's/"/\\"/g')"
    mustnot="$(awk 'BEGIN{in=0} /^##[[:space:]]+Constraints/{in=1;next} /^##[[:space:]]+/{in=0} in && $0 ~ /^- MUST NOT:/{sub(/^- MUST NOT:[[:space:]]*/,"",$0); print $0}' "$cdir/CONTRACT.md" | sed 's/"/\\"/g')"

    $first || echo '    ,'
    first=false

    echo '    {'
    echo "      \"path\": \"$rel\","
    echo "      \"name\": \"${name:-$rel}\","
    echo '      "constraints": {'
    echo '        "must": ['
    if [[ -n "$must" ]]; then
      while IFS= read -r line; do
        echo "          \"$line\","
      done <<< "$must" | sed '$s/,$//'
    fi
    echo '        ],'
    echo '        "must_not": ['
    if [[ -n "$mustnot" ]]; then
      while IFS= read -r line; do
        echo "          \"$line\","
      done <<< "$mustnot" | sed '$s/,$//'
    fi
    echo '        ]'
    echo '      }'
    echo '    }'
  done
  echo '  ]'
  echo '}'
  exit 0
fi

echo "Contract preflight:" 
echo "Root: $ROOT_ABS" 
echo ""

if [[ ${#DIRS[@]} -eq 0 ]]; then
  echo "No CONTRACT.md found for provided paths." >&2
  exit 0
fi

for cdir in "${DIRS[@]}"; do
  rel="${cdir#"$ROOT_ABS"/}"
  name="$(grep -m1 '^# ' "$cdir/CONTRACT.md" | sed 's/^# //')"
  echo "- ${name:-$rel} ($rel)"

  awk 'BEGIN{in=0}
       /^##[[:space:]]+Constraints/{in=1;next}
       /^##[[:space:]]+/{in=0}
       in && $0 ~ /^- MUST:/{print "  MUST: " substr($0,9)}
       in && $0 ~ /^- MUST NOT:/{print "  MUST NOT: " substr($0,13)}' "$cdir/CONTRACT.md" || true

  echo ""
done
