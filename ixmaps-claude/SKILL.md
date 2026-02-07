---
name: create-ixmap
description: Create standalone HTML ixMaps visualizations and interactive maps. Use when the user requests map creation, geographic visualization, or ixMaps layers (bubble, choropleth, pie, bar, dot) with CSV/JSON/GeoJSON/TopoJSON data.
---

# Create ixMap

Create a complete HTML file with an interactive ixMaps visualization.

## Workflow

1. Parse the request and extract filename, data source, fields, viz type, map type, center, and zoom.
2. Ask for missing inputs: data location, value field, title field, visualization type, base map, and output filename.
3. Choose data mode: inline data for small samples, URL for external CSV/JSON/GeoJSON/TopoJSON.
4. Start from `template.html` and replace placeholders.
5. Enforce required layer chain order and required style/meta rules.
6. Write the HTML file and summarize what the map shows.

## Defaults

- filename: `ixmap.html`
- mapType: `VT_TONER_LITE`
- center: `{ lat: 42.5, lng: 12.5 }`
- zoom: `6`
- viz type: `CHART|BUBBLE|SIZE|VALUES`
- colorscheme: `["#0066cc"]`
- normalSizeScale: `"1000000"`
- flushChartDraw: `1000000`

## Required Rules

- Always include `.binding()` for every layer.
- Always include `.style({ showdata: "true", ... })`.
- Always include `.meta({ tooltip: "{{theme.item.chart}}{{theme.item.data}}" })` unless the user requests a custom tooltip.
- Use `value: "$item$"` for GeoJSON/TopoJSON simple features and for `|AGGREGATE` counting.
- Do not use `.tooltip()`.
- Use exact `mapType` names.
- Use this layer chain order: `.data()` → `.binding()` → `.type()` → `.style()` → `.meta()` → `.title()` → `.define()`.

## References

- Data sources, binding/style/meta rules, map types, aggregation: `references/ixmaps-data-rules.md`
- Complete examples: `references/ixmaps-examples.md`
