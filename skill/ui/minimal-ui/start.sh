#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8787}"
PROJECT_ROOT="${PROJECT_ROOT:-}"
NO_OPEN="${NO_OPEN:-false}"
FOREGROUND="${FOREGROUND:-false}"

UI_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SERVER_JS="$UI_DIR/server.js"
CONFIG_PATH="${CONFIG_PATH:-$UI_DIR/contracts-ui.config.json}"

if [[ ! -f "$SERVER_JS" ]]; then
  echo "Missing server.js at $SERVER_JS" >&2
  exit 1
fi

read_config() {
  local key="$1"
  [[ -f "$CONFIG_PATH" ]] || return 1
  node -e "const fs=require('fs');try{const j=JSON.parse(fs.readFileSync(process.env.CONFIG_PATH,'utf8'));const v=j['$key']; if(v===undefined) process.exit(1); process.stdout.write(String(v));}catch(e){process.exit(1);}"
}

export CONFIG_PATH

if [[ -z "$PROJECT_ROOT" ]]; then
  PROJECT_ROOT="$UI_DIR/.."
fi

if [[ -f "$CONFIG_PATH" ]]; then
  if [[ -z "${PORT_SET:-}" ]]; then
    v="$(read_config port || true)"; [[ -n "$v" ]] && PORT="$v"
  fi
  v="$(read_config projectRoot || true)"; [[ -n "$v" ]] && PROJECT_ROOT="$v"
  v="$(read_config openBrowser || true)"; [[ "$v" == "false" ]] && NO_OPEN=true
fi

ROOT_ABS="$(cd "$PROJECT_ROOT" && pwd)"
URL="http://127.0.0.1:$PORT/"

if [[ "$FOREGROUND" == "true" ]]; then
  echo "Starting Contracts UI server (foreground)"
  echo "  Project root: $ROOT_ABS"
  echo "  URL: $URL"
  if [[ "$NO_OPEN" != "true" ]]; then
    if command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL" >/dev/null 2>&1 || true; fi
    if command -v open >/dev/null 2>&1; then open "$URL" >/dev/null 2>&1 || true; fi
  fi
  exec node "$SERVER_JS" --port "$PORT" --project-root "$ROOT_ABS"
fi

echo "Starting Contracts UI server (background)"
echo "  Project root: $ROOT_ABS"
echo "  URL: $URL"

nohup node "$SERVER_JS" --port "$PORT" --project-root "$ROOT_ABS" >/dev/null 2>&1 &

if [[ "$NO_OPEN" != "true" ]]; then
  sleep 0.25 || true
  if command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL" >/dev/null 2>&1 || true; fi
  if command -v open >/dev/null 2>&1; then open "$URL" >/dev/null 2>&1 || true; fi
fi
