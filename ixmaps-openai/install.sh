#!/bin/bash
# ixMaps Claude Skill Installation Script

set -e

echo "🗺️  Installing ixMaps Claude Skill..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Claude Code skills directory exists
SKILLS_DIR="$HOME/.claude/skills"
SKILL_NAME="create-ixmap"
SKILL_PATH="$SKILLS_DIR/$SKILL_NAME"

if [ ! -d "$SKILLS_DIR" ]; then
    echo -e "${RED}Error: Claude Code skills directory not found at $SKILLS_DIR${NC}"
    echo "Please make sure Claude Code is installed."
    exit 1
fi

echo -e "${BLUE}Creating skill directory...${NC}"
mkdir -p "$SKILL_PATH"

echo -e "${BLUE}Copying skill files...${NC}"
cp SKILL.md "$SKILL_PATH/"
cp template.html "$SKILL_PATH/"

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo "The skill has been installed to: $SKILL_PATH"
echo ""
echo "Usage:"
echo "  In Claude Code, type: /create-ixmap"
echo ""
echo "Examples:"
echo "  /create-ixmap"
echo "  /create-ixmap filename=my_map.html title=\"My Custom Map\""
echo ""
echo "For more information, see README.md"
echo ""
echo "🎉 Happy mapping!"
