# Extensions Guide — Client-Side Computed Layers (Turf.js & external libraries)

How to use an external JS library (Turf.js, d3-contour, simple-statistics, …) to
**compute a derived GeoJSON layer at runtime** and inject it into an ixMaps map as
a normal theme. The flagship example is a **weighted KDE (Kernel Density
Estimation) "danger index" heatmap**; the same pattern fits any computed overlay
(isolines, buffers, hulls, clustering, …).

> **Runnable scaffold → `template-kde.html`.** This guide explains the *concepts*
> and the two things you customize; the template is the complete, copy-and-fill file.
> ixMaps draws; the library computes.

---

## The extension pattern (4 steps)

1. **Load the library** via CDN, after `ixmaps.js`.
2. **Read the data you need** — usually the *currently visible* records of an
   existing theme, so the computation follows pan/zoom/filter.
3. **Compute a GeoJSON FeatureCollection** with the library.
4. **Inject it** as a layer and add it through the **map promise**, removing any
   previous instance first so it can be recomputed repeatedly:

```javascript
var _mapPromise = ixmaps.Map("map", {...}, map => map.view(...).layer(__host));

function inject(fc) {
    var def = ixmaps.layer("computed")
        .data({ obj: fc, type: "geojson" })   // obj: = inline data
        .binding({ geo: "geometry" })          // no value for SILENT
        .type("FEATURE|CHOROPLETH|SILENT")     // CHOROPLETH → changeThemeStyle works
        .style({ colorscheme: "#cc2200", fillopacity: 0.15, linewidth: 0.01 })
        .meta({ name: "computed" })            // unique name → remove/restyle target it
        .define();
    _mapPromise.then(api => { try { api.removeTheme("computed"); } catch(e){} api.layer(def); });
}
```

**Two requirements** (both in API_REFERENCE.md): include **`CHOROPLETH`** in the
type or `changeThemeStyle` (e.g. an opacity slider) silently no-ops; give the layer
a **unique `meta.name`** or `removeTheme`/`changeThemeStyle` hit the wrong theme.

---

## Reading the visible records of a theme

```javascript
var objTheme  = ixmaps.getThemeObj("chart");
var dbRecords = objTheme.objTheme.dbRecords;   // all rows (array of arrays)
var dbFields  = objTheme.objTheme.dbFields;    // [{id:"FERITI"}, …] column meta
var iField    = dbFields.findIndex(f => f.id === "FERITI");   // column index by name

var recIdx = [];                               // visible record indices
objTheme.indexA.forEach(ix => {                // indexA = visible items
    var item = objTheme.itemA[ix];
    if (!item) return;
    if (item.dbIndex != null) recIdx.push(item.dbIndex);          // single record
    if (Array.isArray(item.dbIndexA)) item.dbIndexA.forEach(d => recIdx.push(d));  // aggregated cell
});
```

**Coordinates depend on the data source:**

| Source | Coordinates in… | Read with |
|---|---|---|
| **CSV** lat/lng columns | `dbFields` columns | `+rec[iLat]`, `+rec[iLng]` |
| **TopoJSON / GeoJSON** points | the `geometry` field (JSON string) | `JSON.parse(rec[iGeo]).coordinates` → `[lng, lat]` |

---

## Weighted KDE — the two things you customize

The template carries the full engine (Gaussian KDE on a zoom-adaptive grid →
`turf.isobands` → stacked polygons). For your data you edit only:

**(A) coordinate extraction** — pick the row matching your source (table above).

**(B) the weight = the "index".** This is the whole point of a *weighted* KDE —
change it to ask a different question:

| Goal | Weight expression |
|---|---|
| **Danger / severity** (template default) | `deaths*10 + injured` (fatalities dominate) |
| Plain incident frequency | `1` for every point |
| Single field | `(+rec[iWeight] || 1)` |
| Custom severity index | `deaths*9 + injured*3 + 1` (equivalent-accident style) |

Floor the weight to `>= 1` if every record should contribute regardless of casualties.

---

## Why the "stacked isobands" trick works

`turf.isobands` returns **rings** (donuts) between successive break values. The
template discards the holes (keeps only `coordinates[0]`), so each band becomes a
*filled* blob: the 0.15 band covers everything above 0.15, the 0.30 band a smaller
area on top, etc. Drawn with **one color + one opacity**, the overlaps stack — the
peak (under all 4 bands) is darkest, the fringe lightest. A single `fillopacity`
slider rescales the whole ramp at once.

---

## Performance

- **Sample record indices *before* parsing geometry** — parsing tens of thousands
  of `geometry` JSON strings per redraw is the bottleneck; cap to `ptCap` first.
- **Debounce** the recompute 200–300 ms (pan/zoom fire many draw events).
- **Scale bandwidth + grid budget with zoom** (the template's table) — a fine grid
  at region zoom is wasted; a coarse grid at street zoom looks blocky.
- KDE is O(gridCells × points); both are bounded by the zoom table, so a redraw
  stays in the tens-of-ms range.

---

## Gotchas

- **Capture the map promise** (`var _mapPromise = ixmaps.Map(...)`) — the layer is
  injected via `_mapPromise.then(api => api.layer(def))`, recomputed repeatedly,
  not added at build time.
- **Remove before re-adding** every recompute, or duplicate layers stack up.
- **`fillopacity: 0` is coerced to 1** — hide a fill with `colorscheme: ["none"]`.
- **`CHOROPLETH` + unique `meta.name`** are both required for the opacity slider.
- **Guard `typeof turf === "undefined"`** so the map still works if the CDN fails.
- **Host theme must be drawn first** — the recompute reads its `objTheme` record
  store, which exists only after the theme has loaded/drawn. Recompute on its
  draw event (debounced).

> Complete runnable file → **template-kde.html**
> Inline-GeoJSON injection & SILENT layers → **API_REFERENCE.md § Silent/background layer**
> meta.name uniqueness → **API_REFERENCE.md § changeThemeStyle**
