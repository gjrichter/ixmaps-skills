# ixMaps Claude Skill

A Claude Code skill for creating interactive maps using the [ixMaps framework](https://github.com/gjrichter/ixmaps_flat).

[![ixMaps](https://img.shields.io/badge/ixMaps-Interactive%20Maps-blue)](https://github.com/gjrichter/ixmaps_flat)
[![Claude Code](https://img.shields.io/badge/Claude-Code%20Skill-purple)](https://claude.ai)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

> **💡 New to ixMaps?** This skill works in both **Claude Code** (command-line) and **Claude Chat** (conversational). 
> - **Chat users**: Jump to [Using in Claude Chat](#-using-in-claude-chat-not-claude-code)
> - **Code users**: See [Quick Start for Claude Code](#-quick-start-for-claude-code) below

## 🗺️ What is this?

This skill enables Claude to generate interactive HTML maps with ixMaps using simple natural language commands.

**Works in two modes:**
- **Claude Code**: Use `/create-ixmap` skill command for file-based workflow
- **Claude Chat**: Share the skill, then request maps conversationally

Perfect for data visualization, geographic analysis, and creating beautiful interactive maps.

## ✨ Features

* **Multiple visualization types**: Bubble charts, choropleth maps, pie charts, bar charts, dot maps
* **GeoJSON/TopoJSON support**: Full support for geographic features with proper binding
* **Interactive tooltips**: Automatic tooltip generation with customization options
* **Multiple base maps**: VT_TONER_LITE, OpenStreetMap, CartoDB Positron/Dark_Matter, Stamen Terrain
* **Flexible data input**: Inline JSON, CSV files, GeoJSON, TopoJSON, external URLs
* **Standalone output**: No server needed, works offline with CDN resources
* **Categorical coloring**: Dynamic color palettes for categorical data

## 💬 Using in Claude Chat (Not Claude Code)

This skill works in both Claude Code AND regular chat conversations!

### Quick Setup for Chat

**Option 1: Share the raw file URL (Recommended)**
1. Copy this URL: `https://raw.githubusercontent.com/gjrichter/ixmaps-claude-skill/main/SKILL.md`
2. Paste it in your Claude chat with a message like:
```
   Please read the ixmaps skill from this URL and use it to create maps:
   https://raw.githubusercontent.com/gjrichter/ixmaps-claude-skill/main/SKILL.md
```
3. Once Claude confirms, ask for your map in natural language:
```
   Create a map of Italian cities with pie charts showing gender distribution
```

**Option 2: Upload the file**
1. Download [SKILL.md](https://raw.githubusercontent.com/gjrichter/ixmaps-claude-skill/main/SKILL.md) (right-click → Save as)
2. Upload it to your Claude chat conversation
3. Ask Claude to follow those specifications

**Option 3: Copy-paste**
1. Open [SKILL.md](https://github.com/gjrichter/ixmaps-claude-skill/blob/main/SKILL.md)
2. Copy the entire content
3. Paste it in your chat with Claude
4. Ask for your map

### Chat Mode Examples
```
User: "Create a bubble map of Italian cities sized by population"
Claude: [generates complete HTML file with ixmaps]

User: "Now add a choropleth layer showing regions"
Claude: [adds layer to existing map]

User: "Change the base map to dark theme"
Claude: [updates mapType to CartoDB - Dark_Matter]
```

**See [CHAT_USAGE.md](CHAT_USAGE.md) for detailed chat mode guide with more examples.**

## 🚀 Quick Start for Claude Code

### Installation

1. Clone this repository:
```bash
git clone https://github.com/gjrichter/ixmaps-claude-skill.git
```

2. Copy the skill to your Claude Code skills directory:
```bash
mkdir -p ~/.claude/skills/create-ixmap
cp ixmaps-claude-skill/SKILL.md ~/.claude/skills/create-ixmap/
cp ixmaps-claude-skill/template.html ~/.claude/skills/create-ixmap/
```

Or use the install script:
```bash
cd ixmaps-claude-skill
./install.sh
```

3. Restart Claude Code or reload skills

### Usage in Claude Code

Simply invoke the skill:
```bash
/create-ixmap
```

Or with parameters:
```bash
/create-ixmap filename=my_map.html title="My Custom Map"
```

## 📖 Code Examples

### Example 1: Point Data with Bubbles
```javascript
ixmaps.layer("cities")
    .data({ obj: cityData, type: "json" })
    .binding({
        geo: "lat|lon",
        value: "population",
        title: "name"
    })
    .style({
        colorscheme: ["#0066cc"],
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .type("CHART|BUBBLE|SIZE|VALUES")
    .title("Italian Cities by Population")
    .define()
```

### Example 2: GeoJSON Choropleth Map
```javascript
ixmaps.layer("regions")
    .data({ url: "regions.geojson", type: "geojson" })
    .binding({
        geo: "geometry",
        value: "$item$",
        title: "region_name"
    })
    .style({
        colorscheme: ["#ffffcc","#ff0000"],
        opacity: 0.7,
        showdata: "true"
    })
    .meta({
        tooltip: "{{theme.item.chart}}{{theme.item.data}}"
    })
    .type("FEATURE|CHOROPLETH|EQUIDISTANT")
    .title("Regions")
    .define()
```

### Example 3: Categorical Coloring (TopoJSON)
```javascript
ixmaps.layer("european_countries")
    .data({
        url: "https://s3.eu-central-1.amazonaws.com/maps.ixmaps.com/topojson/CNTR_RG_10M_2020_4326.json",
        type: "topojson"
    })
    .binding({
        geo: "geometry",
        value: "NAME_ENGL",
        title: "NAME_ENGL"
    })
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
    .type("FEATURE|CHOROPLETH|CATEGORICAL")
    .title("European Countries by Name")
    .define()
```

See the [examples](examples/) directory for complete working examples.

## 💡 Chat Mode Natural Language Examples

When using in chat, you can request maps naturally:

**Simple requests:**
- "Create a map of European capitals"
- "Show Italian regions with population data"
- "Make a bubble map of cities sized by GDP"

**With data:**
- "Use this CSV: [URL] to create a choropleth map"
- "Map these coordinates: [{lat: 41.9, lon: 12.5, name: "Rome"}, ...]"

**With specific styling:**
- "Create a dark theme map with red bubbles"
- "Use the tableau color palette for categories"
- "Make pie charts showing male/female distribution"

**Iterative refinement:**
- First: "Create a basic map of Italy"
- Then: "Add city markers"
- Then: "Color them by region"
- Finally: "Switch to CartoDB Positron base map"

See [CHAT_USAGE.md](CHAT_USAGE.md) for detailed chat mode guide.

## 📋 Supported Visualization Types

### For Point Data (lat/lon)

* `CHART|DOT` - Simple dots at locations (uniform size and color)
* `CHART|DOT|CATEGORICAL` - Dots colored by categorical field values
* `CHART|BUBBLE|SIZE|VALUES` - Proportional circles sized by data values
* `CHART|PIE` - Pie charts at locations
* `CHART|BAR|VALUES` - Bar charts
* **Note**: All chart types MUST include the `CHART|` prefix

### For GeoJSON/TopoJSON Data

* `FEATURE` - Simple geographic features (polygons, lines) with uniform or single color
* `FEATURE|CHOROPLETH` - Color-coded regions with numeric data values
  * Add `|EQUIDISTANT` for equal intervals: `FEATURE|CHOROPLETH|EQUIDISTANT`
  * Add `|QUANTILE` for quantiles: `FEATURE|CHOROPLETH|QUANTILE`
* `FEATURE|CHOROPLETH|CATEGORICAL` - Color-coded regions by categorical/text field values
  * Use with dynamic colorscheme: `["100", "tableau"]`
  * ixMaps automatically calculates the exact number of colors needed

## 🗺️ Supported Map Types

* `VT_TONER_LITE` - Clean, minimal base map (default)
* `OpenStreetMap` - Standard OSM
* `CartoDB - Positron` - Light CartoDB style
* `CartoDB - Dark_Matter` - Dark CartoDB style
* `Stamen Terrain` - Terrain with hill shading

**Note**: CartoDB map types require spaces around the dash: `"CartoDB - Positron"` NOT `"CartoDB Positron"`

## ⚙️ Critical Rules

The skill follows ixMaps best practices:

### For All Layers (REQUIRED)

* ✅ `.binding()` with appropriate `geo` and `value` properties
* ✅ `showdata: "true"` in `.style()` object
* ✅ `.meta({ tooltip: "{{theme.item.chart}}{{theme.item.data}}" })` method

### For GeoJSON/TopoJSON Specifically

* ✅ Type MUST be `FEATURE` or `FEATURE|CHOROPLETH`
* ✅ For simple features: `{ geo: "geometry", value: "$item$", title: "fieldname" }`
* ✅ For categorical coloring: `{ geo: "geometry", value: "fieldname", title: "fieldname" }`
* ✅ Property fields referenced directly (e.g., `"NAME_ENGL"`), NOT `"properties.NAME_ENGL"`
* ❌ NEVER use regular chart types (BUBBLE, PIE, BAR) with GeoJSON
* ❌ NEVER use `.tooltip()` method (it doesn't exist in ixMaps)

### For Point Data

* ✅ Use chart types: `CHART|BUBBLE|SIZE|VALUES`, `CHART|PIE`, `CHART|DOT`, etc.
* ✅ For categorical coloring: `CHART|DOT|CATEGORICAL` with dynamic colorscheme
* ✅ Binding: `{ geo: "lat|lon", value: "fieldname", title: "titlefield" }` or `{ geo: "coordinate_field", title: "titlefield" }`

### Layer Method Chain Order

1. `.data()` - Define data source
2. `.binding()` - Map data fields to map properties (REQUIRED)
3. `.style()` - Visual styling (MUST include `showdata: "true"`)
4. `.meta()` - Metadata and tooltip configuration (REQUIRED)
5. `.type()` - Visualization type
6. `.title()` - Layer title
7. `.define()` - Finalize layer definition

### Style Rules

* **ALWAYS** include `showdata: "true"` in `.style()`
* Use `colorscheme` for colors (NOT `fillcolor`)
* For static colors: `["#0066cc"]` or `["#ffffcc", "#ff0000"]`
* For categorical: `["100", "tableau"]` - ixMaps calculates exact count needed
* Available palettes: `"tableau"`, `"paired"`, `"set1"`, `"set2"`, `"set3"`, `"pastel1"`, `"dark2"`
* For sizing: use `scale` (scaling factor) or `normalsizevalue` (value = 30px)

## 📚 Documentation

* [SKILL.md](SKILL.md) - Complete skill documentation for Claude
* [CHAT_USAGE.md](CHAT_USAGE.md) - Detailed guide for using in Claude Chat
* [QUICK_START.md](QUICK_START.md) - Quick reference guide
* [template.html](template.html) - HTML template with placeholders
* [examples/](examples/) - Working HTML examples

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

* [ixMaps](https://github.com/gjrichter/ixmaps_flat) - The interactive mapping framework
* [Claude Code](https://claude.ai) - AI-powered coding assistant
* All contributors and users of this skill

## 📧 Contact

For questions or feedback about this skill, please open an issue on GitHub.

## 🔗 Related Projects

* [ixMaps Framework](https://github.com/gjrichter/ixmaps_flat)
* [ixMaps Documentation](https://gjrichter.github.io/ixmaps_flat/)
* [Claude Code Skills](https://github.com/topics/claude-code-skill)

---

Made with ❤️ for the ixMaps and Claude Code communities