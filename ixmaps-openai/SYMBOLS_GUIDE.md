# ixMaps Custom Symbols Guide

## How to Use Custom SVG Symbols

### ✅ Correct Usage

```javascript
.type("CHART|SYMBOL|CATEGORICAL")
.style({
    colorscheme: ["#d32f2f", "#ff9800"],
    symbols: [
        "https://cdn.example.com/icon1.svg",
        "https://cdn.example.com/icon2.svg"
    ],
    scale: 0.1,  // Symbols are typically larger, use smaller scale
    showdata: "true"
})
```

## Critical Rules

### 1. Property Name: `symbols` (plural)
```javascript
// ✅ CORRECT
symbols: ["url1.svg", "url2.svg"]

// ❌ WRONG
symbol: "url.svg"
```

### 2. Must Be an Array
Even for single symbol, use array syntax:

```javascript
// ✅ CORRECT - Non-categorical (single symbol)
symbols: ["https://example.com/icon.svg"]

// ✅ CORRECT - Categorical (one per category)
symbols: [
    "https://example.com/icon-fixed.svg",
    "https://example.com/icon-mobile.svg"
]

// ❌ WRONG
symbols: "https://example.com/icon.svg"
```

### 3. Array Length Must Match Categories
For `CATEGORICAL` visualizations:

```javascript
// If you have 2 categories (e.g., "Fixed", "Mobile")
symbols: ["icon1.svg", "icon2.svg"]  // ✅ 2 symbols

// If you have 3 categories
symbols: ["icon1.svg", "icon2.svg", "icon3.svg"]  // ✅ 3 symbols

// ❌ WRONG - Mismatch
// 2 categories but 1 symbol
symbols: ["icon1.svg"]
```

### 4. Symbol URLs Must Be Accessible
- Use CDN URLs (not local file paths)
- Ensure CORS is enabled on the server
- HTTPS is recommended
- SVG format works best

### 5. Scale Is Much Smaller for Symbols
Symbols are typically larger than dots:

```javascript
// For dots
scale: 2  // Normal scale

// For symbols
scale: 0.1  // Much smaller scale
```

## Visualization Types with Symbols

### CHART|SYMBOL (Non-categorical)
All points use the same symbol:

```javascript
.type("CHART|SYMBOL")
.style({
    colorscheme: ["#0066cc"],
    symbols: ["https://files.svgcdn.io/icon.svg"],
    scale: 0.1,
    showdata: "true"
})
```

### CHART|SYMBOL|CATEGORICAL
Different symbols for different categories:

```javascript
.binding({
    geo: "lat|lon",
    value: "category_field",  // Field to categorize by
    title: "name"
})
.type("CHART|SYMBOL|CATEGORICAL")
.style({
    colorscheme: ["#d32f2f", "#ff9800", "#4caf50"],  // 3 colors
    symbols: [
        "https://cdn.com/icon-red.svg",
        "https://cdn.com/icon-orange.svg",
        "https://cdn.com/icon-green.svg"
    ],  // 3 symbols matching 3 categories
    scale: 0.15,
    showdata: "true"
})
```

### CHART|SYMBOL|SIZE
Symbols sized by value:

```javascript
.binding({
    geo: "lat|lon",
    value: "population",  // Size by this field
    title: "name"
})
.type("CHART|SYMBOL|SIZE")
.style({
    colorscheme: ["#0066cc"],
    symbols: ["https://cdn.com/icon.svg"],
    scale: 0.1,
    normalsizevalue: "500000",  // Value = default size
    showdata: "true"
})
```

## Free SVG Icon Resources

### Recommended CDNs with Direct SVG Access:

1. **SVG CDN (Material Symbols)**
   - URL format: `https://files.svgcdn.io/material-symbols/icon-name.svg`
   - Example: `https://files.svgcdn.io/material-symbols/speed-camera.svg`
   - License: Apache 2.0
   - Reliable, fast, no authentication needed

2. **Simple Icons**
   - URL format: `https://cdn.simpleicons.org/iconname`
   - License: CC0 1.0 (Public Domain)
   - Brand icons available

3. **Iconify API**
   - URL format: `https://api.iconify.design/collection/icon.svg`
   - Example: `https://api.iconify.design/mdi/camera.svg`
   - Large collection

### Other Resources (may require download):
- **Flaticon** - https://www.flaticon.com (download required)
- **Icons8** - https://icons8.com (download or paid API)
- **IconScout** - https://iconscout.com (download required)
- **FreeSVG** - https://freesvg.org (download required)

## Common Icon Categories

### Speed/Traffic:
- `speed-camera.svg` - Speed cameras
- `traffic-light.svg` - Traffic lights
- `warning.svg` - Warning signs

### Location/Places:
- `location-pin.svg` - Generic location
- `restaurant.svg` - Food/dining
- `hotel.svg` - Accommodation
- `hospital.svg` - Healthcare

### Transport:
- `bus.svg` - Bus stops
- `train.svg` - Train stations
- `airport.svg` - Airports
- `parking.svg` - Parking

## Complete Working Example

```javascript
// Speed cameras map with custom icons
const cameraData = [
    { name: "Camera 1", lat: 45.4642, lon: 9.1900, type: "Fixed" },
    { name: "Camera 2", lat: 45.4750, lon: 9.2000, type: "Mobile" }
];

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
    center: { lat: 45.4642, lng: 9.1900 },
    zoom: 12
})
.legend("Speed Cameras")
.layer("cameras")
    .data({ data: cameraData, type: "json" })
    .binding({
        geo: "lat|lon",
        value: "type",  // Categorize by type
        title: "name"
    })
    .type("CHART|SYMBOL|CATEGORICAL")
    .style({
        colorscheme: ["#d32f2f", "#ff9800"],  // Red, Orange
        symbols: [
            "https://files.svgcdn.io/material-symbols/speed-camera.svg",
            "https://files.svgcdn.io/material-symbols/speed-camera.svg"
        ],
        scale: 0.1,  // Small scale for symbols
        opacity: 0.9,
        showdata: "true"
    })
    .meta({
        tooltip: "<h3>{{name}}</h3><p>Type: {{type}}</p>"
    })
    .title("Speed Cameras")
    .define();
```

## Troubleshooting

### Symbols Not Showing
```javascript
// ❌ Problem: Using singular "symbol"
symbol: "url.svg"

// ✅ Solution: Use plural "symbols" with array
symbols: ["url.svg"]
```

### Symbols Too Large/Small
```javascript
// ❌ Problem: Scale too large
scale: 2  // Symbols huge

// ✅ Solution: Use much smaller scale
scale: 0.1  // Appropriate for symbols
```

### Wrong Number of Symbols
```javascript
// ❌ Problem: 3 categories, 2 symbols
colorscheme: ["#f00", "#0f0", "#00f"],  // 3 colors
symbols: ["icon1.svg", "icon2.svg"]     // Only 2 symbols

// ✅ Solution: Match symbol count to categories
symbols: ["icon1.svg", "icon2.svg", "icon3.svg"]  // 3 symbols
```

### CORS Errors
```javascript
// ❌ Problem: Using local file or restricted CDN
symbols: ["file:///local/icon.svg"]

// ✅ Solution: Use public CDN with CORS enabled
symbols: ["https://files.svgcdn.io/material-symbols/icon.svg"]
```

### Symbol Not Loading from CDN
- Check browser console for errors
- Verify URL is accessible (paste in browser)
- Ensure HTTPS (not HTTP)
- Use reliable CDNs listed above

## Best Practices

1. **Always use `symbols` (plural)**, even for single symbol
2. **Match symbol array length** to number of categories
3. **Use small scale values** (0.05 - 0.2 typical range)
4. **Use reliable CDNs** like files.svgcdn.io
5. **Test symbol URLs** in browser before using
6. **Keep SVGs simple** - complex symbols may render slowly
7. **Consider colorscheme** - symbols inherit fill color from colorscheme

## Summary

### Quick Reference:

| Feature | Correct Syntax | Wrong Syntax |
|---------|---------------|--------------|
| Property | `symbols:` | `symbol:` |
| Format | `["url1", "url2"]` | `"url"` |
| Scale | `0.1` | `2` |
| Categories | Match array length | Mismatch |
| URLs | CDN HTTPS | Local files |

### Default Template:

```javascript
.type("CHART|SYMBOL|CATEGORICAL")
.style({
    colorscheme: ["color1", "color2"],
    symbols: ["url1.svg", "url2.svg"],
    scale: 0.1,
    showdata: "true"
})
```
