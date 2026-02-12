# ixMaps Troubleshooting Guide

Solutions to common issues when creating ixMaps visualizations.

## Table of Contents

1. [Map Not Displaying](#map-not-displaying)
2. [Data Not Showing](#data-not-showing)
3. [Data Hosting Issues](#data-hosting-issues) ⭐ NEW
4. [Tooltips Not Working](#tooltips-not-working)
5. [Performance Issues](#performance-issues)
6. [Styling Issues](#styling-issues)
7. [GeoJSON Issues](#geojson-issues)
8. [Coordinate Problems](#coordinate-problems)
9. [Browser Issues](#browser-issues)

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

### Problem: Diverging scale not centered correctly

**Common mistake:** Using odd number of colors with `rangecentervalue`

```javascript
// WRONG - 7 colors (odd number):
.style({
    colorscheme: [
        "#b71c1c", "#d32f2f", "#e57373",  // 3 below
        "#ff9800",                          // 1 at center (wrong!)
        "#66bb6a", "#43a047", "#2e7d32"   // 3 above
    ],
    rangecentervalue: 65
})
// Creates unequal distribution with middle color AT 65

// CORRECT - 6 colors (even number):
.style({
    colorscheme: [
        "#b71c1c", "#d32f2f", "#e57373",  // 3 below 65%
        "#66bb6a", "#43a047", "#2e7d32"   // 3 above 65%
    ],
    rangecentervalue: 65  // 65% is the BOUNDARY between reds and greens
})
```

**Why even numbers required:**
- Center value is a BOUNDARY, not a color itself
- With 6 colors: 3 below + 3 above = equal distribution
- With 7 colors: creates unbalanced scale
- Always use even numbers: 4, 6, 8, 10, etc.

**Note:** `ranges` property works with any number of colors since you explicitly define breaks.

---

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

## Data Hosting Issues

### Problem: CORS errors with local files

**Error:** "Access to fetch at 'file:///...' from origin 'null' has been blocked by CORS policy"

**Cause:** Browsers block local file access due to CORS security restrictions. ixMaps cannot read CSV/JSON files from your filesystem when opening HTML files locally (file:// protocol).

**Solution:** Use external hosting

1. **GitHub + CDN (recommended):**
   ```javascript
   .data({
       url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/path/to/data.csv",
       type: "csv"
   })
   ```
   - Free, fast, reliable
   - CORS-enabled by default
   - See DATA_HOSTING_GUIDE.md for setup

2. **Inline data (for small datasets):**
   ```javascript
   const data = [{...}];  // Embed in HTML
   .data({ obj: data, type: "json" })
   ```
   - Works immediately
   - No external dependencies
   - Bloats HTML for large datasets

### Problem: Data URL returns 404

**Error:** "Failed to load resource: the server responded with a status of 404 (Not Found)"

**Possible causes:**

1. **Incorrect file path (case-sensitive)**
   ```javascript
   // WRONG:
   url: ".../By-Date/2026-02/Cities.csv"  // Wrong capitalization

   // CORRECT:
   url: ".../by-date/2026-02/cities.csv"  // Exact path
   ```

2. **Wrong branch name**
   ```javascript
   // Check your default branch
   url: ".../main/..."  // or
   url: ".../master/..."
   ```

3. **File not yet pushed to GitHub**
   ```bash
   # Verify file exists on GitHub:
   https://github.com/<user>/ixmaps-data/blob/main/path/to/file.csv
   ```

4. **Repository is private**
   - Raw GitHub URLs only work with public repositories
   - Make repository public for CORS access

**Solutions:**
```bash
# Verify exact path
ls -la ~/ixmaps-data/by-date/2026-02/

# Check git status
git status

# Verify on GitHub
# Visit: https://github.com/<user>/ixmaps-data
# Navigate to file location
```

### Problem: CDN not updating with new data

**Error:** Map shows old data after updating CSV file on GitHub

**Cause:** jsDelivr CDN caches files for 5-10 minutes. Your updates haven't synced yet.

**Solutions:**

1. **Wait 5-10 minutes** (recommended for production)
   - CDN will automatically sync
   - Check again after delay

2. **Use raw URL for development:**
   ```javascript
   // Development - immediate updates, no cache
   url: "https://raw.githubusercontent.com/<user>/ixmaps-data/main/path/to/data.csv"

   // Production - fast CDN, cached
   url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/path/to/data.csv"
   ```

3. **Cache bust (temporary fix):**
   ```javascript
   url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/path/to/data.csv?v=" + Date.now()
   ```

4. **Use version tags (best for published maps):**
   ```bash
   # Tag new version
   git tag -a v1.0.1 -m "Update dataset"
   git push origin v1.0.1
   ```

   ```javascript
   // Immutable version URL
   url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@v1.0.1/path/to/data.csv"
   ```

### Problem: Rate limit errors with raw GitHub URLs

**Error:** "API rate limit exceeded for..." (HTTP 429)

**Cause:** GitHub raw content has rate limits:
- Unauthenticated: ~60 requests/hour
- Authenticated: ~5000 requests/hour

**Solutions:**

1. **Switch to CDN URLs (no rate limits):**
   ```javascript
   // No limits, faster
   url: "https://cdn.jsdelivr.net/gh/<user>/ixmaps-data@main/path/to/data.csv"
   ```

2. **Reduce request frequency:**
   - Don't reload map repeatedly during development
   - Cache data in browser

3. **Wait for limit reset:**
   - Limits reset after 1 hour
   - Check `X-RateLimit-Reset` header

### Problem: Token authentication failed

**Error:** "Bad credentials" or "Not Found" when using GitHub API for automated uploads

**Possible causes:**

1. **Token expired**
   - Fine-grained tokens expire (default: 90 days)
   - Create new token at https://github.com/settings/tokens

2. **Wrong permissions**
   - Token needs: Contents (Read and Write)
   - Repository access: ixmaps-data only

3. **Token not in environment**
   ```bash
   # Check if set
   echo $IXMAPS_GITHUB_TOKEN

   # Set token
   export IXMAPS_GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
   export IXMAPS_REPO_USER="<your-username>"

   # Make permanent (add to ~/.bashrc or ~/.zshrc)
   echo 'export IXMAPS_GITHUB_TOKEN="ghp_xxx"' >> ~/.bashrc
   ```

4. **Token in wrong format**
   ```bash
   # WRONG:
   export IXMAPS_GITHUB_TOKEN=ghp_xxx  # Missing quotes

   # CORRECT:
   export IXMAPS_GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
   ```

**Solutions:**
```bash
# Re-create token with correct permissions
# 1. Go to: https://github.com/settings/tokens
# 2. Generate new token (fine-grained)
# 3. Repository access: Only ixmaps-data
# 4. Permissions: Contents (Read and Write)
# 5. Expiration: 90 days
# 6. Generate and copy token

# Set in environment
export IXMAPS_GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
export IXMAPS_REPO_USER="your-username"

# Test
./upload-helper.sh test.csv
```

### Problem: File too large for GitHub

**Error:** "file exceeds maximum size" (HTTP 422)

**GitHub limits:** 100 MB per file

**Solutions:**

1. **Compress data:**
   ```bash
   # Convert GeoJSON to TopoJSON (much smaller)
   npm install -g topojson
   geo2topo data.geojson > data.topojson
   ```

2. **Split large files:**
   ```bash
   # Split CSV into chunks
   split -l 10000 large.csv chunk-
   # Creates: chunk-aa, chunk-ab, chunk-ac, etc.
   ```

3. **Reduce precision:**
   ```javascript
   // Round coordinates to fewer decimal places
   // 6 decimals = ~10cm precision (usually enough)
   lat: 41.902800  // 6 decimals
   lon: 12.496400  // 6 decimals

   // Not: 41.90280000000000 (unnecessary precision)
   ```

4. **Aggregate data:**
   - Use grid aggregation instead of individual points
   - Remove unnecessary fields from CSV
   - Filter out low-importance data

5. **Alternative hosting (for very large files):**
   - S3 + CloudFront (costs money)
   - Backblaze B2 (cheaper)
   - CloudFlare R2 (no bandwidth fees)

### Problem: Data shows but map is slow

**Cause:** Dataset too large for browser to handle efficiently

**Solutions:**

1. **Use aggregation:**
   ```javascript
   // Instead of 100,000 individual points
   .type("CHART|BUBBLE|SIZE|AGGREGATE")
   .style({
       gridwidth: "5px",  // Aggregate into grid
       showdata: "true"
   })
   ```

2. **Reduce data volume:**
   ```bash
   # Filter CSV to reduce rows
   awk 'NR==1 || $3>1000000 {print}' data.csv > filtered.csv
   ```

3. **Use TopoJSON for geometry:**
   - 80-90% smaller than GeoJSON
   - Faster to load and parse

4. **Simplify geometries:**
   ```bash
   # Use mapshaper to simplify
   mapshaper input.json -simplify 10% -o output.json
   ```

### Quick Reference: Data Hosting

| Scenario | Solution | URL Format |
|----------|----------|------------|
| Local file won't load | Use GitHub hosting | `cdn.jsdelivr.net/gh/...` |
| 404 Not Found | Check path, branch, public | Verify on GitHub web |
| CDN not updating | Wait 5-10 min or use raw URL | `raw.githubusercontent.com/...` |
| Rate limits | Switch to CDN | `cdn.jsdelivr.net/gh/...` |
| Token failed | Re-create with correct permissions | Environment variable |
| File too large | Compress, split, or aggregate | TopoJSON, chunked files |
| Slow performance | Aggregate or simplify data | AGGREGATE type, gridwidth |

**For complete guide, see DATA_HOSTING_GUIDE.md**

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
