#!/bin/bash
# Upload Helper Script for ixMaps Data Repository
# Intelligently uploads data files to GitHub ixmaps-data repository
# Tries: GitHub API → Git commands → Manual instructions

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Parse arguments
DATA_FILE="$1"
PROJECT_NAME="$2"

# Validate input
if [ -z "$DATA_FILE" ]; then
    echo "Upload Helper for ixMaps Data Repository"
    echo ""
    echo "Usage: $0 <data-file> [project-name]"
    echo ""
    echo "Examples:"
    echo "  $0 cities.csv                 # Upload to by-date/YYYY-MM/"
    echo "  $0 data.json mepa-2024        # Upload to by-project/mepa-2024/"
    echo ""
    echo "Setup (for automated upload):"
    echo "  export IXMAPS_GITHUB_TOKEN=\"ghp_xxxxxxxxxxxx\""
    echo "  export IXMAPS_REPO_USER=\"<your-username>\""
    echo ""
    exit 1
fi

if [ ! -f "$DATA_FILE" ]; then
    error "File not found: $DATA_FILE"
    exit 1
fi

# Get file information
FILENAME=$(basename "$DATA_FILE")
BASE="${FILENAME%.*}"
EXT="${FILENAME##*.}"
FILESIZE=$(du -h "$DATA_FILE" | cut -f1)

# Generate timestamp
MONTH=$(date +%Y-%m)
TIMESTAMP=$(date +%s)

# Determine upload path
if [ -n "$PROJECT_NAME" ]; then
    UPLOAD_PATH="by-project/${PROJECT_NAME}/${FILENAME}"
    info "Project upload: $PROJECT_NAME/$FILENAME"
else
    TIMESTAMPED_NAME="${BASE}-${TIMESTAMP}.${EXT}"
    UPLOAD_PATH="by-date/${MONTH}/${TIMESTAMPED_NAME}"
    info "Date-based upload: by-date/$MONTH/$TIMESTAMPED_NAME"
fi

info "File: $FILENAME ($FILESIZE)"
echo ""

# ========================================
# METHOD 1: GitHub API (if token available)
# ========================================

if [ -n "$IXMAPS_GITHUB_TOKEN" ] && [ -n "$IXMAPS_REPO_USER" ]; then
    info "Attempting GitHub API upload..."

    # Encode file content to base64
    if command -v base64 &> /dev/null; then
        CONTENT=$(base64 -i "$DATA_FILE" | tr -d '\n')
    else
        error "base64 command not found. Install coreutils."
        CONTENT=""
    fi

    if [ -n "$CONTENT" ]; then
        # Upload via GitHub API
        RESPONSE=$(curl -s -X PUT \
            -H "Authorization: token $IXMAPS_GITHUB_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"message\": \"Add dataset: $FILENAME\",
                \"content\": \"$CONTENT\"
            }" \
            "https://api.github.com/repos/${IXMAPS_REPO_USER}/ixmaps-data/contents/$UPLOAD_PATH")

        # Check if upload succeeded
        if echo "$RESPONSE" | grep -q '"sha"'; then
            success "Upload successful via GitHub API!"
            echo ""
            echo "Raw URL (immediate access):"
            echo "https://raw.githubusercontent.com/${IXMAPS_REPO_USER}/ixmaps-data/main/$UPLOAD_PATH"
            echo ""
            echo "CDN URL (recommended for production, cached):"
            echo "https://cdn.jsdelivr.net/gh/${IXMAPS_REPO_USER}/ixmaps-data@main/$UPLOAD_PATH"
            echo ""
            success "Your data is now hosted and ready to use!"
            echo ""
            info "CDN cache: Allow 5-10 minutes for jsDelivr to sync"
            info "Use raw URL for immediate testing, CDN URL for production"
            exit 0
        else
            # Check for specific errors
            if echo "$RESPONSE" | grep -q "already exists"; then
                error "File already exists at this path"
                warning "Rename file or use a different path"
            elif echo "$RESPONSE" | grep -q "rate limit"; then
                error "GitHub API rate limit exceeded"
                warning "Wait an hour or try git method"
            elif echo "$RESPONSE" | grep -q "Bad credentials"; then
                error "Token authentication failed"
                warning "Check IXMAPS_GITHUB_TOKEN is valid"
            else
                error "API upload failed"
                if echo "$RESPONSE" | grep -q "message"; then
                    echo "$RESPONSE" | grep -o '"message":"[^"]*"' | cut -d'"' -f4
                fi
            fi
            warning "Trying git method..."
            echo ""
        fi
    fi
fi

# ========================================
# METHOD 2: Git (if repo cloned locally)
# ========================================

if [ -d "$HOME/ixmaps-data/.git" ]; then
    info "Found local ixmaps-data repository"
    info "Using git commands..."

    # Create directory if needed
    mkdir -p "$HOME/ixmaps-data/$(dirname "$UPLOAD_PATH")"

    # Copy file
    cp "$DATA_FILE" "$HOME/ixmaps-data/$UPLOAD_PATH"
    success "File copied to repository"

    # Git add and commit
    cd "$HOME/ixmaps-data"
    git add "$UPLOAD_PATH"
    git commit -m "Add dataset: $FILENAME" > /dev/null 2>&1

    success "File committed to git"
    echo ""
    warning "You need to push manually:"
    echo ""
    echo "  cd ~/ixmaps-data && git push"
    echo ""
    echo "After pushing, your data will be available at:"
    echo ""
    echo "Raw URL:"
    echo "https://raw.githubusercontent.com/${IXMAPS_REPO_USER:-<user>}/ixmaps-data/main/$UPLOAD_PATH"
    echo ""
    echo "CDN URL (recommended):"
    echo "https://cdn.jsdelivr.net/gh/${IXMAPS_REPO_USER:-<user>}/ixmaps-data@main/$UPLOAD_PATH"
    echo ""
    exit 0
fi

# ========================================
# METHOD 3: Manual instructions (fallback)
# ========================================

warning "No automated upload method available"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MANUAL UPLOAD INSTRUCTIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open your repository:"
echo "   https://github.com/<your-username>/ixmaps-data"
echo ""
echo "2. Navigate to folder:"
if [ -n "$PROJECT_NAME" ]; then
    echo "   by-project/$PROJECT_NAME/"
else
    echo "   by-date/$MONTH/"
fi
echo ""
echo "3. Click: 'Add file' → 'Upload files'"
echo ""
echo "4. Drag and drop file:"
echo "   $FILENAME"
echo ""
echo "5. Commit changes"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "After upload, your data will be available at:"
echo ""
echo "Raw URL (immediate):"
echo "https://raw.githubusercontent.com/<your-username>/ixmaps-data/main/$UPLOAD_PATH"
echo ""
echo "CDN URL (fast, cached):"
echo "https://cdn.jsdelivr.net/gh/<your-username>/ixmaps-data@main/$UPLOAD_PATH"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "For automated uploads, set up authentication:"
echo ""
echo "  export IXMAPS_GITHUB_TOKEN=\"ghp_xxxxxxxxxxxx\""
echo "  export IXMAPS_REPO_USER=\"<your-username>\""
echo ""
echo "  # Create token at: https://github.com/settings/tokens"
echo "  # Permissions: Contents (Read and Write) for ixmaps-data repo"
echo ""
echo "  # Add to ~/.bashrc or ~/.zshrc for persistence"
echo ""
info "See DATA_HOSTING_GUIDE.md for complete setup instructions"
echo ""
