use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub general: GeneralConfig,
    pub type_mapping: HashMap<String, TypeMapping>,
    pub generation: GenerationConfig,
    pub output: OutputConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeneralConfig {
    pub output_dir: String,
    pub schema_file: String,
    pub overwrite_existing: bool,
    pub include_timestamps: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TypeMapping {
    pub abl_type: String,
    pub prefix: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerationConfig {
    pub include_json_methods: bool,
    pub include_xml_methods: bool,
    pub include_batch_methods: bool,
    pub include_logging: bool,
    pub include_temp_table_methods: bool,
    pub include_related_records_hook: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OutputConfig {
    pub file_extension: String,
    pub class_prefix: String,
    pub namespace: String,
}

impl Config {
    pub fn load(config_file: &str) -> Result<Self> {
        if std::path::Path::new(config_file).exists() {
            let content = fs::read_to_string(config_file)?;
            let config: Config = toml::from_str(&content)?;
            Ok(config)
        } else {
            // Return default configuration
            Ok(Config::default())
        }
    }
}

impl Default for Config {
    fn default() -> Self {
        let mut type_mapping = HashMap::new();
        type_mapping.insert("CHARACTER".to_string(), TypeMapping {
            abl_type: "CHARACTER".to_string(),
            prefix: "c_".to_string(),
        });
        type_mapping.insert("INTEGER".to_string(), TypeMapping {
            abl_type: "INTEGER".to_string(),
            prefix: "i_".to_string(),
        });
        type_mapping.insert("DECIMAL".to_string(), TypeMapping {
            abl_type: "DECIMAL".to_string(),
            prefix: "dec_".to_string(),
        });
        type_mapping.insert("DATE".to_string(), TypeMapping {
            abl_type: "DATE".to_string(),
            prefix: "d_".to_string(),
        });
        type_mapping.insert("DATETIME".to_string(), TypeMapping {
            abl_type: "DATETIME".to_string(),
            prefix: "dt_".to_string(),
        });
        type_mapping.insert("LOGICAL".to_string(), TypeMapping {
            abl_type: "LOGICAL".to_string(),
            prefix: "l_".to_string(),
        });
        type_mapping.insert("RAW".to_string(), TypeMapping {
            abl_type: "RAW".to_string(),
            prefix: "raw_".to_string(),
        });
        type_mapping.insert("LONGCHAR".to_string(), TypeMapping {
            abl_type: "LONGCHAR".to_string(),
            prefix: "cl_".to_string(),
        });

        Config {
            general: GeneralConfig {
                output_dir: "ara".to_string(),
                schema_file: "schema.json".to_string(),
                overwrite_existing: true,
                include_timestamps: true,
            },
            type_mapping,
            generation: GenerationConfig {
                include_json_methods: true,
                include_xml_methods: true,
                include_batch_methods: true,
                include_logging: true,
                include_temp_table_methods: true,
                include_related_records_hook: true,
            },
            output: OutputConfig {
                file_extension: ".cls".to_string(),
                class_prefix: "".to_string(),
                namespace: "ara".to_string(),
            },
        }
    }
}
