# Active Record ABL (ARA) - Rust CLI Implementation

A modern Rust CLI tool that generates type-safe Active Record ORM classes for Progress ABL applications. This tool extracts database schemas from Progress databases and generates comprehensive ABL classes with full CRUD operations, utilities, and type safety.

## Features

- **Two-Phase Architecture**: Progress schema extraction + Rust code generation
- **Type-Safe Generation**: Native ABL types with compile-time safety
- **Full CRUD Operations**: Save, Load (multiple variants), Delete
- **Utility Methods**: JSON/XML serialization, temp-table support, batch operations
- **Index-Based Loading**: Type-safe Load methods for each database index
- **Logging Support**: Built-in debugging and file logging capabilities
- **Extensible Design**: Protected hooks for child class customization
- **Configuration**: TOML-based configuration with sensible defaults

## Quick Start

### 1. Extract Database Schema

For me: Do this from the current working directory of the `ara` tool. The templates directory needs to be relative to the current working directory.

```bash
# Extract schema from Progress database
ara-cli extract-schema --pf-file connect.pf --output schema.json
```

### 2. Generate ABL Classes

```bash
# Generate for specific table
ara-cli generate --table Customer

# Generate for multiple tables
ara-cli generate --tables Customer,Order,OrderLine

# Generate for all tables
ara-cli generate --all

# Dry run to see what would be generated
ara-cli --dry-run generate --all
```

## Installation

### Prerequisites

- Rust 1.70+
- Progress OpenEdge (for schema extraction)
- Access to Progress database

### Build from Source

```bash
git clone <repository-url>
cd active-record-abl
cargo build --release
```

## Usage

### Schema Extraction

The `extract-schema` command runs a Progress script to extract complete database metadata:

```bash
ara-cli extract-schema --pf-file connect.pf --output schema.json
```

**Requirements:**
- Valid Progress connection file (`.pf`)
- Access to Progress database
- `pro` command available in PATH

### Code Generation

The `generate` command creates ABL classes from extracted schema:

```bash
# Basic usage
ara-cli generate --table Customer

# Multiple tables
ara-cli generate --tables Customer,Order

# All tables
ara-cli generate --all

# With custom options
ara-cli --config custom.toml --output ./generated generate --all
```

### Global Options

- `--config <file>`: Configuration file (default: `ara-cli.toml`)
- `--schema <file>`: Schema JSON file (default: `schema.json`)
- `--output <dir>`: Output directory (default: `ara`)
- `--overwrite`: Overwrite existing files
- `--dry-run`: Show what would be generated

## Configuration

### Default Configuration (`ara-cli.toml`)

```toml
[general]
output_dir = "ara"
schema_file = "schema.json"
overwrite_existing = true
include_timestamps = true

[type_mapping]
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

## Generated ABL Classes

Each generated class includes:

### Properties
- One property per database field with correct ABL types
- `ROWID_` property for record identification
- Private temp-table matching table structure
- Protected logging properties (`DebugEnabled`, `LogFile`)

### CRUD Methods
- `Save()`: Create or update with transaction safety
- `Load(ROWID)`: Load by ROWID
- `Load(index_params)`: Type-safe Load methods for each index
- `Delete()`: Delete with transaction safety

### Utility Methods
- `LoadBatch(WHERE)`: Dynamic query with extent return
- `ToJson()`: JSON serialization with extent field support
- `ToXml()`: XML serialization via temp-table
- `ToTempTable()`: Temp-table serialization
- `LoadRelatedRecords()`: Protected hook for child classes

### Example Generated Class

```abl
CLASS ara.Customer:

  DEFINE PUBLIC PROPERTY CustNum AS INTEGER GET. SET.
  DEFINE PUBLIC PROPERTY Name AS CHARACTER GET. SET.
  DEFINE PUBLIC PROPERTY Country AS CHARACTER GET. SET.
  DEFINE PUBLIC PROPERTY ROWID_ AS ROWID GET. SET.

  /* CRUD Methods */
  METHOD PUBLIC VOID Save(): ...
  METHOD PUBLIC LOGICAL Load(INPUT prRowId AS ROWID): ...
  METHOD PUBLIC LOGICAL Load(INPUT pCustNum AS INTEGER): ...
  METHOD PUBLIC LOGICAL Load(INPUT pName AS CHARACTER): ...
  METHOD PUBLIC VOID Delete(): ...

  /* Utility Methods */
  METHOD PUBLIC ara.Customer EXTENT LoadBatch(INPUT pcWhere AS CHARACTER): ...
  METHOD PUBLIC Progress.Json.ObjectModel.JsonObject ToJson(): ...
  METHOD PUBLIC LONGCHAR ToXml(): ...
  METHOD PUBLIC HANDLE ToTempTable(): ...

END CLASS.
```

## Type Safety

Generated Load methods use **native ABL types** directly:

```abl
/* Type-safe method signatures */
METHOD PUBLIC LOGICAL Load(INPUT pCustNum AS INTEGER):
METHOD PUBLIC LOGICAL Load(INPUT pName AS CHARACTER):
METHOD PUBLIC LOGICAL Load(INPUT pOrderNum AS INTEGER, INPUT pLineNum AS INTEGER):
```

No wrapper classes needed - the methods are type-safe at compile time.

## Architecture

### Two-Phase Design

1. **Schema Extraction (Progress)**
   - `extract-schema.p`: Progress script queries system tables
   - Exports complete metadata to JSON format
   - Includes tables, fields, indexes, data types, relationships

2. **Code Generation (Rust)**
   - Reads JSON schema file
   - Generates ABL classes using Tera templates
   - Applies type mappings and configuration

### Project Structure

```
active-record-abl/
├── src/
│   ├── main.rs                 # CLI entry point
│   ├── cli/                    # Command-line interface
│   ├── config/                 # Configuration management
│   ├── schema/                 # Schema models and parsing
│   ├── generator/              # Code generation
│   │   └── templates/          # Tera templates
│   └── utils/                  # Utilities
├── extract-schema.p            # Progress extraction script
├── connect.pf                  # Sample connection file
├── ara-cli.toml               # Default configuration
└── schema.json                 # Generated schema (gitignored)
```

## Development

### Building

```bash
cargo build
cargo build --release
```

### Testing

```bash
cargo test
cargo run -- --help
```

### Template Development

Templates are located in `src/generator/templates/`:
- `class.cls.hbs`: Main class structure
- `methods.hbs`: CRUD and utility methods
- `load_methods.hbs`: Index-based Load methods
- `utilities.hbs`: Serialization methods

## Benefits Over Original Implementation

1. **Performance**: Rust excels at processing large numbers of files
2. **Maintainability**: Separated concerns and template-based generation
3. **Flexibility**: CLI options for different generation scenarios
4. **Type Safety**: Maintained without wrapper class complexity
5. **Extensibility**: Easy to add features via templates and configuration
6. **Modern Tooling**: Contemporary Rust ecosystem and best practices
7. **Better Error Handling**: Comprehensive error reporting and recovery
8. **Configuration Management**: TOML-based customization

## Future Enhancements

- Relationship mapping and foreign key detection
- Validation rules based on field constraints
- Custom template directories
- Plugin system for custom generators
- IDE integration (VS Code extension)
- Database migration support
- Performance analysis and query optimization
- Automated test generation

## License

[License information]

## Contributing

[Contributing guidelines]
