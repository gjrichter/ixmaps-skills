# ixMaps Examples

## Point Data (Bubble)

```javascript
ixmaps.layer("cities")
    .data({ obj: cityData, type: "json" })
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
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("Italian Cities by Population")
    .define();
```

## GeoJSON (Choropleth)

```javascript
ixmaps.layer("regions")
    .data({ url: "regions.geojson", type: "geojson" })
    .binding({
        geo: "geometry",
        value: "$item$",
        title: "region_name"
    })
    .type("FEATURE|CHOROPLETH|EQUIDISTANT")
    .style({
        colorscheme: ["#ffffcc", "#ff0000"],
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("Regions")
    .define();
```

## TopoJSON (Categorical)

```javascript
ixmaps.layer("countries")
    .data({
        url: "https://s3.eu-central-1.amazonaws.com/maps.ixmaps.com/topojson/CNTR_RG_10M_2020_4326.json",
        type: "topojson"
    })
    .binding({
        geo: "geometry",
        value: "NAME_ENGL",
        title: "NAME_ENGL"
    })
    .type("FEATURE|CHOROPLETH|CATEGORICAL")
    .style({
        colorscheme: ["100", "tableau"],
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("European Countries by Name")
    .define();
```

## Aggregated Point Density

```javascript
ixmaps.layer("incident_density")
    .data({ obj: data, type: "json" })
    .binding({
        geo: "lat|lon",
        value: "$item$",
        title: "via"
    })
    .type("CHART|BUBBLE|SIZE|AGGREGATE")
    .style({
        colorscheme: ["#ffeb3b", "#ff9800", "#f44336"],
        gridwidth: "5px",
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .title("Incident Density")
    .define();
```

## Map Options (Animation Control)

```javascript
ixmaps.Map("map", { mapType: "CartoDB - Positron" })
    .options({
        objectscaling: "dynamic",
        normalSizeScale: "1000000",
        basemapopacity: 0.7,
        flushChartDraw: 1000000
    });
```
