# Changelog

All notable changes to the ixMaps Claude Skill will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-04

### Added
- Initial release of ixMaps Claude Skill
- Support for multiple visualization types:
  - Bubble charts (`CHART|BUBBLE|SIZE|VALUES`)
  - Choropleth maps (`FEATURE|CHOROPLETH`)
  - Pie charts (`CHART|PIE`)
  - Bar charts (`CHART|BAR|VALUES`)
  - Simple dots (`DOT`)
- Full GeoJSON support with proper binding
- Automatic tooltip generation with `.meta()` method
- Multiple base map options (VT_TONER_LITE, OpenStreetMap, CartoDB, Stamen)
- Inline and external data source support
- Complete HTML template with responsive design
- Three working examples in `examples/` directory

### Features
- **Binding rules**: Automatic `.binding()` with correct `geo` and `value` properties
- **Style rules**: Always includes `showdata: "true"` for data display
- **Meta rules**: Default tooltip template with customization support
- **MapType validation**: Correct naming for CartoDB maps (e.g., `"CartoDB - Positron"`)
- **Method chain ordering**: Enforces correct order of layer methods

### Documentation
- Comprehensive README.md with quick start guide
- Complete SKILL.md with all API rules and examples
- HTML template with placeholders
- Three example HTML files demonstrating different use cases

### Examples
- `lombardia_ambiti_esempio.html` - Simple FEATURE type visualization
- `lombardia_ambiti_choropleth.html` - Choropleth map with quantile coloring
- `lombardia_ambiti_completo.html` - Complete example with all best practices

## [Unreleased]

### Planned
- Additional map type support
- CSV data handling examples
- Integration with common data sources
- Video tutorials and documentation
- Community contributions guidelines

---

[1.0.0]: https://github.com/YOUR_USERNAME/ixmaps-claude-skill/releases/tag/v1.0.0
