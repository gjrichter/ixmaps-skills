# User-Defined Charts (`CHART|USER`)

`CHART|USER` lets you draw fully custom SVG shapes at each feature centroid using D3.
Use it when built-in chart types (BUBBLE, BAR, VECTOR…) can't express what you need (e.g. wind barbs, thermometers, composite icons).

## Required script dependencies

Load D3 v3 **after** `ixmaps.js`, plus the user chart script(s) you need.

```html
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/ixmaps.js"></script>
<script src="https://d3js.org/d3.v3.min.js"></script>
<!-- choose one or more: -->
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps_flat@master/usercharts/d3/chart.js"></script>       <!-- pinnacleChart -->
<script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps_flat@master/usercharts/d3/arrow_chart.js"></script> <!-- arrowChart -->
<!-- or define your own inline (see below) -->
```

## Layer definition pattern

```js
myMap.layer("myLayer")
  .data({ obj: data, type: "json" })
  .binding({ lookup: "joinField", value: "mainValue", title: "nameField" })
  .type("CHART|USER|SIZE|VALUES")
  .style({
    userdraw: "myChart",              // must match window.ixmaps.myChart function name
    colorscheme: ["#c62828","#1b5e20"],
    rangecentervalue: 0,              // optional: split color at this value
    fillopacity: 0.85,
    rangescale: 0.2,                  // controls chart SIZE (NOT scale:)
    scale: 1,                         // scale does NOT affect size in USER charts
    units: "%",
    linecolor: "white",
    linewidth: 1,
    fadenegative: 0.05,
    showdata: "true"
  })
  .define();
```

### `rangescale` vs `scale` (critical)

In `CHART|USER`, `rangescale` controls sizing; `scale` is ignored for sizing.

- `args.theme.nRangeScale` ← set by `rangescale` style property
- Sizing formula inside draw functions typically resembles:
  - `nHeight = args.maxSize * 20 * (args.theme.nRangeScale || 1)`

## Passing multiple fields (`values:` binding)

To pass multiple fields to the draw function use `values:` instead of `value:`:

```js
.binding({ lookup: "name", values: "wind_speed|wind_dir|precip", title: "name" })
// args.value      === args.values[0] (primary value)
// args.values[1]  === wind_dir
// args.values[2]  === precip
```

`args.item.szLabel` is **always null** in `CHART|USER` layers — do not use it as a lookup key.

Inside a draw function:

```js
var wind_speed = (args.values && args.values[0] != null) ? Number(args.values[0]) : (args.value || 0);
var wind_dir   = (args.values && args.values[1] != null) ? Number(args.values[1]) : 0;
var precip     = (args.values && args.values[2] != null) ? Number(args.values[2]) : 0;
```

Rule: put the “main” value first in the `values:` list — it becomes `args.value` and drives size scaling, legend range, and tooltip range.

## Writing a custom draw function

Define a global `ixmaps.<name>` function and reference it via `.style({ userdraw: "<name>" })`.

```js
window.ixmaps = window.ixmaps || {};
(function () {

  // _init — called once before the first draw; use for shared <defs> etc.
  ixmaps.myChart_init = function (SVGDocument, args) {
    var svg = d3.select(args.target);
    if (!ixmaps.d3svgDefs) {
      ixmaps.d3svgDefs = svg.append("defs");
    }
  };

  // draw — called per data item / feature centroid
  ixmaps.myChart = function (SVGDocument, args) {
    if (!args.item) return false;

    var val = args.value || 0;

    var REF_H   = 900;
    var height  = args.maxSize * 20 * (args.theme.nRangeScale || 1);
    if (height === 0) return false;
    var sc = height / REF_H;

    var color = args.color
      || (args.item && args.item.szColor)
      || args.theme.colorScheme[args.class || 0];
    var fillOpacity = args.theme.fillOpacity || 0.85;
    var opacity     = args.theme.nOpacity || 1;

    var svg = d3.select(args.target);
    var g   = svg.append("g").attr("transform", "scale(" + sc + ")");

    var nMax = Math.max(args.theme.nMax, Math.abs(args.theme.nMin));
    var h    = val / nMax * 900 * (args.theme.nRangeScale || 1);

    g.append("rect")
      .attr("x", -30).attr("y", -h)
      .attr("width", 60).attr("height", h)
      .attr("style", "fill:" + color + ";fill-opacity:" + fillOpacity + ";opacity:" + opacity);

    if (args.flag && args.flag.match(/VALUES/)) {
      var fontSize = Math.max(h / 5.5, 7);
      var text = ixmaps.formatValue(val, 0) + (args.theme.szUnits || "");
      svg.append("text")
        .attr("x", 0).attr("y", -(h * sc + fontSize * 0.6))
        .attr("style", "font-size:" + fontSize + "px;text-anchor:middle;fill:" + color)
        .text(text);
    }

    return { x: 0, y: 0 };
  };

})();
```

## Key `args` properties

| Property | Set by |
|---|---|
| `args.value` | first field in `value:` or `values:` binding |
| `args.values[]` | all fields in `values:` binding (pipe-separated) |
| `args.theme.colorScheme` | `colorscheme` style array |
| `args.theme.nMax` / `nMin` | auto-computed from data range |
| `args.theme.nRangeScale` | `rangescale` style property |
| `args.theme.fillOpacity` | `fillopacity` |
| `args.theme.nOpacity` | `opacity` |
| `args.theme.nLineWidth` | `linewidth` |
| `args.theme.szLineColor` | `linecolor` |
| `args.theme.szUnits` | `units` |
| `args.theme.nFadeNegative` | `fadenegative` |
| `args.theme.szFlag` | type flags string (e.g. `"SHADOW\|GRADIENT"`) |
| `args.flag` | rendering flags (e.g. `"VALUES\|ZOOM"`) |
| `args.maxSize` | computed max display size |
| `args.class` | color-class index into `colorScheme` |
| `args.item.szLabel` | **always null** in `CHART\|USER` — do not use |
| `args.item.szTitle` | title field from binding |
| `args.item.szColor` | per-feature override color |
| `args.target` | CSS selector for the SVG element |
| `args.color` | resolved color for this item |
| `ixmaps.d3svgDefs` | shared `<defs>` element set in `_init` |

## Type flags for `CHART|USER`

| Flag | Effect |
|---|---|
| `USER` | activates `userdraw` function lookup (required) |
| `SIZE` | scales chart height by value magnitude |
| `VALUES` | render numeric labels on charts |
| `TITLE` | render title/name text |
| `ZOOM` | re-create gradients on zoom (quality, slower) |
| `SILENT` | suppress hover tooltips on this layer |

## Pre-built user chart functions

| Script | Function (`userdraw`) | Shape |
|---|---|---|
| `chart.js` | `pinnacleChart` | triangle/peak with gradient |
| `arrow_chart.js` | `arrowChart` | up/down arrows for signed values |

## Wind direction convention example

```js
// staff/arrow points toward wind SOURCE (meteorological convention)
// Draw unrotated symbol pointing UP (−y), then rotate by wind_dir:
var gaWind = g.append("g").attr("transform", "rotate(" + wind_dir + ")");
// rotate(0)   → staff up    → wind from north
// rotate(90)  → staff right → wind from east
// rotate(180) → staff down  → wind from south
```

## Suppressing tooltips on background FEATURE layers

```js
.type("FEATURE|SILENT")
```

