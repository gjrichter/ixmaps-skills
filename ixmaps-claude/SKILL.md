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
- **maptype**: "VT_TONER_LITE"
- **center**: {lat: 42.5, lng: 12.5} (Italy)
- **zoom**: 6
- **viztype**: "CHART|BUBBLE|SIZE|VALUES"
- **colorscheme**: ["#0066cc"]
- **normalSizeScale**: "1000000"
- **flushChartDraw**: 1000000 (instant rendering)
- **basemapopacity**: 0.6
- **opacity**: 0.7

## Valid Map Types

Use exact names (case-sensitive):
- `"VT_TONER_LITE"` - Clean minimal base map (default)
- `"white"` - Plain white background
- `"OpenStreetMap"` - Standard OSM
- `"CartoDB - Positron"` - Light CartoDB (note spaces)
- `"CartoDB - Dark_Matter"` - Dark CartoDB (note spaces)
- `"Stamen Terrain"` - Terrain with hill shading

**CRITICAL**: CartoDB types require spaces: `"CartoDB - Positron"` NOT `"CartoDB Positron"`

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
- `scale`: Size multiplier (e.g., `1.5` = 50% larger)
- `normalsizevalue`: Data value = 30px chart (avoid with AGGREGATE)
- `opacity`: Fill opacity (0-1)
- `fillopacity`: Alternative to opacity
- `linecolor`: Border color (NOT strokecolor)
- `linewidth`: Border width (NOT strokewidth)
- `gridwidth`: For aggregation (e.g., `"5px"`)

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

## Special Cases

### Aggregation with Grid

For density visualization:

```javascript
.binding({
    geo: "lat|lon",
    value: "$item$",  // Count items, not sum field
    title: "location"
})
.style({
    colorscheme: ["#ffeb3b", "#ff9800", "#f44336"],
    gridwidth: "5px",  // Grid cell size
    scale: 1.5,
    showdata: "true"
})
.type("CHART|BUBBLE|SIZE|AGGREGATE")
```

**Key points:**
- Use `value: "$item$"` to count items
- Set `gridwidth` in style (NOT type)
- Avoid `normalsizevalue` (max count unknown)

### Categorical Coloring

**Point data:**
```javascript
.binding({ value: "category_field" })  // Field to colorize by
.style({ colorscheme: ["100", "tableau"] })  // Dynamic colors
.type("CHART|DOT|CATEGORICAL")
```

**GeoJSON data:**
```javascript
.binding({ value: "NAME_ENGL" })  // Field to colorize by
.style({ colorscheme: ["100", "tableau"] })
.type("FEATURE|CHOROPLETH|CATEGORICAL")
```

## Data Handling

- **Inline data**: Embed JSON array directly: `const data = [{...}];`
- **External URL**: Use `.data({url: "...", type: "csv/json/geojson/topojson"})`
- **User describes data**: Create reasonable sample data
- **Ensure required fields**: lat/lon for points, geometry for GeoJSON

## Common Patterns

### Simple point map
```javascript
.binding({ geo: "lat|lon", title: "name" })
.style({ colorscheme: ["#0066cc"], showdata: "true" })
.type("CHART|DOT")
```

### Sized bubbles
```javascript
.binding({ geo: "lat|lon", value: "population", title: "name" })
.style({ colorscheme: ["#0066cc"], showdata: "true" })
.type("CHART|BUBBLE|SIZE|VALUES")
```

### Simple GeoJSON features
```javascript
.binding({ geo: "geometry", value: "$item$", title: "name" })
.style({ colorscheme: ["#0066cc"], showdata: "true" })
.type("FEATURE")
```

### Categorical GeoJSON
```javascript
.binding({ geo: "geometry", value: "category_field", title: "name" })
.style({ colorscheme: ["100", "tableau"], showdata: "true" })
.type("FEATURE|CHOROPLETH|CATEGORICAL")
```

## Templates Available

- **template.html** - General purpose (updated with all fixes)
- **template-flexible.html** - Config-driven, best error handling
- **template-points.html** - Optimized for point data
- **template-geojson.html** - Optimized for GeoJSON/TopoJSON
- **template-multi-layer.html** - Multiple layers with toggle controls

## Additional Resources

- **EXAMPLES.md** - Complete working examples
- **API_REFERENCE.md** - Full API documentation
- **TROUBLESHOOTING.md** - Common issues and solutions

## Notes

- All HTML files are standalone (no server needed)
- Dependencies loaded from CDN
- Maps fully interactive (zoom, pan, hover)
- Always test generated maps in browser
- Offer to adjust/enhance after creation
