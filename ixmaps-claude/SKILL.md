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
8. **`CHART` and `CHOROPLETH` are mutually exclusive** — NEVER combine them (e.g., `CHART|CHOROPLETH` is invalid). Polygon/fill layers use `FEATURE` or `FEATURE|CHOROPLETH`; bubble/symbol layers use `CHART|BUBBLE|…`. Use `FEATURE` (not `CHART`) for all geometry-based themes
9. **NEVER use `|EXACT` classification** - It's a deprecated classification method from older ixmaps versions (use `QUANTILE`, `EQUIDISTANT`, or `CATEGORICAL` instead)
10. **For diverging scales**: `rangecentervalue` requires EVEN number of colors (4, 6, 8). `ranges` requires n+1 values for n colors. DO NOT combine either with QUANTILE/EQUIDISTANT
11. **🚨 ALWAYS store the map instance — NEVER call `ixmaps.layer()` standalone:**
    ```javascript
    // ✅ CORRECT — store map, call .layer() on it
    const myMap = ixmaps.Map("map", { ... }).options({ ... }).view({ ... });
    myMap.layer("layerName").data(...).binding(...).type(...).style(...).define();

    // ❌ WRONG — map instance discarded, layer not attached to any map
    ixmaps.Map("map", { ... }).options({ ... }).view({ ... });
    ixmaps.layer("layerName")...define();   // ← silently never renders
    ```
    - `ixmaps.Map()` returns the map instance — **always assign it to `const myMap`**
    - All `.layer()` calls must be on `myMap`, not on the global `ixmaps` object
    - **EXCEPTION — animated/timeseries maps:** Use `ixmaps.layer(...)...define()` (global) to **build a theme object** without rendering it, then render with `myMap.layer(theme, "direct")` or `mapInstance.addTheme()`/`replaceTheme()`. See "Animated / Timeseries Maps" section.
12. **ALWAYS** use CDN "https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/ixmaps.js"
12. **NEVER** include ixmaps npn
13. **NEVER** use information from https://ixmaps.ca
14. **NEVER** use information from https://ixmaps.com
15. **Only** valid ixmaps repository is https://github.com/gjrichter/ixmaps-flat
16. **ONE layer = ONE `.data()`** - Each layer can have ONLY ONE `.data()` call
17. **🚨 SAME LAYER NAME IS MANDATORY FOR ALL MULTI-LAYER** - This is the #1 cause of silent failures:
    - **RULE:** ANY thematic layer (CHOROPLETH, CHART|BUBBLE, CHART|VECTOR, CHART|PIE, CHART|BAR, CHART|SYMBOL, etc.) that uses geometry from a FEATURE layer MUST use the EXACT SAME layer name
    - ✅ CORRECT: `myMap.layer("us_states").type("FEATURE")` → `myMap.layer("us_states").type("CHOROPLETH")`
    - ✅ CORRECT: `myMap.layer("regions").type("FEATURE")` → `myMap.layer("regions").type("CHART|VECTOR|...")`
    - ❌ WRONG: `myMap.layer("us_states").type("FEATURE")` → `myMap.layer("migration").type("CHOROPLETH")` - **FAILS SILENTLY!**
    - ❌ WRONG: `myMap.layer("states").type("FEATURE")` → `myMap.layer("flows").type("CHART|VECTOR|...")` - **FAILS SILENTLY!**
    - **WHY:** Thematic layers need to resolve positions/geometry from the base FEATURE layer. Different names = no resolution = no visualization
    - **APPLIES TO:** ALL chart and choropleth types overlaid on geometry: CHOROPLETH, BUBBLE, VECTOR, PIE, BAR, SYMBOL, DOT, etc.
18. **Multi-layer join (CRITICAL)**: Joining external data to geometry requires BOTH sides:
    - FEATURE layer: `.binding({ id: "field_name" })` - identifies each feature
    - Thematic layer: `.binding({ lookup: "csv_field" })` - joins CSV to geometry
    - **MATCHING VALUES** - The `id` field in geometry and `lookup` field in CSV must contain matching values
19. **`lookup` goes in `.binding()`** - NOT in `.data()`
20. **`FEATURE` type in multi-layer** - CRITICAL distinction:
    - Base layer: `FEATURE` (creates geometry)
    - Overlay layers: NO `FEATURE` (use existing geometry)
    - Exception: Single theme can use `FEATURE|CHOROPLETH` (all in one)
21. **NEVER use `map` as variable name** - The variable name `map` conflicts with ixMaps internals. Use `myMap`, `mapInstance`, or any other name instead
22. **ALWAYS use `fillopacity`** - NEVER use `opacity` in `.style()`. Use `fillopacity` for fill transparency
23. **NEVER add `colorfield` unless explicitly requested** - DO NOT add color coding by categories (`colorfield: "fieldname"`) unless the user specifically asks for it. Default to single color (`colorscheme: ["#0066cc"]`)
24. **NEVER use `colorfield` pointing to a hex-value column** - ixMaps does NOT support reading colors from a data field (e.g., `colorfield: "color"` where data has `{ color: "#e74c3c" }`). For explicit CATEGORICAL color assignment always use parallel `colorscheme` + `values` arrays (see "Explicit CATEGORICAL Color Binding" section)
23. **NEVER add `.legend()` unless explicitly requested** - DO NOT add legend titles or calls to `.legend()` unless the user specifically asks for a legend. Omit the `.legend()` method call entirely by default.
    - ⚠️ **CRITICAL side-effect**: calling `.legend("any string")` on the map instance **disables the default ixMaps color legend** (color scale, class breaks, layer title). It replaces it with a custom text panel.
    - ✅ To show the default ixMaps legend open at start: use `legend: "open"` in `ixmaps.Map()` options (or omit `legend: "closed"`)
    - ❌ Do NOT call `.legend("string")` to "just set a title" — it destroys the color scale
    - Only use `.legend("string")` when the user explicitly provides a custom legend string or legend file to integrate

## Choosing Visualization Type

```
Is your data...

├─ Points (lat/lon)?
│  ├─ Just showing locations? → CHART|DOT
│  ├─ Sized by values? → CHART|BUBBLE|SIZE|VALUES
│  ├─ Colored by categories? → CHART|BUBBLE|CATEGORICAL  ⚠️ NOT DOT|CATEGORICAL (legend items non-selectable)
│  ├─ Need density heatmap (circles)? → CHART|BUBBLE|SIZE|AGGREGATE
│  ├─ Need density heatmap (squares)? → CHART|SYMBOL|AGGREGATE|RECT|SUM|GRIDSIZE + symbols:"square"
│  └─ Directional flows (origin→destination)? → CHART|VECTOR|BEZIER|POINTER
│
└─ Polygons (GeoJSON/TopoJSON)?
   ├─ Just boundaries? → FEATURE
   ├─ Colored by numbers? → FEATURE|CHOROPLETH
   ├─ Colored by categories? → FEATURE|CHOROPLETH|CATEGORICAL
   └─ Flows between regions? → CHART|VECTOR|BEZIER|POINTER (with region name data)
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
   - [ ] **ALWAYS start with `scale: 1`** - Let user request adjustments after seeing initial result

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
- **tools**: true (enable info/pan toolbar buttons)

## Valid Map Types

⚠️ **CRITICAL**: Map types are case-sensitive. Use ONLY verified types from MAP_TYPES_GUIDE.md

### Safe, Verified Map Types (Use These):

- `"VT_TONER_LITE"` - ✅ Clean minimal base map (DEFAULT - use 90% of the time)
- `"white"` - ✅ Plain white background
- `"OpenStreetMap - Osmarenderer"` - Standard OSM
- `"CartoDB - Positron"` - ✅ Light CartoDB (note spaces!)
- `"CartoDB - Dark matter"` - ✅ Dark CartoDB (note spaces!)
- `"Stamen Terrain"` - ✅ Terrain with hill shading

### ⚠️ Do NOT Use (Unreliable):

- ❌ `"OpenStreetMap"` - Does not exist; use `"OpenStreetMap - Osmarenderer"` or `"VT_TONER_LITE"`
- ❌ `"OSM"` - Does not exist
- ❌ `"CartoDB Positron"` - Missing spaces (must be `"CartoDB - Positron"`)

**DEFAULT RECOMMENDATION:** When in doubt, always use `"VT_TONER_LITE"`

**For full details, see MAP_TYPES_GUIDE.md**

## Data Types & Binding

### Natively Supported Data Formats

ixMaps delegates data loading to **data.js** (a separate module bundled with ixmaps-flat). All formats handled by data.js are available via `.data({ url: "...", type: "..." })` or `.data({ obj: ..., type: "..." })`. Type values are case-insensitive.

| `type` | Description | Engine |
|--------|-------------|--------|
| `"csv"` | Comma-separated values — rows with named columns | native |
| `"json"` | Plain JSON array of objects | native |
| `"jsonl"` / `"ndjson"` | Newline-delimited JSON (one object per line) | native |
| `"jsonstat"` | JSON-stat statistical data format | native |
| `"jsonDB"` | Internal ixMaps database format | native |
| `"geojson"` | GeoJSON `FeatureCollection` | native |
| `"topojson"` | TopoJSON — no conversion library needed | native |
| `"kml"` | KML (Keyhole Markup Language) | native |
| `"gml"` | GML (Geography Markup Language) | native |
| `"rss"` | RSS feed with geographic data | native |
| `"parquet"` | Apache Parquet columnar binary format | DuckDB WASM |
| `"geoparquet"` | GeoParquet (Parquet with geometry) | DuckDB WASM |
| `"gpkg"` / `"geopackage"` | GeoPackage spatial database | DuckDB WASM |
| `"fgb"` / `"flatgeobuf"` | FlatGeobuf binary vector format | DuckDB WASM |
| `"pbf"` / `"geobuf"` | Geobuf Protocol Buffer format | DuckDB WASM |
| `"ext"` | External data reference resolved from another layer or function| — |

**URL example:**
```javascript
.data({ url: "https://cdn.jsdelivr.net/npm/world-atlas@2/countries-110m.json", type: "topojson" })
```

### ✅ Recommended World Country Geometry Sources

For world maps, prefer the **Eurostat GISCO** TopoJSON over `world-atlas`. GISCO provides official EU geometry with multiple resolution levels — pick the scale that fits your zoom:

| URL | Scale | Detail | Best for |
|-----|-------|--------|----------|
| `https://gisco-services.ec.europa.eu/distribution/v2/countries/topojson/CNTR_RG_60M_2020_4326.json` | 1:60M | very low | **World overview (default)** — tiny file, fast load |
| `https://gisco-services.ec.europa.eu/distribution/v2/countries/topojson/CNTR_RG_20M_2020_4326.json` | 1:20M | low | World overview, slightly more detail |
| `https://gisco-services.ec.europa.eu/distribution/v2/countries/topojson/CNTR_RG_10M_2020_4326.json` | 1:10M | medium | Continental or multi-country zoom |
| `https://gisco-services.ec.europa.eu/distribution/v2/countries/topojson/CNTR_RG_03M_2020_4326.json` | 1:3M | high | Country-level zoom |
| `https://gisco-services.ec.europa.eu/distribution/v2/countries/topojson/CNTR_RG_01M_2020_4326.json` | 1:1M | very high | Regional / city zoom |

**GISCO country feature properties (verified from actual file):**
| Field | Example | Description |
|-------|---------|-------------|
| `CNTR_ID` | `"DE"` | ISO 3166-1 alpha-2 country code — **use this for joins** |
| `NAME_ENGL` | `"Germany"` | English country name |
| `NAME_FREN` | `"Allemagne"` | French country name |
| `NAME_GERM` | `"Deutschland"` | German country name |
| `ISO3_CODE` | `"DEU"` | ISO 3166-1 alpha-3 code |
| `EU_STAT` | `"T"` / `"F"` | EU member state flag |

> ⚠️ The ISO-2 field is **`CNTR_ID`** — NOT `CNTR_CODE`. Using `CNTR_CODE` will cause *"itemfield not found"* errors.

**Recommended default for world maps (Equal Earth, world overviews) — rendering only:**
```javascript
.data({
    url:  "https://gisco-services.ec.europa.eu/distribution/v2/countries/topojson/CNTR_RG_60M_2020_4326.json",
    type: "topojson"
})
// binding: { geo: "geometry" }  — no id/title needed if just rendering fill
```

**For CHOROPLETH joins (need to access CNTR_ID for lookup):**
```javascript
.data({
    url:  "https://gisco-services.ec.europa.eu/distribution/v2/countries/geojson/CNTR_RG_60M_2020_4326.geojson",
    type: "geojson"
})
// binding: { geo: "geometry", id: "CNTR_ID", title: "NAME_ENGL" }
```

All GISCO files: projection EPSG:4326 (WGS 84), reference year 2020, global coverage.

**Inline object example:**
```javascript
.data({ obj: myGeoJSON, type: "geojson" })
.data({ obj: myArray,   type: "json" })
```

⚠️ **Local files (`file://`) are NOT supported** — browser CORS blocks them. Use inline `obj` or a CDN/GitHub URL.

---

### Point Data (CSV/JSON with lat/lon)

**Binding format:**
```javascript
.binding({
    geo: "lat|lon",          // or single field: "coordinates"
    value: "fieldname",      // omit for simple dots
    title: "titlefield",
    timefield: "datefield"   // optional — enables time slider in legend (see below)
})
```

**Visualization types:**
- `CHART|DOT` - Uniform dots (non-selectable in legend). ⚠️ Does **NOT** support `VALUES` modifier — use `CHART|BUBBLE|VALUES` or `CHART|SYMBOL|VALUES` for value labels
- `CHART|DOT|CATEGORICAL` - ⚠️ DEPRECATED for categorical use — legend items non-selectable; use `CHART|BUBBLE|CATEGORICAL` instead
- `CHART|BUBBLE|CATEGORICAL` - Bubbles colored by category (uniform size, legend items selectable/filterable) ✅ preferred
- `CHART|BUBBLE|SIZE|VALUES` - Sized by values
- `CHART|SYMBOL` - Custom SVG icons possible (see SYMBOLS_GUIDE.md)
- `CHART|SYMBOL|CATEGORICAL` - Custom icons colored by category
- `CHART|SYMBOL|SIZE` - Custom icons sized by values
- `CHART|PIE` - Pie charts
- `CHART|BAR|VALUES` - Bar charts
- `CHART|BUBBLE|SIZE|AGGREGATE` - Density grid (circles, sized by count; add `gridwidth: "5px"` to style); optionally add `|RELOCATE` on user request (see below)
- `CHART|SYMBOL|AGGREGATE|RECT|SUM|GRIDSIZE` - Density grid (**filled squares**; add `gridwidth: "50px"` + `symbols: "square"` to style) — ❌ `CHART|GRID|AGGREGATE` does NOT exist
- `CHART|SYMBOL|SEQUENCE` - **Multi-variable**: stacked categorical symbol chart; add `STAR` modifier for radial/flower layout — preferred for 5+ categories (see API_REFERENCE.md)
- `CHART|SYMBOL|PLOT|LINES` + `GRIDSIZE` - **Multi-variable**: time-series curve per **grid cell** — chart size = cell size; data is raw events aggregated by grid (see API_REFERENCE.md)
- `CHART|SYMBOL|PLOT|LINES` + `SIZE` (no GRIDSIZE) - **Multi-variable**: time-series curve **anchored to each geo-point** — for pre-aggregated data (one row per point-year); uses `size:` binding for numeric Y, `value:` for categorical X (see API_REFERENCE.md)

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

### Time Slider — `timefield` in `.binding()`

Adding `timefield` to `.binding()` **automatically creates an interactive time slider** in the ixMaps legend panel. The slider lets users scrub through time and filters visible features to a moving time window.

**How to enable:**
```javascript
.binding({
    geo: "lat|lon",          // or "geometry" for GeoJSON
    value: "magnitude",
    title: "place",
    timefield: "time"        // ← field name containing date/time values
})
```

**Works with any layer type:** CHART|BUBBLE, CHART|DOT, CHART|SYMBOL, FEATURE|CHOROPLETH, etc.

**Accepted time value formats** (parsed via JavaScript `new Date()`):
- Unix timestamp in **milliseconds** — `1707834000000` ✅ (best, most reliable)
- ISO date string — `"2024-02-14"` ✅
- ISO datetime string — `"2024-02-14T08:30:00Z"` ✅
- English date string — `"February 14, 2024"` ✅

**What ixMaps builds automatically:**
- Reads `min` / `max` time across all features
- Renders an HTML range slider in the legend panel
- Shows adaptive **range buttons** based on total data span:

| Data span | Range buttons shown | Window size |
|-----------|--------------------|-|
| < 1 day | (none) | single point |
| 1–7 days | Hour | 1-hour window |
| 7–55 days | Hour, Day | 1-hour or 1-day window |
| 55–365 days | Day, Week | 1-day or 7-day window |
| > 365 days | Week, Month | 7-day or 28-day window |

**Requirements:**
- `legend: 'open'` must be set in `ixmaps.Map()` options so the slider is visible on load
- The time field must exist in the data — if missing, ixMaps logs: `ERROR: timefield 'fieldname' not found!`

**Special values:**
- `timefield: "$index$"` — uses sequential row index instead of a date field (frame-based animation)
- `timefield: "$item$"` — similar index-based mode for window calculations

**Full example — real-time earthquake map with USGS feed:**
```javascript
// USGS properties.time is already Unix ms — no preprocessing needed
ixMap.layer('earthquakes')
    .data({ obj: geojsonData, type: 'geojson' })
    .binding({
        geo: 'geometry',
        value: 'mag',
        title: 'place',
        timefield: 'time'    // USGS Unix ms timestamp → instant time slider
    })
    .type('CHART|BUBBLE|SIZE|VALUES')
    .style({
        colorscheme: ['#ffffb2', '#fecc5c', '#fd8d3c', '#f03b20', '#bd0026'],
        fillopacity: 0.80,
        showdata: 'true',
        units: ' M'
    })
    .meta({ name: 'earthquakes', tooltip: '{{place}} — M{{mag}}' })
    .title('Earthquake Magnitude')
    .define();

// Map must have legend open to show the slider:
ixmaps.Map('map', { mapType: 'CartoDB - Dark matter', mode: 'info', legend: 'open' })
```

### Programmatic Time Control — `ixmaps.setThemeTimeFrame()`

Use `setThemeTimeFrame()` to **filter a theme's visible features to a time window from JavaScript** — without rebuilding or reloading the theme. This is the preferred approach when you are building your own custom time slider UI.

```javascript
ixmaps.setThemeTimeFrame(themeId, startTimeMs, endTimeMs);
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `themeId` | string | The theme's stable ID — must match `meta.name` set in `.meta()` |
| `startTimeMs` | number | Window start as Unix timestamp (ms) |
| `endTimeMs` | number | Window end as Unix timestamp (ms) |

**Requirements:**
- The theme must have `timefield` set in `.binding()` so ixMaps knows which property to filter on
- `themeId` must be the value set in `.meta({ name: '...' })` — NOT the layer name from `.layer('...')`
- `legend: 'closed'` is recommended when using a custom slider (prevents duplicate built-in slider UI)

**Typical pattern — load once, filter on slider move:**
```javascript
// On data load — call addLayer() ONCE with ALL features:
ixMap.layer('earthquakes')
    .data({ obj: { type: 'FeatureCollection', features: allFeatures }, type: 'geojson' })
    .binding({ geo: 'geometry', value: 'mag', timefield: 'time' })
    .meta({ name: 'Earthquake Magnitude' })
    .define();

// On every slider move — lightweight filter, no layer rebuild:
slider.addEventListener('input', function () {
    var endMs   = Number(this.value);
    var startMs = endMs - windowMs;   // windowMs = moving window size in ms
    ixmaps.setThemeTimeFrame('Earthquake Magnitude', startMs, endMs);
});
```

**vs. built-in `timefield` slider:**

| Approach | `legend` | When to use |
|----------|----------|-------------|
| `timefield` + `legend: 'open'` | open | Quick built-in slider, no custom UI needed |
| `timefield` + `setThemeTimeFrame()` | closed | Custom slider UI, full programmatic control |

**Key advantage:** `setThemeTimeFrame()` is a lightweight visibility-mask call — the full dataset stays loaded; only which points are shown changes. Scrubbing is near-instant even for thousands of points. **No debounce needed** — fire directly on every `input` event (vs 150 ms debounce required for full theme rebuild).

### Multi-Layer with External Data Join (CRITICAL PATTERN)

When joining external CSV data to geometry (e.g., TopoJSON provinces + CSV statistics):

> ⚠️ **ALWAYS inspect both sources before writing a join binding.**
> The `id` field on the geometry source and the `lookup` field on the data source must contain **matching values** — but field names vary between sources and cannot be assumed.
> - **Fetch and examine the geometry source** (first few features) to find the actual ID field name and value format
> - **Examine the data source** to find which field contains matching identifiers
> - Only then write `id: "actual_geo_field"` and `lookup: "actual_data_field"`
>
> Example of wrong assumption: GISCO world boundaries use `CNTR_ID` (not `CNTR_CODE`) for ISO-2 codes. Assuming the name costs a failed join.

**Pattern requires:**
1. **FEATURE base layer** - Defines geometry with `id` field for join
2. **Thematic layers** - Load CSV with `lookup` field for join
3. **Same base name** - All layers share the same base layer name

**Example - Provinces with CSV data:**
```javascript
// Layer 1: FEATURE base (geometry only)
myMap.layer("provinces")
    .data({
        url: "provinces.topojson",
        type: "topojson",
        name: "limits_IT_provinces"
    })
    .binding({
        geo: "geometry",
        id: "prov_acr",        // ← Field in TopoJSON for join (e.g., "RM", "MI")
        title: "prov_name"     // Province name for display
    })
    .type("FEATURE")
    .style({
        fillopacity: 0.1,
        linecolor: "#666",
        linewidth: 0.5
    })
    .define();

// Layer 2: CHOROPLETH (same name "provinces", CSV only)
myMap.layer("provinces")
    .data({
        url: "data.csv",
        type: "csv"
    })
    .binding({
        lookup: "Provincia",   // ← Field in CSV that matches id (e.g., "RM", "MI")
        value: "Valore_Totale"
    })
    .type("CHOROPLETH|QUANTILE")  // ← NO FEATURE! Uses existing geometry
    .style({
        colorscheme: ["#e3f2fd", "#1565c0"],
        fillopacity: 0.7,
        showdata: "true"
    })
    .meta({
        tooltip: "{{prov_name}}: € {{Valore_Totale}}"
    })
    .define();

// Layer 3: BUBBLE (same name "provinces", CSV only)
myMap.layer("provinces")
    .data({
        url: "data.csv",
        type: "csv"
    })
    .binding({
        lookup: "Provincia",   // ← Same lookup field
        value: "N_Ordini"
    })
    .type("CHART|BUBBLE|SIZE|VALUES")
    .style({
        colorscheme: ["#ff6f00"],
        fillopacity: 0.6,
        showdata: "true"
    })
    .define();
```

**Key points for multi-layer join:**
- ONE `.data()` per layer (no double `.data()` calls)
- FEATURE layer: `id` in `.binding()` identifies features
- Thematic layers: `lookup` in `.binding()` joins CSV to geometry
- `lookup` parameter goes in `.binding()`, NOT in `.data()`
- **All layers MUST share SAME layer name** (e.g., all use `"provinces"`)
- **Values in `id` and `lookup` fields MUST match exactly** - Check your data!
- ixMaps caches and shares data automatically across layers

**🚨 CRITICAL - Common failures that cause silent breakage:**

1. **❌ DIFFERENT LAYER NAMES** (Most common error!)
   - Problem: `myMap.layer("us_states")` for FEATURE, `myMap.layer("migration")` for CHOROPLETH
   - Symptom: No visualization appears, no error message
   - Why: Thematic layer cannot find base geometry to resolve positions
   - Fix: Use identical layer names for both: `myMap.layer("us_states")` for BOTH layers
   - **Applies to ALL overlay types:** CHOROPLETH, BUBBLE, VECTOR, PIE, BAR, SYMBOL, etc.

2. **❌ Mismatched field values**
   - Problem: `id: "state_code"` (uses "CA", "TX") but CSV has full names ("California", "Texas")
   - Symptom: Visualization loads but shows no data, features appear empty
   - Fix: Ensure `id` field values match `lookup` field values exactly

3. **❌ Case sensitivity**
   - Problem: Geometry has "Florida" but CSV has "florida"
   - Symptom: Some features missing data
   - Fix: Match case exactly in both datasets

✅ **Correct pattern:** Same layer name + matching field values

### ⚠️ CRITICAL: FEATURE Type in Multi-Layer Contexts

**When to include FEATURE:**
- Single theme with geometry: `FEATURE|CHOROPLETH` ✓ (all in one)
- Base layer in multi-layer: `FEATURE` ✓ (creates geometry once)

**When to EXCLUDE FEATURE:**
- Thematic overlays in multi-layer: `CHOROPLETH|QUANTILE` ✓ (NO FEATURE!)
- Secondary visualizations: `CHART|BUBBLE|SIZE` ✓ (NO FEATURE!)

**Why this matters:**
Including `FEATURE` creates SVG geometry groups. In multi-layer scenarios:
- Base layer creates geometry ONCE
- Overlay layers must NOT recreate geometry (causes conflicts)
- Each layer with `FEATURE` tries to create its own SVG groups
- Result: undetermined behavior, conflicting SVG structure

**Common mistake:**
```javascript
// ✗ WRONG - both have FEATURE
map.layer("provinces").type("FEATURE").define();
map.layer("provinces").type("FEATURE|CHOROPLETH").define();  // BUG! Creates duplicate groups

// ✓ CORRECT - only base has FEATURE
map.layer("provinces").type("FEATURE").define();
map.layer("provinces").type("CHOROPLETH").define();  // Correct! Uses existing geometry
```

**The distinction:**
- `FEATURE|CHOROPLETH` = Single theme (geometry + colors in one)
- `FEATURE` + `CHOROPLETH` = Multi-layer (geometry separate, then colors)

## Configuration Reference

### Map Options

```javascript
ixmaps.Map("map", {
    mapType: "VT_TONER_LITE",
    mode: "info",       // Enable tooltips on hover
    legend: "closed",   // Start with legend closed (clean view)
    tools: true         // Enable info/pan toolbar buttons (DEFAULT)
})
.view({ center: { lat: 42.5, lng: 12.5 }, zoom: 6 })   // ⚠️ ALWAYS object syntax — NOT positional args!
.options({
    objectscaling: "dynamic",        // Enable dynamic scaling
    normalSizeScale: "8000000",      // REQUIRED with objectscaling — match to initial zoom (zoom 6 ≈ 8000000)
    basemapopacity: 0.6,             // Base map transparency
    flushChartDraw: 1000000          // Animation (1000000=instant, 1=slow)
})
```

**Map initialization parameters (second parameter of ixmaps.Map()):**
- `mapType`: Base map style (use `"VT_TONER_LITE"` as default). Use `"white"` for projection-based maps (Equal Earth, Winkel, etc.)
- `mapProjection`: Optional SVG projection — overrides the default Mercator tile basemap. Supported values: `"equalearth"`, `"winkel"`, `"albers"`, `"lambert"`, `"orthographic"`, `"mercator"`. Requires `mapType: "white"` (no tiles).
- `mode`: Set to `"info"` to enable tooltips on hover
- `legend`: Initial state of the **built-in color legend** — `"closed"` (collapsed, default) or `"open"` (visible on load). ⚠️ Do NOT confuse with the `.legend("string")` method call, which replaces the color legend with custom text.
- `tools`: Enable toolbar with info/pan buttons (default: `true` - always include)

**`.view()` — sets initial map center and zoom (REQUIRED):**

⚠️ **CRITICAL: ALWAYS use object syntax. Positional args `.view(lat, lng, zoom)` do NOT work.**

```javascript
// ✅ CORRECT
.view({ center: { lat: 42.5, lng: 12.5 }, zoom: 6 })

// ❌ WRONG — positional args are NOT supported
.view(42.5, 12.5, 6)
```

Zoom level reference:
- `1–3`: World / continent
- `4–6`: Country
- `7–10`: Region / state
- `11–14`: City
- `15–18`: Street / building

**⚠️ Equal Earth (and other world projections) — special `.view()` setting:**

When using `mapProjection: "equalearth"` (or `"winkel"`, `"orthographic"`, etc.), always set:
```javascript
.view({ center: { lat: 0, lng: 0 }, zoom: 0 })
```
unless the user explicitly requests a different center or zoom. Standard zoom levels (4–6) do not apply to whole-world SVG projections — `zoom: 0` shows the full world correctly.

**Map chain methods (called after `.view()`):**
- `.attribution("text")` — displays a small attribution string in the bottom-left corner of the map; use for boundary/geometry source credits (e.g., `"Boundaries: Eurostat GISCO · NUTS 2021 · © European Union"`)

**Map options (.options() method):**
- `objectscaling`: Dynamic scaling mode
- `normalSizeScale`: **Map scale denominator** at which charts render at normal size — set to match the initial zoom. Rough guide: zoom 4→`"30000000"`, zoom 5→`"15000000"`, zoom 6→`"8000000"`, zoom 8→`"2000000"`, zoom 10→`"500000"`, zoom 12→`"100000"`, zoom 14→`"25000"`. ⛔ **NEVER `"1"` or tiny values** — breaks the entire scaling mechanism.
- `basemapopacity`: Base map transparency
- `flushChartDraw`: Animation speed


### Layer Methods (Order Matters)

```javascript
myMap.layer("layer_id")
    .data()                           // 1. Define data source
    .binding()                        // 2. Map fields (REQUIRED)
    .filter("WHERE field == value")   // 3. Optional filter (MUST start with WHERE)
    .type()                           // 4. Visualization type
    .style()                          // 5. Visual styling (MUST include showdata: "true")
    .meta()                           // 6. Tooltip config (REQUIRED) — also sets theme name via meta.name
    .title()                          // 7. Display title (NOT the theme ID)
    .define()                         // 8. Finalize
```

**⚠️ CRITICAL — Theme name vs. layer name vs. display title:**

These are three **different** things:

| What | Set by | Used for |
|------|--------|----------|
| Layer name | `.layer("my_layer")` | Geometry sharing between layers |
| Theme ID (`szId`) | `meta: { name: "My Theme" }` | `removeTheme()`, `refreshTheme()`, etc. |
| Display title | `.title("My Title")` | Legend label only — **NOT** the theme ID |

**Rules:**
- `meta: { name: "..." }` → sets the theme's internal ID used by all theme API calls
- `.title("...")` → sets the display label in the legend; does **NOT** set the theme ID
- `.layer("layer_id")` → the layer name is **never** the theme ID
- If `meta.name` is omitted → the theme ID is **randomized** (`"theme0.8234…"`) → `removeTheme()` / `refreshTheme()` cannot find it

**Always set `meta.name` when you need to reference the theme later:**
```javascript
// ✅ CORRECT — theme can be found by removeTheme / refreshTheme
.meta({ name: "earthquakes", tooltip: "{{theme.item.chart}}{{theme.item.data}}" })
.title("Earthquake Magnitude")   // display label — separate from name

// ❌ WRONG — no meta.name → theme ID is random → removeTheme("earthquakes") will FAIL
.meta({ tooltip: "{{theme.item.chart}}{{theme.item.data}}" })
.title("earthquakes")            // .title() does NOT set the theme ID
```

**Swapping data without reinitializing the map (correct pattern):**
```javascript
// Remove old theme by its meta.name, then redefine with new data
try { ixmaps.removeTheme('earthquakes'); } catch (e) {}

ixMap.layer('earthquakes')
    .data({ obj: newData, type: 'geojson' })
    .binding({ ... })
    .type('CHART|BUBBLE|SIZE|VALUES')
    .style({ ... })
    .meta({ name: 'earthquakes', tooltip: '...' })   // ← name matches removeTheme arg
    .title('Earthquake Magnitude')
    .define();
```

### Animated / Timeseries Maps — Two Patterns

For maps that update data on user interaction (year slider, play button, etc.), there are two approaches. Both require a theme name set in `.meta({ name: "..." })`.

**⚠️ KEY RULE:** Always use global `ixmaps.layer(...)` (NOT `myMap.layer(...)`) to **build** a theme definition without immediately rendering it. Then use one of the two methods below to add/replace it on the map.

#### Method A — `myMap.layer(theme, "direct")` (simpler, preferred)

`myMap.layer(theme, "direct")` is a **smart upsert**: on the first call it adds the theme, on subsequent calls it replaces it atomically (no flicker). Uses the theme's `meta.name` as the key.

```javascript
function showYear(year) {
    const yearData = allData.filter(r => r.year === String(year));

    const theme = ixmaps.layer("countries")         // ← global ixmaps, NOT myMap
        .data({ obj: yearData, type: "json" })
        .binding({ lookup: "geo", value: "value" })
        .type("CHOROPLETH|EQUIDISTANT")
        .style({ colorscheme: ["#f7fbff","#08306b"], fillopacity: 0.85, showdata: "true" })
        .meta({ name: "defence", tooltip: "<b>{{NAME_ENGL}}</b>: {{value}}%" })
        .title("Defence spending " + year)
        .define();                                   // returns theme object, does NOT render

    myMap.layer(theme, "direct");                    // smart upsert — add OR replace
}

showYear("2023");                                    // no .then() needed
```

**Advantages:** No `activeTheme` flag, no `.then()` / `mapInstance` needed, simpler code.

#### Method B — explicit `addTheme` / `replaceTheme` via Promise API

`addTheme` and `replaceTheme` are **not** available on the fluent chaining API. They must be called on the resolved map instance obtained from `myMap.then()`.

```javascript
let activeTheme = null;
let mapInstance = null;

myMap.then(function(map) {
    mapInstance = map;
    showYear("2023");          // init after map is ready
});

function showYear(year) {
    if (!mapInstance) return;
    const yearData = allData.filter(r => r.year === String(year));

    const theme = ixmaps.layer("countries")         // ← global ixmaps, NOT myMap
        .data({ obj: yearData, type: "json" })
        .binding({ lookup: "geo", value: "value" })
        .type("CHOROPLETH|EQUIDISTANT")
        .style({ colorscheme: ["#f7fbff","#08306b"], fillopacity: 0.85, showdata: "true" })
        .meta({ name: "defence", tooltip: "<b>{{NAME_ENGL}}</b>: {{value}}%" })
        .title("Defence spending " + year)
        .define();

    if (activeTheme) {
        mapInstance.replaceTheme("defence", theme, "direct");  // atomic swap, no flicker
    } else {
        mapInstance.addTheme("defence", theme, "direct");      // first render only
    }
    activeTheme = theme;
}
```

**Use when:** You need explicit control over add vs replace, or other `mapInstance` methods.

#### Comparison

| | Method A (`myMap.layer`) | Method B (explicit) |
|---|---|---|
| Code simplicity | ✅ Simpler | More boilerplate |
| `.then()` required | ❌ No | ✅ Yes |
| `activeTheme` flag | ❌ No | ✅ Yes |
| First call | Auto-add | `addTheme` |
| Subsequent calls | Auto-replace | `replaceTheme` |
| Flicker-free | ✅ Yes | ✅ Yes |
| **Prefer when** | Default choice | Need mapInstance for other calls |

**Filter syntax:**
- ⚠️ **CRITICAL: ALL filters MUST start with "WHERE"**
- `.filter("WHERE field == value")` - Single string parameter with WHERE prefix + filter expression
- Examples:
  - `.filter("WHERE year == 2024")`
  - `.filter("WHERE category == \"Active\"")`
  - `.filter("WHERE value > 1000")`
  - `.filter("WHERE CNTR_CODE == \"IT\"")`
- Operators: `==`, `!=`, `>`, `<`, `>=`, `<=`
- ⚠️ **Use `AND` / `OR` keywords** (NOT `&&` / `||`): `.filter("WHERE year == 2024 AND value > 1000")`
- Multi-condition example: `.filter("WHERE CNTR_CODE == \"DE\" AND LEVL_CODE == 1")`

**Filter string value quoting rules:**
- ⚠️ **NEVER use single quotes `'` around filter values** — ixMaps does NOT recognise `'` as a string delimiter; they become part of the matched value and will never match
- String values with no spaces: can be **unquoted** → `.filter("WHERE code == IT")`
- String values that need to be explicit or contain spaces: use **escaped double quotes** → `.filter("WHERE name == \"Valle d Aosta\"")`
- Since the filter argument is itself a JS double-quoted string, inner `"` must be escaped as `\"`

### Style Properties

**MUST include:**
```javascript
.style({
    colorscheme: ["#0066cc"],  // or dynamic: ["100", "tableau"]
    showdata: "true",          // REQUIRED - enables data display
    // ... other properties
})
```

**Legend text fields (shown in the ixMaps legend panel):**
- `snippet`: Short subtitle shown as `<h4>` below the title (e.g., units, method, year) — set via `.style({ snippet: "..." })`
- `description`: Longer note shown as `<div>` below the color scale (e.g., source, caveats) — set via `.style({ description: "..." })`
- The main title (`<h3>`) is set via the separate `.title("...")` method chain call

```javascript
// Full legend text example
.title("Gender Employment Gap")          // → <h3> in legend
.style({
    snippet: "men − women · age 15–64",  // → <h4> in legend
    description: "Source: ISTAT 2023 · 107 provinces",  // → <div> in legend
    colorscheme: [...],
    showdata: "true"
})
```

**Common properties:**
- `colorscheme`: Array of colors or `["count", "palette"]` for dynamic
  - Static single/gradient: `["#0066cc"]` or `["#ffffcc", "#ff0000"]`
  - Dynamic auto-palette: `["100", "tableau"]` (ixMaps calculates count)
  - **Explicit CATEGORICAL (parallel arrays):** `colorscheme: ["#e74c3c", "#27ae60"]` + `values: ["RegionA", "RegionB"]` — pins specific colors to specific category values (see below)
  - Palettes: "tableau", "paired", "set1", "set2", "pastel1", "dark2"
- `rangecentervalue`: Number - creates automatic diverging scale around this value (e.g., `65` for EU target). **Use EVEN number of colors** (4, 6, 8) for equal distribution above/below. DO NOT combine with QUANTILE/EQUIDISTANT classification
- `ranges`: Array - explicitly defines class breaks (e.g., `[0, 50, 60, 65, 70, 80, 100]`). Array must have n+1 values for n colors. DO NOT combine with QUANTILE/EQUIDISTANT classification
- `scale`: Size multiplier (e.g., `1.5` = 50% larger). **Scales all bubbles uniformly - does NOT change size differences**. **For CHART|VECTOR layers, controls overall vector size**. **ALWAYS start with `scale: 1` in initial maps** - let user request adjustments after seeing results
- `sizepow`: **Controls bubble size scaling power/curve** - Determines how data values map to visual bubble sizes:
  - `1` = **linear** (radius proportional to value) - DEFAULT, largest visual differences
  - `2` = **area-based** (value proportional to bubble area) - reduces visual differences significantly
  - `3` or higher = **volume-based** (even less visual difference) - makes sizes more equal
  - **To reduce size differences**: increase `sizepow` (2, 3, 4, etc.)
  - **To increase size differences**: use `sizepow < 1` (0.5, 0.7, etc.) - rarely needed
  - Works for CHART|BUBBLE and CHART|VECTOR types
- `rangescale`: **For CHART|VECTOR layers only** - Controls the **bow/curvature** of bezier arrows (named `rangescale` for historic reasons). **Do NOT use for sizing.**
  - Range: roughly **-20 to +20**
  - `0` = straight line
  - `-7` = good starting bow (recommended default for curved flows)
  - Negative values = curve one direction, positive = other direction
  - Higher absolute value = more curvature
  - Example: `rangescale: -7`
- `normalsizevalue`: Data value that maps to 30px chart size. **Does NOT change the sizing curve**, only shifts the scale. Use with `sizepow` to control both scale and curve (avoid with AGGREGATE)
- `fillopacity`: Fill opacity (0-1). **ALWAYS use `fillopacity`, NEVER use `opacity`**. ⚠️ Setting `fillopacity: 0` causes errors in ixMaps — to make a fill completely invisible use `colorscheme: ["none"]` instead
- `linecolor`: Border color (NOT strokecolor)
- `linewidth`: Border width (NOT strokewidth)
- `aggregationfield`: String - field name to group/aggregate by (e.g., "comune", "region")
- `gridwidth`: String - spatial grid cell size for density heatmaps (e.g., "5px", "10px")
- `valuedecimals`: Number of decimal places shown by the `VALUES` type modifier (default: `0`; use `1`, `2`, `3`… for precision). Example: `valuedecimals: 1` shows "1.8 %" instead of "2 %"
- `textcolor`: Text colour for value/title labels rendered by `VALUES` and `TITLE` modifiers (e.g., `"#ffffff"` for white on dark maps)
- `align`: String (optional) - chart alignment relative to its anchor point. Default `"center"`. Basic values: `"center"` `"left"` `"right"` `"top"` `"bottom"` `"above"` `"below"`. Combinable: `"top left"`, `"above right"`. Special: `"23right"` / `"23left"` (pixel offset), `"10%right"` / `"10%left"` (% of chart width). **Only add on user request.**
- `dopacitypow`: Number - interpolation curve power for DOPACITYMAX/DOPACITYMINMAX (default: 1). For DOPACITYMAX: higher = gentler curve, lower = steeper curve. For DOPACITYMINMAX: controls U-curve steepness. Only used with `DOPACITYMAX` or `DOPACITYMINMAX` type modifiers
- `dopacityscale`: Number - opacity intensity multiplier for DOPACITYMAX/DOPACITYMINMAX (default: 1). Higher = more opaque, lower = more transparent. Only used with `DOPACITYMAX` or `DOPACITYMINMAX` type modifiers

**Properties that DON'T exist:**
- ❌ `fillcolor` - Use `colorscheme` instead
- ❌ `symbolsize` - Use `scale` or `normalsizevalue`
- ❌ `strokecolor/strokewidth` - Use `linecolor/linewidth`

**Invisible fill — correct pattern:**
```javascript
// ✅ CORRECT — colorscheme: ["none"] makes fill transparent
.style({ colorscheme: ["none"], linewidth: 0, showdata: "true" })

// ❌ WRONG — fillopacity: 0 causes errors in ixMaps
.style({ colorscheme: ["#fff"], fillopacity: 0 })  // DO NOT USE
```

### Dynamic Opacity (DOPACITYMAX)

The `DOPACITYMAX` type modifier adds dynamic transparency to choropleth maps, varying opacity based on data values to create visual depth.

**Enable dynamic opacity:**
```javascript
.type("CHOROPLETH|QUANTILE|DOPACITYMAX")
.style({
    colorscheme: ["#ffffb2", "#bd0026"],
    opacity: 0.85,          // Base opacity
    dopacitypow: 1,         // Interpolation curve (default: 1)
    dopacityscale: 1,       // Intensity multiplier (default: 1)
    showdata: "true"
})
```

**How it works:**
- Uses the same data field as color classification
- Calculates separate opacity from min/max values
- High values → more opaque, low values → more transparent
- Adds visual hierarchy beyond color alone

**Configuration:**

**`dopacitypow`** (Interpolation curve):
- Default: `1` (linear)
- Higher values: Lower contrast (gentler curve)
- Lower values: Higher contrast (steeper curve)

**`dopacityscale`** (Intensity):
- Default: `1` (normal)
- Higher values: More opacity (stronger visibility)
- Lower values: Less opacity (more transparent)

**Use cases:**
- Emphasize high-value areas
- Accessibility: Redundant encoding (color + opacity)
- Multi-layer overlays with varying importance
- Natural visual hierarchy in dense data

**Example:**
```javascript
// Emphasize important values
.type("CHOROPLETH|QUANTILE|DOPACITYMAX")
.style({
    colorscheme: ["#e3f2fd", "#0d47a1"],
    opacity: 0.85,
    dopacitypow: 0.5,      // Steeper curve (more contrast)
    dopacityscale: 1.2,    // 20% more opaque
    showdata: "true"
})
```

**Real-world example:** See `mepa-2024-map-colorblind.html` for DOPACITYMAX in action with colorblind-safe colors.

### Dynamic Opacity - Min/Max Variant (DOPACITYMINMAX)

The `DOPACITYMINMAX` type modifier creates a **U-shaped opacity curve** that highlights both minimum AND maximum values, while fading mid-range values to the background.

**Enable min/max opacity highlighting:**
```javascript
.type("CHOROPLETH|QUANTILE|DOPACITYMINMAX")
.style({
    colorscheme: ["#0571b0", "#f7f7f7", "#ca0020"],  // Diverging: blue-gray-red
    opacity: 0.85,          // Base opacity
    dopacitypow: 1,         // Interpolation curve (default: 1)
    dopacityscale: 1,       // Intensity multiplier (default: 1)
    showdata: "true"
})
```

**How it works:**
- Uses the same data field as color classification
- Creates symmetrical U-shaped opacity curve
- **Low values → high opacity** (prominent)
- **Mid values → low opacity** (fade to background)
- **High values → high opacity** (prominent)
- Emphasizes outliers and extremes at both ends

**Visual effect:**
```
Opacity
   ↑
High│ █           █    ← Min and Max values stand out
    │  ▓         ▓
Mid │   ▒       ▒
    │    ░     ░
Low │     ░░░░░        ← Mid-range values fade
    └─────────────→ Data Value
      Min  Mid  Max
```

**Configuration:**

**`dopacitypow`** (U-curve shape):
- Default: `1` (symmetrical U-curve)
- Higher values: Flatter U (more mid-values visible)
- Lower values: Steeper U (stronger emphasis on extremes)

**`dopacityscale`** (Intensity):
- Default: `1` (normal)
- Higher values: More opacity overall (stronger visibility)
- Lower values: Less opacity overall (more transparent)

**Use cases:**
- **Outlier detection**: Highlight anomalies at both ends
- **Diverging data**: Temperature (hot/cold), sentiment (positive/negative)
- **Performance analysis**: Best and worst performers
- **Deviation from norm**: Values far from average
- **Quality control**: Defects (too high/too low)
- **Risk assessment**: High-risk and safe zones

**Example - Temperature anomalies:**
```javascript
// Highlight both hot and cold extremes
.type("CHOROPLETH|QUANTILE|DOPACITYMINMAX")
.style({
    colorscheme: [
        "#313695",  // Dark blue (very cold)
        "#4575b4",  // Blue (cold)
        "#abd9e9",  // Light blue (cool)
        "#ffffbf",  // Yellow (normal) ← Fades
        "#fdae61",  // Light orange (warm)
        "#f46d43",  // Orange (hot)
        "#a50026"   // Dark red (very hot)
    ],
    opacity: 0.8,
    dopacitypow: 0.8,      // Steeper U-curve (emphasize extremes)
    dopacityscale: 1.1,    // Slightly more opaque
    showdata: "true"
})
```
**Result:** Very cold regions and very hot regions pop out, normal temperatures fade to background.

**Example - Performance outliers:**
```javascript
// Highlight best and worst performers
.type("CHOROPLETH|QUANTILE|DOPACITYMINMAX")
.style({
    colorscheme: [
        "#d7191c",  // Red (worst performers)
        "#fdae61",  // Orange
        "#ffffbf",  // Yellow (average) ← Fades
        "#a6d96a",  // Light green
        "#1a9641"   // Green (best performers)
    ],
    opacity: 0.85,
    dopacitypow: 1,        // Linear U-curve
    dopacityscale: 1.2,    // More opaque
    showdata: "true"
})
```
**Result:** Top performers and bottom performers clearly visible, average performers fade away.

**Comparison: DOPACITYMAX vs DOPACITYMINMAX**

| Aspect | DOPACITYMAX | DOPACITYMINMAX |
|--------|-------------|----------------|
| **Opacity curve** | Linear (low→high) | U-shaped (high→low→high) |
| **Emphasizes** | High values only | Both extremes (min & max) |
| **Fades** | Low values | Mid-range values |
| **Best for** | Hierarchy, rankings | Outliers, anomalies, diverging |
| **Typical data** | GDP, population, sales | Temperature, deviation, performance |
| **Visual metaphor** | "More is important" | "Extremes are important" |

**When to use DOPACITYMINMAX:**
- ✅ Diverging data (temperature, sentiment)
- ✅ Outlier detection (quality control)
- ✅ Bidirectional scales (above/below target)
- ✅ Risk analysis (high-risk and safe zones)
- ✅ Performance extremes (best and worst)

**When to use DOPACITYMAX instead:**
- ✅ Hierarchical data (bigger = more important)
- ✅ Rankings and top performers only
- ✅ Economic indicators (GDP, revenue)
- ✅ Population density
- ✅ Single-direction emphasis

**Advanced: Combining with diverging color schemes**

DOPACITYMINMAX works especially well with diverging color palettes:

```javascript
// Highlight economic deviations from EU average
.type("CHOROPLETH|QUANTILE|DOPACITYMINMAX")
.style({
    colorscheme: [
        "#0571b0",  // Dark blue (much below average)
        "#92c5de",  // Light blue
        "#f7f7f7",  // Gray (at average) ← Fades
        "#f4a582",  // Light red
        "#ca0020"   // Dark red (much above average)
    ],
    rangecentervalue: 65,  // Center diverging scale on target
    opacity: 0.8,
    dopacitypow: 0.7,      // Strong U-curve
    dopacityscale: 1.15,   // More visible
    showdata: "true"
})
```
**Result:** Countries far above or far below the EU average are highly visible, countries near average fade.

**Real-world example pattern:**
```javascript
// Multi-layer with DOPACITYMINMAX choropleth
map.layer("regions")
    .data({ url: "geometry.topojson", type: "topojson" })
    .binding({ geo: "geometry", id: "region_code", title: "name" })
    .type("FEATURE")
    .define();

map.layer("regions")
    .data({ url: "deviation-data.csv", type: "csv" })
    .binding({ lookup: "region_code", value: "deviation_from_norm" })
    .type("CHOROPLETH|QUANTILE|DOPACITYMINMAX")  // ← Highlight outliers
    .style({
        colorscheme: ["#0571b0", "#f7f7f7", "#ca0020"],
        opacity: 0.85,
        dopacitypow: 1,
        dopacityscale: 1,
        showdata: "true"
    })
    .define();
```

### Glow Effect (GLOW type modifier)

The `GLOW` modifier adds a soft radial glow/halo around CHART bubbles and dots — no extra layers needed.

**Apply to any CHART layer:**
```javascript
.type("CHART|BUBBLE|SIZE|VALUES|GLOW")
// also works with DOT, SYMBOL, etc.
.type("CHART|DOT|GLOW")
```

**Key points:**
- Works with `BUBBLE`, `DOT`, `SYMBOL`, and other `CHART` subtypes
- No additional style properties required — glow inherits the layer's `colorscheme`
- Combine freely with other modifiers: `SIZE`, `VALUES`, `CATEGORICAL`, `GLOW`
- Especially effective on dark basemaps (`CartoDB - Dark matter`, `VT_TONER_LITE`)

**Example — glowing incident bubbles:**
```javascript
ixMap.layer("incidents")
    .data({ obj: incidentData, type: "json" })
    .binding({ geo: "lat|lon", value: "ines", title: "name" })
    .type("CHART|BUBBLE|SIZE|VALUES|GLOW")
    .style({
        colorscheme: ["#ff6d00", "#b71c1c"],
        fillopacity: 0.92,
        scale: 2.2,
        sizepow: 1,
        normalsizevalue: 7,
        linecolor: "#ffffff",
        linewidth: 1,
        showdata: "true"
    })
    .meta({ tooltip: "{{name}} — INES {{ines}}" })
    .define();
```

### Flow Visualization (VECTOR)

The `VECTOR` chart type creates directional arrows showing flows between geographic locations (origin → destination).

**Use cases:**
- Supply chain flows (supplier → buyer regions)
- Migration patterns (origin → destination cities)
- Trade routes (exporter → importer countries)
- Transportation flows (departure → arrival locations)
- Any directional relationship between two geographic positions

**Enable vector flows:**
```javascript
.type("CHART|VECTOR|BEZIER|POINTER")
.binding({
    position: "origin_field",      // Starting location (supplier, origin, exporter)
    position2: "destination_field"  // Ending location (buyer, destination, importer)
})
```

**⚠️ CRITICAL: VECTOR layers MUST use the SAME layer name as the base FEATURE layer!**

The VECTOR layer needs to resolve geographic positions from the base geometry. If layer names differ, position resolution fails and arrows won't appear.

```javascript
// ✓ CORRECT - Same layer name
myMap.layer("us_states").type("FEATURE").define();
myMap.layer("us_states").type("CHART|VECTOR|...").define();  // Same name!

// ✗ WRONG - Different layer names
myMap.layer("us_states").type("FEATURE").define();
myMap.layer("migration_flows").type("CHART|VECTOR|...").define();  // FAILS! Different name
```

**Key Features:**

1. **Two Position Bindings (Required):**
   - `position`: Origin/source location field
   - `position2`: Destination/target location field
   - Both fields must reference geographic locations (region names, city names, lat/lon)
   - **CRITICAL:** VECTOR layer must share same layer name as base FEATURE layer for position resolution

2. **Type Modifiers:**
   - `BEZIER`: Creates smooth curved arrows (vs straight lines)
   - `POINTER`: Adds arrowheads showing direction
   - `DASH`: Creates dashed lines instead of solid
   - `NOSCALE`: Prevents arrow thickness from scaling with zoom
   - `EXACT`: Positions arrows precisely at geographic coordinates
   - `AGGREGATE`: Aggregates multiple flows between same origin-destination pair
   - `SUM`: Sums values when aggregating (use with AGGREGATE)
   - `FADEIN`: Makes vectors fade in gradually when drawn (use when user asks for fade-in animation)

3. **Visual Encoding:**
   - **Size:** Flow thickness based on numeric value (e.g., trade volume, order count)
   - **Color:** Arrow color based on category (e.g., by origin region, product type)
   - **Opacity:** Transparency to handle overlapping flows

**Complete Example: Regional Supply Flows**

```javascript
// Data structure: CSV with origin-destination pairs
// origin,destination,value,category
// Lombardia,Lazio,150000,Manufacturing
// Piemonte,Campania,95000,Agriculture
// ...

myMap.layer("supply_flows")
    .data({
        url: "https://cdn.jsdelivr.net/gh/user/repo@main/supply-flows.csv",
        type: "csv"
    })
    .binding({
        position: "origin",        // Supplier region
        position2: "destination",  // Buyer region
        title: "origin"
    })
    .type("CHART|VECTOR|BEZIER|POINTER|NOSCALE|EXACT|AGGREGATE|SUM")
    .style({
        colorscheme: [
            "#1F77B4", "#FF7F0E", "#2CA02C", "#D62728", "#966ABE",
            "#8C564B", "#E377C2", "#7E7E7E", "#BCBD22", "#18BECF"
        ],
        colorfield: "origin",      // Color arrows by origin region
        sizefield: "value",        // Arrow thickness by trade value
        opacity: 0.67,
        units: "€",
        rangescale: -7,            // Bow/curvature: 0=straight, ±7=good start, range ±20
        showdata: "true"
    })
    .meta({
        tooltip: `
            <strong>Flow:</strong> {{origin}} → {{destination}}<br>
            <strong>Value:</strong> €{{value}}<br>
            <strong>Category:</strong> {{category}}
        `
    })
    .title("Regional Supply Flows")
    .define();
```

**Configuration Tips:**

**For clear directional visualization:**
```javascript
.type("CHART|VECTOR|BEZIER|POINTER")  // Smooth curves with arrows
.style({
    fillopacity: 0.65,  // Prefer fillopacity over opacity
    scale: 1.5,         // Overall vector size multiplier
    sizepow: 1,         // Linear size contrast (1=linear, <1=more contrast, >1=less contrast)
    rangescale: -7      // Bow/curvature: 0=straight, ±7=good start, range ±20 — NOT for sizing
})
```

**For aggregated flows (multiple records per route):**
```javascript
.type("CHART|VECTOR|BEZIER|POINTER|AGGREGATE|SUM")  // Sum values per route
```

**For fade-in animation:**
```javascript
.type("CHART|VECTOR|BEZIER|POINTER|FADEIN")  // Vectors fade in on draw
.style({
    fillopacity: 0.67,
    scale: 1.5
})
```

**For animated flowing arrows (DASH):**
```javascript
.type("CHART|VECTOR|BEZIER|POINTER|FADEIN|DASH")  // Animated dashes flow along the arrow path
.style({
    fillopacity: 1,
    scale: 0.6
})
```
- `DASH` renders the vector as animated dashes that move in the direction of flow — great for conveying movement/migration
- Can combine with `BEZIER`, `POINTER`, `FADEIN` freely
- For static dashed lines (no animation) use `DASH|NOSCALE` without BEZIER

**For minimal visual weight (static dashes):**
```javascript
.type("CHART|VECTOR|DASH|NOSCALE")  // Dashed lines, constant thickness, no animation
.style({
    fillopacity: 0.4    // Prefer fillopacity over opacity
})
```

**Data Requirements:**

Your CSV must have at minimum:
- **Origin field:** Geographic identifier (region name, city, lat/lon)
- **Destination field:** Geographic identifier (region name, city, lat/lon)
- **Optional value field:** Numeric value for flow thickness
- **Optional category field:** For color coding

**Example Data Structure:**

```csv
origin,destination,value,category
Lombardia,Lazio,150000,Manufacturing
Piemonte,Campania,95000,Agriculture
Veneto,Sicilia,120000,Services
Emilia-Romagna,Toscana,85000,Technology
...
```

**Multi-Layer Pattern: Flows + Base Map**

Combine VECTOR flows with a base FEATURE layer for context. **CRITICAL: Both layers MUST use the same layer name!**

```javascript
// Layer 1: Base map (regions) - FEATURE layer
myMap.layer("regions")  // ← Layer name: "regions"
    .data({
        url: "https://raw.githubusercontent.com/openpolis/geojson-italy/master/topojson/limits_IT_regions.topo.json",
        type: "topojson",
        name: "regions"
    })
    .binding({
        geo: "geometry",
        id: "reg_name",
        title: "reg_name"
    })
    .type("FEATURE")
    .style({
        colorscheme: ["#e0e0e0"],
        fillopacity: 0.07,              // Very subtle background
        linecolor: "#666666",
        linewidth: 1.0,
        showdata: "true"
    })
    .define();

// Layer 2: VECTOR flows (origin → destination) - SAME LAYER NAME!
myMap.layer("regions")  // ← SAME name: "regions" (NOT "flows"!)
    .data({
        url: "https://cdn.jsdelivr.net/gh/user/repo@main/flows.csv",
        type: "csv"
    })
    .binding({
        position: "origin_region",
        position2: "destination_region"
    })
    .type("CHART|VECTOR|BEZIER|POINTER|AGGREGATE|SUM")
    .style({
        colorscheme: ["#FF7F0E", "#2CA02C", "#D62728"],
        colorfield: "origin_region",
        sizefield: "value",
        fillopacity: 0.67,
        showdata: "true"
    })
    .define();
```

**Why same layer name matters for VECTOR:**
- VECTOR layer needs to resolve `position` and `position2` fields to geographic coordinates
- Position resolution happens by looking up locations in the base FEATURE layer's geometry
- If layer names differ, ixMaps cannot find the geometry to resolve positions
- Result: Arrows don't appear, no error message, silent failure
- ✅ **Solution:** Always use identical layer names for base FEATURE and VECTOR overlay

**Comparison: VECTOR vs BUBBLE**

| Aspect | VECTOR | BUBBLE |
|--------|--------|--------|
| **Purpose** | Show directional flows | Show quantities at locations |
| **Positions** | Two (origin + destination) | One (single location) |
| **Visual** | Arrows/lines between points | Circles at points |
| **Best for** | Relationships, movements, trade | Totals, rankings, distributions |
| **Aggregation** | Sums flows per route | Sums values per location |

**When to Use VECTOR:**
- ✅ Data has origin-destination pairs
- ✅ Direction matters (who supplies to whom, where people migrate)
- ✅ Showing relationships between locations
- ✅ Trade routes, supply chains, migration patterns

**When to Use BUBBLE Instead:**
- ✅ Single location per record
- ✅ Showing totals or rankings per location
- ✅ No directional relationship

**Real-World Example:**

See `/Users/gjrichter/Work/Claude Code/mepa_forniture.html` for a complete implementation showing:
- Inter-regional supply flows in Italian public procurement
- VECTOR flows with BEZIER curves
- Aggregation of multiple orders per supplier-buyer pair
- Color by supplier region, size by economic value
- Combined with BUBBLE overlay for regional totals

**Troubleshooting:**

**Issue:** Arrows don't appear
- Check that both `position` and `position2` fields exist in your data
- Verify field names match exactly (case-sensitive)
- Ensure geographic locations can be resolved (region/city names match map data)

**Issue:** All arrows same thickness
- Add `sizefield` to style
- Ensure value field contains numeric values
- Try adjusting `rangescale` (default is often too small)

**Issue:** Too many overlapping arrows
- Reduce opacity: `opacity: 0.4`
- Use AGGREGATE|SUM to combine duplicate routes
- Filter data to show only significant flows (top N by value)

**Issue:** Arrows too thick or too thin
- Use `scale` property to globally adjust thickness
- For constant thickness: add `NOSCALE` flag

**Issue:** Arrows too straight (need more curve/bow)
- Adjust `rangescale` — start with `-7`, range is roughly -20 to +20
- `0` = straight, higher absolute value = more curvature
- Negative and positive values curve in opposite directions

---

### User-Defined Charts (CHART|USER)

`CHART|USER` lets you draw fully custom SVG shapes at each feature centroid using D3.
Use it when the built-in chart types (BUBBLE, BAR, VECTOR…) can't express what you need —
e.g. weather station symbols, wind barbs, thermometers, composite multi-variable icons.

#### Required script dependencies

Load D3 v3 **after** `ixmaps.js`, plus the chart script(s) you need:

```html
<script src="https://d3js.org/d3.v3.min.js"></script>
<!-- choose one or more: -->
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps_flat@master/usercharts/d3/chart.js"></script>       <!-- pinnacleChart -->
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps_flat@master/usercharts/d3/arrow_chart.js"></script> <!-- arrowChart -->
<!-- or define your own inline (see below) -->
```

#### Layer definition

```javascript
ixMap.layer("myLayer")
    .data({ obj: data, type: "json" })
    .binding({ lookup: "joinField", value: "mainValue", title: "nameField" })
    .type("CHART|USER|SIZE|VALUES")   // USER activates userdraw; add SIZE, VALUES, TITLE as needed
    .style({
        userdraw:         "myChart",       // must match window.ixmaps.myChart function name
        colorscheme:      ["#c62828","#1b5e20"],
        rangecentervalue: 0,               // optional: split color at this value
        fillopacity:      0.85,
        rangescale:       0.2,             // ← controls chart SIZE (NOT scale:)
        scale:            1,               // scale: does NOT affect size in USER charts
        units:            "%",
        linecolor:        "white",
        linewidth:        1,
        fadenegative:     0.05,
        showdata:         "true"
    })
    .define();
```

**⚠️ `rangescale` controls size, NOT `scale`**
- `args.theme.nRangeScale` ← set by `rangescale` style property
- `scale` is ignored for sizing in USER charts
- Formula inside your draw function: `nHeight = args.maxSize * 20 * (args.theme.nRangeScale || 1)`

#### Passing multiple data fields — `values:` binding

`args.item.szLabel` is **always null** in CHART|USER layers. Do NOT use it as a lookup key.

To pass multiple fields to the draw function use `values:` instead of `value:`:

```javascript
.binding({ lookup: "name", values: "wind_speed|wind_dir|precip", title: "name" })
// args.value  === args.values[0]  (ixMaps sets primary value from first field)
// args.values[1] === wind_dir
// args.values[2] === precip
```

Inside the draw function:
```javascript
var wind_speed = (args.values && args.values[0] != null) ? Number(args.values[0]) : (args.value || 0);
var wind_dir   = (args.values && args.values[1] != null) ? Number(args.values[1]) : 0;
var precip     = (args.values && args.values[2] != null) ? Number(args.values[2]) : 0;
```

**Rule:** put the "main" value first in the `values:` list — it becomes `args.value` and drives
SIZE scaling, legend range, and tooltip.

#### Writing a custom draw function

```javascript
window.ixmaps = window.ixmaps || {};
(function () {

    // _init — called ONCE before the first draw; set up shared SVG defs (gradients, etc.)
    ixmaps.myChart_init = function (SVGDocument, args) {
        var svg = d3.select(args.target);
        if (!ixmaps.d3svgDefs) {
            ixmaps.d3svgDefs = svg.append('defs');
        }
    };

    // draw function — called PER data item / feature centroid
    ixmaps.myChart = function (SVGDocument, args) {

        // ── Decode values ─────────────────────────────────────────────
        var val  = args.value || 0;                 // primary value (args.values[0])
        // var val2 = Number(args.values[1] || 0);  // additional fields if using values:

        if (!args.item) return false;

        // ── Compute chart size ────────────────────────────────────────
        var REF_H   = 900;   // reference height matching rangescale calibration
        var nHeight = args.maxSize * 20 * (args.theme.nRangeScale || 1);
        if (nHeight === 0) return false;
        var sc = nHeight / REF_H;  // scale factor: internal units → SVG screen units

        // ── Style helpers ─────────────────────────────────────────────
        var szColor  = args.color
                     || (args.item && args.item.szColor)
                     || args.theme.colorScheme[args.class || 0];
        var szFillOp = args.theme.fillOpacity || 0.85;
        var szOp     = args.theme.nOpacity    || 1;

        // ── Draw ──────────────────────────────────────────────────────
        var svg = d3.select(args.target);
        var g   = svg.append("g").attr("transform", "scale(" + sc + ")");

        var nMax    = Math.max(args.theme.nMax, Math.abs(args.theme.nMin));
        var nHeight = val / nMax * 900;   // height proportional to value in ref space
        nHeight    *= (args.theme.nRangeScale || 1);

        g.append("rect")
            .attr("x", -30).attr("y", -nHeight)
            .attr("width", 60).attr("height", nHeight)
            .attr("style", "fill:" + szColor + ";fill-opacity:" + szFillOp + ";opacity:" + szOp);

        // ── Optional value label ──────────────────────────────────────
        if (args.flag && args.flag.match(/VALUES/)) {
            var nFontSize = Math.max(nHeight / 5.5, 7);
            var szText    = ixmaps.formatValue(val, 0) + (args.theme.szUnits || "");
            svg.append("text")
                .attr("x", 0).attr("y", -(nHeight * sc + nFontSize * 0.6))
                .attr("style", "font-size:" + nFontSize + "px;text-anchor:middle;fill:" + szColor)
                .text(szText);
        }

        return { x: 0, y: 0 };   // return {x,y} offset — always {0,0} for per-feature charts
    };

})();
```

#### Key `args` properties

| Property | Set by |
|---|---|
| `args.value` | first field in `value:` or `values:` binding |
| `args.values[]` | all fields in `values:` binding (pipe-separated) |
| `args.theme.colorScheme` | `colorscheme` style array |
| `args.theme.nMax` / `nMin` | auto-computed from data range |
| `args.theme.nRangeScale` | `rangescale` style property |
| `args.theme.fillOpacity` | `fillopacity` |
| `args.theme.nOpacity` | `opacity` |
| `args.theme.nLineWidth` | `linewidth` |
| `args.theme.szLineColor` | `linecolor` |
| `args.theme.szUnits` | `units` |
| `args.theme.nFadeNegative` | `fadenegative` |
| `args.theme.szFlag` | type flags string (e.g. `"SHADOW\|GRADIENT"`) |
| `args.flag` | rendering flags (e.g. `"VALUES\|ZOOM"`) |
| `args.maxSize` | computed max display size (~300 at Italy zoom 4) |
| `args.class` | color-class index into colorScheme |
| `args.item.szLabel` | **always null** in CHART\|USER — do not use |
| `args.item.szTitle` | title field from binding |
| `args.item.szColor` | per-feature override color |
| `args.target` | CSS selector for the SVG element |
| `args.color` | resolved color for this item |
| `ixmaps.d3svgDefs` | shared `<defs>` element set in `_init` |

#### Type flags for `CHART|USER`

| Flag | Effect |
|---|---|
| `USER` | activates `userdraw` function lookup — required |
| `SIZE` | scales chart height by value magnitude |
| `VALUES` | render numeric labels on charts |
| `TITLE` | render title/name text |
| `ZOOM` | re-create gradients on zoom (quality, slower) |
| `SILENT` | suppress hover tooltips on this layer |

#### Pre-built user chart functions

| Script | Function (`userdraw`) | Shape |
|---|---|---|
| `chart.js` | `pinnacleChart` | triangle/peak with gradient |
| `arrow_chart.js` | `arrowChart` | up/down arrows for signed values |

#### Wind direction convention inside draw functions

```javascript
// staff/arrow points toward wind SOURCE ("comes from" = meteorological convention)
// Draw unrotated symbol pointing UP (−y), then rotate by wind_dir:
var gaWind = g.append("g").attr("transform", "rotate(" + wind_dir + ")");
// rotate(0)   → staff up   → wind from north ✓
// rotate(90)  → staff right → wind from east ✓
// rotate(180) → staff down  → wind from south ✓
```

#### Suppressing tooltips on background FEATURE layers

```javascript
.type("FEATURE|SILENT")   // disables hover interaction; .meta({tooltip:""}) alone is NOT enough
```

---

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

**CRITICAL - Tooltip field syntax:**
- ✅ Use simple field references: `{{value}}`, `{{name}}`, `{{population}}`
- ❌ **NEVER use format specifiers** - ixMaps does NOT support Mustache format syntax
- ❌ Wrong: `{{value:,.0f}}`, `{{price:$,.2f}}`, `{{rate:.1%}}` - These will NOT work!
- ✅ Correct: `{{value}}`, `{{price}}`, `{{rate}}`
- Field names reference properties directly (no "properties." prefix)
- Number formatting happens automatically via the `units` parameter in `.style()` (e.g., `units: " taxpayers"`)

**Example with correct syntax:**
```javascript
.meta({
    tooltip: `
        <div style="padding: 10px;">
            <h3>{{name}}</h3>
            <p><strong>Value:</strong> {{value}}</p>
            <p><strong>Category:</strong> {{category}}</p>
        </div>
    `
})
```

### Legend

**Default ixMaps legend (color scale + layer title):**
- Show open at start: pass `legend: "open"` in `ixmaps.Map()` options
- Show closed (collapsed): pass `legend: "closed"` in `ixmaps.Map()` options (default)
- Omit the option entirely = closed by default

```javascript
// ✅ Show built-in color legend open at start
ixmaps.Map("map", { mapType: "VT_TONER_LITE", mode: "info", legend: "open" })
```

**Custom legend text (ONLY on explicit user request):**
```javascript
// ⚠️ WARNING: this REPLACES (disables) the default color-scale legend!
// Only use when user explicitly provides a legend string or file to integrate.
.legend("Custom legend text")  // Call after .view(), before .layer()
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

**Optional `RELOCATE` modifier (suggest, don't add by default):** When grid cells are large, charts are placed at the fixed cell center, which may not reflect where points actually cluster. You can suggest adding `|RELOCATE` to place each chart at the **geographic center of its aggregated points** instead:

> "The charts are positioned at grid cell centers. If you'd like them repositioned to where the actual points cluster, I can add `RELOCATE` to the type."

```javascript
.type("CHART|BUBBLE|SIZE|AGGREGATE|RELOCATE")  // only on user request
```

**Key points:**
- Use `aggregationfield` to group by data field (comune, region, category)
- Use `gridwidth` for spatial density grid
- Both use `value: "$item$"` to count items
- Avoid `normalsizevalue` (max count unknown)
- These are complementary - choose based on your aggregation goal

### Categorical Coloring

#### Simple Categorical (Uniform Size)

**Point data:**
```javascript
.binding({ value: "category_field" })  // Field to colorize by
.type("CHART|BUBBLE|CATEGORICAL")      // ✅ legend items are selectable/filterable
.style({ colorscheme: ["100", "tableau"] })  // Dynamic colors
```
⚠️ **Do NOT use `CHART|DOT|CATEGORICAL`** — legend category items are non-selectable (cannot click to filter/highlight). Always prefer `CHART|BUBBLE|CATEGORICAL` for categorical point data.

**GeoJSON data:**
```javascript
.binding({ value: "NAME_ENGL" })  // Field to colorize by
.style({ colorscheme: ["100", "tableau"] })
.type("FEATURE|CHOROPLETH|CATEGORICAL")
```

#### Categorical Colors + Size by Value

When you want **both categorical coloring AND size by numeric value**:

⚠️ **ALWAYS add `SUM` modifier when using categorical colors with size** - This shows totals per category in the legend.

```javascript
.binding({
    geo: "lat|lon",
    value: "category_field",  // Field for categorical colors
    title: "name"
})
.type("CHART|BUBBLE|SIZE|CATEGORICAL|SUM")  // ALWAYS include SUM with categorical + size
.style({
    colorscheme: ["100", "tableau"],    // Dynamic categorical colors
    sizefield: "numeric_field",         // Field to control bubble size
    normalsizevalue: 1000000,           // Value = 30px size
    sizepow: 3,                         // Reduce size differences
    fillopacity: 0.7,
    units: " €",                        // Unit display in legend
    showdata: "true"
})
```

**Complete example:**
```javascript
.binding({
    geo: "lat|lon",
    value: "organization_type",  // Categorical colors
    title: "name"
})
.type("CHART|BUBBLE|SIZE|CATEGORICAL|SUM|VALUES")  // VALUES to show size values on bubbles
.style({
    colorscheme: ["100", "tableau"],
    sizefield: "revenue",       // Size by this numeric field
    valuefield: "revenue",      // CRITICAL: Must match sizefield when using VALUES
    normalsizevalue: 2000000,
    sizepow: 3,
    fillopacity: 0.7,
    units: " €",
    showdata: "true"
})
```

**Key points:**
- `value`: Category field for colors
- `sizefield`: Numeric field for bubble size
- `valuefield`: **CRITICAL - When using `VALUES` with categorical + size, MUST set to same field as `sizefield`** to display size values on bubbles
- `CATEGORICAL`: Enables categorical coloring
- `SIZE`: Enables size variation
- `SUM`: **ALWAYS include** - Shows sum of `sizefield` per category in legend
- `VALUES`: Displays values on bubbles (requires `valuefield` = `sizefield`)
- `colorscheme: ["100", "tableau"]`: Auto-generates colors for all categories
- Works with `normalsizevalue` and `sizepow` for size control
- `units`: Display unit in legend (e.g., " €", " people", " tons")

**Use cases:**
- Organizations colored by type, sized by revenue
- Cities colored by region, sized by population
- Products colored by category, sized by sales

### Explicit CATEGORICAL Color Binding (pin colors to values)

When the auto-palette colors are not acceptable and you need **specific colors for specific category values**, use the **parallel `colorscheme` + `values` arrays** pattern:

```javascript
.style({
    colorscheme: ["#e74c3c", "#27ae60", "#2980b9", "#8e44ad"],  // one color per value
    values:      ["Lombardia", "Toscana", "Veneto", "Lazio"],   // matching category labels
    colorfield:  "region",    // field in data that contains the category values
    showdata:    "true"
})
```

**Rules:**
- `colorscheme` and `values` arrays **must be the same length**
- Position i in `colorscheme` maps to position i in `values`
- Values not listed fall back to the first color in `colorscheme`
- Works for VECTOR, BUBBLE|CATEGORICAL, DOT|CATEGORICAL, and CHOROPLETH|CATEGORICAL layers

**Alternative — function as colorscheme:**
```javascript
.style({
    colorscheme: function(value) {
        const c = { "Lombardia": "#e74c3c", "Toscana": "#27ae60", "Veneto": "#2980b9" };
        return c[value] || "#aaaaaa";
    },
    colorfield: "region",
    showdata: "true"
})
```

**⚠️ What does NOT work:**
```javascript
// WRONG — embedding hex values directly in a data field is NOT supported:
.style({ colorfield: "color" })   // where data has { color: "#e74c3c" } — NOT supported
```

### Cross-Visualization Color Consistency (ixMaps + D3/ECharts/Vega)

When ixMaps is combined with an external chart library and both must show the **same colors per category**, build a shared lookup dictionary and derive ixMaps parallel arrays from it:

```javascript
// ── Shared color dictionary (outside both chart and map code) ─────────────
const palette = ["#e74c3c", "#27ae60", "#2980b9", "#8e44ad", "#d35400" /*, ... */];
const allNames = [...new Set(data.map(d => d.region))].sort();  // sort → stable order
const regionColors = {};
allNames.forEach((n, i) => { regionColors[n] = palette[i % palette.length]; });

// ── D3 / ECharts / Vega: use regionColors directly ───────────────────────
const colorFn = name => regionColors[name];

// ── ixMaps: build parallel arrays from the same dictionary ───────────────
// (translate names if data labels ≠ geometry labels)
const nameMap = { "LOMBARDIA": "Lombardia", "EMILIA ROMAGNA": "Emilia-Romagna" /*, ...*/ };
const ixColors = Object.keys(nameMap).filter(k => regionColors[k]).map(k => regionColors[k]);
const ixNames  = Object.keys(nameMap).filter(k => regionColors[k]).map(k => nameMap[k]);

// Apply to ixMaps layer:
myMap.layer("regions")
    .data({ obj: flowData, type: "json" })
    .binding({ position: "origin", position2: "destination" })
    .type("CHART|VECTOR|BEZIER|POINTER|AGGREGATE|SUM")
    .style({
        colorscheme: ixColors,   // ← same colors as external chart
        values:      ixNames,    // ← matching category names
        colorfield:  "origin",
        sizefield:   "value",
        fillopacity: 0.67,
        showdata:    "true"
    })
    .define();
```

**Key points:**
- Alphabetical sort of category names → deterministic assignment across page reloads
- Same `colorscheme` / `values` arrays reused across ALL ixMaps layers (VECTOR, BUBBLE, etc.)
- Name translation map needed when data labels differ from TopoJSON/geometry labels

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

⚠️ **CRITICAL - Local File Restrictions:**
- **ixMaps CANNOT load local files** - Due to browser CORS restrictions, ixMaps cannot use `file://` URLs or load data from the local filesystem via `.data({url: "local-file.json"})`
- **MUST use one of these approaches:**
  - **Inline data** (recommended for local files): Embed JSON array directly in HTML: `const data = [{...}];`, then use `.data({ obj: data, type: "json" })`
  - **External URL**: Host data on GitHub/CDN and use `.data({url: "https://...", type: "csv"})` (any supported type — see format table above)
- **When user provides local file**: Always embed the data inline in the HTML file, never try to load it with a file path

**Data handling options:**
- **Inline data**: Embed JSON array directly: `const data = [{...}];`
- **External URL**: Use `.data({url: "...", type: "..."})` — any type from the supported formats table
- **Multi-source programmatic loading**: Use `query` + `ixmaps.setExternalData()` to load multiple files, merge, and inject — see `API_REFERENCE.md` → `.data()` → "programmatic multi-source loading"
- **User describes data**: Create reasonable sample data
- **Ensure required fields**: lat/lon for points, geometry for GeoJSON

### Data Preprocessing with `process`

You can transform data **after loading but before visualization** using the `process` property. This is useful for standardizing values, computing derived fields, or converting formats.

**Syntax:**
```javascript
// IMPORTANT: process requires STRING representation of function
.data({
    url: "data.csv",
    type: "csv",
    process: preprocessFunction.toString()  // ← Convert to string!
})
```

**Preprocessing function:**

⚠️ **CRITICAL:** `data` is a `data.js` Table object — NOT a plain array. Use `data.column()`, `data.addColumn()`, etc. Do NOT use `data.forEach()` or array methods on it directly.

```javascript
// Define as var so you can use .toString()
var preprocessFunction = function(data) {
    // Standardize an existing column in place
    data.column("REGION").map(function(v) { return (v || "").toUpperCase(); });

    // Add a computed column — pass source column(s) directly to the callback
    data.addColumn({ source: ['FROM', 'TO'], destination: 'is_cross' }, function(from, to, row) {
        return from === to ? "false" : "true";
    });

    // Extract a sub-field from a nested JSON column
    data.addColumn({ source: 'current', destination: 'aqi' }, function(c, row) {
        return c ? Math.round(c.european_aqi || 0) : 0;
    });

    return data;  // Return the data.js Table object
};
```

**Common use cases:**
- **Standardize names**: Fix spelling variations, add hyphens, change case
- **Compute derived fields**: Add boolean flags, categories, or calculated values
- **Format conversion**: Parse dates, convert strings to numbers
- **Data enrichment**: Add lookup values or join with other data

**Key points:**
- ✅ Works with CSV, JSON, GeoJSON, and TopoJSON
- ✅ Function runs after data loads, before visualization
- ✅ New fields are available in `.binding()`, `.filter()`, and tooltips
- ✅ `data` is a `data.js` Table object — use `data.column()`, `data.addColumn()`, `data.select()`, etc.
- ✅ **CRITICAL:** Use `.toString()` to convert function: `process: myFunc.toString()`
- ✅ Define as `var functionName = function(data) {...};`
- ❌ **NEVER** use `data.forEach()` — `data` is not a plain array!
- ❌ **NEVER** reference outer-scope variables inside the function body — `.toString()` only serialises the function body; outer closures are `undefined` at evaluation time. Make functions fully self-contained.

**See `API_REFERENCE.md`** for detailed examples and advanced patterns.
**See `DATA_JS_GUIDE.md`** for the full `Data.Table` / `Data.Column` API reference.

## Centralized Data Hosting

### Overview

For production maps, host data files in a centralized GitHub repository for:
- CORS-enabled access (no local file restrictions)
- Persistent URLs that don't change
- Version control for data updates
- Easy sharing and reuse across maps
- Fast CDN delivery (jsDelivr)
- Free hosting for public data

**Problem with inline data:**
- Bloats HTML files (100KB+ for moderate datasets)
- Hard to update data without regenerating entire HTML
- Poor browser performance with large datasets

**Solution:**
Host data in GitHub repository, reference via CDN URL.

### Setup (One-Time)

1. **Create GitHub repository:**
   ```
   Name: ixmaps-data
   Visibility: Public (required for CORS access)
   ```

2. **Create directory structure:**
   ```bash
   mkdir -p by-date/$(date +%Y-%m)  # For quick uploads
   mkdir -p by-project               # For named projects
   mkdir -p templates                # Sample data
   ```

3. **Optional: Set up authentication for automated uploads:**
   ```bash
   # Create fine-grained token at https://github.com/settings/tokens
   # Permissions: Contents (Read and Write) for ixmaps-data repo only
   # Expiration: 90 days
   export IXMAPS_GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
   export IXMAPS_REPO_USER="<your-username>"
   # Add to ~/.bashrc or ~/.zshrc for persistence
   ```

### Upload Options

**Three pathways for different user levels:**

#### Option A: Automated Upload (Power Users)
If `IXMAPS_GITHUB_TOKEN` and `IXMAPS_REPO_USER` are set, skill will automatically upload data files via GitHub API.

#### Option B: Git Commands (Regular Users)
```bash
# Clone repo once
git clone https://github.com/<user>/ixmaps-data.git

# Upload workflow
cd ~/ixmaps-data
cp data.csv by-date/$(date +%Y-%m)/
git add .
git commit -m "Add dataset"
git push
```

#### Option C: Manual Upload (Beginners)
1. Generate data file
2. Go to https://github.com/<user>/ixmaps-data
3. Navigate to `by-date/YYYY-MM/` folder
4. Click "Add file" → "Upload files"
5. Drag and drop file
6. Commit changes
7. Use provided URL in map

### URL Formats

**Development (immediate updates):**
```javascript
url: "https://raw.githubusercontent.com/<user>/ixmaps-data/main/by-date/2026-02/cities.csv"
```

**Production (cached, fast):**
```javascript
url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/2026-02/cities.csv"
```

**Published (immutable):**
```javascript
url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@v1.0.0/by-date/2026-02/cities.csv"
```

### Example Usage

```javascript
// External hosted data (recommended for production)
myMap.layer("cities")
    .data({
        url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/2026-02/cities.csv",
        type: "csv"
    })
    .binding({
        geo: "lat|lon",
        value: "population",
        title: "name"
    })
    .type("CHART|BUBBLE|SIZE|VALUES")
    .style({
        colorscheme: ["#0066cc"],
        showdata: "true"
    })
    .define();
```

### Repository Structure

```
ixmaps-data/
├── by-date/           # Timestamp-based (default for skill)
│   ├── 2026-02/
│   │   ├── cities-1707834567.csv
│   │   └── covid-1707834890.json
│   └── 2026-03/
├── by-project/        # Named projects
│   ├── mepa-2024/
│   │   ├── data.csv
│   │   └── README.md
│   └── world-bank/
└── templates/         # Sample data
    └── sample-points.csv
```

### When Invoked - Data Hosting Workflow

When skill generates data files:

1. **Check for token**: Look for `$IXMAPS_GITHUB_TOKEN` and `$IXMAPS_REPO_USER`

2. **If token exists (automated):**
   - Upload file via GitHub API to `by-date/YYYY-MM/`
   - Generate timestamped filename (e.g., `cities-1707834567.csv`)
   - Get CDN URL from response
   - Update HTML template with CDN URL
   - Report: "✓ Data hosted at: [CDN URL]"

3. **If no token (manual):**
   - Save data file locally
   - Create HTML with inline data (always works)
   - Provide manual upload instructions with exact paths
   - Show expected CDN URL after upload

4. **Always offer both options:**
   ```
   "Your map is ready with [inline data / hosted data].

    For production use with smaller HTML files:
    - Upload to: github.com/<user>/ixmaps-data/upload/main/by-date/2026-02
    - Use URL: cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/2026-02/yourfile.csv"
   ```

### Security Considerations

✅ **DO:**
- Use fine-grained tokens (not classic tokens)
- Limit token scope to `ixmaps-data` repository only
- Set 90-day expiration with calendar reminder
- Store token in environment variable only
- Only upload public open data

❌ **DON'T:**
- Commit tokens to git
- Store tokens in skill files
- Use tokens with broad permissions
- Upload sensitive data, PII, or credentials
- Share tokens in chat or code

### Troubleshooting

**CDN not updating?**
- jsDelivr cache: 5-10 minute delay
- Use raw URL for development/testing
- Use versioned URL (@v1.0.0) for published maps

**404 Not Found?**
- Verify file path (case-sensitive)
- Check branch name (main vs master)
- Ensure repository is public

**CORS errors?**
- Local files (file://) won't work
- Use GitHub/CDN URLs only
- Repository must be public

**For complete guide, see DATA_HOSTING_GUIDE.md**

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
- **template-world-flows.html** - ✅ World-scale flow map (Equal Earth, GISCO countries, bezier arrows + bubbles)
  - Equal Earth projection (`mapType: "white"` + `mapProjection: "equalearth"`)
  - World bounding box (dense GeoJSON polygon — NOT D3 Sphere) + graticule
  - GISCO 60M countries TopoJSON
  - Any number of flow series defined in `FLOW_SERIES` config array
  - Each series: one destination + N origin points → auto-generates vector arrows, proportional bubbles, destination markers
  - Direct lat|lon VECTOR binding (no FEATURE base layer needed)
  - Auto-built legend and overlays from config
  - All styling via `STYLE` config object

- **template-change-choropleth.html** - ✅ World choropleth + signed change pointers (Equal Earth, GISCO countries)
  - Equal Earth projection + world bbox + graticule
  - GISCO 60M countries GeoJSON (GeoJSON required for CHOROPLETH property join)
  - 3-layer stack on shared layer name `"countries"`:
    1. `FEATURE` — geometry base with neutral fill for no-data countries
    2. `CHOROPLETH` — diverging color fill joined from data by `id` ↔ `lookup`
    3. `CHART|BAR|POINTER|ARROW|SIZE` — signed pointers at centroids (↑ growth, ↓ decline)
  - `CHART|BAR|POINTER|ARROW|SIZE` handles positive **and** negative values natively — no splitting needed
  - Key style params: `rangecentervalue: 0`, `fadenegative: 1`, `linecolor: "white"` for legibility
  - Explicit `CLASS_BREAKS` + `COLORSCHEME` arrays (diverging, centred at 0)
  - Config: `CHANGE_DATA`, `GEO_SOURCE` (url + idField + nameField), `DATA_*_FIELD`, `LEGEND_BANDS`, `TOOLTIP_TEMPLATE`
  - Auto-built legend (color bands + pointer direction key) and overlays from config

## Additional Resources

- **MAP_TYPES_GUIDE.md** - ⚠️ CRITICAL: Valid map types reference (read this first!)
- **SYMBOLS_GUIDE.md** - ⚠️ IMPORTANT: How to use custom SVG symbols/icons
- **DATA_HOSTING_GUIDE.md** - ⚠️ IMPORTANT: Complete guide to hosting data on GitHub + CDN
- **EXAMPLES.md** - Complete working examples
- **API_REFERENCE.md** - Full API documentation
- **DATA_JS_GUIDE.md** - ⚠️ CRITICAL: data.js Data.Table API (use this for all `process` functions)
- **TROUBLESHOOTING.md** - Common issues and solutions

## Notes

- All HTML files are standalone (no server needed)
- Dependencies loaded from CDN
- Maps fully interactive (zoom, pan, hover)
- Always test generated maps in browser
- Offer to adjust/enhance after creation
