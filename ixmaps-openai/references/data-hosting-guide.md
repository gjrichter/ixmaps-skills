# Data Hosting Guide for ixMaps

Complete guide to hosting data files for ixMaps visualizations.

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Setup GitHub Repository](#setup-github-repository)
4. [Upload Methods](#upload-methods)
5. [URL Formats](#url-formats)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)
8. [Integration with ixMaps Skill](#integration-with-ixmaps-skill)
9. [Appendix](#appendix)

## Overview

### Why Host Data Externally?

**Problems with inline data:**
- Bloats HTML files (100KB+ for moderate datasets)
- Hard to update data without regenerating HTML
- Version control complexity
- Poor browser performance with large datasets

**Benefits of external hosting:**
- Small HTML files (faster loading)
- Update data independently
- Version control for data
- Reuse data across multiple maps
- CORS-enabled access
- CDN acceleration

### Hosting Options Comparison

| Option | Pros | Cons | Best For |
|--------|------|------|----------|
| GitHub + raw URL | Free, simple, version controlled | No CDN, rate limits | Development |
| GitHub + jsDelivr | Free CDN, fast, version controlled | 5-10 min sync delay | Production |
| S3/CloudFront | Full control, instant updates | Costs money, setup complexity | Enterprise |
| Inline | No external dependencies | Large files, hard to update | Demos, small data |

**Recommendation:** GitHub + jsDelivr (this guide's focus)

## Quick Start

### 1. Create Repository

```bash
# On GitHub web:
1. Go to https://github.com/new
2. Name: ixmaps-data
3. Visibility: Public
4. Click "Create repository"
```

### 2. Add Your First Dataset

**Web interface (easiest):**
```
1. Click "Add file" → "Upload files"
2. Create path: by-date/2026-02/
3. Drop your CSV/JSON file
4. Commit changes
```

**Command line:**
```bash
git clone https://github.com/<your-username>/ixmaps-data.git
cd ixmaps-data
mkdir -p by-date/$(date +%Y-%m)
cp ~/cities.csv by-date/$(date +%Y-%m)/
git add .
git commit -m "Add cities dataset"
git push
```

### 3. Get URL

```
Raw (immediate):
https://raw.githubusercontent.com/<user>/ixmaps-data/main/by-date/2026-02/cities.csv

CDN (fast, cached):
https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/2026-02/cities.csv
```

### 4. Use in Map

```javascript
.data({
    url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/2026-02/cities.csv",
    type: "csv"
})
```

## Setup GitHub Repository

### Repository Structure

```
ixmaps-data/
├── README.md                    # Index of datasets
├── by-date/                     # Organized by upload date
│   ├── 2026-02/
│   │   ├── cities-1707834567.csv
│   │   ├── covid-1707834890.json
│   │   └── README.md
│   └── 2026-03/
├── by-project/                  # Named projects
│   ├── mepa-2024/
│   │   ├── data.csv
│   │   ├── metadata.json
│   │   └── README.md
│   └── world-bank/
└── templates/                   # Sample data
    ├── sample-points.csv
    └── sample-geojson.json
```

### Initial Setup Script

```bash
#!/bin/bash
# setup-ixmaps-data.sh

USER="<your-github-username>"

echo "Setting up ixmaps-data repository..."

# Create local structure
mkdir -p ixmaps-data
cd ixmaps-data

# Create directories
mkdir -p by-date/$(date +%Y-%m)
mkdir -p by-project
mkdir -p templates

# Create README
cat > README.md << 'EOF'
# ixMaps Data Repository

Central repository for ixMaps visualization data files.

## Structure

- `by-date/YYYY-MM/` - Datasets organized by upload date
- `by-project/` - Named project datasets
- `templates/` - Sample data files

## Usage

Files in this repository are publicly accessible via:

**Raw GitHub:**
```
https://raw.githubusercontent.com/<user>/ixmaps-data/main/<path>
```

**CDN (recommended):**
```
https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/<path>
```

## Adding Data

### Web Interface
1. Navigate to desired folder
2. Click "Add file" → "Upload files"
3. Drag and drop your file
4. Commit changes

### Command Line
```bash
git clone https://github.com/<user>/ixmaps-data.git
cd ixmaps-data
# Add your files
git add .
git commit -m "Add dataset"
git push
```

## File Formats

Supported formats:
- CSV (.csv)
- JSON (.json)
- GeoJSON (.geojson)
- TopoJSON (.topojson)

## Datasets

### By Date
<!-- Auto-updated list of datasets -->

### By Project
<!-- Named projects with descriptions -->
EOF

# Create sample data
cat > templates/sample-points.csv << 'EOF'
name,lat,lon,value,category
Rome,41.9028,12.4964,2873000,capital
Milan,45.4642,9.1900,1372000,city
Naples,40.8518,14.2681,966000,city
EOF

# Initialize git
git init
git add .
git commit -m "Initial structure"

# Connect to GitHub (user needs to create repo first)
git branch -M main
git remote add origin "https://github.com/${USER}/ixmaps-data.git"

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Create repository at: https://github.com/new"
echo "   Name: ixmaps-data"
echo "   Visibility: Public"
echo ""
echo "2. Push your local structure:"
echo "   git push -u origin main"
echo ""
```

## Upload Methods

### Method 1: GitHub Web Interface (Easiest)

**Best for:** Occasional uploads, non-technical users

**Steps:**
1. Go to https://github.com/<user>/ixmaps-data
2. Navigate to destination folder (e.g., `by-date/2026-02/`)
3. Click "Add file" → "Upload files"
4. Drag and drop your CSV/JSON file
5. Add commit message
6. Click "Commit changes"
7. Copy URL from browser or construct:
   ```
   https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/2026-02/yourfile.csv
   ```

**Pros:** Simple, no tools needed
**Cons:** Manual, slow for many files

### Method 2: Git Command Line

**Best for:** Regular uploads, batch operations

**Setup:**
```bash
# One-time clone
git clone https://github.com/<user>/ixmaps-data.git
cd ixmaps-data
```

**Upload workflow:**
```bash
# Navigate to repo
cd ~/ixmaps-data

# Add file
MONTH=$(date +%Y-%m)
mkdir -p "by-date/$MONTH"
cp ~/Desktop/cities.csv "by-date/$MONTH/"

# Commit and push
git add .
git commit -m "Add cities dataset"
git push

# Get URL
echo "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/$MONTH/cities.csv"
```

**Pros:** Fast, scriptable, batch uploads
**Cons:** Requires git knowledge

### Method 3: GitHub API (Automated)

**Best for:** Automation, ixmaps-claude skill integration

**Setup:**
```bash
# Create fine-grained token at https://github.com/settings/tokens
# Permissions: Contents (Read and Write) for ixmaps-data repo only
export IXMAPS_GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
export IXMAPS_REPO_USER="<your-username>"

# Add to ~/.bashrc or ~/.zshrc for persistence
echo 'export IXMAPS_GITHUB_TOKEN="ghp_xxxxxxxxxxxx"' >> ~/.bashrc
echo 'export IXMAPS_REPO_USER="<your-username>"' >> ~/.bashrc
```

**Upload script:**
```bash
#!/bin/bash
# upload-to-github.sh

FILE="$1"
REPO="$IXMAPS_REPO_USER/ixmaps-data"
MONTH=$(date +%Y-%m)
TIMESTAMP=$(date +%s)
FILENAME=$(basename "$FILE")
BASE="${FILENAME%.*}"
EXT="${FILENAME##*.}"
TIMESTAMPED="${BASE}-${TIMESTAMP}.${EXT}"
PATH="by-date/$MONTH/$TIMESTAMPED"

CONTENT=$(base64 -i "$FILE" | tr -d '\n')

curl -X PUT \
  -H "Authorization: token $IXMAPS_GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"message\": \"Add dataset: $FILENAME\",
    \"content\": \"$CONTENT\"
  }" \
  "https://api.github.com/repos/$REPO/contents/$PATH"

echo ""
echo "Uploaded to:"
echo "https://cdn.jsdelivr.net/gh/$REPO@main/$PATH"
```

**Usage:**
```bash
./upload-to-github.sh ~/cities.csv
```

**Pros:** Fully automated, works from skill
**Cons:** Token management, security considerations

### Method 4: Helper Script (Recommended for Skill)

Use the `upload-helper.sh` provided with the skill:

```bash
# From ixmaps-claude directory:
./upload-helper.sh cities.csv
./upload-helper.sh data.json mepa-2024  # Upload to project folder
```

The script automatically:
- Detects available upload methods
- Chooses best method (API > Git > Manual)
- Generates timestamps
- Provides CDN URLs
- Falls back to manual instructions if needed

## URL Formats

### Raw GitHub URL

```
https://raw.githubusercontent.com/<user>/ixmaps-data/main/<path>
```

**Characteristics:**
- Direct access to file
- Immediate updates (no caching)
- Subject to rate limits (5000 req/hour for authenticated)
- Slower (no CDN)

**Use for:** Development, testing

### jsDelivr CDN URL

```
https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/<path>
```

**Characteristics:**
- Global CDN (fast worldwide)
- Cached (5-10 minutes to sync new files)
- No rate limits
- HTTPS by default
- Free for open-source

**Use for:** Production maps

### Versioned CDN URL

```
https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@v1.0.0/<path>
```

**Characteristics:**
- Pinned to specific release/tag
- Immutable (never changes)
- Long-term caching
- Guaranteed availability

**Use for:** Published maps, stable data

### Comparison

| URL Type | Speed | Cache | Updates | Rate Limits | Use Case |
|----------|-------|-------|---------|-------------|----------|
| Raw | Slow | None | Immediate | Yes (5k/hr) | Development |
| CDN @main | Fast | 5-10 min | ~10 min delay | None | Production |
| CDN @version | Fast | Long-term | Never | None | Published |

## Best Practices

### 1. File Naming

```
Good:
- cities-population.csv
- covid-cases-2024.json
- world-bank-gdp.geojson
- cities-population-1707834567.csv  (with timestamp)

Bad:
- data.csv  (too generic)
- file (1).csv  (spaces, parentheses)
- my data file.json  (spaces)
- Data.CSV  (inconsistent casing)
```

**Rules:**
- Use lowercase
- Use hyphens, not spaces
- Be descriptive
- Include timestamps for versioning
- Use standard extensions

### 2. File Size

```
CSV/JSON size guidelines:
- ✅ < 1 MB: Perfect for GitHub + CDN
- ⚠️  1-10 MB: Acceptable, consider compression
- ❌ > 10 MB: Too large, use alternatives

Alternatives for large data:
- Split into multiple files
- Use TopoJSON (compressed GeoJSON)
- Aggregate data (e.g., grid instead of points)
- Use database + API
```

### 3. Data Organization

```
Recommended structure:

by-date/         # For quick uploads, auto-organized
  2026-02/
    cities-1707834567.csv
    covid-1707834890.json

by-project/      # For important, reusable datasets
  mepa-2024/
    data.csv
    metadata.json
    README.md     # Document the dataset
  world-bank-population/
    countries.json
    regions.json
    README.md
```

**When to use each:**
- `by-date/`: Quick data generation from Claude Code
- `by-project/`: Curated, documented datasets for reuse

### 4. Version Control

```bash
# Use git tags for stable versions
git tag -a v1.0.0 -m "Initial dataset release"
git push origin v1.0.0

# Reference in maps:
url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@v1.0.0/path/to/data.csv"

# Benefits:
- Immutable reference
- Maps never break
- Can update data without affecting published maps
```

### 5. Documentation

Always include README.md in project folders:

```markdown
# Dataset: MEPA 2024 Procurement Data

## Description
Procurement data for Italian public administration (2024).

## Source
- Original: MEPA database (dati.consip.it)
- Processing: Claude Code
- Date: 2024-02-08

## Files
- `data.csv` - Main dataset (109 provinces)
- `metadata.json` - Field descriptions

## Fields
- `Sigla_Provincia` - Province code (e.g., "RM", "MI")
- `Regione` - Region name
- `Valore_Totale_Euro` - Total value in EUR
- `N_Ordini_Totale` - Total number of orders

## Usage
```javascript
.data({
    url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-project/mepa-2024/data.csv",
    type: "csv"
})
```

## License
Public domain (government data)
```

### 6. Security

```bash
# ✅ DO:
- Use fine-grained tokens (not classic tokens)
- Limit token scope to specific repo
- Set token expiration (90 days)
- Store token in environment variable
- Use .gitignore for sensitive data

# ❌ DON'T:
- Commit tokens to git
- Share tokens in chat/code
- Use tokens with broad permissions
- Store passwords/keys in repository
- Include PII in public repository
```

## Troubleshooting

### Problem: 404 Not Found

**Causes:**
1. File not yet pushed to GitHub
2. Wrong file path (case-sensitive)
3. Wrong branch name (main vs master)
4. Repository is private

**Solutions:**
```bash
# Verify file exists
https://github.com/<user>/ixmaps-data/blob/main/<path>

# Check branch
git branch  # Should show 'main'

# Check path (case-sensitive)
ls -la by-date/2026-02/  # Exact filename
```

### Problem: CORS Error

**Cause:** File served from non-CORS enabled source

**Solutions:**
- Use GitHub URLs (CORS enabled)
- Check repository is public
- Don't use file:// URLs

### Problem: CDN Not Updating

**Cause:** jsDelivr cache delay (5-10 minutes)

**Solutions:**
```javascript
// Development: Use raw URL
url: "https://raw.githubusercontent.com/<user>/ixmaps-data/main/<path>"

// Development: Cache bust
url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/<path>?v=" + Date.now()

// Production: Wait or use version tags
url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@v1.0.1/<path>"
```

### Problem: Rate Limits (Raw URL)

**Error:** "API rate limit exceeded"

**Solutions:**
- Switch to CDN URLs (no rate limits)
- Authenticate requests (5000/hr limit)
- Wait for rate limit reset (1 hour)

### Problem: Token Authentication Failed

**Causes:**
1. Token expired
2. Wrong permissions
3. Token not in environment

**Solutions:**
```bash
# Check token
echo $IXMAPS_GITHUB_TOKEN

# Verify permissions
# Go to https://github.com/settings/tokens
# Check: Contents (Read and Write)

# Re-export
export IXMAPS_GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
```

### Problem: File Too Large

**Error:** "file exceeds maximum size"

**GitHub limits:** 100 MB per file

**Solutions:**
1. Compress data:
   ```bash
   # Convert GeoJSON to TopoJSON (smaller)
   geo2topo data.geojson > data.topojson
   ```

2. Split file:
   ```bash
   # Split CSV into chunks
   split -l 10000 large.csv chunk-
   ```

3. Aggregate data:
   - Use grid aggregation instead of individual points
   - Reduce precision (coordinates)
   - Remove unnecessary fields

4. Alternative hosting:
   - Use S3 for large files
   - Consider database + API

## Integration with ixMaps Skill

### Workflow in Claude Code

```
1. User requests map with data
   ↓
2. Skill generates CSV/JSON file
   ↓
3. Skill checks for IXMAPS_GITHUB_TOKEN
   ↓
4a. If token exists:           4b. If no token:
    - Upload via API               - Save file locally
    - Get CDN URL                  - Provide manual upload instructions
    - Create HTML with URL         - Create HTML with placeholder or inline
   ↓                               ↓
5. Present options to user:
   - View generated HTML
   - Upload data (if not done)
   - Get URLs for reference
```

### Example: Skill Execution

```bash
# User: "Create a bubble map of Italian cities by population"

# Skill generates:
1. cities-population.csv (local file)
2. cities-map.html (HTML visualization)

# If token configured:
3. Uploads cities-population-1707834567.csv to GitHub
4. Updates HTML with CDN URL
5. Reports:
   "✓ Map created: cities-map.html
    ✓ Data hosted: https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/2026-02/cities-population-1707834567.csv

    Your map is ready to use!"

# If no token:
3. Reports:
   "✓ Map created: cities-map.html (with inline data)
    ✓ Data file: cities-population.csv

    For production use, upload data to GitHub:
    1. Go to https://github.com/<user>/ixmaps-data
    2. Upload cities-population.csv to by-date/2026-02/
    3. Update HTML data URL to:
       https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/2026-02/cities-population.csv"
```

## Appendix

### A. Complete Setup Checklist

- [ ] Create GitHub account (if needed)
- [ ] Create public repository: ixmaps-data
- [ ] Clone repository locally
- [ ] Create directory structure (by-date, by-project)
- [ ] Add README.md
- [ ] Push initial structure
- [ ] (Optional) Create fine-grained token
- [ ] (Optional) Set environment variables
- [ ] Test upload (manual or script)
- [ ] Verify CDN access
- [ ] Create first map with hosted data

### B. Token Permissions

When creating GitHub fine-grained token:

**Repository access:**
- Only select repositories
- Choose: ixmaps-data

**Permissions:**
- Contents: Read and write
- Metadata: Read-only (automatic)

**Expiration:**
- 90 days (recommended)
- Set calendar reminder to renew

**Note:** After 90 days, create new token and update environment variable.

### C. Sample Data Templates

Create these in `templates/` folder:

**sample-points.csv:**
```csv
name,lat,lon,value,category
Rome,41.9028,12.4964,2873000,capital
Milan,45.4642,9.1900,1372000,city
Naples,40.8518,14.2681,966000,city
```

**sample-geojson.json:**
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [12.4964, 41.9028]
      },
      "properties": {
        "name": "Rome",
        "population": 2873000,
        "category": "capital"
      }
    }
  ]
}
```

### D. Alternative CDNs

If jsDelivr is unavailable:

**GitHub raw (no CDN):**
```
https://raw.githubusercontent.com/<user>/ixmaps-data/main/<path>
```

**Statically.io:**
```
https://cdn.statically.io/gh/<user>/ixmaps-data/main/<path>
```

**GitCDN:**
```
https://gitcdn.xyz/repo/<user>/ixmaps-data/main/<path>
```

**Recommendation:** Stick with jsDelivr (most reliable, fastest)

### E. Cost Analysis

**GitHub + jsDelivr:**
- Cost: $0
- Storage: Unlimited (for reasonable use)
- Bandwidth: Unlimited
- Rate limits: None (CDN)

**S3 + CloudFront (for comparison):**
- S3 storage: ~$0.023/GB/month
- CloudFront: ~$0.085/GB transfer
- Example: 10GB data, 1000 requests/day:
  - Storage: $0.23/month
  - Transfer: ~$2.55/month
  - Total: ~$2.78/month

**Verdict:** GitHub + jsDelivr is free and sufficient for most use cases.

## Summary

**Recommended approach:**
1. Create public GitHub repository: `ixmaps-data`
2. Organize with `by-date/` and `by-project/` folders
3. Upload via web interface (easy) or git (power users)
4. Use CDN URLs in production: `cdn.jsdelivr.net`
5. Optional: Set up token for automation

**Key URLs to remember:**
```
Repository: https://github.com/<user>/ixmaps-data
Upload: https://github.com/<user>/ixmaps-data/upload/main
CDN: https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/<path>
```

**For help:**
- GitHub docs: https://docs.github.com
- jsDelivr docs: https://www.jsdelivr.com/github
- ixMaps docs: See SKILL.md, EXAMPLES.md
