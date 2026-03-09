---
name: create-ixmap
description: Creates interactive maps using ixMaps framework. Use when the user wants to create a map, visualize geographic data, or display data with bubble charts, choropleth maps, pie charts, or bar charts on a map.
argument-hint: "[filename] [options]"
allowed-tools: Write, Read, AskUserQuestion
---

# Create ixMap Skill

Creates complete HTML files with interactive ixMaps visualizations for geographic data.

## ⚠️ CRITICAL RULES (Never Skip)

1. **ALWAYS assign `ixmaps.Map()` to `const`** — discarded instance = silent failure
   ```javascript
   const myMap = ixmaps.Map("map", { ... });  // ✅
   ixmaps.Map("map", { ... });                 // ❌ instance lost
   ```
2. **ALWAYS include `.binding()`** with `geo` and `value`
3. **ALWAYS include `showdata: "true"`** in `.style()`
4. **ALWAYS include `.meta()`** with tooltip (default: `{ tooltip: "{{theme.item.chart}}{{theme.item.data}}" }`)
5. **NEVER use `.tooltip()`** — doesn't exist
6. **NEVER combine `CHART` and `CHOROPLETH`** in one type string — mutually exclusive
7. **NEVER use `|EXACT` classification** — deprecated; use `QUANTILE`, `EQUIDISTANT`, or `CATEGORICAL`
8. **NEVER use `map` as variable name** — conflicts with internals; use `myMap`
9. **NEVER use `opacity`** in `.style()` — use `fillopacity`
10. **NEVER use `fillcolor`** — use `colorscheme: ["#hex"]`
11. **NEVER add `.legend("string")`** unless user explicitly requests it — destroys the default color legend
12. **ALWAYS use CDN** `https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/ixmaps.js`
13. **NEVER use info from** `ixmaps.ca` or `ixmaps.com` — only `github.com/gjrichter/ixmaps-flat`
14. **ONE `.data()` per layer** — never chain two `.data()` calls on the same layer
15. **SAME LAYER NAME** for all layers sharing geometry — #1 cause of silent failures:
    - ✅ `myMap.layer("regions").type("FEATURE")` → `myMap.layer("regions").type("CHOROPLETH")`
    - ❌ `myMap.layer("regions").type("FEATURE")` → `myMap.layer("flows").type("CHOROPLETH")` — silently broken
16. **NO `FEATURE` on overlay layers** — base layer gets `FEATURE`; choropleth/chart overlays do not:
    - ✅ `myMap.layer("x").type("FEATURE")` → `myMap.layer("x").type("CHOROPLETH|CATEGORICAL")`
    - ❌ `myMap.layer("x").type("FEATURE")` → `myMap.layer("x").type("FEATURE|CHOROPLETH|CATEGORICAL")`
17. **`objectscaling: "dynamic"` requires `normalSizeScale`** — set to map scale denominator:
    zoom 4→30M · 5→15M · 6→8M · 8→2M · 10→500k · 12→100k
18. **`lookup` goes in `.binding()`**, not in `.data()`
19. **`values:` for CATEGORICAL must be strings** — ixMaps bug: numeric values silently ignored
20. **To make a fill invisible** use `colorscheme: ["none"]` — NOT `fillopacity: 0` (causes errors)

---

## Choosing Visualization Type

```
Is your data...

├─ Points (lat/lon)?
│  ├─ Just locations?                    → CHART|DOT
│  ├─ Colored by category (legend-selectable)? → CHART|BUBBLE|CATEGORICAL  ⚠️ NOT DOT|CATEGORICAL
│  ├─ Sized by value?                    → CHART|BUBBLE|SIZE|VALUES
│  ├─ Density heatmap (circles)?         → CHART|BUBBLE|SIZE|AGGREGATE  + gridwidth:"5px"
│  ├─ Density heatmap (squares)?         → CHART|SYMBOL|AGGREGATE|RECT|SUM|GRIDSIZE  + symbols:"square"
│  ├─ Sparklines per grid cell?          → CHART|SYMBOL|PLOT|LINES  (see Sparklines below)
│  ├─ Flows origin→destination?          → CHART|VECTOR|BEZIER|POINTER
│  └─ Multi-value per point?             → CHART|SYMBOL|SEQUENCE  (|STAR for 5+ categories)
│
└─ Polygons (GeoJSON/TopoJSON)?
   ├─ Boundaries only?                   → FEATURE
   ├─ Colored by data (geometry+data)?   → FEATURE|CHOROPLETH  (|QUANTILE | |EQUIDISTANT | |CATEGORICAL)
   └─ Data joined to pre-loaded geometry?→ CHOROPLETH only — NEVER FEATURE|CHOROPLETH
```

**Key type modifiers:**
- `|GLOW` — glow effect on any CHART type
- `|DOPACITYMAX` — dynamic opacity (high values prominent); add `alpha: "field"` to `.binding()`
- `|DOPACITYMINMAX` — dynamic opacity (extremes prominent)
- `|AGGREGATE|SUM` / `|MEAN` / `|HEADTAIL` — aggregation method for density layers
- `|CATEGORICAL` — discrete category coloring; `values:` array in style maps to `colorscheme` in order

**VECTOR sub-modifiers:**
- `|DASH` — animated flowing dashes along flow direction (combine freely with BEZIER|POINTER|FADEIN)

> For full type-string reference and all modifiers → **API_REFERENCE.md § Visualization Types**

---

## Workflow

1. **Parse** the user's request: data source, visualization goal, styling preferences
2. **Ask** if key info is missing (data format? geographic scope?)
3. **Choose template**:
   - `template-points.html` — CSV/JSON with lat/lon
   - `template-geojson.html` — GeoJSON/TopoJSON
   - `template-multi-layer.html` — multiple layers with join
   - `template.html` — general purpose
4. **Write** the HTML file
5. **Validate before writing**:
   - [ ] `const myMap = ixmaps.Map(...)` — instance stored
   - [ ] `.binding()` has `geo` + `value`
   - [ ] `.style()` has `showdata: "true"`
   - [ ] `.meta()` present with tooltip
   - [ ] If `objectscaling:"dynamic"` → `normalSizeScale` set
   - [ ] Start with `scale: 1` — let user request size adjustments
6. **Confirm** file created; explain what it shows; offer to enhance

---

## Defaults

| Setting | Default |
|---------|---------|
| filename | `ixmap.html` |
| mapType | `"VT_TONER_LITE"` ← always use unless user asks otherwise |
| center | `{ lat: 42.5, lng: 12.5 }` (Italy) |
| zoom | 6 |
| colorscheme | `["#0066cc"]` |
| basemapopacity | 0.6 |
| flushChartDraw | 1000000 |
| tools | true |

**Valid basemaps** (case-sensitive): `"VT_TONER_LITE"` · `"white"` · `"CartoDB - Dark matter"` · `"CartoDB - Positron"` · `"Stamen Terrain"` · `"OpenStreetMap - Osmarenderer"`
❌ NOT: `"OpenStreetMap"` · `"OSM"` · `"CartoDB Positron"` → See **MAP_TYPES_GUIDE.md** for full list

---

## Map Init Pattern

```javascript
const myMap = ixmaps.Map("map", {
    mapType: "VT_TONER_LITE",
    mode:    "info",
    legend:  "closed",   // or "open"
    tools:   true
})
.view({ center: { lat: 42.5, lng: 12.5 }, zoom: 6 })
.options({
    objectscaling:   "dynamic",
    normalSizeScale: "8000000",   // match to zoom (zoom6≈8M, zoom12≈100k)
    basemapopacity:  0.6,
    flushChartDraw:  1000000
});
```

**Layer chain (order matters):**
```javascript
myMap.layer("name")
    .data({ url: "…", type: "csv" })   // OR obj: myArray
    .binding({ geo: "lat|lon", value: "fieldname", title: "label" })
    .filter('WHERE field == "value"')   // optional; use AND/OR not && /||
    .type("CHART|BUBBLE|SIZE|VALUES")
    .style({ colorscheme: ["#0066cc"], fillopacity: 0.7, showdata: "true" })
    .meta({ tooltip: "{{label}}: {{fieldname}}" })
    .title("Legend label")
    .define();
```

> Full `.options()` / `.style()` property reference → **API_REFERENCE.md § Map Constructor** and **§ Style Properties**

---

## Geometry Sources

### World countries (GISCO — preferred over world-atlas)
```javascript
.data({ url: "https://gisco-services.ec.europa.eu/distribution/v2/countries/topojson/CNTR_RG_60M_2020_4326.json", type: "topojson" })
.binding({ geo: "geometry", id: "CNTR_ID", title: "NAME_ENGL" })
// ⚠️ Join field is CNTR_ID (ISO-2) — NOT CNTR_CODE
```
Scales: `60M` (default/world) · `20M` · `10M` · `3M` · `1M` (country zoom)

### Germany municipalities (LAU 2021)
```javascript
.data({ url: "https://cdn.jsdelivr.net/gh/gjrichter/geo@028b3fe/lau/germany_lau_2021_4326.topojson", type: "topojson" })
.binding({ geo: "geometry", id: "LAU_ID", title: "LAU_NAME" })
// LAU_ID = 8-digit AGS · LAU_NAME = name · POP_DENS_2021 = density (useful for alpha/DOPACITYMAX)
```

### NUTS1 Germany
```javascript
.data({ url: "https://gisco-services.ec.europa.eu/distribution/v2/nuts/topojson/NUTS_RG_60M_2021_4326_LEVL_1.json", type: "topojson" })
.filter('WHERE CNTR_CODE == "DE"')
.binding({ geo: "geometry", id: "NUTS_ID", title: "NUTS_NAME" })
// NUTS_ID examples: "DE1", "DEA"  (CNTR_CODE works for NUTS, unlike country data which uses CNTR_ID)
```

> ⚠️ Local `file://` URLs are blocked by browser CORS — always use CDN or inline `obj:`
> Full geometry sources list → **API_REFERENCE.md § Data Configuration**

---

## Multi-Layer Join Pattern

When joining external data to geometry (e.g. TopoJSON + CSV statistics):

```javascript
// Step 1 — FEATURE base (geometry + id field for join)
myMap.layer("regions")
    .data({ url: "regions.topojson", type: "topojson" })
    .binding({ geo: "geometry", id: "reg_code", title: "reg_name" })
    .type("FEATURE")
    .style({ colorscheme: ["#ccc"], fillopacity: 0.1, linecolor: "#666", linewidth: 0.5, showdata: "true" })
    .define();

// Step 2 — CHOROPLETH overlay (SAME layer name, NO FEATURE, lookup joins to id)
myMap.layer("regions")
    .data({ url: "data.csv", type: "csv" })
    .binding({ lookup: "csv_code_col", value: "metric" })
    .type("CHOROPLETH|QUANTILE")
    .style({ colorscheme: ["#eee", "#00468b"], fillopacity: 0.75, showdata: "true" })
    .meta({ tooltip: "{{reg_name}}: {{metric}}" })
    .define();
```

**Critical:** `id` values in geometry must match `lookup` values in CSV exactly (case-sensitive).
Always inspect both sources to confirm field names before writing the join.

---

## Sparklines (CHART|SYMBOL|PLOT|LINES)

Two distinct patterns depending on data shape:

### Pattern A — single column, year as category (raw events)
```javascript
.binding({ geo: "lat|lon", value: "year" })   // year field = categorical x-axis
.type("CHART|SYMBOL|PLOT|LINES|AREA|FADE|LASTARROW|NOCLIP|GRIDSIZE|CATEGORICAL|AGGREGATE|RECT|SUM|FIXSIZE")
.style({ gridwidth: "100px", normalsizevalue: "100", colorscheme: ["#00e5ff"], fillopacity: 0.3, showdata: "true" })
// CATEGORICAL+AGGREGATE+RECT+SUM = aggregation semantics (NOT style)
// AREA|FADE|LASTARROW|FIXSIZE = visual style only
// FIXSIZE: all sparks same size; normalsizevalue controls size (larger = smaller sparks)
```

### Pattern B — multiple pre-aggregated columns
```javascript
.binding({ geo: "lat|lon", value: "val2020|val2021|val2022|val2023" })  // chain columns
.type("CHART|SYMBOL|PLOT|LINES|AREA|FADE|LASTARROW|NOCLIP|GRIDSIZE|FIXSIZE")
// No CATEGORICAL or SUM — data already aggregated
```

> Full sparkline reference, FIXSIZE/normalsizevalue details, point-anchored variant → **API_REFERENCE.md § CHART|SYMBOL|PLOT|LINES**

---

## Animated / Timeseries Maps

### Method A — `myMap.layer(theme, "direct")` (preferred)
```javascript
// ixmaps.layer() (global) builds theme WITHOUT adding to map
// myMap.layer(theme, "direct") = smart upsert: add on first call, replace on subsequent
function showYear(year) {
    const theme = ixmaps.layer("countries")
        .data({ obj: yearData[year], type: "json" })
        .binding({ geo: "lat|lon", value: "metric" })
        .type("CHART|BUBBLE|SIZE|VALUES")
        .style({ colorscheme: ["#0066cc"], fillopacity: 0.7, showdata: "true" })
        .meta({ name: "myTheme", tooltip: "{{label}}: {{metric}}" })
        .define();           // returns theme object, does NOT add to map
    myMap.layer(theme, "direct");   // smart upsert — no tracking needed
}
showYear("2023");
```

### Method B — explicit `addTheme` / `replaceTheme`
```javascript
let activeTheme = null;
let mapInstance = null;
myMap.then(map => { mapInstance = map; showYear("2023"); });

function showYear(year) {
    if (!mapInstance) return;
    const theme = ixmaps.layer("countries")
        .data({ obj: yearData[year], type: "json" })
        .binding({ geo: "lat|lon", value: "metric" })
        .type("CHART|BUBBLE|SIZE|VALUES")
        .style({ colorscheme: ["#0066cc"], fillopacity: 0.7, showdata: "true" })
        .meta({ name: "myTheme", tooltip: "{{label}}: {{metric}}" })
        .define();
    if (activeTheme) mapInstance.replaceTheme("myTheme", theme, "direct");
    else             mapInstance.addTheme("myTheme", theme, "direct");
    activeTheme = theme;
}
```
**Key:** `replaceTheme` avoids flicker vs remove+add. Theme `name` in `.meta()` is the upsert key.

> Time slider (`timefield` in `.binding()`), `setThemeTimeFrame()` → **API_REFERENCE.md § Time Slider**

---

## Key Style Properties (quick ref)

| Property | Notes |
|----------|-------|
| `colorscheme` | Array of hex colors. `["100","tableau"]` for auto-palette |
| `fillopacity` | 0–1. NEVER use `opacity` |
| `linecolor` / `linewidth` | NEVER `strokecolor` / `strokewidth` |
| `scale` | Uniform size multiplier (start at 1) |
| `normalsizevalue` | Data value mapping to 30 px |
| `gridwidth` | Grid cell size for aggregate layers (e.g. `"5px"`) |
| `rangecentervalue` | Diverging center; requires EVEN number of colors |
| `ranges` | Explicit class breaks (n+1 values for n colors) |
| `values` | Category list for CATEGORICAL (must be **strings**) |
| `align` | Chart anchor: `"left"` `"right"` `"top"` `"bottom"` `"above"` `"below"` |

> Complete style properties, dynamic opacity, diverging scales, categorical color binding → **API_REFERENCE.md § Style Properties**

---

## Special Patterns (quick ref)

**Categorical color binding (pin specific colors to values):**
```javascript
.type("CHART|BUBBLE|CATEGORICAL")
.style({ colorscheme: ["#4fc3f7","#ffb300","#ef5350"], values: ["C","F","R"], showdata: "true" })
```

**Dynamic opacity from a field:**
```javascript
.type("CHART|BUBBLE|SIZE|DOPACITYMAX")
.binding({ geo: "lat|lon", value: "count", alpha: "density" })
```

**Glow effect:**  add `|GLOW` to any CHART type

**Flows with animated dashes:**  `CHART|VECTOR|BEZIER|POINTER|DASH`

**CHART|USER (custom draw functions):** requires D3 v3 + arrow_chart.js → **API_REFERENCE.md § CHART|USER**

> Diverging scales, density patterns, road-tracing, SEQUENCE charts → **API_REFERENCE.md § Special Cases**
> Complete working examples → **EXAMPLES.md**
> Data preprocessing (data.js) → **DATA_JS_GUIDE.md**
> Symbols/icons → **SYMBOLS_GUIDE.md**
> Troubleshooting → **TROUBLESHOOTING.md**
