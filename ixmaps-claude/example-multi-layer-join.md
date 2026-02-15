# Example: Multi-Layer Map with External CSV Data Join

This example demonstrates the **correct pattern** for creating multiple thematic layers (choropleth + bubbles) that share the same base geometry and join with external CSV data.

## Use Case: MEPA 2024 - Italian Public Administration Orders

**Real-world implementation**: Visualizing MEPA (Mercato Elettronico PA) procurement data for 2024 across Italian provinces.

**Data sources:**
- **Geometry**: Italian provinces TopoJSON from openpolis/geojson-italy
- **Statistics**: Aggregated CSV with 109 provinces, procurement values, and order counts

**Goal**:
- Choropleth map colored by economic value
- Bubble charts sized by number of orders
- Rich tooltips with detailed statistics

---

## Complete Working Code

```html
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <title>MEPA 2024 - Ordini Pubblici per Provincia</title>
    <script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/ixmaps.js"></script>
    <style>
        body { margin: 0; padding: 0; font-family: Arial, sans-serif; }
        #map { width: 100%; height: 100vh; }
    </style>
</head>
<body>
    <div id="map"></div>

    <script>
        try {
            // Initialize map
            // IMPORTANT: Don't use 'map' as variable name - conflicts with ixMaps internals
            const myMap = ixmaps.Map("map", {
                mapType: "VT_TONER_LITE",
                mode: "info"
            })
            .options({
                objectscaling: "dynamic",
                normalSizeScale: "10000000",
                basemapopacity: 0.5,
                flushChartDraw: 1000000
            })
            .view({
                center: { lat: 42.5, lng: 12.5 },
                zoom: 6
            })
            .legend("MEPA 2024 - Ordini Pubblici per Provincia");

            // ========================================
            // Layer 1: FEATURE base - Geometry ONLY
            // ========================================
            myMap.layer("provinces")
                .data({
                    url: "https://raw.githubusercontent.com/openpolis/geojson-italy/master/topojson/limits_IT_provinces.topo.json",
                    type: "topojson",
                    name: "limits_IT_provinces"
                })
                .binding({
                    geo: "geometry",
                    id: "prov_acr",        // ← TopoJSON field for join (e.g., "RM", "MI", "NA")
                    title: "prov_name"     // Province name for display
                })
                .type("FEATURE")
                .style({
                    opacity: 0.1,
                    linecolor: "#666666",
                    linewidth: 0.5
                })
                .define();

            // ========================================
            // Layer 2: CHOROPLETH - Economic Value
            // ========================================
            myMap.layer("provinces")  // ← Same name as FEATURE base
                .data({
                    url: "https://s3.fr-par.scw.cloud/ixmaps.data/test%20only/mepa-2024-processed.csv",
                    type: "csv"
                })
                .binding({
                    lookup: "Sigla_Provincia",  // ← CSV field for join (e.g., "RM", "MI", "NA")
                    value: "Valore_Totale_Euro"
                })
                .type("CHOROPLETH|QUANTILE")  // ← NO FEATURE! Uses existing geometry
                .style({
                    colorscheme: ["#e3f2fd", "#90caf9", "#42a5f5", "#1e88e5", "#1565c0", "#0d47a1"],
                    opacity: 0.7,
                    linecolor: "#333333",
                    linewidth: 0.5,
                    showdata: "true"
                })
                .meta({
                    tooltip: `
                        <div style="font-family: Arial; padding: 10px; min-width: 250px;">
                            <h3 style="margin: 0 0 10px 0; color: #1565c0;">
                                {{name}} ({{prov_acr}})
                            </h3>
                            <table style="width: 100%; font-size: 13px;">
                                <tr><td><strong>Regione:</strong></td><td>{{Regione}}</td></tr>
                                <tr><td><strong>Valore Totale:</strong></td><td style="color: #1565c0;">€ {{Valore_Totale_Euro}}</td></tr>
                                <tr><td><strong>Numero Ordini:</strong></td><td>{{N_Ordini_Totale}}</td></tr>
                                <tr><td><strong>PA Coinvolte:</strong></td><td>{{N_PA_Stimate}}</td></tr>
                            </table>
                        </div>
                    `
                })
                .title("Valore Economico Ordini (€)")
                .define();

            // ========================================
            // Layer 3: BUBBLE - Number of Orders
            // ========================================
            myMap.layer("provinces")  // ← Same name as FEATURE base
                .data({
                    url: "https://s3.fr-par.scw.cloud/ixmaps.data/test%20only/mepa-2024-processed.csv",
                    type: "csv"
                })
                .binding({
                    lookup: "Sigla_Provincia",  // ← Same CSV field for join
                    value: "N_Ordini_Totale"
                })
                .type("CHART|BUBBLE|SIZE|VALUES")
                .style({
                    colorscheme: ["#ff6f00"],
                    opacity: 0.6,
                    linecolor: "#ffffff",
                    linewidth: 1,
                    scale: 1.2,
                    showdata: "true"
                })
                .meta({
                    tooltip: `
                        <div style="font-family: Arial; padding: 10px;">
                            <h4 style="margin: 0 0 8px 0; color: #ff6f00;">{{name}}</h4>
                            <div><strong>Numero Ordini:</strong> <span style="color: #ff6f00;">{{N_Ordini_Totale}}</span></div>
                            <div><strong>Valore Totale:</strong> € {{Valore_Totale_Euro}}</div>
                        </div>
                    `
                })
                .title("Numero Ordini (Bubble)")
                .define();

        } catch (error) {
            console.error('Map initialization failed:', error);
        }
    </script>
</body>
</html>
```

---

## Key Architecture Points

### 1. Three Separate Layers, Same Name

```javascript
// All three layers share the same base name "provinces"
map.layer("provinces")      // Layer 1: FEATURE base
map.layer("provinces")      // Layer 2: CHOROPLETH
map.layer("provinces")      // Layer 3: BUBBLE
```

ixMaps recognizes these as variations of the same base layer and manages data sharing/caching automatically.

### 2. Join Mechanism (CRITICAL)

**Two-way join required:**

**FEATURE layer (geometry):**
```javascript
.binding({
    geo: "geometry",
    id: "prov_acr",     // ← Field in TopoJSON identifies each feature
    title: "prov_name"
})
```

**Thematic layers (data):**
```javascript
.binding({
    lookup: "Sigla_Provincia",  // ← Field in CSV that matches id
    value: "Valore_Totale_Euro"
})
```

**How it works:**
- FEATURE layer defines: "This feature has ID = 'RM'"
- CSV row has: "Sigla_Provincia = 'RM'"
- ixMaps matches: `id` (TopoJSON) ↔ `lookup` (CSV)
- Result: Province "RM" gets data from CSV row with "Sigla_Provincia = RM"

### 3. ONE `.data()` Per Layer

```javascript
// ✓ CORRECT
map.layer("provinces")
    .data({ url: "geometry.topojson", type: "topojson" })
    .binding({ geo: "geometry", id: "code" })
    .define();

map.layer("provinces")
    .data({ url: "data.csv", type: "csv" })
    .binding({ lookup: "code", value: "stat" })
    .define();

// ✗ WRONG - Two .data() calls on same layer
map.layer("provinces")
    .data({ url: "geometry.topojson", type: "topojson" })
    .data({ url: "data.csv", type: "csv" })  // ERROR!
    .define();
```

### 4. `lookup` Parameter Location

```javascript
// ✓ CORRECT - lookup in .binding()
.binding({
    lookup: "Sigla_Provincia",
    value: "Valore_Totale_Euro"
})

// ✗ WRONG - lookup in .data()
.data({
    url: "data.csv",
    type: "csv",
    lookup: "Sigla_Provincia"  // ERROR! Wrong place
})
```

### 5. ⚠️ CRITICAL: `FEATURE` Type in Multi-Layer

**Important:** The CHOROPLETH and BUBBLE layers do NOT include `FEATURE` in their type definitions because they reference the previously defined FEATURE base layer.

```javascript
// Layer 1: Base geometry
.type("FEATURE")  // ✓ Creates SVG geometry groups

// Layer 2: Choropleth overlay
.type("CHOROPLETH|QUANTILE")  // ✓ NO FEATURE! Uses existing geometry

// Layer 3: Bubble overlay
.type("CHART|BUBBLE|SIZE|VALUES")  // ✓ NO FEATURE! Uses existing geometry
```

**Why this matters:**
- Including `FEATURE` creates SVG geometry groups
- In multi-layer scenarios, base layer creates geometry ONCE
- Overlay layers add visualization only (colors, charts)
- Including `FEATURE` in overlays causes conflicting SVG group creation
- Result: undetermined behavior, duplicate groups

**The distinction:**
- `FEATURE|CHOROPLETH` = Single theme (geometry + colors in one)
- `FEATURE` + `CHOROPLETH` = Multi-layer (geometry separate, then colors)

**Common mistake:**
```javascript
// ✗ WRONG - both have FEATURE
map.layer("provinces").type("FEATURE").define();
map.layer("provinces").type("FEATURE|CHOROPLETH").define();  // BUG!

// ✓ CORRECT - only base has FEATURE
map.layer("provinces").type("FEATURE").define();
map.layer("provinces").type("CHOROPLETH").define();  // Correct!
```

---

## CSV Data Structure

The CSV must have a field that matches the TopoJSON `id` field:

```csv
Sigla_Provincia,Regione,Valore_Totale_Euro,N_Ordini_Totale,N_PA_Stimate
RM,LAZIO,123456789.00,5432,150
MI,LOMBARDIA,234567890.00,8765,280
NA,CAMPANIA,98765432.00,3456,120
...
```

**Key points:**
- `Sigla_Provincia` values ("RM", "MI", "NA") must match `prov_acr` values in TopoJSON
- Values are case-sensitive
- No extra spaces or formatting differences

---

## TopoJSON Structure

The TopoJSON from openpolis/geojson-italy has these properties:

```javascript
{
  "type": "Topology",
  "objects": {
    "limits_IT_provinces": {
      "type": "GeometryCollection",
      "geometries": [
        {
          "type": "Polygon",
          "properties": {
            "prov_acr": "RM",        // ← Used for id in join
            "prov_name": "Roma",     // ← Used for title/display
            "prov_istat_code": "058",
            "reg_name": "Lazio",
            // ... other properties
          },
          "arcs": [...]
        }
      ]
    }
  }
}
```

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Two `.data()` on same layer
```javascript
map.layer("provinces")
    .data({ url: "geometry.json", type: "geojson" })
    .data({ url: "data.csv", type: "csv" })  // ERROR!
```

### ❌ Mistake 2: Missing `id` in FEATURE layer
```javascript
map.layer("provinces")
    .binding({
        geo: "geometry"
        // Missing id!
    })
```

### ❌ Mistake 3: Missing `lookup` in thematic layer
```javascript
map.layer("provinces")
    .binding({
        // Missing lookup!
        value: "stat"
    })
```

### ❌ Mistake 4: `lookup` in wrong place
```javascript
.data({
    url: "data.csv",
    type: "csv",
    lookup: "code"  // Wrong! Goes in .binding()
})
```

### ❌ Mistake 5: Mismatched field values
```javascript
// TopoJSON has: prov_acr = "RM"
// CSV has: Provincia = "Roma"  // Won't match!
```

---

## Benefits of This Pattern

1. **Single geometry load**: TopoJSON loaded once, reused by all layers
2. **Separate data management**: Each layer can visualize different CSV fields
3. **Clean separation**: Geometry vs. data are clearly separated
4. **Easy updates**: Change data source without touching geometry
5. **Automatic caching**: ixMaps handles data sharing efficiently
6. **Multiple visualizations**: Same data, different visual representations

---

## Testing Checklist

- [ ] Map loads without console errors
- [ ] Province boundaries visible
- [ ] Choropleth colors provinces correctly
- [ ] Bubbles appear with correct sizes
- [ ] Tooltips show correct data on hover
- [ ] All provinces have data (or gracefully handle missing data)
- [ ] CSV field values match TopoJSON id field values

---

## Advanced: Dynamic Opacity in Multi-Layer

The `DOPACITYMAX` type modifier can be added to choropleth layers to create visual depth through dynamic transparency. This is especially effective in multi-layer maps where you want to emphasize high-value areas.

### What is DOPACITYMAX?

`DOPACITYMAX` adds **dynamic opacity** based on data values:
- High values → more opaque (stand out)
- Low values → more transparent (fade to background)
- Creates natural visual hierarchy beyond color alone

### Usage in Multi-Layer Context

```javascript
// Layer 1: Base FEATURE (geometry only)
map.layer("provinces")
    .data({
        url: "https://raw.githubusercontent.com/openpolis/geojson-italy/master/topojson/limits_IT_provinces.topo.json",
        type: "topojson",
        name: "limits_IT_provinces"
    })
    .binding({
        geo: "geometry",
        id: "prov_acr",
        title: "prov_name"
    })
    .type("FEATURE")
    .style({
        colorscheme: ["none"],
        linecolor: "#000000",
        linewidth: 1.0
    })
    .define();

// Layer 2: CHOROPLETH with DOPACITYMAX (uses Layer 1 geometry)
map.layer("provinces")
    .data({
        url: "https://s3.fr-par.scw.cloud/ixmaps.data/test%20only/mepa-2024-processed.csv",
        type: "csv"
    })
    .binding({
        lookup: "Sigla_Provincia",
        value: "Valore_Totale_Euro"  // Used for BOTH color AND opacity
    })
    .type("CHOROPLETH|QUANTILE|DOPACITYMAX")  // ← Add dynamic opacity
    .style({
        colorscheme: ["#ffffb2", "#fecc5c", "#fd8d3c", "#f03b20", "#bd0026", "#800026"],
        opacity: 0.85,          // Base opacity
        dopacitypow: 1,         // Interpolation curve (default: 1 = linear)
        dopacityscale: 1,       // Intensity multiplier (default: 1)
        linecolor: "#000000",
        linewidth: 1.0,
        showdata: "true"
    })
    .define();

// Layer 3: BUBBLE overlay (unaffected by DOPACITYMAX)
map.layer("provinces")
    .data({
        url: "https://s3.fr-par.scw.cloud/ixmaps.data/test%20only/mepa-2024-processed.csv",
        type: "csv"
    })
    .binding({
        lookup: "Sigla_Provincia",
        value: "N_Ordini_Totale"
    })
    .type("CHART|BUBBLE|SIZE|VALUES")
    .style({
        colorscheme: ["#006d77"],  // Contrasting teal color
        opacity: 0.75,
        linecolor: "#000000",
        linewidth: 2,
        scale: 1.2
    })
    .define();
```

### Effect

**Without DOPACITYMAX:**
- All provinces have same opacity
- Visual hierarchy comes only from color

**With DOPACITYMAX:**
- High-value provinces: Dark color + high opacity (prominent)
- Low-value provinces: Light color + low opacity (fades to background)
- Natural visual hierarchy where important areas stand out
- Bubble overlay remains clearly visible

### Configuration Parameters

**`dopacitypow`** (Interpolation curve):
- Default: `1` (linear)
- Higher values: Lower contrast (gentler curve)
- Lower values: Higher contrast (steeper curve)

```javascript
dopacitypow: 1      // Linear: even opacity distribution
dopacitypow: 2      // Gentler: compressed opacity range
dopacitypow: 0.5    // Steeper: expanded opacity range
```

**`dopacityscale`** (Intensity):
- Default: `1` (normal)
- Higher values: More opacity (stronger visibility)
- Lower values: Less opacity (more transparent)

```javascript
dopacityscale: 1.0   // Normal opacity
dopacityscale: 1.2   // 20% more opaque (good for multi-layer)
dopacityscale: 0.8   // 20% more transparent
```

### When to Use DOPACITYMAX in Multi-Layer

✅ **Good use cases:**
- Emphasizing high-value areas in choropleth while showing bubble overlay
- Creating visual hierarchy in dense data
- Accessibility: Redundant encoding (color + opacity)
- Multi-layer maps where background context needs to fade

❌ **Avoid when:**
- You want uniform visibility across all values
- Base map already has low opacity
- Multiple choropleth layers (can create confusing transparency)

### Real-World Example

The **MEPA 2024 colorblind-safe map** (`mepa-2024-map-colorblind.html`) uses DOPACITYMAX:

**Result:**
- Provinces with high procurement values (€): Warm colors + high opacity
- Provinces with low procurement values (€): Cool colors + low opacity
- Creates natural visual hierarchy
- Accessibility benefit: Value encoded by BOTH color AND opacity

### Accessibility Benefit

DOPACITYMAX provides **redundant encoding**:
- **Color** encodes data value (for most users)
- **Opacity** encodes same value (for colorblind users)
- Users with color perception difficulties still see hierarchy via opacity
- Works for all colorblind types (deuteranopia, protanopia, tritanopia)

### Summary

```javascript
// Add dynamic opacity to any choropleth layer
.type("CHOROPLETH|QUANTILE|DOPACITYMAX")
.style({
    colorscheme: [...],
    opacity: 0.85,
    dopacitypow: 1,       // Curve shape
    dopacityscale: 1,     // Intensity
    showdata: "true"
})
```

**For more details:**
- See `EXAMPLES.md` Example 0.5: Dynamic Opacity with DOPACITYMAX
- See `SKILL.md` "Dynamic Opacity (DOPACITYMAX)" section
- See `API_REFERENCE.md` Type Modifiers

### DOPACITYMINMAX Variant - Highlighting Outliers

For highlighting both minimum AND maximum values (outliers at both extremes), use `DOPACITYMINMAX` instead:

```javascript
// Highlight both extremes (U-shaped opacity curve)
map.layer("provinces")
    .data({
        url: "https://s3.fr-par.scw.cloud/ixmaps.data/test%20only/deviation-data.csv",
        type: "csv"
    })
    .binding({
        lookup: "Sigla_Provincia",
        value: "deviation_from_target"  // E.g., -50 to +50
    })
    .type("CHOROPLETH|QUANTILE|DOPACITYMINMAX")  // ← U-curve: emphasize both ends
    .style({
        // Diverging scheme: blue (low) → gray (mid) → red (high)
        colorscheme: ["#0571b0", "#92c5de", "#f7f7f7", "#f4a582", "#ca0020"],
        opacity: 0.85,
        dopacitypow: 0.8,      // Steep U-curve (strong emphasis on outliers)
        dopacityscale: 1.1,    // Slightly more opaque
        showdata: "true"
    })
    .define();
```

**Effect:**
- **Low values (blue):** High opacity → stands out
- **Mid values (gray):** Low opacity → fades to background
- **High values (red):** High opacity → stands out

**Use cases for DOPACITYMINMAX:**
- Temperature anomalies (very hot AND very cold)
- Performance outliers (best AND worst)
- Quality control (out-of-spec at both ends)
- Deviation from targets (above AND below norm)
- Risk assessment (high-risk AND safe zones)

**Comparison:**

| DOPACITYMAX | DOPACITYMINMAX |
|-------------|----------------|
| Linear: low→transparent, high→opaque | U-shaped: both extremes opaque, mid transparent |
| Emphasizes high values | Emphasizes outliers at both ends |
| Good for: rankings, hierarchy | Good for: outliers, anomalies, diverging data |

**For more details:**
- See `EXAMPLES.md` Example 0.6: Highlighting Outliers with DOPACITYMINMAX
- See `SKILL.md` "Dynamic Opacity - Min/Max Variant (DOPACITYMINMAX)" section
- See `API_REFERENCE.md` Type Modifiers

---

## Related Examples

- See `EXAMPLES.md` for more multi-layer patterns
- See `API_REFERENCE.md` for complete `.binding()` documentation
- See `SKILL.md` for the critical rules summary

---

## Real-World Application

This pattern was successfully used to visualize MEPA 2024 procurement data:
- **109 Italian provinces** with aggregated order statistics
- **€981M total procurement value** across 221,870 orders
- **Interactive exploration** with choropleth + bubble overlay
- **Rich tooltips** showing 5+ data fields per province

The resulting map enables policy analysis, regional comparison, and procurement pattern identification.
