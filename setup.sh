#!/bin/bash
#
# Contracts Skill - Automated Installer
# Detects AI coding assistants and installs to all of them
#
# One-liner: curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/setup.sh | bash
#

set -e

# Configuration
REPO_OWNER="KombiverseLabs"
REPO_NAME="contracts-skill"
BRANCH="main"
SKILL_NAME="contracts"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Parse arguments
AUTO=false
INSTALL_UI=false
UI_TYPE=""
UI_DIR="contracts-ui"
UI_FORCE=false
SKIP_UI=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto|-a)
            AUTO=true
            shift
            ;;
        --ui|-u)
            INSTALL_UI=true
            if [ -n "$2" ] && [[ "$2" != -* ]]; then
                UI_TYPE="$2"
                shift 2
            else
                shift
            fi
            ;;
        --ui-type)
            UI_TYPE="$2"
            INSTALL_UI=true
            shift 2
            ;;
        --ui-dir)
            UI_DIR="$2"
            INSTALL_UI=true
            shift 2
            ;;
        --ui-force)
            UI_FORCE=true
            INSTALL_UI=true
            shift
            ;;
        --no-ui)
            SKIP_UI=true
            shift
            ;;
        --help|-h)
            echo "Usage: setup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --auto, -a    Install to all detected agents without prompting"
            echo "  --ui, -u      Install Contracts Web UI into this project (optional arg: minimal-ui|php-ui|none)"
            echo "  --ui-type <t> UI type: minimal-ui | php-ui | none"
            echo "  --ui-dir <d>  Target directory for UI (default: contracts-ui)"
            echo "  --ui-force    Overwrite existing UI directory"
            echo "  --no-ui       Do not prompt for UI"
            echo "  --help, -h    Show this help"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           Contracts Skill - Automated Installer             ║${NC}"
echo -e "${CYAN}║         Spec-Driven Development for AI Assistants            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Agent configurations
declare -A AGENTS
declare -A AGENT_PATHS
declare -A AGENT_ICONS

# GitHub Copilot
AGENTS["copilot"]="GitHub Copilot (VS Code)"
AGENT_PATHS["copilot"]="./.github/skills/$SKILL_NAME"
AGENT_ICONS["copilot"]="🤖"

# Claude
AGENTS["claude"]="Claude Code"
AGENT_PATHS["claude"]="$HOME/.claude/skills/$SKILL_NAME"
AGENT_ICONS["claude"]="🧠"

# Cursor
AGENTS["cursor"]="Cursor"
AGENT_PATHS["cursor"]="$HOME/.cursor/skills/$SKILL_NAME"
AGENT_ICONS["cursor"]="⚡"

# Windsurf
AGENTS["windsurf"]="Windsurf (Codeium)"
AGENT_PATHS["windsurf"]="$HOME/.windsurf/skills/$SKILL_NAME"
AGENT_ICONS["windsurf"]="🏄"

# Cline
AGENTS["cline"]="Cline"
AGENT_PATHS["cline"]="$HOME/.cline/skills/$SKILL_NAME"
AGENT_ICONS["cline"]="📟"

# OpenCode
AGENTS["opencode"]="OpenCode"
AGENT_PATHS["opencode"]="$HOME/.opencode/skills/$SKILL_NAME"
AGENT_ICONS["opencode"]="🔓"

# Aider
AGENTS["aider"]="Aider"
AGENT_PATHS["aider"]="$HOME/.aider/skills/$SKILL_NAME"
AGENT_ICONS["aider"]="🔧"

# Project local
AGENTS["local"]="Project Local (.agent)"
AGENT_PATHS["local"]="./.agent/skills/$SKILL_NAME"
AGENT_ICONS["local"]="📁"

# Detection paths
detect_agent() {
    local agent=$1
    case $agent in
        copilot)
            [[ -d "$HOME/.copilot" ]] || [[ -d "$HOME/.vscode" ]] && return 0
            ;;
        claude)
            [[ -d "$HOME/.claude" ]] || [[ -d "$HOME/Library/Application Support/Claude" ]] && return 0
            ;;
        cursor)
            [[ -d "$HOME/.cursor" ]] || [[ -d "$HOME/Library/Application Support/Cursor" ]] && return 0
            ;;
        windsurf)
            [[ -d "$HOME/.windsurf" ]] || [[ -d "$HOME/.codeium" ]] && return 0
            ;;
        cline)
            [[ -d "$HOME/.cline" ]] && return 0
            ;;
        opencode)
            [[ -d "$HOME/.opencode" ]] || [[ -d "$HOME/Library/Application Support/OpenCode" ]] && return 0
            ;;
        aider)
            [[ -f "$HOME/.aider.conf.yml" ]] || [[ -d "$HOME/.aider" ]] && return 0
            ;;
        local)
            [[ -f "./package.json" ]] || [[ -d "./.git" ]] || [[ -d "./.agent" ]] && return 0
            ;;
    esac
    return 1
}

check_installed() {
    local path=$1
    [[ -f "$path/SKILL.md" ]] && return 0
    return 1
}

echo -e "${CYAN}Scanning for AI coding assistants...${NC}"
echo ""

DETECTED=()
INSTALLED=()

for agent in copilot claude cursor windsurf cline aider local; do
    path="${AGENT_PATHS[$agent]}"
    name="${AGENTS[$agent]}"
    icon="${AGENT_ICONS[$agent]}"
    
    if check_installed "$path"; then
        echo -e "  ${icon} ${name}: ${GREEN}[INSTALLED]${NC}"
        INSTALLED+=("$agent")
    elif detect_agent "$agent"; then
        echo -e "  ${icon} ${name}: ${YELLOW}[DETECTED]${NC}"
        DETECTED+=("$agent")
    else
        echo -e "  ${icon} ${name}: ${GRAY}[NOT FOUND]${NC}"
    fi
done

echo ""

if [[ ${#INSTALLED[@]} -gt 0 ]]; then
    echo -e "${GREEN}Already installed:${NC}"
    for agent in "${INSTALLED[@]}"; do
        echo -e "  ${GRAY}✓ ${AGENTS[$agent]} → ${AGENT_PATHS[$agent]}${NC}"
    done
    echo ""
fi

if [[ ${#DETECTED[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No new agents to install to.${NC}"
    echo ""
    echo -e "${CYAN}Tip: Run this in a project directory to install locally to .agent/skills/${NC}"
    exit 0
fi

# Selection
SELECTED=()

if [[ "$AUTO" == "true" ]]; then
    SELECTED=("${DETECTED[@]}")
    echo -e "Auto-installing to ${#SELECTED[@]} agent(s)..."
else
    echo "Select agents to install to:"
    echo ""
    
    idx=1
    for agent in "${DETECTED[@]}"; do
        echo "  [$idx] ${AGENT_ICONS[$agent]} ${AGENTS[$agent]}"
        echo -e "      ${GRAY}→ ${AGENT_PATHS[$agent]}${NC}"
        ((idx++))
    done
    
    echo ""
    echo "  [A] Install to ALL detected agents"
    echo "  [Q] Quit"
    echo ""
    
    read -p "Enter selection (e.g., '1,2' or 'A'): " selection
    
    if [[ "$selection" == "Q" ]] || [[ "$selection" == "q" ]]; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi
    
    if [[ "$selection" == "A" ]] || [[ "$selection" == "a" ]]; then
        SELECTED=("${DETECTED[@]}")
    else
        IFS=',' read -ra indices <<< "$selection"
        for i in "${indices[@]}"; do
            i=$(echo "$i" | tr -d ' ')
            if [[ "$i" =~ ^[0-9]+$ ]]; then
                idx=$((i - 1))
                if [[ $idx -ge 0 ]] && [[ $idx -lt ${#DETECTED[@]} ]]; then
                    SELECTED+=("${DETECTED[$idx]}")
                fi
            fi
        done
    fi
fi

if [[ ${#SELECTED[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No agents selected.${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}Installing to ${#SELECTED[@]} agent(s)...${NC}"

# Download skill
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${YELLOW}Downloading skill from GitHub...${NC}"

if command -v git &> /dev/null; then
    if git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$TEMP_DIR/repo" 2>/dev/null; then
        echo -e "${GREEN}✓ Downloaded via git${NC}"
        SKILL_SOURCE="$TEMP_DIR/repo/skill"
    fi
fi

if [[ -z "$SKILL_SOURCE" ]]; then
    ZIP_URL="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$BRANCH.zip"
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$ZIP_URL" -o "$TEMP_DIR/repo.zip"
    elif command -v wget &> /dev/null; then
        wget -q "$ZIP_URL" -O "$TEMP_DIR/repo.zip"
    else
        echo -e "${RED}Error: curl or wget required${NC}"
        exit 1
    fi
    
    unzip -q "$TEMP_DIR/repo.zip" -d "$TEMP_DIR"
    SKILL_SOURCE="$TEMP_DIR/$REPO_NAME-$BRANCH/skill"
    echo -e "${GREEN}✓ Downloaded via ZIP${NC}"
fi

if [[ ! -d "$SKILL_SOURCE" ]]; then
    echo -e "${RED}Error: Could not find skill folder${NC}"
    exit 1
fi

echo ""

# Install to each agent
SUCCESS_COUNT=0

for agent in "${SELECTED[@]}"; do
    target="${AGENT_PATHS[$agent]}"
    name="${AGENTS[$agent]}"
    
    echo -n "  Installing to $name..."
    
    # Create parent directory
    mkdir -p "$(dirname "$target")"
    
    # Remove existing and copy new
    rm -rf "$target"
    cp -r "$SKILL_SOURCE" "$target"
    
    if [[ -f "$target/SKILL.md" ]]; then
        echo -e " ${GREEN}✓${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e " ${RED}✗ Failed${NC}"
    fi
done

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
if [[ $SUCCESS_COUNT -eq ${#SELECTED[@]} ]]; then
    echo -e "${GREEN} Installation Complete: $SUCCESS_COUNT/${#SELECTED[@]} agents${NC}"
else
    echo -e "${YELLOW} Installation Complete: $SUCCESS_COUNT/${#SELECTED[@]} agents${NC}"
fi
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Open a project and run: ${CYAN}init contracts${NC}"
echo -e "  2. Or ask your AI: ${CYAN}\"Initialize contracts for this project\"${NC}"
echo ""

# Optional: install web UI into current project
is_contracts_skill_repo() {
    [[ -f "./skill/SKILL.md" ]] && [[ -f "./installers/install.sh" ]] && [[ -f "./setup.sh" ]]
}

install_ui_now() {
    local t="$UI_TYPE"; [ -z "$t" ] && t="minimal-ui";
    [ "$t" = "none" ] && return 0
    local src
    if [ "$t" = "php-ui" ]; then
        src="$SKILL_SOURCE/ui/contracts-ui"
    else
        src="$SKILL_SOURCE/ui/minimal-ui"
    fi
    local dst="$UI_DIR"

    if is_contracts_skill_repo && [ "$dst" = "contracts-ui" ] && [ "$UI_FORCE" != true ]; then
        echo -e "${YELLOW}Refusing to install Contracts UI into the contracts-skill repo itself.${NC}"
        echo -e "${GRAY}Tip: run from your project folder, or use --ui-dir test-installation-project/contracts-ui, or pass --ui-force.${NC}"
        return 1
    fi

    if [ ! -d "$src" ]; then
        echo -e "${YELLOW}Contracts UI not found in downloaded skill (${src#$SKILL_SOURCE/}).${NC}"
        return 1
    fi
    if [ -e "$dst" ] && [ "$UI_FORCE" != true ]; then
        echo -e "${YELLOW}Contracts UI already exists at ./$dst (use --ui-force to overwrite).${NC}"
        return 1
    fi
    rm -rf "$dst"
    cp -r "$src" "$dst"

    if [ "$t" = "php-ui" ]; then
        if [ -f "$dst/index.php" ]; then
            echo -e "${GREEN}✓ Installed Contracts UI (php-ui) -> ./$dst${NC}"
            echo -e "${GRAY}Run: php -S localhost:8080 -t $dst${NC}"
            return 0
        fi
        echo -e "${RED}Error: UI install failed (missing index.php).${NC}"
        return 1
    fi

    if [ -f "$dst/index.html" ]; then
        # Best-effort: generate bundle so the UI works via file:// without folder picking.
        if [ -f "$dst/refresh.sh" ]; then
            (cd "$(pwd)" && CONTRACTS_PROJECT_ROOT="$(pwd)" sh "$dst/refresh.sh" >/dev/null 2>&1) || true
        fi
        echo -e "${GREEN}✓ Installed Contracts UI (minimal-ui) -> ./$dst${NC}"
        echo -e "${GRAY}Open: $dst/index.html (auto-loads this project)${NC}"
        return 0
    fi

    echo -e "${RED}Error: UI install failed (missing index.html).${NC}"
    return 1
}

if [ "$INSTALL_UI" = true ]; then
    [ -z "$UI_TYPE" ] && UI_TYPE="minimal-ui"
    [ "$UI_TYPE" = "none" ] && SKIP_UI=true
    install_ui_now || true
elif [ "$SKIP_UI" != true ] && [ -t 0 ]; then
    if is_contracts_skill_repo; then
        echo -e "${GRAY}Note: running inside the contracts-skill repo; skipping UI install prompt.${NC}"
    else
        echo "Install Contracts Web UI into this project?"
        echo "  [1] minimal-ui (browser-only)"
        echo "  [2] php-ui     (PHP)"
        echo "  [3] none"
        read -p "Selection (default: 3): " ui_answer
        case "$ui_answer" in
            1) UI_TYPE="minimal-ui"; install_ui_now || true ;;
            2) UI_TYPE="php-ui"; install_ui_now || true ;;
            *) : ;;
        esac
    fi
fi
