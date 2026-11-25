# Example: World Bubble Map with a Live Equal Earth ⟷ Globe Toggle

This example demonstrates a full world-scale `CATEGORICAL` bubble map (size + color on one
layer), a native-legend capacity rollup via `|SUM` + `valuefield`, hover isolated to one layer
among several background layers via `|SILENT`, and — the genuinely new piece — a working
top-left toggle switch that live-swaps the map between Equal Earth and an Orthographic (3D
globe) projection, with the one broken direction (globe → flat) handled by a page reload instead
of fighting the engine.

## Use Case: Global Power Plant Database (WRI)

**Data source**: `https://raw.githubusercontent.com/wri/global-power-plant-database/master/output_database/global_power_plant_database.csv`
(~35,000 rows: `latitude`, `longitude`, `capacity_mw`, `primary_fuel`, `name`, `country_long`, …)

**Goal**: one bubble per plant, sized by `capacity_mw`, colored by `primary_fuel` with a
semantic dark-theme palette, a legend that shows *summed* capacity per fuel type (not facility
count), hover/tooltip only on the bubbles (not the land/ocean/graticule backdrop), and a toggle
to view the same data as a 3D globe.

---

## Complete Working Code

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Global Power Plants — Capacity &amp; Fuel Type</title>
<style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: #0a1420; }
    #map { width: 100%; height: 100%; }

    #projection-toggle {
        position: absolute;
        top: 12px; left: 12px;
        z-index: 1500;
        display: flex; align-items: center; gap: 8px;
        padding: 7px 12px;
        background: rgba(15, 23, 32, 0.88);
        border: 1px solid rgba(255,255,255,0.08);
        border-radius: 20px;
        font-family: "Helvetica Neue", Arial, sans-serif;
        font-size: 12px; color: #cfd8dc;
        user-select: none; cursor: pointer;
        box-shadow: 0 2px 10px rgba(0,0,0,0.3);
    }
    #projection-toggle .pt-label { opacity: 0.55; transition: opacity 0.15s; }
    #projection-toggle .pt-label.active { opacity: 1; color: #fff; font-weight: 600; }
    #projection-toggle .pt-track {
        position: relative; width: 34px; height: 18px;
        background: #37474f; border-radius: 9px; flex-shrink: 0;
    }
    #projection-toggle .pt-thumb {
        position: absolute; top: 2px; left: 2px; width: 14px; height: 14px;
        border-radius: 50%; background: #d7e600; transition: left 0.18s ease;
    }
    #projection-toggle .pt-track.on .pt-thumb { left: 18px; }
</style>
</head>
<body>

<div id="map"></div>

<div id="projection-toggle" title="Toggle Equal Earth / Globe view">
    <span class="pt-label active" id="pt-label-flat">Equal Earth</span>
    <span class="pt-track" id="pt-track"><span class="pt-thumb"></span></span>
    <span class="pt-label" id="pt-label-globe">Globe</span>
</div>

<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@1/ixmaps.js"></script>
<script>

var DATA_URL = "https://raw.githubusercontent.com/wri/global-power-plant-database/master/output_database/global_power_plant_database.csv";

// `values` and `colorscheme` are positional — index i of one maps to index i of the other.
var FUEL_VALUES = [
    "Solar", "Hydro", "Wind", "Gas", "Coal", "Oil", "Biomass", "Waste",
    "Nuclear", "Geothermal", "Storage", "Other", "Cogeneration", "Petcoke", "Wave and Tidal"
];
var FUEL_COLORS = [
    "#ffd600", "#29b6f6", "#26c6da", "#ff9800", "#8d8d8d", "#8d6e63", "#c0ca33", "#6d4c41",
    "#d7e600", "#ef5350", "#00e5ff", "#b0bec5", "#ff7043", "#4e342e", "#4dd0e1"
];

var STYLE = {
    ocean: "#0d1b2a", oceanLine: "#16293a", graticule: "#152838",
    landFill: "#1c2b36", landLine: "#2e4353"
};

// World bounding box: dense polygon (Equal Earth has no native Sphere geometry).
var _bboxPts = (function() {
    var n = 90, p = [];
    for (var i = 0; i <= n; i++) p.push([-180 + 360*i/n,  89.99]);
    for (var i = 1; i <= n; i++) p.push([ 179.99,  89.99 - 179.98*i/n]);
    for (var i = 1; i <= n; i++) p.push([ 180 - 360*i/n, -89.99]);
    for (var i = 1; i <  n; i++) p.push([-179.99, -89.99 + 179.98*i/n]);
    p.push(p[0]);
    return p;
})();
var worldBBox = { type: "FeatureCollection",
    features: [{ type: "Feature", geometry: { type: "Polygon", coordinates: [_bboxPts] }, properties: {} }] };

// Graticule every 30°.
var _graticuleLines = (function() {
    var lines = [], n = 90;
    for (var lon = -180; lon <= 180; lon += 30) {
        var pts = []; for (var i = 0; i <= n; i++) pts.push([lon, -90 + 180*i/n]); lines.push(pts);
    }
    for (var lat = -90; lat <= 90; lat += 30) {
        var pts = []; for (var i = 0; i <= n; i++) pts.push([-180 + 360*i/n, lat]); lines.push(pts);
    }
    return lines;
})();
var graticuleGeoJSON = { type: "FeatureCollection",
    features: [{ type: "Feature", geometry: { type: "MultiLineString", coordinates: _graticuleLines }, properties: {} }] };

// Orthographic-only ocean backdrop — {type:"Sphere"} is a no-op under any other projection.
var oceanSphereGeoJSON = { type: "FeatureCollection",
    features: [{ type: "Feature", geometry: { type: "Sphere" }, properties: {} }] };

var myMap = ixmaps.Map("map", {
    mapType: "#0a1420", mapProjection: "equalearth", mode: "info", legend: "open", tools: false
})
.view({ center: { lat: 0, lng: 0 }, zoom: 1.5 })
.options({ objectscaling: "dynamic", normalSizeScale: "150000000", basemapopacity: 0, flushChartDraw: 1000000 });

// Ocean, graticule, land — all |SILENT so only the bubble layer highlights/tooltips on hover.
myMap.layer("bbox")
    .data({ obj: worldBBox, type: "geojson" })
    .binding({ geo: "geometry" })
    .type("FEATURE|SILENT")
    .style({ colorscheme: [STYLE.ocean], fillopacity: 1.0, linecolor: STYLE.oceanLine, linewidth: 0.8, showdata: "true" })
    .meta({ name: "ocean_flat", tooltip: "" })
    .define();

myMap.layer("graticule")
    .data({ obj: graticuleGeoJSON, type: "geojson" })
    .binding({ geo: "geometry" })
    .type("FEATURE|SILENT")
    .style({ colorscheme: [STYLE.graticule], linecolor: STYLE.graticule, linewidth: 0.4, showdata: "true" })
    .meta({ tooltip: "" })
    .define();

myMap.layer("world")
    .data({ url: "https://gisco-services.ec.europa.eu/distribution/v2/countries/topojson/CNTR_RG_60M_2020_4326.json", type: "topojson" })
    .binding({ geo: "geometry" })
    .type("FEATURE|SILENT")
    .style({ colorscheme: [STYLE.landFill], fillopacity: 0.9, linecolor: STYLE.landLine, linewidth: 0.5, showdata: "true" })
    .meta({ tooltip: "" })
    .define();

// Size = capacity_mw (binding.size), color = primary_fuel (binding.value, CATEGORICAL).
// |SUM + style.valuefield make the legend show SUMMED capacity per class, not facility count.
myMap.layer("power_plants")
    .data({ url: DATA_URL, type: "csv" })
    .binding({ geo: "latitude|longitude", value: "primary_fuel", title: "name", size: "capacity_mw" })
    .type("CHART|BUBBLE|CATEGORICAL|SUM")
    .style({
        colorscheme: FUEL_COLORS, values: FUEL_VALUES,
        valuefield: "capacity_mw", valuedecimals: 0,
        normalsizevalue: "3000", sizepow: 2, scale: 0.15,
        fillopacity: 0.75, linecolor: "#000000", linewidth: 0.15,
        showdata: "true", units: " MW"
    })
    .meta({
        name: "power_plants",
        tooltip: "<div style='padding:6px;min-width:190px'>" +
                 "<b style='font-size:13px'>{{name}}</b><br>{{country_long}}<br>" +
                 "Fuel: <b>{{primary_fuel}}</b><br>Capacity: <b>{{capacity_mw}}</b> MW</div>",
        snippet: "Bubble size = capacity (MW) · color = primary fuel type",
        description: "Global Power Plant Database — " +
                      "<div style='margin-top:0.6em;padding-top:0.5em;border-top:1px solid #444;font-size:0.8em;color:#999'>" +
                      "Source: World Resources Institute, Global Power Plant Database</div>"
    })
    .title("Global Power Plants")
    .define();

// mode:"info" alone does not arm hover tooltips on this engine (SKILL.md Hotspot #26) —
// tools:false here means there's no toolbar PAN/INFO toggle to fall back on either, so
// without this call tooltips would be dead on first paint with no error at all.
myMap.then(function () {
    try { ixmaps.setMapTool("info"); } catch (e) {}
});

// ── Projection toggle ────────────────────────────────────────────────────
var isGlobeView = false;

function setToggleUI(isGlobe) {
    document.getElementById("pt-track").classList.toggle("on", isGlobe);
    document.getElementById("pt-label-flat").classList.toggle("active", !isGlobe);
    document.getElementById("pt-label-globe").classList.toggle("active", isGlobe);
}

function switchToGlobe() {
    isGlobeView = true;
    setToggleUI(true);

    var project = JSON.parse(ixmaps.getProjectString());
    project.map.map    = ixmaps.szResourceBase + "maps/svg/maps/generic/orthographic.svg";
    project.map.center = { lat: 15, lng: 10 };
    project.map.zoom   = 2.2;
    ixmaps.setProjectJSON(project);
    // Deliberately NOT followed by myMap.view(...) — see the note below.

    myMap.then(function(api) {
        try { api.removeTheme("ocean_flat"); } catch (e) {}
        myMap.layer("ocean_globe", "direct")
            .data({ obj: oceanSphereGeoJSON, type: "geojson" })
            .binding({ geo: "geometry" })
            .type("FEATURE|SILENT")
            .style({ colorscheme: [STYLE.ocean], fillopacity: 1.0, linecolor: STYLE.oceanLine, linewidth: 0.8, showdata: "true" })
            .meta({ name: "ocean_globe", tooltip: "" })
            .define();
    });

    // setProjectJSON's redraw resets the map's tool state again (Hotspot #33), which would
    // silently kill hover tooltips a second time even though setMapTool("info") already ran
    // once at init above. A synchronous re-arm right here is a no-op — the async redraw
    // overwrites it moments later — so delay until the redraw has settled.
    setTimeout(function () { try { ixmaps.setMapTool("info"); } catch (e) {} }, 400);
}

function switchToFlat() {
    // Live globe -> Equal Earth is unreliable in this engine (stuck SVG
    // transform) — reload into the default Equal Earth init instead.
    location.reload();
}

document.getElementById("projection-toggle").addEventListener("click", function () {
    if (isGlobeView) { switchToFlat(); } else { switchToGlobe(); }
});

</script>
</body>
</html>
```

---

## Key Architecture Points

### 1. Categorical color + numeric size on one `BUBBLE` layer

```javascript
.binding({ geo: "latitude|longitude", value: "primary_fuel", title: "name", size: "capacity_mw" })
.type("CHART|BUBBLE|CATEGORICAL|SUM")
```

`binding.value` drives **color** (must be the category field, here `primary_fuel`).
`binding.size` drives **radius** independently (here `capacity_mw`). This is the only working
way to get category color + numeric size on one `BUBBLE` layer — `style.colorfield` looks like
the natural fit but is silently broken for `BUBBLE` (see SKILL.md Hotspot #22).

### 2. `|SUM` + `valuefield` — legend shows summed value, not facility count

Without `style.valuefield`, a `CATEGORICAL` bubble legend shows each class's item **count**
(or a placeholder class index) because `binding.value` is spent driving color, leaving nothing
else to aggregate. Setting `style.valuefield` to the **same field as `binding.size`**, plus
`|SUM` in the type string, makes the legend show the **sum** of that field per class instead:

```javascript
.type("CHART|BUBBLE|CATEGORICAL|SUM")
.style({ valuefield: "capacity_mw", valuedecimals: 0, /* ... */ })
```

Verified against the raw CSV: legend rows read Coal ≈1,964,838 MW, Gas ≈1,492,544 MW, Hydro
≈1,051,692 MW, etc. — matching an independent `sum(capacity_mw)` per `primary_fuel` computed
directly from the source data, not facility counts (which would read ~2,330 for Coal, ~3,998
for Gas — the count values, wrong for this use case).

### 3. `objectscaling: "dynamic"` is safe here because a real size binding exists

```javascript
.options({ objectscaling: "dynamic", normalSizeScale: "150000000", /* ... */ })
```

SKILL.md Hotspot #24 warns that `objectscaling: "dynamic"` on a `CATEGORICAL` bubble theme with
**no** `binding.size` (every bubble meant to be the same fixed size) can silently collapse some
classes to zero size. This map has a real `binding.size` (`capacity_mw`) driving radius, so
dynamic scaling works correctly — confirmed rendering identically with and without it at the
initial view, and growing/shrinking bubbles appropriately on zoom.

### 4. `|SILENT` isolates hover to exactly one layer

Three background layers (ocean bounding box, graticule, land) all get `FEATURE|SILENT` — this
suppresses their tooltip *and* hover highlight, so only the `power_plants` bubble layer (plain
`CHART|BUBBLE|...`, no `|SILENT`) reacts to the mouse. Verified by dispatching real `mouseover`
events: a land `<path>`'s `fill` and the `#tooltip` element were both unchanged on hover, while
a bubble `<circle>` correctly populated `#tooltip` and highlighted.

### 5. Live projection toggle — the real API, and a build-dependent gotcha

`mapProjection` in `ixmaps.Map()` is construction-time only. The runtime way to change
projection on an already-initialized map is `ixmaps.getProjectString()` /
`ixmaps.setProjectJSON()` — the same mechanism the engine's own
`pages/bugs/ixmap_interactive_legend.html` reference demo uses. See SKILL.md § "Switching
projection at runtime" for the full mechanism and the separately-documented broken direction
(globe → flat gets a stuck SVG transform with no live fix — reload instead, as `switchToFlat()`
does above).

**⚠️ The one thing this example corrects**: SKILL.md's own documented pattern (`myMap.view({...})`
right after `setProjectJSON`) was found on *this* engine build to **silently revert the whole
swap** — confirmed via `JSON.parse(ixmaps.getProjectString()).map.map` reading back the
*previous* projection immediately after calling `.view()`. Dropping that trailing `.view()`
call and relying only on `project.map.center`/`.zoom` (set inside the JSON passed to
`setProjectJSON`) worked reliably across many fresh loads and real clicks. Whether `.view()` is
needed appears to be build-dependent — **try without it first**, and confirm the swap actually
stuck via a `getProjectString()` readback (not just a screenshot — see Related below) before
deciding you need it back.

### 6. Ocean backdrop must be swapped per projection

The dense-polygon ocean (needed because Equal Earth has no native `Sphere` support) does not
reproject correctly onto the globe. On switching to globe, it's removed by `meta.name`
(`"ocean_flat"`) and replaced with a `FEATURE|SILENT` layer using native `{type:"Sphere"}`
geometry (Orthographic-only) inside `myMap.then(...)`, since `removeTheme` lives on the
embedded Api, not the top-level `myMap` builder.

### 7. Re-arm hover tooltips after every projection switch, not just once at init

`setMapTool("info")` at init (SKILL.md Hotspot #26) only survives until the *first* call to
`setProjectJSON` — the theme redraw that switch triggers resets `map.szMapToolType` back to
`""` again, so tooltips silently go dead on the very first toggle click even on a map that
worked correctly on load (SKILL.md Hotspot #33). Confirmed the obvious fix doesn't stick:
`setMapTool("info")` called synchronously right after `setProjectJSON()` is a no-op, because
the async redraw overwrites it again moments later; the identical call from the console *after*
the swap visibly finishes works immediately. Fix is the `setTimeout(..., 400)` re-arm inside
`switchToGlobe()` above — needed on **every** runtime projection switch, in addition to (not
instead of) the one-time init call.

---

## Common Mistakes to Avoid

### ❌ Mistake 1: `colorfield` for category color on a BUBBLE theme
```javascript
// Renders every bubble in ONE color — colorfield is silently ignored on BUBBLE.
.style({ colorfield: "primary_fuel", /* ... */ })
```
Use `binding.value` for the category instead (see Key Point 1).

### ❌ Mistake 2: expecting `|SUM` alone to fix the legend
```javascript
// |SUM alone still shows the wrong number without valuefield.
.type("CHART|BUBBLE|CATEGORICAL|SUM")
.style({ /* no valuefield */ })
```
`|SUM` needs `style.valuefield` pointing at the numeric field to sum — without it there's
nothing for `|SUM` to aggregate but the color-class placeholder.

### ❌ Mistake 3: `myMap.view(...)` reflexively after every `setProjectJSON`
```javascript
ixmaps.setProjectJSON(project);
myMap.view({ center: project.map.center, zoom: project.map.zoom });  // may undo the swap!
```
Test without it first (see Key Point 5).

### ❌ Mistake 4: re-projecting the ocean layer instead of swapping it
```javascript
// The dense polygon does NOT reproject correctly onto Orthographic — leave it in place
// and it renders as a degenerate sliver, not a disc.
```
Remove it by `meta.name` and define a fresh `{type:"Sphere"}` layer instead.

### ❌ Mistake 5: trying to live-swap globe → flat
```javascript
// Confirmed broken on every attempt: second .view(), myMap.then(api => api.view(...)),
// repeat setProjectJSON, even a real zoom-button click — none un-stick the transform.
```
Reload the page for that direction; it cleanly resets to the default Equal Earth init.

### ❌ Mistake 6: assuming one `setMapTool("info")` at init survives a projection switch
```javascript
// Tooltips work on load, then silently die after the FIRST toggle click —
// setProjectJSON's redraw resets szMapToolType back to "" again.
```
Re-arm with a delayed `setMapTool("info")` after every `setProjectJSON` call too, not just once
at init — see Key Point 7.

---

## Testing Checklist

- [ ] Legend shows 15 fuel categories with distinct, semantically-chosen colors
- [ ] Legend values are **summed capacity** per class (cross-check a couple against the raw CSV), not facility counts
- [ ] Bubble radius visibly varies with `capacity_mw` (spot-check the largest known plant, e.g. Three Gorges Dam ≈22,500 MW, renders as one of the largest bubbles)
- [ ] Hovering a bubble shows its tooltip and highlight; hovering land/ocean/graticule does neither
- [ ] Clicking the toggle switches live to the globe view (verify `JSON.parse(ixmaps.getProjectString()).map.map` ends in `orthographic.svg`, not just a screenshot)
- [ ] **After** switching to the globe, hover a bubble again and confirm the tooltip still appears — `setProjectJSON` resets the tool state a second time (Hotspot #33), so this must be checked separately from the pre-toggle hover check
- [ ] Clicking the toggle again reloads back to the default Equal Earth view
- [ ] Tested in a real browser at a reasonably wide viewport, not only a headless/embedded preview pane — see Related below

## Related Examples / References

- SKILL.md § "Switching projection at runtime" — full mechanism, the stuck-transform bug, `.view()` build-dependence, the `setMapTool` re-arm
- SKILL.md Hotspot #22 (`colorfield` broken on BUBBLE), #24 (`objectscaling:"dynamic"` needs a real size binding), #10/Rule 16a (`|SILENT` and tooltip suppression), #26 (`mode:"info"` doesn't arm tooltips, needs `setMapTool("info")`), #33 (`setProjectJSON` resets tool state again)
- SKILL.md § "Special Patterns" → "CATEGORICAL + bubble size from a numeric field"
- A Browser-preview-pane screenshot showing a shrunk-to-corner map after a zoom/view change, or a blank canvas for certain projections, can be a **preview-tool-only artifact** rather than a real bug — always cross-check with a DOM/API-level readback (`getProjectString()`, `getZoom()`, element counts) before concluding the map itself is broken, and confirm in a real, non-embedded browser if in doubt.
