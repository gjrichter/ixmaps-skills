# 🚀 Quick Start Guide

Get your ixMaps Skill up and running in 5 minutes!

## 📦 What You Get

This skill lets a CLI tool generate interactive HTML maps with ixMaps using simple commands like:
```
/create-ixmap filename=my_map.html
```

## ⚡ Installation (2 methods)

### Method 1: Automatic Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/gjrichter/ixmaps-skill.git
cd ixmaps-skill

# Run the installer
./install.sh
```

### Method 2: Manual Installation

```bash
# Create the skill directory
mkdir -p <skills_dir>/create-ixmap

# Copy the files
cp SKILL.md <skills_dir>/create-ixmap/
cp template.html <skills_dir>/create-ixmap/
```

## ✅ Verify Installation

Restart your tool (or reload skills), then type:
```
/create-ixmap
```

If the assistant responds asking about what kind of map to create, it's working.

## 📖 First Map in 3 Steps

### Step 1: Invoke the Skill

In your CLI, type:
```
/create-ixmap
```

### Step 2: Describe Your Map

Tell the assistant what you want:
```
Create a map showing Italian regions with population data
```

### Step 3: Open the Result

The assistant will create an HTML file. Open it in your browser:
```bash
open ixmap.html
```

## 🎯 Common Use Cases

### Bubble Map (Point Data)
```
/create-ixmap
Create a bubble map showing European capitals with their populations
```

### Choropleth Map (Regions)
```
/create-ixmap
Create a choropleth map of US states colored by GDP
```

### Custom Data
```
/create-ixmap
Use this GeoJSON: https://example.com/data.geojson
Show it as a choropleth map with blue colors
```

## 🗺️ Examples

Check the `examples/` folder for working HTML files you can open immediately:

1. **lombardia_ambiti_esempio.html** - Simple features
2. **lombardia_ambiti_choropleth.html** - Choropleth coloring
3. **lombardia_ambiti_completo.html** - All best practices

Just double-click to open in your browser!

## 🎓 Learning Path

1. **Start here**: Open `examples/lombardia_ambiti_esempio.html` in browser
2. **Study the code**: Look at the JavaScript in the HTML
3. **Try modifying**: Change colors, zoom level, or data source
4. **Create your own**: Use `/create-ixmap` with your data

## 📚 Key Concepts (in 30 seconds)

**For GeoJSON data:**
- Type: `FEATURE` or `FEATURE|CHOROPLETH`
- Binding: `{ geo: "geometry", value: "$item$" }`

**For point data (lat/lon):**
- Type: `CHART|BUBBLE|SIZE|VALUES` (or PIE, BAR, DOT)
- Binding: `{ geo: "lat|lon", value: "fieldname" }`

**Always include:**
- `.binding()` - Map data to properties
- `showdata: "true"` - In style object
- `.meta({ tooltip: "..." })` - For hover info

## 🆘 Troubleshooting

### Skill not found
```bash
# Check if files are in the right place
ls <skills_dir>/create-ixmap/
# Should show: SKILL.md and template.html
```

### Map doesn't load
- Check browser console for errors (F12)
- Verify internet connection (needs CDN access)
- Try one of the working examples first

### Wrong visualization type
- Use `FEATURE` types only for GeoJSON
- Use `CHART` types only for point data (lat/lon)

## 🎉 You're Ready!

Now try creating your first map:
```
/create-ixmap filename=my_first_map.html title="My First ixMap"
```

For complete documentation, see [README.md](./README.md) and [SKILL.md](./SKILL.md).

## 🔗 Quick Links

- [Full Documentation](./README.md)
- [Examples](./examples/)
- [ixMaps Framework](https://github.com/gjrichter/ixmaps/flat)
- [Report Issues](https://github.com/gjrichter/ixmaps-skill/issues)

---

Happy mapping! 🗺️✨
