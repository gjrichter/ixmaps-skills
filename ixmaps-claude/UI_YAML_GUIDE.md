# UI YAML Configuration Guide

The `skill-ui.yaml` file provides a structured definition of the ixMaps skill's user interface, parameters, and validation rules.

## Purpose

This YAML file enables:

1. **Auto-generation of UI forms** - Build web/desktop interfaces
2. **Parameter validation** - Ensure correct values
3. **IDE integration** - Autocomplete and hints
4. **Command-line parsing** - Structured argument handling
5. **Documentation** - Single source of truth for parameters
6. **Presets** - Common configurations ready to use
7. **Wizards** - Step-by-step guided setup

## File Structure

### 1. Skill Metadata

```yaml
skill:
  name: create-ixmap
  version: 2.0
  description: Create interactive maps using the ixMaps framework
  icon: 🗺️
  category: visualization
```

### 2. Parameters

Each parameter is fully defined:

```yaml
parameters:
  - name: filename
    type: string
    default: "ixmap.html"
    description: "Output HTML filename"
    required: false
    pattern: "^[a-zA-Z0-9_-]+\\.html$"
    example: "mymap.html"
```

**Parameter types:**
- `string` - Text value
- `number` - Numeric value
- `boolean` - True/false
- `select` - Dropdown with options
- `colors` - Color scheme
- `coordinates` - Lat/lng pair
- `data` - Data source

**Parameter properties:**
- `name` - Parameter identifier
- `type` - Data type
- `default` - Default value
- `description` - Help text
- `required` - Whether mandatory
- `group` - Organizational group
- `depends_on` - Conditional dependencies
- `validation` - Validation rules
- `examples` - Example values
- `options` - Available choices (for select type)

### 3. Groups

Parameters organized into logical groups:

```yaml
groups:
  - name: basic
    label: "Basic Settings"
    icon: "📝"
    parameters: [filename, title, data]

  - name: advanced
    label: "Advanced Options"
    icon: "⚙️"
    parameters: [legend_title, tooltip_template]
    collapsible: true
    collapsed: true
```

**UI Rendering:**
- Groups become accordion sections or tabs
- Icons provide visual cues
- Collapsible groups can be hidden by default
- Parameters within groups are rendered together

### 4. Presets

Pre-configured parameter sets for common use cases:

```yaml
presets:
  - name: simple_points
    label: "Simple Point Map"
    description: "Display locations with uniform markers"
    icon: "📍"
    parameters:
      viztype: "CHART|DOT"
      maptype: "VT_TONER_LITE"
      colorscheme: ["#0066cc"]
```

**Usage:**
```bash
/create-ixmap --preset simple_points
/create-ixmap --preset density_heatmap
```

### 5. Validation Rules

Conditional validation and suggestions:

```yaml
validation:
  rules:
    - name: value_for_sizing
      condition: "viztype contains 'SIZE'"
      requires: [value_field]
      message: "Sized visualizations require a value field"
```

**Rule types:**
- `requires` - Parameters that must be set
- `suggests` - Recommended parameter values
- `condition` - When rule applies

### 6. Wizard

Step-by-step guided setup:

```yaml
wizard:
  steps:
    - name: data_type
      title: "What type of data do you have?"
      type: choice
      options:
        - value: "points"
          label: "Point Data (CSV/JSON)"
          next: point_visualization
```

**Wizard flow:**
1. User selects data type
2. Wizard guides to appropriate visualization
3. Preset automatically applied
4. User can customize further

### 7. CLI Aliases

Short forms for command-line usage:

```yaml
cli:
  aliases:
    -f: filename
    -t: title
    -v: viztype
```

**Usage:**
```bash
/create-ixmap -t "My Map" -v BUBBLE
```

## Use Cases

### 1. Building a Web UI

```javascript
// Load YAML
const config = yaml.load('skill-ui.yaml');

// Generate form
config.parameters.forEach(param => {
  if (param.type === 'select') {
    createDropdown(param);
  } else if (param.type === 'number') {
    createSlider(param);
  }
  // ... etc
});

// Apply presets
function applyPreset(presetName) {
  const preset = config.presets.find(p => p.name === presetName);
  preset.parameters.forEach((value, key) => {
    setFormValue(key, value);
  });
}
```

### 2. Parameter Validation

```javascript
function validate(userParams) {
  const errors = [];

  config.validation.rules.forEach(rule => {
    if (evaluateCondition(rule.condition, userParams)) {
      rule.requires.forEach(param => {
        if (!userParams[param]) {
          errors.push(rule.message);
        }
      });
    }
  });

  return errors;
}
```

### 3. IDE Autocomplete

The YAML can generate:
- Parameter hints
- Type checking
- Default value suggestions
- Example snippets

### 4. Command-line Parser

```javascript
function parseArgs(args) {
  const params = {};

  args.forEach(arg => {
    if (arg.startsWith('--preset=')) {
      const presetName = arg.split('=')[1];
      Object.assign(params, getPreset(presetName));
    } else if (arg.startsWith('-')) {
      // Resolve alias
      const alias = config.cli.aliases[arg.split('=')[0]];
      params[alias] = arg.split('=')[1];
    }
  });

  return params;
}
```

### 5. Documentation Generation

```javascript
function generateDocs() {
  let docs = "# Parameters\n\n";

  config.groups.forEach(group => {
    docs += `## ${group.label}\n\n`;

    group.parameters.forEach(paramName => {
      const param = config.parameters.find(p => p.name === paramName);
      docs += `### ${param.name}\n`;
      docs += `- **Type:** ${param.type}\n`;
      docs += `- **Default:** ${param.default}\n`;
      docs += `- **Description:** ${param.description}\n\n`;
    });
  });

  return docs;
}
```

## Integration Examples

### React Component

```jsx
import React from 'react';
import skillConfig from './skill-ui.yaml';

function SkillForm() {
  const [params, setParams] = useState({});

  return (
    <form>
      {skillConfig.groups.map(group => (
        <Accordion key={group.name} title={group.label} icon={group.icon}>
          {group.parameters.map(paramName => {
            const param = skillConfig.parameters.find(p => p.name === paramName);
            return <FormField key={param.name} config={param} />;
          })}
        </Accordion>
      ))}

      <PresetSelector presets={skillConfig.presets} onSelect={applyPreset} />
    </form>
  );
}
```

### Vue Component

```vue
<template>
  <div class="skill-form">
    <v-tabs>
      <v-tab v-for="group in config.groups" :key="group.name">
        {{ group.icon }} {{ group.label }}
      </v-tab>

      <v-tab-item v-for="group in config.groups" :key="group.name">
        <v-form>
          <component
            v-for="param in getGroupParams(group)"
            :is="getFieldComponent(param.type)"
            :key="param.name"
            :config="param"
            v-model="params[param.name]"
          />
        </v-form>
      </v-tab-item>
    </v-tabs>
  </div>
</template>
```

### Command-line Tool

```python
import yaml
import argparse

# Load config
with open('skill-ui.yaml') as f:
    config = yaml.safe_load(f)

# Build argument parser
parser = argparse.ArgumentParser()

for param in config['parameters']:
    if param['type'] == 'boolean':
        parser.add_argument(f"--{param['name']}", action='store_true')
    else:
        parser.add_argument(f"--{param['name']}",
                          default=param.get('default'),
                          help=param['description'])

# Add aliases
for alias, full_name in config['cli']['aliases'].items():
    parser.add_argument(alias, dest=full_name)

# Parse
args = parser.parse_args()
```

## Validation Schema

The UI YAML itself can be validated against a JSON Schema:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["skill", "parameters"],
  "properties": {
    "skill": {
      "type": "object",
      "required": ["name", "version"],
      "properties": {
        "name": {"type": "string"},
        "version": {"type": "string"},
        "description": {"type": "string"}
      }
    },
    "parameters": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["name", "type"],
        "properties": {
          "name": {"type": "string"},
          "type": {"enum": ["string", "number", "boolean", "select", "colors", "coordinates", "data"]},
          "default": {},
          "description": {"type": "string"}
        }
      }
    }
  }
}
```

## Benefits

### For Users

1. **Discoverability** - See all available options
2. **Validation** - Catch errors before generation
3. **Presets** - Quick start with common configurations
4. **Guided setup** - Wizard mode for beginners
5. **Help text** - Inline descriptions and examples

### For Developers

1. **Single source of truth** - One file defines everything
2. **Auto-generated UIs** - Build forms automatically
3. **Consistent validation** - Same rules everywhere
4. **Easy to extend** - Add parameters without code changes
5. **Documentation** - Self-documenting configuration

### For Tools

1. **IDE integration** - Autocomplete and hints
2. **CLI generation** - Automatic argument parsing
3. **UI generation** - Web/desktop interfaces
4. **Testing** - Validate configurations
5. **Versioning** - Track changes to parameters

## Example Tools Using UI YAML

### 1. Web Form Generator

```bash
npm install yaml
node generate-ui.js skill-ui.yaml > form.html
```

### 2. CLI Helper

```bash
create-ixmap --help  # Generated from YAML
create-ixmap --wizard  # Interactive wizard mode
create-ixmap --preset simple_points  # Apply preset
```

### 3. VS Code Extension

- Autocomplete for parameters
- Hover hints from descriptions
- Preset snippets
- Validation on save

### 4. Validation Tool

```bash
validate-config myconfig.json skill-ui.yaml
# Checks: required fields, types, valid values
```

## Future Enhancements

Potential additions to the UI YAML:

1. **Conditional fields** - Show/hide based on other values
2. **Field dependencies** - Auto-update related fields
3. **Custom validators** - JavaScript functions for complex rules
4. **Themes** - UI styling definitions
5. **Localization** - Multi-language support
6. **API integration** - Fetch data for dropdowns
7. **Preview** - Live map preview as you configure
8. **Templates** - Save user configurations

## Related Files

- **skill-ui.yaml** - The UI configuration (this file defines)
- **SKILL.md** - Main skill documentation (consumed by Claude)
- **API_REFERENCE.md** - Complete API documentation
- **EXAMPLES.md** - Code examples

## Contributing

When adding new parameters:

1. Add to `parameters` section with full definition
2. Add to appropriate `group`
3. Add validation rules if needed
4. Add to relevant presets
5. Update wizard if applicable
6. Add examples
7. Test with validation tool

## License

MIT License - Same as parent project

---

**The UI YAML makes the ixMaps skill more accessible, easier to use, and ready for integration with various tools and interfaces! 🎉**
