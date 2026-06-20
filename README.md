# ixMaps Skills

This repository provides ixMaps skills for different assistants plus templates and examples. In the subfolders you will find tool-specific skills for **Claude Code** and **Codex**. For chat usage, use the general `SKILL.md` described below.

These **skills** enable **AI assistants** to create **ixMaps maps** in **HTML documents**. These documents load the **`ixmaps-flat`** framework and are executable in any **HTML5**-capable browser.

---

## Using SKILL.md in Chat

### 1) Load the skill into the chat

Pick one method:

#### Method A: Share the raw GitHub URL
1. Paste this message into your chat:
```
Please read and follow the ixmaps skill specifications from:
https://raw.githubusercontent.com/gjrichter/ixmaps-skills/main/SKILL.md
```
2. Wait for confirmation that the skill is loaded.

#### Method B: Upload the file
1. Download `SKILL.md` from the repository.
2. Upload it to your chat.
3. Say: "Please follow these specifications to create ixmaps."

#### Method C: Copy/paste
1. Open `SKILL.md`.
2. Copy the full content.
3. Paste it into your chat and confirm the assistant should follow it.

### 2) Ask for a map

Start with a clear request and include data or a URL when possible:

```
Create a bubble map of Italian cities sized by population.
Use this data:
[{"name":"Rome","lat":41.9,"lon":12.5,"population":2873000},
 {"name":"Milan","lat":45.46,"lon":9.19,"population":1372000}]
```

### 3) Iterate

Refine the result with short follow-ups:

```
Change the base map to "CartoDB - Positron".
Make the bubbles 2x larger.
Use the tableau palette for categories.
```

### Tips

- Be explicit about field names (e.g., `lat`, `lon`, `population`).
- For GeoJSON/TopoJSON, specify the property field used for labeling or coloring.
- If the assistant doesn't follow the rules, re-share `SKILL.md` in the same chat.

---

## Claude Code Skill

Interactive map creation skill using the ixMaps framework.

## Overview

This skill enables Claude to generate complete HTML files with interactive geographic visualizations. It supports point data, GeoJSON, TopoJSON, and various visualization types including bubble charts, choropleth maps, pie charts, and density heatmaps.

## Quick Start

```bash
/create-ixmap filename=mymap.html title="My Map" viztype=BUBBLE
```

## Files in This Directory

### Core Skill Files

- **skill-ui.yaml** ⭐ - UI configuration and parameter definitions
  - Complete parameter specifications
  - Validation rules
  - Presets for common use cases
  - Wizard definitions
  - CLI aliases
  - Enables auto-generated UIs and validation

### Documentation Files

- **SKILL.md** - Main skill instructions (~1,600 lines)
  - Critical rules + silent-failure hotspots highlighted at top
  - Decision tree for choosing visualization types
  - Core patterns inline; deeper detail delegated to the reference files below
  - All essential information for Claude

- **EXAMPLES.md** - Complete working examples (28 examples)
  - Point data examples
  - GeoJSON/TopoJSON examples
  - Aggregation examples
  - Multi-layer maps
  - Custom styling examples

- **API_REFERENCE.md** - Complete API documentation
  - All methods and properties
  - Parameter descriptions
  - Valid values and formats
  - Quick reference card

- **TROUBLESHOOTING.md** - Common issues and solutions
  - Debugging checklist
  - Error message explanations
  - Performance tips
  - Browser compatibility

- **RUNTIME_CONTROLS.md** - Interactive controls (filters, region selector, hide/show, mark class, `.on()` events, URL sync)
- **FACETS_GUIDE.md** - Facet sidebar + overlay-indicator layer patterns
- **CSS_INTEROP.md** - Avoiding/repairing Bootstrap & dark-basemap CSS conflicts

- **README.md** - This file
- **MAP_TYPES_GUIDE.md** - Valid basemaps & projections reference
- **SYMBOLS_GUIDE.md** - Symbol/icon reference for chart layers
- **DATA_JS_GUIDE.md** - Data preprocessing with data.js (`Data.*` helpers)
- **DATA_HOSTING_GUIDE.md** - Hosting data on a CDN/host for `url:` layers
- **example-multi-layer-join.md** - Worked TopoJSON + CSV join example
- **UI_YAML_GUIDE.md** - Guide to using skill-ui.yaml
- **CHANGELOG.md** - Version history

### Utility Files

- **validate-config.js** - Configuration validator (uses skill-ui.yaml)
- **upload-helper.sh** - Shell helper for uploading data to a CDN/host (see DATA_HOSTING_GUIDE.md)

> Both utility files run via the `Bash` tool (now included in the skill's `allowed-tools`) and are wired into the SKILL.md workflow. `validate-config.js` needs `js-yaml` (`npm install js-yaml`); `upload-helper.sh` needs `IXMAPS_GITHUB_TOKEN` + `IXMAPS_REPO_USER` for automated upload (else it prints manual steps).

### Template Files

- **template.html** - General purpose template (updated)
  - Fixed critical issues (normalSizeScale, mode: "info", flushChartDraw)
  - Added error handling and loading states
  - Works for all data types

- **template-flexible.html** - Advanced flexible template
  - Configuration-driven approach
  - Better error handling
  - Conditional logic support

- **template-points.html** - Optimized for point data
  - CSV/JSON with lat/lon coordinates
  - Streamlined for point visualizations

- **template-geojson.html** - Optimized for GeoJSON/TopoJSON
  - Polygon/feature data
  - Choropleth maps

- **template-multi-layer.html** - Multi-layer support
  - Multiple data layers
  - Layer toggle controls
  - More complex visualizations

- **template-change-choropleth.html** - Period-over-period change maps
  - Choropleth fill + signed pointer arrows at centroids
  - Uses `CHART|BAR|POINTER|ARROW|SIZE` (upward = positive, downward = negative)
  - Style keys: `scale`, `sizepow`, `fadenegative`, `linecolor`, `linewidth`
  - Use for "t1 vs t2" comparisons, delta/variation visualizations

- **template-world-flows.html** - Origin → destination flow maps
  - Bezier flow arrows via `CHART|VECTOR|BEZIER|POINTER|FADEIN`
  - `vectorScale` style key controls overall arrow thickness
  - Use for migration, trade, remittances, connectivity

- **template-europe-choropleth-sparklines.html** - Map + per-feature mini-charts
  - Choropleth base + `CHART|USER` D3 sparklines at each centroid
  - Requires loading `usercharts/d3/chart.js` from the ixmaps-flat CDN
  - Use for "map + trend" dashboards where each polygon has a small time series

## ⚠️ Before Picking a Template

> Critical rules and silent failure hotspots are maintained in **SKILL.md** — refer there as the single source of truth. Key reminder: the overlay layer name **must exactly match** the FEATURE base name or the overlay renders as nothing. See **SKILL.md § Silent Failure Hotspots** and **§ Geometry Reuse Pre-flight Checklist**.

## When to Use Which Template

| Task | Template |
|------|----------|
| Points with lat/lon (cities, events) | `template-points.html` |
| Polygons with a single indicator | `template-geojson.html` |
| Two+ layers (e.g. base + overlay) | `template-multi-layer.html` |
| Swappable themes on one geometry (sidebar picker) | base + redefine `myMap.layer("<base>")` with new `.meta({name})` per theme, preceded by `api.removeTheme(prev)` |
| Delta/variation between two periods (arrows) | `template-change-choropleth.html` |
| Origin → destination flows | `template-world-flows.html` |
| Choropleth + per-feature sparkline | `template-europe-choropleth-sparklines.html` |
| Fully configurable, complex logic | `template-flexible.html` |
| Starting point, generic | `template.html` |

## Improvements Made

### Critical Fixes

1. ✅ **template.html** - Added missing required options:
   - `normalSizeScale` (required with objectscaling)
   - `mode: "info"` (enables tooltips)
   - `flushChartDraw` (animation control)
   - `.legend()` support
   - Error handling
   - Loading states

### Documentation Improvements

2. ✅ **SKILL.md** - Restructured (the v2.0 overhaul cut it to ~326 lines; it has since
   grown to ~1,600 as new patterns were documented)
   - Added decision tree for choosing visualization types
   - Consolidated critical rules + silent-failure hotspots at top
   - Better organization and clearer structure
   - Deeper detail split into the reference files

3. ✅ **EXAMPLES.md** - Comprehensive example library
   - 18 complete working examples
   - Covers all common use cases
   - Copy-paste ready code
   - Annotated with explanations

4. ✅ **API_REFERENCE.md** - Complete API documentation
   - All methods documented
   - All properties explained
   - Valid values listed
   - Quick reference card

5. ✅ **TROUBLESHOOTING.md** - Problem-solving guide
   - Common issues with solutions
   - Debugging checklist
   - Error message explanations
   - Best practices

### New Templates

6. ✅ **template-flexible.html** - Advanced template
   - Configuration object approach
   - Better error handling
   - More flexible

7. ✅ **template-points.html** - Point data specialist

8. ✅ **template-geojson.html** - GeoJSON specialist

9. ✅ **template-multi-layer.html** - Multi-layer maps

10. ✅ **skill-ui.yaml** - UI configuration
    - Complete parameter definitions
    - Validation rules
    - Presets and wizard
    - Enables tool integration

11. ✅ **UI_YAML_GUIDE.md** - Documentation for UI YAML

12. ✅ **validate-config.js** - Configuration validator

## Usage

### In Claude Code CLI

```bash
# Simple map
/create-ixmap title="My Map"

# With parameters
/create-ixmap filename=cities.html title="Italian Cities" viztype=BUBBLE

# Conversational
"Create a choropleth map of European countries"
```

### Skill Behavior

When invoked, Claude will:

1. **Parse parameters** from command or conversation
2. **Ask questions** if information is missing
3. **Choose appropriate template** based on data type
4. **Generate HTML file** with complete map
5. **Validate** before writing
6. **Confirm** creation and explain what was created

## Supported Visualizations

### Point Data (CSV/JSON)
- Simple dots (uniform or categorical)
- Sized bubbles
- Pie charts
- Bar charts
- Density heatmaps (aggregation)

### Polygon Data (GeoJSON/TopoJSON)
- Simple features
- Choropleth maps (numeric)
- Categorical coloring
- Multiple classification methods

## Key Features

- ✅ **Standalone HTML** - No server required
- ✅ **Interactive** - Zoom, pan, hover tooltips
- ✅ **Multiple base maps** - OpenStreetMap, CartoDB, Stamen
- ✅ **Flexible data** - Inline JSON, CSV, GeoJSON, TopoJSON, external URLs
- ✅ **Error handling** - Catches and displays errors gracefully
- ✅ **Performance optimized** - Options for large datasets
- ✅ **Mobile responsive** - Works on all devices

## Critical Rules

> Maintained in **SKILL.md § CRITICAL RULES** — that is the single authoritative source. Do not edit rules here; update SKILL.md instead.

## File Structure

```
create-ixmap/
├── SKILL.md                                    # Main skill instructions (read by Claude)
├── README.md                                   # This file
├── CHANGELOG.md                                # Version history
├── API_REFERENCE.md                            # Complete API docs
├── EXAMPLES.md                                 # Working code examples
├── TROUBLESHOOTING.md                          # Common issues & fixes
├── RUNTIME_CONTROLS.md                         # Filters, toggles, .on() events, URL sync
├── FACETS_GUIDE.md                             # Facet sidebar + overlay indicators
├── CSS_INTEROP.md                              # Bootstrap / dark-basemap CSS conflicts
├── MAP_TYPES_GUIDE.md                          # Valid basemaps & projections
├── SYMBOLS_GUIDE.md                            # Symbol/icon reference
├── DATA_JS_GUIDE.md                            # data.js preprocessing helpers
├── DATA_HOSTING_GUIDE.md                       # Hosting data for url: layers
├── UI_YAML_GUIDE.md                            # skill-ui.yaml usage guide
├── example-multi-layer-join.md                 # Worked TopoJSON + CSV join
├── skill-ui.yaml                               # UI configuration & parameters
├── validate-config.js                          # Configuration validator
├── upload-helper.sh                            # Data upload helper (CDN/host)
├── template.html                               # General purpose
├── template-flexible.html                      # Advanced/config-driven
├── template-points.html                        # Point data specialist
├── template-geojson.html                       # GeoJSON/TopoJSON specialist
├── template-multi-layer.html                   # Multi-layer maps
├── template-change-choropleth.html             # Delta/variation with arrows
├── template-world-flows.html                   # Origin→destination flows
└── template-europe-choropleth-sparklines.html  # Map + per-feature sparklines
```

## Version History

### Version 2.0 (2026-02-07) - Complete Overhaul

**Critical Fixes:**
- Fixed missing `normalSizeScale` issue
- Added `mode: "info"` for tooltips
- Added `flushChartDraw` for animation control
- Added `.legend()` support
- Added error handling and loading states

**Documentation:**
- Reduced SKILL.md by 48% (631 → 326 lines)
- Created EXAMPLES.md with 28 examples
- Created API_REFERENCE.md with complete API docs
- Created TROUBLESHOOTING.md with solutions

**New Templates:**
- Created template-flexible.html
- Created template-points.html
- Created template-geojson.html
- Created template-multi-layer.html

### Version 1.0 (Original)

- Basic skill functionality
- Single template file
- Large SKILL.md (631 lines)
- No separate documentation files

## License

iXMaps-flat is licensed under the [BSD 3-Clause License](LICENSE.txt).

## Credits

- ixMaps framework by Guenter Richter
- Skill created for Claude Code
- Overhauled and improved February 2026

## Support

For issues or questions:
1. Check TROUBLESHOOTING.md
2. Review EXAMPLES.md for working code
3. Consult API_REFERENCE.md for syntax

## Contributing

Improvements welcome! When contributing:
- Keep SKILL.md concise
- Add examples to EXAMPLES.md
- Update API_REFERENCE.md if API changes
- Add troubleshooting entries for new issues discovered
- Test all templates before committing

---

**Happy Mapping! 🗺️**
