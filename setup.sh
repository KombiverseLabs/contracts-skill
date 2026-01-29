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
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto|-a)
            AUTO=true
            shift
            ;;
        --help|-h)
            echo "Usage: setup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --auto, -a    Install to all detected agents without prompting"
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
AGENT_PATHS["copilot"]="$HOME/.copilot/skills/$SKILL_NAME"
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
