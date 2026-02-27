# data.js API Reference

**Version:** 1.62  
**Overview:** JavaScript library for loading, parsing, selection, transforming, and caching data tables. Loaded data is stored in a **Data.Table** (jsonDB format). Supports CSV, JSON, GeoJSON, KML, GML, RSS, Parquet, GeoPackage, FlatGeobuf, Geobuf, TopoJSON, JSON-stat, and jsonDB.

---

## Table of Contents

1. [Data (namespace)](#data-namespace)
2. [Data.Object](#dataobject)
3. [Data.Feed](#datafeed)
4. [Data.Table](#datatable)
5. [Data.Column](#datacolumn)
6. [Data.Broker](#databroker)
7. [Supported source types](#supported-source-types)

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

Create a **Data.Broker** to load multiple sources and run a callback when all are loaded.

- **Returns:** Data.Broker

**Example:**

```javascript
Data.provider()
  .addSource("https://example.com/a.csv", "csv")
  .addSource("https://example.com/b.json", "json")
  .realize(function(dataA) {
    var tableA = dataA[0], tableB = dataA[1];
  });
```

---

#### `Data.broker()` ⚠️ deprecated

Older form of `Data.provider()`. Still works but prefer `Data.provider()`.

---

#### `new Data.Broker()` ⚠️ deprecated

Constructor form. Prefer `Data.provider()`.

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

#### `realize([callback])`

Start loading all added sources. When all are done, calls the callback with an array of **Data.Table** (same order as **addSource**).

- **Parameters:** `callback` (function, optional) – `function(dataA)`
- **Returns:** this

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
| `parquet`  | Parquet (via DuckDB WASM) |
| `geoparquet` | GeoParquet (via DuckDB WASM → GeoJSON) |
| `gpkg` / `geopackage` | GeoPackage (via DuckDB WASM spatial → GeoJSON) |
| `flatgeobuf` / `fgb` | FlatGeobuf (binary → GeoJSON) |
| `geobuf` / `pbf`    | Geobuf (Protocol Buffer → GeoJSON) |
| `rss`      | XML RSS feed |
| `kml`      | Keyhole Markup Language |
| `gml`      | Geography Markup Language |

For **Data.feed()**, `source` is a URL (or path). For **Data.object()** / **Data.import()**, `source` is the in-memory object or string. Parquet/GeoParquet/GeoPackage can also accept an **ArrayBuffer** (e.g. from File API) when used with **Data.object()**.

---

*Generated from data.js (v1.62). Copyright © Guenter Richter. License: MIT.*
