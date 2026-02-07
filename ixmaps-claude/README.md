# ixMaps Skill for Claude Code

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

- **SKILL.md** - Main skill instructions (326 lines, down from 631)
  - Concise, well-organized skill documentation
  - Critical rules highlighted at top
  - Decision tree for choosing visualization types
  - All essential information for Claude

- **SKILL_OLD_BACKUP.md** - Original skill file (backup)
  - Keep for reference
  - Can be deleted if not needed

### Documentation Files

- **EXAMPLES.md** - Complete working examples (18 examples)
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

- **README.md** - This file
- **UI_YAML_GUIDE.md** - Guide to using skill-ui.yaml

### Utility Files

- **validate-config.js** - Configuration validator (uses skill-ui.yaml)

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

2. ✅ **SKILL.md** - Reduced from 631 to 326 lines (48% reduction)
   - Added decision tree for choosing visualization types
   - Consolidated critical rules at top
   - Removed redundancy
   - Better organization
   - Clearer structure

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

## Critical Rules (for Claude)

When using this skill, Claude must:

1. ⚠️ **ALWAYS** include `.binding()` with appropriate `geo` and `value`
2. ⚠️ **ALWAYS** include `showdata: "true"` in `.style()`
3. ⚠️ **ALWAYS** include `.meta()` with tooltip template
4. ⚠️ When using `objectscaling: "dynamic"`, MUST include `normalSizeScale`
5. ⚠️ For GeoJSON: Reference properties directly (no "properties." prefix)
6. ⚠️ For aggregation: Use `value: "$item$"` and `gridwidth` in style
7. ⚠️ **NEVER** use `.tooltip()` method (doesn't exist)

## File Structure

```
create-ixmap/
├── SKILL.md                    # Main skill instructions (read by Claude)
├── skill-ui.yaml              # UI configuration & parameters ⭐ NEW
├── README.md                   # This file
├── CHANGELOG.md               # Version history
├── EXAMPLES.md                 # Working code examples
├── API_REFERENCE.md            # Complete API docs
├── TROUBLESHOOTING.md          # Common issues
├── UI_YAML_GUIDE.md           # UI YAML usage guide ⭐ NEW
├── validate-config.js         # Configuration validator ⭐ NEW
├── template.html               # General purpose (updated)
├── template-flexible.html      # Advanced template
├── template-points.html        # Point data specialist
├── template-geojson.html       # GeoJSON specialist
├── template-multi-layer.html   # Multi-layer maps
└── SKILL_OLD_BACKUP.md         # Original (backup)
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
- Created EXAMPLES.md with 18 examples
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

MIT License - See LICENSE file in parent directory

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
