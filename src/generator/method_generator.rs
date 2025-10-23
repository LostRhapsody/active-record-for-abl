use crate::config::settings::Config;
use crate::schema::models::{Field, IndexField};
use crate::utils::type_mapping::TypeMapping;

pub struct MethodGenerator {
    config: Config,
}

impl MethodGenerator {
    pub fn new(config: Config) -> Self {
        Self { config }
    }
    
    /// Build ASSIGN block for Save method
    pub fn build_assign_block(&self, table_name: &str, fields: &[Field]) -> String {
        let mut assign_lines = Vec::new();
        
        for field in fields {
            let (_abl_type, _prefix) = TypeMapping::map_data_type_with_config(&field.data_type, &self.config);
            assign_lines.push(format!(
                "        buf{}.{} = THIS-OBJECT:{}",
                table_name, field.name, field.name
            ));
        }
        
        assign_lines.join(",\n")
    }
    
    /// Build ASSIGN block for LoadFields method
    pub fn build_load_fields_assign(&self, table_name: &str, fields: &[Field]) -> String {
        let mut assign_lines = Vec::new();
        
        for field in fields {
            assign_lines.push(format!(
                "      THIS-OBJECT:{} = buf{}.{}",
                field.name, table_name, field.name
            ));
        }
        
        assign_lines.join(",\n")
    }
    
    /// Build WHERE clause for index-based Load methods
    pub fn build_where_clause(&self, table_name: &str, index_fields: &[IndexField]) -> String {
        let mut where_parts = Vec::new();
        
        for field in index_fields {
            where_parts.push(format!(
                "buf{}.{} = p{}",
                table_name, field.name, field.name
            ));
        }
        
        where_parts.join(" AND ")
    }
    
    /// Build parameter list for overloaded Load methods
    pub fn build_parameter_list(&self, index_fields: &[IndexField]) -> String {
        let mut params = Vec::new();
        
        for field in index_fields {
            let (abl_type, _prefix) = TypeMapping::map_data_type_with_config(&field.data_type, &self.config);
            params.push(format!("INPUT p{} AS {}", field.name, abl_type));
        }
        
        params.join(", ")
    }
    
    /// Handle extent fields in JSON serialization
    pub fn build_json_extent_handling(&self, fields: &[Field]) -> String {
        let mut json_code = Vec::new();
        
        for field in fields {
            if field.extent > 0 {
                json_code.push(format!(
                    "    ja = NEW Progress.Json.ObjectModel.JsonArray().\n    DO i = 1 TO {}:\n      ja:Add(THIS-OBJECT:{}[i]).\n    END.\n    oJson:Add('{}', ja).",
                    field.extent, field.name, field.name
                ));
            } else {
                json_code.push(format!(
                    "    oJson:Add('{}', THIS-OBJECT:{}).",
                    field.name, field.name
                ));
            }
        }
        
        json_code.join("\n")
    }
}
