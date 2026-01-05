#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const Handlebars = require('handlebars');

/**
 * Generates an HTML documentation page from the OData EDM structure JSON
 */
class HtmlGenerator {
  constructor(jsonFilePath, templatePath) {
    this.jsonFilePath = jsonFilePath;
    this.templatePath = templatePath;
    this.data = null;
  }

  /**
   * Load the JSON data from file
   */
  loadData() {
    const content = fs.readFileSync(this.jsonFilePath, 'utf-8');
    this.data = JSON.parse(content);
  }

  /**
   * Calculate parent relationships by inverting the children relationships
   */
  calculateParents() {
    const parentMap = new Map();
    
    // Initialize all elements with empty parent arrays
    Object.keys(this.data.elements).forEach(elementName => {
      parentMap.set(elementName, []);
    });

    // For each element, add it as a parent to each of its children
    Object.entries(this.data.elements).forEach(([elementName, element]) => {
      if (element.children && element.children.length > 0) {
        element.children.forEach(childName => {
          const parents = parentMap.get(childName) || [];
          parents.push(elementName);
          parentMap.set(childName, parents);
        });
      }
    });

    return parentMap;
  }

  /**
   * Create a valid HTML ID from a name
   */
  makeId(name) {
    return name.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
  }

  /**
   * Format a kebab-case name into a proper display name
   */
  formatDisplayName(name) {
    return name
      .split('-')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }

  /**
   * Collect which attributes use each category for enhanced category tables
   * @returns {Object} Object structure {category: [attributeInfo]}
   * Each attributeInfo contains: {elementName, attrName, displayText, elementId}
   */
  collectCategoryUsage() {
    const usage = {};
    
    Object.entries(this.data.elements).forEach(([elementName, element]) => {
      const resolvedAttributes = this.resolveElementAttributes(element);
      
      if (resolvedAttributes && typeof resolvedAttributes === 'object') {
        Object.entries(resolvedAttributes).forEach(([attrName, attr]) => {
          if (attr.category) {
            if (!usage[attr.category]) {
              usage[attr.category] = [];
            }
            usage[attr.category].push({
              elementName,
              attrName,
              displayText: `${elementName}.${attrName}`,
              attributeId: `${this.makeId(elementName)}-${this.makeId(attrName)}` // Points to specific attribute
            });
          }
        });
      }
    });
    
    return usage;
  }

  /**
   * Resolve $ref references in element attributes
   * Merges referenced definition attributes with explicitly defined attributes
   */
  resolveElementAttributes(element) {
    let resolvedAttributes = element.attributes || {};
    
    // Check if element has $ref that points to a definitions section
    if (element.$ref) {
      const refPath = element.$ref;
      
      // Handle references like "#/definitions/type-facets"
      if (refPath.startsWith('#/definitions/')) {
        const definitionName = refPath.replace('#/definitions/', '');
        
        if (this.data.definitions && this.data.definitions[definitionName]) {
          const referencedDefinition = this.data.definitions[definitionName];
          
          // Merge referenced attributes with explicit attributes
          // Explicit attributes take precedence over referenced ones
          resolvedAttributes = {
            ...referencedDefinition.attributes,
            ...resolvedAttributes
          };
        }
      }
    }
    
    return resolvedAttributes;
  }

  /**
   * Prepare template data
   */
  prepareTemplateData() {
    const parentMap = this.calculateParents();
    
    // Prepare elements with enhanced data
    const elements = Object.entries(this.data.elements).map(([elementName, element]) => {
      const elementId = this.makeId(elementName);
      
      // Prepare children with IDs
      const children = (element.children || []).map(childName => ({
        name: childName,
        id: this.makeId(childName)
      }));
      
      // Prepare parents with IDs
      const parentNames = parentMap.get(elementName) || [];
      const parents = parentNames.map(parentName => ({
        name: parentName,
        id: this.makeId(parentName)
      }));
      
      // Resolve $ref and merge with explicit attributes
      const resolvedAttributes = this.resolveElementAttributes(element);
      
      // Prepare attributes with enhanced type information - handle both array and object formats
      let attributes = [];
      if (Array.isArray(resolvedAttributes)) {
        // Legacy array format
        attributes = resolvedAttributes.map(attr => {
          const attribute = {
            ...attr,
            specUrl: attr.ref ? this.data.metadata.baseUrl + attr.ref : null,
            symbols: attr.symbols || [],
            typeHtml: this.generateTypeHtml(attr)
          };
          return attribute;
        });
      } else if (resolvedAttributes && typeof resolvedAttributes === 'object') {
        // New object format
        attributes = Object.entries(resolvedAttributes).map(([attrName, attr]) => {
          const attribute = {
            ...attr,
            name: attrName, // Add the name back for template
            id: `${elementId}-${this.makeId(attrName)}`, // Unique attribute ID for linking
            specUrl: attr.ref ? this.data.metadata.baseUrl + attr.ref : null,
            symbols: attr.symbols || [],
            typeHtml: this.generateTypeHtml(attr)
          };
          return attribute;
        });
      }
      
      // Sort attributes alphabetically by name
      attributes.sort((a, b) => {
        const nameA = a.name || '';
        const nameB = b.name || '';
        return nameA.localeCompare(nameB);
      });
      
      return {
        ...element,
        name: elementName, // Add the name back for template
        id: elementId,
        children,
        parents,
        attributes
      };
    });
    
    // Collect category usage for enhanced category tables
    const categoryUsage = this.collectCategoryUsage();
    
    // Create attribute categories split by kind (basic/model) and sorted alphabetically
    const basicCategories = [];
    const modelCategories = [];
    
    if (this.data['attribute-categories']) {
      Object.entries(this.data['attribute-categories']).forEach(([categoryName, categoryData]) => {
        const categoryInfo = {
          key: categoryName,
          name: categoryName,
          displayName: this.formatDisplayName(categoryName),
          id: this.makeId(categoryName),
          description: categoryData.description || this.getCategoryDescription(categoryName),
          ref: categoryData.ref, // Include the spec reference if it exists
          usedBy: categoryUsage[categoryName] || []
        };
        
        if (categoryData.kind === 'model') {
          modelCategories.push(categoryInfo);
        } else {
          // Default to basic for any unspecified kind
          basicCategories.push(categoryInfo);
        }
      });
    }
    
    // Sort both sections alphabetically by name
    basicCategories.sort((a, b) => a.name.localeCompare(b.name));
    modelCategories.sort((a, b) => a.name.localeCompare(b.name));
    
    const attributeCategories = {
      basic: {
        categories: basicCategories,
        description: this.data['attribute-category-kinds']?.basic?.description || 'Basic attributes represent values that get associated with the property of model elements.'
      },
      model: {
        categories: modelCategories,
        description: this.data['attribute-category-kinds']?.model?.description || 'Model attributes can be resolved to references to or paths of other model elements.'
      }
    };
    
    return {
      metadata: this.data.metadata,
      elements,
      attributeCategories
    };
  }

  /**
   * Generate the type HTML based on attribute category
   * 
   * DESIGN DECISION: Complex formatting logic is handled in JavaScript rather than Handlebars template
   * 
   * This approach keeps the template clean and readable while centralizing complex presentation logic
   * in testable JavaScript code. The alternative would be nested Handlebars conditionals and helpers
   * that would make the template much harder to read and maintain.
   * 
   * Complex logic handled here includes:
   * - Oxford comma formatting for multiple reference targets ("A, B, or C")
   * - HTML link generation with proper anchor IDs and escaping
   * - Category-based type display with proper capitalization
   * - Fallback handling for edge cases
   * 
   * @param {Object} attr - The attribute object from JSON with category, targets, etc.
   * @returns {string} HTML string for the Type column in attribute tables
   * 
   * Output patterns:
   * - Reference attributes → "Reference to <link>Target1</link>, <link>Target2</link>, or <link>Target3</link>"
   * - Symbol-based attributes → "One of: <code>val1</code>, <code>val2</code>"
   * - Other attributes → "<a href="#category-xxx">Category Name</a>"
   */
  generateTypeHtml(attr) {
    const category = attr.category || 'unknown';
    
    // Handle reference attributes specially - they have targets to link to
    if (attr.targets && attr.targets.length > 0) {
      const links = attr.targets.map(target => {
        const targetId = this.makeId(target);
        return `<a href="#${targetId}">${target}</a>`;
      });
      
      // Format target links with Oxford comma and "or" for readability
      let linksText;
      if (links.length === 1) {
        linksText = links[0];
      } else if (links.length === 2) {
        linksText = `${links[0]} or ${links[1]}`;
      } else {
        linksText = links.slice(0, -1).join(', ') + ', or ' + links[links.length - 1];
      }
      
      return `Reference to ${linksText}`;
    }
    
    // Handle symbols-based attributes (like enums)
    if (attr.symbols && attr.symbols.length > 0) {
      const symbolsList = attr.symbols.map(symbol => `<code>${symbol}</code>`).join(', ');
      
      // If there's also a category, show both the category type and the symbols
      if (category) {
        const categoryId = this.makeId(category);
        const displayCategory = category.replace(/-/g, ' ')
          .replace(/\b\w/g, l => l.toUpperCase());
        return `<a href="#category-${categoryId}">${displayCategory}</a> or one of ${symbolsList}`;
      }
      
      return `One of: ${symbolsList}`;
    }
    
    // For all other categories, show as a link to the category section
    const categoryId = this.makeId(category);
    // Capitalize and format category name for display
    const displayCategory = category.replace(/-/g, ' ')
      .replace(/\b\w/g, l => l.toUpperCase());
    
    return `<a href="#category-${categoryId}">${displayCategory}</a>`;
  }

  /**
   * Get a description for a category
   */
  getCategoryDescription(category) {
    const descriptions = {
      'basic': 'Basic attribute values like strings, identifiers, and literals',
      'path': 'Path-based attributes that reference model elements or properties',
      'string': 'String values',
      'uri': 'URI values',
      'simple-identifier': 'Simple identifier names',
      'qualified-name': 'Qualified names with namespace',
      'qualified-type-name': 'Qualified type names',
      'annotation-target': 'Annotation target paths',
      'propertypath': 'Paths to properties',
      'containerpath': 'Paths within entity containers'
    };
    return descriptions[category] || `${category} attribute values`;
  }

  /**
   * Register Handlebars helpers
   */
  registerHelpers() {
    // Helper to compare values
    Handlebars.registerHelper('eq', function(a, b) {
      return a === b;
    });
  }

  /**
   * Generate the complete HTML document
   */
  generate() {
    this.loadData();
    this.registerHelpers();
    
    // Load and compile template
    const templateContent = fs.readFileSync(this.templatePath, 'utf-8');
    const template = Handlebars.compile(templateContent);
    
    // Prepare data
    const templateData = this.prepareTemplateData();
    
    // Generate HTML
    const html = template(templateData);
    
    return html;
  }
}

/**
 * Main execution
 */
function main() {
  const args = process.argv.slice(2);
  const inputFile = args[0] || path.join(__dirname, 'odata-edm-structure.json');
  const templateFile = path.join(__dirname, 'template.hbs');
  const outputFile = args[1] || path.join(__dirname, 'odata-edm-structure.html');

  console.log('Generating HTML documentation...');
  console.log(`Input: ${inputFile}`);
  console.log(`Template: ${templateFile}`);
  console.log(`Output: ${outputFile}`);

  const generator = new HtmlGenerator(inputFile, templateFile);
  const html = generator.generate();

  fs.writeFileSync(outputFile, html, 'utf-8');
  console.log('Done! HTML documentation generated successfully.');
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { HtmlGenerator };
