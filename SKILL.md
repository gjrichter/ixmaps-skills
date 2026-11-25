---
name: create-ixmap
description: Creates interactive maps using ixMaps framework. Use when the user wants to create a map, visualize geographic data, or display data with bubble charts, choropleth maps, pie charts, or bar charts on a map.
argument-hint: "[filename] [options]"
allowed-tools: Write, Read, AskUserQuestion, Bash
---

# Create ixMap Skill

Creates complete HTML files with interactive ixMaps visualizations for geographic data.

## 📐 Two Modes: Authoring vs. Reading

This skill is used both to **write new maps** and to **read, adapt, explain, or review existing
ones**. The rules below are written for authoring. Applying them as pass/fail checks against
existing code produces false failures, because ixMaps accepts several equivalent forms and this
skill deliberately teaches only one of each.

| Mode | What the rules mean |
|---|---|
| **Authoring** (writing a new map, or new code in an existing one) | Follow the canonical form. Where two forms both work, the canonical one is chosen to make a silent error unrepresentable. |
| **Reading / adapting / reviewing** (learning from a map, porting one, changing part of one) | The canonical form is **not** a correctness criterion. Accepted variants are correct code — do not rewrite them, and do not report them as defects. Match the surrounding file's existing style when adding to it. |

**Three categories — only the third is a defect:**

| Category | In existing code | Examples |
|---|---|---|
| **Accepted variant** — works, equivalent | ✅ Leave it. Not a bug, not a style violation to "fix" unasked. | `.view([lat,lng], zoom)` vs `.view({center,zoom})` · `gridwidth:"5px"` vs `gridwidthpx:"5"` · `colorscheme:"#hex"` vs `["#hex"]` · global `ixmaps.layer(…).define()` + attach vs inline `myMap.layer(…).define()` |
| **Deprecated** — works, discouraged | ⚠️ Mention if relevant; replace only when asked or when already editing that line. | `\|EXACT` → `CATEGORICAL` · `Data.broker()` / `new Data.Broker()` → `Data.provider()` |
| **Actually broken** — silently fails | ❌ Flag and fix. Renders nothing, or does the opposite of what's intended. | missing `showdata:"true"` · `fillopacity:0` (coerced to `1`) · `.tooltip()`, `fillcolor`, `strokecolor` (don't exist) · `CHART\|GRID\|AGGREGATE` (doesn't exist) · single quotes in `.filter()` · `ixmaps.showLayer/hideLayer` (don't exist) · a global `ixmaps.layer(…).define()` whose result is **never** attached anywhere |

> Not variants at all: `fillopacity` and `opacity` are **different properties** (fill only vs.
> fill + stroke), as are `linecolor` (geometry outline) and `bordercolor` (chart background box).
> Seeing the less common one is not evidence of a mistake — check what's being styled.

**When examining a map, judge against "does this work?", not "is this how I'd write it?"**

---

## ✅ The Render Contract (the one guarantee this skill must keep)

**Every map generated from scratch must actually render — data visible on screen, not a blank
map.** This is the skill's single hard guarantee. Style preferences are negotiable; this is not.

ixMaps fails **silently**: a map missing any item below loads without a single console error,
reports the theme as done, and can even populate the legend with a correct value range — while
drawing nothing. So "no errors" is **not** evidence of success. Only seeing rendered elements is.

Stages a map must clear, in order. If output is blank, the first failing stage tells you where:

| Stage | Must be true | If false |
|---|---|---|
| **1. Page** | ixmaps CDN `<script>` present; `#map` div exists with a non-zero **height** (`height:100vh` or fixed px); no reserved ids (`loading-div`, `tooltip`, `contextmenu`) reused | Blank page / zero-height map |
| **2. Init** | `ixmaps.Map("map", …)` result captured — `var myMap = …`, never named `map`; first arg matches the div id | Partial init; later calls no-op |
| **3. Data** | `.data()` resolves: inline `obj:` **or** a CORS-reachable `url:` (never `file://`); `type:` matches the payload | No rows; nothing to draw |
| **4. Layer** | `.binding()` present with `geo` (data-driven layers also need `value`); chain closed by `.define()`; theme **attached** — inline `myMap.layer(…)`, or global `ixmaps.layer(…).define()` whose result is passed to `myMap.layer(theme)` | Layer skipped or orphaned — legend may still look right |
| **5. Draw** | `showdata: "true"` in every data-driven `.style()`; viztype matches data shape (`CHART\|…` for points, `FEATURE\|…` for geometry); `normalSizeScale` set whenever `objectscaling:"dynamic"`; a join overlay's layer name **exactly** equals its FEATURE base's | Invisible, or oversized/undersized to nothing |
| **6. Visible** | `.view()` centred over the data at a sensible zoom; lat/lng not transposed; fill not accidentally hidden (`fillopacity:0` silently becomes `1`; use `colorscheme:["none"]` to hide deliberately); no `chartupper`/`chartlower` gate excluding the current zoom; `values:` entries are strings | Renders off-screen or clipped away |

**Gate:** do not report a map as done until stage 6 is satisfied *and* verified — see Workflow
step 6. If verification isn't possible in the current environment, say the map is unverified
rather than implying it works.

## ⚠️ CRITICAL RULES (Never Skip)

> These are **authoring** rules — see § Two Modes above before applying them to existing code.

1. `ixmaps.Map()` returns a **MapBuilder** — use `.then()` to capture the real map instance

   Simple setup chains work without `.then()` via an internal queue mechanism:
   ```javascript
   // ✅ works for initial setup chain
   ixmaps.Map("map", { ... })
       .view({ ... })
       .options({ ... })
       .layer(theme);
   ```
   But `.then()` is **required** whenever you need the real map instance later —
   in event handlers, dynamic updates, or calls that live on the Api rather than the
   chainable builder (`removeTheme`, `changeThemeStyle` etc.). Note `hideTheme` /
   `showTheme` / `getZoom` / `getCenter` are **global** `ixmaps.*` calls and need no
   `.then()` — see § Runtime Controls:
   ```javascript
   // ✅ always safe — prefer this pattern
   ixmaps.Map("map", { ... }).then(function(map) {
       map.view({ ... }).options({ ... }).layer(theme);
       button.onclick = function() { map.layer(newTheme); }; // real map instance available
   });

   // ⚠️ works for initial setup only — breaks if myMap is used later in event handlers
   const myMap = ixmaps.Map("map", { ... });
   myMap.view(...).layer(...);       // fine here — queued and executed on init
   myMap.layer(newTheme);            // risky if called from an event handler or timeout
   ```
1a. **The global `ixmaps.layer(name)....define()` form only BUILDS a theme — it does NOT put it on any map.** There are exactly two safe ways to end a layer definition; never leave it in neither:
    - **Inline (default — use this unless you have a specific reason not to):** call `.layer("name")` directly on the captured map instance/builder, e.g. `myMap.layer("name").data(...).binding(...).type(...).style(...).meta(...).title(...).define();` — this builds **and** attaches in one step.
    - **Define-then-add (only for a deliberate reason — reusable theme object, or a multi-theme map where layers are loaded/swapped on demand):** `var theme = ixmaps.layer("name")....define();` **followed by** `myMap.layer(theme)` or `myMap.layer(theme, "direct")` (`"direct"` skips the loading spinner). The second call is what actually attaches it — skipping it is the mistake.
    - ❌ **Broken, no error — in a finished program:** `ixmaps.layer("name")....define();` where the return value is discarded and *never* passed to `myMap.layer(...)` anywhere. Data loads, the theme registers, the legend can even populate with a correct value range — but zero elements ever render (`document.querySelector('#map svg').querySelectorAll('circle').length` stays `0`). When copying a standalone `ixmaps.layer(...).define();` into real code, make sure you also add where its result gets attached.
      > ⚠️ The bug is the **missing attachment**, not the global form. A doc fragment or excerpt showing only `ixmaps.layer(...).define()` is the accepted define-then-add variant with the attach call outside the excerpt — see § Two Modes. Flag it only when you can see the whole program and the theme is never attached.
    - **Only use the global/define-then-add form when explicitly asked for a swappable/dynamic multi-theme setup** (sidebar picker, time slider, KDE recompute-on-slider — see § Multi-Layer Join Pattern · B). For a normal single always-visible layer, always use the inline form on the captured instance.
2. **ALWAYS include `.binding()`**, with `geo` **and** `value` on any data-driven layer (CHART/CHOROPLETH). Exception: a `FEATURE` base that carries only geometry omits `value` (use `id` there instead, for the join) — see API_REFERENCE.md § `value` field on FEATURE layers
3. **ALWAYS include `showdata: "true"`** in `.style()`
4. **ALWAYS include `.meta()`** with tooltip (default: `{ tooltip: "{{theme.item.chart}}{{theme.item.data}}" }`)
   - **Also include `name`** whenever you plan to use `changeThemeStyle` at runtime (see rule 21)
5. **NEVER use `.tooltip()`** — doesn't exist
6. **NEVER combine `CHART` and `CHOROPLETH`** in one type string — mutually exclusive
7. **NEVER use `|EXACT` classification** — deprecated; use `CATEGORICAL`
8. **NEVER use `map` as variable name** — conflicts with internals; use `myMap`
8a. **NEVER use reserved HTML element IDs** — ixMaps owns `loading-div`, `tooltip`, `contextmenu`. Using them causes visible artifacts (a white box stuck on the map). Use `app-loading` or any other non-conflicting name for your own overlays.
9. **Use `fillopacity`, not `opacity`, to control transparency** in `.style()` — `fillopacity` fades only the fill; `opacity` fades the whole SVG element (fill *and* stroke/border). `fillopacity` is what most map styling calls for
10. **NEVER use `fillcolor`** — use `colorscheme: ["#hex"]`
11. **NEVER add `.legend("string")`** unless user explicitly requests it — destroys the default color legend. For a map title, use `.title("...")` on the layer instead; for subtitle/description text, use `meta.snippet`/`meta.description` — see § Map title, subtitle & description
12. **ALWAYS use CDN** `https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@1/ixmaps.js`
    - **Default engine is ixmaps-flat.** Use ixmaps-gl only per § Choosing the Engine (flat | gl) below. Never mix both scripts on one page.
    - **data.js** (`https://cdn.jsdelivr.net/gh/gjrichter/data.js@master/data.js`) is **already loaded by ixmaps** — `Data.*` functions are available inside `query:` and `process:` callbacks without any extra `<script>` tag
    - **Only include the data.js CDN explicitly** when you need `Data.*` functions *outside* ixmaps theme realization (e.g. pre-processing data in your own `<script>` block before defining layers)
13. **NEVER use info from** `ixmaps.ca` or `ixmaps.com` — only `github.com/gjrichter/ixmaps-flat` (and `github.com/gjrichter/ixmaps-gl` for the gl engine)
14. **ONE `.data()` per layer** — never chain two `.data()` calls on the same layer
15. **🔑 SAME LAYER NAME = GEOMETRY REUSE** — see § Geometry Reuse Pre-flight Checklist below for the authoritative rules. Quick example:

    ```javascript
    // ✅ Both named "regions" → overlay binds onto regions' geometry
    myMap.layer("regions").data({url:geo}).type("FEATURE").define();
    myMap.layer("regions").data({url:csv}).binding({lookup:"code",value:"pct"})
                          .type("CHOROPLETH|QUANTILE").define();

    // ❌ Different names → overlay has nothing to draw on, silently broken
    myMap.layer("stats").type("CHOROPLETH").define();
    ```

    For runtime theme swapping (sidebar picker, time slider) → see § Multi-Layer Join Pattern · B. Swappable themes for the full `setTheme` / `removeTheme` pattern.

16. **NO `FEATURE` on overlay layers** — base layer gets `FEATURE`; choropleth/chart overlays do not:
    - ✅ `myMap.layer("x").type("FEATURE")` → `myMap.layer("x").type("CHOROPLETH|CATEGORICAL")`
    - ❌ `myMap.layer("x").type("FEATURE")` → `myMap.layer("x").type("FEATURE|CHOROPLETH|CATEGORICAL")`
16a. **`|SILENT` on a `FEATURE` base kills tooltips for every overlay reusing its geometry** — `SILENT` suppresses tooltips/legend/statistics for the theme it's attached to, but a CHOROPLETH/CHART overlay on the same layer name has no hover of its own; it relies on the base. Default to plain `FEATURE` (no `|SILENT`) whenever the overlay needs hover tooltips — which is the common case. Only add `|SILENT` to a base if you deliberately want the whole join (base + overlay) to have no tooltip at all (e.g. a decorative graticule with no overlay). See Silent Failure Hotspot #10.
17. **`objectscaling: "dynamic"` requires `normalSizeScale`** — set to map scale denominator:
    zoom 4→30M · 5→15M · 6→8M · 8→2M · 10→500k · 12→100k
18. **`lookup` goes in `.binding()`**, not in `.data()`
19. **`values:` for CATEGORICAL must be strings** — ixMaps bug: numeric values silently ignored
20. **To make a fill invisible** use `colorscheme: ["none"]` — NOT `fillopacity: 0`. ⚠️ ixMaps bug: `fillopacity: 0` is silently coerced to `1` (fully opaque), so it does the **opposite** of hiding the fill
21. **FEATURE layer styling depends on geometry type:**
    - **Line features** — `colorscheme` sets the line/stroke color; `linecolor` is overridden by `colorscheme` and has no effect. Use `colorscheme: ["none"]` to make lines invisible. Color classes (multi-value array) apply as line-color classes. Data-driven colorization (CHOROPLETH|QUANTILE, CHOROPLETH|CATEGORICAL, etc.) works symmetrically with polygon features — `colorscheme` drives stroke color instead of fill.
    - **Polygon features** — `colorscheme` sets the **fill color** (single value or array for color classes); `linecolor` sets the **border/outline color** of the polygon. `fillopacity` controls fill transparency; `linewidth` controls border thickness.
22. **`changeThemeStyle` requires `name` in `.meta()`** — it finds themes by `name`, NOT by the string in `myMap.layer("name")`. Without `name`, calls silently have no effect:
    ```javascript
    .meta({ name: "punti", tooltip: "..." })   // ✅ — changeThemeStyle("punti", ...) will work
    .meta({ tooltip: "..." })                   // ❌ — theme is invisible to changeThemeStyle
    ```
23. **`hideTheme`/`showTheme` also resolve themes by `name` in `.meta()`** — same rule as `changeThemeStyle`. Once `name` is set, use `ixmaps.hideTheme(name)` / `ixmaps.showTheme(name)` for layer visibility. CSS injection (`[id*=":name:"] { display: none !important }`) remains a reliable fallback if `hideTheme` behaves unexpectedly for a given layer type.
24. **NEVER use the same string for a layer name and a `meta.name`** — reusing one string for both has caused failures. They are different identifiers:
    - **Layer name** (`myMap.layer("comuni")`) = geometry bucket; shared by a FEATURE base and the overlays that reuse its geometry, and **not unique**. A standalone CHART layer with its own geo data can use any arbitrary name (even `"generic"`).
    - **`meta.name`** = the **unique** theme id used by `changeThemeStyle` / `hideTheme` / `showTheme` / `removeTheme`.
    Keep them distinct — e.g. layer `"comuni"` + `meta.name: "comuni-choropleth"`.
25. **ALWAYS write `.view()` in the object form** — `.view({ center: { lat: L, lng: G }, zoom: Z })`. A positional array form `.view([lat, lng], zoom)` also works and appears in some older code, but never emit it: its order is `[lat, lng]`, the **opposite** of GeoJSON's `[lng, lat]`, so a transposed pair silently centres the map somewhere else with no error. Named keys make that mistake unrepresentable.

---

## 🔴 Silent Failure Hotspots

These produce **no error, no warning, no console message** — the map just silently renders wrong. Check these first when something looks broken.

| # | What you did | What happens | Fix |
|---|---|---|---|
| 1 | Omitted `showdata: "true"` | Layer loads, data processes, nothing renders — completely invisible | Add `showdata: "true"` to every `.style()` |
| 1a | Omitted `showdata: "true"` on an AGGREGATE layer that already has a `datafields` + `tooltip: "{{theme.item.data}}"` | The chart itself (`{{theme.item.chart}}`) still draws fine — bubbles/squares appear normally, so it doesn't look broken. Only the `{{theme.item.data}}` listing is silently empty | `showdata` gates the whole data-display phase, not just initial rendering — required even when the chart is already visibly working |
| 2 | Used different layer name for overlay vs FEATURE base | Overlay renders nothing; no error | Overlay name must exactly match the FEATURE base name |
| 3 | Omitted the `ixmaps.Map()` assignment (`var myMap = …`) | Map may partially init; further calls fail or do nothing | Always capture the instance in a variable named `myMap` (never `map`). Use `var`/outer scope if it's reassigned in `buildMap()` or shared across functions; `const` is fine for a single self-contained block |
| 4 | Omitted `name` in `.meta()` | `changeThemeStyle` / `hideTheme` / `showTheme` silently no-op | Add `name: "themeName"` to every `.meta()` you'll reference at runtime |
| 4a | Passed the **layer name** (`myMap.layer("citta")`) to `changeThemeStyle`/`hideTheme`/`showTheme`/`removeTheme` instead of the **theme name** (`.meta({name:...})`) — easy when the two strings differ, since every other call in the same chain (`.binding()`, `.title()`, etc.) legitimately uses the layer name | Silent no-op, same as omitting `meta.name` entirely — no error, the style slider/toggle just does nothing | These are two different identifier slots even though both read as "the name": layer name = geometry/data slot (FEATURE+overlay matching); theme name = runtime-mutation target. When they're set to different strings (not merely omitted), double-check which one you're passing — don't reach for whichever string is most recently typed in the chain |
| 5 | Called `changeThemeStyle` via `ixmaps.map()` or fluent chain | Returns `{szMap: null}`; no update | Use `myMap.then(api => api.changeThemeStyle(...))` |
| 6 | Missing `.binding()` | Layer skipped entirely | `.binding()` with `geo` + `value` is required on every layer |
| 7 | Missing `.define()` | Layer never registered | `.define()` must close every layer chain |
| 8 | `objectscaling: "dynamic"` without `normalSizeScale` | All symbols invisible or wildly oversized | Add `normalSizeScale: "8000000"` (match to zoom level) |
| 9 | Overlay layer named differently from FEATURE base | No geometry to draw on → blank | Always check: overlay name == base name |
| 10 | `FEATURE\|SILENT` on base + overlay needs tooltips | Overlay renders but tooltip never fires | Drop `\|SILENT` from any base that has overlays needing hover |
| 11 | `values:` for CATEGORICAL contains numbers | Categories silently unmatched; no color applied | Cast all `values:` entries to strings: `["1","2","3"]` |
| 12 | `fillopacity: 0` to hide a fill | Silently coerced to `1` (fully opaque) — fill shows at full strength, the opposite of intended | Use `colorscheme: ["none"]` (array) to hide a fill; never `fillopacity: 0` |
| 13 | Redefining an overlay under a **new** `meta.name` without `removeTheme(prev)` | Old theme stays — themes stack | Reuse the **same** `meta.name` (auto-replaces) **or** call `api.removeTheme(prev)` before `.define()` |
| 14 | Geometry branch mismatch (main=2026 codes vs data=2024) | Some regions silently unjoined (Sardinia etc.) | Pin geometry to commit `0153a0e` for 2024-compatible ISTAT codes |
| 15 | Used `geometry:{type:"Sphere"}` on a non-Orthographic projection | Nothing renders; no error, theme reports done | `Sphere` is Orthographic-only — use the dense-polygon world-bounding-box technique for other projections |
| 16 | Used `geometry:{type:"Sphere"}` against an ixmaps-flat build without native Sphere support | Nothing renders; no error, theme reports done | Confirm the loaded engine build/version includes the fix (added 2026-07-03) before assuming a config mistake |
| 17 | Called global `ixmaps.layer(name)....define()` and never passed the result to `myMap.layer(theme)` | Data loads, theme registers, legend can even populate with the correct value range — but zero elements render (0 `<circle>`/`<path>` in the map SVG) | Use `myMap.layer(name)....define()` inline on the captured instance, **or** if using define-then-add, follow it with `myMap.layer(theme)` / `myMap.layer(theme, "direct")` — see Rule 1a |
| 18 | Used `Data.merger()` without `label:` in `addSource`, then bound to the original column names | **Every** merged column is renamed `"<name>.<sourceIndex + 1>"` — including the first source's (`livello.1`, `latitude.2`). The join succeeds, the row count is exactly right, no error is logged — and nothing renders, because `.binding()` points at columns that no longer exist | Pass `label` positionally matching `columns` (`label` identical to `columns` keeps the names). A correct row count proves nothing here — check `mergedTable.columnNames()`. See DATA_JS_GUIDE.md § Data.Merger |
| 19 | Used `table.select('WHERE "col" >= "…"')` (or `<=`/`>`/`<`/`BETWEEN`) on a date or other non-purely-numeric string column | Both sides of the comparison are coerced through `Number()`; a value like `"2026-08-04"` becomes `NaN` on the query side (and is truncated to `2026` on the row side), so the comparison is always false. `select()` returns an empty table — no error, no warning | Never use `>`,`<`,`>=`,`<=`,`BETWEEN` in `select()` on non-numeric strings (dates included). Use `.getArray()` + `.columnNames()` and filter with plain JS string comparison instead — correct for `YYYY-MM-DD` since lexicographic order matches chronological order. `=` and `<>` are unaffected and safe for any string. See DATA_JS_GUIDE.md § `select(szSelection)` |
| 20 | Added `AGGREGATE\|COUNT` to a `MULTIPLE`/`MULTIGRID`/`MULTIQUAD` theme, reasoning that `MULTIGRID` needs `AGGREGATE` (a comment inside the engine's aggregation code mentions both together) | `COUNT` (or `SUM`) selects the merge-into-one-item path shared with `PIE`/`SEQUENCE`/`BAR` — it collapses all N same-position records into a single item holding a value array. `MULTIGRID`'s draw-time position-spreading then has only 1 item to place, not N — theme reports done, one item renders instead of the N-item grid you were expecting, no error | `MULTIPLE`/`MULTIGRID`/`MULTIQUAD` need **no** `AGGREGATE` at all — their position-spreading runs in the draw loop on whatever items already exist (one per record, by default), independent of `AGGREGATE`. See § Chart Shapes above |
| 21 | Assumed `GROUP` merges values too, since it enters the same engine function (`aggregateValues()`) as `AGGREGATE` and the function name itself says "aggregate" | It doesn't — `GROUP` explicitly skips the merge branch. Item count stays N (nothing collapses), only position (snap) and order (sort by value, `UP`/`DOWN`) change. Code that then reads a merged multi-value array (e.g. expects `CATEGORICAL` slices) finds N separate single-value items instead — chart renders, but not the shape expected, no error | `GROUP` and `AGGREGATE` gate the *same* decision in opposite directions — only one of them ever applies. If you need merged category counts, use `AGGREGATE`; if you need N individual items snapped/sorted for `MULTIPLE`/`MULTIGRID`/`MULTIQUAD` to then spread, use `GROUP`. See § Chart Shapes above |
| 22 | Used `colorfield` (style) on a `CHART\|BUBBLE` theme to color bubbles by a field different from the one driving size/value (the pattern documented for CHOROPLETH/VECTOR/DOT categorical coloring) | Every bubble renders in **one single color** — `colorScheme[0]` — regardless of the per-item class, which IS computed correctly (`itemA[a].nClass`/`.szColor` resolve right) but the BUBBLE draw path never reads them: it recomputes color fresh from the chart *value* (`nClass = nValue − 1`), ignoring `colorfield` entirely. No error, no warning — the legend can even show the right classes while every bubble on the map is identical | `colorfield` genuinely doesn't work on BUBBLE. Use the **category field as `binding.value` directly** instead (§ Special Patterns "CATEGORICAL + bubble size from a numeric field" — this is the engine's own supported path for BUBBLE categorical color, decoupled size via `binding.size`). If you truly need `colorfield` semantics (color field ≠ value field) keep the chart as `CHART\|SYMBOL` instead of `BUBBLE` (`symbols:"circle"` looks identical) — SYMBOL's draw path does read the resolved per-item color |
| 23 | Assumed hover/tooltip priority among overlapping `CHART` themes on the same or nearby geometry follows visual z-order (later `.layer()` call = drawn on top = wins hover) | It follows **definition order** instead — the theme defined **earlier** in the `.layer(...)` chain wins hover, even when a later-defined theme is visually on top. A `VECTOR`/`BEZIER` line theme also has a mouse hit-area noticeably wider than its rendered stroke, so an early-defined flow/line theme can silently steal hover from nearby `BUBBLE`/`CHOROPLETH` points that only *look* unrelated. No error — the wrong theme's tooltip just shows | Reorder `.layer(...)` calls: put the theme you want hover/tooltip priority for **earliest**, and push wide-hit-area `VECTOR`/`BEZIER` line themes as **late** as possible in the chain. If a tooltip shows the "wrong" theme's content, suspect layer *order* before debugging tooltip HTML/CSS |
| 24 | Set `objectscaling: "dynamic"` + a very large `normalSizeScale` (e.g. `"150000000"`, for a world/zoom-1 view) on a `CHART|BUBBLE|CATEGORICAL` theme that has **no per-item size binding** (every bubble meant to render at the same fixed size via `style.scale` alone) | Some — not all — category classes silently collapse: their SVG group keeps an identity transform (`matrix(1 0 0 1 0 0)`) and an unscaled raw radius (e.g. `r="100"`), so those items render at zero effective size at the SVG origin instead of at their real position. Confirmed reproducible on a genuine hard reload (not a stale-tab artifact) with 2 of 3 classes affected and the third rendering correctly — the legend still shows correct per-class counts throughout, so it looks like a data problem rather than a draw one | `objectscaling: "dynamic"` has nothing to scale *from* when there's no `binding.size` value — drop `objectscaling`/`normalSizeScale` from `.options()` entirely for a theme where every bubble is meant to be the same fixed size (control size with `style.scale` alone). Only enable dynamic scaling when a real per-item size value exists to drive it. If a map's bubbles inexplicably work for some categories but not others with the legend counts still correct, suspect this before suspecting the data |
| 25 | Built a swappable `CHOROPLETH` overlay reusing a `FEATURE` base's geometry (same layer name, § Multi-Layer Join Pattern · B), binding the overlay with only `geo` + `value` (+ `title`) — no `id` — reasoning that the overlay supplies its own full geometry from the same source file, so no join key should be needed | Only a small, non-random fraction of records get classified/colored — confirmed 1,107 of 7,894 polygons (clustered by insertion order in the source file, e.g. all from the first province) — the rest silently keep the base layer's fallback fill color. `theme done` logs normally, no error, no warning | Give the overlay's `.binding()` an explicit `id` matching the base layer's own `id` field, even though the overlay isn't doing a separate-CSV lookup join: `.binding({ geo: "geometry", id: "PRO_COM", value: field, title: "NAME" })`. Confirmed empirically: without `id`, 6,787/7,894 stuck at the base fill; with it, 7,893/7,894 correctly classified. Add this `id` any time an overlay redefine on a shared layer name covers less than the full dataset with no visible cause |
| 26 | Set `mode: "info"` in `ixmaps.Map()` init options, expecting hover to show tooltips immediately with no further calls — as documented under § `mode`: pan on touch, info on desktop | Hover tooltips stay completely dead. `map.szMapToolType` remains `""` (not `"info"`) at init regardless of the `mode` option, `tools: true`/`false`, or how long you wait after load. `.meta().tooltip` is confirmed correctly registered on the theme object (`ixmaps.getThemeObj(name).objTheme.theme.szTooltip`), and the hover handler (`map.Event.defaultMouseOver`) does fire — but it gates the call to `displayTooltip` on `map.szMapToolType !== ""` and returns early. No console error. Confirmed with both synthetic `MouseEvent` dispatch and genuine mouse hover (`computer` tool), independent of `tools:true/false` | Explicitly call `ixmaps.setMapTool("info")` once the map is ready (e.g. inside `myMap.then(function(){ ixmaps.setMapTool("info"); })`). This is a plain global call — the same one a `tools:true` toolbar's own PAN/INFO toggle button invokes internally — and it reliably sets `szMapToolType` regardless of the `mode` init option. Do this any time a map needs working hover-tooltips from the first paint, without requiring the user to find and click a small toolbar icon first |
| 27 | Redefined the **same** theme repeatedly from a control-driven redraw function (Year/Age/Sex-style dropdowns, § Animated/Timeseries Maps), with `.data({ url: DATA_URL, type: "csv" })` reloaded on every redraw and no `name`+`cache:"true"` | Every redraw re-runs the full fetch→parse pipeline (`Data.Broker.addSource` → `__doCSVImport` → `__processCSVData`) even though the URL never changed — confirmed via console timing: ~450ms per redraw for a real CSV, vs ~5-15ms once cached. No error, no warning — the map just redraws slower than it needs to, and reading `ixmaps.getThemeObj(name).objTheme.dbFields/dbRecords` synchronously right after that `.define()` (e.g. building a custom click/hover panel per Hotspot below) races the reload and can return stale/`null` data | Add `name: "someLabel", cache: "true"` to the repeatedly-reloaded `.data()` call so ixmaps reuses the already-parsed table across redraws instead of re-fetching — this applies to a single theme redefined many times over, not just multiple simultaneous themes sharing one load (API_REFERENCE.md's documented use case). Cleanest of all: fetch/parse the CSV **once** yourself and redefine with `obj: cachedData` instead of `url:` thereafter — the pattern SKILL.md's own swappable-theme example already uses. Either way, still hook `layerdraw`/`"theme done"` rather than assuming any given redraw is fast enough to read synchronously — see the custom-tooltip Hotspot below |
| 28 | Assumed `{{fieldname}}` / `{{raw.fieldname}}` / `{{title}}` in a `.meta().tooltip` mustache template resolve a plain string field the same way they do for a directly-bound `FEATURE`, when the theme is actually a `CHOROPLETH` driven by a `.binding({ lookup: ... })` join | The string field renders **empty** — only the bound numeric `value` and `{{theme.item.data}}` (which dumps every column) actually resolve for a lookup-joined CHOROPLETH. No error; the tooltip just silently loses the country/region name while still showing a value | Read the row directly from the theme's own already-loaded table instead: `ixmaps.getThemeObj(themeName).objTheme.dbFields` (array of `{id,...}`) + `.dbRecords` (raw row arrays) — build a field-name→column-index map from `dbFields`, then scan `dbRecords` for the row matching your join key. Build a fully custom tooltip/panel from that rather than fighting the mustache template. To suppress the native tooltip entirely while doing this, use `tooltip: "{{}}"` in `.meta()` — `tooltip: ""` does not fully disable it |
| 29 | Attached a custom `mousemove` listener via delegation on the map container (e.g. `document.getElementById("map").addEventListener("mousemove", handler)`, the same delegation pattern that works for `click`) to build a custom hover tooltip | The listener never fires. ixmaps attaches its own mousemove/mouseover handlers directly on the SVG item groups for its native hover-highlight system, and those call `stopPropagation()` — a normal bubble-phase listener on the container never receives the event. Click delegation is unaffected (ixmaps doesn't stop that one) — only mousemove/hover | Register the listener on the **capture phase** instead: `addEventListener("mousemove", handler, true)` (3rd argument `true`, or `{capture:true}`). Capture fires top-down before ixmaps' bubble-phase `stopPropagation()` can block it |
| 30 | Applied `name`+`cache:"true"` to every `.data()` call as a blanket habit (following Hotspot #27's fix), rather than scoping each `name` to one specific data source — e.g. reused a generic label like `"data"` across two `.data()` calls that actually load different URLs, or the same URL filtered/queried differently upstream | The **second** theme silently gets the **first** theme's already-cached data object instead of loading its own — `name` is a manually-chosen cache key, and ixmaps has no way to know the two calls were supposed to differ. No error, no warning, no mismatch in row count necessarily — the theme just renders with the wrong dataset behind it | `name`+`cache:"true"` is not a default to sprinkle everywhere — add it only where a `.data({url:...})` genuinely reloads the same source repeatedly (redraw/animated/swappable patterns, Hotspot #27), and give each distinct data source its own `name`. On a theme defined once and never redefined, it's inert boilerplate with no benefit either way |
| 31 | Tried to build a 2D/3D-globe toggle by calling `ixmaps.Map()` a second time for the new projection (a fresh div included) — reasoning that `mapProjection` being init-time-only just meant "re-run init" | The second call returns an empty stub object (`{}`, no `.view()`/`.layer()`) — `ixmaps.Map()` is a page-wide singleton, not scoped per div. Separately, the *correct* live-swap technique (`ixmaps.getProjectString()`/`setProjectJSON()`, § Switching projection at runtime) has its own gotcha: switching Orthographic → Equal Earth leaves the SVG transform permanently stuck off-screen (every path still in the DOM, `getZoom()`/`getCenter()` report correctly, nothing fixes it short of a reload) — no error either way, both fail silently into a blank or broken map | Never re-call `ixmaps.Map()` once a map exists on the page. Use the `getProjectString`/`setProjectJSON` swap instead — and for the one broken direction (3D → 2D), reload the page rather than continuing to fight the stuck transform. Full mechanism, code, and the reload workaround → § Switching projection at runtime |
| 32 | Wrote a `.filter()` with `OR` to select a set of values (e.g. `CNTR_ID == "NL" OR CNTR_ID == "CH" OR ...` to pick 6 countries out of a world dataset) — reasoning that the skill's own `.filter()` examples say "use AND/OR" | Only the **first** clause ever matches — confirmed in the engine source (`maps/svg/js/maptheme.js`): the filter tokenizer only continues past one clause if the next token is literally `"AND"`; anything else, including `"OR"`, breaks the loop and silently discards every remaining clause (source comment: `// only 'AND' combination (OR tdb)` — never implemented). `theme done` logs normally, no error — the theme just renders with 1 record selected instead of 6 | `OR` genuinely does not work in `.filter()` — only `AND` does (confirmed: a 6-clause `<>`/`AND` exclusion filter worked correctly). To select a *set* of values, filter the source data yourself in plain JS before it reaches ixmaps (fetch, `.filter()` the array/features, then `.data({obj: filtered, ...})`) rather than trying to express it as an ixmaps WHERE clause. See API_REFERENCE.md § `.filter(expression)` |
| 33 | Built a live projection toggle (`ixmaps.setProjectJSON()`, § Switching projection at runtime) on a map that already correctly called `ixmaps.setMapTool("info")` once at init (Hotspot #26), assuming that call would keep hover tooltips armed for the rest of the page's life | Hover tooltips work fine until the **first** projection switch, then go silently dead — `setProjectJSON` (via the theme redraw it triggers) resets `map.szMapToolType` back to `""`, the exact same gate as Hotspot #26. No error, no warning. Confirmed the obvious fix doesn't stick: calling `ixmaps.setMapTool("info")` synchronously right after `setProjectJSON()` is a no-op, because the async redraw the swap triggers overwrites the tool state again a moment later; calling the identical line from the console *after* the swap has visibly finished works immediately | Re-arm with a short delay placed **after** the `setProjectJSON`/theme-swap block, not inline with it: `setTimeout(function(){ try { ixmaps.setMapTool("info"); } catch(e){} }, 400);`. Needed on every runtime projection switch, in addition to the one-time init call from Hotspot #26 — the two are independent, both required |

---

## Geometry Reuse Pre-flight Checklist

Run this mental check before writing **any** overlay layer (CHOROPLETH, CHART on polygons):

```
[ ] Is this overlay's myMap.layer("NAME") identical to the FEATURE base layer name?
    → If NO: rename it. A different name = no geometry = nothing renders.

[ ] Does this overlay need to be swappable at runtime (sidebar picker, time slider)?
    → If YES: add name to .meta(). Reuse the SAME meta.name on each swap → auto-replaces.
              (Or use a different name per theme + api.removeTheme(prev) before each .define().)
    → If NO: no meta.name required (unless changeThemeStyle is needed)
```

---

## Choosing the Engine (flat | gl)

Same builder API, two renderers. **Default: ixmaps-flat** (SVG/Leaflet, stable `@1`, every rule,
template and hotspot in this skill is verified against it).
**ixmaps-gl** (MapLibre + deck.gl, 0.x) is an opt-in second option.

**Offer gl only when the user asks for it, or when one of these applies:**
- more than ~50k points/features, or pan/zoom smoothness is the problem
- a globe (orthographic) view or 3D flow arcs (`3D` on `CHART|VECTOR|BEZIER`)
- heatmap/KDE or vector-tile / PMTiles layers (`HEATMAP`, `KDE`, `MLHEATMAP`, `MLPMTILES`)

**Gate, before proposing gl:** run the grammar checker on the finished page.
  `npx ixmaps-check --engine gl page.html`
Any `gl-unsupported` finding on a theme type, flag or style key → stay on flat and say why.
`gl-unsupported` on page chrome only (`tools`, `toolbutton`, `search`, `mapName`, `mapService`,
`flushChartDraw`) is acceptable: gl has no toolbar or search UI.

**Switching:** change only the script tag; never rewrite the page's API calls.
  `<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-gl@0/ixmaps-gl.js"></script>`
(replaces the flat `<script>`; MapLibre, deck.gl and data.js are loaded by the engine itself.)

**Known differences to tell the user:** `objectscaling` defaults to `"dynamic"` in gl; pie/bar
`3D`, `VOLUME`, `TRENDLINE`, `ZOOM` and flow `DYNAMICWIDTH` are logged and drawn plainly;
needs WebGL (no WebGL, no map); this skill's Silent Failure Hotspots are verified on flat only,
so for gl pages verify rendering visibly (Render Contract, stage 6), not by absence of errors.
Debug with `.options({validate:true})` or `?ixmaps-validate` on the page URL.

Full gl feature list and limits → `github.com/gjrichter/ixmaps-gl` README.

## Choosing Visualization Type

```
Is your data...

├─ Points (lat/lon)?
│  ├─ Just locations?                    → CHART|DOT
│  ├─ Colored by category (legend-selectable)? → CHART|BUBBLE|CATEGORICAL  ⚠️ NOT DOT|CATEGORICAL
│  ├─ Sized by value?                    → CHART|BUBBLE|SIZE|VALUES
│  ├─ Density heatmap (circles)?         → CHART|BUBBLE|SIZE|AGGREGATE  + gridwidthpx:"5"
│  ├─ Density heatmap (squares)?         → CHART|SYMBOL|GRIDSIZE|AGGREGATE|RECT|SUM|DOPACITY|VALUES  + symbols:["square"] + gridwidthpx:"80"
│  ├─ Sparklines per grid cell?          → CHART|SYMBOL|PLOT|LINES  (see Sparklines below)
│  ├─ Flows origin→destination?          → CHART|VECTOR|BEZIER|POINTER
│  ├─ Multi-value per point?             → CHART|SYMBOL|SEQUENCE  (|STAR for 5+ categories)
│  ├─ Several records at ONE point, want to MERGE them into counts/sum? → add |AGGREGATE (+ COUNT/SUM) — see § Chart Shapes below
│  ├─ Several records at ONE point, want ALL of them visible, not merged? → add |MULTIPLE, |MULTIGRID, or |MULTIQUAD instead — NOT |AGGREGATE (see § Chart Shapes below — these two are independent mechanisms, easy to conflate)
│  ├─ Records at NEARLY (not exactly) the same point, or need a defined sort/stack order, before spreading them with MULTIPLE/MULTIGRID/MULTIQUAD? → add |GROUP (+ gridwidth/gridwidthpx) alongside them — GROUP snaps/sorts position only, it NEVER merges values, item count stays N (see § Chart Shapes below)
│  └─ Stacked/grouped bars per location? → CHART|BAR|STACKED  (add |SIZE|GRID|BOX|VALUES for full display)
│     gridx:N in .style() = values per bar group (gridx:2 → 2 segments per bar; gridx:3 → 3 separate bars)
│     ⚠️ gridx also controls |MULTIGRID/|MULTIQUAD spacing (items per row) — same name, unrelated meaning there
│
└─ Polygons (GeoJSON/TopoJSON)?
   ├─ Boundaries only?                   → FEATURE
   ├─ Colored by data (geometry+data)?   → FEATURE|CHOROPLETH  (|QUANTILE | |EQUIDISTANT | |CATEGORICAL)
   └─ Data joined to pre-loaded geometry?→ CHOROPLETH only — NEVER FEATURE|CHOROPLETH
```

**Key type modifiers:**
- `|GLOW` — glow effect on any CHART type
- `|DOPACITYMAX` — dynamic opacity (high values prominent); add `alpha: "field"` to `.binding()`
- `|DOPACITYMINMAX` — dynamic opacity (extremes prominent)
- `|CATEGORICAL` — discrete category coloring; `values:` array in style maps to `colorscheme` in order
- `|SILENT` — excludes layer from legend, statistics **and** suppresses tooltips on its items
- `|NOLEGEND` / `|NOINFO` — excludes layer from legend only (tooltips still work); this is also what suppresses that layer's own "loading ..." splash text in the legend panel while its data is still processing — `.meta({splash:"..."})` only changes that text, it doesn't suppress it
- `|NOOUTLIER` — removes extreme outliers from classification calculations
- `|ZEROISNOTVALUE` — suppresses rendering where value ≤ 0 (useful for sparse/incomplete time series)
- `|NOSCALE` — disables dynamic zoom scaling; flows/symbols stay constant size regardless of zoom
- `|GRADIENT` — gradient color along flow lines (origin color → destination color); use with `CHART|VECTOR|BEZIER` — **gradient must be defined via `linecolor: ["#from","#to"]` array, NOT `colorscheme`**
- `|CLIPTOGEOBOUNDS` — clips chart rendering to the containing polygon boundary
- `|DOMINANT` — colors each record by whichever of several piped fields most exceeds the mean *of that record's own fields* (within-record "peak class"); `|PERCENTOFMEAN` changes the axis to *that field's own mean across all records* (cross-record "biggest outlier") — easy to conflate, see § Special Patterns "Dominant class per record" for the verified worked example and the difference in practice
- `|DTEXT` — makes `VALUES`-generated text labels on `CHOROPLETH` themes properly sized (always pair with `|VALUES` on choropleth layers that show value labels)
- `|SMOOTH` — smoothing interpolation on sparkline curves
- `|SORT` / `|SORT|DOWN` — sort sparkline categories ascending / descending
- `|TEXTLEGEND` — renders category labels directly on chart symbols instead of in the legend box
- `|TEXTONLY` — text labels only, no chart symbol (combine with `CHART|LABEL|VALUES|FIXSIZE|NOLEGEND`)

**Aggregation modifiers** (replace the value of each cell with the aggregate):

| Modifier | Computes |
|---|---|
| `SUM` | Sum of all values in cell |
| `COUNT` | Count of rows in cell |
| `MEAN` | Arithmetic mean |
| `MIN` | Minimum value |
| `MAX` | Maximum value |

### § Chart Shapes — and four ways to handle shared positions

`BUBBLE` / `SQUARE` / `LABEL` are interchangeable shapes (circle / square / horizontal
rectangle) — every other modifier applies the same way regardless of which one is picked.

Four ways exist to handle several records landing on the same (or nearly the same) point —
picking the wrong one is a common source of "renders, but not the shape I expected" with no error:

| Need | Use | Item count after |
|---|---|---|
| Merge into counts/totals per category (PIE/SEQUENCE/BAR slices) | `AGGREGATE` (+ `COUNT`/`SUM`/…) | 1 |
| Keep every record visible, snapped/sorted first (nearly-coincident points, or a defined stack order) | `GROUP` + `MULTIPLE`/`MULTIGRID`/`MULTIQUAD` | N |
| Keep every record visible, already exactly coincident | `MULTIPLE`/`MULTIGRID`/`MULTIQUAD` alone | N |
| A handful (2-5) of real coincident points, want to preserve rough true position | Manual `lat`/`lon` jitter (~0.0005–0.02°) in the source data | N |

`AGGREGATE` and `GROUP` are mutually exclusive (same detection pass, opposite merge decision).
`MULTIPLE`/`MULTIGRID`/`MULTIQUAD` are a fully independent mechanism keyed on *resolved screen
position*, not on whether `AGGREGATE`/`GROUP` ran. Manual jitter is the odd one out — it's not an
engine feature, just deciding the source coordinates aren't exactly equal in the first place;
prefer it over `GROUP`+`MULTIPLE` only for a small, known cluster where each point should still
look roughly right at close zoom (`GROUP`+`MULTIPLE` scales further but spreads items into an
arbitrary pattern unrelated to their real position).

> ⚠️ Don't infer from a comment inside the engine's aggregation code that `MULTIGRID` needs
> `AGGREGATE` — it doesn't; `MULTIGRID`'s position-spreading runs independently in the draw loop.
> Full mechanism, worked comparison table, and the jitter tradeoff in detail →
> **API_REFERENCE.md § Chart Shapes, and Four Ways to Handle Shared Positions**.

**Classification methods** (used with `CHOROPLETH` and `CHART`):

| Method | Description |
|---|---|
| `EQUIDISTANT` | Equal-width intervals across the data range |
| `QUANTILE` | Equal-count intervals — each class has the same number of features |
| `HEADTAIL` | Head/tail breaks — iteratively splits at the mean; best for heavy-tailed distributions |
| `NATURAL` | Jenks natural breaks — minimises within-class variance |
| `LOG` | Logarithmic intervals — useful when values span several orders of magnitude |

**VECTOR sub-modifiers:**
- `|DASH` — animated flowing dashes along flow direction (combine freely with BEZIER|POINTER|FADEIN)
- `|GRADIENT` — gradient color from origin to destination along each flow line

**Deprecated modifiers — do NOT use:**
- ~~`SIZEP1`~~ → use `SIZE` + `sizepow: 1` in `.style()` instead
- ~~`EXACT`~~ → use `CATEGORICAL` instead

> For full type-string reference and all modifiers → **API_REFERENCE.md § Visualization Types**

---

## Workflow

1. **Parse** the user's request: data source, visualization goal, styling preferences
2. **Ask** if key info is missing (data format? geographic scope?)
3. **Choose template**:
   - `template-points.html` — CSV/JSON with lat/lon
   - `template-geojson.html` — GeoJSON/TopoJSON
   - `template-multi-layer.html` — multiple layers with join
   - `template-kde.html` — weighted KDE / density heatmap (Turf.js extension)
   - `template-change-choropleth.html` — delta/variation between two periods (arrows)
   - `template-world-flows.html` — origin → destination flows
   - `template-europe-choropleth-sparklines.html` — choropleth + per-feature sparkline
   - `template-flexible.html` — fully configurable, complex logic
   - `template.html` — general purpose
4. **Check against the Render Contract — before writing.** Walk stages 1–6 of § The Render
   Contract against the code you are about to emit. Concretely:
   - [ ] ixmaps CDN `<script>` present; `#map` div has non-zero height; no reserved ids reused
   - [ ] `myMap = ixmaps.Map(...)` — instance captured in a variable (`var` if reassigned/shared, `const` for a single block; never name it `map`)
   - [ ] `.data()` resolves — inline `obj:`, or a CORS-reachable `url:` (never `file://`)
   - [ ] `.binding()` has `geo` (plus `value` on data-driven layers; a FEATURE base uses `id` instead)
   - [ ] `.style()` has `showdata: "true"` on every data-driven layer
   - [ ] Every layer chain is closed by `.define()` **and** attached — inline `myMap.layer(name)....define()`, or (only for a deliberately swappable/multi-theme map) a global `ixmaps.layer(name)....define()` whose result is passed to `myMap.layer(theme)` / `myMap.layer(theme, "direct")`. Never leave a global define's return value discarded — see Rule 1a
   - [ ] viztype matches the data shape; join overlay's layer name == its FEATURE base's name
   - [ ] If `objectscaling:"dynamic"` → `normalSizeScale` set
   - [ ] `.view()` centred over the data (object form, Rule 25); lat/lng not transposed
   - [ ] Map call sequence is `Map(…)` → `.view()` → `.options()` → `.layer()` — `.view()` must
         precede every `.layer()`, since layer symbols size against the current view (see
         § Map call sequence)
   - [ ] `.meta()` present with tooltip; `name` in `.meta()` for anything addressed at runtime
   - [ ] If the map needs a title/subtitle/description, use `.title()` + `meta.snippet` + `meta.description` (§ Map title, subtitle & description) — not a custom overlay `<div>`
   - [ ] Start with `scale: 1` — let user request size adjustments

   **Optional programmatic check** — for parameter-driven maps, validate a JSON config
   against `skill-ui.yaml` before generating:
   ```bash
   node validate-config.js config.json    # checks types, ranges, valid options, deps
   # one-time setup if missing: npm install js-yaml
   ```
   > Full `skill-ui.yaml` parameter/type/schema reference → **UI_YAML_GUIDE.md**
5. **Write** the HTML file
6. **Verify it renders — do not skip, and do not substitute "file created" for this.**
   A written file is not a working map; ixMaps fails silently, so an unverified map is an
   unknown one.
   Verification is **host-dependent by design** — this skill declares no browser tool of its
   own. Use whatever preview/browser capability the calling environment provides (an in-app
   browser pane, a Playwright/Chrome tool, a local preview server). Its absence is a property
   of the environment, not a misconfiguration to fix.
   - With such a tool, run this **preflight first — in order. An element count means nothing
     until all three gates pass**, and a failed gate says the environment cannot verify, *not*
     that the map is broken:
     ```javascript
     // GATE 1 — container has real size. Everything downstream is meaningless without this.
     var d = document.getElementById('map');
     d.offsetWidth > 0 && d.offsetHeight > 0        // must be true
     // GATE 2 — the page actually executed its script
     typeof window.ixmaps === 'object'              // must be true
     // GATE 3 — the theme finished drawing (console logs "theme done - <meta.name>");
     //          poll, don't measure once — drawing completes asynchronously
     ```
     Only then the actual test:
     ```javascript
     document.querySelectorAll('circle, path, rect, image').length
     // > 0 = drew. Compare the count and the painted fills against your data
     // (e.g. N categories → N distinct fills) — that is what proves the join and
     // the colour mapping, not the raw number.
     ```
     Also check the console is clean and the data sits inside the current view. A screenshot is
     good supporting evidence, but the element count is the actual test — a map can look
     plausible while showing only the basemap.
     > ⚠️ **Rule out the tool before blaming the map — these are false negatives, not defects.**
     > - **Gate 1 failing (`0x0` container) is the worst trap:** a headless, background or
     >   unfronted tab commonly reports a `0x0` viewport. Then `height:100%` resolves to `0`,
     >   Leaflet cannot compute tile bounds, and ixMaps cannot size its SVG. The symptom cluster
     >   is **no basemap + `getZoom()` returning a low fallback value + elements present in the
     >   DOM at nonsense transforms + counts that change between calls**. Every one of those
     >   looks like a map bug and none of them is. Check `offsetWidth`/`offsetHeight` before
     >   reading anything else.
     > - **Gate 2 failing:** some preview panes render files outside the project folder as static
     >   snapshots and never execute JavaScript.
     > - **Gate 3 failing:** measuring before `theme done` undercounts — the same page can report
     >   3 elements and then 30 seconds later.
     > - If any gate fails, do not edit the map. Open the file directly in a browser (a map with
     >   inline data needs no server — it works straight from disk) or serve it over HTTP, and
     >   re-run the preflight there. If it still cannot be verified, report it **unverified**.
     > - Likewise, if a synthetic `hover`/`click` doesn't raise a tooltip, dispatch a real
     >   `MouseEvent` on the chart group before deciding tooltips are broken — automated pointer
     >   events don't always reach ixMaps' handlers.
     > - **Two clicks at the same spot in quick succession read as a double-click** — Leaflet's
     >   native zoom fires, jumping to a very high zoom with a blank viewport (`getZoom()` far
     >   above the coded value, nothing renders) — a tool artifact, not a defect. Space out clicks;
     >   don't immediately re-click a spot that didn't seem to register.
     > - **`navigate()` to the identical URL in an already-used tab can leave stale engine state**
     >   (e.g. `getZoom()` wrong even though the DOM/title are correct). Don't chase this by
     >   re-navigating the same tab — open a fresh tab (`tabs_create` → `navigate`) instead.
     >
     > When the tool cannot give you a clean preflight, a **static control** is the honest
     > fallback and is worth more than a bad measurement: check the emitted code against
     > § The Render Contract and the Critical Rules (chain order, `showdata`, binding fields
     > present in the data, `values:` all strings, `meta.name` ≠ layer name), and cross-check
     > every tooltip `{{field}}` against the actual data keys.
   - **Without one:** re-walk the step-4 checklist, then say plainly that the map is written
     but **unverified**, and give the user the one-line check above to run themselves. Never
     report it as working — an unverified map is exactly where a silent failure hides.
7. **Explain** what the map shows; offer to enhance

> **Hosting local data** — if the user's data is a local file but a layer needs a `data({url:…})`
> (CORS blocks `file://`), upload it to get a CDN URL:
> ```bash
> ./upload-helper.sh data.csv [project-name]   # GitHub API → git → manual fallback
> ```
> Needs `IXMAPS_GITHUB_TOKEN` + `IXMAPS_REPO_USER` env vars for automated upload; otherwise it
> prints manual steps. Full setup → **DATA_HOSTING_GUIDE.md**. (Or skip hosting entirely and
> inline the data via `obj:` — see § Data Configuration.)

---

## Defaults

| Setting | Default |
|---------|---------|
| filename | `ixmap.html` |
| mapType | `"VT_TONER_LITE"` ← always use unless user asks otherwise |
| center | `{ lat: 42.5, lng: 12.5 }` (Italy) |
| zoom | 6 |
| colorscheme | `["#0066cc"]` |
| basemapopacity | 0.6 |
| flushChartDraw | 1000000 |
| flushPaintShape | *(not set)* — set to `1000000` when rendering large polygon datasets (municipalities, communes) to avoid rendering hangs |
| zoomAnimation | `true` — smooth zoom transitions; set `false` to disable |
| tools | true |

**Valid basemaps** (case-sensitive): `"VT_TONER_LITE"` · `"white"` · `"CartoDB - Dark matter"` · `"CartoDB - Positron"` · `"Stamen Terrain"` · `"OpenStreetMap - Osmarenderer"`
❌ NOT: `"OpenStreetMap"` · `"OSM"` · `"CartoDB Positron"` → See **MAP_TYPES_GUIDE.md** for full list

---

## Map Init Pattern

> ⚠️ **Scrollbar pitfall** — never use `width: 100vw; height: 100vh` on the map `<div>`. When a scrollbar appears, `vw`/`vh` exceed the viewport and trigger a feedback loop. Always use:
> ```css
> html, body { width: 100%; height: 100%; overflow: hidden; }
> #map { width: 100%; height: 100%; }
> ```

```javascript
const myMap = ixmaps.Map("map", {
    mapType: "VT_TONER_LITE",
    mode:    "info",
    legend:  "closed",   // or "open"
    tools:   true
})
.view({ center: { lat: 42.5, lng: 12.5 }, zoom: 6 })
.options({
    objectscaling:   "dynamic",
    normalSizeScale: "8000000",   // match to zoom (zoom6≈8M, zoom12≈100k)
    basemapopacity:  0.6,
    flushChartDraw:  1000000
});
```

> ⚠️ **Custom top-left overlay (e.g. your own legend/layer panel) vs `tools`** — if you're placing your own HTML panel (not ixMaps' built-in legend) in the map's top-left corner, set `tools: false`. With `tools: true`, ixMaps creates its own UI overlay in that same corner, which visually collides with a custom panel there. This is independent of the "tools" link in the map's bottom footer (`.map-footer` chrome) — that stays regardless of this option.
>
> ⚠️ **Custom panel/legend needs `z-index: 1000` or higher** — ixMaps' own map surface (Leaflet panes: tile pane, marker pane, etc.) tops out around `z-index: 700`, so a custom overlay with a low z-index (e.g. the CSS default `10`) can render **underneath** the map instead of on top of it. Give any custom HTML panel `z-index: 1000`+ to sit above the map surface. Stay below ixMaps' own floating chrome (`#tooltip` is `10000`, `#contextmenu` is `99999`) so native tooltips/context menus can still render on top of your panel if they ever overlap it — `1000`–`2000` is a safe range.

### Map title, subtitle & description — use the native legend panel, not a custom overlay

**Recommended default whenever a map needs a title + subtitle + explanatory note (and optionally a source citation):** put it in ixMaps' own legend panel instead of building a custom absolutely-positioned `<div>`. A custom overlay collides with the INFO/LEGEND buttons or bottom chrome and needs manual z-index tuning — and worse, gets **wiped out on every legend redraw** (mark/unmark a class, zoom, pan all rebuild the legend DOM from scratch). The native fields below are re-rendered by the engine itself on every redraw, so they just persist.

```javascript
myMap.layer("name")
    // ...data/binding/type/style...
    .meta({
        name:        "name",                         // unique theme id
        tooltip:     "...",
        snippet:     "One-line subtitle, shown right below the title",
        description: "Longer explanatory paragraph, shown near the bottom of the " +
                      "legend panel, after the auto color-swatch rows." +
                      "<div style='margin-top:0.6em;padding-top:0.5em;border-top:1px solid #e5e5e5;font-size:0.8em;color:#888'>" +
                      "Source: ...</div>"             // citation nested inside description — no separate slot for it
    })
    .title("Map Title Shown as the Legend Heading")   // NOT .legend("...") — see warning below
    .define();
```

Add `legend: "open"` to the map init options (instead of `"closed"`) so the panel is visible on load without the user having to click the LEGEND toggle.

> ⚠️ **Don't call `.legend("title")` on the map builder for this** — it destroys the auto color-swatch legend (Critical Rule 11). Use `.title("...")` on the **layer** instead. Full mechanism (why `meta.snippet`/`meta.description` survive redraws) → **API_REFERENCE.md § Legend Title, Snippet & Description**.

### `mode`: pan on touch, info on desktop

`mode: "info"` makes a tap/click query features (tooltips) — good for a mouse, but on a touch device it fights with finger-dragging, so the map feels unresponsive to pan. Start touch devices in `"pan"` mode and keep `"info"` for mouse/desktop. Detect the **input type**, not the screen size — a coarse pointer means touch is the primary input (phones, tablets, touch laptops without a mouse):

```javascript
// touch (coarse pointer) → pan; mouse/desktop (fine pointer) → info
var MAP_MODE = (window.matchMedia && window.matchMedia("(pointer: coarse)").matches) ? "pan" : "info";

var myMap = ixmaps.Map("map", { mapType: "white", mode: MAP_MODE, legend: "closed", tools: true })
    .view({ center: { lat: 42.5, lng: 12.5 }, zoom: 6 })
    .options({ /* … */ });

// ⚠️ mode:"info" alone does not reliably arm hover-tooltips — see Silent Failure Hotspot #26.
// Force it explicitly once the map is ready:
myMap.then(function () {
    if (MAP_MODE === "info") { try { ixmaps.setMapTool("info"); } catch (e) {} }
});
```

- Use `(pointer: coarse)` — NOT a `max-width` breakpoint. Screen size ≠ input type (a small window on a desktop is still mouse-driven; a large tablet is still touch).
- Pure CSS media queries can't set `mode` (it's a JS init option), so this branch must run in JS before `ixmaps.Map(...)`.
- The user can still switch modes at runtime via the ixMaps tools toolbar; this only sets the **initial** mode.
- **`mode: "info"` sets the intended starting mode, but not the engine's internal tool state** (`map.szMapToolType`) — confirmed it stays `""` at init regardless of `mode` or `tools:true/false`, leaving hover-tooltips silently dead until either the user clicks the toolbar's PAN/INFO toggle, or `ixmaps.setMapTool("info")` is called explicitly (as above). See Hotspot #26.

### Projections

All projections use SVG-based rendering. Omit `mapProjection` for the default Web Mercator / Leaflet tile setup.

| `mapProjection` value | Also accepted | Projection |
|---|---|---|
| *(omit)* | — | Default Web Mercator (Leaflet tiles) |
| `"mercator"` | — | Mercator (SVG, no tile layer) |
| `"winkel"` | — | Winkel Tripel |
| `"equalearth"` | — | Equal Earth |
| `"albersequalarea"` | `"albers"` | Albers Equal-Area Conic |
| `"lambertazimuthalequalarea"` | `"lambert"` | Lambert Azimuthal Equal-Area (EPSG:3035) |
| `"orthographic"` | — | Orthographic (globe view) |

- Lookup is **case-insensitive**; unknown values fall back to Mercator
- `.view({center: {lat, lng}, zoom})` works with every projection — always use this object form (never the positional `[lat, lng]` array; see Rule 25). For world-scale projections use a low `zoom` (0–1).
- Set `mapType` to the background/sea color instead of using CSS: `mapType: "#0a1929"` (dark), `mapType: "black"`, `mapType: "dark"`, `mapType: "white"`, or any hex color. Do **not** use `mapType: "white"` + CSS `background` on `#map` — set it directly in `mapType`.
- Add a graticule layer **before** data layers for smooth curves (see Graticule below)
- **Albers only:** pass `projectionParams` in map options to set custom standard parallels / center for conic tuning

#### Lambert projection (Eurostat style — Europe)
```javascript
var myMap = ixmaps.Map("map", {
  mapType:       "white",
  mapProjection: "lambert",      // Lambert Azimuthal Equal-Area — EPSG:3035
  mode:          "pan",
  legend:        "closed",
  tools:         false
})
.view({ center: { lat: 53.4, lng: 16.9 }, zoom: 3.7 })
.options({ basemapopacity: 0, flushChartDraw: 1000000 });
```

#### Equal Earth projection (world maps)
```javascript
var myMap = ixmaps.Map("map", {
  mapType:       "#0a1929",      // dark ocean — set background directly in mapType, not CSS
  mapProjection: "equalearth",
  mode:          "info",
  legend:        "closed",
  tools:         false
})
.view({ center: { lat: 0, lng: 0 }, zoom: 1 })   // zoom: 0–1 for world-scale projections
.options({ basemapopacity: 0, flushChartDraw: 1000000 });
```

#### Orthographic projection (globe view) — ocean/sea background
```javascript
var myMap = ixmaps.Map("map", {
  mapType:       "white",
  mapProjection: "orthographic",
  mode:          "info",
  legend:        "closed",
  tools:         false
})
.view({ center: { lat: 13.24, lng: 23.2 }, zoom: 2 })
.options({ basemapopacity: 0.5, flushChartDraw: 1000000 })

// Ocean/sea background — native engine support, define BEFORE data layers so they draw on top.
.layer(
  ixmaps.layer("Ocean")
    .data({
      obj: { type: "FeatureCollection",
             features: [{ type: "Feature", geometry: { type: "Sphere" }, properties: {} }] },
      type: "geojson"
    })
    .binding({ geo: "geometry" })
    .type("FEATURE|NOLEGEND|SILENT")
    .style({ colorscheme: ["#0a2a4a"], fillopacity: "1", showdata: "true", linecolor: "none", linewidth: "0" })
    .meta({ name: "ocean-backdrop", tooltip: "" })   // meta.name ≠ layer name (Rule 24)
    .define()
);
```
- `geometry: {type:"Sphere"}` (no `coordinates` — unlike every other GeoJSON type) draws the full visible-globe disc for the current rotation, and auto-recenters on every pan/zoom/rotate as part of the theme's ordinary redraw cycle — no `moveend`/`zoomend` listeners needed, unlike a hand-rolled geodesic-circle workaround.
- **Orthographic-only.** For every other projection (`equalearth`, `lambert`, etc.) `Sphere` is a no-op (nothing renders, no error) — those projections need the dense-polygon world-bounding-box technique instead (see the ocean-background layer in the Equal Earth/Lambert-style templates).
- Do **not** use a full ±180°/±90° world-bounding polygon for the orthographic ocean background (the classic d3 "Sphere hack") — this engine's orthographic renderer does adaptive horizon-clamping per vertex, and a polygon spanning both hemispheres collapses into a degenerate sliver instead of a disc. `{type:"Sphere"}` is the correct native replacement.
- ⚠️ Requires an ixmaps-flat build with native Sphere support (added 2026-07-03). If the sea silently doesn't render and the theme otherwise reports done with no error, the loaded engine predates this feature — confirm the build/version before assuming a config mistake.

#### Switching projection at runtime (e.g. a 2D/3D-globe toggle button)

`mapProjection` is an init-time-only option on `ixmaps.Map()` — there is no documented call to
change it on a live map. **Do not try to work around this by calling `ixmaps.Map()` again**
(even targeting a brand-new, never-before-used div): confirmed empirically, once one instance
exists on the page, every subsequent `ixmaps.Map()` call returns an empty stub object with no
`.view()`/`.layer()` methods at all — `ixmaps.Map()` is a page-wide singleton, not scoped per
div, regardless of target id.

The real mechanism — found in production code (a live `ixmap_interactive_legend.html` demo),
completely undocumented elsewhere — is a lower-level project-JSON swap that never touches
`ixmaps.Map()`:

```javascript
function switchProjection(name) {           // "equalearth" | "orthographic" | "winkel" | "mercator" | "lambert" | ...
  var project = JSON.parse(ixmaps.getProjectString());
  project.map.map = ixmaps.szResourceBase + "maps/svg/maps/generic/" + name + ".svg";
  project.map.center = { lat: 0, lng: 0 };   // set inside the JSON — see caveat below on .view()
  project.map.zoom   = 1;
  ixmaps.setProjectJSON(project);
  // Do NOT chain a `myMap.view({...})` call here on every build — see caveat below.
}
```

- Existing themes (FEATURE base, CHOROPLETH overlay) reproject in place automatically — no
  redefine needed. Confirmed: switching an Equal Earth choropleth to Orthographic changed the
  rendered path count from 1626 to 808 (back-hemisphere countries correctly clipped) while
  keeping the same theme instance and its color mapping.
- A **dense-polygon** ocean background (the Equal Earth/Lambert technique above) does **not**
  reproject correctly through this swap — it needs `removeTheme` + a fresh `.define()` with the
  geometry appropriate for the new projection (`{type:"Sphere"}` for orthographic, the polygon
  otherwise), same as building either projection from scratch.
- ⚠️ **Whether a trailing `myMap.view({...})` call is needed after `setProjectJSON` is
  build-dependent — test both ways.** One session found it necessary (without it, the rendered
  SVG transform silently kept its old pan/zoom even though `getCenter()`/`getZoom()` reported
  the new values correctly). A later session, on a different engine build, found the exact
  opposite: adding that same `myMap.view({...})` call **silently reverted the whole projection
  swap** — confirmed by reading `JSON.parse(ixmaps.getProjectString()).map.map` immediately
  after, which showed the *previous* projection's `.svg` path and the *original* init
  center/zoom, as if `setProjectJSON` had never run. No error either way. Try the swap **without**
  `.view()` first (rely on `project.map.center`/`.zoom` alone), verify via a
  `getProjectString()` readback that `map.map` actually changed, and only add `.view()` back if
  the projection changed but the pan/zoom visibly didn't follow. Full worked example (world
  bubble map, Equal Earth ⟷ Orthographic toggle switch) → **example-world-bubble-projection-toggle.md**.
- ⚠️ **One specific direction is still broken even with the `.view()` call**: switching
  **from Orthographic back to Equal Earth** (3D globe → 2D) leaves the SVG group's transform
  matrix stuck on the Orthographic pan offset — confirmed reproducible on a clean cycle, every
  time. `ixmaps.getZoom()`/`getCenter()` report the correct restored values and every path is
  still present in the DOM (confirmed via path count) — the map is just rendered off-screen, a
  pure transform bug. Tried and confirmed **ineffective** for un-sticking it: a second
  `.view()` call, routing through `myMap.then(api => api.view(...))` instead, a repeat
  `setProjectJSON`, and even a genuine zoom-button click. No workaround found short of a full
  page reload (which does cleanly reset to Equal Earth) — for a 2D/3D toggle, make the "back to
  2D" direction specifically do `location.reload()` (persisting Year/Age/Sex-style UI state via
  `sessionStorage` across the reload) rather than fighting this further. The reverse direction
  (2D → 3D, or presumably any other same-hemisphere-style pair) is unaffected.
- ⚠️ **`setProjectJSON` also resets the map's tool state, silently killing hover tooltips** —
  the same `map.szMapToolType` gate as Hotspot #26, tripped a second time by the redraw the
  projection swap triggers. This bites even a map that already correctly called
  `ixmaps.setMapTool("info")` once at init — the tooltip works fine until the first projection
  toggle, then goes dead. Confirmed the naive fix doesn't stick: calling
  `ixmaps.setMapTool("info")` synchronously right after `setProjectJSON()` is a no-op (the async
  theme redraw the swap triggers overwrites it again a moment later); calling it from the
  console *after* the swap has visibly settled works immediately. Re-arm it with a short delay
  **after** the `setProjectJSON`/theme-swap block, not inline with it:
  ```javascript
  ixmaps.setProjectJSON(project);
  // ...removeTheme/define swap for the projection-specific ocean backdrop, if any...
  setTimeout(function () { try { ixmaps.setMapTool("info"); } catch (e) {} }, 400);
  ```
  Do this on every call that switches projection at runtime, in addition to the one-time
  `setMapTool("info")` call at initial map load (Hotspot #26) — see Hotspot #33.

### Graticule (world grid lines)
```javascript
(function() {
  var step = 10, features = [];
  for (var lon = -180; lon <= 180; lon += step) {
    var coords = [];
    for (var lat = -90; lat <= 90; lat += 2) coords.push([lon, lat]);
    features.push({ type:"Feature", geometry:{ type:"LineString", coordinates:coords }, properties:{} });
  }
  for (var lat = -80; lat <= 80; lat += step) {
    var coords = [];
    for (var lon = -180; lon <= 180; lon += 2) coords.push([lon, lat]);
    features.push({ type:"Feature", geometry:{ type:"LineString", coordinates:coords }, properties:{} });
  }
  myMap.layer("graticule")
    .data({ obj: { type:"FeatureCollection", features:features }, type: "geojson" })
    .binding({ geo: "geometry" })
    .type("FEATURE|SILENT")
    .style({ colorscheme: ["#7aaabb"], linewidth: 0.6 })
    .define();
})();
```
**Note:** `FEATURE|SILENT` layers do not need `value` in `.binding()` or `showdata` in `.style()` — omit both to avoid 'type not found' load errors. This is a scoped exception to Critical Rules 2/3 for `|SILENT` bases with no overlay (e.g. this decorative graticule) — see Rule 16a for why `|SILENT` on a base with an overlay is different (it kills the overlay's tooltip) and TROUBLESHOOTING.md § Tooltips Not Working.

Intermediate points every 2° ensure smooth curves in Lambert projection. Define graticule **before** the countries layer so it renders underneath.

---

**Map call sequence for a map built from scratch — emit these in this order:**
```javascript
const myMap = ixmaps.Map("map", { mapType, mode, legend, tools })  // 1. construct
    .view({ center: { lat: L, lng: G }, zoom: Z })                 // 2. view   — BEFORE options and layers
    .options({ objectscaling: "dynamic", normalSizeScale: "…" });   // 3. options — after view

myMap.layer("name") /* … */ .define();                             // 4. layers — last
```
- **`.view()` before any `.layer()`** is the load-bearing part: layer symbols are sized and
  positioned against the current view (`objectscaling:"dynamic"` derives symbol size from map
  scale), so the view must exist before a layer is defined against it.
- **`.view()` before `.options()`** matches API_REFERENCE.md (`.options()` — "call after
  `.view()` and before `.layer()`"). The engine tolerates the reverse, so this is
  canonicalisation for consistency — one sequence to emit, one to review against — not a bug
  fix. When *reading* an existing map, `.options()` before `.view()` is an accepted variant;
  leave it alone (see § Two Modes).

**Layer chain (order matters):**
```javascript
myMap.layer("name")
    .data({ url: "…", type: "csv" })   // OR obj: myArray
    .binding({ geo: "lat|lon", value: "fieldname", title: "label" })
    .filter('WHERE field == "value"')   // optional; use AND (not && /||) — OR is NOT implemented, see Hotspot #32
    .type("CHART|BUBBLE|SIZE|VALUES")
    .style({ colorscheme: ["#0066cc"], fillopacity: 0.7, showdata: "true" })
    .meta({ tooltip: "{{label}}: {{fieldname}}" })
    .title("Legend label")
    .define();
```

> Full `.options()` / `.style()` property reference → **API_REFERENCE.md § Map Constructor** and **§ Style Properties**

---

## Tooltip Mustache Reference

Tooltips in `.meta({ tooltip: "..." })` use `{{…}}` placeholders. Two prefixes control formatting:

| Syntax | Behaviour |
|--------|-----------|
| `{{fieldname}}` | ixmaps-formatted value — may apply number formatting, units, rounding |
| `{{raw.fieldname}}` | **Raw unformatted value** — bypasses all ixmaps formatting; use this when you want pre-formatted strings (e.g. `"1.234.567"` from `.toLocaleString()`) or exact string values |
| `{{theme.item.chart}}` | Renders the built-in chart SVG/HTML for this item |
| `{{theme.item.data}}` | Renders the built-in data table for this item |

**`raw.` is the escape hatch** — whenever ixmaps mangles a value (reformats numbers, truncates strings, adds units), use `{{raw.field}}` to get the original data value unchanged.

> ⚠️ **`raw.` bypasses auto-formatting — use it only when you do NOT want ixmaps to format the value** (e.g. a year `2025` that should not become `2.025`). For everything else use `{{field}}`.
>
> ⚠️ **`datafields` is only for restricting `{{theme.item.data}}`** — it filters which fields appear in the built-in data table. All data fields are automatically available as `{{field}}` in custom tooltip templates; no need to list them in `datafields`.
>
> | Goal | Syntax | Example output |
> |---|---|---|
> | Auto-formatted number | `{{freq}}` | `"8.519"` |
> | String field | `{{provincia}}` | `"PD"` |
> | Raw unformatted number (special cases only) | `{{raw.anno}}` | `2025` |
> | Built-in value+label display | `{{theme.item.data}}` | ixmaps default table |
>
> **Pattern for CHOROPLETH tooltips:**
> ```javascript
> .binding({ lookup: "istat", value: "media", title: "comune" })
> .style({ showdata: "true" })   // no datafields needed for custom tooltip fields
> .meta({ tooltip: "<b>{{comune}}</b> ({{provincia}} — {{regione}})<br>N: {{freq}}<br>Tot: {{ammk}} k€<br>{{theme.item.data}}" })
> // string/number fields via {{field}}; use {{theme.item.data}} for the bound value display
> ```

> ⚠️ **Generating this HTML via Python f-strings (or similar templating that treats `{{`/`}}` specially)?** Use **four** braces in the source (`{{{{field}}}}`) to get the required double-brace `{{field}}` in the output — an f-string's own escaping collapses `{{` → `{` and `}}` → `}`, so a single-escaped `{{field}}` in the source produces `{field}` in the emitted HTML, which ixMaps doesn't recognize as a tooltip placeholder.

### `{{theme.item.chart}}` on a CHOROPLETH → pulls a sibling CHART theme (not a histogram)

`{{theme.item.chart}}` does **not** always render the hovered theme's own chart. For a
**CHOROPLETH**, ixMaps' `__add_chart` scans all themes for a *sibling* chart theme to render
instead — so you can show a **per-feature line/sparkline (time series) inside a choropleth
tooltip** while the choropleth itself only carries a single value for colour. This is the
correct, native way to get "sparkline in the tooltip, not on the map" (no hand-rolled SVG).

The sibling is matched by **three conditions — all required**:

1. **Same base layer name** — the CHART theme must use the *same* `myMap.layer("NAME")` as the
   choropleth (so `szThemes` matches). Reuses the base geometry (see § Geometry Reuse).
2. **`szFlag` is a chart** — `CHART|…|PLOT|LINES` (or any `CHART`/`COMPOSECOLOR`).
3. **`title` binding == the choropleth's geo-key value** — ⚠️ **the trap.** CHART|PLOT items are
   keyed by *centroid coordinates*, so the primary key lookup fails and ixMaps falls back to
   matching the chart item's `szTitle` against the hovered choropleth's geo value
   (`hoveredItemId.split("::")[1]`). If you join on a **code** (base `id:"ISO3_CODE"`, choropleth
   `lookup:"countryiso3code"` → hovered item `…::IND`), the chart theme must bind
   **`title:"countryiso3code"`** (→ `szTitle "IND"`), **not** the human name. With the name the
   match silently fails and the tooltip shows the **class-distribution histogram** instead of the line.

**Switch the sparkline OFF the map but keep it in the tooltip** — give the CHART theme
scale-visibility thresholds so it isn't drawn at the working zoom, yet still feeds the tooltip:

```javascript
// choropleth: colour by latest year; its {{theme.item.chart}} will render the line below
myMap.layer("World_countries")
  .data({ obj: pivot, type: "jsondb" })
  .binding({ lookup: "countryiso3code", value: latestYear, title: "country_value" })
  .type("CHOROPLETH|QUANTILE|DOPACITYMAX")
  .style({ colorscheme: ["25","#F7FAF2","#669900"], showdata: "true", name: "choro" })
  .meta({ name: "choro", tooltip: "<b>{{country_value}}</b><br>{{theme.item.chart}}" })
  .define();

// sibling sparkline: SAME layer name, title == the join code, scale-gated off the map
myMap.layer("World_countries")
  .data({ obj: pivot, type: "jsondb" })
  .binding({ lookup: "countryiso3code", value: years.join("|"), title: "countryiso3code" }) // ← title = code
  .type("CHART|SYMBOL|SEQUENCE|PLOT|LINES|SIZE|AREA|LASTPOP|NOCLIP|BOX|BOTTOMTITLE|FAST")
  .style({
    colorscheme: ["#669900"], fillopacity: "0.1", scale: "0.06", linewidth: "10",
    maxvalue: "auto", xaxis: years.map(y => Number(y)%5===0 ? String(y) : " "),
    chartupper: "1:30000000", boxupper: "1:10000000", gridupper: "1:100000", // hidden at world zoom
    valuescale: "0",          // ← suppress per-point value labels → clean line (else cluttered)
    showdata: "true", name: "curves"
  })
  .meta({ name: "curves", tooltip: "{{theme.item.chart}}" })
  .define();
```

- `chartupper`/`boxupper`/`gridupper` keep the curve off the map until you zoom in; the tooltip
  chart renders regardless of those thresholds.
- If the choropleth join is by **name** instead of code, set the chart `title` to that same name field.
- Reference implementation: `flat_multi/.../pages/ACLED/political_violence.html`.

---

## Geometry Sources

**`geo: "geometry"` for GeoJSON point data** — works correctly with all CHART types.
ixmaps extracts full-precision coordinates directly from `Point.coordinates[lon,lat]`.
The `.type()` call (CHART|DOT, CHART|BUBBLE, etc.) controls the renderer — NOT the geo binding.
Use `geo: "geometry"` when source GeoJSON has Point geometry (preferred over property lat/lon fields which may be truncated).
Only use `geo: "lat|lon"` when the data has separate lat/lon columns (CSV, non-geometry JSON).

### World countries (GISCO — preferred over world-atlas)
```javascript
.data({ url: "https://gisco-services.ec.europa.eu/distribution/v2/countries/topojson/CNTR_RG_60M_2020_4326.json", type: "topojson" })
.binding({ geo: "geometry", id: "CNTR_ID", title: "NAME_ENGL" })
// ⚠️ Join field is CNTR_ID (ISO-2) — NOT CNTR_CODE
```
Scales: `60M` (default/world) · `20M` · `10M` · `3M` · `1M` (country zoom)

### Germany municipalities (LAU 2021)
```javascript
.data({ url: "https://cdn.jsdelivr.net/gh/gjrichter/geo@028b3fe/lau/germany_lau_2021_4326.topojson", type: "topojson" })
.binding({ geo: "geometry", id: "LAU_ID", title: "LAU_NAME" })
// LAU_ID = 8-digit AGS · LAU_NAME = name · POP_DENS_2021 = density (useful for alpha/DOPACITYMAX)
```

### NUTS1 Germany
```javascript
.data({ url: "https://gisco-services.ec.europa.eu/distribution/v2/nuts/topojson/NUTS_RG_60M_2021_4326_LEVL_1.json", type: "topojson" })
.filter('WHERE CNTR_CODE == "DE"')
.binding({ geo: "geometry", id: "NUTS_ID", title: "NUTS_NAME" })
// NUTS_ID examples: "DE1", "DEA"  (CNTR_CODE works for NUTS, unlike country data which uses CNTR_ID)
```

### Italy geometry sources (gjrichter/geo)

**Municipalities (comuni) — ISTAT, ~8 000 polygons, 500m simplified:**
```javascript
.data({ url: "https://raw.githubusercontent.com/gjrichter/geo/main/italy/boundaries/italy_istat_municipalities_4326_500m.topojson", type: "topojson" })
.binding({ geo: "geometry", id: "com_istat_code_num", title: "name" })
// com_istat_code     = zero-padded STRING "028001"  ← do NOT use for joins unless your data also has zero-padded strings
// com_istat_code_num = plain INTEGER    28001       ← use this for joins with ISTAT CSV data
// Useful properties: com_istat_code_num, com_istat_code, name, prov_istat_code_num, reg_istat_code_num
```

> ⚠️ **Geometry version pitfall** — the `main` branch of gjrichter/geo was updated to **2026 ISTAT codes** on 2026-03-24. Official data sources (MEF IRPEF, ISTAT CSVs) still use **2024 codes**. Using `main` will silently break the join for all Sardinian municipalities and any others renumbered in 2026. Pin to commit `0153a0e14da5dae877b8c94d6deb11f210d4660a` for 2024-compatible codes:
> ```
> https://raw.githubusercontent.com/gjrichter/geo/0153a0e14da5dae877b8c94d6deb11f210d4660a/italy/boundaries/italy_istat_municipalities_4326_500m.topojson
> ```

> ⚠️ **ISTAT code join pitfall** — the geometry exposes two variants of the municipality code:
> - `com_istat_code` is a **zero-padded string** (`"028001"`) — it will **not** match integers or un-padded strings from CSV data
> - `com_istat_code_num` is a plain **integer** (`28001`) — use this when your lookup data comes from ISTAT CSVs where codes are stored as numbers
>
> Always verify which variant matches your data before writing the join. Mismatching types silently renders only a fraction of features (those whose string representation happens to match).

⚠️ Use `flushPaintShape: 1000000` in `.options()` when rendering all 8 000 polygons to avoid hangs.

> ⚠️ Local `file://` URLs are blocked by browser CORS — always use CDN or inline `obj:`
> Full geometry sources list → **API_REFERENCE.md § Data Configuration**

---

## Multi-Layer Join Pattern

When joining external data to geometry (e.g. TopoJSON + CSV statistics), the overlay layer
**must reuse the FEATURE base's name** so it joins onto its geometry (see critical rule 15).

> Full real-world worked example (TopoJSON + CSV, 3-layer choropleth + bubble join) → **example-multi-layer-join.md**

### A. Static overlay (base + one data-driven layer)

```javascript
// Step 1 — FEATURE base (geometry + id field for join)
myMap.layer("regions")
    .data({ url: "regions.topojson", type: "topojson" })
    .binding({ geo: "geometry", id: "reg_code", title: "reg_name" })
    .type("FEATURE")
    .style({ colorscheme: ["#ccc"], fillopacity: 0.1, linecolor: "#666", linewidth: 0.5, showdata: "true" })
    .define();

// Step 2 — CHOROPLETH overlay (SAME layer name "regions", NO FEATURE flag, lookup joins to id)
myMap.layer("regions")
    .data({ url: "data.csv", type: "csv" })
    .binding({ lookup: "csv_code_col", value: "metric" })
    .type("CHOROPLETH|QUANTILE")
    .style({ colorscheme: ["#eee", "#00468b"], fillopacity: 0.75, showdata: "true" })
    .meta({ tooltip: "{{reg_name}}: {{metric}}" })
    .define();
```

**Critical:** `id` values in geometry must match `lookup` values in CSV exactly (case-sensitive).
Always inspect both sources to confirm field names before writing the join.

### B. Swappable themes on the same base (remove-then-define)

For apps where the user flips between multiple visualizations of the same geometry
(choropleth / dominant / sparkline / arrows / etc.), use **one FEATURE base** plus a single
swappable overlay always redefined under the **same layer name** as the base. Do **not**
create a separate layer per theme.

**Two identifiers — don't confuse them:**
- **Layer name** (`myMap.layer("comuni")`) = GEOMETRY bucket — must equal the FEATURE base's name (not unique).
- **meta.name** (`.meta({name: "pie-theme-rd"})`) = THEME identity — unique, and the **key that drives replacement**.
- ⚠️ **Never make these two the same string** (see Rule 24) — reusing one string for both has caused failures. Keep the `meta.name` distinct from the layer name.

⚠️ **The overlay always needs an explicit `id` in its `.binding()`, matching the base's `id`** —
even when the overlay's own `.data()` call re-supplies full `geo` geometry from the *same* source
file as the base (not a separate lookup CSV). Omitting it silently joins only a fraction of
records (confirmed: ~14% of a 7,894-feature set, with no error) — see Hotspot #25.

**Replacement is automatic by `meta.name`.** Adding a theme whose `meta.name` already exists
on the map *replaces* the existing one in place. So there are two ways to swap:

- **Same `meta.name` on every swap → automatic replace** (simplest; no `removeTheme` needed).
- **Different `meta.name` per theme** (e.g. one per year/category) → each `.define()` ADDS a
  new theme, so you must track the previous name and call `api.removeTheme(prev)` before
  defining the next, or they stack. The example below uses this form.

The **`"direct"` flag** (aliases **`"fast"`**, **`"silent"`**), passed as the 2nd argument to
`.layer(...)`, makes the add/replace *fluent* — it suppresses the loading spinner and status
messages and skips the intermediate render flash during a replace. It does **not** decide
*whether* a replace happens (that's `meta.name`); it only makes the transition smooth. The
same flag also works as a mode on `changeThemeStyle`.

```javascript
// ONE FEATURE base — defined once, no meta.name so it's never removed
// ⚠️ NO |SILENT here: the swappable overlays below carry tooltips, and |SILENT
// on this base would kill hover for all of them (see Rule 16a).
myMap.layer("comuni")
    .data({ url: GEO_URL, type: "topojson" })
    .binding({ geo: "geometry", id: "com_istat_code_num", title: "name" })
    .filter("WHERE reg_istat_code_num == 1")
    .type("FEATURE")
    .style({ colorscheme: ["#d9e4dc"], fillopacity: 0.55, linecolor: "#8a9d8c", linewidth: 0.2, showdata: "true" })
    .define();

// Remove-then-define swapper.
// removeTheme lives on the embedded Api (not the MapBuilder shim), so the call
// goes through myMap.then(api => ...). Defining the new layer INSIDE the same
// callback guarantees remove-before-add ordering.
let ACTIVE_THEME_NAME = null;

function setTheme({ id, value, value100, type, style, tooltip }) {
  const themeName = "theme-" + id;
  const prev      = ACTIVE_THEME_NAME;
  const bind = { lookup: "ISTAT", title: "COMUNE", value };
  if (value100) bind.value100 = value100;

  myMap.then(api => {
    if (prev) { try { api.removeTheme(prev); } catch(e){} }

    const meta = { name: themeName };
    if (tooltip) meta.tooltip = tooltip;

    myMap.layer("comuni")                                 // ← same name as FEATURE base
      .data({ obj: DATA, type: "json", cache: "true" })
      .binding(bind)
      .type(type)
      .style(Object.assign({ showdata: "true" }, style))
      .meta(meta)                                         // ← meta.name = theme handle
      .define();

    ACTIVE_THEME_NAME = themeName;
  });
}

// Each sidebar click = one setTheme({id, ...}) call — overlays REPLACE, not stack.
setTheme({ id: "rd",        value: "% di RD [RD/RT]",
           type: "CHOROPLETH|QUANTILE|VALUES",
           style:{ colorscheme:["5","#FF4800","#7CB832","auto","#F7FA7A"], title:"% RD" }});
setTheme({ id: "sparkline", value: "% RD 2011|% RD 2012|% RD 2013|% RD 2014",
           type: "CHART|SYMBOL|PLOT|LINES|AREA|AGGREGATE|RECT|GRIDSIZE|MEAN",
           style:{ gridwidthpx:"150", xaxis:["2011","2012","2013","2014"] }});
```

**Common mistakes — DO NOT DO THIS:**
```javascript
// ❌ Different layer names → overlay has no geometry to bind to
myMap.layer("comuni").type("FEATURE").define();
myMap.layer("theme").type("CHOROPLETH")...   // blank / error

// ❌ No meta.name + no removeTheme → every click STACKS a new theme on the map
function setTheme(opts) {
  myMap.layer("comuni").type(opts.type)....define();   // stacks forever
}

// ⚠️ "direct"/"fast"/"silent" is a FLUENCY flag, NOT the replace mechanism.
// Replacement is keyed on meta.name; the flag only suppresses spinner/messages
// and the intermediate render flash. With NO meta.name it still stacks.
myMap.layer("comuni", "direct")...   // smooth, but only replaces if meta.name matches
```
For replacement, give each swap a **stable `meta.name`** (automatic replace) — or use
**different** names plus an explicit `removeTheme(prev)`. Either way the layer name stays
`"comuni"` so the overlay reuses the base geometry.

---

## Sparklines (CHART|SYMBOL|PLOT|LINES)

Two distinct patterns depending on data shape:

### Pattern A — single column, year as category (raw events)
```javascript
.binding({ geo: "lat|lon", value: "year" })   // year field = categorical x-axis
.type("CHART|SYMBOL|PLOT|LINES|AREA|FADE|LASTARROW|NOCLIP|GRIDSIZE|CATEGORICAL|AGGREGATE|RECT|SUM|FIXSIZE")
.style({
  gridwidthpx: "100", normalsizevalue: "30", markersize: 2,
  colorscheme: ["#00e5ff"], fillopacity: 0.5,
  values: ["2020","2021","2022","2023"],  // ordered x-axis categories (also controls sort)
  showdata: "true"
})
// CATEGORICAL+AGGREGATE+RECT+SUM = aggregation semantics (NOT style)
// AREA|FADE|LASTARROW|FIXSIZE = visual style only
// FIXSIZE: all sparks same size; normalsizevalue controls chart scale (larger = smaller sparks)
// markersize: controls LASTARROW arrow head size (default ~8; use 1–3 for smaller arrows)
// ⚠️ normalsizevalue does NOT control arrow size — use markersize for that
// LASTARROW = arrow marker on last point  |  LASTPOP = dot/pop marker on last point (use one or the other)
// MAX/MIN/MEAN/COUNT/SUM = aggregation modifiers — compute cell aggregate value; NOT sparkline visual markers
```

**BOX|GRID and XAXIS — only add on explicit user request:**
- Default (no BOX|GRID): sparkline appears as a lightweight curve/arrow on the map; xaxis/chart still visible in tooltip via `{{theme.item.chart}}`
- `BOX|GRID|XAXIS` + `label:[]+xaxis:[]` in style: renders grid boxes + x-axis labels ON the map — heavier, less performant; use only when user wants to see the grid/axes directly on the map
- `BOX` alone (without GRID): adds a background box; can be combined with `TITLE` or `BOTTOMTITLE` for chart titles; scale-dependent via `boxupper`/`boxlower` and `titleupper`/`titlelower` style params

```javascript
// Only when user explicitly wants grid + axis labels on map:
.type("...NOCLIP|BOX|GRID|GRIDSIZE|XAXIS|CATEGORICAL|AGGREGATE|RECT|SUM|FIXSIZE")
.style({
  values: ["2020","2021","2022","2023"],
  label:  ["2020","2021","2022","2023"],
  xaxis:  ["2020","2021","2022","2023"],
})
```

### Pattern B — multiple pre-aggregated columns
```javascript
.binding({ geo: "lat|lon", value: "val2020|val2021|val2022|val2023" })  // chain columns
.type("CHART|SYMBOL|PLOT|LINES|AREA|FADE|LASTARROW|NOCLIP|GRIDSIZE|FIXSIZE")
// No CATEGORICAL or SUM — data already aggregated
```

> Full sparkline reference, FIXSIZE/normalsizevalue details, point-anchored variant → **API_REFERENCE.md § CHART|SYMBOL|PLOT|LINES**

---

## Animated / Timeseries Maps

⚠️ `mapInstance` must be captured inside `.then(function(map) { mapInstance = map; })` — it is NOT the return value of `ixmaps.Map()`, which is a **MapBuilder**. The real map instance is only available inside `.then()`.

### Remove-then-define (needed only when meta.name varies)
```javascript
// This example gives each year a DIFFERENT meta.name ("year-2023", "year-2024"),
// so each showYear() would ADD a new theme — removeTheme(prev) tears down the
// previous one first. Simpler alternative: use ONE stable meta.name for all years;
// then each define auto-replaces and no removeTheme is needed.
let ACTIVE = null;   // meta.name of the currently-drawn theme

function showYear(year) {
    const themeName = "year-" + year;
    const prev = ACTIVE;
    myMap.then(api => {
        if (prev) { try { api.removeTheme(prev); } catch(e){} }
        myMap.layer("countries")                                   // SAME name as FEATURE base
            .data({ obj: yearData[year], type: "json" })
            .binding({ geo: "lat|lon", value: "metric" })
            .type("CHART|BUBBLE|SIZE|VALUES")
            .style({ colorscheme: ["#0066cc"], fillopacity: 0.7, showdata: "true" })
            .meta({ name: themeName, tooltip: "{{label}}: {{metric}}" })
            .define();
        ACTIVE = themeName;
    });
}
showYear("2023");
```
**Key:** replacement is automatic when the new theme's `meta.name` matches one already on the
map; `removeTheme` is only needed when the names differ (as above). `removeTheme` lives on the
embedded Api — reach it via `myMap.then(api => api.removeTheme(name))`. The
`"direct"`/`"fast"`/`"silent"` flag (2nd arg to `.layer(...)`) just makes the swap fluent
(no spinner / no intermediate render flash); it is not itself the upsert. Theme `name` in
`.meta()` is the replace key; layer name (`"countries"`) is the geometry bucket.

> Time slider (`timefield` in `.binding()`), `setThemeTimeFrame()` → **API_REFERENCE.md § Time Slider**

---

## Key Style Properties (quick ref)

| Property | Notes |
|----------|-------|
| `colorscheme` | Array of hex colors. `["100","tableau"]` for auto-palette. `["N", colorA, colorB, colorC]` = N-class gradient auto-swept start→middle→end (middle auto-computed if `colorC` omitted) — caps at 3 anchor colors, does NOT extend to more; a bare list of colors with no leading count (`["c1","c2","c3","c4","c5"]`) maps 1:1 to classes instead (no interpolation) — see API_REFERENCE.md § Color Properties. A bare string (`colorscheme: "#0066cc"`) is accepted **only** for a single color — **always use the array form** (`["#0066cc"]`, `["none"]`) as best practice |
| `fillopacity` | 0–1. Fades only the fill. `opacity` also exists but fades the whole element (fill + stroke) — use `fillopacity` unless the border should fade too |
| `linecolor` / `linewidth` | NEVER `strokecolor` / `strokewidth`; `linecolor` accepts a single string **or** an array `["#c1","#c2"]` — array form required for `VECTOR\|GRADIENT` |
| `scale` | Uniform size multiplier (start at 1). On a chart/symbol theme this resizes the symbol; on a separate *label/text overlay* theme (some styles render on-map value text as its own theme layered over the chart, not as part of the chart theme) it resizes that theme's own text — check which theme is actually drawing the visible text before deciding which knob to turn |
| `valuescale` | Size of the value-label text rendered **by the theme that owns it** (e.g. `VALUES`-generated numbers on a CHOROPLETH/chart theme). Not interchangeable with a *different* label-overlay theme's `scale` (see above) — these are separate knobs on separate themes even though both visually affect "the text size" |
| `normalsizevalue` | Data value that maps to "normal" display size. **Higher = SMALLER bubbles** — a larger reference value means most real data values fall below it, so bubbles render smaller. E.g. `"1000"` → smaller bubbles than `"300"`. |
| `gridwidthpx` | Grid cell size for aggregate layers, unitless string (e.g. `"5"`). Canonical form — same name `changeThemeStyle` uses. (`gridwidth: "5px"` is an accepted variant you'll see in existing maps.) |
| `rangecentervalue` | Diverging center; requires EVEN number of colors |
| `ranges` | Explicit class breaks (n+1 values for n colors) |
| `values` | Category list for CATEGORICAL (must be **strings**). These strings are shown **verbatim** as the legend row labels — there's no separate display-label mapping, so write the full human-readable category name here (e.g. `"Ruled misleading / banned"`), not a terse internal code, if the map has a visible legend |
| `align` | Chart anchor: `"left"` `"right"` `"top"` `"bottom"` `"above"` `"below"` |
| `sizepow` | Power for size scaling: radius ∝ value^(1/sizepow). `1` = linear (width ∝ value); `2` = area proportional to value (cartographic standard, flattens apparent contrast); `3` = volume proportional to value (even flatter). Higher = smaller arrows for small values appear relatively larger |
| `rotation` | Rotate chart symbol in degrees (e.g. `35` for a tilted arrow) |
| `rangescale` | Scale factor applied after range computation |
| `aggregationfield` | Field used as aggregation key when `AGGREGATE` is set |
| `titlefield` | Field used as chart title label (overrides binding `title`) |
| `datafields` | Array of extra fields carried through to tooltip: `["field1","field2"]` — access as `{{raw.field1}}` |
| `textscale` | Scale factor for label text rendered on the chart |
| `boxupper` / `boxlower` | Scale-dependent box visibility threshold, e.g. `"1:250000"` — box shown only when map scale ≤ 1:250k |
| `valuesupper` / `valueslower` | Scale-dependent value label visibility threshold |
| `valuedecimals` | Decimal places for rendered value labels |
| `minvaluesize` | Minimum pixel size below which no chart symbol is drawn |
| `units` | String appended to rendered value labels, e.g. `"%"`, `"€"`, `"km"` |
| `sizefield` | Data column that drives symbol SIZE independently from the `value` (color) field — use with `CATEGORICAL` to combine category color + numeric size on one layer |
| `dopacitypow` | Power curve exponent for `DOPACITY` opacity mapping (default ≈ 1; `2` = quadratic, exaggerates contrast) |
| `dopacityscale` | Multiplier applied after opacity calculation — stretches the opacity range |
| `gridwidthpx` | (see Key Style Properties) supports `"factor"` mode in `changeThemeStyle` for runtime zoom-scaling |
| `shadow` | `"true"` adds a real SVG drop-shadow filter — works on `FEATURE`/`CHOROPLETH` polygons **and** `CHART` symbols/bars (verified in engine source, `maptheme.js` `chartMap`/FEATURE branch — see API_REFERENCE.md § Shadow Properties). Not the same thing as the `SHADOW` token inside a `CHART\|USER` type string, which only triggers a hand-drawn shadow shape in the `pinnacleChart`/`arrowChart` D3 scripts |
| `shadowupper` / `shadowlower` | Scale-gate for the shadow filter only (shape still renders outside the range, just without shadow) |
| `maxshadow` | Cap on simultaneously-shadowed items (perf/crash guard on large point datasets) |

**Trees (street-level) sizing baseline with `|GLOW`:**
- Use this as a reliable starting point for urban tree inventories (diameter in cm):
  - `objectscaling: "dynamic"`
  - `normalSizeScale: "5000"` (street-detail zoom reference)
  - `normalsizevalue: "220"` (higher value keeps bubbles controlled)
  - `scale: 0.32` (reduce apparent size added by `|GLOW`)
- Rule of thumb: with `|GLOW`, start with a **smaller `scale`** than non-glow bubbles.

> Complete style properties, dynamic opacity, diverging scales, categorical color binding → **API_REFERENCE.md § Style Properties**

---

## Runtime Controls (Filters & Layer Toggles)

Interactive controls that modify the map after load. What's available:

- **Filter across layers** — `changeThemeStyle(themeName, "filter:WHERE …", "set")` via `myMap.then(map => …)`; aggregate layers (grids, sparklines) re-aggregate. Every responsive layer needs `name` in `.meta()`.
- **Resize all charts** — `ixmaps.changeThemeStyle(null, null, 'scale:' + v, 'set')` (null = every non-FEATURE theme, no `meta.name` needed) → **RUNTIME_CONTROLS.md**
- **Region selector + zoom** — a `<select>` that filters all named themes and pans/zooms via `myMap.view()`; `<option value="">` is the "show all" sentinel.
- **Toggle visibility** — `ixmaps.hideTheme(name)` / `ixmaps.showTheme(name)` are global, so a user-triggered toggle (button, checkbox) can call them directly without `.then()`. To start a layer **hidden on load**, use `visible: false` in `.style()` — do **not** try to achieve it by calling `hideTheme` from `myMap.then()` at init time (the theme may not exist yet). See RUNTIME_CONTROLS.md § Initially hidden layer.
- **Isolate categories** — `ixmaps.markThemeClass(name, idx)` / `unmarkThemeClass(name, idx)` for clickable legends (idx = position in the `values:` array).
- **Highlight a single item** — `ixmaps.highlightThemeItems(name, itemId)` / `ixmaps.clearHighlight()`; e.g. legend-row hover highlighting its map feature. `itemId` is the full SVG group id `"<layerName>::<lookupValue>"`, not the bare lookup value — passing the bare value silently no-ops.
- **React to zoom/pan/click** — `myMap.on("zoomend moveend click mouseover …", handler)`. `ixmaps.getZoom()` / `getCenter()` are global (no `.then()`); `getBounds()` returns a flat `[swLat, swLng, neLat, neLng]` array.
- **Persist view in URL** — read `lat/lng/zoom` params on init, write back with `history.replaceState` (debounced); wrap (don't overwrite) an existing `htmlgui_onZoomAndPan`.

> ⚠️ `ixmaps.map().changeThemeStyle()` returns `{szMap:null}` and silently no-ops — always go through `myMap.then(map => …)`.
> Full patterns + copy-paste code (filter helper, region selector + overlay CSS, hide/show, mark/unmark, highlight, `.on()` event tables, URL-sync wrapper) → **RUNTIME_CONTROLS.md**

---

## Special Patterns (quick ref)

**Dominant class per record, from several piped fields (e.g. "which age band is this comune's peak?"):**
```javascript
.binding({ lookup: "joinField", value: "class1|class2|class3|...classN", title: "nameField" })
.type("CHOROPLETH|DOMINANT")
.style({ colorscheme: [...N distinct colors], values: ["class1","class2",...,"classN"], showdata: "true" })
```
Picks, **per record**, whichever piped field most exceeds the mean of *that record's own* N fields — e.g. with 21 age-band columns piped in, colors each comune by its own peak age band relative to its own age profile. Confirmed with a controlled 3-field test (Roma 2024 male: `0-4`=1.71, `50-54`=4.07, `100+`=0.01 → mean 1.93) — renders `50-54` (the correct within-record winner, 211% of that 3-field mean), matching a from-scratch calculation exactly.

> ⚠️ **`|PERCENTOFMEAN` changes the comparison axis entirely** — `CHOROPLETH|DOMINANT|PERCENTOFMEAN` compares each piped field against **that field's own mean across all records** instead (e.g. Roma's `100+` share vs. the *national average* `100+` share), not against the other fields within the same record. On the same Roma test, adding `PERCENTOFMEAN` picked `100+` as "dominant" — a band where Roma's raw value (0.0085%) is negligible in absolute terms, but far above what `100+` typically looks like nationally (most small comuni round to 0% for a band that rare). Confirmed reproducible, not a bug: it answers a legitimately different question ("which class is this record the biggest *national* outlier for", vs. plain `DOMINANT`'s "which class dominates *within* this one record"). Reach for whichever axis the question actually needs — they are easy to conflate since both render, both report `theme done`, and neither errors.

**Categorical color binding (pin specific colors to values):**
```javascript
.type("CHART|BUBBLE|CATEGORICAL")
.style({ colorscheme: ["#4fc3f7","#ffb300","#ef5350"], values: ["C","F","R"], showdata: "true" })
```
> ⚠️ **Always use `values`** with CATEGORICAL — without it, ixMaps assigns colors by **order of first occurrence** in the dataset, not by category name. This means color assignments change depending on data order and are unpredictable. `values` is the only reliable way to pin a specific color to a specific category.

**CATEGORICAL + bubble size from a numeric field (color by category AND size by value — single layer):**
```javascript
.binding({ geo: "lat|lon", value: "categoryField", title: "label", size: "numericField" })
.type("CHART|BUBBLE|CATEGORICAL|GLOW")
.style({ colorscheme: ["#4fc3f7","#ffb300","#ef5350"], values: ["C","F","R"], normalsizevalue: "80", showdata: "true" })
```
> Add `size: "numericField"` to `.binding()` to drive bubble radius from a numeric column independently from the category `value` field. This avoids needing a separate `SIZE|VALUES` layer when you want both category color and numeric sizing.
> ⚠️ This is the **only** working way to get size + categorical color on one `BUBBLE` layer — `style.colorfield` looks like the natural fit (it's how CHOROPLETH/VECTOR/DOT do it) but is silently broken for BUBBLE, see Silent Failure Hotspot #22.

**...with the real number displayed too (on-bubble label + tooltip), not the category code:**
```javascript
.binding({ geo: "lat|lon", value: "categoryField", title: "label", size: "numericField" })
.type("CHART|BUBBLE|SIZE|CATEGORICAL|VALUES|DTEXT|VALUEBACKGROUND|SUM")
.style({
    colorscheme: ["#4fc3f7","#ffb300","#ef5350"], values: ["C","F","R"],
    valuefield:  "numericField",   // ← mirrors size back in as the displayed value
    normalsizevalue: "80", showdata: "true"
})
```
> Without `valuefield`, `{{theme.item.data}}`/the on-bubble label show the internal class index (or `1`), not `numericField`'s real value — `binding.value` is spent driving color, so the engine has nothing else to display by default. Set `style.valuefield` to the **same field name as `binding.size`** and the engine substitutes that field's value for display (maptheme.js: `szValueField == szSizeField` → shows the size value) without disturbing the color binding.
> Add `|SUM` to `.type()` to make legend rows show the **sum** of `valuefield`/size across each category's items (e.g. total population per class) instead of a per-class mean/representative value.

**Urban trees preset (species color + diameter size + GLOW):**
```javascript
.binding({ geo: "lat|lon", value: "SPECIE", size: "DIAMETRO", title: "LUOGO" })
.type("CHART|BUBBLE|CATEGORICAL|GLOW")
.style({
  colorscheme: [...],
  values: [...],               // species list, fixed order
  normalsizevalue: "220",
  scale: 0.32,
  fillopacity: 0.8,
  showdata: "true"
})
// map options: objectscaling:"dynamic", normalSizeScale:"5000"
```

**Dynamic opacity from a field:**
```javascript
.type("CHART|BUBBLE|SIZE|DOPACITYMAX")
.binding({ geo: "lat|lon", value: "count", alpha: "density" })
```

**Glow effect:**  add `|GLOW` to any CHART type

**Flows with animated dashes:**  `CHART|VECTOR|BEZIER|POINTER|DASH`

**CHART|USER — custom draw functions (pinnacleChart, arrowChart):**

Scripts required — load after `ixmaps.js`, order between them does not matter:

| Draw function | Scripts needed |
|---|---|
| `arrowChart` | `d3.v3.min.js` + `arrow_chart.js` |
| `pinnacleChart` | `d3.v3.min.js` + `chart.js` + `arrow_chart.js` |

```html
<!-- arrowChart only -->
<script src="https://d3js.org/d3.v3.min.js"></script>
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@1/usercharts/d3/arrow_chart.js"></script>

<!-- pinnacleChart (also needs chart.js) -->
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@1/usercharts/d3/chart.js"></script>
```

The `userdraw` style property names the draw function (`"pinnacleChart"` or `"arrowChart"`).
Key type modifiers used with USER charts:

| Modifier | Role |
|---|---|
| `DIFFERENCE` | computes `value[1] − value[0]` from a `"a\|b"` binding |
| `NONEGATIVE` | **render flag** — suppresses drawing the chart symbol where the computed value ≤ 0 (data row is still processed; only rendering is skipped) |
| `RELOCATE` | relocates the chart symbol to the geometry centroid |
| `BOX` | adds a background box behind the label |
| `BOTTOMTITLE` | places title below the chart symbol |
| `NOLEGEND` | excludes this layer from the map legend |

**Split-winner pattern** — two layers from one dataset, no pre-filtering needed:
```javascript
// Layer A — shows only communes where Sì wins (voti_si − voti_no > 0)
myMap.layer("comuni")
    .data({ url: DATA_URL, type: "csv" })
    .binding({ lookup: "cod_istat", value: "voti_no|voti_si", title: "desc_com" })
    .type("CHART|USER|3D|DIFFERENCE|AGGREGATE|RECT|RELOCATE|SUM|VALUES|NONEGATIVE|BOX|BOTTOMTITLE|NOLEGEND")
    .style({
        name:             "chart_si",
        userdraw:         "pinnacleChart",
        colorscheme:      SI_COLORS,
        sizepow:          2,
        normalsizevalue:  1000000,
        aggregationfield: "desc_com",
        titlefield:       "desc_com",
        datafields:       ["desc_com","desc_prov","margin_f"],
        showdata:         "true"
    })
    .meta({ name: "chart_si", tooltip: "{{desc_com}}<br>voti in più Sì: {{raw.margin_f}}" })
    .define();

// Layer B — shows only communes where No wins: swap binding order, NONEGATIVE drops the rest
myMap.layer("comuni")
    .data({ url: DATA_URL, type: "csv" })
    .binding({ lookup: "cod_istat", value: "voti_si|voti_no", title: "desc_com" })  // ← swapped
    .type("CHART|USER|3D|DIFFERENCE|HEADTAIL|AGGREGATE|RECT|RELOCATE|SUM|VALUES|NONEGATIVE|NOLEGEND")
    .style({ name: "chart_no", userdraw: "pinnacleChart", /* ... */ showdata: "true" })
    .meta({ name: "chart_no", tooltip: "..." })
    .define();
```
> Binding order determines sign: `"a|b"` → `b − a`. With `NONEGATIVE`, only locations where the result > 0 get a chart drawn. Swapping `a` and `b` between two layers gives "A wins" vs "B wins" without any data pre-processing.
> `{{raw.fieldname}}` in tooltip accesses fields listed in `datafields` — useful for pre-formatted strings (e.g. `"12.345"` from `.toLocaleString()`).

**Rotated arrowChart wrapper** — tilt arrows left/right to distinguish two groups visually:

Redirect `args.target` to a rotated child `<g>` before calling the standard `arrowChart`, then restore it. The outer group keeps its ixmaps-assigned translate; only the drawn shapes rotate.

```javascript
window.ixmaps = window.ixmaps || {};

function makeRotatedArrowChart(angle) {
  return function(SVGDocument, args) {
    var origTarget = args.target;
    var rotG = d3.select(origTarget)
                 .append("g")
                 .attr("transform", "rotate(" + angle + ")")
                 .node();
    args.target = rotG;
    var result = ixmaps.arrowChart(SVGDocument, args);
    args.target = origTarget;
    return result;
  };
}
ixmaps.arrowChartLeft_init  = function(s,a) { if (typeof ixmaps.arrowChart_init === "function") ixmaps.arrowChart_init(s,a); };
ixmaps.arrowChartRight_init = function(s,a) { if (typeof ixmaps.arrowChart_init === "function") ixmaps.arrowChart_init(s,a); };
ixmaps.arrowChartLeft  = makeRotatedArrowChart(-15);   // ← tilts left  (e.g. CS/left bloc)
ixmaps.arrowChartRight = makeRotatedArrowChart(+15);   // → tilts right (e.g. CDX/right bloc)
```

Then use `userdraw: "arrowChartLeft"` / `userdraw: "arrowChartRight"` in `.style()`.

**Simultaneous theme stacking on one layer** — two themes rendered at the same position:

Calling `.define()` multiple times on the same layer name *adds* themes (they stack). Use this when you need two independent visual signals at the same geo-coordinates (e.g. one red arrow group + one blue arrow group). Each theme must have a distinct `name` in `.meta()` so they can be removed independently.

```javascript
// Both themes render simultaneously on layer "sedi"
// Pre-filtered: csWins has only sedes where CS leads; cdWins only where CDX leads
myMap.layer("sedi")
  .data({ obj: csWins, type: "json" })
  .binding({ geo: "sez_da", value: "margin" })
  .type("CHART|USER|SIZE|VALUES")
  .style({ userdraw: "arrowChartLeft", colorscheme: ["#e74c3c","#e74c3c"],
           normalsizevalue: 100, rangescale: 0.5, fillopacity: 0.85,
           showdata: "true", units: " voti", valuedecimals: 0 })
  .meta({ name: "cs_dom", title: "CS in testa", tooltip: "..." })
  .define();                               // ← adds theme, does NOT replace

myMap.layer("sedi")
  .data({ obj: cdWins, type: "json" })
  .binding({ geo: "sez_da", value: "margin" })
  .type("CHART|USER|SIZE|VALUES")
  .style({ userdraw: "arrowChartRight", colorscheme: ["#2980b9","#2980b9"],
           normalsizevalue: 100, rangescale: 0.5, fillopacity: 0.85,
           showdata: "true", units: " voti", valuedecimals: 0 })
  .meta({ name: "cd_dom", title: "CDX in testa", tooltip: "..." })
  .define();                               // ← stacks on top of cs_dom

// To refresh: remove both by name, then redefine
myMap.then(function(api) {
  try { api.removeTheme("cs_dom"); } catch(e) {}
  try { api.removeTheme("cd_dom"); } catch(e) {}
  // ... redefine both
});
```

> ⚠️ Stacking only works correctly when the two datasets are **mutually exclusive** per feature (e.g. pre-filtered so each sede appears in at most one theme). If the same `sez_da` id appears in both, both themes draw at that location and visually overlap.

**Invisible point anchor layer** — load centroid geometry without rendering anything:
```javascript
// Required when CHART|USER layers need to snap to precise urban centroids
// For POINT geometry: colorscheme:["none"] + scale:0 suppress the dot completely.
// (Do NOT rely on fillopacity:0 — ixMaps coerces it to 1, so it never hides anything.)
myMap.layer("centroids")
    .data({ url: CENTROIDS_URL, type: "geojson" })
    .binding({ geo: "geometry", id: "PRO_COM", title: "PRO_COM" })
    .type("FEATURE|NOLEGEND")
    .style({
        colorscheme: ["none"],
        scale:       0,         // ← required for point geometry
        linecolor:   "none",
        linewidth:   0,
        showdata:    "true"
    })
    .define();
```

> Diverging scales, density patterns, road-tracing, SEQUENCE charts → **API_REFERENCE.md § Special Cases**
> Complete working examples → **EXAMPLES.md**
> Data preprocessing (data.js) → **DATA_JS_GUIDE.md**
> Symbols/icons → **SYMBOLS_GUIDE.md**
> Computed layers via external libs (Turf.js), weighted KDE heatmap → **EXTENSIONS_GUIDE.md**
> Troubleshooting → **TROUBLESHOOTING.md**

---

## Facet Sidebar (filter panel updated on zoom/pan)

A clickable facet panel that auto-updates on every zoom/pan/filter. Requires three CDN plugins (`format.js`, `facet.js`, `show_facets.js`), a sidebar `<div id="show-facets-div">`, an override of `ixmaps.statistics` (calls `ixmaps.data.getFacets` → `showFacets`), wired via `myMap.on("layerdraw", …)`. Pass `"NONUMERIC"` to `getFacets` for numeric-looking category fields; a facet field matching the theme's `value` binding auto-picks up theme colors.

> Full sidebar HTML/CSS, `ixmaps.statistics` hook, layerdraw wiring, clear-filter, button-style overrides → **FACETS_GUIDE.md**

---

## Overlay Indicator Layer (small status dot on top of main bubbles)

A second `CHART|BUBBLE|CATEGORICAL|NOLEGEND` layer drawn over the main bubbles to show a per-item status flag (risk class, alert state) without touching the primary colors. Add a constant `_dot` size field, filter to only meaningful states, use `scale: ~0.1` + `align: "bottom"`. `NOLEGEND` **must** be in the type string so the layerdraw/statistics handler skips it.

> Full pattern, key rules, define-then-add (`ixmaps.layer(...).define()` + `myMap.layer(theme, "direct")`) → **FACETS_GUIDE.md § Overlay Indicator Layer**

---

## Computed Layers via External Libraries (Turf.js) — e.g. weighted KDE heatmap

Use an external geospatial-JS library (Turf.js, d3-contour, …) to **compute a GeoJSON layer at runtime** from the visible records of an existing theme, then inject it as a normal ixMaps layer. Flagship case: a **weighted KDE "danger index" heatmap** — each point weighted by severity (e.g. `morti*10 + feriti`), Gaussian density on a zoom-adaptive grid, rendered as stacked `turf.isobands` polygons. Capture the map promise (`var _mapPromise = ixmaps.Map(...)`), read `objTheme.objTheme.dbRecords/dbFields` + `indexA/itemA/dbIndexA` for visible rows (coords from lat/lng columns for CSV, or `JSON.parse(rec[iGeo]).coordinates` for topojson), compute, then `_mapPromise.then(api => { api.removeTheme("kde"); api.layer(def); })`. The injected layer needs `FEATURE|CHOROPLETH|SILENT` (CHOROPLETH so the opacity slider's `changeThemeStyle` works) and a **unique `meta.name`**. Sample record indices *before* parsing geometry and debounce the recompute (~300 ms) for performance.

> Runnable scaffold → **template-kde.html** (fill placeholders; edit coordinate extraction + weight expression). Concepts, weight choices, stacked-isoband trick, perf & gotchas, general external-library pattern → **EXTENSIONS_GUIDE.md**

---

## WMS / External Raster Overlays (Copernicus, EEA, Esri REST services)

ixMaps has a native `WMS|IMAGE` theme type for dropping a **server-rendered raster image** on the map (e.g. Copernicus Land Monitoring Service layers — Urban Atlas, Riparian Zones — hosted by EEA):

```javascript
// Single, always-visible WMS layer — inline form (default per Rule 1a; no swap needed here)
ixmaps.Map("map", {
        mapType: "VT_TONER_LITE",
        mode:    "pan",
        width:   window.innerWidth + "px",     // ⚠️ MUST be explicit pixels — see gotcha below
        height:  window.innerHeight + "px",
        legend:  "closed"
    },
    map => map.view({ center: { lat: 45.4642, lng: 9.1900 }, zoom: 12 }).options({ basemapopacity: "0.6" })
        .layer("urban_atlas")
            .type("WMS|IMAGE|NOLEGEND")
            .data({ server: "https://image.discomap.eea.europa.eu/arcgis/rest/services/UrbanAtlas/UA_UrbanAtlas_2018/MapServer/export" })
            .style({ opacity: "0.8", layerupper: "1:750000" })   // layerupper = scale-gate; hides layer when zoomed out past this denominator
            .define()
);
```

- **`type("WMS|IMAGE|...")`** — the `data({server: url})` value goes to an internal `szServer`/Esri REST **`MapServer/export`** (or `ImageServer/exportImage`) endpoint — `?f=image&transparent=true&bbox=...&bboxSR=4326&size=W,H` gets appended automatically. This is **not** literal OGC `WMS GetMap` syntax — a true OGC WMS endpoint (`SERVICE=WMS&REQUEST=GetMap&...`) will not work here. EEA hosts Copernicus datasets on Esri ArcGIS Server, so their REST `export` endpoints are the correct URLs to use (find one via the ArcGIS REST metadata: `.../MapServer?f=json`, or by dropping `/WMSServer` and appending nothing to the base `MapServer` URL).
- **`layerupper` / `layerlower`** (style props) — scale-string gates (`"1:750000"`) that hide the theme above/below a given map-scale denominator; use this instead of hand-rolled zoom-threshold JS.
- No `.data({url:...})`/`.binding()` needed — this theme type draws one image per redraw, not per-record data.

> ⚠️ **Critical gotcha:** `width`/`height` in the `ixmaps.Map()`/`ixmaps.embed()` options **must be explicit pixel strings** (`window.innerWidth + "px"`), never `"100%"`. Percentage sizing breaks this theme's internal SVG scale math — the image request still fires and succeeds (confirm via network tab), but the `<image>` element renders a few SVG-units across, i.e. invisible. This affects both the modern `ixmaps.Map()` loader and the classic `ixmaps.embed()` + `htmlgui_flat.js` path identically — it is a sizing-string issue, not an old-API-vs-new-API issue.
>
> Also don't be alarmed by tiny `width`/`x`/`y` numbers on the `<image>` element in devtools (e.g. `width:1.3`) — those are the engine's internal SVG user-coordinate space, scaled up by the outer `<svg>` viewBox to real pixel size. Verify visibility with a screenshot, not by eyeballing those attribute values.

**Switchable WMS layers (e.g. a dataset picker for several Copernicus/EEA services)** — the same **stable `meta.name` → auto-replace** pattern from § Multi-Layer Join Pattern · B works identically for `WMS|IMAGE` themes, confirmed with a 4-layer Copernicus showcase (Urban Atlas / Riparian Zones / Corine Land Cover / Imperviousness Density) switched via button clicks with no stacking or ghosting:

```javascript
var WMS_THEME_NAME = "copernicus-wms";   // same name every time = auto-replace, no removeTheme needed

function setLayer(cfg) {
    myMap.then(function (api) {
        myMap.layer("copernicus")                    // layer name is arbitrary for WMS|IMAGE (no geometry to bind)
            .type("WMS|IMAGE|NOLEGEND")
            .data({ server: cfg.server })
            .style(Object.assign({ opacity: "0.8" }, cfg.style))
            .meta({ name: WMS_THEME_NAME })
            .define();
    });
}
```

Each `setLayer(cfg)` call swaps the raster in place — no `removeTheme` call needed as long as `meta.name` stays constant across all options in the picker.

---

## CSS Conflicts with External Frameworks (Bootstrap etc.)

**Never load Bootstrap 3 alongside ixmaps** — its `.hidden { display:none !important }` silently hides ixmaps' toolbar / tooltip / contextmenu (ixmaps toggles them via inline `style.display`, which `!important` beats). Ship the ~35-line standalone facet CSS instead. On dark basemaps, force `#tooltip` text color. Always run the tooltip/contextmenu class-cleanup inside `myMap.then()`.

> Standalone facet CSS, dark-basemap tooltip fix, tooltip/contextmenu cleanup, attribute-selector fallback → **CSS_INTEROP.md**
