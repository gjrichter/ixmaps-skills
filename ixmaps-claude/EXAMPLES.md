# ixMaps Examples

Complete working examples for common use cases.

## Table of Contents

1. [Point Data Examples](#point-data-examples)
2. [GeoJSON Examples](#geojson-examples)
3. [TopoJSON Examples](#topojson-examples)
4. [Aggregation Examples](#aggregation-examples)
5. [Multi-Layer Examples](#multi-layer-examples)
6. [Custom Styling Examples](#custom-styling-examples)

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
    <script src="https://cdn.jsdelivr.net/gh/gjrichter/ixmaps_flat@master/ixmaps.js"></script>
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
