# Active Record ABL (ARA) - Implementation Plan

## Overview

This document outlines the complete implementation plan for a Rust CLI tool that serves as the spiritual successor to the original Progress ABL ORM generator. The tool will generate type-safe Active Record classes for Progress OpenEdge ABL applications.

## Architecture

### Two-Phase Approach

1. **Schema Extraction (Progress)**
   - Progress script (`extract-schema.p`) + `.pf` connection file
   - Exports complete database schema to JSON format
   - Includes tables, fields, indexes, data types, and relationships

2. **Code Generation (Rust CLI)**
   - Reads JSON schema file
   - Generates ABL classes based on CLI arguments
   - Uses TOML configuration for customization

### Project Structure

```
active-record-abl/
├── README.md
├── IMPLEMENTATION_PLAN.md
├── Cargo.toml
├── ara-cli.toml              # Default configuration
├── extract-schema.p          # Progress schema extraction script
├── connect.pf                # Sample Progress connection file
├── schema.json               # Generated schema (gitignored)
├── ara/                      # Generated ABL output (gitignored)
└── src/
    ├── main.rs               # CLI entry point
    ├── cli/
    │   ├── mod.rs
    │   ├── commands.rs       # CLI command definitions
    │   └── args.rs          # Argument parsing
    ├── config/
    │   ├── mod.rs
    │   └── settings.rs       # TOML configuration handling
    ├── schema/
    │   ├── mod.rs
    │   ├── parser.rs         # JSON schema parsing
    │   └── models.rs         # Schema data models
    ├── generator/
    │   ├── mod.rs
    │   ├── class_generator.rs # Main ABL class generation
    │   ├── method_generator.rs # CRUD/utility methods
    │   └── templates/        # Handlebars templates
    │       ├── class.cls.hbs
    │       ├── methods.hbs
    │       ├── properties.hbs
    │       └── load_methods.hbs
    └── utils/
        ├── mod.rs
        └── type_mapping.rs   # Progress to ABL type mapping
```

## CLI Interface Design

### Commands

```bash
# Generate for specific table
ara-cli generate --table Customer

# Generate for multiple tables
ara-cli generate --tables Customer,Order,OrderLine

# Generate for all tables
ara-cli generate --all

# Custom schema file
ara-cli generate --table Customer --schema ./custom-schema.json

# Custom config file
ara-cli generate --all --config ./custom-config.toml

# Extract schema (optional separate step)
ara-cli extract-schema --pf connect.pf --output schema.json
```

### Arguments

- `--table <name>`: Generate class for specific table
- `--tables <list>`: Generate classes for comma-separated list of tables
- `--all`: Generate classes for all tables in schema
- `--schema <file>`: Path to schema JSON file (default: schema.json)
- `--config <file>`: Path to configuration TOML file (default: ara-cli.toml)
- `--output <dir>`: Output directory (default: ara/)
- `--overwrite`: Overwrite existing files
- `--dry-run`: Show what would be generated without writing files

## Configuration

### TOML Configuration Structure

```toml
[general]
output_dir = "ara"
schema_file = "schema.json"
overwrite_existing = true
include_timestamps = true

[type_mapping]
# Custom type overrides (optional)
CHARACTER = { abl_type = "CHARACTER", prefix = "c_" }
INTEGER = { abl_type = "INTEGER", prefix = "i_" }
DECIMAL = { abl_type = "DECIMAL", prefix = "dec_" }
DATE = { abl_type = "DATE", prefix = "d_" }
DATETIME = { abl_type = "DATETIME", prefix = "dt_" }
LOGICAL = { abl_type = "LOGICAL", prefix = "l_" }
RAW = { abl_type = "RAW", prefix = "raw_" }
LONGCHAR = { abl_type = "LONGCHAR", prefix = "cl_" }

[generation]
include_json_methods = true
include_xml_methods = true
include_batch_methods = true
include_logging = true
include_temp_table_methods = true
include_related_records_hook = true

[output]
file_extension = ".cls"
class_prefix = ""
namespace = "ara"
```

## Schema Format

### JSON Schema Structure

```json
{
  "extracted_at": "2025-10-23T10:30:00Z",
  "database_info": {
    "name": "sports2020",
    "version": "12.8",
    "character_set": "iso8859-1"
  },
  "tables": [
    {
      "name": "Customer",
      "description": "Customer master table",
      "fields": [
        {
          "name": "CustNum",
          "data_type": "INTEGER",
          "extent": 0,
          "nullable": false,
          "initial": "0",
          "label": "Customer Number",
          "format": ">>>9",
          "help": "Unique customer identifier"
        },
        {
          "name": "Name",
          "data_type": "CHARACTER",
          "extent": 0,
          "nullable": false,
          "initial": "",
          "label": "Customer Name",
          "format": "x(30)",
          "help": "Customer full name"
        }
      ],
      "indexes": [
        {
          "name": "CustNum",
          "unique": true,
          "primary": true,
          "active": true,
          "fields": [
            {
              "name": "CustNum",
              "data_type": "INTEGER",
              "abl_type": "INTEGER",
              "ascending": true
            }
          ]
        },
        {
          "name": "Name",
          "unique": false,
          "primary": false,
          "active": true,
          "fields": [
            {
              "name": "Name",
              "data_type": "CHARACTER",
              "abl_type": "CHARACTER",
              "ascending": true
            }
          ]
        }
      ]
    }
  ]
}
```

## Code Generation

### Generated Class Structure

Each generated ABL class will include:

1. **Properties**: One property per table field with proper ABL data types
2. **ROWID Property**: Internal record identifier
3. **Temp Table**: Private temp-table matching table structure
4. **CRUD Methods**:
   - `Save()` - Create or update record
   - `Load(ROWID)` - Load by ROWID
   - `Load(index_params)` - Load by each index (type-safe)
   - `Delete()` - Delete current record
5. **Utility Methods**:
   - `LoadBatch(where_clause)` - Load multiple records
   - `LoadFields()` - Internal field loading
   - `LoadRelatedRecords()` - Hook for child classes
   - `ToJson()` - JSON serialization
   - `ToXml()` - XML serialization
   - `ToTempTable()` - Temp-table serialization
6. **Logging**: Optional debug logging support
7. **Constructor/Destructor**: Proper initialization

### Template System

Using Handlebars templates for maintainable code generation:

- `class.cls.hbs`: Main class structure
- `methods.hbs`: CRUD and utility methods
- `properties.hbs`: Property definitions
- `load_methods.hbs`: Index-based Load methods

### Type Safety

Without ara/types/ directory, method signatures use native ABL types:

```abl
/* Instead of: METHOD PUBLIC LOGICAL Load(INPUT pCustNum AS ara.types.i_CustNum): */
METHOD PUBLIC LOGICAL Load(INPUT pCustNum AS INTEGER):
```

## Progress Schema Extraction Script

### extract-schema.p Features

1. **Database Connection**: Uses provided .pf file
2. **Comprehensive Extraction**:
   - Table metadata from `_File`
   - Field details from `_Field`
   - Index information from `_Index` and `_Index-Field`
   - Data type mapping and validation
3. **JSON Output**: Structured JSON format for Rust parsing
4. **Performance**: Single-pass extraction with proper indexing
5. **Error Handling**: Robust error handling and logging

### Script Improvements Over Original

- Complete schema in single JSON file
- More detailed field metadata
- Better error handling and validation
- Configurable output options
- Performance optimizations

## Dependencies

### Rust Dependencies

```toml
[dependencies]
clap = { version = "4.0", features = ["derive"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tera = "1.19"
anyhow = "1.0"
thiserror = "1.0"
tokio = { version = "1.0", features = ["full"] }
tracing = "0.1"
tracing-subscriber = "0.3"

[dev-dependencies]
tempfile = "3.0"
assert_cmd = "2.0"
predicates = "3.0"
```

## Development Workflow

### 1. Setup Development Environment

```bash
# Initialize Rust project
cargo init
cargo add clap serde serde_json tera anyhow thiserror tokio tracing tracing-subscriber

# Create directory structure
mkdir -p src/{cli,config,schema,generator/templates,utils}
```

### 2. Implement Core Components

1. **Schema Models** (`src/schema/models.rs`)
2. **Configuration** (`src/config/settings.rs`)
3. **CLI Arguments** (`src/cli/args.rs`)
4. **Schema Parser** (`src/schema/parser.rs`)
5. **Type Mapping** (`src/utils/type_mapping.rs`)
6. **Templates** (`src/generator/templates/`)
7. **Class Generator** (`src/generator/class_generator.rs`)
8. **CLI Commands** (`src/cli/commands.rs`)
9. **Main Entry Point** (`src/main.rs`)

### 3. Create Progress Extraction Script

Develop `extract-schema.p` with comprehensive schema extraction capabilities.

### 4. Testing Strategy

- Unit tests for each component
- Integration tests with sample schemas
- End-to-end tests with Progress database
- Template validation tests
- CLI argument parsing tests

### 5. Documentation

- Comprehensive README with usage examples
- Inline code documentation
- Configuration reference
- Troubleshooting guide

## Benefits Over Original Implementation

1. **Performance**: Rust excels at processing large numbers of files efficiently
2. **Maintainability**: Separated concerns and template-based generation
3. **Flexibility**: CLI options for different generation scenarios
4. **Type Safety**: Maintained without wrapper class complexity
5. **Extensibility**: Easy to add new features via templates and configuration
6. **Modern Tooling**: Uses contemporary Rust ecosystem and best practices
7. **Better Error Handling**: Comprehensive error reporting and recovery
8. **Configuration Management**: TOML-based configuration for customization

## Future Enhancements

1. **Relationship Mapping**: Automatic foreign key relationship detection
2. **Validation Rules**: Generate validation methods based on field constraints
3. **Custom Templates**: Allow user-defined template directories
4. **Plugin System**: Extensible architecture for custom generators
5. **IDE Integration**: VS Code extension for ABL development
6. **Database Migration**: Schema change detection and migration support
7. **Performance Analysis**: Query optimization suggestions
8. **Testing Support**: Automated test generation for ORM classes

## Implementation Timeline

### Phase 1: Core Infrastructure (Week 1-2)
- Project setup and dependencies
- Schema models and configuration
- Basic CLI structure
- JSON schema parsing

### Phase 2: Code Generation (Week 3-4)
- Template system implementation
- Class generator core logic
- Method generation
- Type mapping utilities

### Phase 3: Progress Integration (Week 5)
- Schema extraction script
- End-to-end testing
- Error handling and validation

### Phase 4: Polish and Documentation (Week 6)
- Comprehensive testing
- Documentation and examples
- Performance optimization
- Release preparation

This implementation plan provides a solid foundation for a modern, efficient, and maintainable ABL ORM generator that builds upon the strengths of the original while leveraging Rust's performance and ecosystem advantages.