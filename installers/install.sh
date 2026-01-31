#!/bin/bash
#
# Contracts Skill Installer with Agent Selection
# One-liner: curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/installers/install.sh | bash
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
NC='\033[0m' # No Color

# Print header
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN} Contracts Skill Installer${NC}"
echo -e "${CYAN} Spec-Driven Development for AI Assistants${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Parse arguments
AGENTS=""
AUTO=false
INIT=false
INSTALL_UI=false
UI_TYPE=""
UI_DIR="contracts-ui"
UI_FORCE=false
SKIP_UI=false
UI_AUTOSTART="ask"   # ask | on | off | once
START_UI=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --agents)
            AGENTS="$2"
            shift 2
            ;;
        --auto|-a)
            AUTO=true
            shift
            ;;
        --init|-i)
            INIT=true
            shift
            ;;
        --ui|-u)
            INSTALL_UI=true
            # optional: --ui minimal-ui|php-ui|none
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
        --ui-autostart)
            UI_AUTOSTART="$2"
            INSTALL_UI=true
            shift 2
            ;;
        --start-ui)
            START_UI=true
            INSTALL_UI=true
            shift
            ;;
        --no-ui)
            SKIP_UI=true
            shift
            ;;
        --help|-h)
            echo "Usage: install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --agents <list>  Comma-separated agent IDs (e.g., copilot,claude,cursor)"
            echo "  --auto, -a       Install to all detected agents without prompting"
            echo "  --init, -i       Run initialization after install"
            echo "  --ui, -u         Install minimal Contracts Web UI into this project"
            echo "                 (optional arg: minimal-ui|php-ui|none)"
            echo "  --ui-type <t>    UI type: minimal-ui | php-ui | none"
            echo "  --ui-dir <dir>   Target directory for UI (default: contracts-ui)"
            echo "  --ui-force       Overwrite existing UI directory"
            echo "  --ui-autostart <m>  UI auto-start: ask | on | off | once"
            echo "  --start-ui         Start the UI immediately after install"
            echo "  --no-ui          Do not prompt for UI"
            echo "  --help, -h       Show this help"
            echo ""
            echo "Agent IDs: copilot, claude, cursor, windsurf, aider, cline, local"
            exit 0
            ;;
        *)
            echo -e "${YELLOW}Unknown option: $1${NC}"
            shift
            ;;
    esac
done

# Agent configurations
declare -A AGENT_NAMES
declare -A AGENT_PATHS
declare -A AGENT_ICONS
declare -A AGENT_DETECT_PATHS

# GitHub Copilot
AGENT_NAMES["copilot"]="GitHub Copilot (VS Code)"
AGENT_PATHS["copilot"]="./.github/skills/$SKILL_NAME"
AGENT_ICONS["copilot"]="🤖"
AGENT_DETECT_PATHS["copilot"]="$HOME/.copilot:$HOME/.config/Code/User/settings.json"

# Claude
AGENT_NAMES["claude"]="Claude Code"
AGENT_PATHS["claude"]="$HOME/.claude/skills/$SKILL_NAME"
AGENT_ICONS["claude"]="🧠"
AGENT_DETECT_PATHS["claude"]="$HOME/.claude:$HOME/Library/Application Support/Claude"

# Cursor
AGENT_NAMES["cursor"]="Cursor"
AGENT_PATHS["cursor"]="$HOME/.cursor/skills/$SKILL_NAME"
AGENT_ICONS["cursor"]="⚡"
AGENT_DETECT_PATHS["cursor"]="$HOME/.cursor:$HOME/Library/Application Support/Cursor"

# Windsurf
AGENT_NAMES["windsurf"]="Windsurf (Codeium)"
AGENT_PATHS["windsurf"]="$HOME/.windsurf/skills/$SKILL_NAME"
AGENT_ICONS["windsurf"]="🏄"
AGENT_DETECT_PATHS["windsurf"]="$HOME/.windsurf:$HOME/.codeium"

# Cline
AGENT_NAMES["cline"]="Cline"
AGENT_PATHS["cline"]="$HOME/.cline/skills/$SKILL_NAME"
AGENT_ICONS["cline"]="📟"
AGENT_DETECT_PATHS["cline"]="$HOME/.cline"

# OpenCode
AGENT_NAMES["opencode"]="OpenCode"
AGENT_PATHS["opencode"]="$HOME/.opencode/skills/$SKILL_NAME"
AGENT_ICONS["opencode"]="🔓"
AGENT_DETECT_PATHS["opencode"]="$HOME/.opencode:$HOME/Library/Application Support/OpenCode"

# Aider
AGENT_NAMES["aider"]="Aider"
AGENT_PATHS["aider"]="$HOME/.aider/skills/$SKILL_NAME"
AGENT_ICONS["aider"]="🔧"
AGENT_DETECT_PATHS["aider"]="$HOME/.aider:$HOME/.aider.conf.yml"

# Project Local
AGENT_NAMES["local"]="Project Local (.agent)"
AGENT_PATHS["local"]="./.agent/skills/$SKILL_NAME"
AGENT_ICONS["local"]="📁"
AGENT_DETECT_PATHS["local"]="./.agent:./package.json:./.git"

# Detection function
detect_agent() {
    local agent=$1
    local paths="${AGENT_DETECT_PATHS[$agent]}"
    
    IFS=':' read -ra PATH_ARRAY <<< "$paths"
    for p in "${PATH_ARRAY[@]}"; do
        if [ -e "$p" ]; then
            return 0
        fi
    done
    return 1
}

# Check if skill is installed
check_installed() {
    local path=$1
    [ -f "$path/SKILL.md" ] && return 0
    return 1
}

# Scan for agents
echo -e "${CYAN}Scanning for AI coding assistants...${NC}"
echo ""

DETECTED=()
INSTALLED=()

for agent in copilot claude cursor windsurf cline aider local; do
    path="${AGENT_PATHS[$agent]}"
    name="${AGENT_NAMES[$agent]}"
    icon="${AGENT_ICONS[$agent]}"
    
    if check_installed "$path"; then
        echo -e "  ${icon} ${name}: ${GREEN}[INSTALLED]${NC}"
        INSTALLED+=("$agent")
    elif detect_agent "$agent" || [ "$agent" == "local" ]; then
        echo -e "  ${icon} ${name}: ${YELLOW}[DETECTED]${NC}"
        DETECTED+=("$agent")
    else
        echo -e "  ${icon} ${name}: ${GRAY}[NOT FOUND]${NC}"
    fi
done

echo ""

# Show already installed
if [ ${#INSTALLED[@]} -gt 0 ]; then
    echo -e "${GREEN}Already installed:${NC}"
    for agent in "${INSTALLED[@]}"; do
        echo -e "  ${GRAY}✓ ${AGENT_NAMES[$agent]} → ${AGENT_PATHS[$agent]}${NC}"
    done
    echo ""
fi

# Determine which agents to install to
SELECTED=()

# If --agents specified
if [ -n "$AGENTS" ]; then
    IFS=',' read -ra AGENT_LIST <<< "$AGENTS"
    for requested in "${AGENT_LIST[@]}"; do
        agent=$(echo "$requested" | tr -d ' ')
        # Check if this agent was detected
        for detected in "${DETECTED[@]}"; do
            if [ "$detected" == "$agent" ]; then
                SELECTED+=("$agent")
                break
            fi
        done
    done
# If --auto specified
elif [ "$AUTO" = true ]; then
    SELECTED=("${DETECTED[@]}")
# Interactive selection
else
    if [ ${#DETECTED[@]} -eq 0 ]; then
        echo -e "${YELLOW}No new agents to install to.${NC}"
        echo ""
        echo -e "${CYAN}Tip: Run this in a project directory to install locally to .agent/skills/${NC}"
        exit 0
    fi
    
    echo "Select agents to install to:"
    echo ""
    
    idx=1
    for agent in "${DETECTED[@]}"; do
        echo "  [$idx] ${AGENT_ICONS[$agent]} ${AGENT_NAMES[$agent]}"
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
                if [ $idx -ge 0 ] && [ $idx -lt ${#DETECTED[@]} ]; then
                    SELECTED+=("${DETECTED[$idx]}")
                fi
            fi
        done
    fi
fi

if [ ${#SELECTED[@]} -eq 0 ]; then
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

if [ -z "$SKILL_SOURCE" ]; then
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

if [ ! -d "$SKILL_SOURCE" ]; then
    echo -e "${RED}Error: Could not find skill folder${NC}"
    exit 1
fi

echo ""

# Install to each agent
SUCCESS_COUNT=0

for agent in "${SELECTED[@]}"; do
    target="${AGENT_PATHS[$agent]}"
    name="${AGENT_NAMES[$agent]}"
    
    echo -n "  Installing to $name..."
    
    # Create parent directory
    mkdir -p "$(dirname "$target")"
    
    # Remove existing and copy new
    rm -rf "$target"
    cp -r "$SKILL_SOURCE" "$target"
    
    if [ -f "$target/SKILL.md" ]; then
        echo -e " ${GREEN}✓${NC}"
        ((SUCCESS_COUNT++))
        
        # Add instruction hook for local install
        if [ "$agent" == "local" ]; then
            if [ ! -f ".github/copilot-instructions.md" ]; then
                mkdir -p ".github"
                cat > ".github/copilot-instructions.md" << 'EOF'
## Contracts System
Before starting any task that changes code, determine the target module(s) (by path) and locate the nearest CONTRACT.md.
Read CONTRACT.md + CONTRACT.yaml for those module(s) and check for drift (source_hash vs current hash).
If drift exists, stop and sync CONTRACT.yaml first.
Before editing, summarize the relevant MUST / MUST NOT constraints to the user in max 5 sentences.
Never edit CONTRACT.md directly - it is user-owned.
EOF
                echo -e "    ${GRAY}→ Created .github/copilot-instructions.md${NC}"
            fi
        fi
    else
        echo -e " ${RED}✗ Failed${NC}"
    fi
done

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
if [ $SUCCESS_COUNT -eq ${#SELECTED[@]} ]; then
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

# Optional: install minimal web UI
is_contracts_skill_repo() {
    [ -f "./skill/SKILL.md" ] && [ -f "./installers/install.sh" ] && [ -f "./setup.sh" ]
}

install_ui_now() {
    local t="$UI_TYPE"
    if [ -z "$t" ]; then t="minimal-ui"; fi
    if [ "$t" = "none" ]; then return 0; fi

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
        echo -e "${YELLOW}Contracts UI not found in downloaded skill (ui/contracts-ui).${NC}"
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

    if [ -f "$dst/index.php" ]; then
        # Back-compat if someone still has the old php-ui folder copied
        echo -e "${GREEN}✓ Installed Contracts UI -> ./$dst${NC}"
        echo -e "${GRAY}Run: php -S localhost:8080 -t $dst${NC}"
        return 0
    fi

    if [ -f "$dst/index.html" ]; then
        # Best-effort: generate bundle so the UI works via file:// without folder picking.
        if [ -f "$dst/refresh.sh" ]; then
            (cd "$(pwd)" && CONTRACTS_PROJECT_ROOT="$(pwd)" sh "$dst/refresh.sh" >/dev/null 2>&1) || true
        fi
        echo -e "${GREEN}✓ Installed Contracts UI (minimal-ui) -> ./$dst${NC}"

                # Default config (best-effort)
                if [ ! -f "$dst/contracts-ui.config.json" ]; then
                    cat > "$dst/contracts-ui.config.json" <<'JSON'
{
    "autoStart": false,
    "port": 8787,
    "openBrowser": true,
    "projectRoot": "."
}
JSON
                fi

                echo -e "${GRAY}Start (recommended): ./$dst/start.sh${NC}"
                echo -e "${GRAY}Open (snapshot, read-only): $dst/index.html${NC}"

                local mode="$UI_AUTOSTART"
                if [ "$mode" = "ask" ] && [ -t 0 ]; then
                    echo ""
                    echo "Configure Contracts UI auto-start?"
                    echo "  [1] off (default)"
                    echo "  [2] start once (do not remember)"
                    echo "  [3] on (auto-start on init-contracts)"
                    read -p "Selection (default: 1): " m
                    case "$m" in
                        2) mode="once" ;;
                        3) mode="on" ;;
                        *) mode="off" ;;
                    esac
                fi

                if [ "$mode" = "on" ] || [ "$mode" = "off" ]; then
                    node -e "const fs=require('fs');const p=process.argv[1];const j=JSON.parse(fs.readFileSync(p,'utf8'));j.autoStart=(process.argv[2]==='on');fs.writeFileSync(p,JSON.stringify(j,null,2));" "$dst/contracts-ui.config.json" "$mode" >/dev/null 2>&1 || true
                fi

                local start_now=false
                if [ "$START_UI" = true ] || [ "$mode" = "once" ] || [ "$mode" = "on" ]; then
                    start_now=true
                fi

                if [ "$start_now" = true ] && [ -f "$dst/start.sh" ]; then
                    (sh "$dst/start.sh" >/dev/null 2>&1) || true
                fi

        return 0
    fi

    echo -e "${RED}Error: UI install failed (missing index.html).${NC}"
    return 1
}

if [ "$INSTALL_UI" = true ]; then
    if [ -z "$UI_TYPE" ]; then UI_TYPE="minimal-ui"; fi
    if [ "$UI_TYPE" = "none" ]; then
        SKIP_UI=true
    fi
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

# Run initialization if requested
if [ "$INIT" = true ]; then
    echo ""
    echo -e "${CYAN}Running initialization...${NC}"
    
    # Check if local install exists
    if [ -f "./.agent/skills/$SKILL_NAME/ai/init-agent/index.js" ]; then
        node "./.agent/skills/$SKILL_NAME/ai/init-agent/index.js" --path . --analyze
    fi
fi
