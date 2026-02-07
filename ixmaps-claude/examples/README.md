# ixMaps Examples

This directory contains working HTML examples demonstrating different features of the ixMaps Claude Skill.

## 📁 Examples

### 1. lombardia_ambiti_esempio.html
**Type**: Simple FEATURE visualization

Demonstrates:
- Basic GeoJSON loading
- Simple feature display with uniform coloring
- Proper binding with `geo: "geometry"` and `value: "$item$"`
- Clean VT_TONER_LITE base map

**View**: Open the file in any modern web browser

```javascript
.type("FEATURE")
```

---

### 2. lombardia_ambiti_choropleth.html
**Type**: Choropleth map with quantile coloring

Demonstrates:
- GeoJSON choropleth visualization
- Quantile-based color distribution
- Color scheme from yellow to dark red
- CartoDB Positron base map

**View**: Open the file in any modern web browser

```javascript
.type("FEATURE|CHOROPLETH|QUANTILE")
```

---

### 3. lombardia_ambiti_completo.html
**Type**: Complete example with all best practices

Demonstrates:
- All required properties (`showdata: "true"`)
- Meta method with tooltip configuration
- Proper method chain order
- Info panel with instructions
- Interactive hover tooltips

**View**: Open the file in any modern web browser

This is the **recommended example** to study for understanding all ixMaps requirements.

```javascript
.binding({ geo: "geometry", value: "$item$" })
.style({ colorscheme: [...], opacity: 0.7, showdata: "true" })
.meta({ tooltip: "{{theme.item.chart}}{{theme.item.data}}" })
.type("FEATURE|CHOROPLETH|QUANTILE")
```

---

## 🗺️ Data Source

All examples use the Lombardia territorial boundaries GeoJSON:
```
https://s3.fr-par.scw.cloud/ixmaps.data/test%20only/lombardia_ambiti_territoriali_confini_wgs84.geojson
```

## 🚀 How to Use These Examples

1. **Open directly in browser**: Double-click any HTML file
2. **Modify for your needs**: Edit the JavaScript configuration
3. **Use as templates**: Copy and adapt for your own data

## 📚 Key Takeaways

From these examples, you'll learn:

✅ **Correct type for GeoJSON**: `FEATURE` or `FEATURE|CHOROPLETH`
✅ **Required binding**: `{ geo: "geometry", value: "$item$" }`
✅ **Style property**: Always include `showdata: "true"`
✅ **Meta method**: Always include tooltip configuration
✅ **Method order**: data → binding → style → meta → type → title → define

## 🔧 Customization Tips

### Change Colors
```javascript
.style({
    colorscheme: ["#yourcolor1", "#yourcolor2"],
    // ... other properties
})
```

### Change Base Map
```javascript
ixmaps.Map("map", {
    mapType: "OpenStreetMap"  // or VT_TONER_LITE, CartoDB - Positron, etc.
})
```

### Adjust Map View
```javascript
.view({
    center: { lat: YOUR_LAT, lng: YOUR_LNG },
    zoom: YOUR_ZOOM_LEVEL
})
```

## ❓ Questions?

Refer to the main [README.md](../README.md) and [SKILL.md](../SKILL.md) for complete documentation.
