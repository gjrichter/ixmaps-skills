# Using ixMaps Skill in Claude Chat

This guide explains how to use the ixMaps skill in regular Claude chat conversations (not Claude Code).

## Setup (One-Time)

Choose one method to load the skill into your conversation:

### Method A: Share the GitHub URL (Recommended)
In your chat with Claude, paste:
```
Please read and follow the ixmaps skill specifications from:
https://raw.githubusercontent.com/gjrichter/ixmaps-claude-skill/main/SKILL.md
```

### Method B: Upload the File
1. Download [SKILL.md](https://raw.githubusercontent.com/gjrichter/ixmaps-claude-skill/main/SKILL.md) (right-click → Save as)
2. Upload it to your chat conversation
3. Say: "Please follow these specifications to create ixmaps"

### Method C: Direct Paste
1. Copy the content of [SKILL.md](https://github.com/gjrichter/ixmaps-claude-skill/blob/main/SKILL.md)
2. Paste it in your chat
3. Ask Claude to use those specifications

## Usage Examples

### Example 1: Simple Point Map
```
You: Create an ixmap showing these cities with bubble charts sized by population:
- Rome: 2,873,000
- Milan: 1,372,000  
- Naples: 967,000

Claude: [creates complete HTML file with ixmaps]
```

**Result**: Standalone HTML file with interactive map, bubbles sized proportionally to population values.

### Example 2: Using External Data
```
You: Create an ixmap using this CSV data:
https://example.com/cities.csv

Show it as a choropleth map with CartoDB Positron base map

Claude: [creates map with data from URL]
```

**Result**: Map loads data from URL and displays as choropleth with specified base map.

### Example 3: GeoJSON Map
```
You: Create an ixmap showing European countries from this GeoJSON:
https://s3.eu-central-1.amazonaws.com/maps.ixmaps.com/topojson/CNTR_RG_10M_2020_4326.json

Color them categorically by country name using the tableau palette

Claude: [creates FEATURE|CHOROPLETH|CATEGORICAL map]
```

**Result**: Each country gets a unique color from the tableau palette, automatically calculated.

### Example 4: Multiple Layers
```
You: Create a map with two layers:
1. Italian regions as choropleth (population density)
2. Major cities as pie charts (age distribution)

Claude: [creates map with both layers]
```

**Result**: Layered visualization with regions and cities, each with appropriate styling.

### Example 5: Pie Charts with Multiple Values
```
You: Create an ixmap of Italian cities with pie charts showing gender distribution.
Use these cities:
- Roma: 1,393,405 male, 1,479,595 female
- Milano: 665,420 male, 706,580 female
- Napoli: 469,000 male, 498,000 female

Claude: [creates CHART|PIE|SIZE|VALUES map]
```

**Result**: Pie charts sized by total population, with two segments (male/female) in different colors.

### Example 6: Categorical Dot Map
```
You: Create an ixmap using this CSV:
https://data.example.com/infrastructure.csv

Show dots colored by the "type" field using the tableau palette

Claude: [creates CHART|DOT|CATEGORICAL map]
```

**Result**: Each infrastructure type gets a unique color, legend automatically generated.

## Tips for Chat Mode

### Be Specific About Data
- Provide inline data, CSV URLs, or GeoJSON URLs
- Specify field names clearly
- Indicate which field to visualize

**Good:**
```
Create a map with this data: [{name: "Rome", lat: 41.9, lon: 12.5, pop: 2873000}]
Show bubbles sized by the "pop" field
```

**Less clear:**
```
Make a map of cities
```

### Request Modifications Naturally
```
"Change the colors to blue and red"
"Make the bubbles bigger" 
"Add a legend"
"Switch to dark mode base map"
"Use the tableau color palette"
"Increase the opacity to 0.8"
```

### Ask for Explanations
```
"Explain what colorscheme options are available"
"What visualization types work with GeoJSON?"
"How do I adjust bubble sizes?"
"What does normalsizevalue do?"
"Show me examples of categorical coloring"
```

### Specify Visualization Type When Known
```
"Create a CHART|BUBBLE|SIZE|VALUES map"
"Use FEATURE|CHOROPLETH|CATEGORICAL"
"Make it a CHART|PIE visualization"
```

## Common Patterns

### Pattern 1: Quick Data Visualization
```
You: I have this data: [paste JSON array]
     Create an ixmap with bubbles sized by "value" field

Claude: [immediate map generation]
```

**Use when**: You have data ready and know what visualization you want.

### Pattern 2: Iterative Refinement
```
You: Create a basic map of Italy
Claude: [creates map]

You: Add major cities as dots
Claude: [adds layer]

You: Color the cities by region
Claude: [modifies layer styling]

You: Make the dots bigger and use the tableau palette
Claude: [updates scale and colorscheme]
```

**Use when**: You want to build the map step by step.

### Pattern 3: Template Reuse
```
You: Create an ixmap template I can reuse for different datasets.
     It should have placeholders for:
     - Data URL
     - Value field name
     - Title field name

Claude: [creates parameterized template with clear data section]
```

**Use when**: You need to create multiple similar maps with different data.

### Pattern 4: Data + Search
```
You: Search for population data for the top 10 Italian cities,
     then create an ixmap with pie charts showing age distribution

Claude: [searches web, structures data, creates map]
```

**Use when**: You need Claude to find and structure the data first.

### Pattern 5: Complex Multi-Layer
```
You: Create a map showing:
     1. Base layer: Italian regions (GeoJSON) colored by GDP
     2. Overlay: Major airports as red dots
     3. Overlay: Tourist attractions as blue stars
     Use CartoDB Dark_Matter base map

Claude: [creates multi-layer map with proper styling]
```

**Use when**: You need multiple data sources on one map.

## Troubleshooting

### "I don't have the skill loaded"
**Problem**: Claude doesn't follow ixmaps specifications.

**Solution**: 
- Make sure you've shared the SKILL.md URL or content in the current conversation
- Claude needs it loaded to know the correct API syntax
- Try Method A from the Setup section

### "The map doesn't work"
**Problem**: HTML file doesn't display correctly or has errors.

**Solutions**:
- Ask Claude: "Please validate this code against the ixmaps skill specifications"
- Check browser console (F12) for JavaScript errors
- Verify data format matches expectations (check field names, coordinate format)
- Ensure URLs are accessible (try opening data URLs in browser)

### "Colors/sizing looks wrong"
**Problem**: Bubbles too small/large, colors don't match expectations.

**Solutions**:
- For bubble sizing: Adjust `normalsizevalue` in style
  - Lower value = bigger charts (e.g., `normalsizevalue: 300000`)
  - Higher value = smaller charts (e.g., `normalsizevalue: 800000`)
- For colors: 
  - Static: Use hex color arrays `["#ff0000", "#0000ff"]`
  - Categorical: Use dynamic scheme `["100", "tableau"]`
- Ask Claude: "Make the bubbles twice as large" or "Use brighter colors"

### "GeoJSON doesn't display"
**Problem**: GeoJSON features not showing on map.

**Solutions**:
- Verify binding includes: `geo: "geometry"` and `value: "$item$"`
- Check type is `FEATURE` or `FEATURE|CHOROPLETH`, NOT a chart type
- Ensure `showdata: "true"` is in style
- Ask Claude: "Debug why the GeoJSON isn't displaying"

### "Categorical colors not working"
**Problem**: All items same color instead of different colors per category.

**Solutions**:
- Verify colorscheme is dynamic: `["100", "tableau"]` not static colors
- Check type includes `|CATEGORICAL`: e.g., `FEATURE|CHOROPLETH|CATEGORICAL`
- Ensure binding's value field points to the categorical field
- Ask Claude: "Use categorical coloring for the 'type' field with tableau palette"

### "Tooltips not showing"
**Problem**: Hovering over map elements shows no information.

**Solutions**:
- Verify `.meta()` method is present with tooltip template
- Check that `showdata: "true"` is in style
- Ensure data binding includes a `title` field
- Ask Claude: "Add tooltips showing the name and value"

## Differences from Claude Code Mode

| Feature       | Claude Code                 | Claude Chat               |
| ------------- | --------------------------- | ------------------------- |
| Invocation    | `/create-ixmap` command     | Natural language request  |
| File creation | Automatic to disk           | Returns HTML code block   |
| Skill loading | Auto-detected in skills dir | Manual (share URL/file)   |
| Iterations    | Updates existing file       | Provides new code version |
| Context       | Project directory aware     | Conversation-based        |
| Workflow      | Command-driven              | Conversational            |

## Advanced Usage

### Combining with Web Search
```
You: Search for the latest population data for European capitals,
     then create an ixmap with bubbles sized by population

Claude: [searches web, finds data, structures it, creates map]
```

**Result**: Claude finds current data and creates map in one flow.

### Using with CKAN Data
```
You: Query the dati.gov.it CKAN portal for infrastructure data in Lombardy,
     then create a categorized dot map colored by infrastructure type

Claude: [queries CKAN API, processes results, creates map]
```

**Result**: Live data from open data portals visualized immediately.

### Dynamic Updates
```
You: Create a map with the data variable at the top so I can easily 
     change the data later without touching the rest of the code

Claude: [creates map with clearly separated data section]
```

**Result**: Template where you can just paste new data and reload.

### Comparing Multiple Datasets
```
You: Create two maps side by side:
     1. Population in 2020
     2. Population in 2024
     Use the same scale for both

Claude: [creates HTML with two map divs, synchronized styling]
```

**Result**: Visual comparison made easy with consistent styling.

### Animation Preparation
```
You: Create an ixmap where I can easily add time-series data
     to animate changes over time

Claude: [creates structure ready for animation implementation]
```

**Result**: Foundation for animated visualizations.

## Best Practices

1. **Always specify data source clearly**
   - Inline: Paste JSON array directly
   - URL: Provide full URL to CSV/JSON/GeoJSON
   - Search: Ask Claude to find and structure data

2. **Name your fields explicitly for binding**
```
   "Use 'latitude' and 'longitude' for coordinates"
   "The population is in the 'pop' field"
   "Color by the 'region' field"
```

3. **Request specific visualization types when you know what you want**
```
   "Create a CHART|BUBBLE|SIZE|VALUES map"
   "Use FEATURE|CHOROPLETH|CATEGORICAL for regions"
```

4. **Iterate gradually** - start simple, then refine
```
   First: Basic map with data
   Then: Add styling
   Then: Adjust colors/sizes
   Finally: Add additional layers
```

5. **Save the HTML files** Claude creates for reuse
   - Copy code to .html file
   - Open in browser
   - Modify data section for new datasets

6. **Ask for explanations** when you need to understand options
```
   "What colorscheme options work with categorical data?"
   "Explain the difference between BUBBLE and PIE charts"
```

7. **Provide context for better results**
```
   "I'm creating a map for a presentation about climate change"
   "This is for analyzing traffic patterns"
   "I need to compare regional economic data"
```

## Real-World Use Cases

### Use Case 1: Business Analytics
```
You: I have sales data by region. Create a choropleth map of Italy
     showing sales volume by region, using green (low) to red (high) colors

Claude: [creates FEATURE|CHOROPLETH|EQUIDISTANT map]
```

### Use Case 2: Academic Research
```
You: Create a map showing survey response locations with pie charts
     displaying yes/no/undecided responses. Data: [paste survey data]

Claude: [creates CHART|PIE map with three-segment pies]
```

### Use Case 3: Public Data Visualization
```
You: Query CKAN for hospital locations in Tuscany,
     create a map with dots colored by hospital type

Claude: [queries CKAN, creates CHART|DOT|CATEGORICAL map]
```

### Use Case 4: Travel Planning
```
You: Create a map of hotels in Rome with bubbles sized by price
     and colored by rating (red=low, green=high)

Claude: [creates CHART|BUBBLE with gradient colorscheme]
```

### Use Case 5: Environmental Monitoring
```
You: Map air quality monitoring stations with current AQI values.
     Use this CSV: [URL]. Color by AQI category (good/moderate/unhealthy)

Claude: [creates CHART|DOT|CATEGORICAL with appropriate colors]
```

## Getting Help

### Ask Claude Directly
Claude can explain any aspect of the skill:
```
"What's the difference between FEATURE and CHART types?"
"Show me all available color palettes"
"How do I make tooltips show custom information?"
"What does the normalsizevalue parameter do?"
```

### Check Examples
- Look at [examples/](../examples/) directory for working code
- Examine the HTML source to see how layers are structured
- Modify example code with your own data

### GitHub Issues
- Open an issue for bugs or feature requests
- Share your use case for community help
- Contribute examples back to the repository

## Resources

- [Main README](README.md) - Full documentation
- [SKILL.md](SKILL.md) - Complete skill specifications
- [QUICK_START.md](QUICK_START.md) - Quick reference
- [Examples](examples/) - Working HTML examples
- [ixMaps Documentation](https://gjrichter.github.io/ixmaps_flat/) - Official ixMaps docs
- [ixMaps GitHub](https://github.com/gjrichter/ixmaps_flat) - Source code

## Contributing

Found a better way to use the skill in chat? 
- Open an issue to share your technique
- Submit a PR with additional examples
- Help improve this documentation

---

**Happy Mapping! 🗺️**

Questions? Just ask Claude - it's an expert on this skill!