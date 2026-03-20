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
   - **Also include `name`** whenever you plan to use `changeThemeStyle` at runtime (see rule 21)
5. **NEVER use `.tooltip()`** — doesn't exist
6. **NEVER combine `CHART` and `CHOROPLETH`** in one type string — mutually exclusive
7. **NEVER use `|EXACT` classification** — deprecated; use `QUANTILE`, `EQUIDISTANT`, or `CATEGORICAL`
8. **NEVER use `map` as variable name** — conflicts with internals; use `myMap`
8a. **NEVER use reserved HTML element IDs** — ixMaps owns `loading-div`, `tooltip`, `contextmenu`. Using them causes visible artifacts (a white box stuck on the map). Use `app-loading` or any other non-conflicting name for your own overlays.
9. **NEVER use `opacity`** in `.style()` — use `fillopacity`
10. **NEVER use `fillcolor`** — use `colorscheme: ["#hex"]`
11. **NEVER add `.legend("string")`** unless user explicitly requests it — destroys the default color legend
12. **ALWAYS use CDN** `https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/ixmaps.js`
    - **data.js** (`https://cdn.jsdelivr.net/gh/gjrichter/data.js@master/data.js`) is **already loaded by ixmaps** — `Data.*` functions are available inside `query:` and `process:` callbacks without any extra `<script>` tag
    - **Only include the data.js CDN explicitly** when you need `Data.*` functions *outside* ixmaps theme realization (e.g. pre-processing data in your own `<script>` block before defining layers)
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
21. **`changeThemeStyle` requires `name` in `.meta()`** — it finds themes by `name`, NOT by the string in `myMap.layer("name")`. Without `name`, calls silently have no effect:
    ```javascript
    .meta({ name: "punti", tooltip: "..." })   // ✅ — changeThemeStyle("punti", ...) will work
    .meta({ tooltip: "..." })                   // ❌ — theme is invisible to changeThemeStyle
    ```
22. **`hideTheme`/`showTheme` also resolve themes by `name` in `.meta()`** — same rule as `changeThemeStyle`. Once `name` is set, use `ixmaps.hideTheme(name)` / `ixmaps.showTheme(name)` for layer visibility. CSS injection (`[id*=":name:"] { display: none !important }`) remains a reliable fallback if `hideTheme` behaves unexpectedly for a given layer type.

---

## Choosing Visualization Type

```
Is your data...

├─ Points (lat/lon)?
│  ├─ Just locations?                    → CHART|DOT
│  ├─ Colored by category (legend-selectable)? → CHART|BUBBLE|CATEGORICAL  ⚠️ NOT DOT|CATEGORICAL
│  ├─ Sized by value?                    → CHART|BUBBLE|SIZE|VALUES
│  ├─ Density heatmap (circles)?         → CHART|BUBBLE|SIZE|AGGREGATE  + gridwidth:"5px"
│  ├─ Density heatmap (squares)?         → CHART|SYMBOL|GRIDSIZE|AGGREGATE|RECT|SUM|DOPACITY|VALUES  + symbols:["square"] + gridwidth:"80px"
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

> ⚠️ **Scrollbar pitfall** — never use `width: 100vw; height: 100vh` on the map `<div>`. When a scrollbar appears, `vw`/`vh` exceed the viewport and trigger a feedback loop. Always use:
> ```css
> html, body { width: 100%; height: 100%; overflow: hidden; }
> #map { width: 100%; height: 100%; }
> ```

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

**`geo: "geometry"` for GeoJSON point data** — works correctly with all CHART types.
ixmaps extracts full-precision coordinates directly from `Point.coordinates[lon,lat]`.
The `.type()` call (CHART|DOT, CHART|BUBBLE, etc.) controls the renderer — NOT the geo binding.
Use `geo: "geometry"` when source GeoJSON has Point geometry (preferred over property lat/lon fields which may be truncated).
Only use `geo: "lat|lon"` when the data has separate lat/lon columns (CSV, non-geometry JSON).

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
.style({
  gridwidth: "100px", normalsizevalue: "30", markersize: 2,
  colorscheme: ["#00e5ff"], fillopacity: 0.5,
  values: ["2020","2021","2022","2023"],  // ordered x-axis categories (also controls sort)
  showdata: "true"
})
// CATEGORICAL+AGGREGATE+RECT+SUM = aggregation semantics (NOT style)
// AREA|FADE|LASTARROW|FIXSIZE = visual style only
// FIXSIZE: all sparks same size; normalsizevalue controls chart scale (larger = smaller sparks)
// markersize: controls LASTARROW arrow head size (default ~8; use 1–3 for smaller arrows)
// ⚠️ normalsizevalue does NOT control arrow size — use markersize for that
```

**BOX|GRID and XAXIS — only add on explicit user request:**
- Default (no BOX|GRID): sparkline appears as a lightweight curve/arrow on the map; xaxis/chart still visible in tooltip via `{{theme.item.chart}}`
- `BOX|GRID|XAXIS` + `label:[]+xaxis:[]` in style: renders grid boxes + x-axis labels ON the map — heavier, less performant; use only when user wants to see the grid/axes directly on the map
- `BOX` alone (without GRID): adds a background box; can be combined with `TITLE` or `BOTTOMTITLE` for chart titles; scale-dependent via `boxupper`/`boxlower` and `titleupper`/`titlelower` style params

```javascript
// Only when user explicitly wants grid + axis labels on map:
.type("...NOCLIP|BOX|GRID|GRIDSIZE|XAXIS|CATEGORICAL|AGGREGATE|RECT|SUM|FIXSIZE")
.style({
  values: ["2020","2021","2022","2023"],
  label:  ["2020","2021","2022","2023"],
  xaxis:  ["2020","2021","2022","2023"],
})
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
| `normalsizevalue` | Data value that maps to "normal" display size. **Higher = SMALLER bubbles** — a larger reference value means most real data values fall below it, so bubbles render smaller. E.g. `"1000"` → smaller bubbles than `"300"`. |
| `gridwidth` | Grid cell size for aggregate layers (e.g. `"5px"`) |
| `rangecentervalue` | Diverging center; requires EVEN number of colors |
| `ranges` | Explicit class breaks (n+1 values for n colors) |
| `values` | Category list for CATEGORICAL (must be **strings**) |
| `align` | Chart anchor: `"left"` `"right"` `"top"` `"bottom"` `"above"` `"below"` |

**Trees (street-level) sizing baseline with `|GLOW`:**
- Use this as a reliable starting point for urban tree inventories (diameter in cm):
  - `objectscaling: "dynamic"`
  - `normalSizeScale: "5000"` (street-detail zoom reference)
  - `normalsizevalue: "220"` (higher value keeps bubbles controlled)
  - `scale: 0.32` (reduce apparent size added by `|GLOW`)
- Rule of thumb: with `|GLOW`, start with a **smaller `scale`** than non-glow bubbles.

> Complete style properties, dynamic opacity, diverging scales, categorical color binding → **API_REFERENCE.md § Style Properties**

---

## Runtime Controls (Filters & Layer Toggles)

Use these patterns when you need interactive UI controls (checkboxes, dropdowns) that modify the map after it's loaded.

### Filtering data across all layers — `changeThemeStyle`

`changeThemeStyle` triggers a re-render with a new data filter. For aggregate layers (grid counts, sparklines) it also **re-aggregates** — cells recount correctly with only the filtered rows.

**Prerequisites:**
1. Every layer that should respond must have `name` in its `.meta()` (see Rule 21)
2. Must call via the **Promise API** — `myMap.then(map => ...)` — NOT the fluent chain

```javascript
function applyFilter(activeValues) {
  // activeValues = array of selected values, e.g. ["M", "F"]
  const szFilter = (activeValues.length === totalCount)
    ? null   // all selected → remove filter
    : 'WHERE fieldName in (' + activeValues.join(',') + ')';

  myMap.then(function(map) {
    ['layerNameA', 'layerNameB', 'layerNameC'].forEach(function(id) {
      if (szFilter) {
        map.changeThemeStyle(id, 'filter:' + szFilter, 'set');
      } else {
        map.changeThemeStyle(id, 'filter', 'remove');
      }
    });
  });
}
```

> ⚠️ `ixmaps.map().changeThemeStyle()` returns `{szMap: null}` and silently does nothing — that form cannot find the live map instance.

### Toggling layer visibility — `hideTheme` / `showTheme`

`hideTheme` and `showTheme` resolve themes by `name` in `.meta()` — just like `changeThemeStyle`. Once `name` is set on every layer, the standard calls work:

```javascript
ixmaps.hideTheme("grid");       // hides layer named "grid"
ixmaps.showTheme("grid");       // shows it again
// Usage: <input type="checkbox" onchange="this.checked ? ixmaps.showTheme('grid') : ixmaps.hideTheme('grid')">
```

**Initially hidden layer** — add `visible: false` to `.style()` — do NOT call `hideTheme` from `myMap.then()`:

```javascript
myMap.layer("danno")
  .binding({ ... })
  .type("CHART|BUBBLE|CATEGORICAL|GLOW")
  .style({
    colorscheme: [...],
    values:      [...],
    visible:     false    // ✅ layer starts hidden; toggle via showTheme/hideTheme at runtime
  })
  .define();
// ❌ WRONG: myMap.then(function() { ixmaps.hideTheme('danno'); });  — unreliable timing
```

**CSS injection fallback** — if `hideTheme` behaves unexpectedly for a layer type, inject/remove a style rule instead:

```javascript
function toggleLayer(id, show) {
  const styleId = 'hide-' + id;
  if (!show) {
    if (!document.getElementById(styleId)) {
      const s = document.createElement('style');
      s.id = styleId;
      s.textContent = '[id*=":' + id + ':"] { display: none !important; }';
      document.head.appendChild(s);
    }
  } else {
    document.getElementById(styleId)?.remove();
  }
}
```

The category filter and layer-visibility toggle work independently and can be freely combined.

### Isolating categorical classes — `markThemeClass` / `unmarkThemeClass`

Use these to isolate one or more categorical classes in a `CATEGORICAL` layer. Marked classes stay visible; all others are hidden. When zero classes are marked, every class is shown again — no reset call needed.

```javascript
// Mark (isolate) class at index n — index = position in the `values:` array (0-based)
ixmaps.markThemeClass("themeName", n);

// Remove the isolation for class n
ixmaps.unmarkThemeClass("themeName", n);
```

**Clickable legend pattern** — toggle isolation on click, track state in a `Set`:
```javascript
const markedClasses = new Set();

function toggleClass(classIdx) {
    if (markedClasses.has(classIdx)) {
        markedClasses.delete(classIdx);
        ixmaps.unmarkThemeClass("myLayer", classIdx);
    } else {
        markedClasses.add(classIdx);
        ixmaps.markThemeClass("myLayer", classIdx);
    }
    // update legend UI: dim items not in markedClasses (only when set is non-empty)
    document.querySelectorAll(".leg-item").forEach(el => {
        const c = parseInt(el.dataset.class, 10);
        el.classList.toggle("off", markedClasses.size > 0 && !markedClasses.has(c));
    });
}
// HTML: <div class="leg-item" data-class="0" onclick="toggleClass(0)">…</div>
```

> Multiple classes can be marked simultaneously — all marked classes show together. The `themeName` must match `name` in `.meta()` (same rule as `changeThemeStyle`).

### Reacting to zoom / pan — `htmlgui_onZoomAndPan`

`map.on("zoomend", ...)` is **NOT implemented** in ixmaps. Instead, assign the hook as a method on the `ixmaps` object:

```javascript
// ✅ CORRECT — assign as method on ixmaps object
ixmaps.htmlgui_onZoomAndPan = function() {
  myMap.then(function(map) {
    var z = map.getZoom();
    var bounds = map.getBounds();  // returns [swLat, swLng, neLat, neLng] — NOT a LatLngBounds object
    // update basemap opacity and/or theme style based on zoom
    map.setBasemapOpacity(value, "absolute"); // ✅ NOT map.options({ basemapopacity: ... })
    map.changeThemeStyle("themeName", "fillopacity:" + ..., "set");
  });
};

// ❌ WRONG — standalone global function is NOT called by ixmaps
function htmlgui_onZoomAndPan() { ... }
```

Called by ixmaps on every zoom **and** pan event. Inside the Promise callback:
- `map.getZoom()` — current zoom level
- `map.getBounds()` — returns a flat **4-element array** `[swLat, swLng, neLat, neLng]`
  - ⚠️ **NOT** a Leaflet `LatLngBounds` object — `.contains()` is **not defined** on it
  - Always guard: `if (!bounds || bounds.length !== 4) return;`
  - Test a point manually: `t.lat < swLat || t.lat > neLat || t.lon < swLng || t.lon > neLng`

**Live legend pattern** — update sidebar counts from inline data on every pan/zoom:
```javascript
ixmaps.htmlgui_onZoomAndPan = function() {
  myMap.then(function(m) { updateLegend(m.getBounds()); });
};
// Also fire once on load:
myMap.then(function(m) { updateLegend(m.getBounds()); });

function updateLegend(bounds) {
  if (!bounds || bounds.length !== 4) return;
  const [swLat, swLng, neLat, neLng] = bounds;
  const counts = {};
  for (const t of DATA) {
    if (t.lat < swLat || t.lat > neLat || t.lon < swLng || t.lon > neLng) continue;
    counts[t.category] = (counts[t.category] || 0) + 1;
  }
  // update DOM legend elements with new counts
}
```

### Persisting the map view in the browser URL

Storing `lat`/`lng`/`zoom` in URL params lets users bookmark or share the exact view. Use `ixmaps.getCenter()` and `ixmaps.getZoom()` (global, no Promise needed) to read state, and `history.replaceState` to update silently.

**Important:** if another handler (e.g. a data provider) already owns `htmlgui_onZoomAndPan`, use a **wrapper** that calls `_prev` first — never overwrite blindly.

```javascript
/* ── 1. Read initial view from URL (before map init) ── */
var _urlParams = new URLSearchParams(window.location.search);
var _initLat   = parseFloat(_urlParams.get("lat"))  || 46.8;   // default fallback
var _initLng   = parseFloat(_urlParams.get("lng"))  || 2.3;
var _initZoom  = parseFloat(_urlParams.get("zoom")) || 6;

const myMap = ixmaps.Map("map", { ... })
    .view({ center: { lat: _initLat, lng: _initLng }, zoom: _initZoom })
    ...

/* ── 2. Write current view back to URL (debounced) ── */
var _urlUpdateTimer = null;

function updateUrlFromView() {
    try {
        var c = ixmaps.getCenter();
        var z = ixmaps.getZoom();
        if (!c || z == null) { return; }
        var params = new URLSearchParams(window.location.search);
        params.set("lat",  c.lat.toFixed(6));
        params.set("lng",  c.lng.toFixed(6));
        params.set("zoom", z.toFixed(4));
        history.replaceState(null, "", "?" + params.toString());
    } catch(e) {}
}

/* ── 3. Wrap the existing htmlgui_onZoomAndPan (don't replace it) ── */
function hookUrlUpdate() {
    var _prev = ixmaps.htmlgui_onZoomAndPan;   // save whatever is already there
    ixmaps.htmlgui_onZoomAndPan = function(nZoom) {
        try { if (_prev) { _prev.call(this, nZoom); } } catch(e) {}
        clearTimeout(_urlUpdateTimer);
        _urlUpdateTimer = setTimeout(updateUrlFromView, 400);
    };
}

/* ── 4. Install after map is ready; setTimeout fallback for edge cases ── */
myMap.then(function() { hookUrlUpdate(); updateUrlFromView(); });
setTimeout(function()  { hookUrlUpdate(); updateUrlFromView(); }, 1000);
```

> `ixmaps.getCenter()` / `ixmaps.getZoom()` are global — call them directly, no `myMap.then()` needed.
> Shareable URL format: `map.html?lat=48.856900&lng=2.347800&zoom=14.0000`

---

## Special Patterns (quick ref)

**Categorical color binding (pin specific colors to values):**
```javascript
.type("CHART|BUBBLE|CATEGORICAL")
.style({ colorscheme: ["#4fc3f7","#ffb300","#ef5350"], values: ["C","F","R"], showdata: "true" })
```
> ⚠️ **Always use `values`** with CATEGORICAL — without it, ixMaps assigns colors by **order of first occurrence** in the dataset, not by category name. This means color assignments change depending on data order and are unpredictable. `values` is the only reliable way to pin a specific color to a specific category.

**CATEGORICAL + bubble size from a numeric field (color by category AND size by value — single layer):**
```javascript
.binding({ geo: "lat|lon", value: "categoryField", title: "label", size: "numericField" })
.type("CHART|BUBBLE|CATEGORICAL|GLOW")
.style({ colorscheme: ["#4fc3f7","#ffb300","#ef5350"], values: ["C","F","R"], normalsizevalue: "80", showdata: "true" })
```
> Add `size: "numericField"` to `.binding()` to drive bubble radius from a numeric column independently from the category `value` field. This avoids needing a separate `SIZE|VALUES` layer when you want both category color and numeric sizing.

**Urban trees preset (species color + diameter size + GLOW):**
```javascript
.binding({ geo: "lat|lon", value: "SPECIE", size: "DIAMETRO", title: "LUOGO" })
.type("CHART|BUBBLE|CATEGORICAL|GLOW")
.style({
  colorscheme: [...],
  values: [...],               // species list, fixed order
  normalsizevalue: "220",
  scale: 0.32,
  fillopacity: 0.8,
  showdata: "true"
})
// map options: objectscaling:"dynamic", normalSizeScale:"5000"
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

---

## Facet Sidebar (filter panel updated on zoom/pan)

A facet sidebar lets users filter the map by clicking category values or dragging range sliders. It auto-updates on every zoom, pan, and filter change. This pattern requires three CDN plugins:

```html
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/plugins/format.js"></script>
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/plugins/facet.js"></script>
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/plugins/show_facets.js"></script>
```

### Sidebar HTML structure

Use the canonical template below. The counter-chips pattern (`🌳 N totali` / `👁 N in vista`) gives users immediate feedback on dataset size and current view. Adapt the emoji and label text to the subject matter.

```html
<!-- Sidebar — place outside #map_div, position with CSS (right panel, overlay, etc.) -->
<div id="sidebar_div" style="
    position:absolute; top:0; right:0; width:320px; height:100%;
    display:flex; flex-direction:column;
    background:rgba(248,247,242,0.97); box-shadow:-2px 0 8px rgba(0,0,0,0.08);
    font-family:sans-serif; z-index:900;">

  <!-- Title block -->
  <div style="padding:1.2em 1.2em 0.6em">
    <div style="font-size:1.3em; font-weight:700">🌳 Map Title</div>
    <div style="font-size:0.85em; color:#888; margin-top:0.2em">Subtitle / data source line</div>
  </div>

  <!-- Counter chips: total + in-view -->
  <div style="padding:0 1.2em 0.8em; display:flex; gap:0.5em; flex-wrap:wrap; border-bottom:1px solid #e0dfd8">
    <span id="count-chip-total" style="
        background:#fff; border:1.5px solid #ccc; border-radius:2em;
        padding:0.3em 0.9em; font-size:0.9em; white-space:nowrap">
      🌳 <b id="count-total">—</b> totali
    </span>
    <span id="count-chip-visible" style="
        background:#fff; border:1.5px solid #ccc; border-radius:2em;
        padding:0.3em 0.9em; font-size:0.9em; white-space:nowrap">
      👁 <b id="count-visible">—</b> in vista
    </span>
  </div>

  <!-- Active-filter banner (hidden until a filter is applied) -->
  <div id="filter-div" style="display:none; padding:0.4em 1.2em; background:#fff3cd; font-size:0.82em">
    <b>Filtro attivo:</b> <span id="filter" style="font-style:italic"></span>
    <button onclick="clearFilter()" style="
        float:right; background:none; border:none; cursor:pointer;
        font-size:1em; color:#666">✕</button>
  </div>

  <!-- Data source credit -->
  <div style="padding:0.4em 1.2em; font-size:0.78em; color:#999; border-bottom:1px solid #e0dfd8">
    Dati: <a href="#" target="_blank" style="color:#888">Source Name</a> (CC-BY)
  </div>

  <!-- Scrollable facet area -->
  <div style="overflow-y:auto; flex:1; padding:0 0.4em">
    <div id="show-facets-div"></div>
  </div>
</div>
```

**Set the total count once** after data loads (not on every draw):
```javascript
document.getElementById("count-total").textContent = DATA.length;
```

### `ixmaps.statistics` — the facet engine hook

Override `ixmaps.statistics` to compute and render facets. It is called by ixmaps after every draw:

```javascript
ixmaps.statistics = function (szId) {
    var themeObj = ixmaps.getThemeObj(szId);
    if (!themeObj) return;

    var lastFilter = themeObj.szFilter || "";

    // Fields to facet — order determines sidebar order.
    // NONUMERIC flag: suppresses numeric range sliders for fields that
    // have many unique numbers but are better treated as categories.
    // Fields with >N unique values auto-render as text-search inputs.
    ixmaps.data.fShowFacetValues = false;
    var szFieldsA = [
        "CATEGORY_FIELD",   // categorical — picks up theme colors if it's the value field
        "HEIGHT_CLASS",     // ordinal text
        "STREET_NAME",      // high-cardinality → auto text-search input
        "YEAR"              // numeric range slider (omit NONUMERIC to allow)
    ];

    var facetsA = ixmaps.data.getFacets(
        lastFilter, "user_legend", szFieldsA, szId, "map", "NONUMERIC"
    );

    if (facetsA && facetsA.length) {
        ixmaps.data.showFacets(lastFilter, "show-facets-div", facetsA);
    }

    // update visible-count chip — use your inline DATA array, not theme.indexA
    myMap.then(function(m) {
        var bounds = m.getBounds();
        if (!bounds || bounds.length !== 4) return;
        var swLat = bounds[0], swLng = bounds[1], neLat = bounds[2], neLng = bounds[3];
        var vis = 0;
        DATA.forEach(function(d) {
            if (d.lat >= swLat && d.lat <= neLat && d.lon >= swLng && d.lon <= neLng) vis++;
        });
        var el = document.getElementById("count-visible");
        if (el) el.textContent = vis;
    });
};
```

### `htmlgui_onDrawTheme` — fire on every zoom/pan/filter

```javascript
var _prevOnDrawTheme = ixmaps.htmlgui_onDrawTheme;

ixmaps.htmlgui_onDrawTheme = function (szId) {
    var themeObj = ixmaps.getThemeObj(szId);

    // skip helper/invisible layers
    if (!themeObj) { try { _prevOnDrawTheme && _prevOnDrawTheme(szId); } catch(e){} return; }
    if (themeObj.szFlag && themeObj.szFlag.match(/NOLEGEND/)) { try { _prevOnDrawTheme && _prevOnDrawTheme(szId); } catch(e){} return; }
    if (!themeObj.fVisible) { try { _prevOnDrawTheme && _prevOnDrawTheme(szId); } catch(e){} return; }

    ixmaps.statistics(szId);

    // show/hide active-filter banner
    if (themeObj.szFilter) {
        document.getElementById("filter").innerHTML = themeObj.szFilter;
        document.getElementById("filter-div").style.display = "";
    } else {
        document.getElementById("filter-div").style.display = "none";
    }

    try { _prevOnDrawTheme && _prevOnDrawTheme(szId); } catch(e) {}
};
```

### Clear all facet filters

```javascript
function clearFilter() {
    ixmaps.data.facetsFilterA = [];
    myMap.then(function(m) {
        m.changeThemeStyle("yourThemeName", "filter", "remove");
    });
}
```

### Facet button style overrides

`show_facets.js` generates `.btn-primary` buttons and `.badge` count labels. Override them to match your design:

```css
#show-facets-div .btn-primary {
    background-color: #fff;
    color: #334;
    border: none;
    border-bottom: solid rgba(128,128,128,0.25) 1px;
    border-radius: 0;
}
#show-facets-div .btn-primary:hover,
#show-facets-div .btn-primary:focus {
    background-color: #f0efe8;
    color: #112;
    outline: none; box-shadow: none;
}
#show-facets-div .badge {
    background: transparent;
    color: #778;
    font-size: 13px;
    font-weight: 400;
}
```

### `NONUMERIC` flag

Pass `"NONUMERIC"` as the last argument to `getFacets` to suppress range-slider facets for fields that happen to contain numbers but are really categories (e.g. year codes, ID numbers). Without this flag, any numeric field will render as a histogram + dual-handle slider.

### Category field gets theme colors automatically

If one of the facet fields matches the theme's `value` binding field, `show_facets.js` automatically colors each facet button with the corresponding theme color. No extra config needed — just include the field name.

### `theme.szFilter` vs `themeObj.szFilter`

`lastFilter = themeObj.szFilter || ""` — always read the filter from the theme object, not a local variable. The facet engine updates it internally; reading it fresh on each draw ensures facets reflect the current filter state.

---

## Overlay Indicator Layer (small dot on top of main bubble)

Use a second layer over the main bubbles to show a per-item status flag — e.g. failure risk class, alert state, certification level — without changing the primary color scheme.

### Pattern

1. **Add a constant `_dot` field** to source data so the size binding has a numeric value:
   ```javascript
   DATA.forEach(function(d) { d._dot = 50; });
   ```

2. **Filter to only the items worth showing** (e.g. only elevated/extreme risk, skip negligible):
   ```javascript
   var riskData = DATA.filter(function(d) {
       return d.RISK && d.RISK.match(/^(HIGH|EXTREME)/);
   });
   ```

3. **Define the overlay layer** using `CATEGORICAL|NOLEGEND` piped into the type string, `scale` for size, and `_dot` for the size binding:
   ```javascript
   var indicatorTheme = ixmaps.layer("risk_dots")
       .data({ obj: riskData, type: "json" })
       .binding({ geo: "lat|lon", value: "RISK", title: "NAME", size: "_dot" })
       .type("CHART|BUBBLE|CATEGORICAL|NOLEGEND")
       .style({
           colorscheme:    ["#ff9800", "#d32f2f"],
           values:         ["HIGH", "EXTREME"],
           normalsizevalue: "1000",   // same as main layer
           scale:           0.1,      // 10% of main bubble size → small indicator dot
           fillopacity:     1.0,
           strokewidth:     "0",
           showdata:        "true",
           align:           "bottom"  // anchor dot to bottom of main bubble
       })
       .meta({ name: "risk_dots" })
       .title("Risk indicator")
       .define();

   myMap.layer(indicatorTheme, "direct");
   ```

### Key rules

| Rule | Why |
|------|-----|
| `NOLEGEND` **must be piped** into the type string: `"CHART|BUBBLE|CATEGORICAL|NOLEGEND"` | Passing it only in `.meta({ flag: "NOLEGEND" })` is not enough — it must appear in the type flags so the draw hook skips this layer when scanning for the statistics theme |
| Use `scale: 0.1` rather than a very large `normalsizevalue` | `scale` is a clean multiplier applied after size calculation; `normalsizevalue` only works cleanly when the size field has a known typical range |
| Keep `normalsizevalue` the same as the main layer | Makes the dot size proportional to the main bubble for the same item — a bigger tree gets a bigger dot |
| Add `_dot` constant **before** filtering | `DATA.forEach(d => d._dot = 50)` on the source array means every filtered subset inherits the field |
| Filter to only meaningful states | Empty dots for the "all-clear" state (A/negligible) add clutter without information |

### `htmlgui_onDrawTheme` — skip the indicator layer

The draw hook must skip `NOLEGEND` layers to avoid running `ixmaps.statistics` on the indicator layer (which would show the risk categories as the main facets):

```javascript
// Already in the recommended hook template:
if (themeObj.szFlag && themeObj.szFlag.match(/NOLEGEND/)) {
    try { _prevOnDrawTheme && _prevOnDrawTheme(szId); } catch(e) {}
    return;
}
```

---

## CSS Conflicts with External Frameworks (Bootstrap etc.)

**Never load Bootstrap 3 (or similar CSS frameworks) alongside ixmaps.** Bootstrap 3's `.hidden { display:none !important }` rule silently breaks ixmaps UI elements — toolbar buttons, tooltip, and context menu all become invisible because:
- ixmaps creates elements with `class="hidden"` and controls visibility via `element.style.display = "flex/block/inline"`
- Bootstrap's `!important` on `.hidden` beats inline styles — ixmaps can never win
- The failure is **silent**: no JS errors, elements just stay invisible

### Root fix: standalone facet CSS

Instead of Bootstrap, include ~35 lines of standalone CSS that covers only what `show_facets.js` generates:

```css
/* ── Standalone facet CSS (replaces Bootstrap 3) ── */
.list-group { padding-left: 0; margin-bottom: 20px; list-style: none; }
.facet, .facet-active { margin-bottom: 0; }

/* CRITICAL: must use display:table, NOT flexbox.
   show_facets.js renders a colored proportion bar as a <div> immediately
   after each <button> inside .input-group. With display:table, they stack
   vertically (each becomes a table row). With display:flex, the bar becomes
   a horizontal sibling and disappears entirely. */
.input-group { position: relative; display: table; border-collapse: separate; width: 100%; }
.input-group .form-control { display: table-cell; width: 100%; }
.input-group-btn { display: table-cell; white-space: nowrap; width: 1%; vertical-align: middle; }
.form-control {
  display: block; width: 100%;
  padding: 4px 8px; font-size: 14px; line-height: 1.43;
  color: #555; background: #fff;
  border: 1px solid #ccc; border-radius: 4px;
}
.form-control:focus { outline: none; border-color: #66afe9; }

.btn {
  display: inline-block; padding: 5px 10px;
  font-size: 14px; font-weight: 400; line-height: 1.43;
  text-align: center; white-space: nowrap; vertical-align: middle;
  cursor: pointer; border: 1px solid transparent; border-radius: 4px;
  background: none; font-family: inherit;
}
.btn-block  { display: block; width: 100%; }
.btn-primary { color: #fff; background: #337ab7; border-color: #2e6da4; }
.btn-default { color: #333; background: #fff; border-color: #ccc; }
.btn-default:hover { background: #e6e6e6; border-color: #adadad; }
.badge {
  display: inline-block; min-width: 10px; padding: 3px 7px;
  font-size: 12px; font-weight: 700; line-height: 1;
  color: #fff; text-align: center; white-space: nowrap;
  vertical-align: baseline; background: #777; border-radius: 10px;
}
.pull-right { float: right !important; }
```

### Tooltip and context menu fix

ixmaps creates `#tooltip` and `#contextmenu` with `class="hidden visibility-hidden;"` (note: literal semicolon in the class attribute). Always add this safety fix in `myMap.then()`:

```javascript
myMap.then(function() {
    setTimeout(function() {
        ["tooltip","contextmenu"].forEach(function(id) {
            var el = document.getElementById(id);
            if (el) {
                el.classList.remove("hidden");
                el.classList.remove("visibility-hidden");
                el.style.display = "none";
            }
        });
    }, 500);
});
```

### Fallback: CSS attribute-selector workaround

If Bootstrap cannot be removed (e.g. it is required by other page content), use higher-specificity rules to override the conflict. Specificity (0,2,0) beats Bootstrap's (0,1,0):

```css
.hidden[style*="display: flex"],   .hidden[style*="display:flex"]   { display: flex   !important; }
.hidden[style*="display: block"],  .hidden[style*="display:block"]  { display: block  !important; }
.hidden[style*="display: inline"], .hidden[style*="display:inline"] { display: inline !important; }
```

> Note: CDN-loaded Bootstrap stylesheets are CORS-blocked, so JS-based patching of `cssRules` does not work. The CSS or JS approaches above are the only reliable fixes.
