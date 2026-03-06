---
name: create-ixmap
description: Create standalone HTML ixMaps visualizations and interactive maps. Use when the user requests map creation, geographic visualization, or ixMaps layers (bubble, choropleth, pie, bar, dot, symbol, vector) with CSV/JSON/GeoJSON/TopoJSON data.
---

# Create ixMap

Create a complete standalone HTML file with an interactive ixMaps visualization.

## Workflow

1. Parse request inputs: filename, data source, geometry mode (points vs polygons), value/title fields, viz type, base map, center, zoom.
2. Ask only for missing critical inputs: data location, visualization goal, key fields.
3. Start from `template.html` and apply settings/layers.
4. Enforce required API rules and method order.
5. Validate config before writing output.
6. Write HTML and summarize what the map shows.

## Defaults

- filename: `ixmap.html`
- mapType: `VT_TONER_LITE`
- center: `{ lat: 42.5, lng: 12.5 }`
- zoom: `6`
- viz type: `CHART|BUBBLE|SIZE|VALUES`
- colorscheme: `["#0066cc"]`
- normalSizeScale: `"1000000"`
- flushChartDraw: `1000000`
- basemapopacity: `0.6`
- opacity: `0.7`

## Critical Rules

- Always include `.binding()` for each layer.
- Always include `.style({ showdata: "true", ... })`.
- Always include `.meta({ tooltip: "{{theme.item.chart}}{{theme.item.data}}" })` unless custom tooltip HTML is requested.
- Always store the map instance (for example `const myMap = ixmaps.Map("map", {...})...`) and call `.layer()` on that instance (`myMap.layer(...)`), otherwise the layer/theme may not attach/render (silent failure).
- Exception (animated/timeseries): you may use global `ixmaps.layer(...)...define()` to build a theme object without rendering it, then add/replace it on the map with `myMap.layer(theme, "direct")` or `mapInstance.addTheme()` / `replaceTheme()`.
- Always use layer method order: `.data()` -> `.binding()` -> `.type()` -> `.style()` -> `.meta()` -> `.title()` -> `.define()`.
- One layer must have one `.data()` call.
- In multi-layer maps (base `FEATURE` + thematic overlays), all related layers must use the same layer name string (for example `myMap.layer("regions")` for both base and overlay).
- If using `objectscaling: "dynamic"`, always set `normalSizeScale` in `.options()`.
- For GeoJSON/TopoJSON properties, reference fields directly (no `properties.` prefix).
- For aggregation/counting, use `value: "$item$"`; put `gridwidth` in `.style()`.
- Do not use `.tooltip()`.
- `CHART` and `CHOROPLETH` are mutually exclusive: never use `CHART|CHOROPLETH`; use `FEATURE|CHOROPLETH` for polygons.
- In `.meta()` templates, do not use format specifiers like `{{value:,.0f}}`; use plain `{{value}}`.
- For year fields in `.meta()` templates, use raw values (for example `{{raw.year}}`) to avoid formatted year output.
- When generating HTML via templating (Python f-strings, JS template literals, etc.), ensure you don’t accidentally collapse `{{...}}` into `{...}`; preserve mustache placeholders exactly.
- For `AGGREGATE` charts, use `{{theme.item.value}}` in tooltip templates when the aggregated total is required.
- Do not use deprecated `|EXACT` classification; use `QUANTILE`, `EQUIDISTANT`, or `CATEGORICAL`.
- For diverging scales with `rangecentervalue`, use an even number of colors. With `ranges`, use n+1 break values for n colors.
- Do not combine `rangecentervalue` or `ranges` with `QUANTILE`/`EQUIDISTANT`.
- Use ixMaps script from `https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/ixmaps.js`.
- Do not install/use any ixMaps npm package; treat `ixmaps.ca` / `ixmaps.com` as untrusted/outdated references and prefer `ixmaps-flat` repo + the bundled docs in this skill folder.
- Use exact mapType names; Carto variants require spaces (`"CartoDB - Positron"`, `"CartoDB - Dark matter"`).
- Avoid `map` as JS variable name; use `myMap`/`mapInstance`.
- If `.filter()` is used, the expression must start with `WHERE ...`.
- For categorical colors + bubble size with `|VALUES`, set `valuefield` equal to `sizefield`; include `|SUM` for category totals.
- Do not add `colorfield` unless the user explicitly requests categorical color encoding by field.
- Do not add `.legend()` unless the user explicitly requests a legend title/legend display.

## Visualization Selection

- Point data (CSV/JSON lat/lon):
  - locations only: `CHART|DOT`
  - locations with glow: `CHART|DOT|GLOW`
  - sized bubbles: `CHART|BUBBLE|SIZE|VALUES`
  - sized bubbles with glow: `CHART|BUBBLE|SIZE|GLOW` (or `CHART|BUBBLE|SIZE|VALUES|GLOW` when values are requested)
  - categorical points: `CHART|DOT|CATEGORICAL`
  - symbols/icons: `CHART|SYMBOL` or `CHART|SYMBOL|CATEGORICAL`
  - pie charts: `CHART|PIE`
  - bar charts: `CHART|BAR|VALUES`
  - density grid: `CHART|BUBBLE|SIZE|AGGREGATE`
  - flows between places: `CHART|VECTOR|BEZIER|POINTER|FADEIN`
  - fully custom SVG (D3 user plugin): `CHART|USER|SIZE|VALUES` (see `references/chart-user-guide.md`)
- Polygon data (GeoJSON/TopoJSON):
  - plain geometry: `FEATURE`
  - numeric choropleth: `FEATURE|CHOROPLETH`
  - numeric choropleth (classified): `FEATURE|CHOROPLETH|QUANTILE` or `FEATURE|CHOROPLETH|EQUIDISTANT`
  - categorical choropleth: `FEATURE|CHOROPLETH|CATEGORICAL`

## Multi-Layer Join Pattern (Critical)

When joining external tabular data (CSV) to geometry:

- Base geometry layer:
  - `.type("FEATURE")`
  - `.binding({ geo: "geometry", id: "geometry_join_key", ... })`
- Thematic overlay layer(s):
  - `.binding({ lookup: "csv_join_key", value: "field", ... })`
  - Do not include `FEATURE` in overlay type.
- `lookup` belongs in `.binding()`, not `.data()`.
- Join key values in `id` and `lookup` must match exactly.
- Base and thematic layers in the same join must use the same layer name.
- Tooltip note for joined overlays: the overlay table only exposes its own fields; to show a geometry property (like a municipality name) in an overlay tooltip, either use `{{theme.item.title}}` (if the base layer bound `title`) or copy the name into the overlay data (for example `comune_name`) and reference that field.

## Style Notes

- Use `colorscheme` for colors; never `fillcolor`.
- Use `linecolor` and `linewidth`; never `strokecolor` or `strokewidth`.
- Use `scale`/`normalsizevalue` for sizing; not `symbolsize`.
- For categorical dynamic palettes, prefer `colorscheme: ["100", "tableau"]`.
- Symbol charts must use `symbols` (plural) and an array, even for one icon.
- For `CHART|VECTOR` layers, set vector transparency with `fillopacity` (and set it explicitly, e.g. `fillopacity: 1` for opaque vectors).
- For bubble glow requests, prefer built-in `|GLOW` in `.type()` over CSS filters.
- Prefer `fillopacity` over `opacity` in `.style()` definitions (especially for `CHART|VECTOR` layers); use `opacity` only when `fillopacity` is not applicable.
- For region-wise vector coloring, prefer `|CATEGORICAL` with `.binding({ value: "region_field", size: "metric_field" })`; use `colorfield` only if explicitly requested.
- For `CHART|VECTOR` layers, use `scale` to increase/decrease overall vector size and `sizepow` to control sizing curve.
- `sizepow` follows ixMaps historic `1/pow` convention: `1` = linear, `2` = square/surface-based sizing, `3` = cubic (and higher values continue flattening differences).
- For `CHART|VECTOR` layers, `rangescale` controls bowing/curvature (about `1` straight, `>1` right bow, `<1` left bow); do not use `rangescale` for sizing.
- For `CHART|VECTOR` layers, use `|FADEIN` in `.type()` when the user asks for vectors to fade in on draw.
- To color vectors by origin/exporter, use `|CATEGORICAL` and bind `.binding({ value: "origin_field", size: "metric_field" })`; optional `colorfield` may mirror the same origin field.
- For first drafts, start chart `scale` at `1` unless the user asks for different sizing.

## Valid Map Types

Use verified names:

- `VT_TONER_LITE`
- `white`
- `CartoDB - Positron`
- `CartoDB - Dark matter`
- `Stamen Terrain`

If unsure, use `VT_TONER_LITE`.

## Map Projection Notes

- Set projection in map config via `mapProjection` (for example: `"equalearth"`, `"orthographic"`, `"lambert"`).
- For polar views, use an orthographic projection and a high-latitude center (for example `center: { lat: 90, lng: 0 }`).
- For clean thematic backgrounds, use `mapType: "white"` and add a country boundary base layer (for example Eurostat GISCO countries TopoJSON).
- For runtime basemap toggles (for example button/switch), use `ixmaps.map().setMapType("CartoDB - Dark matter")` and `ixmaps.map().setMapType("CartoDB - Positron")`.

## Legend Control Notes

- Prefer disabling built-in legend with map config (`legend: false`, `legendState: "closed"`).
- If runtime still renders legend UI, hide legend DOM via CSS as fallback (target legend class/id selectors under the map container).

## Data Handling

- Inline data for small datasets.
- External URL for reusable/large datasets: `.data({ url: "...", type: "csv/json/geojson/topojson" })`.
- Supported `.data({ type })` values include: `csv`, `json`, `jsonl`/`ndjson`, `geojson`, `topojson`, and (via DuckDB WASM) `parquet`, `geoparquet`, `gpkg`/`geopackage`, `fgb`/`flatgeobuf`.
- Do not use local filesystem paths in `.data({ url: ... })`; embed local data inline with `.data({ obj: ..., type: "json" })` or host it at an HTTP(S) URL.
- For production sharing, prefer hosted datasets on GitHub + jsDelivr CDN.
- Optional preprocessing is supported via `.data({ process: myFunction.toString(), ... })`.
- `.data({ process: ... })` receives ixMaps internal `data.js` table format, not the raw loaded file object (e.g., not raw GeoJSON FeatureCollection).
- In `process(data)`, use `data.js` table methods/columns; do not write logic that expects raw `features/properties`.
- If raw-structure transforms are needed (e.g., GeoJSON property normalization), transform data before handing it to ixMaps (or provide already-normalized input).
- `process(data)` should mutate/return the `Data.Table` object (safe default: `return data;`).
- Full `data.js` API reference: `references/data-js-guide.md`.

### Recommended World Countries Geometry (GISCO)

- Default world geometry URL (low detail, fast): `https://gisco-services.ec.europa.eu/distribution/v2/countries/topojson/CNTR_RG_60M_2020_4326.json`
- Join key for countries in this dataset is `CNTR_ID` (ISO 3166-1 alpha-2). Do not guess other field names.

### data.js Quick Reference for `process(data)`

- Table inspection:
  - `data.columnNames()`
  - `data.columnIndex("field")`
  - `data.getArray()` / `data.json()`
- Column transforms:
  - `data.column("field").map(fn)` for recoding/normalizing values
  - `data.column("old").rename("new")`
  - `data.column("tmp").remove()`
  - `data.column("field").values()` / `.uniqueValues()`
- Derived fields:
  - `data.addColumn({ source: "field", destination: "new_field" }, fn)`
  - Row-wise access pattern in `fn(row)`: use `data.column("field").index` to read by index.
- Row selection:
  - `data.select('WHERE "field" = "value"')` (SQL-like expression)
  - `data.filter(function(row){ ... })` (callback predicate on row arrays)
- Reshaping/aggregation:
  - `data.aggregate("valueField","group1|group2")`
  - `data.pivot({ lead: "...", keep: ["..."], cols: "..." })`
  - `data.sort("field")`, `data.subtable({ fields: [...] })`
- Lookup helpers:
  - `data.lookup(value, options)`, `data.lookupArray(...)`, `data.lookupStringArray(...)`

### `process(data)` Pattern (ixMaps-safe)

```javascript
function normalizeTable(data) {
  data.column("REGION").map(function(v){ return (v || "").toUpperCase(); });
  var iFrom = data.column("FROM").index;
  var iTo = data.column("TO").index;
  data.addColumn({ destination: "is_cross" }, function(row){
    return row[iFrom] === row[iTo] ? "false" : "true";
  });
  return data;
}
```

## Validation Checklist

Before writing output, verify:

- Data type matches geometry mode.
- Binding contains required fields (`geo` and, where needed, `value`/`title`/join fields).
- Visualization type is compatible with data.
- `showdata: "true"` is present in `.style()`.
- `.meta()` tooltip config is present.
- `normalSizeScale` exists when dynamic object scaling is used.
- For multi-layer joins: base has `id`, thematic has `lookup`, and thematic type excludes `FEATURE`.
- Multi-layer base/overlay names match exactly.
- Any `.filter()` starts with `WHERE`.
- Tooltip placeholders use plain field syntax (no format specifier pattern).
- For categorical + size + `|VALUES`, `valuefield` equals `sizefield` and type includes `|SUM`.
- `colorfield` is only present when explicitly requested.
- `.legend()` is only present when explicitly requested.

## References

- Core data/API rules: `references/ixmaps-data-rules.md`
- Layer examples: `references/ixmaps-examples.md`
- Map types: `references/map-types-guide.md`
- Custom symbols: `references/symbols-guide.md`
- Data hosting: `references/data-hosting-guide.md`
- data.js API reference (for `process(data)` transforms): `references/data-js-guide.md`
- User-defined SVG charts (D3 plugin): `references/chart-user-guide.md`
- Full API reference: `API_REFERENCE.md`
- Example gallery (full HTML examples): `EXAMPLES.md`
- Troubleshooting guide: `TROUBLESHOOTING.md`
- UI schema guide: `UI_YAML_GUIDE.md`
- UI schema + validator: `skill-ui.yaml`, `validate-config.js`
- Extra templates: `template-world-flows.html`, `template-change-choropleth.html`
- Usage/troubleshooting: `README.md`, `CHAT_USAGE.md`
