#!/usr/bin/env bash
set -euo pipefail

# Standards-first Contracts skill installer.
# Copies skill/ to a target or compatibility profile and optionally writes
# compact instruction hooks.

REPO_OWNER="kombifyio"
REPO_NAME="contracts-skill"
SKILL_NAME="contracts"
GIT_BRANCH="main"
TARGET_PATH=""
PROFILES=""
HOOKS="auto"
LEGACY_HOOKS=false
USE_LOCAL=false
SKILL_SOURCE_PATH=""
AUTO=false
NO_UI=false

usage() {
  cat <<'EOF'
Usage:
  install.sh [--target PATH] [--profiles codex,local] [--hooks auto|base|beads|none]

Options:
  --target PATH              Explicit skill target directory
  --profiles LIST            Compatibility profiles: codex, claude, copilot, cursor, local
  --agents LIST              Legacy alias for --profiles
  --hooks MODE               Hook mode: auto, base, beads, none (default: auto)
  --legacy-hooks             Mirror selected hook to legacy instruction files
  --source PATH              Use local skill source directory
  --local                    Use ./skill from this repository
  --branch NAME              Git branch to download (default: main)
  --auto                     Legacy no-op
  --no-ui                    Legacy no-op; UI is never installed here
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET_PATH="$2"; shift 2 ;;
    --profiles|--profile) PROFILES="$2"; shift 2 ;;
    --agents|-a) PROFILES="$2"; shift 2 ;;
    --hooks) HOOKS="$2"; shift 2 ;;
    --legacy-hooks) LEGACY_HOOKS=true; shift ;;
    --source) SKILL_SOURCE_PATH="$2"; shift 2 ;;
    --local) USE_LOCAL=true; shift ;;
    --branch|-b) GIT_BRANCH="$2"; shift 2 ;;
    --auto) AUTO=true; shift ;;
    --no-ui) NO_UI=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

case "$HOOKS" in
  auto|base|beads|none) ;;
  *) echo "Invalid --hooks value: $HOOKS" >&2; exit 1 ;;
esac

home_dir="${HOME:-}"
if [[ -z "$home_dir" ]]; then
  echo "HOME is not set." >&2
  exit 1
fi

default_target() {
  if [[ -n "${CODEX_HOME:-}" ]]; then
    printf '%s\n' "$CODEX_HOME/skills/$SKILL_NAME"
  else
    printf '%s\n' "$home_dir/.codex/skills/$SKILL_NAME"
  fi
}

profile_target() {
  case "$1" in
    codex) printf '%s\n' "$(default_target)" ;;
    claude) printf '%s\n' "$home_dir/.claude/skills/$SKILL_NAME" ;;
    copilot) printf '%s\n' "$home_dir/.copilot/skills/$SKILL_NAME" ;;
    cursor) printf '%s\n' "$home_dir/.cursor/skills/$SKILL_NAME" ;;
    local) printf '%s\n' "$(pwd)/.agent/skills/$SKILL_NAME" ;;
    *) echo "Unknown profile '$1'. Use codex, claude, copilot, cursor, or local." >&2; exit 1 ;;
  esac
}

resolve_target() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    ~*) printf '%s\n' "${1/#\~/$home_dir}" ;;
    *) printf '%s\n' "$(pwd)/$1" ;;
  esac
}

get_targets() {
  if [[ -n "$TARGET_PATH" ]]; then
    resolve_target "$TARGET_PATH"
    return
  fi

  if [[ -z "$PROFILES" ]]; then
    default_target
    return
  fi

  IFS=',' read -ra profile_list <<< "$PROFILES"
  declare -A seen=()
  for raw in "${profile_list[@]}"; do
    profile="$(printf '%s' "$raw" | xargs | tr '[:upper:]' '[:lower:]')"
    [[ -z "$profile" ]] && continue
    target="$(profile_target "$profile")"
    if [[ -z "${seen[$target]:-}" ]]; then
      seen[$target]=1
      printf '%s\n' "$target"
    fi
  done
}

extract_zip() {
  zip_path="$1"
  dest_dir="$2"

  if command -v unzip >/dev/null 2>&1; then
    unzip -q "$zip_path" -d "$dest_dir"
    return
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$zip_path" "$dest_dir" <<'PY'
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    archive.extractall(sys.argv[2])
PY
    return
  fi

  echo "Need unzip or python3 to extract the downloaded archive." >&2
  exit 1
}

download_skill() {
  temp_dir="$1"

  if command -v git >/dev/null 2>&1; then
    if git clone --quiet --depth 1 --branch "$GIT_BRANCH" \
      "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$temp_dir" 2>/dev/null; then
      printf '%s\n' "$temp_dir/skill"
      return
    fi
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "Need git or curl to download the skill." >&2
    exit 1
  fi

  zip_path="$temp_dir/skill.zip"
  curl -fsSL -o "$zip_path" "https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$GIT_BRANCH.zip"
  extract_zip "$zip_path" "$temp_dir"
  rm -f "$zip_path"
  extracted="$(find "$temp_dir" -maxdepth 1 -mindepth 1 -type d | head -1)"
  printf '%s\n' "$extracted/skill"
}

get_skill_source() {
  temp_dir="$1"

  if [[ -n "$SKILL_SOURCE_PATH" ]]; then
    source_dir="$SKILL_SOURCE_PATH"
  elif $USE_LOCAL; then
    script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    source_dir="$(dirname "$script_dir")/skill"
  else
    source_dir="$(download_skill "$temp_dir")"
  fi

  if [[ ! -f "$source_dir/SKILL.md" ]]; then
    echo "Skill source does not contain SKILL.md: $source_dir" >&2
    exit 1
  fi

  printf '%s\n' "$source_dir"
}

copy_skill() {
  source_dir="$1"
  target_dir="$2"

  mkdir -p "$(dirname "$target_dir")"
  rm -rf "$target_dir"
  mkdir -p "$target_dir"
  cp -R "$source_dir"/. "$target_dir"/

  if [[ ! -f "$target_dir/SKILL.md" ]]; then
    echo "Install failed: SKILL.md missing at $target_dir" >&2
    exit 1
  fi
}

hook_mode() {
  if [[ "$HOOKS" == "auto" ]]; then
    if [[ -d ".beads" ]]; then
      printf '%s\n' "beads"
    else
      printf '%s\n' "base"
    fi
  else
    printf '%s\n' "$HOOKS"
  fi
}

set_contracts_hook() {
  file_path="$1"
  hook_text="$2"
  start='<!-- contracts-skill:start -->'
  end='<!-- contracts-skill:end -->'
  block="$start
$hook_text
$end"

  mkdir -p "$(dirname "$file_path")"

  if [[ -f "$file_path" ]] && grep -qF "$start" "$file_path"; then
    tmp_file="$(mktemp)"
    awk -v start="$start" -v end="$end" -v block="$block" '
      index($0, start) { print block; skipping=1; next }
      skipping && index($0, end) { skipping=0; next }
      !skipping { print }
    ' "$file_path" > "$tmp_file"
    mv "$tmp_file" "$file_path"
  elif [[ -f "$file_path" ]]; then
    {
      sed -e '${/^$/d;}' "$file_path"
      printf '\n\n%s\n' "$block"
    } > "$file_path.tmp"
    mv "$file_path.tmp" "$file_path"
  else
    printf '%s\n' "$block" > "$file_path"
  fi
}

install_hooks() {
  source_dir="$1"
  mode="$(hook_mode)"
  [[ "$mode" == "none" ]] && return

  template="$source_dir/references/instruction-hooks/$mode.md"
  if [[ ! -f "$template" ]]; then
    echo "Hook template not found: $template" >&2
    exit 1
  fi
  hook_text="$(sed -e '${/^$/d;}' "$template")"

  set_contracts_hook "$(pwd)/AGENTS.md" "$hook_text"

  if $LEGACY_HOOKS; then
    set_contracts_hook "$(pwd)/CLAUDE.md" "$hook_text"
    set_contracts_hook "$(pwd)/codex.md" "$hook_text"
    set_contracts_hook "$(pwd)/.github/copilot-instructions.md" "$hook_text"
    set_contracts_hook "$(pwd)/.cursor/rules/contracts-system.mdc" "$hook_text"
  fi

  echo "Installed $mode contract hook -> AGENTS.md"
}

echo ""
echo "Contracts Skill Installer"
echo ""

if $AUTO; then
  echo "Note: --auto is accepted for compatibility and no longer changes target selection."
fi
if $NO_UI; then
  echo "Note: --no-ui is accepted for compatibility; UI is not installed by this installer."
fi

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

skill_source="$(get_skill_source "$temp_dir")"
mapfile -t targets < <(get_targets)

if [[ ${#targets[@]} -eq 0 ]]; then
  echo "No install targets resolved." >&2
  exit 1
fi

for target in "${targets[@]}"; do
  copy_skill "$skill_source" "$target"
  echo "Installed Contracts skill -> $target"
done

install_hooks "$skill_source"

echo ""
echo 'Done. Say "init contracts" to set up contracts for a project.'
