# Facet Sidebar & Overlay Indicators

> Reference detail for **SKILL.md § Facet Sidebar** and **§ Overlay Indicator Layer**.
> Both rely on the `layerdraw` / `ixmaps.statistics` draw machinery, so they are documented together.

## Facet Sidebar (filter panel updated on zoom/pan)

A facet sidebar lets users filter the map by clicking category values or dragging range sliders. It auto-updates on every zoom, pan, and filter change. This pattern requires three CDN plugins:

```html
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/plugins/format.js"></script>
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/plugins/facet.js"></script>
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/plugins/show_facets.js"></script>
```

### Sidebar HTML structure

Use the canonical template below. The counter-chips pattern (`🌳 N totali` / `👁 N in vista`) gives users immediate feedback on dataset size and current view. Adapt the emoji and label text to the subject matter.

```html
<!-- Sidebar — place outside #map_div, position with CSS (right panel, overlay, etc.) -->
<div id="sidebar_div" style="
    position:absolute; top:0; right:0; width:320px; height:100%;
    display:flex; flex-direction:column;
    background:rgba(248,247,242,0.97); box-shadow:-2px 0 8px rgba(0,0,0,0.08);
    font-family:sans-serif; z-index:900;">

  <!-- Title block -->
  <div style="padding:1.2em 1.2em 0.6em">
    <div style="font-size:1.3em; font-weight:700">🌳 Map Title</div>
    <div style="font-size:0.85em; color:#888; margin-top:0.2em">Subtitle / data source line</div>
  </div>

  <!-- Counter chips: total + in-view -->
  <div style="padding:0 1.2em 0.8em; display:flex; gap:0.5em; flex-wrap:wrap; border-bottom:1px solid #e0dfd8">
    <span id="count-chip-total" style="
        background:#fff; border:1.5px solid #ccc; border-radius:2em;
        padding:0.3em 0.9em; font-size:0.9em; white-space:nowrap">
      🌳 <b id="count-total">—</b> totali
    </span>
    <span id="count-chip-visible" style="
        background:#fff; border:1.5px solid #ccc; border-radius:2em;
        padding:0.3em 0.9em; font-size:0.9em; white-space:nowrap">
      👁 <b id="count-visible">—</b> in vista
    </span>
  </div>

  <!-- Active-filter banner (hidden until a filter is applied) -->
  <div id="filter-div" style="display:none; padding:0.4em 1.2em; background:#fff3cd; font-size:0.82em">
    <b>Filtro attivo:</b> <span id="filter" style="font-style:italic"></span>
    <button onclick="clearFilter()" style="
        float:right; background:none; border:none; cursor:pointer;
        font-size:1em; color:#666">✕</button>
  </div>

  <!-- Data source credit -->
  <div style="padding:0.4em 1.2em; font-size:0.78em; color:#999; border-bottom:1px solid #e0dfd8">
    Dati: <a href="#" target="_blank" style="color:#888">Source Name</a> (CC-BY)
  </div>

  <!-- Scrollable facet area -->
  <div style="overflow-y:auto; flex:1; padding:0 0.4em">
    <div id="show-facets-div"></div>
  </div>
</div>
```

**Set the total count once** after data loads (not on every draw):
```javascript
document.getElementById("count-total").textContent = DATA.length;
```

### `ixmaps.statistics` — the facet engine hook

Override `ixmaps.statistics` to compute and render facets. It is called by ixmaps after every draw:

```javascript
ixmaps.statistics = function (szId) {
    var themeObj = ixmaps.getThemeObj(szId);
    if (!themeObj) return;

    var lastFilter = themeObj.szFilter || "";

    // Fields to facet — order determines sidebar order.
    // NONUMERIC flag: suppresses numeric range sliders for fields that
    // have many unique numbers but are better treated as categories.
    // Fields with >N unique values auto-render as text-search inputs.
    ixmaps.data.fShowFacetValues = false;
    var szFieldsA = [
        "CATEGORY_FIELD",   // categorical — picks up theme colors if it's the value field
        "HEIGHT_CLASS",     // ordinal text
        "STREET_NAME",      // high-cardinality → auto text-search input
        "YEAR"              // numeric range slider (omit NONUMERIC to allow)
    ];

    var facetsA = ixmaps.data.getFacets(
        lastFilter, "user_legend", szFieldsA, szId, "map", "NONUMERIC"
    );

    if (facetsA && facetsA.length) {
        ixmaps.data.showFacets(lastFilter, "show-facets-div", facetsA);
    }

    // update visible-count chip — use your inline DATA array, not theme.indexA
    myMap.then(function(m) {
        var bounds = m.getBounds();
        if (!bounds || bounds.length !== 4) return;
        var swLat = bounds[0], swLng = bounds[1], neLat = bounds[2], neLng = bounds[3];
        var vis = 0;
        DATA.forEach(function(d) {
            if (d.lat >= swLat && d.lat <= neLat && d.lon >= swLng && d.lon <= neLng) vis++;
        });
        var el = document.getElementById("count-visible");
        if (el) el.textContent = vis;
    });
};
```

### React to layer draw — `map.on("layerdraw")`

Use the event API (preferred over the legacy `htmlgui_onDrawTheme` hook):

```javascript
myMap.on("layerdraw", function(e) {
    var themeObj = ixmaps.getThemeObj(e.id);

    // skip helper/invisible layers
    if (!themeObj) return;
    if (themeObj.szFlag && themeObj.szFlag.match(/NOLEGEND/)) return;
    if (!themeObj.fVisible) return;

    ixmaps.statistics(e.id);

    // show/hide active-filter banner
    if (themeObj.szFilter) {
        document.getElementById("filter").innerHTML = themeObj.szFilter;
        document.getElementById("filter-div").style.display = "";
    } else {
        document.getElementById("filter-div").style.display = "none";
    }
});
```

> **Legacy hook `ixmaps.htmlgui_onDrawTheme`** — still works but is old-style. Prefer `map.on("layerdraw")` for new code. If an existing plugin already uses `htmlgui_onDrawTheme`, wrap it (`var _prev = ixmaps.htmlgui_onDrawTheme; ixmaps.htmlgui_onDrawTheme = function(szId){ ...; _prev && _prev(szId); }`) rather than overwriting.

### Clear all facet filters

```javascript
function clearFilter() {
    ixmaps.data.facetsFilterA = [];
    myMap.then(function(m) {
        m.changeThemeStyle("yourThemeName", "filter", "remove");
    });
}
```

### Facet button style overrides

`show_facets.js` generates `.btn-primary` buttons and `.badge` count labels. Override them to match your design:

```css
#show-facets-div .btn-primary {
    background-color: #fff;
    color: #334;
    border: none;
    border-bottom: solid rgba(128,128,128,0.25) 1px;
    border-radius: 0;
}
#show-facets-div .btn-primary:hover,
#show-facets-div .btn-primary:focus {
    background-color: #f0efe8;
    color: #112;
    outline: none; box-shadow: none;
}
#show-facets-div .badge {
    background: transparent;
    color: #778;
    font-size: 13px;
    font-weight: 400;
}
```

### `NONUMERIC` flag

Pass `"NONUMERIC"` as the last argument to `getFacets` to suppress range-slider facets for fields that happen to contain numbers but are really categories (e.g. year codes, ID numbers). Without this flag, any numeric field will render as a histogram + dual-handle slider.

### Category field gets theme colors automatically

If one of the facet fields matches the theme's `value` binding field, `show_facets.js` automatically colors each facet button with the corresponding theme color. No extra config needed — just include the field name.

### `theme.szFilter` vs `themeObj.szFilter`

`lastFilter = themeObj.szFilter || ""` — always read the filter from the theme object, not a local variable. The facet engine updates it internally; reading it fresh on each draw ensures facets reflect the current filter state.

---

## Overlay Indicator Layer (small dot on top of main bubble)

Use a second layer over the main bubbles to show a per-item status flag — e.g. failure risk class, alert state, certification level — without changing the primary color scheme.

### Pattern

1. **Add a constant `_dot` field** to source data so the size binding has a numeric value:
   ```javascript
   DATA.forEach(function(d) { d._dot = 50; });
   ```

2. **Filter to only the items worth showing** (e.g. only elevated/extreme risk, skip negligible):
   ```javascript
   var riskData = DATA.filter(function(d) {
       return d.RISK && d.RISK.match(/^(HIGH|EXTREME)/);
   });
   ```

3. **Define the overlay layer** using `CATEGORICAL|NOLEGEND` piped into the type string, `scale` for size, and `_dot` for the size binding:
   ```javascript
   var indicatorTheme = ixmaps.layer("risk_dots")
       .data({ obj: riskData, type: "json" })
       .binding({ geo: "lat|lon", value: "RISK", title: "NAME", size: "_dot" })
       .type("CHART|BUBBLE|CATEGORICAL|NOLEGEND")
       .style({
           colorscheme:    ["#ff9800", "#d32f2f"],
           values:         ["HIGH", "EXTREME"],
           normalsizevalue: "1000",   // same as main layer
           scale:           0.1,      // 10% of main bubble size → small indicator dot
           fillopacity:     1.0,
           linewidth:       0,
           showdata:        "true",
           align:           "bottom"  // anchor dot to bottom of main bubble
       })
       .meta({ name: "risk_dots_theme" })   // meta.name ≠ layer name "risk_dots"
       .title("Risk indicator")
       .define();

   myMap.layer(indicatorTheme, "direct");
   ```

   > **Define-then-add pattern:** `ixmaps.layer(...).define()` builds the theme **without**
   > putting it on the map and returns the theme object; `myMap.layer(themeObj, "direct")` then
   > adds it. `"direct"` (aliases `"fast"`/`"silent"`) makes the add fluent — no spinner, no
   > intermediate render. If a theme with the same `meta.name` is already on the map, this
   > replaces it. This is the off-map-define variant of the usual inline
   > `myMap.layer("name")....define()` chain.

### Key rules

| Rule | Why |
|------|-----|
| `NOLEGEND` **must be piped** into the type string: `"CHART|BUBBLE|CATEGORICAL|NOLEGEND"` | Passing it only in `.meta({ flag: "NOLEGEND" })` is not enough — it must appear in the type flags so the draw hook skips this layer when scanning for the statistics theme |
| Use `scale: 0.1` rather than a very large `normalsizevalue` | `scale` is a clean multiplier applied after size calculation; `normalsizevalue` only works cleanly when the size field has a known typical range |
| Keep `normalsizevalue` the same as the main layer | Makes the dot size proportional to the main bubble for the same item — a bigger tree gets a bigger dot |
| Add `_dot` constant **before** filtering | `DATA.forEach(d => d._dot = 50)` on the source array means every filtered subset inherits the field |
| Filter to only meaningful states | Empty dots for the "all-clear" state (A/negligible) add clutter without information |

### Skip the indicator layer in `layerdraw`

The draw handler must skip `NOLEGEND` layers to avoid running `ixmaps.statistics` on the indicator layer (which would show the risk categories as the main facets). The guard is already in the recommended pattern above:

```javascript
if (themeObj.szFlag && themeObj.szFlag.match(/NOLEGEND/)) return;
```
