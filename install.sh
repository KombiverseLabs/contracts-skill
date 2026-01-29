#!/bin/bash
#
# Contracts Skill Installer
# One-liner: curl -fsSL https://raw.githubusercontent.com/KombiverseLabs/contracts-skill/main/install.sh | bash
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
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN} Contracts Skill Installer${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Parse arguments
SCOPE="project"
INIT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            SCOPE="global"
            shift
            ;;
        --init|-i)
            INIT=true
            shift
            ;;
        --help|-h)
            echo "Usage: install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --global, -g    Install globally (~/.copilot/skills/)"
            echo "  --init, -i      Run initialization after install"
            echo "  --help, -h      Show this help"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Determine target directory
if [ "$SCOPE" = "global" ]; then
    TARGET_DIR="$HOME/.copilot/skills/$SKILL_NAME"
    echo -e "${YELLOW}Installing globally to: $TARGET_DIR${NC}"
else
    TARGET_DIR="./.agent/skills/$SKILL_NAME"
    echo -e "${YELLOW}Installing to project: $TARGET_DIR${NC}"
fi

# Check if already installed
if [ -d "$TARGET_DIR" ]; then
    echo ""
    echo -e "${YELLOW}Skill already installed at: $TARGET_DIR${NC}"
    read -p "Overwrite? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled.${NC}"
        exit 0
    fi
    rm -rf "$TARGET_DIR"
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo ""
echo -e "${CYAN}Downloading from GitHub...${NC}"

# Try git clone first
if command -v git &> /dev/null; then
    if git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$TEMP_DIR/repo" 2>/dev/null; then
        echo -e "${GREEN}Downloaded via git clone${NC}"
        SOURCE_DIR="$TEMP_DIR/repo"
    else
        echo -e "${YELLOW}Git clone failed, trying ZIP...${NC}"
        SOURCE_DIR=""
    fi
else
    SOURCE_DIR=""
fi

# Fallback to ZIP download
if [ -z "$SOURCE_DIR" ]; then
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
    SOURCE_DIR="$TEMP_DIR/$REPO_NAME-$BRANCH"
    echo -e "${GREEN}Downloaded via ZIP${NC}"
fi

# Find skill folder
SKILL_SOURCE=""
if [ -d "$SOURCE_DIR/skill" ]; then
    SKILL_SOURCE="$SOURCE_DIR/skill"
elif [ -d "$SOURCE_DIR/.agent/skills/contracts" ]; then
    SKILL_SOURCE="$SOURCE_DIR/.agent/skills/contracts"
else
    echo -e "${RED}Error: Could not find skill folder${NC}"
    exit 1
fi

# Create parent directory
mkdir -p "$(dirname "$TARGET_DIR")"

# Copy skill
echo ""
echo -e "${CYAN}Installing skill...${NC}"
cp -r "$SKILL_SOURCE" "$TARGET_DIR"

# Verify
if [ -f "$TARGET_DIR/SKILL.md" ]; then
    echo -e "${GREEN}Verification: SKILL.md found ✓${NC}"
else
    echo -e "${YELLOW}Warning: SKILL.md not found${NC}"
fi

echo -e "${GREEN}Skill installed to: $TARGET_DIR${NC}"

# Run initialization if requested
if [ "$INIT" = true ]; then
    echo ""
    echo -e "${CYAN}Running initialization...${NC}"
    INIT_SCRIPT="$TARGET_DIR/scripts/init-contracts.ps1"
    if [ -f "$INIT_SCRIPT" ]; then
        if command -v pwsh &> /dev/null; then
            pwsh "$INIT_SCRIPT" -Path "."
        else
            echo -e "${YELLOW}PowerShell (pwsh) not found. Run manually:${NC}"
            echo "  pwsh $INIT_SCRIPT -Path \".\""
        fi
    fi
fi

# Success
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Initialize contracts:"
echo -e "     ${CYAN}pwsh $TARGET_DIR/scripts/init-contracts.ps1 -Path \".\"${NC}"
echo ""
echo "  2. Or ask your AI assistant:"
echo -e "     ${CYAN}\"Initialize contracts for this project\"${NC}"
echo ""
