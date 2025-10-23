# Agent Guidelines for Active Record ABL

## Build/Test Commands
- `cargo build` - Build the project
- `cargo build --release` - Build optimized release
- `cargo test` - Run all tests
- `cargo test <test_name>` - Run single test
- `cargo run -- --help` - Test CLI functionality

## Code Style Guidelines

### Imports & Structure
- Use `use crate::` for internal modules
- Group external imports after internal ones
- Keep module declarations at file top

### Naming Conventions
- `PascalCase` for structs, enums, types
- `snake_case` for functions, variables, modules
- `SCREAMING_SNAKE_CASE` for constants
- Use descriptive names (e.g., `ClassGenerator`, `ProcessedField`)

### Error Handling
- Use `anyhow::Result<T>` for function returns
- Use `thiserror` for custom error types
- Use `?` operator for error propagation
- Handle errors gracefully with context

### Types & Patterns
- Prefer `String` over `&str` for owned data
- Use `HashMap<String, T>` for key-value mappings
- Implement `Default` for configuration structs
- Use `#[derive(Serialize, Deserialize)]` for data models

### Code Organization
- Keep modules focused and small
- Use `pub mod` for public module exports
- Separate data models from business logic
- Use templates for code generation (Tera)

### Configuration
- Use TOML for configuration files
- Provide sensible defaults
- Support CLI overrides for config values
- Use `clap` for command-line parsing