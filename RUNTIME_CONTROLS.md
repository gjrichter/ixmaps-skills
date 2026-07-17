# Runtime Controls (Filters & Layer Toggles)

> Reference detail for **SKILL.md § Runtime Controls**. Patterns for interactive UI controls
> (checkboxes, dropdowns, clickable legends, URL sync) that modify the map after it's loaded.

Use these patterns when you need interactive UI controls (checkboxes, dropdowns) that modify the map after it's loaded.

## Filtering data across all layers — `changeThemeStyle`

`changeThemeStyle(themeName, styleString, mode)` modifies a live layer property and triggers a re-render. For aggregate layers (grid counts, sparklines) it also **re-aggregates** — cells recount correctly with only the filtered rows.

**Mode values:**

| Mode | Behaviour |
|------|-----------|
| `"set"` | Replace property with the given value (default) |
| `"remove"` | Delete the property entirely |
| `"factor"` | Multiply the current numeric value by the given factor (e.g. `"gridwidthpx:1.1"` → 10% larger) |
| `"set\|silent"` | Set value WITHOUT triggering a redraw (use for low-priority zoom tweaks) |

**Prerequisites:**
1. Every layer that should respond must have `name` in its `.meta()` (see Rule 21)
2. Must call via the **Promise API** — `myMap.then(map => ...)` — NOT the fluent chain

```javascript
function applyFilter(activeValues) {
  // activeValues = array of selected values, e.g. ["M", "F"]
  const szFilter = (activeValues.length === totalCount)
    ? null   // all selected → remove filter
    : 'WHERE fieldName in (' + activeValues.join(',') + ')';

  myMap.then(function(map) {
    ['layerNameA', 'layerNameB', 'layerNameC'].forEach(function(id) {
      if (szFilter) {
        map.changeThemeStyle(id, 'filter:' + szFilter, 'set');
      } else {
        map.changeThemeStyle(id, 'filter', 'remove');
      }
    });
  });
}
```

> ⚠️ `ixmaps.map().changeThemeStyle()` returns `{szMap: null}` and silently does nothing — that form cannot find the live map instance.

**Other common `changeThemeStyle` uses — opacity and grid size sliders:**

```javascript
// Opacity slider (fillopacity is 0–1, slider is 0–100)
opSlider.addEventListener('input', function () {
  myMap.then(function(api) {
    api.changeThemeStyle("layerName", "fillopacity:" + (+this.value / 100), "set");
  }.bind(this));
});

// Grid cell size slider (px value as plain number string)
gridSlider.addEventListener('input', function () {
  myMap.then(function(api) {
    api.changeThemeStyle("layerName", "gridwidthpx:" + this.value, "set");
  }.bind(this));
});
```

> ❌ Wrong (silently ignored): `api.changeThemeStyle("name", "fillopacity", "0.5")` — the second argument must be `"prop:value"`, not two separate arguments for property and value.

## Region selector with zoom navigation

Use a `<select>` dropdown to filter all theme layers to a single geographic region **and** pan/zoom to it. The map needs to be declared as `var myMap` (not `const`) in outer scope so both `buildMap()` and `changeRegion()` can access it.

**Key facts:**
- Filter uses single-value equality: `WHERE field = value`
- Empty `<option value="">` is the "show all" sentinel — triggers filter removal
- Navigation uses `myMap.view()` called **outside** `.then()` — it is safe to call on the fluent chain after init
- `myMap.view()` only pans/zooms; it does not reset layers

**REGION_VIEWS lookup table:**
```javascript
const REGION_VIEWS = {
    "":  { lat: 42.5, lng: 12.5, zoom: 6 },   // full extent
    "1": { lat: 44.9, lng:  7.9, zoom: 8 },
    // ... one entry per region code
};
```

**changeRegion function:**
```javascript
var myMap;   // outer scope — shared by buildMap() and changeRegion()

function changeRegion(code) {
    var THEME_NAMES = ["themeA", "themeB", "themeC"];  // all named themes that should filter
    var filterStr = code ? "WHERE regionField = " + code : null;
    var v = REGION_VIEWS[code] || REGION_VIEWS[""];

    myMap.then(function(m) {
        THEME_NAMES.forEach(function(name) {
            if (filterStr) {
                m.changeThemeStyle(name, "filter:" + filterStr, "set");
            } else {
                m.changeThemeStyle(name, "filter", "remove");
            }
        });
    });

    myMap.view({ center: { lat: v.lat, lng: v.lng }, zoom: v.zoom });
}

function buildMap() {
    myMap = ixmaps.Map("map", { ... });
    // ...layers...
}
```

**Overlay selector UI** — centered over the map, no background bar, map interaction passes through the wrapper:
```html
<!-- CSS -->
#region-bar {
    position: absolute;
    top: 20px; left: 50%; transform: translateX(-50%);
    z-index: 1001;
    display: flex; align-items: center; gap: 8px;
    pointer-events: none;        /* wrapper is click-through */
}
#region-bar label {
    color: #333; font-size: 0.78rem;
    pointer-events: none;
}
#region-select {
    background: rgba(20,20,20,0.72);
    border: 1px solid rgba(255,255,255,0.22);
    border-radius: 6px; color: #f0f0f0;
    padding: 5px 10px; cursor: pointer;
    pointer-events: all;         /* select itself is interactive */
}
#region-select option { background: #1e1e1e; color: #f0f0f0; }

<!-- HTML (inside the 1024px container div, above the map div) -->
<div id="region-bar">
    <label for="region-select">Regione:</label>
    <select id="region-select" onchange="changeRegion(this.value)">
        <option value="">— Tutta Italia —</option>
        <option value="1">Piemonte</option>
        <!-- ... -->
    </select>
</div>
```

> ⚠️ Always include `<option value="">` as the first option — it is the "show all" state that triggers `filter remove`. Presetting a region on load via `selected` means removing the initial `.filter()` from layer definitions; conversely, if a region is pre-filtered in `.filter()`, set `selected` on the matching option so the UI and the data stay in sync.

## Toggling layer visibility — `hideTheme` / `showTheme`

`hideTheme` and `showTheme` resolve themes by `name` in `.meta()` — just like `changeThemeStyle`. Once `name` is set on every layer, the standard calls work:

```javascript
ixmaps.hideTheme("grid");       // hides layer named "grid"
ixmaps.showTheme("grid");       // shows it again
// Usage: <input type="checkbox" onchange="this.checked ? ixmaps.showTheme('grid') : ixmaps.hideTheme('grid')">
```

**Initially hidden layer** — add `visible: false` to `.style()` — do NOT call `hideTheme` from `myMap.then()`:

```javascript
myMap.layer("danno")
  .binding({ ... })
  .type("CHART|BUBBLE|CATEGORICAL|GLOW")
  .style({
    colorscheme: [...],
    values:      [...],
    visible:     false    // ✅ layer starts hidden; toggle via showTheme/hideTheme at runtime
  })
  .define();
// ❌ WRONG: myMap.then(function() { ixmaps.hideTheme('danno'); });  — unreliable timing
```

**CSS injection fallback** — if `hideTheme` behaves unexpectedly for a layer type, inject/remove a style rule instead:

```javascript
function toggleLayer(id, show) {
  const styleId = 'hide-' + id;
  if (!show) {
    if (!document.getElementById(styleId)) {
      const s = document.createElement('style');
      s.id = styleId;
      s.textContent = '[id*=":' + id + ':"] { display: none !important; }';
      document.head.appendChild(s);
    }
  } else {
    document.getElementById(styleId)?.remove();
  }
}
```

The category filter and layer-visibility toggle work independently and can be freely combined.

## Isolating categorical classes — `markThemeClass` / `unmarkThemeClass`

Use these to isolate one or more categorical classes in a `CATEGORICAL` layer. Marked classes stay visible; all others are hidden. When zero classes are marked, every class is shown again — no reset call needed.

```javascript
// Mark (isolate) class at index n — index = position in the `values:` array (0-based)
ixmaps.markThemeClass("themeName", n);

// Remove the isolation for class n
ixmaps.unmarkThemeClass("themeName", n);
```

**Clickable legend pattern** — toggle isolation on click, track state in a `Set`:
```javascript
const markedClasses = new Set();

function toggleClass(classIdx) {
    if (markedClasses.has(classIdx)) {
        markedClasses.delete(classIdx);
        ixmaps.unmarkThemeClass("myLayer", classIdx);
    } else {
        markedClasses.add(classIdx);
        ixmaps.markThemeClass("myLayer", classIdx);
    }
    // update legend UI: dim items not in markedClasses (only when set is non-empty)
    document.querySelectorAll(".leg-item").forEach(el => {
        const c = parseInt(el.dataset.class, 10);
        el.classList.toggle("off", markedClasses.size > 0 && !markedClasses.has(c));
    });
}
// HTML: <div class="leg-item" data-class="0" onclick="toggleClass(0)">…</div>
```

> Multiple classes can be marked simultaneously — all marked classes show together. The `themeName` must match `name` in `.meta()` (same rule as `changeThemeStyle`).

## Highlighting a single item — `highlightThemeItems` / `clearHighlight`

Use this to draw a bold outline over one specific feature (e.g. a legend row hover highlighting
its region on the map, mirroring a Leaflet/MapLibre `feature-state` hover pattern). Undocumented
elsewhere in the ixMaps API surface — found by inspecting `htmlgui.js` directly.

```javascript
ixmaps.highlightThemeItems(themeName, itemId);   // draws the outline
ixmaps.clearHighlight();                         // removes it (global — clears any theme's highlight)
```

- `themeName` — the theme's `name` from `.meta()` (same rule as `changeThemeStyle` / `hideTheme`).
- `itemId` — **the full SVG group id, not the bare lookup/join value.** ixMaps renders each choropleth
  feature as an SVG group `id="<layerName>::<lookupValue>"` (e.g. a layer `myMap.layer("regions")`
  joined on code `"19"` renders as `id="regions::19"`). Passing just `"19"` silently does nothing —
  no error, the call just no-ops. Build the id as `layerName + "::" + code`.
- `clearHighlight()` takes no arguments and clears whatever is currently highlighted, regardless of
  theme — there is no per-theme clear.

**Legend-hover pattern:**
```javascript
document.querySelectorAll(".rank-row").forEach(function (row) {
  var itemId = "regions::" + row.dataset.code;   // "<layerName>::<code>"
  row.addEventListener("mouseenter", function () { ixmaps.highlightThemeItems("tfr-choropleth", itemId); });
  row.addEventListener("mouseleave", function () { ixmaps.clearHighlight(); });
});
```

## Reacting to zoom / pan — `.on()` events

Use `.on(events, handler)` to subscribe to view events. Multiple space-separated events are accepted in one call.

### View events

| Event | Fires when |
|-------|-----------|
| `zoomend` | Zoom level changed |
| `moveend` | Map panned without zoom change |
| `viewchange` (alias `zoompan`) | Any zoom or pan |

Handler receives `{ nZoom, zoomChanged, panChanged, szMap }`.

**Typical zoom-adaptive pattern** — debounce to avoid firing on every intermediate step:
```javascript
var _zoomTimer = null;
myMap.on("zoomend moveend", function() {
    clearTimeout(_zoomTimer);
    _zoomTimer = setTimeout(function() {
        var z = ixmaps.getZoom();   // global, no .then() needed
        myMap.then(function(m) {
            m.setBasemapOpacity(Math.max(0, Math.min(0.8, (z - 9) / 3)), "absolute");
            m.changeThemeStyle("layerName", "minvaluesize:" + (z > 10 ? 1 : 15), "set");
        });
    }, 400);
});
```

### Item (feature) events

| Event | Fires when | Handler receives |
|-------|-----------|-----------------|
| `mouseover` / `itemover` | Pointer enters a feature | `{ szId, id, theme, szMap }` |
| `mouseout` / `itemout` | Pointer leaves a feature | same |
| `click` / `itemclick` | Feature clicked | same |

`szId` = full compound id `"themeId::itemKey"` · `id` = item key only · `theme` = layer id

### Lifecycle events

| Event | Fires when |
|-------|-----------|
| `ready` / `mapready` | SVG engine fully loaded |
| `layerdraw` / `drawtheme` | A layer finishes drawing |
| `layeradd` / `newtheme` | A layer is created |
| `layerremove` / `removetheme` | A layer is removed |

```javascript
myMap
  .on("ready",     function()  { hideSpinner(); })
  .on("layerdraw", function(e) { console.log("drawn:", e.id); })
  .on("click",     function(e) { showDetail(e.id); })
  .on("mouseover", function(e) { highlight(e.id); })
  .on("mouseout",  function()  { clearHighlight(); });
```

**Inside handlers** — call `ixmaps.getZoom()` / `ixmaps.getCenter()` directly (no Promise); use `myMap.then(m => ...)` only when you need to call `m.changeThemeStyle()` or `m.setBasemapOpacity()`.

**`getBounds()` note** — returns a flat **4-element array** `[swLat, swLng, neLat, neLng]`, NOT a Leaflet `LatLngBounds` object. Always guard: `if (!bounds || bounds.length !== 4) return;`

**Legacy hook — `ixmaps.htmlgui_onZoomAndPan`** — still works; prefer `.on()` for new code:
```javascript
ixmaps.htmlgui_onZoomAndPan = function() {
  myMap.then(function(m) { updateLegend(m.getBounds()); });
};
```
When another handler already owns `htmlgui_onZoomAndPan`, wrap it to call `_prev` first instead of overwriting.

**Live legend pattern** — update sidebar counts from inline data on every pan/zoom:
```javascript
myMap.on("viewchange", function() {
  myMap.then(function(m) { updateLegend(m.getBounds()); });
});
// Also fire once on load:
myMap.then(function(m) { updateLegend(m.getBounds()); });

function updateLegend(bounds) {
  if (!bounds || bounds.length !== 4) return;
  const [swLat, swLng, neLat, neLng] = bounds;
  const counts = {};
  for (const t of DATA) {
    if (t.lat < swLat || t.lat > neLat || t.lon < swLng || t.lon > neLng) continue;
    counts[t.category] = (counts[t.category] || 0) + 1;
  }
  // update DOM legend elements with new counts
}
```

## Persisting the map view in the browser URL

Storing `lat`/`lng`/`zoom` in URL params lets users bookmark or share the exact view. Use `ixmaps.getCenter()` and `ixmaps.getZoom()` (global, no Promise needed) to read state, and `history.replaceState` to update silently.

**Important:** if another handler (e.g. a data provider) already owns `htmlgui_onZoomAndPan`, use a **wrapper** that calls `_prev` first — never overwrite blindly.

```javascript
/* ── 1. Read initial view from URL (before map init) ── */
var _urlParams = new URLSearchParams(window.location.search);
var _initLat   = parseFloat(_urlParams.get("lat"))  || 46.8;   // default fallback
var _initLng   = parseFloat(_urlParams.get("lng"))  || 2.3;
var _initZoom  = parseFloat(_urlParams.get("zoom")) || 6;

const myMap = ixmaps.Map("map", { ... })
    .view({ center: { lat: _initLat, lng: _initLng }, zoom: _initZoom })
    ...

/* ── 2. Write current view back to URL (debounced) ── */
var _urlUpdateTimer = null;

function updateUrlFromView() {
    try {
        var c = ixmaps.getCenter();
        var z = ixmaps.getZoom();
        if (!c || z == null) { return; }
        var params = new URLSearchParams(window.location.search);
        params.set("lat",  c.lat.toFixed(6));
        params.set("lng",  c.lng.toFixed(6));
        params.set("zoom", z.toFixed(4));
        history.replaceState(null, "", "?" + params.toString());
    } catch(e) {}
}

/* ── 3. Wrap the existing htmlgui_onZoomAndPan (don't replace it) ── */
function hookUrlUpdate() {
    var _prev = ixmaps.htmlgui_onZoomAndPan;   // save whatever is already there
    ixmaps.htmlgui_onZoomAndPan = function(nZoom) {
        try { if (_prev) { _prev.call(this, nZoom); } } catch(e) {}
        clearTimeout(_urlUpdateTimer);
        _urlUpdateTimer = setTimeout(updateUrlFromView, 400);
    };
}

/* ── 4. Install after map is ready; setTimeout fallback for edge cases ── */
myMap.then(function() { hookUrlUpdate(); updateUrlFromView(); });
setTimeout(function()  { hookUrlUpdate(); updateUrlFromView(); }, 1000);
```

> `ixmaps.getCenter()` / `ixmaps.getZoom()` are global — call them directly, no `myMap.then()` needed.
> Shareable URL format: `map.html?lat=48.856900&lng=2.347800&zoom=14.0000`
