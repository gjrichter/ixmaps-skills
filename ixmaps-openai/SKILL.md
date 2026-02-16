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
- Always use layer method order: `.data()` -> `.binding()` -> `.type()` -> `.style()` -> `.meta()` -> `.title()` -> `.define()`.
- One layer must have one `.data()` call.
- If using `objectscaling: "dynamic"`, always set `normalSizeScale` in `.options()`.
- For GeoJSON/TopoJSON properties, reference fields directly (no `properties.` prefix).
- For aggregation/counting, use `value: "$item$"`; put `gridwidth` in `.style()`.
- Do not use `.tooltip()`.
- Do not use deprecated `|EXACT` classification; use `QUANTILE`, `EQUIDISTANT`, or `CATEGORICAL`.
- For diverging scales with `rangecentervalue`, use an even number of colors. With `ranges`, use n+1 break values for n colors.
- Do not combine `rangecentervalue` or `ranges` with `QUANTILE`/`EQUIDISTANT`.
- Use ixMaps script from `https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/ixmaps.js`.
- Use exact mapType names; Carto variants require spaces (`"CartoDB - Positron"`, `"CartoDB - Dark_Matter"`).
- Avoid `map` as JS variable name; use `myMap`/`mapInstance`.

## Visualization Selection

- Point data (CSV/JSON lat/lon):
  - locations only: `CHART|DOT`
  - sized bubbles: `CHART|BUBBLE|SIZE|VALUES`
  - categorical points: `CHART|DOT|CATEGORICAL`
  - symbols/icons: `CHART|SYMBOL` or `CHART|SYMBOL|CATEGORICAL`
  - density grid: `CHART|BUBBLE|SIZE|AGGREGATE`
  - flows between places: `CHART|VECTOR|BEZIER|POINTER`
- Polygon data (GeoJSON/TopoJSON):
  - plain geometry: `FEATURE`
  - numeric choropleth: `FEATURE|CHOROPLETH`
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

## Style Notes

- Use `colorscheme` for colors; never `fillcolor`.
- Use `linecolor` and `linewidth`; never `strokecolor` or `strokewidth`.
- Use `scale`/`normalsizevalue` for sizing; not `symbolsize`.
- For categorical dynamic palettes, prefer `colorscheme: ["100", "tableau"]`.
- Symbol charts must use `symbols` (plural) and an array, even for one icon.

## Valid Map Types

Use verified names:

- `VT_TONER_LITE`
- `white`
- `CartoDB - Positron`
- `CartoDB - Dark_Matter`
- `Stamen Terrain`

If unsure, use `VT_TONER_LITE`.

## Data Handling

- Inline data for small datasets.
- External URL for reusable/large datasets: `.data({ url: "...", type: "csv/json/geojson/topojson" })`.
- For production sharing, prefer hosted datasets on GitHub + jsDelivr CDN.
- Optional preprocessing is supported via `.data({ process: myFunction.toString(), ... })`.

## Validation Checklist

Before writing output, verify:

- Data type matches geometry mode.
- Binding contains required fields (`geo` and, where needed, `value`/`title`/join fields).
- Visualization type is compatible with data.
- `showdata: "true"` is present in `.style()`.
- `.meta()` tooltip config is present.
- `normalSizeScale` exists when dynamic object scaling is used.
- For multi-layer joins: base has `id`, thematic has `lookup`, and thematic type excludes `FEATURE`.

## References

- Core data/API rules: `references/ixmaps-data-rules.md`
- Layer examples: `references/ixmaps-examples.md`
- Map types: `references/map-types-guide.md`
- Custom symbols: `references/symbols-guide.md`
- Data hosting: `references/data-hosting-guide.md`
- Usage/troubleshooting: `README.md`, `CHAT_USAGE.md`
