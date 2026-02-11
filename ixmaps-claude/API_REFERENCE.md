# ixMaps API Reference

Complete reference for the ixMaps JavaScript API.

## Table of Contents

1. [Map Constructor](#map-constructor)
2. [Map Methods](#map-methods)
3. [Layer Methods](#layer-methods)
4. [Data Configuration](#data-configuration)
5. [Binding Configuration](#binding-configuration)
6. [Style Properties](#style-properties)
7. [Visualization Types](#visualization-types)
8. [Color Schemes](#color-schemes)
9. [Meta Configuration](#meta-configuration)

---

## Map Constructor

### `ixmaps.Map(elementId, options)`

Creates a new map instance.

**Parameters:**
- `elementId` (string) - ID of the HTML element to contain the map
- `options` (object) - Map configuration options

**Options:**
```javascript
{
    mapType: "VT_TONER_LITE",  // Base map style
    mode: "info"                // Enable tooltips on hover
}
```

**Valid mapType values:**
- `"VT_TONER_LITE"` - Clean minimal base map (default)
- `"white"` - Plain white background
- `"OpenStreetMap"` - Standard OpenStreetMap
- `"CartoDB - Positron"` - Light CartoDB style (note spaces)
- `"CartoDB - Dark_Matter"` - Dark CartoDB style (note spaces)
- `"Stamen Terrain"` - Terrain with hill shading

**Valid mode values:**
- `"info"` - Show tooltips on mouseover (recommended)
- `"pan"` - Pan/zoom only, no tooltips
- `undefined` - Default behavior

**Example:**
```javascript
ixmaps.Map("map", {
    mapType: "CartoDB - Positron",
    mode: "info"
})
```

---

## Map Methods

Methods called on the map instance (fluent API - chainable).

### `.options(opts)`

Configure map behavior and rendering.

**Parameters:**
```javascript
{
    objectscaling: "dynamic",        // Enable dynamic symbol scaling
    normalSizeScale: "1000000",      // REQUIRED with objectscaling
    basemapopacity: 0.6,             // Base map opacity (0-1)
    flushChartDraw: 1000000          // Rendering speed
}
```

**Key Options:**

**objectscaling** (string)
- `"dynamic"` - Symbols scale with zoom level
- `undefined` - Fixed size symbols

**normalSizeScale** (string) ⚠️ REQUIRED with objectscaling
- Map scale where symbols appear at normal size
- Common values: `"500000"`, `"1000000"`, `"2000000"`
- Larger values = smaller symbols at given zoom

**basemapopacity** (number)
- Opacity of base map tiles: `0.0` (invisible) to `1.0` (opaque)
- Default: `0.6`

**flushChartDraw** (number)
- `1` - Animate slowly (one chart at a time)
- `100` - Animate medium speed (batches of 100)
- `1000000` - No animation (instant rendering) - recommended

**Example:**
```javascript
.options({
    objectscaling: "dynamic",
    normalSizeScale: "1000000",
    basemapopacity: 0.7,
    flushChartDraw: 1000000
})
```

### `.view(config)`

Set initial map view (center and zoom).

**Parameters:**
```javascript
{
    center: { lat: 42.5, lng: 12.5 },  // Center coordinates
    zoom: 6                             // Zoom level (1-18)
}
```

**Example:**
```javascript
.view({
    center: { lat: 40.7128, lng: -74.0060 },  // New York City
    zoom: 11
})
```

**Zoom levels guide:**
- `1-3` - World/continent view
- `4-6` - Country view
- `7-10` - Region/state view
- `11-14` - City view
- `15-18` - Street/building view

### `.legend(title)`

Set custom legend title.

**Parameters:**
- `title` (string) - Legend title text

**Example:**
```javascript
.legend("Population by Region")
```

**Notes:**
- Call after `.view()` and before `.layer()`
- Legend automatically shows categories for CATEGORICAL themes
- Omit to hide legend

### `.layer(layerDefinition)`

Add a data layer to the map.

**Parameters:**
- `layerDefinition` - Layer object created with `ixmaps.layer()`

**Example:**
```javascript
.layer(
    ixmaps.layer("layer_id")
        .data({...})
        .binding({...})
        .type("...")
        .style({...})
        .meta({...})
        .title("...")
        .define()
)
```

**Notes:**
- Can chain multiple `.layer()` calls for multi-layer maps
- Each layer must have unique ID

---

## Layer Methods

Methods called on layer objects created with `ixmaps.layer(id)`.

### `ixmaps.layer(id)`

Create a new layer.

**Parameters:**
- `id` (string) - Unique layer identifier

**Returns:** Layer object (chainable)

**Method chain order (IMPORTANT):**
1. `.data()` - Define data source
2. `.binding()` - Map data fields
3. `.filter()` - Optional data filter
4. `.type()` - Visualization type
5. `.style()` - Visual styling
6. `.meta()` - Metadata/tooltips
7. `.title()` - Layer title
8. `.define()` - Finalize

### `.data(config)`

Define the data source.

**For inline data (JSON):**
```javascript
.data({
    obj: dataArray,
    type: "json"
})
```

**For external file (URL):**
```javascript
.data({
    url: "https://example.com/data.csv",
    type: "csv"  // or "json", "geojson", "topojson"
})
```

**Supported types:**
- `"json"` - JSON array
- `"jsonl"` - JSON line array
- `"csv"` - Comma-separated values
- `"geojson"` - GeoJSON format
- `"topojson"` - TopoJSON format
- `"parquet"` - Parquet format
- `"geoparquet"` - GeoParquet format
- `"geopackage"` - GeoPackage format
- `"gpck"` - GeoPackage format
- `"flatgeobuf"` - FlatGeoBuf format
- `"fgb"` - FlatGeoBuf format
- `"geobuf"` - GeoBuf format
- `"pbf"` - GeoBuf format

### `.binding(config)` ⚠️ REQUIRED

Map data fields to map properties.

**For point data (lat/lon):**
```javascript
.binding({
    geo: "lat|lon",         // Separate fields
    // OR geo: "coordinates" // Single field
    value: "fieldname",     // Data value (optional for dots)
    title: "titlefield"     // Display name
})
```

**For GeoJSON/TopoJSON:**
```javascript
.binding({
    geo: "geometry",
    value: "$item$",        // For simple features
    // OR value: "fieldname" // For categorical coloring
    title: "NAME_ENGL"      // Property name directly
})
```

**For aggregation:**
```javascript
.binding({
    geo: "lat|lon",
    value: "$item$",  // Count items, not sum
    title: "location"
})
```

**Key points:**
- `geo` - Geographic coordinates
  - Point data: `"lat|lon"` or single field
  - Geometry: `"geometry"`
- `value` - Data values to visualize
  - Use `"$item$"` for: GeoJSON features, aggregation counts
  - Use field name for: sizing, categorical coloring
  - Omit for: simple uniform dots
- `title` - Display name in tooltips
  - GeoJSON: reference properties directly, no "properties." prefix

### `.filter(expression)` (Optional)

Filter data before visualization.

**Example:**
```javascript
.filter("WHERE value > 100")
```

### `.type(vizType)`

Specify visualization type.

**Point data types:**
- `"CHART|DOT"` - Uniform dots
- `"CHART|DOT|CATEGORICAL"` - Categorical dots
- `"CHART|BUBBLE|SIZE|VALUES"` - Sized bubbles
- `"CHART|PIE"` - Pie charts
- `"CHART|BAR|VALUES"` - Bar charts
- `"CHART|BUBBLE|SIZE|AGGREGATE"` - Density grid
- `"CHART|GRID|AGGREGATE"` - Square grid

**GeoJSON/TopoJSON types:**
- `"FEATURE"` - Simple features
- `"FEATURE|CHOROPLETH"` - Numeric choropleth
- `"FEATURE|CHOROPLETH|EQUIDISTANT"` - Equal intervals
- `"FEATURE|CHOROPLETH|QUANTILE"` - Quantile breaks
- `"FEATURE|CHOROPLETH|CATEGORICAL"` - Category choropleth

**Notes:**
- Point types MUST include `CHART|` prefix
- Add `|AGGREGATE` for density visualization
- Add `|CATEGORICAL` for category-based coloring

### `.style(properties)` ⚠️ REQUIRED

Visual styling properties.

**Must include:**
```javascript
.style({
    colorscheme: ["#0066cc"],  // Colors array
    showdata: "true",          // REQUIRED - enables data display
    // ... other properties
})
```

See [Style Properties](#style-properties) section for all options.

### `.meta(config)` ⚠️ REQUIRED

Metadata and tooltip configuration.

**Default (always include):**
```javascript
.meta({
    tooltip: "{{theme.item.chart}}{{theme.item.data}}"
})
```

**Custom HTML tooltip:**
```javascript
.meta({
    tooltip: "<h3>{{FIELD_NAME}}</h3><p>{{OTHER_FIELD}}</p>"
})
```

See [Meta Configuration](#meta-configuration) section for details.

### `.title(text)`

Set layer title (shown in legend).

**Example:**
```javascript
.title("Population by City")
```

### `.define()`

Finalize layer definition (REQUIRED at end of chain).

**Example:**
```javascript
.define()
```

---

## Data Configuration

### Inline Data Format

**JSON array:**
```javascript
const data = [
    { name: "Rome", lat: 41.9, lon: 12.5, population: 2870500 },
    { name: "Milan", lat: 45.5, lon: 9.2, population: 1378000 }
];

.data({ obj: data, type: "json" })
```

**Required fields:**
- Geographic: `lat`/`lon` or combined coordinate field
- Optional: value fields for sizing/coloring
- Optional: title/name field for tooltips

### External Data Sources

**CSV file:**
```javascript
.data({
    url: "https://example.com/data.csv",
    type: "csv"
})
```

**GeoJSON file:**
```javascript
.data({
    url: "https://example.com/regions.geojson",
    type: "geojson"
})
```

**TopoJSON file:**
```javascript
.data({
    url: "https://example.com/countries.json",
    type: "topojson"
})
```

**CSV format example:**
```csv
name,lat,lon,population
Rome,41.9028,12.4964,2870500
Milan,45.4642,9.1900,1378000
```

---

## Binding Configuration

Complete binding reference.

### Point Data Binding

**Simple dots (no values):**
```javascript
.binding({
    geo: "lat|lon",
    title: "name"
})
```

**Sized by values:**
```javascript
.binding({
    geo: "lat|lon",
    value: "population",
    title: "name"
})
```

**Categorical coloring:**
```javascript
.binding({
    geo: "coordinates",  // Single field with lat,lon
    value: "category",   // Color by this field
    title: "name"
})
```

**Aggregation (count):**
```javascript
.binding({
    geo: "lat|lon",
    value: "$item$",  // Count items
    title: "location"
})
```

### GeoJSON/TopoJSON Binding

**Simple features:**
```javascript
.binding({
    geo: "geometry",
    value: "$item$",
    title: "NAME_ENGL"  // Property directly
})
```

**Categorical coloring:**
```javascript
.binding({
    geo: "geometry",
    value: "region_type",  // Color by this field
    title: "name"
})
```

**Key differences from point data:**
- Always use `geo: "geometry"`
- Use `value: "$item$"` for simple features
- Use `value: "fieldname"` for categorical coloring
- Reference properties directly (no "properties." prefix)

---

## Style Properties

Complete style property reference.

### Required Properties

**showdata** (string) ⚠️ REQUIRED
- MUST be `"true"` (string, not boolean)
- Enables data display on map elements
- Omitting this will result in invisible data

**colorscheme** (array) ⚠️ REQUIRED
- Array of color values
- Static: `["#0066cc"]` or `["#ffffcc", "#ff0000"]`
- Dynamic: `["100", "tableau"]` for categorical

### Color Properties

**colorscheme** (array)
- Static colors: hex codes
  ```javascript
  colorscheme: ["#0066cc"]  // Single color
  colorscheme: ["#ffffcc", "#ff9800", "#ff0000"]  // Gradient
  ```
- Dynamic colors: count + palette
  ```javascript
  colorscheme: ["100", "tableau"]  // Up to 100 colors from tableau palette
  ```
- Available palettes: "tableau", "paired", "set1", "set2", "set3", "pastel1", "pastel2", "dark2", "accent"

**linecolor** (string)
- Border/stroke color
- Hex code: `"#ffffff"` or named color: `"white"`
- Default: `"#000000"`

**linewidth** (number)
- Border/stroke width in pixels
- Example: `2` or `0.5`
- Default: `1`

### Size Properties

**scale** (number)
- Size multiplier for all symbols
- `1` = normal size
- `1.5` = 50% larger
- `0.5` = 50% smaller

**normalsizevalue** (number)
- Data value that corresponds to 30px chart size
- Example: `normalsizevalue: 1000` means value of 1000 = 30px
- Useful for consistent sizing across datasets
- Avoid with `|AGGREGATE` (unknown max values)

### Opacity Properties

**opacity** (number)
- Overall opacity: `0.0` (invisible) to `1.0` (opaque)
- Default: `1.0`

**fillopacity** (number)
- Fill opacity (alternative to opacity)
- `0.0` to `1.0`

### Aggregation Properties

**gridwidth** (string)
- Grid cell size for aggregation
- Format: `"5px"`, `"10px"`, `"20px"`
- Only used with `|AGGREGATE` types
- Larger values = coarser aggregation

### Diverging Scale Properties

**rangecentervalue** (number)
- Creates automatic diverging color scale around a center value
- Center value is the BOUNDARY between colors, not a color itself
- **IMPORTANT: Use EVEN number of colors** (4, 6, 8, etc.) for equal distribution above and below
- Perfect for target-based visualizations (e.g., EU 65% target)
- DO NOT combine with QUANTILE, EQUIDISTANT classification methods
- Use with plain `CHOROPLETH` or `FEATURE` type only

**Example:**
```javascript
.style({
    colorscheme: [
        "#b71c1c", "#d32f2f", "#e57373",  // 3 reds (below 65%)
        "#66bb6a", "#43a047", "#2e7d32"   // 3 greens (above 65%)
    ],  // 6 colors total (even number) - 65% is the boundary between reds and greens
    rangecentervalue: 65,  // EU target - boundary between color groups
    opacity: 0.7,
    showdata: "true"
})
.type("FEATURE|CHOROPLETH")  // No QUANTILE/EQUIDISTANT
```

**ranges** (array)
- Explicitly defines class break values for choropleth
- Array must have n+1 values for n colors
- First value = minimum, last value = maximum, middle values = breaks
- Allows precise control over class intervals
- **Can use ANY number of colors** (not restricted like rangecentervalue)
- Allows asymmetric distributions (e.g., 3 below center, 4 above center)
- DO NOT combine with QUANTILE, EQUIDISTANT classification methods
- Use with plain `CHOROPLETH` or `FEATURE` type only

**Example (symmetric, 6 colors):**
```javascript
.style({
    colorscheme: [
        "#b71c1c",  // 1. <50%
        "#d32f2f",  // 2. 50-57.5%
        "#e57373",  // 3. 57.5-65%
        "#66bb6a",  // 4. 65-72.5%
        "#43a047",  // 5. 72.5-80%
        "#2e7d32"   // 6. >80%
    ],
    ranges: [0, 50, 57.5, 65, 72.5, 80, 100],  // 6 colors = 7 values
    opacity: 0.7,
    showdata: "true"
})
.type("FEATURE|CHOROPLETH")  // No QUANTILE/EQUIDISTANT
```

**Example (asymmetric, 7 colors):**
```javascript
.style({
    colorscheme: [
        "#b71c1c",  // <50%
        "#d32f2f",  // 50-55%
        "#e57373",  // 55-60%
        "#ff9800",  // 60-65%
        "#66bb6a",  // 65-70%
        "#43a047",  // 70-80%
        "#2e7d32"   // >80%
    ],
    ranges: [0, 50, 55, 60, 65, 70, 80, 100],  // 7 colors = 8 values, 4 below + 3 above
    opacity: 0.7,
    showdata: "true"
})
.type("FEATURE|CHOROPLETH")
```

**When to use:**
- `rangecentervalue` - Simple, automatic, symmetric distribution around target/threshold (use even number of colors)
- `ranges` - Full control, asymmetric intervals, specific meaningful breaks (any number of colors)

**IMPORTANT:** Both properties conflict with classification methods (QUANTILE, EQUIDISTANT). Use plain `CHOROPLETH` type when using these properties.

### Example Styles

**Simple dot style:**
```javascript
.style({
    colorscheme: ["#0066cc"],
    scale: 1,
    opacity: 0.7,
    showdata: "true"
})
```

**Categorical style:**
```javascript
.style({
    colorscheme: ["100", "tableau"],
    scale: 1.5,
    opacity: 0.8,
    showdata: "true"
})
```

**Sized bubble style:**
```javascript
.style({
    colorscheme: ["#ff5722"],
    normalsizevalue: 500000,
    opacity: 0.7,
    linecolor: "#ffffff",
    linewidth: 1,
    showdata: "true"
})
```

**Aggregation style:**
```javascript
.style({
    colorscheme: ["#ffeb3b", "#ff9800", "#f44336"],
    gridwidth: "5px",
    scale: 1.5,
    opacity: 0.7,
    showdata: "true"
})
```

**GeoJSON choropleth style:**
```javascript
.style({
    colorscheme: ["#ffffcc", "#ffeda0", "#feb24c", "#f03b20"],
    fillopacity: 0.7,
    linecolor: "#ffffff",
    linewidth: 2,
    showdata: "true"
})
```

### Properties That DON'T Exist

❌ **These properties are NOT valid:**
- `fillcolor` - Use `colorscheme` instead
- `symbolsize` - Use `scale` or `normalsizevalue`
- `strokecolor` - Use `linecolor`
- `strokewidth` - Use `linewidth`

---

## Visualization Types

Complete visualization type reference.

### Point Data Types

**CHART|DOT**
- Simple uniform dots
- All same size and color
- Use with: uniform colorscheme

**CHART|DOT|CATEGORICAL**
- Dots colored by category field
- Different color per category value
- Use with: dynamic colorscheme `["100", "tableau"]`

**CHART|BUBBLE|SIZE|VALUES**
- Bubbles sized by data values
- Larger values = larger circles
- Use with: `value` binding and `normalsizevalue` or `scale`

**CHART|PIE**
- Pie charts at locations
- Use with: multiple value fields (pipe-separated)
- Example: `value: "age_0_14|age_15_64|age_65_plus"`

**CHART|BAR|VALUES**
- Bar charts at locations
- Use with: single or multiple value fields

**CHART|BUBBLE|SIZE|AGGREGATE**
- Density grid with sized bubbles
- Use with: `value: "$item$"` and `gridwidth` in style

**CHART|GRID|AGGREGATE**
- Density grid with square cells
- Use with: `value: "$item$"` and `gridwidth` in style

**CHART|DOT|AGGREGATE**
- Density grid with dots
- Use with: `value: "$item$"` and `gridwidth` in style

### GeoJSON/TopoJSON Types

**FEATURE**
- Simple geographic features
- Uniform or single color
- Use with: `value: "$item$"`

**FEATURE|CHOROPLETH**
- Colored by numeric data values
- Color intensity represents value
- Use with: numeric field or `"$item$"`

**FEATURE|CHOROPLETH|EQUIDISTANT**
- Choropleth with equal interval breaks
- Values divided into equal ranges

**FEATURE|CHOROPLETH|QUANTILE**
- Choropleth with quantile breaks
- Each class contains equal number of features

**FEATURE|CHOROPLETH|CATEGORICAL**
- Colored by category/text field
- Different color per unique value
- Use with: `value: "fieldname"` and dynamic colorscheme

**⚠️ Important: When to omit classification methods**

When using `rangecentervalue` or `ranges` in style properties, DO NOT include classification methods:

```javascript
// WRONG - conflict between rangecentervalue and QUANTILE:
.style({ rangecentervalue: 65 })
.type("FEATURE|CHOROPLETH|QUANTILE")

// CORRECT - use plain CHOROPLETH:
.style({ rangecentervalue: 65 })
.type("FEATURE|CHOROPLETH")

// CORRECT - explicit ranges:
.style({ ranges: [0, 50, 60, 65, 70, 80, 100] })
.type("FEATURE|CHOROPLETH")
```

Classification methods (QUANTILE, EQUIDISTANT) calculate their own class breaks, which conflicts with explicit range definitions.

---

### ⚠️ Deprecated: EXACT Classification

**DO NOT USE: `|EXACT`**

`EXACT` was a classification method in older ixmaps versions (similar to `CATEGORICAL`, `QUANTILE`, `EQUIDISTANT`) but is now **deprecated**.

**What NOT to do:**
```javascript
// DEPRECATED - Don't use EXACT:
.type("FEATURE|CHOROPLETH|EXACT")
```

**What to do instead:**
```javascript
// Use modern classification methods:
.type("FEATURE|CHOROPLETH|QUANTILE")      // Quantile breaks
.type("FEATURE|CHOROPLETH|EQUIDISTANT")   // Equal intervals
.type("FEATURE|CHOROPLETH|CATEGORICAL")   // Categories
```

**Why it's deprecated:**
- Obsolete classification algorithm from older ixmaps versions
- Replaced by more robust classification methods
- Can cause unexpected behavior in current ixmaps
- Modern methods provide better results

---

## Color Schemes

### Static Color Schemes

**Single color:**
```javascript
colorscheme: ["#0066cc"]
```

**Gradient (2+ colors):**
```javascript
colorscheme: ["#ffffcc", "#ff0000"]
colorscheme: ["#f7fbff", "#deebf7", "#c6dbef", "#6baed6", "#08519c"]
```

**Multi-class:**
```javascript
colorscheme: ["#4CAF50", "#2196F3", "#FF9800", "#F44336"]
```

### Dynamic Color Schemes (Categorical)

**Format:** `["count", "palette_name"]`

```javascript
colorscheme: ["100", "tableau"]
```

- First value: maximum number of colors
- Second value: palette name
- ixMaps automatically calculates exact number needed

**Available palettes:**
- `"tableau"` - Tableau 10 colors (good for 5-10 categories)
- `"paired"` - ColorBrewer Paired (12 colors)
- `"set1"` - ColorBrewer Set1 (9 colors)
- `"set2"` - ColorBrewer Set2 (8 colors)
- `"set3"` - ColorBrewer Set3 (12 colors)
- `"pastel1"` - ColorBrewer Pastel1 (9 colors)
- `"pastel2"` - ColorBrewer Pastel2 (8 colors)
- `"dark2"` - ColorBrewer Dark2 (8 colors)
- `"accent"` - ColorBrewer Accent (8 colors)

### Color Scheme Examples

**Red-to-green gradient:**
```javascript
colorscheme: ["#ff0000", "#ffff00", "#00ff00"]
```

**Blue gradient (light to dark):**
```javascript
colorscheme: ["#e3f2fd", "#90caf9", "#42a5f5", "#1e88e5", "#1565c0"]
```

**Heat colors:**
```javascript
colorscheme: ["#ffeb3b", "#ff9800", "#ff5722", "#d32f2f"]
```

**Categorical with tableau:**
```javascript
colorscheme: ["100", "tableau"]
```

---

## Meta Configuration

### Tooltip Templates

**Default (always use):**
```javascript
.meta({
    tooltip: "{{theme.item.chart}}{{theme.item.data}}"
})
```

- `{{theme.item.chart}}` - Visual representation (bubble/chart)
- `{{theme.item.data}}` - Data values formatted

**Custom HTML tooltips:**
```javascript
.meta({
    tooltip: "<h3>{{field_name}}</h3><p>{{other_field}}</p>"
})
```

**Field placeholders:**
- Use `{{FIELD_NAME}}` to reference data fields
- For GeoJSON: reference properties directly
- HTML allowed: `<h1>`, `<p>`, `<strong>`, `<br>`, etc.

### Tooltip Examples

**Simple title:**
```javascript
.meta({
    tooltip: "<h3>{{name}}</h3>"
})
```

**Title + value:**
```javascript
.meta({
    tooltip: "<strong>{{name}}</strong><br>Population: {{population}}"
})
```

**Multi-field:**
```javascript
.meta({
    tooltip: "<h3>{{AMBITO}}</h3><p>{{LISTA_COMUNI}}</p><small>{{DESCRIZIONE}}</small>"
})
```

**Styled tooltip:**
```javascript
.meta({
    tooltip: "<div style='background: #333; color: white; padding: 10px;'>" +
             "<strong>{{name}}</strong><br>{{category}}</div>"
})
```

**Data only (no chart):**
```javascript
.meta({
    tooltip: "{{theme.item.data}}"
})
```

---

## Complete API Flow

### Basic Flow

```javascript
// 1. Create map
ixmaps.Map("map", { mapType: "VT_TONER_LITE", mode: "info" })

// 2. Configure options
.options({
    objectscaling: "dynamic",
    normalSizeScale: "1000000",
    basemapopacity: 0.6,
    flushChartDraw: 1000000
})

// 3. Set view
.view({
    center: { lat: 42.5, lng: 12.5 },
    zoom: 6
})

// 4. Add legend (optional)
.legend("Legend Title")

// 5. Add layer(s)
.layer(
    ixmaps.layer("layer_id")
        .data({ obj: data, type: "json" })
        .binding({ geo: "lat|lon", value: "population", title: "name" })
        .type("CHART|BUBBLE|SIZE|VALUES")
        .style({ colorscheme: ["#0066cc"], showdata: "true" })
        .meta({ tooltip: "{{theme.item.chart}}{{theme.item.data}}" })
        .title("Layer Title")
        .define()
);
```

### Multi-Layer Flow

```javascript
const map = ixmaps.Map("map", { mapType: "white", mode: "info" })
    .options({ ... })
    .view({ ... })
    .legend("Multi-Layer Map");

// Layer 1
map.layer(
    ixmaps.layer("layer1")
        .data({ ... })
        .binding({ ... })
        .type("...")
        .style({ ... })
        .meta({ ... })
        .title("Layer 1")
        .define()
);

// Layer 2
map.layer(
    ixmaps.layer("layer2")
        .data({ ... })
        .binding({ ... })
        .type("...")
        .style({ ... })
        .meta({ ... })
        .title("Layer 2")
        .define()
);
```

---

## Quick Reference Card

### Essential Three Rules

1. ⚠️ **ALWAYS** include `.binding()` with `geo` and appropriate `value`
2. ⚠️ **ALWAYS** include `.type()` before `.style()`
3. ⚠️ **ALWAYS** include `showdata: "true"` in `.style()`
4. ⚠️ **ALWAYS** include `.meta()` with tooltip template

### Method Chain Order

```
ixmaps.layer(id)
  → .data()
  → .binding()     [REQUIRED]
  → .filter()      [optional]
  → .type("CHART|BUBBLE|SIZE|VALUES")  // point data
  → .type("FEATURE")                  // GeoJSON/TopoJSON
  → .style()       [MUST include showdata: "true"]
  → .meta()        [REQUIRED]
  → .title()
  → .define()      [REQUIRED]
```

### Quick Syntax

**Point data:**
```javascript
.binding({ geo: "lat|lon", value: "field", title: "name" })
```

**GeoJSON features:**
```javascript
.binding({ geo: "geometry", value: "$item$", title: "name" })
```

**Categorical:**
```javascript
.binding({ geo: "...", value: "category_field", title: "name" })
.type("...|CATEGORICAL")
.style({ colorscheme: ["100", "tableau"], showdata: "true" })
```

**Aggregation:**
```javascript
.binding({ geo: "lat|lon", value: "$item$", title: "location" })
.type("CHART|BUBBLE|SIZE|AGGREGATE")
.style({ gridwidth: "5px", showdata: "true" })
```

---

For more information:
- **SKILL.md** - Skill documentation
- **EXAMPLES.md** - Working examples
- **TROUBLESHOOTING.md** - Common issues
