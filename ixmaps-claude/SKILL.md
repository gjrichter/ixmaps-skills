---
name: create-ixmap
description: Creates interactive maps using ixMaps framework. Use when the user wants to create a map, visualize geographic data, or display data with bubble charts, choropleth maps, pie charts, or bar charts on a map.
argument-hint: "[filename] [options]"
allowed-tools: Write, Read, AskUserQuestion
---

# Create ixMap Skill

Creates complete HTML files with interactive ixMaps visualizations for geographic data.

## Quick Start

```bash
/create-ixmap filename=map.html title="My Map" viztype=BUBBLE
```

## ⚠️ CRITICAL RULES (Never Skip)

1. **ALWAYS include `.binding()`** with appropriate `geo` and `value` properties
2. **ALWAYS include `showdata: "true"`** in `.style()`
3. **ALWAYS include `.meta()`** with tooltip template (default: `{ tooltip: "{{theme.item.chart}}{{theme.item.data}}" }`)
4. **When using `objectscaling: "dynamic"`**, MUST include `normalSizeScale` in options
5. **For GeoJSON/TopoJSON**: Reference properties directly (NOT with "properties." prefix)
6. **For aggregation**: Use `value: "$item$"` and `gridwidth` in style (NOT in type)
7. **NEVER use `.tooltip()`** - It doesn't exist in ixMaps API
8. **NEVER use `|EXACT` classification** - It's a deprecated classification method from older ixmaps versions (use `QUANTILE`, `EQUIDISTANT`, or `CATEGORICAL` instead)
9. **For diverging scales**: `rangecentervalue` requires EVEN number of colors (4, 6, 8). `ranges` requires n+1 values for n colors. DO NOT combine either with QUANTILE/EQUIDISTANT
10. **ALWAYS** use CDN "https://cdn.jsdelivr.net/gh/gjrichter/ixmaps_flat@master/ixmaps.js"
11. **NEVER** include ixmaps npn 
12. **NEVER** use information from https://ixmaps.ca
13. **NEVER** use information from https://ixmaps.com
14. **Only** valid ixmaps repository is https://github.com/gjrichter/ixmaps_flat

## Choosing Visualization Type

```
Is your data...

├─ Points (lat/lon)?
│  ├─ Just showing locations? → CHART|DOT
│  ├─ Sized by values? → CHART|BUBBLE|SIZE|VALUES
│  ├─ Colored by categories? → CHART|DOT|CATEGORICAL
│  └─ Need density heatmap? → CHART|BUBBLE|SIZE|AGGREGATE
│
└─ Polygons (GeoJSON/TopoJSON)?
   ├─ Just boundaries? → FEATURE
   ├─ Colored by numbers? → FEATURE|CHOROPLETH
   └─ Colored by categories? → FEATURE|CHOROPLETH|CATEGORICAL
```

## When Invoked

1. **Parse parameters** from user's request or conversational context

2. **Gather information** if needed (ask user):
   - What data to display?
   - What should visualization show?
   - Styling preferences?

3. **Choose appropriate template**:
   - `template-points.html` - For CSV/JSON point data
   - `template-geojson.html` - For GeoJSON/TopoJSON
   - `template-multi-layer.html` - For multiple layers
   - `template.html` - General purpose (now has all fixes)

4. **Generate HTML** with proper configuration

5. **Validate before writing**:
   - [ ] Data has geographic coordinates
   - [ ] Visualization type matches data structure
   - [ ] Binding includes required fields
   - [ ] If using objectscaling, normalSizeScale is set
   - [ ] Color scheme is valid array

6. **After creation**:
   - Confirm file was created
   - Explain what the map shows
   - Suggest how to open (in browser)
   - Offer to modify/enhance

## Default Values

Use these when not specified:
- **filename**: "ixmap.html"
- **maptype**: "VT_TONER_LITE" ⚠️ ALWAYS use this unless user specifically requests different basemap
- **center**: {lat: 42.5, lng: 12.5} (Italy)
- **zoom**: 6
- **viztype**: "CHART|BUBBLE|SIZE|VALUES"
- **colorscheme**: ["#0066cc"]
- **normalSizeScale**: "1000000"
- **flushChartDraw**: 1000000 (instant rendering)
- **basemapopacity**: 0.6
- **opacity**: 0.7

## Valid Map Types

⚠️ **CRITICAL**: Map types are case-sensitive. Use ONLY verified types from MAP_TYPES_GUIDE.md

### Safe, Verified Map Types (Use These):

- `"VT_TONER_LITE"` - ✅ Clean minimal base map (DEFAULT - use 90% of the time)
- `"white"` - ✅ Plain white background
- `"OpenStreetMap - Osmarenderer"` - Standard OSM
- `"CartoDB - Positron"` - ✅ Light CartoDB (note spaces!)
- `"CartoDB - Dark_Matter"` - ✅ Dark CartoDB (note spaces!)
- `"Stamen Terrain"` - ✅ Terrain with hill shading

### ⚠️ Do NOT Use (Unreliable):

- ❌ `"OpenStreetMap"` - Unreliable, use `"VT_TONER_LITE"` instead
- ❌ `"OSM"` - Does not exist
- ❌ `"CartoDB Positron"` - Missing spaces (must be `"CartoDB - Positron"`)

**DEFAULT RECOMMENDATION:** When in doubt, always use `"VT_TONER_LITE"`

**For full details, see MAP_TYPES_GUIDE.md**

## Data Types & Binding

### Point Data (CSV/JSON with lat/lon)

**Binding format:**
```javascript
.binding({
    geo: "lat|lon",          // or single field: "coordinates"
    value: "fieldname",      // omit for simple dots
    title: "titlefield"
})
```

**Visualization types:**
- `CHART|DOT` - Uniform dots
- `CHART|DOT|CATEGORICAL` - Dots colored by category
- `CHART|BUBBLE|SIZE|VALUES` - Sized by values
- `CHART|SYMBOL` - Custom SVG icons poossible (see SYMBOLS_GUIDE.md)
- `CHART|SYMBOL|CATEGORICAL` - Custom icons cìpossible colored by category
- `CHART|SYMBOL|SIZE` - Custom icons possible sized by values
- `CHART|PIE` - Pie charts
- `CHART|BAR|VALUES` - Bar charts
- `CHART|BUBBLE|SIZE|AGGREGATE` - Density grid (add `gridwidth: "5px"` to style)

### GeoJSON/TopoJSON Geometry Data

**Binding format:**
```javascript
.binding({
    geo: "geometry",
    value: "$item$",         // for simple features
    // OR value: "fieldname" // for categorical coloring
    title: "NAME_ENGL"       // property name directly
})
```

**Visualization types:**
- `FEATURE` - Simple features
- `FEATURE|CHOROPLETH` - Numeric data coloring
- `FEATURE|CHOROPLETH|EQUIDISTANT` - Equal intervals
- `FEATURE|CHOROPLETH|QUANTILE` - Quantiles
- `FEATURE|CHOROPLETH|CATEGORICAL` - Category coloring

**IMPORTANT**: Property names referenced directly (e.g., `"NAME_ENGL"`), NOT `"properties.NAME_ENGL"`

## Configuration Reference

### Map Options

```javascript
ixmaps.Map("map", {
    mapType: "VT_TONER_LITE",
    mode: "info"  // Enable tooltips on hover
})
.options({
    objectscaling: "dynamic",        // Enable dynamic scaling
    normalSizeScale: "1000000",      // REQUIRED with objectscaling
    basemapopacity: 0.6,             // Base map transparency
    flushChartDraw: 1000000          // Animation (1000000=instant, 1=slow)
})
```

### Layer Methods (Order Matters)

```javascript
ixmaps.layer("layer_id")
    .data()      // 1. Define data source
    .binding()   // 2. Map fields (REQUIRED)
    .filter()    // 3. Optional filter
    .type()      // 4. Visualization type
    .style()     // 5. Visual styling (MUST include showdata: "true")
    .meta()      // 6. Tooltip config (REQUIRED)
    .title()     // 7. Layer title
    .define()    // 8. Finalize
```

### Style Properties

**MUST include:**
```javascript
.style({
    colorscheme: ["#0066cc"],  // or dynamic: ["100", "tableau"]
    showdata: "true",          // REQUIRED - enables data display
    // ... other properties
})
```

**Common properties:**
- `colorscheme`: Array of colors or `["count", "palette"]` for dynamic
  - Static: `["#0066cc"]` or `["#ffffcc", "#ff0000"]`
  - Dynamic: `["100", "tableau"]` (ixMaps calculates count)
  - Palettes: "tableau", "paired", "set1", "set2", "pastel1", "dark2"
- `rangecentervalue`: Number - creates automatic diverging scale around this value (e.g., `65` for EU target). **Use EVEN number of colors** (4, 6, 8) for equal distribution above/below. DO NOT combine with QUANTILE/EQUIDISTANT classification
- `ranges`: Array - explicitly defines class breaks (e.g., `[0, 50, 60, 65, 70, 80, 100]`). Array must have n+1 values for n colors. DO NOT combine with QUANTILE/EQUIDISTANT classification
- `scale`: Size multiplier (e.g., `1.5` = 50% larger)
- `normalsizevalue`: Data value = 30px chart (avoid with AGGREGATE)
- `opacity`: Fill opacity (0-1)
- `fillopacity`: Alternative to opacity
- `linecolor`: Border color (NOT strokecolor)
- `linewidth`: Border width (NOT strokewidth)
- `aggregationfield`: String - field name to group/aggregate by (e.g., "comune", "region")
- `gridwidth`: String - spatial grid cell size for density heatmaps (e.g., "5px", "10px")

**Properties that DON'T exist:**
- ❌ `fillcolor` - Use `colorscheme` instead
- ❌ `symbolsize` - Use `scale` or `normalsizevalue`
- ❌ `strokecolor/strokewidth` - Use `linecolor/linewidth`

### Meta (Tooltips)

**Default (always include):**
```javascript
.meta({
    tooltip: "{{theme.item.chart}}{{theme.item.data}}"
})
```

**Custom HTML tooltips:**
```javascript
.meta({
    tooltip: "<h3>{{FIELD_NAME}}</h3><p>{{OTHER_FIELD}}</p>"
})
```

Field names reference properties directly (no "properties." prefix).

### Legend

```javascript
.legend("Custom Legend Title")  // Call after .view(), before .layer()
```

### Custom Symbols (Icons)

⚠️ **CRITICAL**: Use `symbols` (plural), not `symbol`. Must be array format.

**Basic symbol usage:**
```javascript
.type("CHART|SYMBOL|CATEGORICAL")
.style({
    colorscheme: ["#d32f2f", "#ff9800"],  // Colors per category
    symbols: [
        "https://files.svgcdn.io/material-symbols/icon1.svg",
        "https://files.svgcdn.io/material-symbols/icon2.svg"
    ],  // One symbol URL per category
    scale: 0.1,  // Much smaller than dots (symbols are larger)
    showdata: "true"
})
```

**Key points:**
- Property name is `symbols` (PLURAL), not `symbol`
- Must be an array: `symbols: ["url"]` not `symbols: "url"`
- Array length must match number of categories
- Use scale 0.05-0.2 (symbols are much larger than dots)
- Recommended CDN: `https://files.svgcdn.io/material-symbols/icon-name.svg`

**For complete symbol documentation, see SYMBOLS_GUIDE.md**

## Special Cases

### Aggregation Types

There are TWO complementary aggregation methods:

#### 1. Aggregation by Field (Group by data field)

Aggregates items by a specific data field (e.g., count devices per municipality):

```javascript
.binding({
    geo: "geometry",  // or "lat|lon" for point data
    value: "$item$",  // Count items in each group
    title: "comune"   // Field to display
})
.type("CHART|BUBBLE|SIZE|AGGREGATE")
.style({
    colorscheme: ["#ffeb3b", "#ff9800", "#f44336"],
    aggregationfield: "comune",  // Field to group by
    scale: 1.5,
    showdata: "true"
})
```

**Use when:** You want to count/sum items grouped by a categorical field (municipality, region, category, etc.)

#### 2. Spatial Grid Aggregation (Density heatmap)

Aggregates items into spatial grid cells for density visualization:

```javascript
.binding({
    geo: "lat|lon",
    value: "$item$",  // Count items per grid cell
    title: "location"
})
.type("CHART|BUBBLE|SIZE|AGGREGATE")
.style({
    colorscheme: ["#ffeb3b", "#ff9800", "#f44336"],
    gridwidth: "5px",  // Grid cell size (5px, 10px, etc.)
    scale: 1.5,
    showdata: "true"
})
```

**Use when:** You want a spatial density heatmap showing where items cluster geographically

**Key points:**
- Use `aggregationfield` to group by data field (comune, region, category)
- Use `gridwidth` for spatial density grid
- Both use `value: "$item$"` to count items
- Avoid `normalsizevalue` (max count unknown)
- These are complementary - choose based on your aggregation goal

### Categorical Coloring

**Point data:**
```javascript
.binding({ value: "category_field" })  // Field to colorize by
.type("CHART|DOT|CATEGORICAL")
.style({ colorscheme: ["100", "tableau"] })  // Dynamic colors
```

**GeoJSON data:**
```javascript
.binding({ value: "NAME_ENGL" })  // Field to colorize by
.style({ colorscheme: ["100", "tableau"] })
.type("FEATURE|CHOROPLETH|CATEGORICAL")
```

### Diverging Color Schemes

For visualizations centered around a target value (e.g., EU 65% recycling target):

**Method 1: rangecentervalue (Recommended - Automatic):**
```javascript
.binding({ geo: "geometry", value: "recycling_rate", title: "name" })
.style({
    colorscheme: [
        "#b71c1c", "#d32f2f", "#e57373",  // 3 reds (below 65%)
        "#66bb6a", "#43a047", "#2e7d32"   // 3 greens (above 65%)
    ],  // 6 colors (EVEN number) - equal above/below, 65% is the boundary
    rangecentervalue: 65,  // EU target - boundary between color groups
    opacity: 0.7,
    showdata: "true"
})
.type("FEATURE|CHOROPLETH")  // No QUANTILE/EQUIDISTANT
```

**Method 2: ranges (Explicit Control):**
```javascript
.binding({ geo: "geometry", value: "recycling_rate", title: "name" })
.style({
    colorscheme: [
        "#b71c1c",  // <50%
        "#d32f2f",  // 50-57.5%
        "#e57373",  // 57.5-65%
        "#66bb6a",  // 65-72.5%
        "#43a047",  // 72.5-80%
        "#2e7d32"   // >80%
    ],
    ranges: [0, 50, 57.5, 65, 72.5, 80, 100],  // 6 colors = 7 values (n+1)
    opacity: 0.7,
    showdata: "true"
})
.type("FEATURE|CHOROPLETH")  // No QUANTILE/EQUIDISTANT
```

**Asymmetric example (4 below + 3 above target):**
```javascript
.style({
    colorscheme: [
        "#b71c1c", "#d32f2f", "#e57373", "#ff9800",  // 4 below
        "#66bb6a", "#43a047", "#2e7d32"              // 3 above
    ],
    ranges: [0, 50, 55, 60, 65, 70, 80, 100],  // 7 colors = 8 values
    showdata: "true"
})
```

**Key points:**
- Use `rangecentervalue` for automatic, symmetric distribution (requires **EVEN number of colors**: 4, 6, 8, etc.)
- Center value is the boundary between color groups (not a color itself)
- Use `ranges` for precise control over class breaks (**any number of colors**, allows asymmetric)
- ranges array must have n+1 values for n colors (first = min, last = max, middle = breaks)
- DO NOT combine with QUANTILE or EQUIDISTANT classification methods
- Use plain `CHOROPLETH` type (no classification modifier)
- Colors array is ordered from low to high values

## Data Handling

- **Inline data**: Embed JSON array directly: `const data = [{...}];`
- **External URL**: Use `.data({url: "...", type: "csv/json/geojson/topojson"})`
- **User describes data**: Create reasonable sample data
- **Ensure required fields**: lat/lon for points, geometry for GeoJSON

## Common Patterns

### Simple point map
```javascript
.binding({ geo: "lat|lon", title: "name" })
.type("CHART|DOT")
.style({ colorscheme: ["#0066cc"], showdata: "true" })
```

### Sized bubbles
```javascript
.binding({ geo: "lat|lon", value: "population", title: "name" })
.type("CHART|BUBBLE|SIZE|VALUES")
.style({ colorscheme: ["#0066cc"], showdata: "true" })
```

### Simple GeoJSON features
```javascript
.binding({ geo: "geometry", value: "$item$", title: "name" })
.type("FEATURE")
.style({ colorscheme: ["#0066cc"], showdata: "true" })
```

### Categorical GeoJSON
```javascript
.binding({ geo: "geometry", value: "category_field", title: "name" })
.style({ colorscheme: ["100", "tableau"], showdata: "true" })
.type("FEATURE|CHOROPLETH|CATEGORICAL")
```

### Diverging choropleth (target-based)
```javascript
.binding({ geo: "geometry", value: "rate_field", title: "name" })
.style({
    colorscheme: [
        "#d32f2f", "#e57373", "#ffab91",  // 3 below target
        "#66bb6a", "#43a047", "#2e7d32"   // 3 above target
    ],  // 6 colors (even) - target is boundary
    rangecentervalue: 65,  // Boundary between color groups
    showdata: "true"
})
.type("FEATURE|CHOROPLETH")  // No classification method
```

## Templates Available

- **template.html** - General purpose (updated with all fixes)
- **template-flexible.html** - Config-driven, best error handling
- **template-points.html** - Optimized for point data
- **template-geojson.html** - Optimized for GeoJSON/TopoJSON
- **template-multi-layer.html** - Multiple layers with toggle controls

## Additional Resources

- **MAP_TYPES_GUIDE.md** - ⚠️ CRITICAL: Valid map types reference (read this first!)
- **SYMBOLS_GUIDE.md** - ⚠️ IMPORTANT: How to use custom SVG symbols/icons
- **EXAMPLES.md** - Complete working examples
- **API_REFERENCE.md** - Full API documentation
- **TROUBLESHOOTING.md** - Common issues and solutions

## Notes

- All HTML files are standalone (no server needed)
- Dependencies loaded from CDN
- Maps fully interactive (zoom, pan, hover)
- Always test generated maps in browser
- Offer to adjust/enhance after creation
