use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatabaseSchema {
    pub extracted_at: String,
    pub database_info: DatabaseInfo,
    pub tables: Vec<Table>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatabaseInfo {
    pub name: String,
    pub version: String,
    pub character_set: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Table {
    pub name: String,
    pub description: Option<String>,
    pub fields: Vec<Field>,
    pub indexes: Vec<Index>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Field {
    pub name: String,
    pub data_type: String,
    pub extent: u32,
    pub nullable: bool,
    pub initial: String,
    pub label: Option<String>,
    pub format: Option<String>,
    pub help: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Index {
    pub name: String,
    pub unique: bool,
    pub primary: bool,
    pub active: bool,
    pub fields: Vec<IndexField>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IndexField {
    pub name: String,
    pub data_type: String,
    pub abl_type: String,
    pub ascending: bool,
}
