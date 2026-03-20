#!/usr/bin/env node

/**
 * Configuration Validator for ixMaps Skill
 *
 * Validates user parameters against skill-ui.yaml specification
 *
 * Usage:
 *   node validate-config.js myconfig.json
 *   node validate-config.js --interactive
 */

const fs = require('fs');
const yaml = require('js-yaml');

// Load skill configuration
function loadSkillConfig() {
  try {
    const yamlContent = fs.readFileSync('./skill-ui.yaml', 'utf8');
    return yaml.load(yamlContent);
  } catch (e) {
    console.error('Error loading skill-ui.yaml:', e.message);
    process.exit(1);
  }
}

// Validate parameter value against its definition
function validateParameter(param, value, allParams) {
  const errors = [];
  const warnings = [];

  // Check type
  switch (param.type) {
    case 'string':
      if (typeof value !== 'string') {
        errors.push(`${param.name}: Expected string, got ${typeof value}`);
      }
      if (param.pattern) {
        const regex = new RegExp(param.pattern);
        if (!regex.test(value)) {
          errors.push(`${param.name}: Value "${value}" doesn't match pattern ${param.pattern}`);
        }
      }
      break;

    case 'number':
      if (typeof value !== 'number') {
        errors.push(`${param.name}: Expected number, got ${typeof value}`);
      } else {
        if (param.min !== undefined && value < param.min) {
          errors.push(`${param.name}: Value ${value} is below minimum ${param.min}`);
        }
        if (param.max !== undefined && value > param.max) {
          errors.push(`${param.name}: Value ${value} is above maximum ${param.max}`);
        }
      }
      break;

    case 'boolean':
      if (typeof value !== 'boolean') {
        errors.push(`${param.name}: Expected boolean, got ${typeof value}`);
      }
      break;

    case 'select':
      const validOptions = [];
      if (param.options) {
        if (Array.isArray(param.options)) {
          validOptions.push(...param.options.map(opt => opt.value || opt));
        } else {
          // Options grouped by category
          Object.values(param.options).forEach(group => {
            validOptions.push(...group.map(opt => opt.value));
          });
        }
      }
      if (validOptions.length > 0 && !validOptions.includes(value)) {
        errors.push(`${param.name}: Invalid option "${value}". Valid options: ${validOptions.join(', ')}`);
      }
      break;

    case 'colors':
      if (!Array.isArray(value)) {
        errors.push(`${param.name}: Expected array of colors`);
      }
      break;

    case 'coordinates':
      if (typeof value !== 'object' || !value.lat || !value.lng) {
        errors.push(`${param.name}: Expected object with lat and lng properties`);
      } else {
        if (param.validation) {
          if (param.validation.lat) {
            if (value.lat < param.validation.lat.min || value.lat > param.validation.lat.max) {
              errors.push(`${param.name}: Latitude must be between ${param.validation.lat.min} and ${param.validation.lat.max}`);
            }
          }
          if (param.validation.lng) {
            if (value.lng < param.validation.lng.min || value.lng > param.validation.lng.max) {
              errors.push(`${param.name}: Longitude must be between ${param.validation.lng.min} and ${param.validation.lng.max}`);
            }
          }
        }
      }
      break;
  }

  // Check dependencies
  if (param.depends_on) {
    const satisfied = Object.entries(param.depends_on).every(([depParam, expectedValues]) => {
      const actualValue = allParams[depParam];
      if (Array.isArray(expectedValues)) {
        return expectedValues.includes(actualValue);
      }
      return actualValue === expectedValues;
    });

    if (!satisfied) {
      warnings.push(`${param.name}: Dependencies not satisfied. Check ${Object.keys(param.depends_on).join(', ')}`);
    }
  }

  return { errors, warnings };
}

// Validate complete configuration
function validateConfig(userParams, skillConfig) {
  const errors = [];
  const warnings = [];
  const suggestions = [];

  // Check required parameters
  skillConfig.parameters.forEach(param => {
    if (param.required && userParams[param.name] === undefined) {
      errors.push(`Missing required parameter: ${param.name}`);
    }
  });

  // Validate provided parameters
  Object.entries(userParams).forEach(([name, value]) => {
    const param = skillConfig.parameters.find(p => p.name === name);

    if (!param) {
      warnings.push(`Unknown parameter: ${name}`);
      return;
    }

    const result = validateParameter(param, value, userParams);
    errors.push(...result.errors);
    warnings.push(...result.warnings);
  });

  // Apply validation rules
  if (skillConfig.validation && skillConfig.validation.rules) {
    skillConfig.validation.rules.forEach(rule => {
      // Evaluate condition (simplified - real implementation would need proper expression parser)
      const conditionMet = evaluateCondition(rule.condition, userParams);

      if (conditionMet) {
        // Check requires
        if (rule.requires) {
          rule.requires.forEach(requiredParam => {
            if (userParams[requiredParam] === undefined) {
              errors.push(`${rule.message || `Parameter ${requiredParam} is required`}`);
            }
          });
        }

        // Add suggestions
        if (rule.suggests) {
          Object.entries(rule.suggests).forEach(([param, value]) => {
            if (userParams[param] === undefined) {
              suggestions.push(`Consider setting ${param} to ${JSON.stringify(value)}: ${rule.message}`);
            }
          });
        }
      }
    });
  }

  return { errors, warnings, suggestions };
}

// Simple condition evaluator
function evaluateCondition(condition, params) {
  // This is a simplified evaluator
  // Real implementation would need proper expression parsing

  if (condition.includes('starts with')) {
    const [param, prefix] = condition.match(/"([^"]+)"/g).map(s => s.replace(/"/g, ''));
    const key = condition.split(' ')[0];
    return params[key]?.startsWith(prefix);
  }

  if (condition.includes('contains')) {
    const [substring] = condition.match(/"([^"]+)"/g).map(s => s.replace(/"/g, ''));
    const key = condition.split(' ')[0];
    return params[key]?.includes(substring);
  }

  return false;
}

// Format and display results
function displayResults(results, userParams) {
  console.log('\n' + '='.repeat(60));
  console.log('VALIDATION RESULTS');
  console.log('='.repeat(60) + '\n');

  // Show provided parameters
  console.log('📋 Provided Parameters:');
  Object.entries(userParams).forEach(([key, value]) => {
    console.log(`   ${key}: ${JSON.stringify(value)}`);
  });
  console.log();

  // Show errors
  if (results.errors.length > 0) {
    console.log('❌ Errors:');
    results.errors.forEach(error => console.log(`   ${error}`));
    console.log();
  } else {
    console.log('✅ No errors found!\n');
  }

  // Show warnings
  if (results.warnings.length > 0) {
    console.log('⚠️  Warnings:');
    results.warnings.forEach(warning => console.log(`   ${warning}`));
    console.log();
  }

  // Show suggestions
  if (results.suggestions.length > 0) {
    console.log('💡 Suggestions:');
    results.suggestions.forEach(suggestion => console.log(`   ${suggestion}`));
    console.log();
  }

  // Summary
  console.log('='.repeat(60));
  if (results.errors.length === 0) {
    console.log('✅ Configuration is valid!');
  } else {
    console.log(`❌ Found ${results.errors.length} error(s). Please fix before proceeding.`);
  }
  console.log('='.repeat(60) + '\n');

  return results.errors.length === 0;
}

// Main
function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log('Usage: node validate-config.js <config.json>');
    console.log('       node validate-config.js --example');
    process.exit(1);
  }

  const skillConfig = loadSkillConfig();

  if (args[0] === '--example') {
    // Show example configuration
    console.log('Example configuration:\n');
    const example = {
      title: "My Interactive Map",
      viztype: "CHART|BUBBLE|SIZE|VALUES",
      maptype: "VT_TONER_LITE",
      center: { lat: 42.5, lng: 12.5 },
      zoom: 6,
      colorscheme: ["#0066cc"],
      data: [
        { name: "Rome", lat: 41.9, lon: 12.5, population: 2870500 },
        { name: "Milan", lat: 45.5, lon: 9.2, population: 1378000 }
      ]
    };
    console.log(JSON.stringify(example, null, 2));
    console.log('\nSave this to a file and validate with:');
    console.log('node validate-config.js config.json\n');
    return;
  }

  // Load user configuration
  let userParams;
  try {
    const configContent = fs.readFileSync(args[0], 'utf8');
    userParams = JSON.parse(configContent);
  } catch (e) {
    console.error('Error loading configuration file:', e.message);
    process.exit(1);
  }

  // Validate
  const results = validateConfig(userParams, skillConfig);

  // Display results
  const isValid = displayResults(results, userParams);

  process.exit(isValid ? 0 : 1);
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { validateConfig, loadSkillConfig };
