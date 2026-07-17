---
name: create-ixmap
description: Creates interactive maps using ixMaps framework. Use when the user wants to create a map, visualize geographic data, or display data with bubble charts, choropleth maps, pie charts, or bar charts on a map.
argument-hint: "[filename] [options]"
allowed-tools: Write, Read, AskUserQuestion, Bash
---

# Create ixMap Skill

Creates complete HTML files with interactive ixMaps visualizations for geographic data.

## ⚠️ CRITICAL RULES (Never Skip)

1. `ixmaps.Map()` returns a **MapBuilder** — use `.then()` to capture the real map instance

   Simple setup chains work without `.then()` via an internal queue mechanism:
   ```javascript
   // ✅ works for initial setup chain
   ixmaps.Map("map", { ... })
       .view({ ... })
       .options({ ... })
       .layer(theme);
   ```
   But `.then()` is **required** whenever you need the real map instance later —
   in event handlers, dynamic updates, or calls outside the chainable set
   (`removeTheme`, `changeThemeStyle`, `hideTheme`, `showTheme` etc.):
   ```javascript
   // ✅ always safe — prefer this pattern
   ixmaps.Map("map", { ... }).then(function(map) {
       map.view({ ... }).options({ ... }).layer(theme);
       button.onclick = function() { map.layer(newTheme); }; // real map instance available
   });

   // ⚠️ works for initial setup only — breaks if myMap is used later in event handlers
   const myMap = ixmaps.Map("map", { ... });
   myMap.view(...).layer(...);       // fine here — queued and executed on init
   myMap.layer(newTheme);            // risky if called from an event handler or timeout
   ```
2. **ALWAYS include `.binding()`** with `geo` and `value`
3. **ALWAYS include `showdata: "true"`** in `.style()`
4. **ALWAYS include `.meta()`** with tooltip (default: `{ tooltip: "{{theme.item.chart}}{{theme.item.data}}" }`)
   - **Also include `name`** whenever you plan to use `changeThemeStyle` at runtime (see rule 21)
5. **NEVER use `.tooltip()`** — doesn't exist
6. **NEVER combine `CHART` and `CHOROPLETH`** in one type string — mutually exclusive
7. **NEVER use `|EXACT` classification** — deprecated; use `CATEGORICAL`
8. **NEVER use `map` as variable name** — conflicts with internals; use `myMap`
8a. **NEVER use reserved HTML element IDs** — ixMaps owns `loading-div`, `tooltip`, `contextmenu`. Using them causes visible artifacts (a white box stuck on the map). Use `app-loading` or any other non-conflicting name for your own overlays.
9. **Prefer `fillopacity` over `opacity`** in `.style()` — both work, but `fillopacity` is the recommended form
10. **NEVER use `fillcolor`** — use `colorscheme: ["#hex"]`
11. **NEVER add `.legend("string")`** unless user explicitly requests it — destroys the default color legend
12. **ALWAYS use CDN** `https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@1/ixmaps.js`
    - **data.js** (`https://cdn.jsdelivr.net/gh/gjrichter/data.js@master/data.js`) is **already loaded by ixmaps** — `Data.*` functions are available inside `query:` and `process:` callbacks without any extra `<script>` tag
    - **Only include the data.js CDN explicitly** when you need `Data.*` functions *outside* ixmaps theme realization (e.g. pre-processing data in your own `<script>` block before defining layers)
13. **NEVER use info from** `ixmaps.ca` or `ixmaps.com` — only `github.com/gjrichter/ixmaps-flat`
14. **ONE `.data()` per layer** — never chain two `.data()` calls on the same layer
15. **🔑 SAME LAYER NAME = GEOMETRY REUSE** — see § Geometry Reuse Pre-flight Checklist below for the authoritative rules. Quick example:

    ```javascript
    // ✅ Both named "regions" → overlay binds onto regions' geometry
    myMap.layer("regions").data({url:geo}).type("FEATURE").define();
    myMap.layer("regions").data({url:csv}).binding({lookup:"code",value:"pct"})
                          .type("CHOROPLETH|QUANTILE").define();

    // ❌ Different names → overlay has nothing to draw on, silently broken
    myMap.layer("stats").type("CHOROPLETH").define();
    ```

    For runtime theme swapping (sidebar picker, time slider) → see § Multi-Layer Join Pattern · B. Swappable themes for the full `setTheme` / `removeTheme` pattern.

16. **NO `FEATURE` on overlay layers** — base layer gets `FEATURE`; choropleth/chart overlays do not:
    - ✅ `myMap.layer("x").type("FEATURE")` → `myMap.layer("x").type("CHOROPLETH|CATEGORICAL")`
    - ❌ `myMap.layer("x").type("FEATURE")` → `myMap.layer("x").type("FEATURE|CHOROPLETH|CATEGORICAL")`
16a. **`|SILENT` on a `FEATURE` base kills tooltips for every overlay reusing its geometry** — `SILENT` suppresses tooltips/legend/statistics for the theme it's attached to, but a CHOROPLETH/CHART overlay on the same layer name has no hover of its own; it relies on the base. Default to plain `FEATURE` (no `|SILENT`) whenever the overlay needs hover tooltips — which is the common case. Only add `|SILENT` to a base if you deliberately want the whole join (base + overlay) to have no tooltip at all (e.g. a decorative graticule with no overlay). See Silent Failure Hotspot #10.
17. **`objectscaling: "dynamic"` requires `normalSizeScale`** — set to map scale denominator:
    zoom 4→30M · 5→15M · 6→8M · 8→2M · 10→500k · 12→100k
18. **`lookup` goes in `.binding()`**, not in `.data()`
19. **`values:` for CATEGORICAL must be strings** — ixMaps bug: numeric values silently ignored
20. **To make a fill invisible** use `colorscheme: ["none"]` — NOT `fillopacity: 0`. ⚠️ ixMaps bug: `fillopacity: 0` is silently coerced to `1` (fully opaque), so it does the **opposite** of hiding the fill
21. **FEATURE layer styling depends on geometry type:**
    - **Line features** — `colorscheme` sets the line/stroke color; `linecolor` is overridden by `colorscheme` and has no effect. Use `colorscheme: ["none"]` to make lines invisible. Color classes (multi-value array) apply as line-color classes. Data-driven colorization (CHOROPLETH|QUANTILE, CHOROPLETH|CATEGORICAL, etc.) works symmetrically with polygon features — `colorscheme` drives stroke color instead of fill.
    - **Polygon features** — `colorscheme` sets the **fill color** (single value or array for color classes); `linecolor` sets the **border/outline color** of the polygon. `fillopacity` controls fill transparency; `linewidth` controls border thickness.
22. **`changeThemeStyle` requires `name` in `.meta()`** — it finds themes by `name`, NOT by the string in `myMap.layer("name")`. Without `name`, calls silently have no effect:
    ```javascript
    .meta({ name: "punti", tooltip: "..." })   // ✅ — changeThemeStyle("punti", ...) will work
    .meta({ tooltip: "..." })                   // ❌ — theme is invisible to changeThemeStyle
    ```
23. **`hideTheme`/`showTheme` also resolve themes by `name` in `.meta()`** — same rule as `changeThemeStyle`. Once `name` is set, use `ixmaps.hideTheme(name)` / `ixmaps.showTheme(name)` for layer visibility. CSS injection (`[id*=":name:"] { display: none !important }`) remains a reliable fallback if `hideTheme` behaves unexpectedly for a given layer type.
24. **NEVER use the same string for a layer name and a `meta.name`** — reusing one string for both has caused failures. They are different identifiers:
    - **Layer name** (`myMap.layer("comuni")`) = geometry bucket; shared by a FEATURE base and the overlays that reuse its geometry, and **not unique**. A standalone CHART layer with its own geo data can use any arbitrary name (even `"generic"`).
    - **`meta.name`** = the **unique** theme id used by `changeThemeStyle` / `hideTheme` / `showTheme` / `removeTheme`.
    Keep them distinct — e.g. layer `"comuni"` + `meta.name: "comuni-choropleth"`.

---

## 🔴 Silent Failure Hotspots

These produce **no error, no warning, no console message** — the map just silently renders wrong. Check these first when something looks broken.

| # | What you did | What happens | Fix |
|---|---|---|---|
| 1 | Omitted `showdata: "true"` | Layer loads, data processes, nothing renders — completely invisible | Add `showdata: "true"` to every `.style()` |
| 2 | Used different layer name for overlay vs FEATURE base | Overlay renders nothing; no error | Overlay name must exactly match the FEATURE base name |
| 3 | Omitted the `ixmaps.Map()` assignment (`var myMap = …`) | Map may partially init; further calls fail or do nothing | Always capture the instance in a variable named `myMap` (never `map`). Use `var`/outer scope if it's reassigned in `buildMap()` or shared across functions; `const` is fine for a single self-contained block |
| 4 | Omitted `name` in `.meta()` | `changeThemeStyle` / `hideTheme` / `showTheme` silently no-op | Add `name: "themeName"` to every `.meta()` you'll reference at runtime |
| 5 | Called `changeThemeStyle` via `ixmaps.map()` or fluent chain | Returns `{szMap: null}`; no update | Use `myMap.then(api => api.changeThemeStyle(...))` |
| 6 | Missing `.binding()` | Layer skipped entirely | `.binding()` with `geo` + `value` is required on every layer |
| 7 | Missing `.define()` | Layer never registered | `.define()` must close every layer chain |
| 8 | `objectscaling: "dynamic"` without `normalSizeScale` | All symbols invisible or wildly oversized | Add `normalSizeScale: "8000000"` (match to zoom level) |
| 9 | Overlay layer named differently from FEATURE base | No geometry to draw on → blank | Always check: overlay name == base name |
| 10 | `FEATURE\|SILENT` on base + overlay needs tooltips | Overlay renders but tooltip never fires | Drop `\|SILENT` from any base that has overlays needing hover |
| 11 | `values:` for CATEGORICAL contains numbers | Categories silently unmatched; no color applied | Cast all `values:` entries to strings: `["1","2","3"]` |
| 12 | `fillopacity: 0` to hide a fill | Silently coerced to `1` (fully opaque) — fill shows at full strength, the opposite of intended | Use `colorscheme: ["none"]` (array) to hide a fill; never `fillopacity: 0` |
| 13 | Redefining an overlay under a **new** `meta.name` without `removeTheme(prev)` | Old theme stays — themes stack | Reuse the **same** `meta.name` (auto-replaces) **or** call `api.removeTheme(prev)` before `.define()` |
| 14 | Geometry branch mismatch (main=2026 codes vs data=2024) | Some regions silently unjoined (Sardinia etc.) | Pin geometry to commit `0153a0e` for 2024-compatible ISTAT codes |
| 15 | Used `geometry:{type:"Sphere"}` on a non-Orthographic projection | Nothing renders; no error, theme reports done | `Sphere` is Orthographic-only — use the dense-polygon world-bounding-box technique for other projections |
| 16 | Used `geometry:{type:"Sphere"}` against an ixmaps-flat build without native Sphere support | Nothing renders; no error, theme reports done | Confirm the loaded engine build/version includes the fix (added 2026-07-03) before assuming a config mistake |

---

## Geometry Reuse Pre-flight Checklist

Run this mental check before writing **any** overlay layer (CHOROPLETH, CHART on polygons):

```
[ ] Is this overlay's myMap.layer("NAME") identical to the FEATURE base layer name?
    → If NO: rename it. A different name = no geometry = nothing renders.

[ ] Does this overlay need to be swappable at runtime (sidebar picker, time slider)?
    → If YES: add name to .meta(). Reuse the SAME meta.name on each swap → auto-replaces.
              (Or use a different name per theme + api.removeTheme(prev) before each .define().)
    → If NO: no meta.name required (unless changeThemeStyle is needed)
```

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
│  ├─ Multi-value per point?             → CHART|SYMBOL|SEQUENCE  (|STAR for 5+ categories)
│  └─ Stacked/grouped bars per location? → CHART|BAR|STACKED  (add |SIZE|GRID|BOX|VALUES for full display)
│     gridx:N in .style() = values per bar group (gridx:2 → 2 segments per bar; gridx:3 → 3 separate bars)
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
- `|CATEGORICAL` — discrete category coloring; `values:` array in style maps to `colorscheme` in order
- `|SILENT` — excludes layer from legend, statistics **and** suppresses tooltips on its items
- `|NOLEGEND` — excludes layer from legend only (tooltips still work)
- `|NOOUTLIER` — removes extreme outliers from classification calculations
- `|ZEROISNOTVALUE` — suppresses rendering where value ≤ 0 (useful for sparse/incomplete time series)
- `|NOSCALE` — disables dynamic zoom scaling; flows/symbols stay constant size regardless of zoom
- `|GRADIENT` — gradient color along flow lines (origin color → destination color); use with `CHART|VECTOR|BEZIER` — **gradient must be defined via `linecolor: ["#from","#to"]` array, NOT `colorscheme`**
- `|CLIPTOGEOBOUNDS` — clips chart rendering to the containing polygon boundary
- `|DOMINANT|PERCENTOFMEAN` — colors by which of multiple piped fields is above-mean dominant; useful for showing "winner" category per region
- `|DTEXT` — makes `VALUES`-generated text labels on `CHOROPLETH` themes properly sized (always pair with `|VALUES` on choropleth layers that show value labels)
- `|SMOOTH` — smoothing interpolation on sparkline curves
- `|SORT` / `|SORT|DOWN` — sort sparkline categories ascending / descending
- `|TEXTLEGEND` — renders category labels directly on chart symbols instead of in the legend box
- `|TEXTONLY` — text labels only, no chart symbol (combine with `CHART|LABEL|VALUES|FIXSIZE|NOLEGEND`)

**Aggregation modifiers** (replace the value of each cell with the aggregate):

| Modifier | Computes |
|---|---|
| `SUM` | Sum of all values in cell |
| `COUNT` | Count of rows in cell |
| `MEAN` | Arithmetic mean |
| `MIN` | Minimum value |
| `MAX` | Maximum value |

**Classification methods** (used with `CHOROPLETH` and `CHART`):

| Method | Description |
|---|---|
| `EQUIDISTANT` | Equal-width intervals across the data range |
| `QUANTILE` | Equal-count intervals — each class has the same number of features |
| `HEADTAIL` | Head/tail breaks — iteratively splits at the mean; best for heavy-tailed distributions |
| `NATURAL` | Jenks natural breaks — minimises within-class variance |
| `LOG` | Logarithmic intervals — useful when values span several orders of magnitude |

**VECTOR sub-modifiers:**
- `|DASH` — animated flowing dashes along flow direction (combine freely with BEZIER|POINTER|FADEIN)
- `|GRADIENT` — gradient color from origin to destination along each flow line

**Deprecated modifiers — do NOT use:**
- ~~`SIZEP1`~~ → use `SIZE` + `sizepow: 1` in `.style()` instead
- ~~`EXACT`~~ → use `CATEGORICAL` instead

> For full type-string reference and all modifiers → **API_REFERENCE.md § Visualization Types**

---

## Workflow

1. **Parse** the user's request: data source, visualization goal, styling preferences
2. **Ask** if key info is missing (data format? geographic scope?)
3. **Choose template**:
   - `template-points.html` — CSV/JSON with lat/lon
   - `template-geojson.html` — GeoJSON/TopoJSON
   - `template-multi-layer.html` — multiple layers with join
   - `template-kde.html` — weighted KDE / density heatmap (Turf.js extension)
   - `template.html` — general purpose
4. **Write** the HTML file
5. **Validate before writing**:
   - [ ] `myMap = ixmaps.Map(...)` — instance captured in a variable (`var` if reassigned/shared, `const` for a single block; never name it `map`)
   - [ ] `.binding()` has `geo` + `value`
   - [ ] `.style()` has `showdata: "true"`
   - [ ] `.meta()` present with tooltip
   - [ ] If `objectscaling:"dynamic"` → `normalSizeScale` set
   - [ ] Start with `scale: 1` — let user request size adjustments

   **Optional programmatic check** — for parameter-driven maps, validate a JSON config
   against `skill-ui.yaml` before generating:
   ```bash
   node validate-config.js config.json    # checks types, ranges, valid options, deps
   # one-time setup if missing: npm install js-yaml
   ```
6. **Confirm** file created; explain what it shows; offer to enhance

> **Hosting local data** — if the user's data is a local file but a layer needs a `data({url:…})`
> (CORS blocks `file://`), upload it to get a CDN URL:
> ```bash
> ./upload-helper.sh data.csv [project-name]   # GitHub API → git → manual fallback
> ```
> Needs `IXMAPS_GITHUB_TOKEN` + `IXMAPS_REPO_USER` env vars for automated upload; otherwise it
> prints manual steps. Full setup → **DATA_HOSTING_GUIDE.md**. (Or skip hosting entirely and
> inline the data via `obj:` — see § Data Configuration.)

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
| flushPaintShape | *(not set)* — set to `1000000` when rendering large polygon datasets (municipalities, communes) to avoid rendering hangs |
| zoomAnimation | `true` — smooth zoom transitions; set `false` to disable |
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

> ⚠️ **Custom top-left overlay (e.g. your own legend/layer panel) vs `tools`** — if you're placing your own HTML panel (not ixMaps' built-in legend) in the map's top-left corner, set `tools: false`. With `tools: true`, ixMaps creates its own UI overlay in that same corner, which visually collides with a custom panel there. This is independent of the "tools" link in the map's bottom footer (`.map-footer` chrome) — that stays regardless of this option.
>
> ⚠️ **Custom panel/legend needs `z-index: 1000` or higher** — ixMaps' own map surface (Leaflet panes: tile pane, marker pane, etc.) tops out around `z-index: 700`, so a custom overlay with a low z-index (e.g. the CSS default `10`) can render **underneath** the map instead of on top of it. Give any custom HTML panel `z-index: 1000`+ to sit above the map surface. Stay below ixMaps' own floating chrome (`#tooltip` is `10000`, `#contextmenu` is `99999`) so native tooltips/context menus can still render on top of your panel if they ever overlap it — `1000`–`2000` is a safe range.

### `mode`: pan on touch, info on desktop

`mode: "info"` makes a tap/click query features (tooltips) — good for a mouse, but on a touch device it fights with finger-dragging, so the map feels unresponsive to pan. Start touch devices in `"pan"` mode and keep `"info"` for mouse/desktop. Detect the **input type**, not the screen size — a coarse pointer means touch is the primary input (phones, tablets, touch laptops without a mouse):

```javascript
// touch (coarse pointer) → pan; mouse/desktop (fine pointer) → info
var MAP_MODE = (window.matchMedia && window.matchMedia("(pointer: coarse)").matches) ? "pan" : "info";

var myMap = ixmaps.Map("map", { mapType: "white", mode: MAP_MODE, legend: "closed", tools: true })
    .view({ center: { lat: 42.5, lng: 12.5 }, zoom: 6 })
    .options({ /* … */ });
```

- Use `(pointer: coarse)` — NOT a `max-width` breakpoint. Screen size ≠ input type (a small window on a desktop is still mouse-driven; a large tablet is still touch).
- Pure CSS media queries can't set `mode` (it's a JS init option), so this branch must run in JS before `ixmaps.Map(...)`.
- The user can still switch modes at runtime via the ixMaps tools toolbar; this only sets the **initial** mode.

### Projections

All projections use SVG-based rendering. Omit `mapProjection` for the default Web Mercator / Leaflet tile setup.

| `mapProjection` value | Also accepted | Projection |
|---|---|---|
| *(omit)* | — | Default Web Mercator (Leaflet tiles) |
| `"mercator"` | — | Mercator (SVG, no tile layer) |
| `"winkel"` | — | Winkel Tripel |
| `"equalearth"` | — | Equal Earth |
| `"albersequalarea"` | `"albers"` | Albers Equal-Area Conic |
| `"lambertazimuthalequalarea"` | `"lambert"` | Lambert Azimuthal Equal-Area (EPSG:3035) |
| `"orthographic"` | — | Orthographic (globe view) |

- Lookup is **case-insensitive**; unknown values fall back to Mercator
- For **any** projected map: use **array** `.view([lat, lng], zoom)` — object `{center,zoom}` does NOT work with projections
- Set `mapType` to the background/sea color instead of using CSS: `mapType: "#0a1929"` (dark), `mapType: "black"`, `mapType: "dark"`, `mapType: "white"`, or any hex color. Do **not** use `mapType: "white"` + CSS `background` on `#map` — set it directly in `mapType`.
- Add a graticule layer **before** data layers for smooth curves (see Graticule below)
- **Albers only:** pass `projectionParams` in map options to set custom standard parallels / center for conic tuning

#### Lambert projection (Eurostat style — Europe)
```javascript
var myMap = ixmaps.Map("map", {
  mapType:       "white",
  mapProjection: "lambert",      // Lambert Azimuthal Equal-Area — EPSG:3035
  mode:          "pan",
  legend:        "closed",
  tools:         false
})
.view([53.4, 16.9], 3.7)
.options({ basemapopacity: 0, flushChartDraw: 1000000 });
```

#### Equal Earth projection (world maps)
```javascript
var myMap = ixmaps.Map("map", {
  mapType:       "#0a1929",      // dark ocean — set background directly in mapType, not CSS
  mapProjection: "equalearth",
  mode:          "info",
  legend:        "closed",
  tools:         false
})
.view([0, 0], 1)                // zoom: 0–1 for world-scale projections
.options({ basemapopacity: 0, flushChartDraw: 1000000 });
```

#### Orthographic projection (globe view) — ocean/sea background
```javascript
var myMap = ixmaps.Map("map", {
  mapType:       "white",
  mapProjection: "orthographic",
  mode:          "info",
  legend:        "closed",
  tools:         false
})
.view([13.24, 23.2], 2)             // array [lat, lng] — required for orthographic
.options({ basemapopacity: 0.5, flushChartDraw: 1000000 })

// Ocean/sea background — native engine support, define BEFORE data layers so they draw on top.
.layer(
  ixmaps.Layer("Ocean")
    .data({
      obj: { type: "FeatureCollection",
             features: [{ type: "Feature", geometry: { type: "Sphere" }, properties: {} }] },
      type: "geojson"
    })
    .type("FEATURE|NOLEGEND|SILENT")
    .style({ colorscheme: ["#0a2a4a"], fillopacity: "1", showdata: "true", linecolor: "none", linewidth: "0" })
    .meta({ name: "Ocean", tooltip: "" })
    .json()
);
```
- `geometry: {type:"Sphere"}` (no `coordinates` — unlike every other GeoJSON type) draws the full visible-globe disc for the current rotation, and auto-recenters on every pan/zoom/rotate as part of the theme's ordinary redraw cycle — no `moveend`/`zoomend` listeners needed, unlike a hand-rolled geodesic-circle workaround.
- **Orthographic-only.** For every other projection (`equalearth`, `lambert`, etc.) `Sphere` is a no-op (nothing renders, no error) — those projections need the dense-polygon world-bounding-box technique instead (see the ocean-background layer in the Equal Earth/Lambert-style templates).
- Do **not** use a full ±180°/±90° world-bounding polygon for the orthographic ocean background (the classic d3 "Sphere hack") — this engine's orthographic renderer does adaptive horizon-clamping per vertex, and a polygon spanning both hemispheres collapses into a degenerate sliver instead of a disc. `{type:"Sphere"}` is the correct native replacement.
- ⚠️ Requires an ixmaps-flat build with native Sphere support (added 2026-07-03). If the sea silently doesn't render and the theme otherwise reports done with no error, the loaded engine predates this feature — confirm the build/version before assuming a config mistake.

### Graticule (world grid lines)
```javascript
(function() {
  var step = 10, features = [];
  for (var lon = -180; lon <= 180; lon += step) {
    var coords = [];
    for (var lat = -90; lat <= 90; lat += 2) coords.push([lon, lat]);
    features.push({ type:"Feature", geometry:{ type:"LineString", coordinates:coords }, properties:{} });
  }
  for (var lat = -80; lat <= 80; lat += step) {
    var coords = [];
    for (var lon = -180; lon <= 180; lon += 2) coords.push([lon, lat]);
    features.push({ type:"Feature", geometry:{ type:"LineString", coordinates:coords }, properties:{} });
  }
  myMap.layer("graticule")
    .data({ obj: { type:"FeatureCollection", features:features }, type: "geojson" })
    .binding({ geo: "geometry" })
    .type("FEATURE|SILENT")
    .style({ colorscheme: ["#7aaabb"], linewidth: 0.6 })
    .define();
})();
```
**Note:** `FEATURE|SILENT` layers do not need `value` in `.binding()` or `showdata` in `.style()` — omit both to avoid 'type not found' load errors.

Intermediate points every 2° ensure smooth curves in Lambert projection. Define graticule **before** the countries layer so it renders underneath.

---

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

## Tooltip Mustache Reference

Tooltips in `.meta({ tooltip: "..." })` use `{{…}}` placeholders. Two prefixes control formatting:

| Syntax | Behaviour |
|--------|-----------|
| `{{fieldname}}` | ixmaps-formatted value — may apply number formatting, units, rounding |
| `{{raw.fieldname}}` | **Raw unformatted value** — bypasses all ixmaps formatting; use this when you want pre-formatted strings (e.g. `"1.234.567"` from `.toLocaleString()`) or exact string values |
| `{{theme.item.chart}}` | Renders the built-in chart SVG/HTML for this item |
| `{{theme.item.data}}` | Renders the built-in data table for this item |

**`raw.` is the escape hatch** — whenever ixmaps mangles a value (reformats numbers, truncates strings, adds units), use `{{raw.field}}` to get the original data value unchanged.

> ⚠️ **`raw.` bypasses auto-formatting — use it only when you do NOT want ixmaps to format the value** (e.g. a year `2025` that should not become `2.025`). For everything else use `{{field}}`.
>
> ⚠️ **`datafields` is only for restricting `{{theme.item.data}}`** — it filters which fields appear in the built-in data table. All data fields are automatically available as `{{field}}` in custom tooltip templates; no need to list them in `datafields`.
>
> | Goal | Syntax | Example output |
> |---|---|---|
> | Auto-formatted number | `{{freq}}` | `"8.519"` |
> | String field | `{{provincia}}` | `"PD"` |
> | Raw unformatted number (special cases only) | `{{raw.anno}}` | `2025` |
> | Built-in value+label display | `{{theme.item.data}}` | ixmaps default table |
>
> **Pattern for CHOROPLETH tooltips:**
> ```javascript
> .binding({ lookup: "istat", value: "media", title: "comune" })
> .style({ showdata: "true" })   // no datafields needed for custom tooltip fields
> .meta({ tooltip: "<b>{{comune}}</b> ({{provincia}} — {{regione}})<br>N: {{freq}}<br>Tot: {{ammk}} k€<br>{{theme.item.data}}" })
> // string/number fields via {{field}}; use {{theme.item.data}} for the bound value display
> ```

### `{{theme.item.chart}}` on a CHOROPLETH → pulls a sibling CHART theme (not a histogram)

`{{theme.item.chart}}` does **not** always render the hovered theme's own chart. For a
**CHOROPLETH**, ixMaps' `__add_chart` scans all themes for a *sibling* chart theme to render
instead — so you can show a **per-feature line/sparkline (time series) inside a choropleth
tooltip** while the choropleth itself only carries a single value for colour. This is the
correct, native way to get "sparkline in the tooltip, not on the map" (no hand-rolled SVG).

The sibling is matched by **three conditions — all required**:

1. **Same base layer name** — the CHART theme must use the *same* `myMap.layer("NAME")` as the
   choropleth (so `szThemes` matches). Reuses the base geometry (see § Geometry Reuse).
2. **`szFlag` is a chart** — `CHART|…|PLOT|LINES` (or any `CHART`/`COMPOSECOLOR`).
3. **`title` binding == the choropleth's geo-key value** — ⚠️ **the trap.** CHART|PLOT items are
   keyed by *centroid coordinates*, so the primary key lookup fails and ixMaps falls back to
   matching the chart item's `szTitle` against the hovered choropleth's geo value
   (`hoveredItemId.split("::")[1]`). If you join on a **code** (base `id:"ISO3_CODE"`, choropleth
   `lookup:"countryiso3code"` → hovered item `…::IND`), the chart theme must bind
   **`title:"countryiso3code"`** (→ `szTitle "IND"`), **not** the human name. With the name the
   match silently fails and the tooltip shows the **class-distribution histogram** instead of the line.

**Switch the sparkline OFF the map but keep it in the tooltip** — give the CHART theme
scale-visibility thresholds so it isn't drawn at the working zoom, yet still feeds the tooltip:

```javascript
// choropleth: colour by latest year; its {{theme.item.chart}} will render the line below
myMap.layer("World_countries")
  .data({ obj: pivot, type: "jsondb" })
  .binding({ lookup: "countryiso3code", value: latestYear, title: "country_value" })
  .type("CHOROPLETH|QUANTILE|DOPACITYMAX")
  .style({ colorscheme: ["25","#F7FAF2","#669900"], showdata: "true", name: "choro" })
  .meta({ name: "choro", tooltip: "<b>{{country_value}}</b><br>{{theme.item.chart}}" })
  .define();

// sibling sparkline: SAME layer name, title == the join code, scale-gated off the map
myMap.layer("World_countries")
  .data({ obj: pivot, type: "jsondb" })
  .binding({ lookup: "countryiso3code", value: years.join("|"), title: "countryiso3code" }) // ← title = code
  .type("CHART|SYMBOL|SEQUENCE|PLOT|LINES|SIZE|AREA|LASTPOP|NOCLIP|BOX|BOTTOMTITLE|FAST")
  .style({
    colorscheme: ["#669900"], fillopacity: "0.1", scale: "0.06", linewidth: "10",
    maxvalue: "auto", xaxis: years.map(y => Number(y)%5===0 ? String(y) : " "),
    chartupper: "1:30000000", boxupper: "1:10000000", gridupper: "1:100000", // hidden at world zoom
    valuescale: "0",          // ← suppress per-point value labels → clean line (else cluttered)
    showdata: "true", name: "curves"
  })
  .meta({ name: "curves", tooltip: "{{theme.item.chart}}" })
  .define();
```

- `chartupper`/`boxupper`/`gridupper` keep the curve off the map until you zoom in; the tooltip
  chart renders regardless of those thresholds.
- If the choropleth join is by **name** instead of code, set the chart `title` to that same name field.
- Reference implementation: `flat_multi/.../pages/ACLED/political_violence.html`.

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

### Italy geometry sources (gjrichter/geo)

**Municipalities (comuni) — ISTAT, ~8 000 polygons, 500m simplified:**
```javascript
.data({ url: "https://raw.githubusercontent.com/gjrichter/geo/main/italy/boundaries/italy_istat_municipalities_4326_500m.topojson", type: "topojson" })
.binding({ geo: "geometry", id: "com_istat_code_num", title: "name" })
// com_istat_code     = zero-padded STRING "028001"  ← do NOT use for joins unless your data also has zero-padded strings
// com_istat_code_num = plain INTEGER    28001       ← use this for joins with ISTAT CSV data
// Useful properties: com_istat_code_num, com_istat_code, name, prov_istat_code_num, reg_istat_code_num
```

> ⚠️ **Geometry version pitfall** — the `main` branch of gjrichter/geo was updated to **2026 ISTAT codes** on 2026-03-24. Official data sources (MEF IRPEF, ISTAT CSVs) still use **2024 codes**. Using `main` will silently break the join for all Sardinian municipalities and any others renumbered in 2026. Pin to commit `0153a0e14da5dae877b8c94d6deb11f210d4660a` for 2024-compatible codes:
> ```
> https://raw.githubusercontent.com/gjrichter/geo/0153a0e14da5dae877b8c94d6deb11f210d4660a/italy/boundaries/italy_istat_municipalities_4326_500m.topojson
> ```

> ⚠️ **ISTAT code join pitfall** — the geometry exposes two variants of the municipality code:
> - `com_istat_code` is a **zero-padded string** (`"028001"`) — it will **not** match integers or un-padded strings from CSV data
> - `com_istat_code_num` is a plain **integer** (`28001`) — use this when your lookup data comes from ISTAT CSVs where codes are stored as numbers
>
> Always verify which variant matches your data before writing the join. Mismatching types silently renders only a fraction of features (those whose string representation happens to match).

⚠️ Use `flushPaintShape: 1000000` in `.options()` when rendering all 8 000 polygons to avoid hangs.

> ⚠️ Local `file://` URLs are blocked by browser CORS — always use CDN or inline `obj:`
> Full geometry sources list → **API_REFERENCE.md § Data Configuration**

---

## Multi-Layer Join Pattern

When joining external data to geometry (e.g. TopoJSON + CSV statistics), the overlay layer
**must reuse the FEATURE base's name** so it joins onto its geometry (see critical rule 15).

### A. Static overlay (base + one data-driven layer)

```javascript
// Step 1 — FEATURE base (geometry + id field for join)
myMap.layer("regions")
    .data({ url: "regions.topojson", type: "topojson" })
    .binding({ geo: "geometry", id: "reg_code", title: "reg_name" })
    .type("FEATURE")
    .style({ colorscheme: ["#ccc"], fillopacity: 0.1, linecolor: "#666", linewidth: 0.5, showdata: "true" })
    .define();

// Step 2 — CHOROPLETH overlay (SAME layer name "regions", NO FEATURE flag, lookup joins to id)
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

### B. Swappable themes on the same base (remove-then-define)

For apps where the user flips between multiple visualizations of the same geometry
(choropleth / dominant / sparkline / arrows / etc.), use **one FEATURE base** plus a single
swappable overlay always redefined under the **same layer name** as the base. Do **not**
create a separate layer per theme.

**Two identifiers — don't confuse them:**
- **Layer name** (`myMap.layer("comuni")`) = GEOMETRY bucket — must equal the FEATURE base's name (not unique).
- **meta.name** (`.meta({name: "pie-theme-rd"})`) = THEME identity — unique, and the **key that drives replacement**.
- ⚠️ **Never make these two the same string** (see Rule 24) — reusing one string for both has caused failures. Keep the `meta.name` distinct from the layer name.

**Replacement is automatic by `meta.name`.** Adding a theme whose `meta.name` already exists
on the map *replaces* the existing one in place. So there are two ways to swap:

- **Same `meta.name` on every swap → automatic replace** (simplest; no `removeTheme` needed).
- **Different `meta.name` per theme** (e.g. one per year/category) → each `.define()` ADDS a
  new theme, so you must track the previous name and call `api.removeTheme(prev)` before
  defining the next, or they stack. The example below uses this form.

The **`"direct"` flag** (aliases **`"fast"`**, **`"silent"`**), passed as the 2nd argument to
`.layer(...)`, makes the add/replace *fluent* — it suppresses the loading spinner and status
messages and skips the intermediate render flash during a replace. It does **not** decide
*whether* a replace happens (that's `meta.name`); it only makes the transition smooth. The
same flag also works as a mode on `changeThemeStyle`.

```javascript
// ONE FEATURE base — defined once, no meta.name so it's never removed
// ⚠️ NO |SILENT here: the swappable overlays below carry tooltips, and |SILENT
// on this base would kill hover for all of them (see Rule 16a).
myMap.layer("comuni")
    .data({ url: GEO_URL, type: "topojson" })
    .binding({ geo: "geometry", id: "com_istat_code_num", title: "name" })
    .filter("WHERE reg_istat_code_num == 1")
    .type("FEATURE")
    .style({ colorscheme: ["#d9e4dc"], fillopacity: 0.55, linecolor: "#8a9d8c", linewidth: 0.2, showdata: "true" })
    .define();

// Remove-then-define swapper.
// removeTheme lives on the embedded Api (not the MapBuilder shim), so the call
// goes through myMap.then(api => ...). Defining the new layer INSIDE the same
// callback guarantees remove-before-add ordering.
let ACTIVE_THEME_NAME = null;

function setTheme({ id, value, value100, type, style, tooltip }) {
  const themeName = "theme-" + id;
  const prev      = ACTIVE_THEME_NAME;
  const bind = { lookup: "ISTAT", title: "COMUNE", value };
  if (value100) bind.value100 = value100;

  myMap.then(api => {
    if (prev) { try { api.removeTheme(prev); } catch(e){} }

    const meta = { name: themeName };
    if (tooltip) meta.tooltip = tooltip;

    myMap.layer("comuni")                                 // ← same name as FEATURE base
      .data({ obj: DATA, type: "json", cache: "true" })
      .binding(bind)
      .type(type)
      .style(Object.assign({ showdata: "true" }, style))
      .meta(meta)                                         // ← meta.name = theme handle
      .define();

    ACTIVE_THEME_NAME = themeName;
  });
}

// Each sidebar click = one setTheme({id, ...}) call — overlays REPLACE, not stack.
setTheme({ id: "rd",        value: "% di RD [RD/RT]",
           type: "CHOROPLETH|QUANTILE|VALUES",
           style:{ colorscheme:["5","#FF4800","#7CB832","auto","#F7FA7A"], title:"% RD" }});
setTheme({ id: "sparkline", value: "% RD 2011|% RD 2012|% RD 2013|% RD 2014",
           type: "CHART|SYMBOL|PLOT|LINES|AREA|AGGREGATE|RECT|GRIDSIZE|MEAN",
           style:{ gridwidthpx:"150", xaxis:["2011","2012","2013","2014"] }});
```

**Common mistakes — DO NOT DO THIS:**
```javascript
// ❌ Different layer names → overlay has no geometry to bind to
myMap.layer("comuni").type("FEATURE").define();
myMap.layer("theme").type("CHOROPLETH")...   // blank / error

// ❌ No meta.name + no removeTheme → every click STACKS a new theme on the map
function setTheme(opts) {
  myMap.layer("comuni").type(opts.type)....define();   // stacks forever
}

// ⚠️ "direct"/"fast"/"silent" is a FLUENCY flag, NOT the replace mechanism.
// Replacement is keyed on meta.name; the flag only suppresses spinner/messages
// and the intermediate render flash. With NO meta.name it still stacks.
myMap.layer("comuni", "direct")...   // smooth, but only replaces if meta.name matches
```
For replacement, give each swap a **stable `meta.name`** (automatic replace) — or use
**different** names plus an explicit `removeTheme(prev)`. Either way the layer name stays
`"comuni"` so the overlay reuses the base geometry.

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
// LASTARROW = arrow marker on last point  |  LASTPOP = dot/pop marker on last point (use one or the other)
// MAX/MIN/MEAN/COUNT/SUM = aggregation modifiers — compute cell aggregate value; NOT sparkline visual markers
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

⚠️ `mapInstance` must be captured inside `.then(function(map) { mapInstance = map; })` — it is NOT the return value of `ixmaps.Map()`, which is a **MapBuilder**. The real map instance is only available inside `.then()`.

### Remove-then-define (needed only when meta.name varies)
```javascript
// This example gives each year a DIFFERENT meta.name ("year-2023", "year-2024"),
// so each showYear() would ADD a new theme — removeTheme(prev) tears down the
// previous one first. Simpler alternative: use ONE stable meta.name for all years;
// then each define auto-replaces and no removeTheme is needed.
let ACTIVE = null;   // meta.name of the currently-drawn theme

function showYear(year) {
    const themeName = "year-" + year;
    const prev = ACTIVE;
    myMap.then(api => {
        if (prev) { try { api.removeTheme(prev); } catch(e){} }
        myMap.layer("countries")                                   // SAME name as FEATURE base
            .data({ obj: yearData[year], type: "json" })
            .binding({ geo: "lat|lon", value: "metric" })
            .type("CHART|BUBBLE|SIZE|VALUES")
            .style({ colorscheme: ["#0066cc"], fillopacity: 0.7, showdata: "true" })
            .meta({ name: themeName, tooltip: "{{label}}: {{metric}}" })
            .define();
        ACTIVE = themeName;
    });
}
showYear("2023");
```
**Key:** replacement is automatic when the new theme's `meta.name` matches one already on the
map; `removeTheme` is only needed when the names differ (as above). `removeTheme` lives on the
embedded Api — reach it via `myMap.then(api => api.removeTheme(name))`. The
`"direct"`/`"fast"`/`"silent"` flag (2nd arg to `.layer(...)`) just makes the swap fluent
(no spinner / no intermediate render flash); it is not itself the upsert. Theme `name` in
`.meta()` is the replace key; layer name (`"countries"`) is the geometry bucket.

> Time slider (`timefield` in `.binding()`), `setThemeTimeFrame()` → **API_REFERENCE.md § Time Slider**

---

## Key Style Properties (quick ref)

| Property | Notes |
|----------|-------|
| `colorscheme` | Array of hex colors. `["100","tableau"]` for auto-palette. A bare string (`colorscheme: "#0066cc"`) is accepted **only** for a single color — **always use the array form** (`["#0066cc"]`, `["none"]`) as best practice |
| `fillopacity` | 0–1. NEVER use `opacity` |
| `linecolor` / `linewidth` | NEVER `strokecolor` / `strokewidth`; `linecolor` accepts a single string **or** an array `["#c1","#c2"]` — array form required for `VECTOR\|GRADIENT` |
| `scale` | Uniform size multiplier (start at 1) |
| `normalsizevalue` | Data value that maps to "normal" display size. **Higher = SMALLER bubbles** — a larger reference value means most real data values fall below it, so bubbles render smaller. E.g. `"1000"` → smaller bubbles than `"300"`. |
| `gridwidth` | Grid cell size for aggregate layers (e.g. `"5px"`) |
| `rangecentervalue` | Diverging center; requires EVEN number of colors |
| `ranges` | Explicit class breaks (n+1 values for n colors) |
| `values` | Category list for CATEGORICAL (must be **strings**) |
| `align` | Chart anchor: `"left"` `"right"` `"top"` `"bottom"` `"above"` `"below"` |
| `sizepow` | Power for size scaling: radius ∝ value^(1/sizepow). `1` = linear (width ∝ value); `2` = area proportional to value (cartographic standard, flattens apparent contrast); `3` = volume proportional to value (even flatter). Higher = smaller arrows for small values appear relatively larger |
| `rotation` | Rotate chart symbol in degrees (e.g. `35` for a tilted arrow) |
| `rangescale` | Scale factor applied after range computation |
| `aggregationfield` | Field used as aggregation key when `AGGREGATE` is set |
| `titlefield` | Field used as chart title label (overrides binding `title`) |
| `datafields` | Array of extra fields carried through to tooltip: `["field1","field2"]` — access as `{{raw.field1}}` |
| `textscale` | Scale factor for label text rendered on the chart |
| `boxupper` / `boxlower` | Scale-dependent box visibility threshold, e.g. `"1:250000"` — box shown only when map scale ≤ 1:250k |
| `valuesupper` / `valueslower` | Scale-dependent value label visibility threshold |
| `valuedecimals` | Decimal places for rendered value labels |
| `minvaluesize` | Minimum pixel size below which no chart symbol is drawn |
| `units` | String appended to rendered value labels, e.g. `"%"`, `"€"`, `"km"` |
| `sizefield` | Data column that drives symbol SIZE independently from the `value` (color) field — use with `CATEGORICAL` to combine category color + numeric size on one layer |
| `dopacitypow` | Power curve exponent for `DOPACITY` opacity mapping (default ≈ 1; `2` = quadratic, exaggerates contrast) |
| `dopacityscale` | Multiplier applied after opacity calculation — stretches the opacity range |
| `gridwidthpx` | Grid cell width in pixels; supports `"factor"` mode in `changeThemeStyle` for runtime zoom-scaling |

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

Interactive controls that modify the map after load. What's available:

- **Filter across layers** — `changeThemeStyle(themeName, "filter:WHERE …", "set")` via `myMap.then(map => …)`; aggregate layers (grids, sparklines) re-aggregate. Every responsive layer needs `name` in `.meta()`.
- **Region selector + zoom** — a `<select>` that filters all named themes and pans/zooms via `myMap.view()`; `<option value="">` is the "show all" sentinel.
- **Toggle visibility** — `ixmaps.hideTheme(name)` / `ixmaps.showTheme(name)`; start a layer hidden with `visible: false` in `.style()` (never call `hideTheme` from `myMap.then()`).
- **Isolate categories** — `ixmaps.markThemeClass(name, idx)` / `unmarkThemeClass(name, idx)` for clickable legends (idx = position in the `values:` array).
- **Highlight a single item** — `ixmaps.highlightThemeItems(name, itemId)` / `ixmaps.clearHighlight()`; e.g. legend-row hover highlighting its map feature. `itemId` is the full SVG group id `"<layerName>::<lookupValue>"`, not the bare lookup value — passing the bare value silently no-ops.
- **React to zoom/pan/click** — `myMap.on("zoomend moveend click mouseover …", handler)`. `ixmaps.getZoom()` / `getCenter()` are global (no `.then()`); `getBounds()` returns a flat `[swLat, swLng, neLat, neLng]` array.
- **Persist view in URL** — read `lat/lng/zoom` params on init, write back with `history.replaceState` (debounced); wrap (don't overwrite) an existing `htmlgui_onZoomAndPan`.

> ⚠️ `ixmaps.map().changeThemeStyle()` returns `{szMap:null}` and silently no-ops — always go through `myMap.then(map => …)`.
> Full patterns + copy-paste code (filter helper, region selector + overlay CSS, hide/show, mark/unmark, highlight, `.on()` event tables, URL-sync wrapper) → **RUNTIME_CONTROLS.md**

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

**CHART|USER — custom draw functions (pinnacleChart, arrowChart):**

Scripts required — load after `ixmaps.js`, order between them does not matter:

| Draw function | Scripts needed |
|---|---|
| `arrowChart` | `d3.v3.min.js` + `arrow_chart.js` |
| `pinnacleChart` | `d3.v3.min.js` + `chart.js` + `arrow_chart.js` |

```html
<!-- arrowChart only -->
<script src="https://d3js.org/d3.v3.min.js"></script>
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@1/usercharts/d3/arrow_chart.js"></script>

<!-- pinnacleChart (also needs chart.js) -->
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@1/usercharts/d3/chart.js"></script>
```

The `userdraw` style property names the draw function (`"pinnacleChart"` or `"arrowChart"`).
Key type modifiers used with USER charts:

| Modifier | Role |
|---|---|
| `DIFFERENCE` | computes `value[1] − value[0]` from a `"a\|b"` binding |
| `NONEGATIVE` | **render flag** — suppresses drawing the chart symbol where the computed value ≤ 0 (data row is still processed; only rendering is skipped) |
| `RELOCATE` | relocates the chart symbol to the geometry centroid |
| `BOX` | adds a background box behind the label |
| `BOTTOMTITLE` | places title below the chart symbol |
| `NOLEGEND` | excludes this layer from the map legend |

**Split-winner pattern** — two layers from one dataset, no pre-filtering needed:
```javascript
// Layer A — shows only communes where Sì wins (voti_si − voti_no > 0)
myMap.layer("comuni")
    .data({ url: DATA_URL, type: "csv" })
    .binding({ lookup: "cod_istat", value: "voti_no|voti_si", title: "desc_com" })
    .type("CHART|USER|3D|DIFFERENCE|AGGREGATE|RECT|RELOCATE|SUM|VALUES|NONEGATIVE|BOX|BOTTOMTITLE|NOLEGEND")
    .style({
        name:             "chart_si",
        userdraw:         "pinnacleChart",
        colorscheme:      SI_COLORS,
        sizepow:          2,
        normalsizevalue:  1000000,
        aggregationfield: "desc_com",
        titlefield:       "desc_com",
        datafields:       ["desc_com","desc_prov","margin_f"],
        showdata:         "true"
    })
    .meta({ name: "chart_si", tooltip: "{{desc_com}}<br>voti in più Sì: {{raw.margin_f}}" })
    .define();

// Layer B — shows only communes where No wins: swap binding order, NONEGATIVE drops the rest
myMap.layer("comuni")
    .data({ url: DATA_URL, type: "csv" })
    .binding({ lookup: "cod_istat", value: "voti_si|voti_no", title: "desc_com" })  // ← swapped
    .type("CHART|USER|3D|DIFFERENCE|HEADTAIL|AGGREGATE|RECT|RELOCATE|SUM|VALUES|NONEGATIVE|NOLEGEND")
    .style({ name: "chart_no", userdraw: "pinnacleChart", /* ... */ showdata: "true" })
    .meta({ name: "chart_no", tooltip: "..." })
    .define();
```
> Binding order determines sign: `"a|b"` → `b − a`. With `NONEGATIVE`, only locations where the result > 0 get a chart drawn. Swapping `a` and `b` between two layers gives "A wins" vs "B wins" without any data pre-processing.
> `{{raw.fieldname}}` in tooltip accesses fields listed in `datafields` — useful for pre-formatted strings (e.g. `"12.345"` from `.toLocaleString()`).

**Rotated arrowChart wrapper** — tilt arrows left/right to distinguish two groups visually:

Redirect `args.target` to a rotated child `<g>` before calling the standard `arrowChart`, then restore it. The outer group keeps its ixmaps-assigned translate; only the drawn shapes rotate.

```javascript
window.ixmaps = window.ixmaps || {};

function makeRotatedArrowChart(angle) {
  return function(SVGDocument, args) {
    var origTarget = args.target;
    var rotG = d3.select(origTarget)
                 .append("g")
                 .attr("transform", "rotate(" + angle + ")")
                 .node();
    args.target = rotG;
    var result = ixmaps.arrowChart(SVGDocument, args);
    args.target = origTarget;
    return result;
  };
}
ixmaps.arrowChartLeft_init  = function(s,a) { if (typeof ixmaps.arrowChart_init === "function") ixmaps.arrowChart_init(s,a); };
ixmaps.arrowChartRight_init = function(s,a) { if (typeof ixmaps.arrowChart_init === "function") ixmaps.arrowChart_init(s,a); };
ixmaps.arrowChartLeft  = makeRotatedArrowChart(-15);   // ← tilts left  (e.g. CS/left bloc)
ixmaps.arrowChartRight = makeRotatedArrowChart(+15);   // → tilts right (e.g. CDX/right bloc)
```

Then use `userdraw: "arrowChartLeft"` / `userdraw: "arrowChartRight"` in `.style()`.

**Simultaneous theme stacking on one layer** — two themes rendered at the same position:

Calling `.define()` multiple times on the same layer name *adds* themes (they stack). Use this when you need two independent visual signals at the same geo-coordinates (e.g. one red arrow group + one blue arrow group). Each theme must have a distinct `name` in `.meta()` so they can be removed independently.

```javascript
// Both themes render simultaneously on layer "sedi"
// Pre-filtered: csWins has only sedes where CS leads; cdWins only where CDX leads
myMap.layer("sedi")
  .data({ obj: csWins, type: "json" })
  .binding({ geo: "sez_da", value: "margin" })
  .type("CHART|USER|SIZE|VALUES")
  .style({ userdraw: "arrowChartLeft", colorscheme: ["#e74c3c","#e74c3c"],
           normalsizevalue: 100, rangescale: 0.5, fillopacity: 0.85,
           showdata: "true", units: " voti", valuedecimals: 0 })
  .meta({ name: "cs_dom", title: "CS in testa", tooltip: "..." })
  .define();                               // ← adds theme, does NOT replace

myMap.layer("sedi")
  .data({ obj: cdWins, type: "json" })
  .binding({ geo: "sez_da", value: "margin" })
  .type("CHART|USER|SIZE|VALUES")
  .style({ userdraw: "arrowChartRight", colorscheme: ["#2980b9","#2980b9"],
           normalsizevalue: 100, rangescale: 0.5, fillopacity: 0.85,
           showdata: "true", units: " voti", valuedecimals: 0 })
  .meta({ name: "cd_dom", title: "CDX in testa", tooltip: "..." })
  .define();                               // ← stacks on top of cs_dom

// To refresh: remove both by name, then redefine
myMap.then(function(api) {
  try { api.removeTheme("cs_dom"); } catch(e) {}
  try { api.removeTheme("cd_dom"); } catch(e) {}
  // ... redefine both
});
```

> ⚠️ Stacking only works correctly when the two datasets are **mutually exclusive** per feature (e.g. pre-filtered so each sede appears in at most one theme). If the same `sez_da` id appears in both, both themes draw at that location and visually overlap.

**Invisible point anchor layer** — load centroid geometry without rendering anything:
```javascript
// Required when CHART|USER layers need to snap to precise urban centroids
// For POINT geometry: colorscheme:["none"] + scale:0 suppress the dot completely.
// (Do NOT rely on fillopacity:0 — ixMaps coerces it to 1, so it never hides anything.)
myMap.layer("centroids")
    .data({ url: CENTROIDS_URL, type: "geojson" })
    .binding({ geo: "geometry", id: "PRO_COM", title: "PRO_COM" })
    .type("FEATURE|NOLEGEND")
    .style({
        colorscheme: ["none"],
        scale:       0,         // ← required for point geometry
        linecolor:   "none",
        linewidth:   0,
        showdata:    "true"
    })
    .define();
```

> Diverging scales, density patterns, road-tracing, SEQUENCE charts → **API_REFERENCE.md § Special Cases**
> Complete working examples → **EXAMPLES.md**
> Data preprocessing (data.js) → **DATA_JS_GUIDE.md**
> Symbols/icons → **SYMBOLS_GUIDE.md**
> Computed layers via external libs (Turf.js), weighted KDE heatmap → **EXTENSIONS_GUIDE.md**
> Troubleshooting → **TROUBLESHOOTING.md**

---

## Facet Sidebar (filter panel updated on zoom/pan)

A clickable facet panel that auto-updates on every zoom/pan/filter. Requires three CDN plugins (`format.js`, `facet.js`, `show_facets.js`), a sidebar `<div id="show-facets-div">`, an override of `ixmaps.statistics` (calls `ixmaps.data.getFacets` → `showFacets`), wired via `myMap.on("layerdraw", …)`. Pass `"NONUMERIC"` to `getFacets` for numeric-looking category fields; a facet field matching the theme's `value` binding auto-picks up theme colors.

> Full sidebar HTML/CSS, `ixmaps.statistics` hook, layerdraw wiring, clear-filter, button-style overrides → **FACETS_GUIDE.md**

---

## Overlay Indicator Layer (small status dot on top of main bubbles)

A second `CHART|BUBBLE|CATEGORICAL|NOLEGEND` layer drawn over the main bubbles to show a per-item status flag (risk class, alert state) without touching the primary colors. Add a constant `_dot` size field, filter to only meaningful states, use `scale: ~0.1` + `align: "bottom"`. `NOLEGEND` **must** be in the type string so the layerdraw/statistics handler skips it.

> Full pattern, key rules, define-then-add (`ixmaps.layer(...).define()` + `myMap.layer(theme, "direct")`) → **FACETS_GUIDE.md § Overlay Indicator Layer**

---

## Computed Layers via External Libraries (Turf.js) — e.g. weighted KDE heatmap

Use an external geospatial-JS library (Turf.js, d3-contour, …) to **compute a GeoJSON layer at runtime** from the visible records of an existing theme, then inject it as a normal ixMaps layer. Flagship case: a **weighted KDE "danger index" heatmap** — each point weighted by severity (e.g. `morti*10 + feriti`), Gaussian density on a zoom-adaptive grid, rendered as stacked `turf.isobands` polygons. Capture the map promise (`var _mapPromise = ixmaps.Map(...)`), read `objTheme.objTheme.dbRecords/dbFields` + `indexA/itemA/dbIndexA` for visible rows (coords from lat/lng columns for CSV, or `JSON.parse(rec[iGeo]).coordinates` for topojson), compute, then `_mapPromise.then(api => { api.removeTheme("kde"); api.layer(def); })`. The injected layer needs `FEATURE|CHOROPLETH|SILENT` (CHOROPLETH so the opacity slider's `changeThemeStyle` works) and a **unique `meta.name`**. Sample record indices *before* parsing geometry and debounce the recompute (~300 ms) for performance.

> Runnable scaffold → **template-kde.html** (fill placeholders; edit coordinate extraction + weight expression). Concepts, weight choices, stacked-isoband trick, perf & gotchas, general external-library pattern → **EXTENSIONS_GUIDE.md**

---

## WMS / External Raster Overlays (Copernicus, EEA, Esri REST services)

ixMaps has a native `WMS|IMAGE` theme type for dropping a **server-rendered raster image** on the map (e.g. Copernicus Land Monitoring Service layers — Urban Atlas, Riparian Zones — hosted by EEA):

```javascript
var wmsLayer =
    ixmaps.layer("urban_atlas")
        .type("WMS|IMAGE|NOLEGEND")
        .data({ server: "https://image.discomap.eea.europa.eu/arcgis/rest/services/UrbanAtlas/UA_UrbanAtlas_2018/MapServer/export" })
        .style({ opacity: "0.8", layerupper: "1:750000" })   // layerupper = scale-gate; hides layer when zoomed out past this denominator
        .define();

ixmaps.Map("map", {
        mapType: "VT_TONER_LITE",
        mode:    "pan",
        width:   window.innerWidth + "px",     // ⚠️ MUST be explicit pixels — see gotcha below
        height:  window.innerHeight + "px",
        legend:  "closed"
    },
    map => map.view([45.4642, 9.1900], 12).options({ basemapopacity: "0.6" }).layer(wmsLayer)
);
```

- **`type("WMS|IMAGE|...")`** — the `data({server: url})` value goes to an internal `szServer`/Esri REST **`MapServer/export`** (or `ImageServer/exportImage`) endpoint — `?f=image&transparent=true&bbox=...&bboxSR=4326&size=W,H` gets appended automatically. This is **not** literal OGC `WMS GetMap` syntax — a true OGC WMS endpoint (`SERVICE=WMS&REQUEST=GetMap&...`) will not work here. EEA hosts Copernicus datasets on Esri ArcGIS Server, so their REST `export` endpoints are the correct URLs to use (find one via the ArcGIS REST metadata: `.../MapServer?f=json`, or by dropping `/WMSServer` and appending nothing to the base `MapServer` URL).
- **`layerupper` / `layerlower`** (style props) — scale-string gates (`"1:750000"`) that hide the theme above/below a given map-scale denominator; use this instead of hand-rolled zoom-threshold JS.
- No `.data({url:...})`/`.binding()` needed — this theme type draws one image per redraw, not per-record data.

> ⚠️ **Critical gotcha:** `width`/`height` in the `ixmaps.Map()`/`ixmaps.embed()` options **must be explicit pixel strings** (`window.innerWidth + "px"`), never `"100%"`. Percentage sizing breaks this theme's internal SVG scale math — the image request still fires and succeeds (confirm via network tab), but the `<image>` element renders a few SVG-units across, i.e. invisible. This affects both the modern `ixmaps.Map()` loader and the classic `ixmaps.embed()` + `htmlgui_flat.js` path identically — it is a sizing-string issue, not an old-API-vs-new-API issue.
>
> Also don't be alarmed by tiny `width`/`x`/`y` numbers on the `<image>` element in devtools (e.g. `width:1.3`) — those are the engine's internal SVG user-coordinate space, scaled up by the outer `<svg>` viewBox to real pixel size. Verify visibility with a screenshot, not by eyeballing those attribute values.

**Switchable WMS layers (e.g. a dataset picker for several Copernicus/EEA services)** — the same **stable `meta.name` → auto-replace** pattern from § Multi-Layer Join Pattern · B works identically for `WMS|IMAGE` themes, confirmed with a 4-layer Copernicus showcase (Urban Atlas / Riparian Zones / Corine Land Cover / Imperviousness Density) switched via button clicks with no stacking or ghosting:

```javascript
var WMS_THEME_NAME = "copernicus-wms";   // same name every time = auto-replace, no removeTheme needed

function setLayer(cfg) {
    myMap.then(function (api) {
        myMap.layer("copernicus")                    // layer name is arbitrary for WMS|IMAGE (no geometry to bind)
            .type("WMS|IMAGE|NOLEGEND")
            .data({ server: cfg.server })
            .style(Object.assign({ opacity: "0.8" }, cfg.style))
            .meta({ name: WMS_THEME_NAME })
            .define();
    });
}
```

Each `setLayer(cfg)` call swaps the raster in place — no `removeTheme` call needed as long as `meta.name` stays constant across all options in the picker.

---

## CSS Conflicts with External Frameworks (Bootstrap etc.)

**Never load Bootstrap 3 alongside ixmaps** — its `.hidden { display:none !important }` silently hides ixmaps' toolbar / tooltip / contextmenu (ixmaps toggles them via inline `style.display`, which `!important` beats). Ship the ~35-line standalone facet CSS instead. On dark basemaps, force `#tooltip` text color. Always run the tooltip/contextmenu class-cleanup inside `myMap.then()`.

> Standalone facet CSS, dark-basemap tooltip fix, tooltip/contextmenu cleanup, attribute-selector fallback → **CSS_INTEROP.md**
