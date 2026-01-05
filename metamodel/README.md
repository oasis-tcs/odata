# OData EDM Model Structure Documentation

This folder contains the OData EDM (Entity Data Model) structure definition and tools to generate human-readable HTML documentation from it.

## Files

- `odata-edm-structure.json` - The complete structure definition of the OData EDM model
- `generateHtml.js` - Node.js script to generate HTML documentation
- `template.hbs` - Handlebars template for the HTML output
- `odata-edm-structure.html` - Generated HTML documentation (human-readable)

## Generating Documentation

First, install the dependencies (only needed once):

```bash
cd metamodel
npm install
```

Then, to regenerate the HTML documentation:

```bash
node generateHtml.js
# or
npm run generate
```

## Structure

The JSON file describes:

- All EDM model elements (Edmx, Schema, EntityType, ComplexType, etc.)
- Their attributes categorized as:
  - **Basic** - primitive values (strings, booleans, numbers)
  - **Reference** - symbolic references to other model elements
  - **Path** - path expressions through the model structure
- Parent-child relationships between elements
- Links to the official OASIS OData specification

## References

- [original Jira ISSUE](https://issues.oasis-open.org/browse/ODATA-1062)
- [GitHub Issue](https://github.com/oasis-tcs/odata-specs/issues/288)
