#!/usr/bin/env bash
set -euo pipefail

# Lightweight wrapper around the Node init-agent plus optional UI startup.
# Usage:
#   ./skill/scripts/init-contracts.sh --path . --analyze
#   ./skill/scripts/init-contracts.sh --path . --apply --ui on

PATH_ARG="."
MODE="analyze"   # analyze|recommend|dry-run|apply|module
MODULE_PATH=""
FORCE=false
YES=false
UI_MODE="ask"    # ask|on|off|once
UI_PORT=8787
UI_NO_OPEN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      PATH_ARG="$2"; shift 2 ;;
    --analyze)
      MODE="analyze"; shift ;;
    --recommend)
      MODE="recommend"; shift ;;
    --dry-run)
      MODE="dry-run"; shift ;;
    --apply)
      MODE="apply"; shift ;;
    --module)
      MODE="module"; MODULE_PATH="$2"; shift 2 ;;
    --force)
      FORCE=true; shift ;;
    --yes)
      YES=true; shift ;;
    --ui)
      UI_MODE="$2"; shift 2 ;;
    --ui-port)
      UI_PORT="$2"; shift 2 ;;
    --ui-no-open)
      UI_NO_OPEN=true; shift ;;
    -h|--help)
      echo "Usage: init-contracts.sh [--path <dir>] [--analyze|--recommend|--dry-run|--apply|--module <p>] [--force] [--yes] [--ui ask|on|off|once]"; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2; shift ;;
  esac
done

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SKILL_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
INIT_AGENT="$SKILL_DIR/ai/init-agent/index.js"

if [[ ! -f "$INIT_AGENT" ]]; then
  echo "Error: init-agent not found at $INIT_AGENT" >&2
  exit 1
fi

ARGS=("--path" "$PATH_ARG")
case "$MODE" in
  analyze) ARGS+=("--analyze") ;;
  recommend) ARGS+=("--recommend") ;;
  dry-run) ARGS+=("--dry-run") ;;
  apply) ARGS+=("--apply") ;;
  module) ARGS+=("--module" "$MODULE_PATH") ;;
  *) ARGS+=("--analyze") ;;
esac

$FORCE && ARGS+=("--force")
$YES && ARGS+=("--yes")

RESOLVED_PATH="$(cd "$PATH_ARG" && pwd)"
echo "Analyzing project at: $RESOLVED_PATH"
echo ""
node "$INIT_AGENT" "${ARGS[@]}"

UI_DIR="$RESOLVED_PATH/contracts-ui"
if [[ ! -d "$UI_DIR" ]]; then
  exit 0
fi

START_SH="$UI_DIR/start.sh"
CFG="$UI_DIR/contracts-ui.config.json"

read_cfg() {
  local key="$1"
  [[ -f "$CFG" ]] || return 1
  node -e "const fs=require('fs');try{const j=JSON.parse(fs.readFileSync(process.env.CFG,'utf8'));const v=j['$key']; if(v===undefined) process.exit(1); process.stdout.write(String(v));}catch(e){process.exit(1);}"
}

export CFG

if [[ -f "$CFG" ]]; then
  v="$(read_cfg autoStart || true)"; [[ "$v" == "true" && "$UI_MODE" == "ask" ]] && UI_MODE="on"
  v="$(read_cfg port || true)"; [[ -n "$v" ]] && UI_PORT="$v"
  v="$(read_cfg openBrowser || true)"; [[ "$v" == "false" ]] && UI_NO_OPEN=true
fi

if [[ "$UI_MODE" == "ask" && -t 0 ]]; then
  echo ""
  echo "Start Contracts UI?"
  echo "  [1] no (default)"
  echo "  [2] start once"
  echo "  [3] start and enable auto-start"
  read -p "Selection (default: 1): " a
  case "$a" in
    2) UI_MODE="once" ;;
    3) UI_MODE="on" ;;
    *) UI_MODE="off" ;;
  esac
fi

if [[ "$UI_MODE" == "off" ]]; then
  exit 0
fi

if [[ "$UI_MODE" == "on" ]]; then
  if [[ -f "$CFG" ]]; then
    node -e "const fs=require('fs');const p=process.argv[1];const j=JSON.parse(fs.readFileSync(p,'utf8'));j.autoStart=true;fs.writeFileSync(p,JSON.stringify(j,null,2));" "$CFG" >/dev/null 2>&1 || true
  fi
fi

if [[ -f "$START_SH" ]]; then
  PORT="$UI_PORT" PROJECT_ROOT="$RESOLVED_PATH" NO_OPEN="$UI_NO_OPEN" sh "$START_SH" || true
fi
