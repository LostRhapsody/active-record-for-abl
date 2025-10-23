use anyhow::Result;
use crate::schema::models::DatabaseSchema;
use std::fs;

pub struct SchemaParser;

impl SchemaParser {
    pub fn load(schema_file: &str) -> Result<DatabaseSchema> {
        let content = fs::read_to_string(schema_file)?;
        let schema: DatabaseSchema = serde_json::from_str(&content)?;
        Ok(schema)
    }
}
