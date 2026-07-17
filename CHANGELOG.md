# ixMaps Skill Changelog

## 2026-07-17 — `|SILENT` on a FEATURE base silently kills overlay tooltips

Promoted Silent Failure Hotspot #10 to a top-level critical rule (16a): `FEATURE|SILENT` on a
base layer suppresses tooltips for any CHOROPLETH/CHART overlay reusing its geometry, since the
overlay has no hover of its own — it relies on the base theme. This was easy to miss because it
was documented only in the hotspot table; an agent following the skill still produced a
choropleth with dead tooltips by copying `FEATURE|SILENT` out of habit. Also fixed the
"Swappable themes" example in § Multi-Layer Join Pattern, which used `FEATURE|SILENT` as its base
despite its own swappable overlays carrying tooltips — a contradiction within the skill itself.

## 2026-07-11 — data.js: `.load()`/`.merge()` aliases, Data.Merger, remote-parquet bbox

Synced DATA_JS_GUIDE.md and API_REFERENCE.md with three data.js changes (bumped documented
version 1.62 → 1.63):

- `Data.Broker` (`Data.provider()`) gained a `.load(callback)` alias for `.realize(callback)` —
  matches `Data.feed(...).load(...)`'s naming. Updated all `Data.provider()` code examples to use
  it; `.realize()` still works and is noted as the older name.
- `Data.Merger` (`Data.merger()`) similarly gained a `.merge(callback)` alias for `.realize()`.
  **`Data.Merger` itself was previously undocumented in this skill** — added a full `## Data.Merger`
  section (constructor, `addSource(table, {lookup, columns, label})`, `setOutputColumns()`,
  `merge()`, `error()`) plus a namespace-level `Data.merger()` entry, so an agent joining two
  already-loaded tables by a shared key knows this exists instead of hand-rolling a lookup.
- **Remote parquet by bounding box was entirely undocumented** — data.js's `parquet` loader now
  supports `bbox`/`columns`/`crs`/`proj4`/`maxRows` options: with `bbox` set, it queries a remote
  GeoParquet URL directly via DuckDB WASM's `httpfs` extension (genuine HTTP range reads) instead
  of downloading the whole file, with automatic CRS detection/reprojection (built-in proj4 defs for
  EPSG 3035/3857/2154/25832/25833/32632/32633) and a 2GB fallback gate if `httpfs` fails to load.
  Added a full "Remote parquet by bounding box" subsection to DATA_JS_GUIDE.md, linking to the
  new full guide at gjrichter.github.io/docs/data.js/docs/remote_parquet_bbox.html.

## 2026-07-10 — `tools: false` needed alongside a custom top-left panel

Documented (SKILL.md § Map Init Pattern) that a custom HTML overlay (e.g. a legend/layer-picker
panel) placed in the map's top-left corner needs `tools: false` in the map options — otherwise
ixMaps creates its own UI overlay in that same corner, colliding with the custom panel. Noted
this is unrelated to the "tools" link in the bottom `.map-footer` chrome, which is unaffected by
this option (found while building the Copernicus WMS coexisting-layers map, which uses a custom
top-left legend).

## 2026-07-10 — WMS layers are swappable via the standard meta.name pattern

Confirmed via a live 4-layer Copernicus/EEA showcase (Urban Atlas, Riparian Zones, Corine Land
Cover, Imperviousness Density switched by button clicks over Milano) that the `WMS|IMAGE` theme
type swaps cleanly using the same **stable `meta.name` → auto-replace** pattern already documented
for CHOROPLETH/CHART themes (§ Multi-Layer Join Pattern · B) — no `removeTheme` call needed, no
stacking/ghosting between layers. Added a short example to SKILL.md § WMS / External Raster
Overlays.

## 2026-07-10 — WMS/raster overlay theme documented + pixel-size gotcha

Documented (SKILL.md § WMS / External Raster Overlays) the native `WMS|IMAGE` theme type for
dropping server-rendered raster layers (Copernicus/EEA Urban Atlas, Riparian Zones, etc.) on the
map via `ixmaps.layer(name).type("WMS|IMAGE|NOLEGEND").data({server: url}).style({opacity, layerupper})`.

- The theme speaks **Esri ArcGIS REST `MapServer/export`** conventions
  (`?f=image&transparent=true&bbox=...&bboxSR=4326&size=W,H`), not literal OGC WMS `GetMap` — point
  `server` at the ArcGIS REST `export`/`exportImage` endpoint, not a `WMSServer`/`GetCapabilities` URL.
- `layerupper`/`layerlower` style props give native scale-gating (e.g. `"1:750000"`) — no custom
  zoom-threshold JS needed.
- **Critical gotcha found via live testing:** `width`/`height` in `ixmaps.Map()`/`ixmaps.embed()`
  options must be explicit pixel strings (`window.innerWidth + "px"`) — `"100%"` silently breaks the
  theme's internal SVG scale math, shrinking the raster `<image>` to a few invisible SVG-units even
  though the underlying HTTP request succeeds. Confirmed this is identical across the modern
  `ixmaps.Map()` loader and the classic `ixmaps.embed()` + `htmlgui_flat.js` path — a sizing-string
  issue, not an old-vs-new-API issue.
- Also noted: small `width`/`x`/`y` values on the theme's `<image>` element (e.g. `width:1.3`) are
  normal internal SVG user-coordinates scaled by the outer viewBox, not a sign of breakage — verify
  visibility with a screenshot instead of the raw attribute value.

## 2026-06-23 — Sparkline-in-CHOROPLETH-tooltip mechanism

Documented (SKILL.md § Tooltip Mustache Reference) how `{{theme.item.chart}}` on a CHOROPLETH
renders a **sibling CHART/PLOT theme** rather than the hovered theme's own chart — the native way
to show a per-feature time-series sparkline *in the tooltip* while keeping it *off the map*.

- Sibling match requires: same base layer name (`szThemes`), a `CHART` flag, **and** the chart
  theme's `title` binding equal to the choropleth's geo-key value (CHART|PLOT items are keyed by
  centroid coords, so ixMaps falls back to `szTitle == geoValue`). Binding `title` to the human
  name instead of the join code silently degrades the tooltip to the class-distribution histogram.
- Hide the curve on the map but keep it in the tooltip via `chartupper`/`boxupper`/`gridupper`
  scale thresholds; add `valuescale: "0"` to drop per-point value labels for a clean line.
- Reference: `flat_multi/.../pages/ACLED/political_violence.html`.

## Version 2.0 - Complete Overhaul (2026-02-07)

### 🚨 Critical Fixes

#### template.html - Fixed Blocking Issues

**Before:** Template was missing critical required options that caused maps to malfunction.

**After:** All required options now included:

1. **Added `mode: "info"`** (Line 72)
   - Enables tooltips on mouseover
   - Without this, hover tooltips don't work
   - Impact: HIGH - Tooltips are expected feature

2. **Added `normalSizeScale`** (Line 76)
   - Required when using `objectscaling: "dynamic"`
   - Missing this causes errors or incorrect rendering
   - Impact: CRITICAL - Breaks maps with scaling

3. **Added `flushChartDraw`** (Line 78)
   - Controls animation speed
   - Default value (1000000) = instant rendering
   - Without this, large datasets render slowly
   - Impact: MEDIUM - Performance issue

4. **Added `.legend()` method** (Line 84)
   - Allows custom legend titles
   - Common requirement for professional maps
   - Impact: MEDIUM - Feature gap

5. **Added error handling** (Lines 70, 119-128)
   - try/catch wrapper around map creation
   - User-friendly error messages
   - Console logging for debugging
   - Impact: MEDIUM - Better UX

6. **Added loading indicator** (Lines 62-64, 116-118)
   - Shows "Loading map..." during initialization
   - Hidden after 1 second or on error
   - Impact: LOW - UX improvement

### 📚 Documentation Improvements

#### SKILL.md - 48% Size Reduction (631 → 326 lines)

**Changes made:**

1. **Removed redundancy**
   - Consolidated repeated critical rules
   - Combined similar sections
   - Removed duplicate examples
   - Moved detailed examples to EXAMPLES.md

2. **Better organization**
   - Added "Critical Rules" section at top (most important first)
   - Added decision tree for choosing visualization types
   - Grouped related content
   - Created clear hierarchy

3. **Improved readability**
   - Shorter sections
   - More headings
   - Better formatting
   - Removed verbosity

4. **Added quick reference**
   - Common patterns section
   - Default values list
   - Template selection guide

**Impact:** Claude can process skill instructions faster and more accurately.

#### EXAMPLES.md - New File (18 Examples)

Extracted all examples from SKILL.md into dedicated file:

1. Point Data Examples (4)
   - Simple dots
   - Sized bubbles
   - Categorical dots
   - Pie charts

2. GeoJSON Examples (4)
   - Simple features
   - Numeric choropleth
   - Categorical choropleth
   - Custom tooltips

3. TopoJSON Examples (2)
   - Simple features
   - Categorical coloring

4. Aggregation Examples (2)
   - Point density
   - Hexagonal grid

5. Multi-Layer Examples (2)
   - Boundaries + points
   - Multiple point layers

6. Custom Styling Examples (3)
   - Color gradients
   - Dark theme
   - Minimal white background

7. Complete HTML Example (1)
   - Full working template

**Impact:** Easy to find and copy working code examples.

#### API_REFERENCE.md - New File (Complete API Docs)

Comprehensive reference covering:

1. Map Constructor
   - Parameters
   - Valid map types
   - Mode options

2. Map Methods
   - .options()
   - .view()
   - .legend()
   - .layer()

3. Layer Methods
   - All 8 methods documented
   - Correct order specified
   - Required vs optional marked

4. Data Configuration
   - Inline data format
   - External sources
   - All supported types

5. Binding Configuration
   - Point data patterns
   - GeoJSON patterns
   - All variations covered

6. Style Properties
   - All valid properties listed
   - Invalid properties marked with ❌
   - Examples for each

7. Visualization Types
   - Complete type reference
   - When to use each
   - Required bindings

8. Color Schemes
   - Static schemes
   - Dynamic schemes
   - Available palettes

9. Meta Configuration
   - Tooltip templates
   - Field placeholders
   - Custom HTML

10. Quick Reference Card
    - Essential rules
    - Method chain order
    - Quick syntax patterns

**Impact:** Complete reference for correct API usage.

#### TROUBLESHOOTING.md - New File (Problem Solving)

Common issues organized by category:

1. Map Not Displaying
   - Blank page issues
   - Gray tiles
   - Common errors

2. Data Not Showing
   - Most common: missing `showdata: "true"`
   - Missing binding
   - Invalid coordinates
   - Data outside view

3. Tooltips Not Working
   - Missing `mode: "info"`
   - Missing `.meta()`
   - Invalid field names

4. Performance Issues
   - Slow loading solutions
   - Browser freezing
   - Optimization tips

5. Styling Issues
   - Colors not applying
   - Symbol sizing
   - Missing normalSizeScale

6. GeoJSON Issues
   - Wrong visualization type
   - Property references
   - Format validation

7. Coordinate Problems
   - Swapped lat/lon
   - Wrong projection
   - String vs numeric

8. Browser Issues
   - Cross-browser compatibility
   - CORS errors
   - Local file access

**Plus:**
- Debugging checklist
- Common error messages explained
- Best practices to avoid issues

**Impact:** Faster problem resolution, fewer errors.

#### README.md - New File (Directory Guide)

Overview document covering:

1. What the skill does
2. Quick start examples
3. File descriptions
4. Improvements summary
5. Usage guide
6. Key features
7. Critical rules
8. File structure
9. Version history

**Impact:** Easy onboarding and reference.

### 🎨 New Templates

#### template-flexible.html

**Purpose:** Advanced template with maximum flexibility

**Features:**
- Configuration object approach
- Conditional logic for optional features
- Better error handling with error div
- Loading state management
- Supports all map types
- Cleaner code structure

**Use when:** Need maximum control or complex configurations

#### template-points.html

**Purpose:** Optimized for CSV/JSON point data

**Features:**
- Streamlined for point visualizations
- All point-specific options
- Simplified structure
- Inline data support

**Use when:** Displaying points with lat/lon coordinates

#### template-geojson.html

**Purpose:** Optimized for GeoJSON/TopoJSON

**Features:**
- Geometry-focused configuration
- Choropleth map optimized
- External file loading
- Polygon styling options

**Use when:** Displaying polygons, regions, or features

#### template-multi-layer.html

**Purpose:** Multiple data layers on one map

**Features:**
- Multiple layer support
- Layer toggle controls
- Control panel UI
- Layer visibility functions

**Use when:** Combining different data sources on one map

### 📊 Comparison

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| SKILL.md lines | 631 | 326 | -48% |
| Template files | 1 | 5 | +4 |
| Documentation files | 0 | 4 | +4 |
| Critical issues | 4 | 0 | Fixed |
| Examples in SKILL.md | 8 | 0 | Moved |
| Examples in EXAMPLES.md | 0 | 18 | Created |
| API docs | Scattered | Complete | Organized |
| Troubleshooting | None | 8 sections | Created |

### 🎯 Impact Summary

**For Claude:**
- Faster skill processing (smaller SKILL.md)
- Clearer instructions (better organization)
- Fewer errors (critical rules prominent)
- Better examples (dedicated file)
- Complete reference (API_REFERENCE.md)

**For Users:**
- Maps work correctly (critical fixes)
- Better tooltips (mode: "info" added)
- Faster rendering (flushChartDraw added)
- More options (new templates)
- Easier troubleshooting (TROUBLESHOOTING.md)

**For Developers:**
- Better documentation (4 new docs)
- Working examples (18 examples)
- Complete API reference
- Clear file structure
- Easy to contribute

### 📁 Files Added

```
New files:
✅ EXAMPLES.md (17KB)
✅ API_REFERENCE.md (20KB)
✅ TROUBLESHOOTING.md (12KB)
✅ README.md (6.4KB)
✅ CHANGELOG.md (this file)
✅ template-flexible.html (5.1KB)
✅ template-points.html (2.4KB)
✅ template-geojson.html (2.4KB)
✅ template-multi-layer.html (2.5KB)

Modified files:
📝 SKILL.md (24KB → 9.4KB)
📝 template.html (2.5KB → 4.0KB)

Backup files:
💾 SKILL_OLD_BACKUP.md (24KB)
```

### 🔍 Testing Checklist

All improvements tested and validated:

- [x] template.html includes all required options
- [x] SKILL.md is concise and well-organized
- [x] EXAMPLES.md has working code examples
- [x] API_REFERENCE.md is complete and accurate
- [x] TROUBLESHOOTING.md covers common issues
- [x] README.md provides good overview
- [x] All new templates are functional
- [x] File structure is clean and organized
- [x] Old SKILL.md backed up

### 🚀 Future Improvements

Potential enhancements for future versions:

1. Add more color palette examples
2. Create wizard-style template selector
3. Add data validation helpers
4. Include performance profiling tips
5. Add internationalization examples
6. Create video tutorials/GIFs
7. Add unit tests for templates
8. Create interactive documentation

---

## Version 1.0 - Initial Release

- Basic ixMaps skill functionality
- Single template.html file
- Large SKILL.md (631 lines)
- No separate documentation
- Missing critical options
- No error handling
- No examples file

---

**Changelog maintained by:** Claude Sonnet 4.5
**Last updated:** 2026-02-07
