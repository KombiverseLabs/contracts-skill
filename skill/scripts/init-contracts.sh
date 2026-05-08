#!/usr/bin/env bash
set -euo pipefail

# Agent-led wrapper around the deterministic Node init helper.
# Analyze and dry-run modes are read-only. Writes require --apply --yes.

PATH_ARG="."
MODE="analyze"
MODULE_PATH=""
FORCE=false
YES=false

usage() {
  cat <<'EOF'
Usage:
  init-contracts.sh [--path DIR] [--analyze|--recommend|--dry-run|--apply] [--module PATH] [--force] [--yes]

Writes require --apply --yes after user approval.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) PATH_ARG="$2"; shift 2 ;;
    --analyze) MODE="analyze"; shift ;;
    --recommend) MODE="recommend"; shift ;;
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --module) MODULE_PATH="$2"; shift 2 ;;
    --force) FORCE=true; shift ;;
    --yes) YES=true; shift ;;
    --ui|--ui-port)
      # Backward-compatible no-op options. UI is no longer auto-started here.
      shift 2 ;;
    --ui-no-open)
      shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ "$MODE" == "apply" && "$YES" != "true" ]]; then
  echo "Error: --apply requires --yes after the user has approved the drafts." >&2
  exit 1
fi

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SKILL_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
INIT_AGENT="$SKILL_DIR/ai/init-agent/index.js"

if [[ ! -f "$INIT_AGENT" ]]; then
  echo "Error: init helper not found at $INIT_AGENT" >&2
  exit 1
fi

ARGS=("--path" "$PATH_ARG")

if [[ -n "$MODULE_PATH" ]]; then
  ARGS+=("--module" "$MODULE_PATH")
fi

case "$MODE" in
  analyze) ARGS+=("--analyze") ;;
  recommend) ARGS+=("--recommend") ;;
  dry-run) ARGS+=("--dry-run") ;;
  apply) ARGS+=("--apply") ;;
esac

$FORCE && ARGS+=("--force")
$YES && ARGS+=("--yes")

RESOLVED_PATH="$(cd "$PATH_ARG" && pwd)"
echo "Analyzing project at: $RESOLVED_PATH"
echo ""
node "$INIT_AGENT" "${ARGS[@]}"
