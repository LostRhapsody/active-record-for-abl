use crate::config::settings::Config;

pub struct TypeMapping;

impl TypeMapping {
    /// Maps Progress data types to ABL types with prefixes
    /// Ported from progress-orm-generate.p lines 22-38
    pub fn map_data_type(progress_type: &str) -> (String, String) {
        let progress_type = progress_type.to_uppercase();
        match progress_type.as_str() {
            "BLOB" => ("RAW".to_string(), "b_".to_string()),
            "CHARACTER" => ("CHARACTER".to_string(), "c_".to_string()),
            "CLOB" => ("LONGCHAR".to_string(), "cl_".to_string()),
            "DATE" => ("DATE".to_string(), "d_".to_string()),
            "DATETIME" => ("DATETIME".to_string(), "dt_".to_string()),
            "DATETIME-TZ" => ("DATETIME-TZ".to_string(), "dttz_".to_string()),
            "DECIMAL" => ("DECIMAL".to_string(), "dec_".to_string()),
            "INTEGER" => ("INTEGER".to_string(), "i_".to_string()),
            "INT64" => ("INT64".to_string(), "i64_".to_string()),
            "LOGICAL" => ("LOGICAL".to_string(), "l_".to_string()),
            "RECID" => ("INTEGER".to_string(), "r_".to_string()),
            "RAW" => ("RAW".to_string(), "raw_".to_string()),
            _ => ("CHARACTER".to_string(), "c_".to_string()), // Fallback
        }
    }
    
    /// Maps Progress data types using configuration overrides
    pub fn map_data_type_with_config(progress_type: &str, config: &Config) -> (String, String) {
        if let Some(mapping) = config.type_mapping.get(progress_type) {
            (mapping.abl_type.clone(), mapping.prefix.clone())
        } else {
            Self::map_data_type(progress_type)
        }
    }
}
