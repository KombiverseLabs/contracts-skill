#!/usr/bin/env bash
set -euo pipefail

# StackKit contract lock standard.
# Locks approved CONTRACT.md files as read-only guardrails for agent workflows.

ROOT="."
INCLUDE_YAML=false
FILES=()

usage() {
  cat <<'EOF'
Usage:
  ./lock-contracts.sh [--path .] [--file path]... [--include-yaml]

Examples:
  ./lock-contracts.sh --path .
  ./lock-contracts.sh --file src/core/auth/CONTRACT.md
  ./lock-contracts.sh --path . --include-yaml

By default only CONTRACT.md files are locked. CONTRACT.yaml remains writable
because it is the AI-maintained technical mapping.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) ROOT="$2"; shift 2 ;;
    --file) FILES+=("$2"); shift 2 ;;
    --include-yaml) INCLUDE_YAML=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

ROOT_ABS="$(cd "$ROOT" && pwd)"
TARGETS=()

add_contract_file() {
  local candidate="$1"
  if [[ -f "$candidate" ]]; then
    case "$(basename "$candidate")" in
      CONTRACT.md|CONTRACT.yaml) TARGETS+=("$candidate") ;;
      *) echo "Skipping non-contract file: $candidate" >&2 ;;
    esac
  elif [[ -d "$candidate" ]]; then
    local find_expr=(-name CONTRACT.md)
    if $INCLUDE_YAML; then
      find_expr=(\( -name CONTRACT.md -o -name CONTRACT.yaml \))
    fi
    while IFS= read -r -d '' file; do
      TARGETS+=("$file")
    done < <(find "$candidate" "${find_expr[@]}" -type f -print0)
  else
    echo "Not found: $candidate" >&2
    exit 1
  fi
}

if [[ ${#FILES[@]} -gt 0 ]]; then
  for f in "${FILES[@]}"; do
    if [[ "$f" = /* || "$f" =~ ^[A-Za-z]:/ ]]; then
      add_contract_file "$f"
    else
      add_contract_file "$ROOT_ABS/$f"
    fi
  done
else
  add_contract_file "$ROOT_ABS"
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo "No contract files found to lock."
  exit 0
fi

count=0
for file in "${TARGETS[@]}"; do
  chmod a-w "$file"
  printf '[locked] %s\n' "$file"
  count=$((count + 1))
done

printf 'Locked %d contract file(s).\n' "$count"
