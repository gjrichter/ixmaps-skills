# ixMaps Examples

Complete working examples for common use cases.

**🆕 NEW EXAMPLE:** See **[example-multi-layer-join.md](example-multi-layer-join.md)** for a complete real-world case study of multi-layer mapping with external CSV data join (MEPA 2024 Italian procurement visualization with choropleth + bubbles).

## Table of Contents

0. **[Data Hosting with GitHub + CDN](#example-0-data-hosting-with-github--cdn)** ⭐ **BEST PRACTICE**
0.5. **[Dynamic Opacity with DOPACITYMAX](#example-05-dynamic-opacity-with-dopacitymax)** ⭐ **ACCESSIBILITY**
0.6. **[Highlighting Outliers with DOPACITYMINMAX](#example-06-highlighting-outliers-with-dopacityminmax)** ⭐ **OUTLIER DETECTION**
0.7. **[Data Preprocessing with `process`](#example-07-data-preprocessing-with-process)** ⭐ **DATA TRANSFORMATION**
1. [Point Data Examples](#point-data-examples)
2. [GeoJSON Examples](#geojson-examples)
3. [TopoJSON Examples](#topojson-examples)
4. [Aggregation Examples](#aggregation-examples)
5. [Multi-Layer Examples](#multi-layer-examples)
5.5. **[Flow Visualization Examples](#flow-visualization-examples)** ⭐ **VECTOR FLOWS**
6. [Custom Styling Examples](#custom-styling-examples)
7. **[Multi-Layer with External Data Join](example-multi-layer-join.md)** ⭐ NEW

---

## Example 0: Data Hosting with GitHub + CDN

**Best practice for production maps** - Host data externally for smaller HTML files, easy updates, and better performance.

### The Problem with Inline Data

```javascript
// ❌ Inline data bloats HTML files (200KB+ for moderate datasets)
const cityData = [
    {name: "Rome", lat: 41.9028, lon: 12.4964, population: 2873000},
    {name: "Milan", lat: 45.4642, lon: 9.1900, population: 1372000},
    // ... hundreds more rows ...
];

ixmaps.layer("cities")
    .data({ obj: cityData, type: "json" })  // Embedded in HTML
    // ...
```

**Problems:**
- Large HTML files (slow loading)
- Can't update data without regenerating HTML
- Hard to share data across multiple maps
- Version control complexity

### The Solution: External Hosting

```javascript
// ✅ External data via CDN (HTML stays small, ~5KB)
ixmaps.layer("cities")
    .data({
        url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/2026-02/cities.csv",
        type: "csv"
    })
    .binding({
        geo: "lat|lon",
        value: "population",
        title: "name"
    })
    .type("CHART|BUBBLE|SIZE|VALUES")
    .style({
        colorscheme: ["#0066cc"],
        showdata: "true"
    })
    .meta({
        tooltip: "<strong>{{name}}</strong><br>Population: {{population}}"
    })
    .title("Italian Cities by Population")
    .define();
```

**Benefits:**
- ✅ Small HTML files (faster loading)
- ✅ Update data independently of HTML
- ✅ Share data across multiple maps
- ✅ Version control for data
- ✅ Free CDN (jsDelivr)
- ✅ CORS-enabled (no local file issues)

### Complete Example

**cities.csv** (hosted on GitHub):
```csv
name,lat,lon,population,category
Rome,41.9028,12.4964,2873000,capital
Milan,45.4642,9.1900,1372000,city
Naples,40.8518,14.2681,966000,city
Turin,45.0703,7.6869,875000,city
Palermo,38.1157,13.3615,657000,city
```

**map.html** (references hosted data):
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Italian Cities Map</title>
    <script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/ixmaps.js"></script>
    <style>
        body { margin: 0; }
        #map { width: 100%; height: 100vh; }
    </style>
</head>
<body>
    <div id="map"></div>
    <script>
        ixmaps.Map("map", {
            mapType: "VT_TONER_LITE",
            mode: "info"
        })
        .options({
            center: { lat: 42.5, lng: 12.5 },
            zoom: 6,
            objectscaling: "dynamic",
            normalSizeScale: "1000000",
            basemapopacity: 0.6,
            flushChartDraw: 1000000
        });

        // External hosted data - production approach
        ixmaps.layer("cities")
            .data({
                url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/2026-02/cities.csv",
                type: "csv"
            })
            .binding({
                geo: "lat|lon",
                value: "population",
                title: "name"
            })
            .type("CHART|BUBBLE|SIZE|VALUES")
            .style({
                colorscheme: ["#0066cc"],
                opacity: 0.7,
                scale: 1.5,
                showdata: "true"
            })
            .meta({
                tooltip: "<strong>{{name}}</strong><br>Population: {{population:,.0f}}<br>Type: {{category}}"
            })
            .title("Italian Cities by Population")
            .define();
    </script>
</body>
</html>
```

### Setup Instructions

1. **Create GitHub repository** (one-time):
   ```bash
   # On GitHub web: https://github.com/new
   Name: ixmaps-data
   Visibility: Public
   ```

2. **Upload your data**:
   - Go to: https://github.com/<user>/ixmaps-data
   - Navigate to: `by-date/2026-02/`
   - Click "Add file" → "Upload files"
   - Upload `cities.csv`
   - Commit changes

3. **Get CDN URL**:
   ```
   Raw (immediate): https://raw.githubusercontent.com/<user>/ixmaps-data/main/by-date/2026-02/cities.csv
   CDN (fast): https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/2026-02/cities.csv
   ```

4. **Use in map** (as shown above)

### URL Formats

**Development (immediate updates):**
```javascript
url: "https://raw.githubusercontent.com/<user>/ixmaps-data/main/path/to/data.csv"
```
- No caching
- Updates immediately
- Slower (no CDN)
- Use for testing

**Production (cached, fast):**
```javascript
url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/path/to/data.csv"
```
- Global CDN
- 5-10 minute cache sync
- Much faster
- Use for published maps

**Published (immutable):**
```javascript
url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@v1.0.0/path/to/data.csv"
```
- Version-pinned
- Never changes
- Long-term caching
- Use for stable releases

### When to Use Each Approach

| Approach | When to Use | File Size | Updates | Setup |
|----------|-------------|-----------|---------|-------|
| **Inline data** | Demos, prototypes, small datasets | Any | Regenerate HTML | None |
| **GitHub raw** | Development, testing | <10MB | Immediate | Create repo |
| **GitHub CDN** | Production maps | <10MB | 5-10 min delay | Create repo |
| **S3/CloudFront** | Enterprise, large files | Any | Immediate | AWS account, CORS config |

**Recommendation:** Use GitHub + CDN for most production cases (free, fast, reliable).

### Complete Workflow

```bash
# 1. Generate data with Claude Code
# (skill generates cities.csv)

# 2. Upload to GitHub (manual or automated)
# Manual: Web interface (3 clicks)
# Automated: Set IXMAPS_GITHUB_TOKEN (see DATA_HOSTING_GUIDE.md)

# 3. Get CDN URL
CDNURL="https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/by-date/2026-02/cities.csv"

# 4. Use in map
# (skill updates HTML with URL automatically if token set)
```

### Troubleshooting

**404 Not Found?**
- Check file path (case-sensitive)
- Verify repository is public
- Confirm branch name (main vs master)

**CDN not updating?**
- Wait 5-10 minutes for cache sync
- Test with raw URL first
- Use cache bust: `?v=` + timestamp

**CORS errors?**
- Repository must be public
- Don't use file:// URLs
- Use GitHub/CDN URLs only

**For complete guide, see DATA_HOSTING_GUIDE.md**

---

## Example 0.5: Dynamic Opacity with DOPACITYMAX

**Add visual depth to choropleth maps using opacity gradients**

The `DOPACITYMAX` type modifier creates dynamic transparency based on data values, adding visual hierarchy beyond color classification alone. High-value areas become more opaque, low-value areas more transparent.

### Why Use Dynamic Opacity?

**Benefits:**
- ✅ Emphasizes high-value areas naturally
- ✅ Accessibility: Redundant encoding (color + opacity)
- ✅ Creates visual hierarchy in dense data
- ✅ Helps with overlapping multi-layer maps

**Use cases:**
- Economic data (GDP, revenue, spending)
- Population density maps
- Environmental data (pollution, temperature)
- Any choropleth where high values need emphasis

### Basic Example

```javascript
// Economic data with dynamic opacity
ixmaps.layer("regions")
    .data({
        url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/economic-data.csv",
        type: "csv"
    })
    .binding({
        lookup: "region_code",    // Join key
        value: "gdp_per_capita",  // Used for BOTH color AND opacity
        title: "region_name"
    })
    .type("CHOROPLETH|QUANTILE|DOPACITYMAX")  // ← Enable dynamic opacity
    .style({
        colorscheme: [
            "#fff7bc",  // Light yellow (low GDP)
            "#fee391",
            "#fec44f",
            "#fe9929",
            "#ec7014",
            "#cc4c02",
            "#8c2d04"   // Dark brown (high GDP)
        ],
        opacity: 0.8,           // Base opacity
        dopacitypow: 1,         // Interpolation curve (default: 1 = linear)
        dopacityscale: 1.1,     // Intensity multiplier (default: 1)
        linecolor: "#333",
        linewidth: 0.5,
        showdata: "true"
    })
    .meta({
        tooltip: "<strong>{{region_name}}</strong><br>GDP: ${{gdp_per_capita:,.0f}}"
    })
    .title("GDP per Capita with Dynamic Opacity")
    .define();
```

**Effect:**
- High GDP regions: Dark colors + high opacity (stand out)
- Low GDP regions: Light colors + low opacity (fade to background)
- Natural visual hierarchy without overlays

### Configuration Parameters

#### `dopacitypow` - Interpolation Curve

Controls how opacity transitions from low to high values.

```javascript
// LINEAR (default)
dopacitypow: 1    // Even distribution: low=0.2, mid=0.5, high=0.8

// GENTLER (less dramatic)
dopacitypow: 2    // Compressed range: low=0.3, mid=0.5, high=0.7

// STEEPER (more dramatic)
dopacitypow: 0.5  // Expanded range: low=0.1, mid=0.5, high=0.9
```

**When to use:**
- `dopacitypow = 1`: Default, balanced (most cases)
- `dopacitypow > 1`: When you want subtle emphasis (2-3)
- `dopacitypow < 1`: When you want strong contrast (0.5-0.8)

#### `dopacityscale` - Intensity Multiplier

Controls overall opacity level.

```javascript
// NORMAL (default)
dopacityscale: 1.0   // Calculated opacities as-is

// MORE OPAQUE
dopacityscale: 1.5   // 50% more opaque overall

// MORE TRANSPARENT
dopacityscale: 0.7   // 30% more transparent overall
```

**When to use:**
- `dopacityscale = 1`: Default (most cases)
- `dopacityscale > 1`: Multi-layer maps (1.2-1.5)
- `dopacityscale < 1`: Subtle backgrounds (0.7-0.9)

### Advanced Example: Accessibility Enhancement

Combine colorblind-safe colors with dynamic opacity for maximum accessibility.

```javascript
// MEPA 2024 Italian procurement data (colorblind-safe)
map.layer("provinces")
    .data({
        url: "https://s3.fr-par.scw.cloud/ixmaps.data/test%20only/mepa-2024-processed.csv",
        type: "csv"
    })
    .binding({
        lookup: "Sigla_Provincia",
        value: "Valore_Totale_Euro"
    })
    .type("CHOROPLETH|QUANTILE|DOPACITYMAX")
    .style({
        // ColorBrewer YlOrRd - safe for deuteranopia, protanopia, tritanopia
        colorscheme: [
            "#ffffb2",  // Very light yellow (lowest values)
            "#fecc5c",  // Light orange
            "#fd8d3c",  // Orange
            "#f03b20",  // Red-orange
            "#bd0026",  // Dark red
            "#800026"   // Very dark red (highest values)
        ],
        opacity: 0.85,
        dopacitypow: 1,         // Linear curve
        dopacityscale: 1,       // Normal intensity
        linecolor: "#000000",   // Black borders for high contrast
        linewidth: 1.0,
        showdata: "true"
    })
    .meta({
        tooltip: `
            <strong>{{name}} ({{prov_acr}})</strong><br>
            Valore Totale: € {{Valore_Totale_Euro:,.0f}}<br>
            Numero Ordini: {{N_Ordini_Totale:,.0f}}
        `
    })
    .title("Valore Economico Ordini MEPA 2024")
    .define();
```

**Accessibility benefit:**
- Value encoded by **both** color and opacity
- Users with color perception difficulties still see hierarchy via opacity
- Redundant encoding = better comprehension
- Works for all colorblind types

### Configuration Tips

**For strong emphasis:**
```javascript
dopacitypow: 0.5,      // Steep curve (dramatic)
dopacityscale: 1.3     // More opaque overall
```

**For subtle background:**
```javascript
dopacitypow: 2,        // Gentle curve (subtle)
dopacityscale: 0.8     // More transparent overall
```

**For balanced hierarchy (default):**
```javascript
dopacitypow: 1,        // Linear curve
dopacityscale: 1       // Normal intensity
```

### Multi-Layer Usage

Use DOPACITYMAX on choropleth layers when combining with bubbles or other overlays:

```javascript
// Layer 1: Base FEATURE (geometry only)
map.layer("provinces")
    .data({ url: "topojson-url", type: "topojson", name: "limits" })
    .binding({ geo: "geometry", id: "prov_acr", title: "prov_name" })
    .type("FEATURE")
    .style({ colorscheme: ["none"], linecolor: "#666", linewidth: 0.5 })
    .define();

// Layer 2: CHOROPLETH with DOPACITYMAX (uses Layer 1 geometry)
map.layer("provinces")
    .data({ url: "data.csv", type: "csv" })
    .binding({ lookup: "province_code", value: "economic_value" })
    .type("CHOROPLETH|QUANTILE|DOPACITYMAX")  // ← NO FEATURE! Uses existing geometry
    .style({
        colorscheme: ["#ffffb2", "#bd0026"],
        opacity: 0.85,
        dopacitypow: 1,
        dopacityscale: 1.2,    // Slightly more opaque for multi-layer
        showdata: "true"
    })
    .define();

// Layer 3: BUBBLE overlay
map.layer("provinces")
    .data({ url: "data.csv", type: "csv" })
    .binding({ lookup: "province_code", value: "order_count" })
    .type("CHART|BUBBLE|SIZE|VALUES")
    .style({
        colorscheme: ["#006d77"],  // Contrasting color
        opacity: 0.75,
        linecolor: "#000",
        linewidth: 2
    })
    .define();
```

**Result:** High-value provinces have strong color + opacity, creating natural visual hierarchy that doesn't conflict with bubble overlay.

### Real-World Example

See the complete working example in:
- **File:** `mepa-2024-map-colorblind.html`
- **Description:** MEPA 2024 Italian public procurement data
- **Features:** ColorBrewer YlOrRd + DOPACITYMAX + bubble overlay

**Data:** Economic values by province with dynamic opacity creating natural emphasis on high-procurement areas.

### Summary

**Enable dynamic opacity:**
```javascript
.type("CHOROPLETH|QUANTILE|DOPACITYMAX")
```

**Configure:**
- `dopacitypow`: Curve shape (default: 1)
- `dopacityscale`: Intensity (default: 1)

**Best for:**
- Emphasizing important values
- Accessibility (redundant encoding)
- Multi-layer maps with overlays
- Natural visual hierarchy

**See also:**
- SKILL.md: "Dynamic Opacity (DOPACITYMAX)" section
- API_REFERENCE.md: Type Modifiers
- example-multi-layer-join.md: Real-world MEPA example

---

## Example 0.6: Highlighting Outliers with DOPACITYMINMAX

**Emphasize both minimum and maximum values using U-shaped opacity curves**

The `DOPACITYMINMAX` type modifier creates a U-shaped opacity curve that makes both extremes (minimum and maximum values) highly visible while fading mid-range values to the background. Perfect for outlier detection, diverging data, and highlighting anomalies.

### Why Use DOPACITYMINMAX?

**Benefits:**
- ✅ Highlights outliers at both ends of data range
- ✅ Perfect for diverging data (temperature, sentiment, deviation)
- ✅ Emphasizes best AND worst performers
- ✅ Fades "normal" mid-range values
- ✅ Natural for quality control and anomaly detection

**Use cases:**
- Temperature extremes (very hot AND very cold)
- Performance analysis (top AND bottom performers)
- Quality control (defects at both ends of tolerance)
- Deviation from targets (above AND below norm)
- Risk assessment (high-risk AND safe zones)

**Visual difference:**

| DOPACITYMAX | DOPACITYMINMAX |
|-------------|----------------|
| Low → transparent<br>High → opaque | Low → opaque<br>Mid → transparent<br>High → opaque |
| Linear gradient | U-shaped curve |
| Emphasizes one end | Emphasizes both ends |

### Basic Example: Temperature Anomalies

```javascript
// Highlight both extremely hot and extremely cold regions
ixmaps.layer("countries")
    .data({
        url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/climate/temperature-anomaly.csv",
        type: "csv"
    })
    .binding({
        lookup: "country_code",
        value: "temp_deviation",  // Deviation from normal (-5 to +5°C)
        title: "country_name"
    })
    .type("CHOROPLETH|QUANTILE|DOPACITYMINMAX")  // ← Highlight outliers
    .style({
        // Diverging color scheme: blue (cold) → gray (normal) → red (hot)
        colorscheme: [
            "#313695",  // Dark blue (very cold)
            "#4575b4",  // Blue (cold)
            "#abd9e9",  // Light blue (cool)
            "#ffffbf",  // Yellow (normal) ← Will fade
            "#fdae61",  // Light orange (warm)
            "#f46d43",  // Orange (hot)
            "#a50026"   // Dark red (very hot)
        ],
        opacity: 0.8,
        dopacitypow: 0.8,       // Steep U-curve (strong emphasis on extremes)
        dopacityscale: 1.1,     // Slightly more opaque overall
        linecolor: "#333",
        linewidth: 0.5,
        showdata: "true"
    })
    .meta({
        tooltip: "<strong>{{country_name}}</strong><br>Temperature Deviation: {{temp_deviation}}°C"
    })
    .title("Temperature Anomalies (Outliers Highlighted)")
    .define();
```

**Effect:**
- Very cold regions (dark blue): High opacity (stand out)
- Normal temperature regions (yellow): Low opacity (fade to background)
- Very hot regions (dark red): High opacity (stand out)
- Natural emphasis on climate anomalies at both extremes

### Advanced Example: Performance Analysis

```javascript
// Highlight both top performers and underperformers
ixmaps.layer("sales_regions")
    .data({
        url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/sales/regional-performance.csv",
        type: "csv"
    })
    .binding({
        lookup: "region_id",
        value: "performance_score",  // 0-100 scale
        title: "region_name"
    })
    .type("CHOROPLETH|QUANTILE|DOPACITYMINMAX")  // ← Emphasize outliers
    .style({
        colorscheme: [
            "#d7191c",  // Red (worst: 0-20)
            "#fdae61",  // Orange (below average: 20-40)
            "#ffffbf",  // Yellow (average: 40-60) ← Fades
            "#a6d96a",  // Light green (above average: 60-80)
            "#1a9641"   // Dark green (best: 80-100)
        ],
        opacity: 0.85,
        dopacitypow: 1,         // Linear U-curve (balanced)
        dopacityscale: 1.2,     // More opaque (stronger visibility)
        linecolor: "#000",
        linewidth: 1,
        showdata: "true"
    })
    .meta({
        tooltip: `
            <strong>{{region_name}}</strong><br>
            Performance: {{performance_score}}/100<br>
            Status: {{performance_category}}
        `
    })
    .title("Regional Performance (Outliers Emphasized)")
    .define();
```

**Effect:**
- Worst performers (red): Highly visible
- Average performers (yellow): Fade to background
- Top performers (green): Highly visible
- Management can focus on regions needing attention OR recognition

### Configuration Guide

#### `dopacitypow` - U-Curve Steepness

Controls how dramatically mid-range values fade:

```javascript
// GENTLE U-curve (more mid-values visible)
dopacitypow: 2    // Flatter curve, subtle fade

// BALANCED U-curve (default)
dopacitypow: 1    // Symmetrical, moderate fade

// STEEP U-curve (strong emphasis on extremes)
dopacitypow: 0.5  // Sharp curve, dramatic fade of mid-values
```

**Visualization:**
```
dopacitypow = 2 (Gentle):        dopacitypow = 0.5 (Steep):
Opacity                          Opacity
   ↑                                ↑
   │ █       █                      │ █           █
   │  ▓     ▓                       │  ▓         ▓
   │   ▒   ▒                        │
   │    ░ ░                         │     ░░░
   └────────→                       └─────────→
```

#### `dopacityscale` - Overall Intensity

Controls overall opacity level:

```javascript
// MORE TRANSPARENT (subtle background)
dopacityscale: 0.8   // 20% more transparent overall

// NORMAL (default)
dopacityscale: 1.0   // Standard intensity

// MORE OPAQUE (stronger visibility)
dopacityscale: 1.3   // 30% more opaque overall
```

### Real-World Example: Quality Control

```javascript
// Manufacturing: Highlight parts outside tolerance (too small OR too large)
map.layer("production_batches")
    .data({
        url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/qc/part-dimensions.csv",
        type: "csv"
    })
    .binding({
        lookup: "batch_id",
        value: "dimension_mm",  // Target: 50mm, tolerance: ±2mm
        title: "batch_name"
    })
    .type("CHOROPLETH|QUANTILE|DOPACITYMINMAX")
    .style({
        colorscheme: [
            "#e41a1c",  // Red (too small: < 48mm)
            "#ff7f00",  // Orange (borderline small: 48-49mm)
            "#4daf4a",  // Green (within spec: 49-51mm) ← Fades
            "#ff7f00",  // Orange (borderline large: 51-52mm)
            "#e41a1c"   // Red (too large: > 52mm)
        ],
        rangecentervalue: 50,  // Center on target dimension
        opacity: 0.8,
        dopacitypow: 0.7,      // Strong U-curve (emphasize defects)
        dopacityscale: 1.15,
        showdata: "true"
    })
    .meta({
        tooltip: `
            <strong>Batch {{batch_name}}</strong><br>
            Dimension: {{dimension_mm}}mm<br>
            Status: {{status}}<br>
            Deviation: {{deviation}}mm
        `
    })
    .title("Part Dimensions - Quality Control")
    .define();
```

**Effect:**
- Parts too small (red): Highly visible → immediate action
- Parts within tolerance (green): Fade → no action needed
- Parts too large (red): Highly visible → immediate action
- QC team focuses on outliers automatically

### Comparison: When to Use Each Variant

**Use DOPACITYMAX when:**
- ✅ Higher values are more important (GDP, population, revenue)
- ✅ You want hierarchical emphasis (rankings)
- ✅ Single-direction scales (more is better/worse)
- ✅ Top performers need attention

**Use DOPACITYMINMAX when:**
- ✅ Extremes at BOTH ends are important (outliers)
- ✅ Diverging data (hot/cold, above/below)
- ✅ Quality control (out-of-spec at both ends)
- ✅ Risk analysis (high-risk AND safe zones)
- ✅ Performance analysis (best AND worst)

### Multi-Layer Usage

Combine DOPACITYMINMAX choropleth with bubble overlay:

```javascript
// Layer 1: Base geometry
map.layer("regions")
    .data({ url: "geometry.topojson", type: "topojson" })
    .binding({ geo: "geometry", id: "region_code", title: "name" })
    .type("FEATURE")
    .define();

// Layer 2: DOPACITYMINMAX choropleth (outliers)
map.layer("regions")
    .data({ url: "deviation-data.csv", type: "csv" })
    .binding({ lookup: "region_code", value: "deviation_from_target" })
    .type("CHOROPLETH|QUANTILE|DOPACITYMINMAX")  // ← NO FEATURE
    .style({
        colorscheme: ["#0571b0", "#f7f7f7", "#ca0020"],
        opacity: 0.8,
        dopacitypow: 0.8,
        dopacityscale: 1.1,
        showdata: "true"
    })
    .define();

// Layer 3: Bubble overlay (sample size)
map.layer("regions")
    .data({ url: "deviation-data.csv", type: "csv" })
    .binding({ lookup: "region_code", value: "sample_size" })
    .type("CHART|BUBBLE|SIZE|VALUES")
    .style({
        colorscheme: ["#984ea3"],  // Purple (contrasts with blue-red)
        opacity: 0.6
    })
    .define();
```

**Result:** Regions with extreme deviations are highly visible (choropleth), bubble size shows data reliability (sample size).

### Configuration Tips

**For strong outlier emphasis:**
```javascript
dopacitypow: 0.5,      // Steep U-curve
dopacityscale: 1.3     // More opaque overall
```

**For subtle outlier detection:**
```javascript
dopacitypow: 1.5,      // Gentle U-curve
dopacityscale: 0.9     // Slightly transparent
```

**For balanced emphasis (default):**
```javascript
dopacitypow: 1,        // Linear U-curve
dopacityscale: 1       // Normal intensity
```

### Best Practices

1. **Use diverging color schemes** with DOPACITYMINMAX:
   - Blue → Gray → Red (temperature, sentiment)
   - Red → Yellow → Green (performance)
   - Dark → Light → Dark (deviation)

2. **Center your color scale** when appropriate:
   - Use `rangecentervalue` for target-based data
   - E.g., `rangecentervalue: 50` for 50mm target dimension

3. **Adjust dopacitypow** based on data distribution:
   - Many outliers: `dopacitypow: 1.5` (gentle)
   - Few outliers: `dopacitypow: 0.7` (steep)

4. **Test opacity values**:
   - Start with defaults: `dopacitypow: 1`, `dopacityscale: 1`
   - Adjust based on visual clarity
   - Increase `dopacityscale` for multi-layer maps

### Summary

**Enable outlier highlighting:**
```javascript
.type("CHOROPLETH|QUANTILE|DOPACITYMINMAX")
```

**Configure U-curve:**
- `dopacitypow`: Steepness (default: 1)
- `dopacityscale`: Intensity (default: 1)

**Best for:**
- Outlier detection and anomaly highlighting
- Diverging data with meaningful extremes
- Quality control (out-of-spec values)
- Performance analysis (best and worst)

**See also:**
- SKILL.md: "Dynamic Opacity - Min/Max Variant (DOPACITYMINMAX)" section
- API_REFERENCE.md: Type Modifiers
- Example 0.5 for comparison with DOPACITYMAX

---

## Example 0.7: Data Preprocessing with `process`

**Transform data after loading but before visualization**

The `process` property allows you to standardize values, compute derived fields, or enrich data dynamically. This is essential for handling inconsistent data sources or adding computed fields for filtering and visualization.

### Why Use Data Preprocessing?

**Benefits:**
- ✅ Standardize inconsistent field values (e.g., region name variations)
- ✅ Compute derived fields without modifying source data
- ✅ Filter or clean invalid records
- ✅ Convert data formats (strings to numbers, dates, etc.)
- ✅ Enrich data with lookup values

**Use cases:**
- Standardizing region/country names from different sources
- Computing boolean flags (e.g., "is_cross_regional", "is_outlier")
- Adding calculated fields (distance, percentage, category)
- Cleaning malformed data
- Enriching with external lookups

### Example 1: Standardize Region Names

```javascript
// Problem: Source data has inconsistent region names
// "EMILIA ROMAGNA" vs "EMILIA-ROMAGNA"
// "TRENTINO ALTO ADIGE" vs "TRENTINO-ALTO ADIGE"

// Define preprocessing function as var
var standardizeRegionNames = function(data, options) {
    data.forEach(record => {
        // Fix spacing/hyphen inconsistencies
        if (record.region === "EMILIA ROMAGNA") {
            record.region = "EMILIA-ROMAGNA";
        }
        if (record.region === "TRENTINO ALTO ADIGE") {
            record.region = "TRENTINO-ALTO ADIGE";
        }
        // Could add more standardizations...
    });
    return data;
};

// Apply preprocessing in layer definition with .toString()
myMap.layer("regions")
    .data({
        url: "https://cdn.jsdelivr.net/gh/user/repo@main/regional-data.csv",
        type: "csv",
        process: standardizeRegionNames.toString()  // ← String representation!
    })
    .binding({
        lookup: "region",  // Now guaranteed to match geometry IDs
        value: "total_value",
        title: "region"
    })
    .type("CHOROPLETH|QUANTILE")
    .style({
        colorscheme: ["#ffffb2", "#fecc5c", "#fd8d3c", "#f03b20", "#bd0026"],
        opacity: 0.8,
        showdata: "true"
    })
    .meta({
        tooltip: "<strong>{{region}}</strong><br>Value: €{{total_value}}"
    })
    .title("Regional Data (Standardized)")
    .define();
```

**Result:** Data with inconsistent region names now correctly joins with geometry, preventing missing visualizations.

### Example 2: Compute Derived Boolean Field

```javascript
// Problem: Need to filter/visualize cross-regional flows
// Source data has origin and destination, but no "is_cross_regional" field

var addCrossRegionalFlag = function(data, options) {
    data.forEach(record => {
        // Add boolean field for filtering
        record.is_cross_regional =
            (record.origin_region !== record.destination_region) ? "true" : "false";

        // Could add more derived fields...
        record.flow_type = (record.is_cross_regional === "true")
            ? "Inter-regional"
            : "Intra-regional";
    });
    return data;
};

// Use derived field in visualization
myMap.layer("supply_flows")
    .data({
        url: "https://cdn.jsdelivr.net/gh/user/repo@main/supply-chain.csv",
        type: "csv",
        process: addCrossRegionalFlag.toString()  // ← String representation!
    })
    .filter("is_cross_regional = 'true'")  // ← Use derived field!
    .binding({
        position: "origin_region",
        position2: "destination_region",
        value: "flow_value"
    })
    .type("CHART|VECTOR|BEZIER|POINTER|AGGREGATE|SUM")
    .style({
        colorscheme: ["#1f77b4", "#ff7f0e", "#2ca02c"],
        colorfield: "origin_region",
        opacity: 0.67,
        showdata: "true"
    })
    .meta({
        tooltip: `
            <strong>{{origin_region}} → {{destination_region}}</strong><br>
            Value: €{{flow_value}}<br>
            Type: {{flow_type}}
        `
    })
    .title("Cross-Regional Supply Flows")
    .define();
```

**Result:** Only cross-regional flows are visualized (within-region flows filtered out), with computed "flow_type" shown in tooltip.

### Example 3: Transform TopoJSON Properties

```javascript
// Problem: TopoJSON has lowercase region names, but you need uppercase IDs

var uppercaseRegionNames = function(topoData, options) {
    // Works with TopoJSON objects too!
    topoData.objects.regions.geometries.forEach(region => {
        if (region.properties && region.properties.reg_name) {
            const original = region.properties.reg_name;
            region.properties.reg_name = region.properties.reg_name.toUpperCase();
            console.log(`Transformed: ${original} → ${region.properties.reg_name}`);
        }
    });
    return topoData;
};

myMap.layer("regions")
    .data({
        url: "https://raw.githubusercontent.com/openpolis/geojson-italy/master/topojson/limits_IT_regions.topo.json",
        type: "topojson",
        name: "regions",
        process: uppercaseRegionNames.toString()  // ← String representation!
    })
    .binding({
        geo: "geometry",
        id: "reg_name",      // Now uppercase: "PIEMONTE", "LOMBARDIA"
        title: "reg_name"
    })
    .type("FEATURE")
    .style({
        colorscheme: ["#e0e0e0"],
        opacity: 0.7,
        linecolor: "#666666",
        linewidth: 1.0,
        showdata: "true"
    })
    .meta({
        tooltip: "<h4>{{reg_name}}</h4>ISTAT Code: {{reg_istat_code}}"
    })
    .title("Italian Regions (Uppercase IDs)")
    .define();
```

**Result:** Region IDs are now "PIEMONTE", "LOMBARDIA" instead of "Piemonte", "Lombardia" - consistent with external CSV data.

### Example 4: Compute Calculated Fields

```javascript
// Problem: Need percentage and category fields for visualization

var enrichSalesData = function(data, options) {
    // Find max value for percentage calculation
    const maxValue = Math.max(...data.map(r => r.sales));

    data.forEach(record => {
        // Compute percentage of max
        record.sales_pct = ((record.sales / maxValue) * 100).toFixed(1);

        // Categorize performance
        if (record.sales_pct >= 80) {
            record.performance = "Excellent";
        } else if (record.sales_pct >= 60) {
            record.performance = "Good";
        } else if (record.sales_pct >= 40) {
            record.performance = "Average";
        } else {
            record.performance = "Below Target";
        }

        // Convert to number if needed
        record.sales = parseFloat(record.sales);
    });

    return data;
};

myMap.layer("sales_regions")
    .data({
        url: "https://cdn.jsdelivr.net/gh/user/repo@main/sales.csv",
        type: "csv",
        process: enrichSalesData.toString()  // ← String representation!
    })
    .binding({
        lookup: "region_code",
        value: "sales",  // Now guaranteed to be numeric
        title: "region_name"
    })
    .type("CHART|BUBBLE|SIZE|VALUES")
    .style({
        colorscheme: ["#d32f2f", "#ff9800", "#4caf50", "#2e7d32"],
        colorfield: "performance",  // ← Use computed category!
        opacity: 0.75,
        showdata: "true"
    })
    .meta({
        tooltip: `
            <strong>{{region_name}}</strong><br>
            Sales: €{{sales}}<br>
            % of Best: {{sales_pct}}%<br>
            Performance: {{performance}}
        `
    })
    .title("Regional Sales (Computed Categories)")
    .define();
```

**Result:** Bubbles colored by computed performance category, tooltip shows percentage - all without modifying source CSV.

### Function Signature and Best Practices

**Function signature:**
```javascript
// Define as var for .toString() conversion
var preprocessData = function(data, options) {
    // data: Array of objects (one per CSV row or JSON record)
    // options: Data configuration object (contains url, type, etc.)

    // Transform in place or return new array
    data.forEach(record => {
        // Modify record.field = newValue
    });

    return data;  // Return transformed data
};

// Use with .toString() in layer definition
.data({
    url: "data.csv",
    type: "csv",
    process: preprocessData.toString()  // ← String representation!
})
```

**Key points:**
- ✅ **CRITICAL:** Use `.toString()` to convert function: `process: myFunc.toString()`
- ✅ Define as `var functionName = function(data, options) {...};`
- ✅ Function receives data array + options object
- ✅ Modify data in place OR return new data
- ✅ Works with CSV, JSON, GeoJSON, TopoJSON
- ✅ Runs synchronously after load, before visualization
- ✅ New/modified fields available in `.binding()`, `.filter()`, `.meta()`
- ⚠️ Keep function fast (runs synchronously)
- ⚠️ Handle missing/invalid data gracefully

**Common patterns:**
```javascript
// Pattern 1: Standardization
record.field = record.field.toUpperCase();

// Pattern 2: Derived boolean
record.is_active = (record.status === "active") ? "true" : "false";

// Pattern 3: Calculation
record.percentage = ((record.value / total) * 100).toFixed(1);

// Pattern 4: Categorization
record.category = (record.value > threshold) ? "High" : "Low";

// Pattern 5: Type conversion
record.number = parseFloat(record.string_number);
```

### Real-World Example: MEPA Supply Flows

From `mepa_forniture.html` - standardizing region names and computing cross-regional flag:

```javascript
var __mepa_process = function(data, options) {
    data.forEach(record => {
        // Standardize region names
        if (record.Regione_PA === "EMILIA ROMAGNA") {
            record.Regione_PA = "EMILIA-ROMAGNA";
        }
        if (record.Regione_Fornitore === "EMILIA ROMAGNA") {
            record.Regione_Fornitore = "EMILIA-ROMAGNA";
        }
        if (record.Regione_PA === "TRENTINO ALTO ADIGE") {
            record.Regione_PA = "TRENTINO-ALTO ADIGE";
        }
        if (record.Regione_Fornitore === "TRENTINO ALTO ADIGE") {
            record.Regione_Fornitore = "TRENTINO-ALTO ADIGE";
        }

        // Compute derived field for filtering
        record["fuori regione"] =
            (record.Regione_PA !== record.Regione_Fornitore) ? "true" : "false";
    });
    return data;
};

// Use in layer with filter
myMap.layer("flows")
    .data({
        url: "mepa-data.csv",
        type: "csv",
        process: __mepa_process.toString()  // ← String representation!
    })
    .filter("fuori regione = 'true'")  // Only cross-regional flows
    .binding({
        position: "Regione_Fornitore",
        position2: "Regione_PA",
        value: "Valore_economico_Ordini"
    })
    .type("CHART|VECTOR|BEZIER|POINTER|AGGREGATE|SUM")
    .define();
```

**Effect:** Inconsistent region names fixed, cross-regional flows isolated for visualization.

### Summary

**Enable preprocessing:**
```javascript
// Define function as var
var myPreprocessFunction = function(data, options) {
    // Transform data
    return data;
};

// Use with .toString()
.data({
    url: "data.csv",
    type: "csv",
    process: myPreprocessFunction.toString()  // ← String representation!
})
```

**Common use cases:**
- Standardize inconsistent field values
- Compute derived boolean flags
- Add calculated numeric fields
- Categorize continuous values
- Transform geometry properties (TopoJSON)

**Best for:**
- Data cleaning and standardization
- Dynamic field computation
- Filtering based on derived values
- Multi-source data consistency

**See also:**
- SKILL.md: "Data Preprocessing with `process`" section
- API_REFERENCE.md: Data Configuration - Data Preprocessing
- mepa_forniture.html: Real-world preprocessing example

---

## Point Data Examples

### Example 1: Simple Dots (Uniform Color)

Show locations without data values.

```javascript
ixmaps.layer("cities")
    .data({ obj: cityData, type: "json" })
    .binding({
        geo: "lat|lon",
        title: "name"
    })
    .type("CHART|DOT")
    .style({
        colorscheme: ["#0066cc"],
        scale: 1,
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("Italian Cities")
    .define()
```

### Example 2: Sized Bubbles

Bubbles proportional to data values.

```javascript
ixmaps.layer("population")
    .data({ obj: cityData, type: "json" })
    .binding({
        geo: "lat|lon",
        value: "population",
        title: "name"
    })
    .type("CHART|BUBBLE|SIZE|VALUES")
    .style({
        colorscheme: ["#0066cc"],
        normalsizevalue: 100000,  // 100k population = 30px
        opacity: 0.7,
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("Cities by Population")
    .define()
```

**Data format:**
```javascript
const cityData = [
    { name: "Rome", lat: 41.9028, lon: 12.4964, population: 2870500 },
    { name: "Milan", lat: 45.4642, lon: 9.1900, population: 1378000 },
    { name: "Naples", lat: 40.8518, lon: 14.2681, population: 966000 }
];
```

### Example 3: Categorical Dots

Points colored by category field.

```javascript
ixmaps.layer("poi")
    .data({ url: "points.csv", type: "csv" })
    .binding({
        geo: "coordinates",  // Single field with lat,lon
        value: "category",   // Color by this field
        title: "name"
    })
    .type("CHART|DOT|CATEGORICAL")
    .style({
        colorscheme: ["100", "tableau"],  // Dynamic colors
        scale: 1.5,
        opacity: 0.8,
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("Points of Interest by Category")
    .define()
```

### Example 4: Pie Charts at Locations

Multi-value data displayed as pie charts.

```javascript
ixmaps.layer("demographics")
    .data({ obj: demographicData, type: "json" })
    .binding({
        geo: "lat|lon",
        value: "age_0_14|age_15_64|age_65_plus",  // Multiple values
        title: "city"
    })
    .type("CHART|PIE")
    .style({
        colorscheme: ["#4CAF50", "#2196F3", "#FF9800"],
        scale: 2,
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("Age Distribution")
    .define()
```

---

## GeoJSON Examples

### Example 5: Simple Features (Uniform Color)

Display geographic boundaries without data.

```javascript
ixmaps.layer("boundaries")
    .data({ url: "regions.geojson", type: "geojson" })
    .binding({
        geo: "geometry",
        value: "$item$",  // Required even without data
        title: "name"
    })
    .type("FEATURE")
    .style({
        colorscheme: ["#cccccc"],
        fillopacity: 0.3,
        linecolor: "#666666",
        linewidth: 1,
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("Administrative Boundaries")
    .define()
```

### Example 6: Choropleth (Numeric Data)

Regions colored by numeric values.

```javascript
ixmaps.layer("population_density")
    .data({ url: "regions.geojson", type: "geojson" })
    .binding({
        geo: "geometry",
        value: "$item$",
        title: "region_name"
    })
    .type("FEATURE|CHOROPLETH|EQUIDISTANT")
    .style({
        colorscheme: ["#ffffcc", "#ffeda0", "#feb24c", "#f03b20"],
        opacity: 0.7,
        linecolor: "#ffffff",
        linewidth: 2,
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("Population Density")
    .define()
```

### Example 7: Categorical Choropleth

Regions colored by text/category field.

```javascript
ixmaps.layer("regions_by_type")
    .data({ url: "regions.geojson", type: "geojson" })
    .binding({
        geo: "geometry",
        value: "region_type",  // Categorical field
        title: "name"
    })
    .type("FEATURE|CHOROPLETH|CATEGORICAL")
    .style({
        colorscheme: ["100", "tableau"],  // Dynamic colors
        fillopacity: 0.7,
        linecolor: "#ffffff",
        linewidth: 2,
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("Regions by Type")
    .define()
```

### Example 8: Custom HTML Tooltip

GeoJSON with custom formatted tooltip.

```javascript
ixmaps.layer("territories")
    .data({
        url: "lombardia_ambiti.geojson",
        type: "geojson"
    })
    .binding({
        geo: "geometry",
        value: "AMBITO",
        title: "AMBITO"
    })
    .type("FEATURE|CHOROPLETH|CATEGORICAL")
    .style({
        colorscheme: ["100", "tableau"],
        fillopacity: 0.7,
        linecolor: "#ffffff",
        linewidth: 2,
        showdata: "true"
    })
    .meta({
        tooltip: "<h3>{{AMBITO}}</h3><p>{{LISTA_COMUNI}}</p>"
    })
    .title("Territorial Areas")
    .define()
```

---

## TopoJSON Examples

### Example 9: Simple TopoJSON Features

European countries from TopoJSON.

```javascript
ixmaps.layer("european_countries")
    .data({
        url: "https://s3.eu-central-1.amazonaws.com/maps.ixmaps.com/topojson/CNTR_RG_10M_2020_4326.json",
        type: "topojson"
    })
    .binding({
        geo: "geometry",
        value: "$item$",
        title: "NAME_ENGL"  // Property name directly
    })
    .type("FEATURE")
    .style({
        colorscheme: ["#6ba3d9"],
        fillopacity: 0.6,
        linecolor: "#ffffff",
        linewidth: 1.5,
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("European Countries (2020)")
    .define()
```

### Example 10: TopoJSON with Categorical Coloring

Each country colored differently.

```javascript
ixmaps.layer("countries_colored")
    .data({
        url: "https://s3.eu-central-1.amazonaws.com/maps.ixmaps.com/topojson/CNTR_RG_10M_2020_4326.json",
        type: "topojson"
    })
    .binding({
        geo: "geometry",
        value: "NAME_ENGL",  // Color by country name
        title: "NAME_ENGL"
    })
    .type("FEATURE|CHOROPLETH|CATEGORICAL")
    .style({
        colorscheme: ["100", "tableau"],
        fillopacity: 0.7,
        linecolor: "#ffffff",
        linewidth: 1.5,
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("European Countries by Name")
    .define()
```

---

## Aggregation Examples

### Example 11: Point Density with Grid

Aggregate points into density grid.

```javascript
ixmaps.layer("incident_density")
    .data({
        url: "incidents.geojson",
        type: "geojson"
    })
    .binding({
        geo: "lat|lon",
        value: "$item$",  // Count items per cell
        title: "location"
    })
    .type("CHART|BUBBLE|SIZE|AGGREGATE")
    .style({
        colorscheme: ["#ffeb3b", "#ff9800", "#f44336", "#b71c1c"],
        gridwidth: "5px",  // 5 pixel grid cells
        scale: 1.5,
        opacity: 0.7,
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("Incident Density (5px grid)")
    .define()
```

### Example 12: Hexagonal Grid Aggregation

Larger grid for broader patterns.

```javascript
ixmaps.layer("crime_heatmap")
    .data({ obj: crimeData, type: "json" })
    .binding({
        geo: "latitude|longitude",
        value: "$item$",
        title: "type"
    })
    .type("CHART|GRID|AGGREGATE")
    .style({
        colorscheme: ["#ffffb2", "#fecc5c", "#fd8d3c", "#e31a1c"],
        gridwidth: "10px",  // Larger cells
        scale: 2,
        opacity: 0.8,
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("Crime Density Heatmap")
    .define()
```

---

## Multi-Layer Examples

### Example 13: Boundaries + Points

Combine GeoJSON regions with point data.

```javascript
// Complete map setup
ixmaps.Map("map", {
    mapType: "white",
    mode: "info"
})
.options({
    objectscaling: "dynamic",
    normalSizeScale: "1000000",
    basemapopacity: 0.6,
    flushChartDraw: 1000000
})
.view({
    center: { lat: 42.5, lng: 12.5 },
    zoom: 6
})
.legend("Italian Regions and Cities")

// Layer 1: Regional boundaries
.layer(
    ixmaps.layer("regions")
        .data({ url: "regions.geojson", type: "geojson" })
        .binding({
            geo: "geometry",
            value: "$item$",
            title: "region_name"
        })
        .type("FEATURE")
        .style({
            colorscheme: ["#e0e0e0"],
            fillopacity: 0.3,
            linecolor: "#999999",
            linewidth: 2,
            showdata: "true"
        })
        .meta({
            tooltip: "{{theme.item.chart}}{{theme.item.data}}"
        })
        .title("Regions")
        .define()
)

// Layer 2: City points
.layer(
    ixmaps.layer("cities")
        .data({ obj: cityData, type: "json" })
        .binding({
            geo: "lat|lon",
            value: "population",
            title: "name"
        })
        .type("CHART|BUBBLE|SIZE|VALUES")
        .style({
            colorscheme: ["#ff5722"],
            normalsizevalue: 500000,
            opacity: 0.7,
            showdata: "true"
        })
        .meta({
            tooltip: "{{theme.item.chart}}{{theme.item.data}}"
        })
        .title("Cities")
        .define()
);
```

### Example 14: Multiple Point Layers with Different Styles

```javascript
ixmaps.Map("map", {
    mapType: "CartoDB - Positron",
    mode: "info"
})
.options({
    objectscaling: "dynamic",
    normalSizeScale: "1000000",
    basemapopacity: 0.7,
    flushChartDraw: 1000000
})
.view({
    center: { lat: 40.7, lng: -74.0 },
    zoom: 11
})
.legend("NYC Points of Interest")

// Layer 1: Restaurants
.layer(
    ixmaps.layer("restaurants")
        .data({ url: "restaurants.csv", type: "csv" })
        .binding({
            geo: "coordinates",
            value: "rating",
            title: "name"
        })
        .type("CHART|BUBBLE|SIZE|VALUES")
        .style({
            colorscheme: ["#ff6f00"],
            scale: 1.2,
            showdata: "true"
        })
        .meta({
            tooltip: "{{theme.item.chart}}{{theme.item.data}}"
        })
        .title("Restaurants")
        .define()
)

// Layer 2: Hotels
.layer(
    ixmaps.layer("hotels")
        .data({ url: "hotels.csv", type: "csv" })
        .binding({
            geo: "coordinates",
            value: "rating",
            title: "name"
        })
        .type("CHART|BUBBLE|SIZE|VALUES")
        .style({
            colorscheme: ["#2196f3"],
            scale: 1.2,
            showdata: "true"
        })
        .meta({
            tooltip: "{{theme.item.chart}}{{theme.item.data}}"
        })
        .title("Hotels")
        .define()
)

// Layer 3: Attractions
.layer(
    ixmaps.layer("attractions")
        .data({ url: "attractions.csv", type: "csv" })
        .binding({
            geo: "coordinates",
            title: "name"
        })
        .type("CHART|DOT")
        .style({
            colorscheme: ["#4caf50"],
            scale: 1,
            showdata: "true"
        })
        .meta({
            tooltip: "{{theme.item.chart}}{{theme.item.data}}"
        })
        .title("Attractions")
        .define()
);
```

---

## Flow Visualization Examples

### Example: Regional Supply Chain Flows

Show directional flows between Italian regions using VECTOR arrows.

**Data Structure:** CSV with origin-destination pairs

```csv
origin,destination,value,category
LOMBARDIA,LAZIO,150000,Manufacturing
PIEMONTE,CAMPANIA,95000,Agriculture
VENETO,SICILIA,120000,Services
EMILIA-ROMAGNA,TOSCANA,85000,Technology
LAZIO,LOMBARDIA,110000,Manufacturing
TOSCANA,PIEMONTE,75000,Agriculture
```

**Implementation:**

```javascript
// Multi-layer: Base map + Flow vectors

// Layer 1: Base FEATURE layer (regions background)
myMap.layer("regions")
    .data({
        url: "https://raw.githubusercontent.com/openpolis/geojson-italy/master/topojson/limits_IT_regions.topo.json",
        type: "topojson",
        name: "regions"
    })
    .binding({
        geo: "geometry",
        id: "reg_name",
        title: "reg_name"
    })
    .type("FEATURE")
    .style({
        colorscheme: ["#e0e0e0"],  // Light gray background
        opacity: 0.07,              // Very subtle
        linecolor: "#666666",
        linewidth: 1.0,
        showdata: "true"
    })
    .meta({
        tooltip: "<strong>{{reg_name}}</strong>"
    })
    .title("Italian Regions")
    .define();

// Layer 2: VECTOR flows (supply chain arrows)
myMap.layer("flows")
    .data({
        url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/supply-flows.csv",
        type: "csv"
    })
    .binding({
        position: "origin",        // Supplier region (starting point)
        position2: "destination",  // Buyer region (ending point)
        title: "origin"
    })
    .type("CHART|VECTOR|BEZIER|POINTER|NOSCALE|EXACT|AGGREGATE|SUM")
    .style({
        // Color palette for regions
        colorscheme: [
            "#1F77B4", "#FF7F0E", "#2CA02C", "#D62728", "#966ABE",
            "#8C564B", "#E377C2", "#7E7E7E", "#BCBD22", "#18BECF"
        ],
        colorfield: "origin",      // Color arrows by supplier region
        sizefield: "value",        // Arrow thickness by trade value
        opacity: 0.67,
        rangescale: 5,             // Thickness variation range
        units: "€",
        showdata: "true"
    })
    .meta({
        tooltip: `
            <div style="padding: 8px;">
                <strong>Supply Flow</strong><br>
                From: <strong>{{origin}}</strong><br>
                To: <strong>{{destination}}</strong><br>
                Value: <strong>€{{value:,.0f}}</strong><br>
                Category: {{category}}
            </div>
        `
    })
    .title("Regional Supply Flows")
    .define();
```

**Result:**
- Smooth curved arrows (BEZIER) from supplier → buyer regions
- Arrow thickness shows trade volume
- Arrow color shows supplier region
- Arrows point in direction of flow (POINTER)
- Multiple flows between same regions are aggregated (AGGREGATE|SUM)

**Type Modifiers Explained:**
- `VECTOR`: Creates directional arrows
- `BEZIER`: Smooth curves instead of straight lines
- `POINTER`: Adds arrowheads showing direction
- `NOSCALE`: Keeps arrow thickness constant when zooming
- `EXACT`: Positions arrows precisely at region centers
- `AGGREGATE`: Combines multiple records with same origin-destination
- `SUM`: Sums values when aggregating

**Use Cases:**
- Supply chain flows (which region supplies to which)
- Migration patterns (where people move from/to)
- Trade routes (exports/imports between regions)
- Transportation flows (origin-destination trips)

**Comparison to BUBBLE:**

| VECTOR | BUBBLE |
|--------|--------|
| Shows directional relationships | Shows quantities at single location |
| Two positions (origin + destination) | One position per record |
| Arrows between locations | Circles at locations |
| "Who supplies to whom" | "Total per location" |

**For more details:** See SKILL.md "Flow Visualization (VECTOR)" section

**Real-world reference:** `/Users/gjrichter/Work/Claude Code/mepa_forniture.html`

---

## Custom Styling Examples

### Example 15: Custom Color Gradients

Multi-stop color gradient for choropleth.

```javascript
.type("FEATURE|CHOROPLETH|EQUIDISTANT")
.style({
    colorscheme: [
        "#f7fbff",  // Lightest
        "#deebf7",
        "#c6dbef",
        "#9ecae1",
        "#6baed6",
        "#4292c6",
        "#2171b5",
        "#08519c",
        "#08306b"   // Darkest
    ],
    fillopacity: 0.8,
    linecolor: "#ffffff",
    linewidth: 1,
    showdata: "true"
})
```

### Example 16: Dark Theme Map

Map with dark base and bright markers.

```javascript
ixmaps.Map("map", {
    mapType: "CartoDB - Dark_Matter",
    mode: "info"
})
.options({
    objectscaling: "dynamic",
    normalSizeScale: "500000",
    basemapopacity: 1.0,  // Full opacity for dark map
    flushChartDraw: 1000000
})
.view({
    center: { lat: 51.5074, lng: -0.1278 },
    zoom: 10
})
.legend("London Events")
.layer(
    ixmaps.layer("events")
        .data({ obj: eventData, type: "json" })
        .binding({
            geo: "lat|lon",
            value: "category",
            title: "name"
        })
        .type("CHART|DOT|CATEGORICAL")
        .style({
            colorscheme: ["#ffeb3b", "#ff5722", "#e91e63", "#9c27b0", "#3f51b5"],
            scale: 1.5,
            opacity: 0.9,
            showdata: "true"
        })
        .meta({
            tooltip: "<div style='background: #333; color: white; padding: 10px;'>" +
                     "<strong>{{name}}</strong><br>{{category}}</div>"
        })
        .title("Events by Category")
        .define()
);
```

### Example 17: Minimal White Background

Clean map with white background.

```javascript
ixmaps.Map("map", {
    mapType: "white",
    mode: "info"
})
.options({
    basemapopacity: 1.0,
    flushChartDraw: 1000000
})
.view({
    center: { lat: 45.65, lng: 9.5 },
    zoom: 8
})
.legend("Regions")
.layer(
    ixmaps.layer("boundaries")
        .data({ url: "regions.geojson", type: "geojson" })
        .binding({
            geo: "geometry",
            value: "NAME",
            title: "NAME"
        })
        .type("FEATURE|CHOROPLETH|CATEGORICAL")
        .style({
            colorscheme: ["100", "pastel1"],
            fillopacity: 0.7,
            linecolor: "#ffffff",
            linewidth: 3,
            showdata: "true"
        })
        .meta({
            tooltip: "<h3>{{NAME}}</h3><p>{{DESCRIPTION}}</p>"
        })
        .title("Territorial Areas")
        .define()
);
```

---

## Complete HTML Template Example

### Example 18: Full HTML File Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Interactive Map</title>
    <script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps-flat@master/ixmaps.js"></script>
    <style>
        body { margin: 0; padding: 0; font-family: -apple-system, sans-serif; }
        #map { width: 100%; height: 100vh; }
        #loading { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); z-index: 999; }
    </style>
</head>
<body>
    <div id="loading">Loading map...</div>
    <div id="map"></div>

    <script>
        const data = [
            { name: "Rome", lat: 41.9028, lon: 12.4964, population: 2870500 },
            { name: "Milan", lat: 45.4642, lon: 9.1900, population: 1378000 },
            { name: "Naples", lat: 40.8518, lon: 14.2681, population: 966000 }
        ];

        try {
            ixmaps.Map("map", {
                mapType: "VT_TONER_LITE",
                mode: "info"
            })
            .options({
                objectscaling: "dynamic",
                normalSizeScale: "1000000",
                basemapopacity: 0.6,
                flushChartDraw: 1000000
            })
            .view({
                center: { lat: 42.5, lng: 12.5 },
                zoom: 6
            })
            .legend("Italian Cities by Population")
            .layer(
                ixmaps.layer("cities")
                    .data({ obj: data, type: "json" })
                    .binding({
                        geo: "lat|lon",
                        value: "population",
                        title: "name"
                    })
                    .type("CHART|BUBBLE|SIZE|VALUES")
                    .style({
                        colorscheme: ["#0066cc"],
                        normalsizevalue: 1000000,
                        opacity: 0.7,
                        showdata: "true"
                    })
                    .meta({
                        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
                    })
                    .title("Cities")
                    .define()
            );

            setTimeout(() => document.getElementById('loading').style.display = 'none', 1000);

        } catch (error) {
            console.error('Map failed:', error);
            document.getElementById('loading').innerHTML = 'Error: ' + error.message;
        }
    </script>
</body>
</html>
```

---

## Tips & Best Practices

1. **Always test in browser** - Generated maps should open directly
2. **Start simple** - Begin with basic examples, add complexity gradually
3. **Use appropriate scales** - Adjust `normalsizevalue` based on data range
4. **Color wisely** - Use colorbrewer/tableau palettes for readability
5. **Optimize performance** - Use `flushChartDraw: 1000000` for large datasets
6. **Validate data** - Ensure lat/lon coordinates are valid (-90 to 90, -180 to 180)
7. **Browser console** - Check for JavaScript errors if map doesn't render
8. **Property names** - GeoJSON properties referenced directly, no "properties." prefix

---

For more information:
- **SKILL.md** - Core skill documentation
- **API_REFERENCE.md** - Complete API reference
- **TROUBLESHOOTING.md** - Common issues and solutions
