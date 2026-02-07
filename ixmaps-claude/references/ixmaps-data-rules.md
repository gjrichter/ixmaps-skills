# ixMaps Data Rules

## Data Sources

### GeoJSON

- Use `.data({ url: "...", type: "geojson" })`.
- Use `type: "FEATURE"` for simple features.
- Use `type: "FEATURE|CHOROPLETH"` for numeric choropleth.
- Use `type: "FEATURE|CHOROPLETH|CATEGORICAL"` for text categories.
- Use `value: "$item$"` for simple features.
- Use `value: "fieldname"` for categorical choropleth.
- Reference property names directly (no `properties.` prefix).

### TopoJSON

- Use `.data({ url: "...", type: "topojson" })`.
- Apply the same binding/type rules as GeoJSON.

### Point Data (CSV/JSON)

- Use `.data({ url: "...", type: "csv" })` or `.data({ obj: data, type: "json" })`.
- Use `geo: "lat|lon"` for separate fields or a single coordinate field name.
- Use `CHART|DOT` for simple points.
- Use `CHART|DOT|CATEGORICAL` for categorical points.
- Use `CHART|BUBBLE|SIZE|VALUES` for size by value.

## Binding Rules

- Always include `.binding()` for every layer.
- GeoJSON/TopoJSON simple: `{ geo: "geometry", value: "$item$", title: "NAME" }`.
- GeoJSON/TopoJSON categorical: `{ geo: "geometry", value: "CATEGORY", title: "NAME" }`.
- Point data with value: `{ geo: "lat|lon", value: "VALUE", title: "NAME" }`.
- Point data without value: `{ geo: "lat|lon", title: "NAME" }`.
- Aggregation counting: use `value: "$item$"` with `|AGGREGATE`.

## Style Rules

- Always include `showdata: "true"` in `.style()`.
- Colors use `colorscheme` (never `fillcolor`).
- Static colors: `colorscheme: ["#0066cc"]`.
- Categorical colors: `colorscheme: ["100", "tableau"]` (dynamic palette).
- Borders: `linecolor`, `linewidth`.
- Aggregation grid size: `gridwidth: "5px"`.
- Avoid `normalsizevalue` with `|AGGREGATE`.

## Meta Rules

- Always include `.meta({ tooltip: "{{theme.item.chart}}{{theme.item.data}}" })`.
- Use custom HTML only if requested.
- Do not use `.tooltip()`.

## Map Options

- If `objectscaling: "dynamic"`, always set `normalSizeScale`.
- Control animation with `flushChartDraw` (`1`, `100`, or `1000000`).
- Use `.legend("Legend Title")` for a custom legend title.
- Enable hover info with `mode: "info"` in `ixmaps.Map()` options.

## Map Types (Exact Names)

- `VT_TONER_LITE` (default)
- `white`
- `OpenStreetMap`
- `CartoDB - Positron`
- `CartoDB - Dark_Matter`
- `Stamen Terrain`

## Visualization Types

- Point data: `CHART|DOT`, `CHART|DOT|CATEGORICAL`, `CHART|BUBBLE|SIZE|VALUES`, `CHART|PIE`, `CHART|BAR|VALUES`.
- GeoJSON/TopoJSON: `FEATURE`, `FEATURE|CHOROPLETH`, `FEATURE|CHOROPLETH|CATEGORICAL`.
- Quantiles/equidistant: add `|QUANTILE` or `|EQUIDISTANT`.

## Aggregation

- Use `|AGGREGATE` in the type string.
- Use `gridwidth` in `.style()`.
- Use `value: "$item$"` to count items.
