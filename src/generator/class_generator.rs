use crate::config::settings::Config;
use crate::schema::models::Table;
use crate::utils::type_mapping::TypeMapping;
use anyhow::Result;
use tera::{Context, Tera};

pub struct ClassGenerator {
    config: Config,
    tera: Tera,
}

impl ClassGenerator {
    pub fn new(config: Config) -> Self {
        let mut tera = Tera::default();
        tera.autoescape_on(vec![]); // Disable auto-escaping for ABL code

        // Add embedded templates
        tera.add_raw_template("class.cls.hbs", include_str!("templates/class.cls.hbs")).unwrap();
        tera.add_raw_template("methods.hbs", include_str!("templates/methods.hbs")).unwrap();
        tera.add_raw_template("load_methods.hbs", include_str!("templates/load_methods.hbs")).unwrap();
        tera.add_raw_template("utilities.hbs", include_str!("templates/utilities.hbs")).unwrap();

        Self { config, tera }
    }

    pub fn generate_class(&self, table: &Table, class_name: &str) -> Result<String> {
        let mut context = Context::new();

        // Basic table info\
        context.insert("class_name", &class_name);
        context.insert("table_name", &table.name);
        context.insert("namespace", &self.config.output.namespace);
        context.insert(
            "timestamp",
            &chrono::Utc::now()
                .format("%Y-%m-%d %H:%M:%S UTC")
                .to_string(),
        );

        // Process fields with type mapping
        let mut processed_fields = Vec::new();
        for field in &table.fields {
            let (abl_type, _prefix) =
                TypeMapping::map_data_type_with_config(&field.data_type, &self.config);
            processed_fields.push(ProcessedField {
                name: field.name.clone(),
                abl_type,
                extent: field.extent,
            });
        }
        context.insert("fields", &processed_fields);

        // Process indexes with type mapping
        let mut processed_indexes = Vec::new();
        for index in &table.indexes {
            let mut processed_index_fields = Vec::new();
            for index_field in &index.fields {
                let (abl_type, _prefix) =
                    TypeMapping::map_data_type_with_config(&index_field.data_type, &self.config);
                processed_index_fields.push(ProcessedIndexField {
                    name: index_field.name.clone(),
                    abl_type,
                });
            }
            processed_indexes.push(ProcessedIndex {
                name: index.name.clone(),
                fields: processed_index_fields,
            });
        }
        context.insert("indexes", &processed_indexes);

        // Render the main class template
        let content = self.tera.render("class.cls.hbs", &context)?;
        
        // Post-process: strip empty lines to make files more compact
        let cleaned_content = content
            .lines()
            .filter(|line| !line.trim().is_empty())
            .collect::<Vec<&str>>()
            .join("\n");
        
        Ok(cleaned_content)
    }
}

#[derive(serde::Serialize)]
struct ProcessedField {
    name: String,
    abl_type: String,
    extent: u32,
}

#[derive(serde::Serialize)]
struct ProcessedIndex {
    name: String,
    fields: Vec<ProcessedIndexField>,
}

#[derive(serde::Serialize)]
struct ProcessedIndexField {
    name: String,
    abl_type: String,
}
