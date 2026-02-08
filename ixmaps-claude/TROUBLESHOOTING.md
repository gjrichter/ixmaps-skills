# ixMaps Troubleshooting Guide

Solutions to common issues when creating ixMaps visualizations.

## Table of Contents

1. [Map Not Displaying](#map-not-displaying)
2. [Data Not Showing](#data-not-showing)
3. [Tooltips Not Working](#tooltips-not-working)
4. [Performance Issues](#performance-issues)
5. [Styling Issues](#styling-issues)
6. [GeoJSON Issues](#geojson-issues)
7. [Coordinate Problems](#coordinate-problems)
8. [Browser Issues](#browser-issues)

---

## Map Not Displaying

### Problem: Blank page or white screen

**Possible causes:**

1. **JavaScript error in code**
   - Open browser console (F12)
   - Check for red error messages
   - Common errors:
     - Syntax error in JavaScript
     - Missing commas or brackets
     - Typo in method names

2. **ixMaps library not loaded**
   ```html
   <!-- Make sure this is in <head> -->
   <script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps_flat@master/ixmaps.js"></script>
   ```

3. **Map container has no height**
   ```css
   #map {
       width: 100%;
       height: 100vh;  /* REQUIRED - give map a height */
   }
   ```

4. **Invalid map type name**
   ```javascript
   // WRONG:
   mapType: "CartoDB Positron"

   // CORRECT (note spaces and dash):
   mapType: "CartoDB - Positron"
   ```

### Problem: Map loads but shows gray tiles

**Solution:** Check internet connection - base map tiles require network access.

---

## Data Not Showing

### Problem: Map displays but no data points/features visible

**Checklist:**

1. **Missing `showdata: "true"` in style** ⚠️ Most common issue
   ```javascript
   .style({
       colorscheme: ["#0066cc"],
       showdata: "true"  // REQUIRED - must be string "true"
   })
   ```

2. **Missing or incorrect `.binding()`**
   ```javascript
   // WRONG - missing binding:
   .data({ obj: data, type: "json" })
   .style({ ... })

   // CORRECT:
   .data({ obj: data, type: "json" })
   .binding({ geo: "lat|lon", title: "name" })  // REQUIRED
   .type("CHART|BUBBLE|SIZE|VALUES")
   .style({ ... })
   ```

3. **Invalid coordinates**
   - Latitude must be -90 to 90
   - Longitude must be -180 to 180
   - Check for swapped lat/lon
   - Check for null/undefined coordinates

4. **Data outside map view**
   - Zoom out to see if data appears
   - Check center/zoom settings match data location
   - Verify coordinate system (must be WGS84/EPSG:4326)

5. **Missing `.define()` at end of layer**
   ```javascript
   .title("Layer Title")
   .define()  // REQUIRED - don't forget this!
   ```

6. **Wrong visualization type for data**
   - Point data: Use `CHART|...` types
   - GeoJSON: Use `FEATURE` or `FEATURE|CHOROPLETH` types

### Problem: Some data shows, some doesn't

**Solutions:**

1. **Check for data validation issues**
   - Look for null/undefined values
   - Verify all required fields exist
   - Check for malformed coordinates

2. **Filter might be excluding data**
   - Remove `.filter()` temporarily to test

3. **Color scheme issue**
   - If using categorical, ensure enough colors
   - Try `colorscheme: ["100", "tableau"]` to auto-calculate

---

## Tooltips Not Working

### Problem: No tooltips appear on hover

**Solutions:**

1. **Missing `mode: "info"` in Map constructor**
   ```javascript
   // WRONG:
   ixmaps.Map("map", {
       mapType: "VT_TONER_LITE"
   })

   // CORRECT:
   ixmaps.Map("map", {
       mapType: "VT_TONER_LITE",
       mode: "info"  // REQUIRED for tooltips
   })
   ```

2. **Missing `.meta()` method**
   ```javascript
   .meta({
       tooltip: "{{theme.item.chart}}{{theme.item.data}}"
   })
   ```

3. **Invalid field names in tooltip template**
   ```javascript
   // For GeoJSON, reference properties directly:
   // WRONG:
   tooltip: "{{properties.NAME}}"

   // CORRECT:
   tooltip: "{{NAME}}"
   ```

### Problem: Tooltips show "undefined" values

**Solution:** Field names don't match data

- Check exact field names (case-sensitive)
- For GeoJSON: use property names directly
- For point data: use exact field names from data object

---

## Performance Issues

### Problem: Map loads slowly or lags

**Solutions:**

1. **Disable animation for large datasets**
   ```javascript
   .options({
       flushChartDraw: 1000000  // Instant rendering
   })
   ```

2. **Use aggregation for many points**
   ```javascript
   // Instead of 10,000 individual points:

   // Use aggregation:
   .type("CHART|BUBBLE|SIZE|AGGREGATE")
   .style({ gridwidth: "5px" })
   ```

3. **Simplify GeoJSON geometry**
   - Use TopoJSON (compressed format)
   - Simplify geometries before use (e.g., mapshaper.org)

4. **Reduce color stops in gradient**
   ```javascript
   // Instead of 20 colors:
   colorscheme: [...20 colors...]

   // Use fewer:
   colorscheme: ["#ffffcc", "#ffeda0", "#f03b20"]
   ```

5. **Use external URLs instead of inline data**
   ```javascript
   // Instead of embedding large dataset:
   .data({ obj: largeDataArray, type: "json" })

   // Use external URL:
   .data({ url: "data.json", type: "json" })
   ```

### Problem: Browser freezes when loading map

**Solution:** Data is too large

- Break into smaller datasets
- Use aggregation
- Simplify geometries
- Consider server-side tile generation for very large datasets

---

## Styling Issues

### Problem: Colors not applying

**Solutions:**

1. **Using wrong property name**
   ```javascript
   // WRONG:
   fillcolor: "#ff0000"

   // CORRECT:
   colorscheme: ["#ff0000"]
   ```

2. **Missing `showdata: "true"`**
   - See "Data Not Showing" section

3. **Invalid color format**
   ```javascript
   // WRONG:
   colorscheme: "#ff0000"  // String instead of array

   // CORRECT:
   colorscheme: ["#ff0000"]  // Array
   ```

4. **Categorical coloring needs dynamic scheme**
   ```javascript
   // For categorical data:
   .binding({ value: "category_field" })
   .type("CHART|DOT|CATEGORICAL")
   .style({
       colorscheme: ["100", "tableau"],  // Dynamic
       showdata: "true"
   })
   ```

### Problem: Symbols too small/large

**Solutions:**

1. **Adjust scale**
   ```javascript
   .style({
       scale: 2.0  // Make 2x larger
   })
   ```

2. **Adjust normalSizeScale (map-level)**
   ```javascript
   .options({
       objectscaling: "dynamic",
       normalSizeScale: "2000000"  // Larger = smaller symbols
   })
   ```

3. **Set normalsizevalue (layer-level)**
   ```javascript
   .type("CHART|BUBBLE|SIZE|VALUES")
   .type("FEATURE")
   .type("FEATURE|CHOROPLETH")
   .style({
       normalsizevalue: 100000  // Value of 100k = 30px
   })
   ```

### Problem: Missing `normalSizeScale` error

**Solution:** When using `objectscaling: "dynamic"`, MUST include `normalSizeScale`

```javascript
.options({
    objectscaling: "dynamic",
    normalSizeScale: "1000000"  // REQUIRED
})
```

---

## GeoJSON Issues

### Problem: GeoJSON features not displaying

**Solutions:**

1. **Wrong visualization type**
   ```javascript
   // WRONG for GeoJSON:

   // CORRECT:
   // or
   ```

2. **Missing `value: "$item$"` for simple features**
   ```javascript
   .binding({
       geo: "geometry",
       value: "$item$",  // REQUIRED for simple features
       title: "name"
   })
   ```

3. **Wrong property reference**
   ```javascript
   // WRONG:
   .binding({ title: "properties.NAME" })

   // CORRECT (direct reference):
   .binding({ title: "NAME" })
   ```

4. **Invalid GeoJSON format**
   - Validate at http://geojson.io
   - Check for valid coordinate arrays
   - Verify coordinate order [lng, lat] not [lat, lng]

### Problem: TopoJSON not loading

**Solutions:**

1. **Check data type**
   ```javascript
   .data({
       url: "data.json",
       type: "topojson"  // Not "json"
   })
   ```

2. **CORS issues with external URLs**
   - File must be served from CORS-enabled server
   - Test with public URLs first
   - Consider using CDN or hosting on GitHub

---

## Type Modifier Issues

### Problem: Using deprecated EXACT classification

**Common mistake:**

```javascript
// WRONG - EXACT is deprecated:
.type("FEATURE|CHOROPLETH|EXACT")

// CORRECT - Use modern classification methods:
.type("FEATURE|CHOROPLETH|QUANTILE")
.type("FEATURE|CHOROPLETH|EQUIDISTANT")
.type("FEATURE|CHOROPLETH|CATEGORICAL")
```

**Why EXACT is deprecated:**

1. **Obsolete algorithm** - From older ixmaps versions
2. **Replaced by better methods** - QUANTILE, EQUIDISTANT, CATEGORICAL
3. **Can cause errors** - Not supported in current ixmaps
4. **Like CATEGORICAL was** - EXACT was a classification method, not a modifier

**Background:**
- In older ixmaps: `EXACT` was used like `CATEGORICAL` as a classification method
- In current ixmaps: `EXACT` is deprecated and must not be used
- Exact values are preserved regardless of classification method chosen

**Valid classification methods:**
- `QUANTILE` - Equal frequency distribution
- `EQUIDISTANT` - Equal interval ranges
- `CATEGORICAL` - One color per category

**Chart types and options:**
- `BUBBLE`, `PIE`, `BAR`, `DOT`, `GRID`
- `SIZE`, `VALUES`, `AGGREGATE`

**Never use:** `EXACT` ❌ (deprecated)

---

## Coordinate Problems

### Problem: Data appears in wrong location

**Solutions:**

1. **Swapped lat/lon**
   ```javascript
   // Check your data - might be lon,lat instead of lat,lon
   // If so, swap in binding:
   .binding({ geo: "lon|lat" })  // Reverse order
   ```

2. **Wrong coordinate system**
   - ixMaps requires WGS84 (EPSG:4326)
   - If data is in different projection, convert first
   - GeoJSON coordinates must be [longitude, latitude]

3. **Coordinates as strings instead of numbers**
   ```javascript
   // WRONG:
   { lat: "41.9", lon: "12.5" }

   // CORRECT:
   { lat: 41.9, lon: 12.5 }
   ```

### Problem: Points cluster at 0,0 (null island)

**Solution:** Missing or invalid coordinates

- Check for null/undefined lat/lon values
- Verify field names match data
- Ensure coordinates are numeric

---

## Browser Issues

### Problem: Works in Chrome but not Safari/Firefox

**Solutions:**

1. **Console polyfills**
   - Add to beginning of script:
   ```javascript
   if (!window.console) window.console = {};
   if (!console.log) console.log = function() {};
   ```

2. **ES6 syntax**
   - Avoid arrow functions in older browsers
   - Use `var` instead of `const`/`let` if targeting IE

### Problem: CORS errors with external data

**Solution:** Data must be served from CORS-enabled server

- Use CDN with CORS headers
- Host on GitHub Pages (CORS-enabled)
- Use https://cors-anywhere.herokuapp.com/ proxy (development only)
- Embed data inline as workaround

### Problem: File loads in browser but not from file://

**Solution:** Use local web server

```bash
# Python 3:
python -m http.server 8000

# Python 2:
python -m SimpleHTTPServer 8000

# Node.js:
npx http-server
```

Then open: http://localhost:8000/map.html

---

## Debugging Checklist

When something doesn't work, check in order:

1. ✅ Open browser console (F12) - check for errors
2. ✅ Verify ixMaps script loaded
3. ✅ Check map container has height
4. ✅ Verify `showdata: "true"` in style
5. ✅ Confirm `.binding()` is present and correct
6. ✅ Check `.meta()` is present
7. ✅ Verify `.define()` at end of layer
8. ✅ Validate data format and coordinates
9. ✅ Check visualization type matches data
10. ✅ Verify map center/zoom shows data area

---

## Getting Help

If you're still stuck:

1. **Check browser console** - error messages are very helpful
2. **Simplify** - Start with minimal example, add complexity gradually
3. **Validate data** - Use online validators for JSON/GeoJSON
4. **Compare with examples** - See EXAMPLES.md for working code
5. **Check API reference** - See API_REFERENCE.md for correct syntax

---

## Common Error Messages

### "Cannot read property 'geo' of undefined"

**Cause:** Missing `.binding()`

**Fix:** Add binding method:
```javascript
.binding({ geo: "lat|lon", title: "name" })
```

### "normalSizeScale is required with objectscaling"

**Cause:** Using `objectscaling: "dynamic"` without `normalSizeScale`

**Fix:**
```javascript
.options({
    objectscaling: "dynamic",
    normalSizeScale: "1000000"  // Add this
})
```

### "Data not loaded" or "Data is undefined"

**Cause:** Data URL unreachable or wrong format

**Fix:**
- Check URL is accessible
- Verify CORS headers
- Check data type parameter matches file format
- Test URL directly in browser

### "Invalid GeoJSON geometry"

**Cause:** Malformed GeoJSON structure

**Fix:**
- Validate at http://geojson.io
- Check coordinate arrays format
- Verify geometry type is valid

---

## Best Practices to Avoid Issues

1. **Always start with working example**
   - Copy from EXAMPLES.md
   - Modify incrementally
   - Test after each change

2. **Use validation tools**
   - JSON: jsonlint.com
   - GeoJSON: geojson.io
   - TopoJSON: mapshaper.org

3. **Keep browser console open**
   - Catch errors immediately
   - Watch for warnings

4. **Test with small datasets first**
   - Verify logic works
   - Then scale up

5. **Follow the critical rules**
   - Include `.binding()`
   - Include `showdata: "true"`
   - Include `.meta()`
   - Include `.define()`

6. **Use proper method order**
   - data → binding → type → style → meta → title → define

7. **Save working versions**
   - Keep backups of working code
   - Easy to revert if something breaks

---

For more information:
- **SKILL.md** - Core skill documentation
- **EXAMPLES.md** - Working code examples
- **API_REFERENCE.md** - Complete API reference
