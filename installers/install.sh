#!/usr/bin/env bash
set -euo pipefail

# Contracts Skill Installer
# Installs the Contracts skill for AI coding assistants.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/kombifyio/contracts-skill/main/installers/install.sh | bash
#   ./install.sh --agents copilot,claude --auto

REPO_OWNER="kombifyio"
REPO_NAME="contracts-skill"
SKILL_NAME="contracts"
GIT_BRANCH="main"
AGENTS=""
AUTO=false
NO_UI=false
USE_LOCAL=false
SKILL_SOURCE_PATH=""

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --agents|-a)     AGENTS="$2"; shift 2 ;;
        --auto)          AUTO=true; shift ;;
        --branch|-b)     GIT_BRANCH="$2"; shift 2 ;;
        --no-ui)         NO_UI=true; shift ;;
        --local)         USE_LOCAL=true; shift ;;
        --source)        SKILL_SOURCE_PATH="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: install.sh [--agents copilot,claude] [--auto] [--branch main] [--no-ui] [--local] [--source PATH]"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m'

# --- Agent Definitions ---
declare -a AGENT_IDS=("copilot" "claude" "cursor" "codex" "local")
declare -a AGENT_NAMES=("GitHub Copilot" "Claude Code" "Cursor" "OpenAI Codex" "Project Local")

get_install_path() {
    local id="$1"
    case "$id" in
        copilot)  echo "$HOME/.copilot/skills/$SKILL_NAME" ;;
        claude)   echo "$HOME/.claude/skills/$SKILL_NAME" ;;
        cursor)   echo "$HOME/.cursor/skills/$SKILL_NAME" ;;
        codex)    echo "$HOME/.codex/skills/$SKILL_NAME" ;;
        local)    echo "$(pwd)/.agent/skills/$SKILL_NAME" ;;
    esac
}

is_detected() {
    local id="$1"
    case "$id" in
        copilot)  [[ -d "$HOME/.copilot" ]] || [[ -d "$HOME/.vscode" ]] ;;
        claude)   [[ -d "$HOME/.claude" ]] ;;
        cursor)   [[ -d "$HOME/.cursor" ]] ;;
        codex)    [[ -d "$HOME/.codex" ]] ;;
        local)    [[ -d ".git" ]] || [[ -f "package.json" ]] ;;
    esac
}

is_installed() {
    local path; path=$(get_install_path "$1")
    [[ -f "$path/SKILL.md" ]]
}

get_instruction_file() {
    local id="$1"
    case "$id" in
        copilot)  echo ".github/copilot-instructions.md" ;;
        claude)   echo "CLAUDE.md" ;;
        cursor)   echo ".cursor/rules/contracts-system.mdc" ;;
        codex)    echo "codex.md" ;;
        local)    echo "" ;;
    esac
}

get_instruction_snippet() {
    local id="$1"
    case "$id" in
        copilot)
            cat <<'SNIPPET'

## Contracts System (MANDATORY)
Before any code changes: locate CONTRACT.md in target module, read spec + metadata, verify source_hash, summarize constraints briefly, then proceed.
SNIPPET
            ;;
        claude)
            cat <<'SNIPPET'

## Contracts System
Before any code changes, determine the target module(s) and locate the nearest CONTRACT.md.
Read CONTRACT.md + CONTRACT.yaml and check drift (source_hash vs current hash); if drift exists, sync YAML first.
Before editing, give the user a very short "Contract Notes" summary of MUST / MUST NOT constraints (max 5 sentences).
CONTRACT.md is user-owned (never edit directly).
When creating a new module, propose generating a matching contract via init-agent (--module).
SNIPPET
            ;;
        cursor)
            cat <<'SNIPPET'
---
description: "Contracts System preflight - MANDATORY before code changes"
alwaysApply: true
---

# Contracts System (MANDATORY)
Before code changes: locate CONTRACT.md in target module, read spec + metadata, verify source_hash, summarize constraints briefly.
SNIPPET
            ;;
        codex)
            cat <<'SNIPPET'

## Contracts System (MANDATORY)
Before any code changes: locate CONTRACT.md in target module, read spec + metadata, verify source_hash, summarize constraints briefly, then proceed.
SNIPPET
            ;;
    esac
}

extract_zip() {
    local zip_path="$1"
    local dest_dir="$2"

    if command -v unzip &>/dev/null; then
        unzip -q "$zip_path" -d "$dest_dir"
        return 0
    fi

    if command -v python3 &>/dev/null; then
        python3 - "$zip_path" "$dest_dir" <<'PY'
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    archive.extractall(sys.argv[2])
PY
        return 0
    fi

    echo -e "  ${RED}Need either 'unzip' or 'python3' to extract the downloaded archive.${NC}" >&2
    return 1
}

# --- Download Skill ---
download_skill() {
    local temp_dir="$1"

    echo -e "  ${YELLOW}Downloading skill...${NC}"

    if command -v git &>/dev/null; then
        if git clone --quiet --depth 1 --branch "$GIT_BRANCH" \
            "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$temp_dir" 2>/dev/null; then
            echo -e "  ${GREEN}Downloaded via git${NC}"
            echo "$temp_dir/skill"
            return 0
        fi
    fi

    if ! command -v curl &>/dev/null; then
        echo -e "  ${RED}Need either 'git' or 'curl' to download the skill.${NC}" >&2
        return 1
    fi

    local zip_url="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$GIT_BRANCH.zip"
    local zip_path="$temp_dir/skill.zip"
    curl -fsSL -o "$zip_path" "$zip_url"
    extract_zip "$zip_path" "$temp_dir"
    rm -f "$zip_path"
    local extracted; extracted=$(find "$temp_dir" -maxdepth 1 -mindepth 1 -type d | head -1)
    echo -e "  ${GREEN}Downloaded via ZIP${NC}"
    echo "$extracted/skill"
}

# --- Main ---
echo ""
echo -e "  ${CYAN}Contracts Skill Installer${NC}"
echo -e "  ${CYAN}Spec-Driven Development for AI Assistants${NC}"
echo ""

echo -e "  ${CYAN}Scanning for AI coding assistants...${NC}"
echo ""

declare -a DETECTED_IDS=()
declare -a DETECTED_NAMES=()
declare -a INSTALLED_IDS=()

for i in "${!AGENT_IDS[@]}"; do
    id="${AGENT_IDS[$i]}"
    name="${AGENT_NAMES[$i]}"

    if is_installed "$id"; then
        echo -e "    ${name}: ${GREEN}[INSTALLED]${NC}"
        INSTALLED_IDS+=("$id")
    elif is_detected "$id"; then
        echo -e "    ${name}: ${YELLOW}[DETECTED]${NC}"
        DETECTED_IDS+=("$id")
        DETECTED_NAMES+=("$name")
    else
        echo -e "    ${name}: ${GRAY}[NOT FOUND]${NC}"
    fi
done

echo ""

# --- Select Agents ---
declare -a SELECTED_IDS=()
declare -a SELECTED_NAMES=()

if [[ -n "$AGENTS" ]]; then
    IFS=',' read -ra agent_list <<< "$AGENTS"
    for a in "${agent_list[@]}"; do
        a=$(echo "$a" | xargs | tr '[:upper:]' '[:lower:]')
        for i in "${!DETECTED_IDS[@]}"; do
            if [[ "${DETECTED_IDS[$i]}" == "$a" ]]; then
                SELECTED_IDS+=("$a")
                SELECTED_NAMES+=("${DETECTED_NAMES[$i]}")
            fi
        done
    done
elif $AUTO; then
    SELECTED_IDS=("${DETECTED_IDS[@]}")
    SELECTED_NAMES=("${DETECTED_NAMES[@]}")
else
    if [[ ${#DETECTED_IDS[@]} -eq 0 ]]; then
        echo -e "  ${YELLOW}No new agents to install to.${NC}"
        exit 0
    fi

    for i in "${!DETECTED_IDS[@]}"; do
        echo -e "    ${WHITE}[$((i+1))] ${DETECTED_NAMES[$i]}${NC}"
    done
    echo -e "    ${WHITE}[A] All detected${NC}"
    echo ""

    read -rp "  Select (e.g., 1,2 or A): " resp
    if [[ "$resp" =~ ^[Aa]$ ]]; then
        SELECTED_IDS=("${DETECTED_IDS[@]}")
        SELECTED_NAMES=("${DETECTED_NAMES[@]}")
    else
        IFS=',' read -ra indices <<< "$resp"
        for idx in "${indices[@]}"; do
            idx=$(echo "$idx" | xargs)
            if [[ "$idx" =~ ^[0-9]+$ ]]; then
                n=$((idx - 1))
                if [[ $n -ge 0 && $n -lt ${#DETECTED_IDS[@]} ]]; then
                    SELECTED_IDS+=("${DETECTED_IDS[$n]}")
                    SELECTED_NAMES+=("${DETECTED_NAMES[$n]}")
                fi
            fi
        done
    fi
fi

if [[ ${#SELECTED_IDS[@]} -eq 0 ]]; then
    echo -e "  ${YELLOW}No agents selected.${NC}"
    exit 0
fi

# --- Get Skill Source ---
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

SKILL_SOURCE=""
if [[ -n "$SKILL_SOURCE_PATH" ]]; then
    SKILL_SOURCE="$SKILL_SOURCE_PATH"
elif $USE_LOCAL; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SKILL_SOURCE="$(dirname "$SCRIPT_DIR")/skill"
    if [[ ! -d "$SKILL_SOURCE" ]]; then
        echo -e "  ${RED}Local skill folder not found: $SKILL_SOURCE${NC}"
        exit 1
    fi
else
    SKILL_SOURCE=$(download_skill "$TEMP_DIR")
fi

echo ""
echo -e "  ${CYAN}Installing to ${#SELECTED_IDS[@]} agent(s)...${NC}"

SUCCESS=0
for i in "${!SELECTED_IDS[@]}"; do
    id="${SELECTED_IDS[$i]}"
    name="${SELECTED_NAMES[$i]}"
    target=$(get_install_path "$id")

    printf "    %s..." "$name"

    parent=$(dirname "$target")
    mkdir -p "$parent"
    rm -rf "$target"
    cp -r "$SKILL_SOURCE" "$target"

    if [[ -f "$target/SKILL.md" ]]; then
        echo -e " ${GREEN}OK${NC}"
        SUCCESS=$((SUCCESS + 1))

        # Inject instruction hook
        instr_file=$(get_instruction_file "$id")
        if [[ -n "$instr_file" ]]; then
            snippet=$(get_instruction_snippet "$id")
            if [[ -f "$instr_file" ]]; then
                if ! grep -q "Contracts System" "$instr_file" 2>/dev/null; then
                    echo "$snippet" >> "$instr_file"
                    echo -e "      ${GRAY}-> Updated $instr_file${NC}"
                fi
            else
                dir=$(dirname "$instr_file")
                mkdir -p "$dir"
                echo "$snippet" > "$instr_file"
                echo -e "      ${GRAY}-> Created $instr_file${NC}"
            fi
        fi
    else
        echo -e " ${RED}FAILED${NC}"
    fi
done

# --- Install UI ---
if ! $NO_UI; then
    ui_source="$SKILL_SOURCE/ui/minimal-ui"
    if [[ -d "$ui_source" ]]; then
        echo ""
        install_ui=false
        if $AUTO; then
            install_ui=true
        else
            read -rp "  Install Contracts Web UI? (y/N): " resp
            [[ "$resp" =~ ^[Yy]$ ]] && install_ui=true
        fi

        if $install_ui; then
            ui_target="$(pwd)/contracts-ui"
            rm -rf "$ui_target"
            cp -r "$ui_source" "$ui_target"
            echo -e "    ${GREEN}Installed Contracts UI -> ./contracts-ui${NC}"
            echo -e "    ${GRAY}Start: ./contracts-ui/start.sh${NC}"
        fi
    fi
fi

# --- Project Setup ---
echo ""
echo -e "  ${CYAN}Project Setup${NC}"
echo ""

SETUP_PROJECT=false
if $AUTO; then
    SETUP_PROJECT=true
else
    read -rp "  Set up .contracts/ directory in this project? (Y/n): " resp
    if [[ -z "$resp" || "$resp" =~ ^[Yy]$ ]]; then
        SETUP_PROJECT=true
    fi
fi

if $SETUP_PROJECT; then
    # Gather project info
    PROJECT_NAME=""
    PROJECT_STACK="(not set)"
    PROJECT_OWNER="(not set)"
    PROJECT_CONVENTIONS="(Add your project conventions here — module layout, test location, naming rules, etc.)"

    if ! $AUTO; then
        # Auto-detect project name
        DETECTED_NAME=""
        if [[ -f "package.json" ]] && command -v node &>/dev/null; then
            DETECTED_NAME=$(node -e "try{process.stdout.write(require('./package.json').name||'')}catch(e){}" 2>/dev/null)
        fi
        if [[ -z "$DETECTED_NAME" ]] && command -v git &>/dev/null; then
            REMOTE=$(git remote get-url origin 2>/dev/null || true)
            if [[ -n "$REMOTE" ]]; then
                DETECTED_NAME=$(basename "$REMOTE" .git)
            fi
        fi
        if [[ -z "$DETECTED_NAME" ]]; then
            DETECTED_NAME=$(basename "$(pwd)")
        fi

        echo -e "    ${GRAY}Detected project name: $DETECTED_NAME${NC}"
        read -rp "    Project name (Enter = $DETECTED_NAME): " input
        PROJECT_NAME="${input:-$DETECTED_NAME}"

        read -rp "    Primary stack/language (e.g., TypeScript, Go, Python): " input
        [[ -n "$input" ]] && PROJECT_STACK="$input"

        read -rp "    Contracts owner/team (e.g., your name or team): " input
        [[ -n "$input" ]] && PROJECT_OWNER="$input"

        read -rp "    Project conventions? (e.g., features in src/features/, tests in __tests__/) or Enter to skip: " input
        [[ -n "$input" ]] && PROJECT_CONVENTIONS="$input"
    else
        # Auto-detect project name
        if [[ -f "package.json" ]] && command -v node &>/dev/null; then
            PROJECT_NAME=$(node -e "try{process.stdout.write(require('./package.json').name||'')}catch(e){}" 2>/dev/null)
        fi
        if [[ -z "$PROJECT_NAME" ]] && command -v git &>/dev/null; then
            REMOTE=$(git remote get-url origin 2>/dev/null || true)
            if [[ -n "$REMOTE" ]]; then
                PROJECT_NAME=$(basename "$REMOTE" .git)
            fi
        fi
        if [[ -z "$PROJECT_NAME" ]]; then
            PROJECT_NAME=$(basename "$(pwd)")
        fi
    fi

    # Create .contracts/ directory
    mkdir -p .contracts

    # Build skill paths table
    SKILL_PATH_ROWS="| Agent | Skill Path |\n|-------|-----------|"
    for i in "${!SELECTED_IDS[@]}"; do
        id="${SELECTED_IDS[$i]}"
        name="${SELECTED_NAMES[$i]}"
        path=$(get_install_path "$id")
        SKILL_PATH_ROWS="$SKILL_PATH_ROWS\n| $name | \`$path\` |"
    done

    TODAY=$(date '+%Y-%m-%d')

    # Write CONTRACTS-GUIDE.md
    cat > .contracts/CONTRACTS-GUIDE.md <<GUIDE
# Contracts System — Project Guide

> **Permanent project artifact.** Commit this file to version control.
> This guide tells every developer and AI agent how the Contracts system is set up in this project.

---

## Project

**Name:** $PROJECT_NAME
**Stack:** $PROJECT_STACK
**Owner:** $PROJECT_OWNER
**Initialized:** $TODAY

---

## Where to Find Things

| What you need | Location |
|---------------|----------|
| All contracts (registry) | \`.contracts/registry.yaml\` |
| A module's specification | \`<module-dir>/CONTRACT.md\` |
| A module's technical mapping | \`<module-dir>/CONTRACT.yaml\` |
| Contract templates | Skill: \`references/templates/\` |
| Init workflow (AI hook) | Skill: \`references/assistant-hooks/init-contracts.md\` |
| Preflight workflow (AI hook) | Skill: \`references/assistant-hooks/contract-preflight.md\` |
| Review workflow (AI hook) | Skill: \`references/assistant-hooks/contract-review.md\` |
| Validation script | Skill: \`scripts/validate-contracts.ps1\` (Windows) |

## Skill Locations

$(echo -e "$SKILL_PATH_ROWS")

---

## Registered Modules

*(Run \`"init contracts"\` to discover and register modules.)*

| Module | Path | Tier | Contract |
|--------|------|------|----------|

---

## How Contracts Are Applied

### Before any code change

The AI runs a **contract preflight** automatically before touching any module:

1. Locate \`CONTRACT.md\` in or above the target directory.
2. Read spec + YAML, compare \`source_hash\`. Hash mismatch → sync YAML first.
3. Check attestation freshness and VT status.
4. Summarize MUST / MUST NOT constraints (max 5 sentences).

Say **\`"contract preflight"\`** to trigger manually at any time.

### When you change a module spec

1. Edit \`CONTRACT.md\` yourself — AI never modifies the spec.
2. Tell the AI: \`"I've updated the contract for [module]"\`.
3. AI syncs \`CONTRACT.yaml\`, resets attestation to \`low\`, adds changelog entry.

### When you add a new module

Say **\`"init contracts for [module-path]"\`** or **\`"create a contract for [module]"\`**.
AI drafts from the matching template and presents it for your review.

### When work is out of scope

If the AI says "this isn't in the contract" — that is **intended behavior**.
Options: update \`CONTRACT.md\` to include it, or tell the AI to mark it as Out of Scope.

---

## Quick Commands

| Intent | Say to your AI |
|--------|----------------|
| Initialize contracts for this project | \`"init contracts"\` |
| Check before implementing a feature | \`"contract preflight"\` |
| Review scope after completing work | \`"contract review"\` |
| Scan all contracts for drift | \`"check contracts"\` |
| Sync all YAMLs from changed MDs | \`"sync contracts"\` |

---

## Project Conventions

$PROJECT_CONVENTIONS

---

## Contract Tiers

| Tier | MD line limit | Typical complexity | Verification tests |
|------|--------------|--------------------|--------------------|
| \`core\` | 30 lines | < 100 LOC, foundational module | 1 |
| \`standard\` | 50 lines | 100-500 LOC, feature module | 1-2 |
| \`complex\` | 80 lines | > 500 LOC, multi-concern module | 2-3 |

---

*Contracts Skill — https://github.com/kombifyio/contracts-skill*
GUIDE

    echo -e "    ${GREEN}Created .contracts/CONTRACTS-GUIDE.md${NC}"

    # Create registry.yaml if it doesn't exist
    if [[ ! -f ".contracts/registry.yaml" ]]; then
        cat > .contracts/registry.yaml <<'REGISTRY'
# Contracts Registry
# Maintained by the Contracts Skill. Run "init contracts" to populate.
contracts: []
REGISTRY
        echo -e "    ${GREEN}Created .contracts/registry.yaml${NC}"
    fi

    echo ""
    echo -e "    ${GRAY}Tip: Commit .contracts/ to version control.${NC}"
fi

# --- Summary ---
echo ""
if [[ $SUCCESS -eq ${#SELECTED_IDS[@]} ]]; then
    echo -e "  ${GREEN}Done: $SUCCESS/${#SELECTED_IDS[@]} agents installed.${NC}"
else
    echo -e "  ${YELLOW}Done: $SUCCESS/${#SELECTED_IDS[@]} agents installed.${NC}"
fi
echo ""
echo -e "  ${YELLOW}Next: ask your AI \"Initialize contracts for this project\"${NC}"
echo ""