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
- `"OpenStreetMap - Osmarenderer"` - Standard OpenStreetMap
- `"CartoDB - Positron"` - Light CartoDB style (note spaces)
- `"CartoDB - Dark matter"` - Dark CartoDB style (note spaces)
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
- The **map scale denominator** at which charts render at their normal/default size — i.e. the scale part after "1:" in "1:n"
- This is the **starting scale** for zoom-dependent chart sizing: charts grow when zooming in past this scale, shrink when zooming out
- **Set it to match the initial zoom level of the map** so charts appear correctly sized on first load
- Rough zoom → scale reference (web Mercator, mid-latitudes):
  - zoom 4 (continent): `"30000000"`
  - zoom 5 (large country): `"15000000"`
  - zoom 6 (country, e.g. Italy): `"8000000"`
  - zoom 8 (region): `"2000000"`
  - zoom 10 (province/county): `"500000"`
  - zoom 12 (city): `"100000"`
  - zoom 14 (district): `"25000"`
- Larger denominator = charts appear smaller at that zoom; smaller = larger
- ⛔ **NEVER set to `"1"` or any value below ~`"10000"`** — this tilts the entire scaling mechanism and produces wildly oversized or invisible charts at all zoom levels. Always use a geographically meaningful scale denominator.

**featurescaling** (string)
- `"true"` - Scale individual features (points/symbols) relative to each other based on zoom
- Works together with `objectscaling`

**dynamicScalePow** (number/string)
- Exponent controlling how aggressively symbols grow/shrink with zoom when `objectscaling: "dynamic"`
- `"1.0"` - linear scaling
- `"1.8"` - recommended for dense point datasets (symbols grow faster on zoom-in, preventing clutter at low zoom)
- Higher values = more contrast between zoom levels

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
    featurescaling: "true",
    objectscaling: "dynamic",
    normalSizeScale: "50000",     // lower value for city-scale maps
    dynamicScalePow: "1.8",       // aggressive zoom scaling for dense data
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

**For programmatic multi-source loading (`query` + `ixmaps.setExternalData`):**

Use this pattern when you need to load multiple files, merge them, and/or transform the combined result before handing it to the layer. The `query` property takes a function string (like `process`); the function receives a `themeObj` and an `options` object and must call `ixmaps.setExternalData(table, options)` to inject the final Data.Table.

```javascript
var loadData = function(themeObj, options) {
    Data.provider()                // ✅ preferred form; Data.broker() / new Data.Broker() are deprecated
        .addSource("https://example.com/data_2022.csv.gz", "csv")
        .addSource("https://example.com/data_2023.csv.gz", "csv")
        .addSource("https://example.com/data_2024.csv.gz", "csv")
        .realize(function(dataA) {
            // Keep only needed columns (saves memory with large datasets)
            for (var i = 0; i < dataA.length; i++) {
                dataA[i] = dataA[i].subtable({ fields: ['lat', 'lon', 'category', 'value'] });
            }
            // Merge all tables into dataA[0]
            dataA[0].append(dataA[1]);
            dataA[0].append(dataA[2]);

            // Optionally transform columns in place
            dataA[0].column("category").map(function(v) {
                if (v == 1) return "Low";
                if (v == 2) return "Medium";
                if (v == 3) return "High";
                return v;
            });

            // REQUIRED: inject the merged table into the layer
            options.type = "dbtable";
            ixmaps.setExternalData(dataA[0], options);
        });
};

myMap.layer("accidents")
    .data({
        name: "themeDataObj",      // fixed name — tells ixmaps to expect external data
        query: loadData.toString(), // serialized function string
        cache: "true"              // cache so shared layers reuse the same load
    })
    .binding({ position: "lat|lon", value: "value", title: "category" })
    .type("CHART|BUBBLE|SIZE|VALUES|CATEGORICAL|AGGREGATE|COUNT|RECT")
    .style({ ... })
    .define();
```

**Key points:**
- `name: "themeDataObj"` — fixed sentinel name; tells ixmaps the data comes via `setExternalData`
- `query: fn.toString()` — serialized function string; the function receives `(themeObj, options)` and must call `ixmaps.setExternalData(data, options)` when ready
- **`options.type` must be set before calling `setExternalData`** — two valid values:
  - `options.type = "dbtable"` — when passing a Data.js table (from `Data.provider().realize()`)
  - `options.type = "json"` — when passing a plain JSON array of objects (e.g. from `fetch()` + manual CSV parse)
- `ixmaps.setExternalData(data, options)` — injects the data into the waiting layer
- `cache: "true"` — multiple layers sharing the same `name` reuse one load (efficient for overlays)
- Use `subtable({ fields: [...] })` before `append()` to discard unneeded columns — critical for memory when merging millions of rows
- `Data.Broker` is the right tool for Data.js tables; use `fetch()` + manual parse for multi-source CSV with custom transformations

**Pattern: multi-CSV fetch with custom parsing (e.g. semicolon-delimited, European decimals):**
```javascript
var loadData = function(themeObj, options) {
    var csvUrls = { "2020": "https://...", "2021": "https://..." };

    function parseCSV(text, anno) {
        var lines = text.split('\n');
        var sep = lines[0].indexOf(';') >= 0 ? ';' : ',';
        var header = lines[0].split(sep).map(function(h) { return h.trim(); });
        var latIdx = header.findIndex(function(h) { return /^latitud/i.test(h); });
        var lonIdx = header.findIndex(function(h) { return /^longitud/i.test(h); });
        var records = [];
        for (var i = 1; i < lines.length; i++) {
            var cols = lines[i].split(sep);
            var lat = parseFloat((cols[latIdx] || '').replace(',', '.'));  // fix EU decimals
            var lon = parseFloat((cols[lonIdx] || '').replace(',', '.'));
            if (!isNaN(lat) && !isNaN(lon)) records.push({ lat, lon, anno });
        }
        return records;
    }

    var annos = Object.keys(csvUrls), allRecords = [], loaded = 0;
    annos.forEach(function(anno) {
        fetch(csvUrls[anno]).then(function(r) { return r.text(); }).then(function(text) {
            allRecords = allRecords.concat(parseCSV(text, anno));
            if (++loaded === annos.length) {
                options.type = "json";                   // ← plain JSON array
                ixmaps.setExternalData(allRecords, options);
            }
        });
    });
};

myMap.layer("sinistri")
    .data({ name: "sinistriData", query: loadData.toString(), cache: "true" })
    .binding({ position: "lat|lon", value: "anno" })
    ...
    .define();
```
⚠️ **The function must be entirely self-contained** (no closure variables) because `.toString()` serialises only the function body — any variables referenced from an outer scope will be `undefined` when ixmaps evaluates the serialised string.

---

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

**Examples:**
```javascript
.filter("WHERE value > 100")
.filter("WHERE year == 2024")
.filter("WHERE CNTR_CODE == \"IT\"")       // string value — escaped " inside JS string
.filter("WHERE category == \"Active\"")    // NEVER use single quotes for string values!
```

**String value quoting rules:**
- ⚠️ **NEVER use single quotes `'`** — they are NOT string delimiters in ixMaps filters; they become part of the matched value and produce no matches
- Unquoted (no spaces): `.filter("WHERE code == IT")`
- Quoted (explicit / spaces): use escaped double quotes → `.filter("WHERE name == \"New York\"")`

### `.type(vizType)`

Specify visualization type.

**Point data types:**
- `"CHART|DOT"` - Uniform dots
- `"CHART|DOT|CATEGORICAL"` - Categorical dots
- `"CHART|BUBBLE|SIZE"` - Sized bubbles, **no labels** (preferred default)
- `"CHART|BUBBLE|SIZE|VALUES"` - Sized bubbles **with numeric value labels** rendered inside each circle (`VALUES` activates the text)
- `"CHART|PIE"` - Pie charts
- `"CHART|BAR|VALUES"` - Bar charts
- `"CHART|BUBBLE|SIZE|AGGREGATE"` - Density grid (circles, sized by count)
- `"CHART|SYMBOL|AGGREGATE|RECT|SUM|GRIDSIZE"` + `symbols:"square"` - Density grid (filled squares)
- `"CHART|VECTOR|BEZIER|POINTER"` - Directional flow arrows (origin → destination)

**GeoJSON/TopoJSON types:**
- `"FEATURE"` - Simple features
- `"FEATURE|CHOROPLETH"` - Numeric choropleth
- `"FEATURE|CHOROPLETH|EQUIDISTANT"` - Equal intervals
- `"FEATURE|CHOROPLETH|QUANTILE"` - Quantile breaks
- `"FEATURE|CHOROPLETH|CATEGORICAL"` - Category choropleth
- `"CHOROPLETH|QUANTILE|DOPACITYMAX"` - Dynamic opacity (varies transparency by data values)
- `"CHOROPLETH|QUANTILE|DOPACITYMINMAX"` - Dynamic opacity highlighting min/max extremes

**Type Modifier: DOPACITYMAX**

Adds dynamic opacity to choropleth maps based on data values, creating linear opacity gradient from low to high.

**Usage:**
```javascript
.type("CHOROPLETH|QUANTILE|DOPACITYMAX")
```

**Requires style properties:**
- `dopacitypow`: Interpolation curve power (default: 1)
- `dopacityscale`: Opacity intensity multiplier (default: 1)

**Effect:** High values become more opaque, low values more transparent, creating visual hierarchy.

See SKILL.md "Dynamic Opacity (DOPACITYMAX)" for detailed documentation and examples.

**Type Modifier: DOPACITYMINMAX**

Adds dynamic opacity with U-shaped curve that highlights both minimum AND maximum values while fading mid-range values.

**Usage:**
```javascript
.type("CHOROPLETH|QUANTILE|DOPACITYMINMAX")
```

**Requires style properties:**
- `dopacitypow`: U-curve steepness (default: 1)
- `dopacityscale`: Opacity intensity multiplier (default: 1)

**Effect:** Both low and high values become opaque (prominent), mid-range values become transparent (fade), creating outlier emphasis.

**Use cases:**
- Outlier detection (quality control, anomalies)
- Diverging data (temperature hot/cold, sentiment positive/negative)
- Performance extremes (best and worst performers)
- Deviation from norm (above/below target)

See SKILL.md "Dynamic Opacity - Min/Max Variant (DOPACITYMINMAX)" for detailed documentation and examples.

**Type: VECTOR (Flow Visualization)**

Creates directional arrows showing flows between geographic locations.

**Usage:**
```javascript
.type("CHART|VECTOR|BEZIER|POINTER")
```

**Requires binding properties:**
- `position`: Origin/source location field
- `position2`: Destination/target location field

**Common modifiers:**
- `BEZIER`: Smooth curved arrows (vs straight lines)
- `POINTER`: Adds arrowheads showing direction
- `DASH`: Dashed lines instead of solid
- `NOSCALE`: Constant arrow thickness (doesn't scale with zoom)
- `EXACT`: Precise positioning at geographic coordinates
- `AGGREGATE`: Combines multiple flows between same origin-destination
- `SUM`: Sums values when aggregating (use with AGGREGATE)

**Requires style properties:**
- `colorfield`: Field name for arrow color (e.g., "origin")
- `sizefield`: Field name for arrow thickness (e.g., "value")
- `rangescale`: Thickness variation range (typical: 3-10)

**Effect:** Creates directional arrows from origin → destination locations. Arrow thickness encodes numeric values, arrow color encodes categories.

**Use cases:**
- Supply chain flows (supplier → buyer)
- Migration patterns (origin → destination)
- Trade routes (exporter → importer)
- Transportation flows (departure → arrival)

**Example:**
```javascript
.binding({
    position: "origin_region",
    position2: "destination_region"
})
.type("CHART|VECTOR|BEZIER|POINTER|AGGREGATE|SUM")
.style({
    colorscheme: ["#1F77B4", "#FF7F0E", "#2CA02C"],
    colorfield: "origin_region",
    sizefield: "trade_value",
    opacity: 0.67,
    rangescale: 5,
    showdata: "true"
})
```

See SKILL.md "Flow Visualization (VECTOR)" and EXAMPLES.md "Flow Visualization Examples" for complete documentation.

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

### Data Preprocessing with `process`

The `process` property allows you to transform data **after loading but before visualization**. This is useful for:
- Adding computed columns (categories, derived values, parsed sub-fields)
- Standardizing or transforming existing column values
- Filtering records
- Enriching data before binding

**Syntax:**
```javascript
// IMPORTANT: process requires STRING representation of function
.data({
    url: "data.csv",
    type: "csv",
    process: functionName.toString()  // ← Convert function to string!
})
```

**Preprocessing function signature:**
```javascript
function preprocessData(data) {
    // data: a Data.Table object — NOT a plain array
    // Use data.addColumn(), data.column(), data.filter(), etc.

    data.addColumn({ source: 'existingField', destination: 'newField' }, function(value, row) {
        return transformedValue(value);
    });

    return data;  // Return the Data.Table
}
```

> ❌ **Do NOT use** `data.forEach(record => {...})` — `data` is a **Data.Table**, not an array.
> ✅ Use `data.addColumn()`, `data.column().map()`, `data.filter()`, `data.select()`.
> See `DATA_JS_GUIDE.md` for the full Data.Table API reference.

**Example 1: Extract fields from a nested JSON column**

When the API returns nested objects (e.g. `{ "current": { "temperature": 25, "humidity": 60 } }`):
```javascript
var extractFields = function(data) {
    data.addColumn({ source: 'current', destination: 'temperature' }, function(c, row) {
        return c ? Math.round(c.temperature || 0) : 0;
    });
    data.addColumn({ source: 'current', destination: 'humidity' }, function(c, row) {
        return (c && c.humidity != null) ? c.humidity.toFixed(1) : '-';
    });
    return data;
};

myMap.layer("weather")
    .data({ url: apiUrl, type: "json", process: extractFields.toString() })
    .binding({ position: "latitude|longitude", value: "temperature", title: "city" })
    .type("CHART|BUBBLE|SIZE|VALUES")
    .define();
```

**Example 2: Add a computed category column**
```javascript
var addCategory = function(data) {
    data.addColumn({ source: 'aqi', destination: 'category' }, function(v, row) {
        if (v <= 20)  return 'Good';
        if (v <= 40)  return 'Fair';
        if (v <= 60)  return 'Moderate';
        if (v <= 80)  return 'Poor';
        if (v <= 100) return 'Very Poor';
        return 'Extremely Poor';
    });
    return data;
};
```

**Example 3: Standardize an existing column in place**

Use `data.column('name').map(fn)` to transform values in place (no new column added):
```javascript
var standardizeRegions = function(data) {
    data.column('region').map(function(value, row, index) {
        if (value === 'EMILIA ROMAGNA')     return 'EMILIA-ROMAGNA';
        if (value === 'TRENTINO ALTO ADIGE') return 'TRENTINO-ALTO ADIGE';
        return value;
    });
    return data;
};

myMap.layer("regions")
    .data({
        url: "https://example.com/data.csv",
        type: "csv",
        process: standardizeRegions.toString()
    })
    .binding({ lookup: "region", value: "population" })
    .type("CHOROPLETH")
    .define();
```

**Example 4: Add a row-index column (using closure counter)**

`addColumn` callbacks do not receive row index — use a closure counter:
```javascript
var addNames = function(data) {
    var names = ['Roma', 'Milano', 'Napoli', 'Torino'];
    var i = 0;
    data.addColumn({ destination: 'city' }, function(row) {
        return names[i++] || '';
    });
    return data;
};
```

**Example 5: Combine two source columns into one**
```javascript
var combineFields = function(data) {
    data.addColumn({ source: ['first_name', 'last_name'], destination: 'full_name' },
        function(first, last, row) {
            return first + ' ' + last;
        }
    );
    return data;
};
```

**Key Points:**
- ✅ `data` is a **Data.Table** — use `data.addColumn()`, `data.column()`, `data.columnIndex()`
- ✅ `addColumn({ source: 'field', destination: 'newField' }, fn)` — `fn(sourceValue, row)`
- ✅ `addColumn({ source: ['f1','f2'], destination: 'out' }, fn)` — `fn(v1, v2, row)` for multi-source
- ✅ `addColumn({ destination: 'out' }, fn)` — no source → `fn(row)` only (use closure counter for index)
- ✅ `column('name').map(fn)` — `fn(value, row, index)`, transforms column in place
- ✅ `data.filter(fn)` — keep rows where `fn(row)` is truthy
- ✅ `data.select('WHERE "col" = "val"')` — SQL-like filtering
- ✅ `data.json()` — convert to array of plain objects (useful for debugging)
- ✅ **CRITICAL:** Use `.toString()` to convert function to string: `process: myFunc.toString()`
- ❌ Do NOT use `data.forEach(...)` — Data.Table is not a plain array
- ❌ Do NOT use `data.column('x').index` — use `data.columnIndex('x')` instead

**Common Use Cases:**
1. **Nested object extraction**: Unpack `current.temperature` into a top-level `temperature` column
2. **Computed categories**: Map numeric ranges to string labels
3. **Name standardization**: Fix spelling variations, change case
4. **Derived fields**: Combine, calculate, or classify values
5. **Record filtering**: Remove incomplete or out-of-range rows

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

### Position / Alignment Properties

**align** (string, optional)
- Controls where the chart is positioned relative to its anchor point
- Default: `"center"` (chart centered on its geographic position)
- **Basic values:** `"center"` `"left"` `"right"` `"top"` `"bottom"` `"above"` `"below"`
- **Combined values** (space-separated): `"top left"`, `"above right"`, `"below left"`, etc.
- **Pixel offset syntax:** `"23right"` / `"23left"` — shift by fixed pixel amount
- **Percentage offset syntax:** `"10%right"` / `"10%left"` — shift by % of chart width
- Only add on user request; default `"center"` is correct for most use cases
- Examples:
  ```javascript
  align: "right"         // anchor left edge of chart to the geo point
  align: "above"         // chart sits above its geo point
  align: "top left"      // chart above and to the left
  align: "23right"       // shift 23px to the right
  align: "10%left"       // shift 10% of chart width to the left
  ```

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

**CHART|BUBBLE|SIZE**
- Bubbles sized by data values, **no text labels** — preferred default for clean maps
- Larger values = larger circles
- Use with: `value` binding and `normalsizevalue` or `scale`

**CHART|BUBBLE|SIZE|VALUES**
- Same as above but **renders the numeric value as a text label inside each circle**
- The `VALUES` modifier is what activates the text — omit it to suppress labels
- Use only when the number inside the bubble adds meaningful information

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

**CHART|SYMBOL|AGGREGATE|RECT|SUM|GRIDSIZE** (square cell density)
- Density grid with filled square cells (heatmap style)
- Use with: `value: "$item$"`, `gridwidth` in style, and **`symbols: "square"`** in style
- ❌ `CHART|GRID|AGGREGATE` does NOT exist — always use `CHART|SYMBOL|AGGREGATE|RECT|SUM|GRIDSIZE` + `symbols:"square"` for square cells

**CHART|DOT|AGGREGATE**
- Density grid with dots
- Use with: `value: "$item$"` and `gridwidth` in style

---

## Multi-Variable Charts

Multi-variable charts display **more than one value** per location — either by breaking a categorical field into per-category counts, or by showing a multi-field value array. Each grid cell or point gets its own mini-chart (pie, bar, sequence of symbols, line curve, etc.).

### How the value array is built

There are three ways to feed a multi-variable chart:

| Method | Binding | Style | Aggregation |
|--------|---------|-------|-------------|
| **Explicit fields** | `values: "f1\|f2\|f3"` | `label:[]` names the segments | No aggregation needed |
| **Categorical count** | `value: "catField"` | `values:[...]` lists the categories | `CATEGORICAL\|AGGREGATE\|COUNT\|RECT` — counts rows per category per grid cell |
| **Categorical sum** | `value: "catField"` + `sizefield: "numericField"` | `values:[...]` lists the categories | `CATEGORICAL\|AGGREGATE\|SUM\|RECT` — sums `sizefield` per category per grid cell |

The `values:` + `label:` arrays in `.style()` always map the **category codes** → **display labels** (and implicitly define the segment order and colorscheme index).

**Categorical sum detail:** `sizefield` in `.style()` names the numeric column to sum. The `value` binding still defines the categorical axis (which segment), while `sizefield` provides the magnitude to accumulate:

```javascript
.binding({ position: "lat|lon", value: "accident_type" })
.type("CHART|SYMBOL|SEQUENCE|CATEGORICAL|AGGREGATE|SUM|RECT|...")
.style({
    sizefield:   "injured_count",  // ← numeric column to sum per category per cell
    values:      ["rear-end", "side", "pedestrian"],
    label:       ["Rear-end", "Side", "Pedestrian"],
    colorscheme: ["#0066cc", "#ddbb22", "#ff0088"]
})
```

Without `sizefield`, use `COUNT` instead of `SUM` (no numeric column needed — just tallies rows).

### Available multi-variable chart types (partial list — more will be added)

| Type | Description |
|------|-------------|
| `CHART\|PIE` | Pie / donut chart |
| `CHART\|BAR` | Horizontal bar chart |
| `CHART\|SYMBOL\|SEQUENCE` | Stack of colored symbols (circles/squares), one per category |
| `CHART\|SYMBOL\|PLOT\|LINES` | Line / area curve chart (time series per cell) |

---

## CHART|SYMBOL|SEQUENCE — Categorical Symbol Stack

Renders a **stacked column of proportionally-sized colored symbols** (one symbol per category), sized by count or sum. The overall chart height represents the total, and each segment's height represents its category share. Used for spatial aggregation of categorical point data.

**Typical use:** show the breakdown of accident types, land-use categories, incident categories, etc. per grid cell.

### Full type string

```
GLOW|CHART|SYMBOL|VALUES|SEQUENCE|STAR|SORT|DOWN|SIZEP1|CATEGORICAL|AGGREGATE|COUNT|RELOCATE|TEXTLEGEND|RECT|CLIPTOGEOBOUNDS
```

### Key flags explained

| Flag | Role |
|------|------|
| `CHART\|SYMBOL` | Base: render a chart made of symbols (circles by default) |
| `SEQUENCE` | Stack symbols vertically, one per active category |
| `STAR` | **Radial/star layout** — symbols radiate outward from the center like flower petals instead of stacking in a vertical column. Each category gets its own petal, sized by its share. Preferred over the default linear stack when there are many categories (5+), since no single direction is overloaded and the overall shape stays compact and readable at small sizes. |
| `SORT\|DOWN` | Sort segments largest-first, descending |
| `SIZEP1` | Size the first (dominant) segment proportionally to the total |
| `CATEGORICAL` | Treat the value field as categorical (not numeric) |
| `AGGREGATE\|COUNT` | Spatial aggregation: count rows per category per grid cell |
| `RECT` | Rectangular grid cell aggregation (vs hexagonal) |
| `RELOCATE` | Used with `AGGREGATE`: repositions the aggregated chart to the geographic center of the aggregated point positions (instead of the fixed grid cell center) |
| `TEXTLEGEND` | Show text-based legend (category names as labels) |
| `VALUES` | Render numeric count labels on segments |
| `CLIPTOGEOBOUNDS` | Clip charts to the map geographic bounds |
| `GLOW` | Add a soft glow/halo behind each symbol for legibility |
| `NOLEGEND` | Suppress the layer from the legend panel (use when a companion legend exists) |

### Binding

```javascript
.binding({
    position: "lat|lon",   // point positions
    value: "UART",         // categorical field — unique values become segments
    title: "UART"
})
```

### Style

```javascript
.style({
    // Explicit category → color mapping (parallel arrays)
    colorscheme: ["none", "#0066cc", "#ddbb22", "#ff0088", "#88dd88"],
    values:      ["0",    "1",       "3",       "6",       "4"],   // category codes
    label:       ["other","rear-end","side",    "pedestrian","head-on"], // display names

    fillopacity:    0.9,
    scale:          1,             // overall chart scale factor
    normalsizevalue: 20,           // cell count where chart appears at "normal" size
    valuescale:     1,
    valuedecimals:  0,
    clipparts:      10,            // max segments to render per chart
    maxcharts:      100000,        // cap on total charts rendered

    // Zoom-dependent aggregation cell size
    aggregation: ["1:1", "3px", "1:500000", "2px"],  // [scale, px, scale, px, ...]

    // Scale-dependent visibility
    chartupper:  "1:1000000",  // hide charts when zoomed out beyond this scale (denominator > N)
    chartlower:  "1:1000",     // hide charts when zoomed in beyond this scale (denominator < N)
    valuesupper: "1:10000",    // hide value labels above this map scale

    showdata: "true",
    name: "chart"              // theme name for changeThemeStyle() targeting
})
```

### Complete example

```javascript
myMap.layer("accidents")
    .data({ url: "accidents.csv", type: "csv" })
    .binding({
        position: "lat|lon",
        value: "accident_type",
        title: "accident_type"
    })
    .type("GLOW|CHART|SYMBOL|VALUES|SEQUENCE|STAR|SORT|DOWN|SIZEP1|CATEGORICAL|AGGREGATE|COUNT|RECT|CLIPTOGEOBOUNDS")
    .style({
        colorscheme:     ["#0066cc", "#ddbb22", "#ff0088", "#88dd88", "#aaaaaa"],
        values:          ["rear-end", "side", "pedestrian", "head-on", "other"],
        label:           ["Rear-end", "Side impact", "Pedestrian", "Head-on", "Other"],
        fillopacity:     0.9,
        scale:           1,
        normalsizevalue: 20,
        clipparts:       5,
        maxcharts:       100000,
        aggregation:     ["1:1", "3px", "1:500000", "2px"],
        chartupper:      "1:1000000",
        showdata:        "true"
    })
    .meta({ title: "Accident Types" })
    .define();
```

---

## CHART|SYMBOL|PLOT|LINES — Time-Series Curve Chart

Renders a **line/area curve chart** per grid cell, showing how a value changes across an ordered set of categories (typically years or time steps). Each cell shows its own mini sparkline. Used for trend analysis across time within spatial grid cells.

**Typical use:** show how accident counts, case numbers, or measurements evolved year-by-year per area.

### Full type string

```
CHART|SYMBOL|PLOT|LINES|AREA|LASTARROW|SMOOTH|CATEGORICAL|BOX|XAXIS|FIXSIZE|GRIDSIZE|ZEROISNOTVALUE|AGGREGATE|RECT|SUM|NOSORT|NOLEGEND|CLIPTOGEOBOUNDS
```

### Key flags explained

| Flag | Role |
|------|------|
| `CHART\|SYMBOL\|PLOT` | Base: render a plot/chart as a symbol per location |
| `LINES` | Draw lines connecting data points |
| `AREA` | Fill area under the line |
| `SMOOTH` | Smooth/interpolate the curve between points |
| `LASTARROW` | Draw a directional arrow at the last data point (shows trend direction) |
| `BOX` | Draw a background box behind the chart |
| `XAXIS` | Show x-axis labels (from `xaxis:` style array) |
| `FIXSIZE` | Chart has a fixed size regardless of data values |
| `GRIDSIZE` | Chart size matches the grid cell size |
| `CATEGORICAL` | Treat value field as categorical (here: year values as categories) |
| `AGGREGATE\|SUM` | Spatial aggregation: **sum** the numeric value per category per cell |
| `AGGREGATE\|COUNT` | Alternative: count occurrences per category per cell |
| `RECT` | Rectangular grid cell aggregation |
| `NOSORT` | Keep categories in declared order (crucial for time series — do NOT sort years) |
| `ZEROISNOTVALUE` | Do not plot zero values (gaps in line where data is absent) |
| `NOLEGEND` | Suppress the layer from the legend panel |
| `CLIPTOGEOBOUNDS` | Clip charts to geographic bounds |

### Binding

```javascript
.binding({
    position: "lat|lon",
    value: "UJAHR"    // The field whose unique values form the X-axis (e.g. year)
})
```

### Style

```javascript
.style({
    colorscheme:     ["#666666"],  // single color for the line/area
    fillopacity:     "0.05",       // area fill opacity (low = subtle)
    shadow:          "true",

    // Define the ordered X-axis categories
    values:  ["2020", "2021", "2022", "2023", "2024"],  // category codes (must match data values)
    label:   ["2020", "2021", "2022", "2023", "2024"],  // X-axis labels
    xaxis:   ["2020", "2021", "2022", "2023", "2024"],  // which labels to show on X-axis

    normalsizevalue: "20",    // cell count where chart appears at normal size
    scale:           "0.9",   // overall scale factor
    rangescale:      "1",     // Y-axis scale factor
    linewidth:       "2",     // line stroke width
    markersize:      "3",     // data point marker size
    offsetx:         "-18",   // horizontal offset from grid cell center
    offsety:         "0",     // vertical offset
    boxopacity:      "0.001", // background box opacity
    bordercolor:     "none",  // background box border
    valuescale:      "1",
    gridwidthpx:     "100",   // grid cell width in pixels
    name:            "curves" // theme name for changeThemeStyle() targeting
})
```

### Complete example

```javascript
myMap.layer("yearly_trends")
    .data({ url: "events.csv", type: "csv" })
    .binding({
        position: "lat|lon",
        value: "year"          // categorical year field
    })
    .type("CHART|SYMBOL|PLOT|LINES|AREA|SMOOTH|LASTARROW|CATEGORICAL|BOX|XAXIS|FIXSIZE|GRIDSIZE|ZEROISNOTVALUE|AGGREGATE|RECT|COUNT|NOSORT|NOLEGEND|CLIPTOGEOBOUNDS")
    .style({
        colorscheme:     ["#0066cc"],
        fillopacity:     "0.1",
        values:          ["2020", "2021", "2022", "2023", "2024"],
        label:           ["2020", "2021", "2022", "2023", "2024"],
        xaxis:           ["2020", "2021", "2022", "2023", "2024"],
        normalsizevalue: "20",
        scale:           "1",
        rangescale:      "1",
        linewidth:       "2",
        markersize:      "3",
        gridwidthpx:     "100",
        name:            "curves"
    })
    .meta({ title: "Events per Year" })
    .define();
```

### Pairing SEQUENCE + PLOT on the same data

A powerful pattern is to show SEQUENCE charts as the primary layer and toggle PLOT curves as an overlay, both sharing the same `Data.provider()` load via `cache: "true"`. The curves layer is added/removed dynamically:

```javascript
// Toggle curves on/off
var toggleCurves = function(show) {
    if (show) {
        myMap.add(curvesLayer);   // layer pre-defined as variable
    } else {
        myMap.remove('curves');   // remove by style.name
    }
};
```

---

## CHART|SYMBOL|PLOT|LINES — Curves Anchored to Geo-Points (no grid)

A **variant** of the grid-based curve chart where each chart is pinned to the **exact geographic position** of a data point rather than a grid cell. Use this when your data is **already aggregated** (one row per location-year) and you want one curve per named location.

**Key difference from the GRIDSIZE variant:**

| | Grid-based (`GRIDSIZE`) | Point-anchored (`SIZE`, no `GRIDSIZE`) |
|---|---|---|
| Data format | Raw events (one row per event) | Pre-aggregated (one row per location-year) |
| Chart position | Grid cell centroid | Exact point lat/lon |
| Chart size | Matches cell size | Scaled by `SIZE` flag + `normalsizevalue` |
| Y-axis | COUNT or SUM of events per cell-year | SUM of `size:` field per location-year |
| `RECT` flag | Required | Not used |
| `GRIDSIZE` flag | Required | **Not used** |

### Binding

```javascript
.binding({
    position: "lat|lon",
    value:    "year",       // categorical field → X-axis grouper; string or ["year"]
    size:     "prestiti",  // numeric field → aggregated (SUM) per X-axis category
    title:    "name"
})
```

- **`value:`** — the categorical field whose distinct values map to X-axis positions; accepts a string `"year"` or array `["year"]`
- **`size:`** — the numeric field to SUM per category; drives chart height and the `SIZE` scaling
- **`values:` in style** — **defines the X-axis sequence**: order, count, and which categories appear; data field values are matched against this array

### Type flags (working set)

```
CHART|SYMBOL|PLOT|LINES|AREA|SMOOTH|FADE|BOX|TITLE|XAXIS|SIZE|NOSORT|ZEROISNOTVALUE|CATEGORICAL|AGGREGATE|SUM
```

| Flag | Role |
|------|------|
| `SIZE` | Scale chart by total aggregated value — replaces `GRIDSIZE` for point-anchored charts |
| `FADE` | Fade effect on chart |
| `TITLE` | Show title text from `.meta({ title: "…" })` in the legend panel |
| `XAXIS` | Show X-axis labels (from `label:` style array) |
| `NOSORT` | Keep categories in declared `values:` order — **critical for time series** |
| `ZEROISNOTVALUE` | Skip zero/null values (leaves gaps in the curve) |
| `CATEGORICAL\|AGGREGATE\|SUM` | Group rows by `value:` category, SUM the `size:` field per group |
| `LINES` / `AREA` / `SMOOTH` | Line, area fill, interpolation |
| `BOX` | Background box behind the chart |

### Style

```javascript
.style({
    colorscheme:     ["#1565C0"],
    fillopacity:     "0.12",           // area fill opacity
    values:          ["2016","2017","2018","2019","2020","2021","2022","2023"],
    label:           ["'16","'17","'18","'19","'20","'21","'22","'23"],
    xaxis:           ["'16","","","'19","'20","","","'23"],  // sparse labels
    normalsizevalue: "5000000",        // reference value: chart at 100% when size=this
    scale:           "0.05",           // overall chart scale
    rangescale:      "0.6",            // Y-axis zoom factor
    linewidth:       "2",
    markersize:      "1",
    valuescale:      "0.5",
    textscale:       "3",
    boxopacity:      "0.5",
    bordercolor:     "#cccccc",
    borderradius:    "10",
    boxmargin:       "5",
    showdata:        "true"
})
```

### Tooltip with inline chart preview

```javascript
.meta({
    tooltip: "{{theme.item.chart}}{{name}}",  // {{theme.item.chart}} = mini chart in tooltip
    title:   "label shown in legend panel"
})
```

### Complete example — library loans 2016–2023

```javascript
// Data: one row per library-year  { name, lat, lon, year: "2016", prestiti: 35000 }
myMap.layer("biblioteche")
    .data({ obj: libData, type: "json" })
    .binding({
        position: "lat|lon",
        value:    "year",
        size:     "prestiti",
        title:    "name"
    })
    .type("CHART|SYMBOL|PLOT|LINES|AREA|SMOOTH|FADE|BOX|TITLE|XAXIS|SIZE|NOSORT|ZEROISNOTVALUE|CATEGORICAL|AGGREGATE|SUM")
    .style({
        colorscheme:     ["#1565C0"],
        fillopacity:     "0.12",
        values:          ["2016","2017","2018","2019","2020","2021","2022","2023"],
        label:           ["'16","'17","'18","'19","'20","'21","'22","'23"],
        xaxis:           ["'16","","","'19","'20","","","'23"],
        normalsizevalue: "5000000",
        scale:           "0.05",
        rangescale:      "0.6",
        linewidth:       "2",
        markersize:      "1",
        valuescale:      "0.5",
        textscale:       "3",
        boxopacity:      "0.5",
        bordercolor:     "#cccccc",
        borderradius:    "10",
        boxmargin:       "5",
        showdata:        "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{name}}",
        title:   "prestiti per anno per biblioteca"
    })
    .define();
```

---

## CHART|SYMBOL|PLOT|LINES — Pattern A vs Pattern B (choosing the right shape)

The two grid-based sparkline patterns differ in **how the data is shaped**, which determines which type modifiers to use.

### Choosing which pattern to use

| | Pattern A — single column, categorical year | Pattern B — multiple pre-aggregated columns |
|---|---|---|
| **Data shape** | One row per event; year stored in a single field (e.g. `year: 2021`) | One row per location; each time step has its own column (e.g. `val2020`, `val2021`) |
| **`value:` binding** | Name of the year/category field: `value: "year"` | Pipe-chained column names: `value: "val2020\|val2021\|val2022"` |
| **Required aggregation flags** | `CATEGORICAL\|AGGREGATE\|RECT\|SUM` | ❌ None — data is already aggregated |
| **Style modifiers** | `AREA\|FADE\|LASTARROW\|FIXSIZE\|NOCLIP` (same) | `AREA\|FADE\|LASTARROW\|FIXSIZE\|NOCLIP` (same) |

### Role of aggregation flags (Pattern A only)

These flags are **aggregation semantics**, not visual style:
- `CATEGORICAL` — the `value:` field contains discrete category labels (year strings like `"2020"`, `"2021"`), not a numeric measure to plot directly
- `AGGREGATE` + `RECT` — partition the map into rectangular grid cells and aggregate records that fall inside each cell
- `SUM` — within each cell, sum counts per category to get the Y-axis value for each time step

### FIXSIZE and normalsizevalue

`FIXSIZE` makes all sparklines render at the **same physical size**, independent of data magnitude:
- **With `FIXSIZE`**: spark size is constant; controlled by `normalsizevalue` — a **larger value makes sparks smaller** (it is the reference data value that maps to the standard 30 px size, so higher = each unit is worth fewer pixels)
- **Without `FIXSIZE`**: spark height scales with the data — cells with more events get taller charts

### Pattern A — minimal example

```javascript
// Data: { lat, lon, year: 2021, ... }  — one row per incident
myMap.layer("sparks")
    .data({ obj: events, type: "json" })
    .binding({ geo: "lat|lon", value: "year" })
    .type("CHART|SYMBOL|PLOT|LINES|AREA|FADE|LASTARROW|NOCLIP|GRIDSIZE|CATEGORICAL|AGGREGATE|RECT|SUM|FIXSIZE")
    .style({
        colorscheme:     ["#00e5ff"],
        fillopacity:     0.3,
        gridwidth:       "100px",
        normalsizevalue: "100",   // tune this: larger = smaller sparks
        showdata:        "true"
    })
    .meta({ tooltip: "{{theme.item.chart}}{{theme.item.data}}" })
    .define();
```

### Pattern B — minimal example

```javascript
// Data: { lat, lon, val2020: 12, val2021: 18, val2022: 9, val2023: 21 }
myMap.layer("sparks")
    .data({ obj: preAgg, type: "json" })
    .binding({ geo: "lat|lon", value: "val2020|val2021|val2022|val2023" })
    .type("CHART|SYMBOL|PLOT|LINES|AREA|FADE|LASTARROW|NOCLIP|GRIDSIZE|FIXSIZE")
    .style({
        colorscheme:     ["#00e5ff"],
        fillopacity:     0.3,
        gridwidth:       "100px",
        normalsizevalue: "100",
        showdata:        "true"
    })
    .meta({ tooltip: "{{theme.item.chart}}{{theme.item.data}}" })
    .define();
```

---

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

### Explicit CATEGORICAL Color Binding (colorscheme + values)

When you need to **pin specific colors to specific category values** (e.g., for cross-visualization color consistency), use **parallel `colorscheme` and `values` arrays** instead of a palette name.

**Two valid approaches for explicit CATEGORICAL color binding:**

**Option 1 — Parallel arrays (colorscheme + values):**
```javascript
.style({
    colorscheme: ["#e74c3c", "#27ae60", "#2980b9"],  // one color per category
    values:      ["Lombardia", "Toscana", "Veneto"],  // matching category labels
    colorfield:  "origin",                            // field that holds category values
    showdata:    "true"
})
```
- `colorscheme` and `values` must be the same length
- Position i in `colorscheme` is assigned to position i in `values`
- Any category value not listed in `values` falls back to the first color

**Option 2 — Function as colorscheme:**
```javascript
.style({
    colorscheme: function(value) {
        const map = { "Lombardia": "#e74c3c", "Toscana": "#27ae60", "Veneto": "#2980b9" };
        return map[value] || "#aaaaaa";
    },
    colorfield: "origin",
    showdata: "true"
})
```

**⚠️ What does NOT work:**
```javascript
// WRONG — ixMaps does not support inline colorfield with embedded hex values:
.style({
    colorfield: "color",   // field that contains "#e74c3c" etc.  ← NOT supported
    showdata: "true"
})
```

### Cross-Visualization Color Consistency

When a map is combined with an external chart (D3, ECharts, Vega, etc.) and both must use the **same colors per category**, build a shared color lookup and derive the ixMaps parallel arrays from it:

```javascript
// 1. Build shared color dictionary (sorted alphabetically → stable across renders)
const palette = ["#e74c3c", "#27ae60", "#2980b9", "#8e44ad", "#d35400" /*, ... */];
const allNames = [...new Set(data.map(d => d.region))].sort();
const regionColors = {};
allNames.forEach((name, i) => { regionColors[name] = palette[i % palette.length]; });

// 2. Use regionColors in the external chart (D3 example)
const color = name => regionColors[name];

// 3. Build parallel arrays for ixMaps layers
//    (nameMap translates data names → TopoJSON / ixMaps geometry names if needed)
const ixNames  = Object.keys(nameMap).filter(k => regionColors[k]).map(k => nameMap[k]);
const ixColors = Object.keys(nameMap).filter(k => regionColors[k]).map(k => regionColors[k]);

// 4. Apply to VECTOR layer
ixmaps.layer("regions")
    .data({ obj: flowData, type: "json" })
    .binding({ position: "origin", position2: "destination" })
    .type("CHART|VECTOR|BEZIER|POINTER|AGGREGATE|SUM")
    .style({
        colorscheme: ixColors,   // parallel array
        values:      ixNames,    // parallel array
        colorfield:  "origin",
        sizefield:   "value",
        fillopacity: 0.67,
        showdata:    "true"
    })
    .define();

// 5. Apply identically to BUBBLE layer — same colorscheme + values
ixmaps.layer("regions")
    .data({ obj: bubbleData, type: "json" })
    .binding({ position: "region" })
    .type("CHART|BUBBLE|SIZE|VALUES|CATEGORICAL")
    .style({
        colorscheme: ixColors,
        values:      ixNames,
        colorfield:  "region",
        sizefield:   "total",
        fillopacity: 0.8,
        showdata:    "true"
    })
    .define();
```

**Key points:**
- Alphabetical sort of category names → deterministic color assignment across renders
- Same `colorscheme` / `values` arrays reused across all ixMaps layers → guaranteed consistency
- Name translation map needed when data labels differ from geometry labels (e.g., `"EMILIA ROMAGNA"` → `"Emilia-Romagna"`)
- Works for VECTOR, BUBBLE, DOT, and CHOROPLETH|CATEGORICAL layers

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
// IMPORTANT: Don't use 'map' as variable name - conflicts with ixMaps internals
const myMap = ixmaps.Map("map", { mapType: "white", mode: "info" })
    .options({ ... })
    .view({ ... })
    .legend("Multi-Layer Map");

// Layer 1
myMap.layer(
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
myMap.layer(
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

## Time Slider — `timefield` in `.binding()`

Adding `timefield` to `.binding()` **automatically creates an interactive time slider** in the ixMaps legend panel.

```javascript
.binding({
    geo: "lat|lon",    // or "geometry" for GeoJSON
    value: "magnitude",
    title: "place",
    timefield: "time"  // ← field containing date/time values
})
```

Works with any layer type: CHART|BUBBLE, CHART|DOT, CHART|SYMBOL, FEATURE|CHOROPLETH, etc.

**Accepted time formats** (via JavaScript `new Date()`):
- Unix timestamp in **milliseconds** — `1707834000000` ✅ (best)
- ISO date string — `"2024-02-14"` ✅
- ISO datetime string — `"2024-02-14T08:30:00Z"` ✅

**Adaptive range buttons** (auto-shown based on total data span):

| Data span | Range buttons | Window size |
|-----------|--------------|-------------|
| < 1 day | (none) | single point |
| 1–7 days | Hour | 1-hour window |
| 7–55 days | Hour, Day | 1-hour or 1-day window |
| 55–365 days | Day, Week | 1-day or 7-day window |
| > 365 days | Week, Month | 7-day or 28-day window |

**Requirements:**
- `legend: 'open'` in `ixmaps.Map()` so slider is visible on load
- Time field must exist in data; if missing: `ERROR: timefield 'fieldname' not found!`

**Special values:** `timefield: "$index$"` — frame-based animation using row index

**Full example — USGS earthquake map:**
```javascript
const myMap = ixmaps.Map('map', { mapType: 'CartoDB - Dark matter', mode: 'info', legend: 'open' })
    .view({ center: { lat: 35, lng: -100 }, zoom: 4 });

myMap.layer('earthquakes')
    .data({ obj: geojsonData, type: 'geojson' })
    .binding({ geo: 'geometry', value: 'mag', title: 'place', timefield: 'time' })
    .type('CHART|BUBBLE|SIZE|VALUES')
    .style({ colorscheme: ['#ffffb2','#fecc5c','#fd8d3c','#f03b20','#bd0026'],
             fillopacity: 0.80, showdata: 'true', units: ' M' })
    .meta({ name: 'earthquakes', tooltip: '{{place}} — M{{mag}}' })
    .define();
```

---

## Programmatic Time Control — `ixmaps.setThemeTimeFrame()`

Filters a theme's visible features to a time window from JavaScript — without rebuilding the theme. Use when building a custom slider UI.

```javascript
ixmaps.setThemeTimeFrame(themeId, startTimeMs, endTimeMs);
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `themeId` | string | Must match `name` in `.meta({ name: '...' })` — NOT the layer name |
| `startTimeMs` | number | Window start as Unix timestamp (ms) |
| `endTimeMs` | number | Window end as Unix timestamp (ms) |

**Requirements:** theme must have `timefield` in `.binding()`; use `legend: 'closed'` to hide built-in slider.

**Pattern — load once, filter on slider move:**
```javascript
myMap.layer('quakes')
    .data({ obj: allFeatures, type: 'geojson' })
    .binding({ geo: 'geometry', value: 'mag', timefield: 'time' })
    .meta({ name: 'quakes' })
    .define();

slider.addEventListener('input', function () {
    var endMs   = Number(this.value);
    var startMs = endMs - windowMs;
    ixmaps.setThemeTimeFrame('quakes', startMs, endMs);  // lightweight — no debounce needed
});
```

| Approach | `legend` | When to use |
|----------|----------|-------------|
| `timefield` + `legend: 'open'` | open | Quick built-in slider |
| `timefield` + `setThemeTimeFrame()` | closed | Custom slider UI, full programmatic control |

---

## CHART|USER — Custom Draw Functions

Lets you draw fully custom SVG shapes at each feature centroid using D3.

**Required dependencies** (load after ixmaps.js):
```html
<script src="https://d3js.org/d3.v3.min.js"></script>
<!-- pre-built options: -->
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps_flat@master/usercharts/d3/chart.js"></script>       <!-- pinnacleChart -->
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps_flat@master/usercharts/d3/arrow_chart.js"></script> <!-- arrowChart -->
```
Note: `ixmaps_flat` with **underscore** (not hyphen).

**Layer definition:**
```javascript
myMap.layer("myLayer")
    .data({ obj: data, type: "json" })
    .binding({ lookup: "joinField", value: "mainValue", title: "nameField" })
    .type("CHART|USER|SIZE|VALUES")
    .style({
        userdraw:         "myChart",   // must match window.ixmaps.myChart function name
        colorscheme:      ["#c62828","#1b5e20"],
        rangecentervalue: 0,
        fillopacity:      0.85,
        rangescale:       0.2,         // ← controls SIZE (NOT scale:)
        showdata:         "true"
    })
    .define();
```

**⚠️ `rangescale` controls chart size, NOT `scale:`**

**Multiple data fields** — use `values:` (pipe-separated):
```javascript
.binding({ lookup: "name", values: "wind_speed|wind_dir|precip", title: "name" })
// args.value  === args.values[0]
// args.values[1] === wind_dir, args.values[2] === precip
// ⚠️ args.item.szLabel is ALWAYS null in CHART|USER — do not use as lookup key
```

**Key `args` properties in draw function:**

| Property | Source |
|----------|--------|
| `args.value` | first field in `value:` / `values:` |
| `args.values[]` | all pipe-separated fields |
| `args.theme.colorScheme` | `colorscheme` array |
| `args.theme.nMax` / `nMin` | auto-computed range |
| `args.theme.nRangeScale` | `rangescale` property |
| `args.theme.fillOpacity` | `fillopacity` |
| `args.theme.szUnits` | `units` |
| `args.maxSize` | computed max display size |
| `args.item.szTitle` | title from binding |
| `args.target` | CSS selector for SVG element |

**Minimal draw function skeleton:**
```javascript
window.ixmaps = window.ixmaps || {};
ixmaps.myChart_init = function (SVGDocument, args) { /* shared SVG defs once */ };
ixmaps.myChart = function (SVGDocument, args) {
    var val     = args.value || 0;
    var nHeight = args.maxSize * 20 * (args.theme.nRangeScale || 1);
    if (!args.item || nHeight === 0) return false;
    var sc      = nHeight / 900;
    var szColor = args.color || args.theme.colorScheme[args.class || 0];
    var svg = d3.select(args.target);
    var g   = svg.append("g").attr("transform", "scale(" + sc + ")");
    g.append("rect")
        .attr("x", -30).attr("y", -900).attr("width", 60).attr("height", 900 * (val / args.theme.nMax))
        .attr("style", "fill:" + szColor + ";fill-opacity:" + args.theme.fillOpacity);
    return { x: 0, y: 0 };
};
```

**Type flags for CHART|USER:**
`USER` (required) · `SIZE` · `VALUES` · `TITLE` · `ZOOM` · `SILENT`

**Pre-built functions:**

| Script | `userdraw` value | Shape |
|--------|-----------------|-------|
| `chart.js` | `"pinnacleChart"` | triangle/peak with gradient |
| `arrow_chart.js` | `"arrowChart"` | up/down arrows for signed values |

**Suppressing tooltips on FEATURE layers:**
```javascript
.type("FEATURE|SILENT")   // .meta({tooltip:""}) alone is NOT enough
```

---

For more information:
- **SKILL.md** - Skill decision guide and critical rules
- **EXAMPLES.md** - Complete working examples
- **TROUBLESHOOTING.md** - Common issues and fixes
