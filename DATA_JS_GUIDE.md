# data.js API Reference

**CDN:** `https://cdn.jsdelivr.net/gh/gjrichter/data.js@master/data.js`
**Version:** 1.63
**Overview:** JavaScript library for loading, parsing, selection, transforming, and caching data tables. Loaded data is stored in a **Data.Table** (jsonDB format). Supports CSV, JSON, GeoJSON, KML, GML, RSS, Parquet, GeoPackage, FlatGeobuf, Geobuf, TopoJSON, JSON-stat, and jsonDB.

> **data.js is already loaded by the ixmaps framework.** `Data.*` functions are available inside `query:` and `process:` callbacks without any extra `<script>` tag.
> Only include the CDN explicitly when you need `Data.*` **outside** ixmaps theme realization (e.g. pre-processing data in your own `<script>` block before defining layers).

---

## ixmaps Integration

### When to include data.js explicitly

```html
<!-- ixmaps only — data.js is bundled, no extra script needed -->
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@1/ixmaps.js"></script>

<!-- Add data.js ONLY if you use Data.* in your own script outside ixmaps callbacks -->
<script src="https://cdn.jsdelivr.net/gh/gjrichter/data.js@master/data.js"></script>
```

### Inside `query:` / `process:` — Data.* available automatically

`Data` is globally available inside `query:` and `process:` functions because ixmaps has already loaded data.js:

```javascript
var myQueryFn = function(themeObj, options) {
  Data.provider()
    .addSource("https://example.com/2022.csv", "csv")
    .addSource("https://example.com/2023.csv", "csv")
    .load(function(tables) {
      var combined = tables[0].append(tables[1]);
      options.type = "jsondb";
      ixmaps.setExternalData(combined, options);
    });
};

myMap.layer("points")
  .data({ name: "myData", query: myQueryFn.toString(), cache: "true" })
  .binding({ geo: "lat|lon", value: "metric" })
  .type("CHART|BUBBLE|SIZE|VALUES")
  .style({ colorscheme: ["#0066cc"], showdata: "true" })
  .meta({ tooltip: "{{metric}}" })
  .define();
```

> **`name` + `cache: "true"`** — names the in-memory data object so it is loaded/parsed once. Omit `name` and each theme gets its own copy; give multiple themes the **same** `name` to share one dataset. It's the data-source name only — unrelated to the layer name or `meta.name`. See **API_REFERENCE.md § Data Configuration**.

### Outside ixmaps — include CDN, then use Data.*

When pre-processing data in your own `<script>` block (before or alongside layer definitions), include the CDN:

```html
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@1/ixmaps.js"></script>
<script src="https://cdn.jsdelivr.net/gh/gjrichter/data.js@master/data.js"></script>
<script>
Data.feed({ source: "https://example.com/data.csv", type: "csv" })
  .load(function(table) {
    table.addColumn({ source: "value", destination: "scaled" }, v => parseFloat(v) * 1000);
    myMap.layer("points")
      .data({ obj: table, type: "jsondb" })
      .binding({ geo: "lat|lon", value: "scaled" })
      .type("CHART|BUBBLE|SIZE|VALUES")
      .style({ colorscheme: ["#0066cc"], fillopacity: 0.7, showdata: "true" })
      .meta({ tooltip: "{{label}}: {{scaled}}" })
      .define();
  });
</script>
```

---

---

## Table of Contents

1. [Data (namespace)](#data-namespace)
2. [Data.Object](#dataobject)
3. [Data.Feed](#datafeed)
4. [Data.Table](#datatable)
5. [Data.Column](#datacolumn)
6. [Data.Broker](#databroker)
7. [Data.Merger](#datamerger)
8. [Supported source types](#supported-source-types)

---

## Data (namespace)

Global namespace. Use **Data.feed()** to load from URL, **Data.object()** / **Data.import()** to use in-memory objects, **Data.provider()** to load multiple sources (preferred; `Data.broker()` / `new Data.Broker()` are deprecated).

### Properties

| Property   | Type     | Description                    |
|-----------|----------|--------------------------------|
| `version` | string   | Library version (e.g. `"1.62"`) |
| `errors`  | Array    | Array of recent error messages |

### Methods

#### `Data.log(message)`

Log a message to the console.

- **Parameters:** `message` (any) – Message to log.
- **Returns:** void

---

#### `Data.cleanupDuckDB()`

Manually release DuckDB resources. Use if you see "Resource temporarily unavailable" errors.

- **Returns:** void

---

#### `Data.getOptimizedBatchSize(batchType, datasetRows, columnsCount)`

Get a batch size for parquet/worker processing based on memory and dataset shape.

- **Parameters:**
  - `batchType` (string) – `'parquet'`, `'worker'`, or `'extract'`
  - `datasetRows` (number) – Number of rows
  - `columnsCount` (number) – Number of columns
- **Returns:** number – Suggested batch size

---

#### `Data.batchConfig`

Configurable batch parameters for parquet reading (e.g. `maxMemoryMB`, default batch sizes). Adjust for memory/performance.

---

#### `Data.recordBatchPerformance(batchType, batchSize, processingTime, memoryUsed)`

Record one batch run for performance tuning.

- **Parameters:** `batchType` (string), `batchSize` (number), `processingTime` (number, ms), `memoryUsed` (number, MB)
- **Returns:** void

---

#### `Data.getPerformanceStats(batchType)`

Get performance statistics for a batch type.

- **Parameters:** `batchType` (string)
- **Returns:** object – Stats (e.g. recommended batch size, timings)

---

#### `Data.calculateOptimalBatchSize(batchType, records)`

Compute recommended batch size from performance history.

- **Parameters:** `batchType` (string), `records` (array)
- **Returns:** number

---

#### `Data.logPerformanceSummary()`

Log a performance summary to the console.

- **Returns:** void

---

#### `Data.feed(options)`

Create a **Data.Feed** instance to load one remote or local source.

- **Parameters:** `options` (object) – `{ source: url, type: "csv"|"json"|... }`. See [Supported source types](#supported-source-types).
- **Returns:** Data.Feed

**Example:**

```javascript
var myfeed = Data.feed({ source: "https://example.com/data.csv", type: "csv" })
  .load(function(mydata) { /* mydata is Data.Table */ })
  .error(function(e) { console.error(e); });
```

---

#### `Data.object(options)`

Create a **Data.Object** instance to import from an in-memory JavaScript object (e.g. parsed CSV/JSON).

- **Parameters:** `options` (object) – `{ source: object, type: "csv"|"json"|"geojson"|... }`
- **Returns:** Data.Object

**Example:**

```javascript
Data.object({ source: response, type: "json" }).import(function(mydata) {
  var a = mydata.column("column name").values();
});
```

---

#### `Data.import(options)`

Convenience: create a Data.Object, run import, and return the resulting **Data.Table** (synchronous for in-memory source).

- **Parameters:** `options` (object) – Same as `Data.object()`
- **Returns:** Data.Table

**Example:**

```javascript
table = Data.import({ source: response, type: "json" });
var a = table.column("column name").values();
```

---

#### `Data.provider()` ✅ preferred

Create a **Data.Broker** to load multiple sources in parallel and run a callback when all are loaded.

- **Returns:** Data.Broker

**Example:**

```javascript
Data.provider()
  .addSource("https://example.com/a.csv", "csv")
  .addSource("https://example.com/b.json", "json")
  .load(function(dataA) {
    var tableA = dataA[0], tableB = dataA[1];
  });
```

> **`.load(callback)`** is the method to call — `.realize(callback)` is an older alias for the exact same method, still works, but `.load()` is what to reach for in new code (matches `Data.feed(...).load(...)`'s naming).

---

#### `Data.broker()` ⚠️ deprecated

Older name for `Data.provider()`. Both return the same **Data.Broker** instance — still works, but `Data.provider()` is the current, unambiguous name.

---

#### `new Data.Broker()` ⚠️ deprecated

Constructor form. Prefer `Data.provider()`.

---

#### `Data.merger()` ✅ preferred

Create a **Data.Merger** to join two or more *already-loaded* `Data.Table`s by a shared lookup key — different from `Data.provider()`, which loads sources but does not join them.

- **Returns:** Data.Merger

**Example:**

```javascript
Data.merger()
  .addSource(prezzi,   { lookup: "idImpianto", columns: ["descCarburante", "prezzo"] })
  .addSource(impianti, { lookup: "idImpianto", columns: ["Bandiera", "Latitudine"] })
  .merge(function(mergedTable) {
    // mergedTable has prezzi's rows enriched with impianti's columns
  });
```

> **`.merge(callback)`** — `.realize(callback)` is an older alias for the same method, still works.

See [Data.Merger](#datamerger) below for the full method list.

---

## Data.Object

Imports data from an in-memory source (object or string). Use **Data.object(options)** to create.

### Constructor

`new Data.Object(options)`  
- **options:** `{ source, type }` – `source` is the raw data (object or string); `type` is the format (see [Supported source types](#supported-source-types)).

### Methods

#### `import(callback)`

Parse the source and call `callback` with a **Data.Table**.

- **Parameters:** `callback` (function) – `function(result)` where `result` is the Data.Table.
- **Returns:** this (chainable)

---

#### `error(callback)`

Register a function to run on import error.

- **Parameters:** `callback` (function) – `function(errorText)`
- **Returns:** this (chainable)

---

## Data.Feed

Loads one data source from a URL (or file). Use **Data.feed(options)** to create.

### Constructor

`new Data.Feed(options)`  
- **options:** `{ source, type, cache? }` – `source` is URL or path; `type` is format; `cache` optional (default true).

### Methods

#### `load(callback)`

Fetch and parse the source, then call `callback` with a **Data.Table**.

- **Parameters:** `callback` (function) – `function(data)` with Data.Table.
- **Returns:** this (chainable)

---

#### `error(callback)`

Register a function to run on load error.

- **Parameters:** `callback` (function) – `function(errorText)`
- **Returns:** this (chainable)

---

#### `getFileSize([callback])`

Get the size in bytes of the source (via HEAD/GET and Content-Length or Content-Range).

- **Parameters:** `callback` (function, optional) – `function(size)`. If omitted, returns a Promise.
- **Returns:** this (if callback given) or Promise&lt;number|null&gt;

---

#### Table delegates

After a successful **load()**, the feed’s internal table is available. These methods delegate to that **Data.Table**:

- **`column(szColumn)`** → Data.Column
- **`select(szSelection)`** → Data.Table (selection)
- **`aggregate(szColumn, szAggregation)`** → Data.Table
- **`revert()`** → Data.Table
- **`reverse()`** → Data.Table
- **`pivot(options)`** → Data.Table
- **`subtable(options)`** → Data.Table
- **`addTimeColumns(options)`** → this

See [Data.Table](#datatable) for semantics.

---

## Data.Table

Stores data in jsonDB shape: `{ table: { records, fields }, fields: [{ id, ... }], records: [ [...] ] }`. All data loaded by **feed()**, **object()**, or **broker()** is exposed as a Data.Table.

### Constructor

`new Data.Table([table])`  
- **table** (optional): object with `table`, `fields`, `records` to copy.

### Methods

#### `getArray()`

Return the table as a 2D array (first row = column names).

- **Returns:** Array&lt;Array&gt;

---

#### `setArray(dataA)`

Set table from a 2D array (first row = column names).

- **Parameters:** `dataA` (Array&lt;Array&gt;)
- **Returns:** this

---

#### `revert()` / `reverse()`

Reverse row order (last row becomes first).

- **Returns:** this

---

#### `columnNames()`

Return an array of column names.

- **Returns:** Array&lt;string&gt;

---

#### `columnIndex(columnName)`

Return the index of a column by name, or `null`.

- **Parameters:** `columnName` (string)
- **Returns:** number | null

---

#### `column(columnName)`

Return a **Data.Column** for the given column.

- **Parameters:** `columnName` (string)
- **Returns:** Data.Column | null

---

#### `lookupArray(szValue, szLookup)` / `lookupArray(options)`

Build an associative array: key = lookup column value, value = value column value. Options: `{ value, key, calc? }` where `calc` can be `"overwrite"`, `"sum"`, `"max"`.

- **Parameters:** `szValue` (string) – value column; `szLookup` (string) – key column. Or single `options` object.
- **Returns:** object (key → value)

---

#### `lookupStringArray(szValue, szLookup)`

Like `lookupArray` but concatenates multiple values per key as comma-separated strings.

- **Parameters:** `szValue`, `szLookup` (strings) or `{ value, key }`
- **Returns:** object

---

#### `lookup(value, option)`

Get one value by lookup. `option = { value: valueColumnName, lookup: lookupColumnName }`.

- **Parameters:** `value` (any), `option` (object)
- **Returns:** found value or `"-"`

---

#### `toKeyValue(option)`

Alias for `lookupArray(option.value, option.key)`. `option = { key, value }`.

- **Returns:** object

---

#### `addColumn(options, callback)`

Add a computed column.

- **options:** `{ source?: string | string[], destination: string }` – `source` is one column name or array of names; `destination` is the new column name.
- **callback:** `function(...values, row)` – receives source cell value(s) and full row; returns the new cell value. For multiple sources: `function(value1, value2, ..., row)`.
- **Returns:** this

**Example (single source):**

```javascript
mydata.addColumn({ source: 'created_at', destination: 'date' }, function(value, row) {
  var d = new Date(value);
  return d.getDate() + "." + (d.getMonth()+1) + "." + d.getFullYear();
});
```

---

#### `addRow(options)`

Append one row. `options` is an object mapping column names to values; missing columns get `""`.

- **Parameters:** `options` (object)
- **Returns:** this

---

#### `filter(callback)`

Keep rows for which `callback(row)` is truthy. Returns a new Data.Table (selection).

- **Parameters:** `callback` (function) – `function(row)` → boolean
- **Returns:** Data.Table

---

#### `select(szSelection)`

SQL-like selection. Query string must start with `WHERE`; supports `=`, `<>`, `>`, `<`, `>=`, `<=`, `BETWEEN ... AND ...`, `LIKE`, `NOT`, `IN (v1,v2,...)` or `IN "v1,v2,v3"`, combined with `AND` / `OR`. Column and values in double quotes; use `$columnname$` for value from another column.

- **Parameters:** `szSelection` (string) – e.g. `'WHERE "Age" = "Total"'`, `'WHERE "col" BETWEEN "1" AND "10"'`
- **Returns:** Data.Table (selection)

---

#### `aggregate(szColumn, szAggregate)` / `aggregate(options)`

Aggregate one value column by unique combinations of one or more lead columns (e.g. `"value"`, `"month|type"`). Options: `{ column/value, lead, calc?: "mean" }`.

- **Parameters:** `szColumn` (string) – value column; `szAggregate` (string) – lead column(s) separated by `|`. Or single options object.
- **Returns:** Data.Table

---

#### `condense(szColumn, option)` / `condense(options)`

Condense rows by a lead column: same lead value → one row; numeric columns summed (or `option.calc === "max"` for max). `option.keep` = column name or array of names to keep (not summed).

- **Parameters:** `szColumn` (string), `option` (object) – `{ lead, keep?, calc? }`. Or single options object with `lead`, `keep`, `calc`.
- **Returns:** Data.Table

---

#### `groupColumns(options)`

Add a column that is the sum of several numeric columns. `options = { source: [col1, col2, ...], destination: newColName }`.

- **Parameters:** `options` (object)
- **Returns:** this

---

#### `pivot(options)`

Build a pivot table.

- **options:**  
  - `lead` / `rows` – column(s) defining rows (string or array).  
  - `cols` / `columns` – column(s) defining pivot columns.  
  - `keep` – column(s) to copy as-is (array).  
  - `sum` – column(s) to sum (array).  
  - `value` – column(s) to aggregate (or `["1"]` for count).  
  - `forced` – optional array of column names to force in output.  
  - `calc` – `"string"` | `"max"` | `"mean"` (optional).

- **Returns:** Data.Table (pivot)

---

#### `subtable(options)`

Return a table with only the given columns. `options.columns` = array of column indices, or `options.fields` = array of column names.

- **Parameters:** `options` (object) – `{ columns?: number[] }` or `{ fields?: string[] }`
- **Returns:** Data.Table

---

#### `sort(sortColumn, [szFlag])`

Sort rows by `sortColumn`. Numeric if values look numeric; otherwise string. `szFlag === "DOWN"` for descending.

- **Parameters:** `sortColumn` (string), `szFlag` (string, optional) – `"DOWN"` for descending
- **Returns:** this

---

#### `append(sourceTable)`

Append all rows of `sourceTable`. Column count and names must match.

- **Parameters:** `sourceTable` (Data.Table)
- **Returns:** this

---

#### `json()`

Convert table to an array of objects (one per row), keys = column names.

- **Returns:** Array&lt;object&gt;

---

#### `addTimeColumns(options)`

Add date/time columns from a timestamp column. `options.source` = timestamp column name; `options.create` = optional array of names, default `['date','year','month','day','hour']`.

- **Parameters:** `options` (object) – `{ source: string, create?: string[] }`
- **Returns:** this

---

## Data.Column

Handle for a single column of a Data.Table. Obtained via **table.column(columnName)**.

### Constructor

`new Data.Column()` (internal; use **table.column(name)**).

### Methods

#### `values()`

Return an array of all values in the column.

- **Returns:** Array

---

#### `uniqueValues()`

Return an array of unique values (duplicates removed).

- **Returns:** Array

---

#### `map(callback)`

Replace each cell with the result of `callback(value, row, index)`.

- **Parameters:** `callback` (function) – `function(currVal, row, index)`
- **Returns:** this (Data.Column)

---

#### `rename(szName)`

Change the column’s name.

- **Parameters:** `szName` (string)
- **Returns:** this

---

#### `remove()`

Remove this column from the table.

- **Returns:** this

---

## Data.Broker

Loads multiple sources and runs a single callback when all are loaded. Use **Data.broker()** or **Data.provider()** to create.

### Constructor

`new Data.Broker([options])`  
- **options:** optional `{ callback }`.

### Methods

#### `addSource(szUrl, szType)`

Add a source URL and its type (see [Supported source types](#supported-source-types)).

- **Parameters:** `szUrl` (string), `szType` (string)
- **Returns:** this

---

#### `setCallback(callback)`

Set the success callback (alternative to passing it to **realize()**). *Deprecated: prefer passing callback to **realize()**.*

- **Parameters:** `callback` (function) – `function(dataA)` where `dataA` is an array of Data.Table, one per source.
- **Returns:** this

---

#### `load([callback])`

Start loading all added sources. When all are done, calls the callback with an array of **Data.Table** (same order as **addSource**).

- **Parameters:** `callback` (function, optional) – `function(dataA)`
- **Returns:** this

> `realize([callback])` is an older alias for this exact method — still works, identical behavior.

---

#### `error(onError)`

Set the error handler (called if any source fails).

- **Parameters:** `onError` (function) – `function(exception)`
- **Returns:** this

---

#### `notify(onNotify)`

Set a notify handler (e.g. progress).

- **Parameters:** `onNotify` (function)
- **Returns:** this

---

## Data.Merger

Joins two or more **already-loaded** `Data.Table`s by a shared lookup key column — a join, not a parallel-load (that's [Data.Broker](#databroker) / `Data.provider()`). Use **Data.merger()** to create.

### Constructor

`new Data.Merger()`

### Methods

#### `addSource(table, option)`

Register a loaded table as a merge source.

- **Parameters:** `table` (Data.Table or 2D array), `option` (object) – `{ lookup, columns, label }`:
  - `lookup` (string) – join key column name, present in every source
  - `columns` (array) – which columns from this source to pull into the merged result
  - `label` (array, optional) – rename incoming columns; positionally matched to `columns`
- **Returns:** this

The **first** `addSource` call provides the row backbone; every subsequent source is looked up by matching `lookup` values.

---

#### `setOutputColumns(columnsA)`

Restrict/order the final merged table's columns to a subset of the labels defined via `addSource`.

- **Parameters:** `columnsA` (array of strings)
- **Returns:** this

---

#### `merge([callback])`

Perform the join. Calls the callback with the merged **Data.Table**.

- **Parameters:** `callback` (function, optional) – `function(mergedTable)`
- **Returns:** this

> `realize([callback])` is an older alias for this exact method — still works, identical behavior.

**Example:**

```javascript
Data.merger()
  .addSource(prezzi,   { lookup: "idImpianto", columns: ["descCarburante", "prezzo"] })
  .addSource(impianti, { lookup: "idImpianto", columns: ["Bandiera", "Latitudine"] })
  .merge(function(mergedTable) {
    var selection = mergedTable.select('WHERE tipo_riga == "LI"');
  });
```

---

#### `error(onError)`

Set the error handler.

- **Parameters:** `onError` (function) – `function(exception)`
- **Returns:** this

---

## Supported source types

| type        | Description |
|------------|-------------|
| `csv`      | Comma- or semicolon-separated values (plain text) |
| `json`     | JSON (JavaScript object) |
| `geojson`  | [GeoJSON](https://geojson.org/) |
| `topojson` | [TopoJSON](https://github.com/topojson/topojson) |
| `jsonl` / `ndjson` | Newline-delimited JSON |
| `jsonDB` / `jsondb` | ixmaps internal table format |
| `jsonstat` | [JSON-stat](https://json-stat.org/format/) 2.0 dataset or bundle |
| `parquet`  | Parquet (via DuckDB WASM). With `bbox` set, queries a remote URL directly instead of downloading it — see [Remote parquet by bounding box](#remote-parquet-by-bounding-box) below |
| `geoparquet` | GeoParquet (via DuckDB WASM → GeoJSON) |
| `gpkg` / `geopackage` | GeoPackage (via DuckDB WASM spatial → GeoJSON) |
| `flatgeobuf` / `fgb` | FlatGeobuf (binary → GeoJSON) |
| `geobuf` / `pbf`    | Geobuf (Protocol Buffer → GeoJSON) |
| `rss`      | XML RSS feed |
| `kml`      | Keyhole Markup Language |
| `gml`      | Geography Markup Language |

---

### Remote parquet by bounding box

Large GeoParquet files (a country's worth of buildings, for example) don't need to be downloaded in full just to show what's in the current map viewport. Pass `bbox` on a `parquet` feed and data.js queries the remote URL directly with DuckDB WASM, reading only the row groups/columns that intersect the box — instead of downloading the whole file first.

```javascript
Data.feed({
    source:  "https://s3.eubucco.com/eubucco/v0.2/buildings/parquet/nuts_id=ITC4/ITC4.parquet",
    type:    "parquet",
    bbox:    [9.185, 45.460, 9.198, 45.468],   // [minX, minY, maxX, maxY], always EPSG:4326
    columns: ["id", "subtype", "height"],
    maxRows: 50000
}).load(function (mydata) {
    // mydata.records — only the buildings inside bbox
}).error(function (e) {
    // e.g. "bbox selects N rows (limit 50000) - zoom in or raise maxRows" if the box is too wide
});
```

**Options (bbox mode only):**

| Option | Type | Description |
|---|---|---|
| `bbox` | `[minX, minY, maxX, maxY]` | Required for bbox mode. Always EPSG:4326 (plain lon/lat), regardless of the source file's own CRS |
| `columns` | array of strings | Restrict the result to these columns (geometry is always included). Omit to get every non-list column |
| `crs` | string, e.g. `"EPSG:3035"` | Override the auto-detected source CRS |
| `proj4` | proj4 definition string | Override with a raw proj4 definition — takes precedence over `crs` |
| `maxRows` | number | Abort with a clear error instead of running the query if the bbox would select more rows than this |

**How it works:**
- Requires the source file to have a GeoParquet bbox helper column (the `covering.bbox` convention) — if it doesn't, data.js logs a warning and falls back to a full download.
- Automatically loads DuckDB WASM's `httpfs` extension for genuine HTTP range reads. Without `httpfs`, remote files ≥ 2 GB are rejected outright rather than risking an in-memory download that crashes; this only matters as a fallback if `httpfs` fails to load.
- Many real-world GeoParquet datasets use a projected CRS, not plain lon/lat — [EUBUCCO](https://eubucco.com/) v0.2, for example, uses EPSG:3035. data.js auto-detects this from the file's GeoParquet metadata, transforms your `bbox` into that CRS before querying (using all four corners, since projections curve straight edges), and transforms returned geometries back to EPSG:4326. Built-in proj4 definitions cover EPSG 3035, 3857, 2154, 25832/25833, 32632/32633; pass `crs` or `proj4` explicitly for anything else.

Full guide with more detail: [Remote Parquet by Bounding Box](https://gjrichter.github.io/docs/data.js/docs/remote_parquet_bbox.html) in the data.js documentation.

For **Data.feed()**, `source` is a URL (or path). For **Data.object()** / **Data.import()**, `source` is the in-memory object or string. Parquet/GeoParquet/GeoPackage can also accept an **ArrayBuffer** (e.g. from File API) when used with **Data.object()**.

---

*Generated from data.js (v1.62). Copyright © Guenter Richter. License: MIT.*
