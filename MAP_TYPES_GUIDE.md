# ixMaps Valid Map Types Reference

## ⚠️ CRITICAL: Always Use These Exact Names

Map types in ixMaps are **case-sensitive** and must match exactly. Using invalid map type names will cause the map to fail silently or display incorrectly.

## ✅ Verified Working Map Types

These map types are confirmed to work with ixMaps:

### Recommended (Always Work)

```javascript
mapType: "VT_TONER_LITE"  // ✅ RECOMMENDED - Clean minimal basemap (default)
```

```javascript
mapType: "white"  // ✅ Plain white background (no map tiles)
```

### CartoDB Maps (Note the Spaces!)

```javascript
mapType: "CartoDB - Positron"  // ✅ Light, minimal CartoDB style
```

```javascript
mapType: "CartoDB - Dark matter"  // ✅ Dark CartoDB style
```

**CRITICAL:** CartoDB types REQUIRE spaces around the dash:
- ✅ CORRECT: `"CartoDB - Positron"`
- ❌ WRONG: `"CartoDB Positron"`
- ❌ WRONG: `"CartoDB-Positron"`

### Stamen Maps

```javascript
mapType: "Stamen Terrain"  // ✅ Terrain with hill shading
```

## ✅ OpenStreetMap

Use the full name with renderer suffix:

```javascript
mapType: "OpenStreetMap - Osmarenderer"  // ✅ Correct full name
```

**Note:** `"OpenStreetMap"` alone does not work — always use `"OpenStreetMap - Osmarenderer"`.

## 🚫 Common Mistakes to Avoid

### Wrong: Invalid Map Type Names
```javascript
// ❌ These DON'T exist or are wrong:
mapType: "OSM"
mapType: "Leaflet"
mapType: "Google Maps"
mapType: "Mapbox"
mapType: "CartoDB Positron"  // Missing spaces around dash!
mapType: "CartoDB - Dark_Matter"  // Wrong: underscore+capital; use "CartoDB - Dark matter"
mapType: "openstreetmap"     // Wrong case
mapType: "OpenStreetMap"     // Missing renderer; use "OpenStreetMap - Osmarenderer"
mapType: "vt_toner_lite"     // Wrong case
```

### Correct: Valid Map Type Names
```javascript
// ✅ These DO exist:
mapType: "VT_TONER_LITE"     // Correct case
mapType: "CartoDB - Positron" // Correct spacing
mapType: "white"              // Lowercase for this one
```

## 📋 Quick Reference Table

| Map Type | Status | Use Case | Notes |
|----------|--------|----------|-------|
| `"VT_TONER_LITE"` | ✅ Verified | **Default choice** | Clean, minimal, always works |
| `"white"` | ✅ Verified | Data-focused viz | No basemap distractions |
| `"CartoDB - Positron"` | ✅ Verified | Light, modern style | **Note the spaces!** |
| `"CartoDB - Dark matter"` | ✅ Verified | Dark theme | **Note the spaces!** |
| `"Stamen Terrain"` | ✅ Verified | Topographic maps | Shows elevation |
| `"OpenStreetMap - Osmarenderer"` | ✅ Verified | Standard OSM | Use full name with Osmarenderer |

## 💡 Best Practices

### 1. Always Use VT_TONER_LITE as Default
Unless you have a specific reason to use another basemap, stick with the default:

```javascript
ixmaps.Map("map", {
    mapType: "VT_TONER_LITE",
    mode: "info"
})
```

### 2. For Data-Heavy Visualizations, Use White Background
When your data overlays are dense and colorful, minimize distraction:

```javascript
ixmaps.Map("map", {
    mapType: "white",
    mode: "info"
})
```

### 3. Adjust Basemap Opacity
Instead of changing map types, consider adjusting `basemapopacity`:

```javascript
.options({
    basemapopacity: 0.3  // Make basemap very subtle
})
```

### 4. When In Doubt, Test
If unsure whether a map type works, test with `"VT_TONER_LITE"` first, then experiment.

## 🔍 How to Verify a Map Type

If you're unsure whether a map type is valid:

1. **Check this guide first**
2. **Default to `"VT_TONER_LITE"`** - it always works
3. **Test in browser** - invalid types may fail silently
4. **Check browser console** for errors

## 🛠️ Troubleshooting

### Map Not Displaying
```javascript
// ❌ Problem: Used bare OpenStreetMap name
mapType: "OpenStreetMap"

// ✅ Solution: Use full name with renderer
mapType: "OpenStreetMap - Osmarenderer"
// or use the safe default:
mapType: "VT_TONER_LITE"
```

### CartoDB Map Not Loading
```javascript
// ❌ Problem: Missing spaces
mapType: "CartoDB Positron"

// ✅ Solution: Add spaces around dash
mapType: "CartoDB - Positron"
```

### Map Looks Wrong
```javascript
// Check case sensitivity
// ❌ Wrong: "vt_toner_lite"
// ✅ Correct: "VT_TONER_LITE"
```

## 📚 Related Documentation

- **SKILL.md** - Main skill documentation
- **API_REFERENCE.md** - Complete API reference
- **EXAMPLES.md** - Working code examples
- **TROUBLESHOOTING.md** - Common issues and fixes
- **UI_YAML_GUIDE.md** - `maptype`/`basemapopacity`/`mapProjection` as `skill-ui.yaml` parameters
- **CSS_INTEROP.md** - Dark-basemap tooltip contrast fix
- **RUNTIME_CONTROLS.md** - Runtime style/opacity changes after load
- **DATA_JS_GUIDE.md** - Data loading (unrelated to basemap choice, but same reference set)
- **FACETS_GUIDE.md** - Facet sidebar patterns layered on top of a chosen basemap
- **EXTENSIONS_GUIDE.md** - Computed overlay layers (Turf.js, KDE) rendered above the basemap

## 🔄 Updates

This guide will be updated as new map types are verified or deprecated.

**Last Updated:** 2026-02-11
**Status:** Living document - always use the most conservative/tested options

---

## Summary: Safe Map Type Choices

**Just want it to work? Use one of these:**

1. **`"VT_TONER_LITE"`** - Best default choice (90% of use cases)
2. **`"white"`** - For data-focused visualizations
3. **`"CartoDB - Positron"`** - Modern, light aesthetic (remember the spaces!)

**Common mistakes:**
- `"OpenStreetMap"` - Missing renderer suffix; use `"OpenStreetMap - Osmarenderer"` instead
