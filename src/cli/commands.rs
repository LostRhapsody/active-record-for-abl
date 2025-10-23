use crate::config::settings::Config;
use crate::generator::class_generator::ClassGenerator;
use crate::schema::parser::SchemaParser;
use anyhow::Result;
use std::process::Command;

pub async fn handle_generate(
    config: Config,
    schema_file: String,
    output_dir: String,
    table: Option<String>,
    tables: Option<String>,
    all: bool,
    overwrite: bool,
    dry_run: bool,
) -> Result<()> {
    tracing::info!("Starting code generation");

    // Parse schema
    let schema = SchemaParser::load(&schema_file)?;

    // Determine which tables to generate
    let table_names = if let Some(table_name) = table {
        vec![table_name]
    } else if let Some(table_list) = tables {
        table_list
            .split(',')
            .map(|s| s.trim().to_string())
            .collect()
    } else if all {
        schema.tables.iter().map(|t| t.name.clone()).collect()
    } else {
        return Err(anyhow::anyhow!("Must specify --table, --tables, or --all"));
    };

    // Generate classes
    let generator = ClassGenerator::new(config);

    for table_name in table_names {
        if let Some(table) = schema.tables.iter().find(|t| t.name == table_name) {
            tracing::info!("Generating class for table: {}", table_name);

            if dry_run {
                println!("Would generate: {}/{}.cls", output_dir, table_name);
                continue;
            }

            // Convert table_name to PascalCase for class naming (remove - and _ and uppercase each word)
            let class_name = table_name
            .replace(['-', '_'], " ")
            .split_whitespace()
            .map(|word| {
                let mut chars = word.chars();
                match chars.next() {
                    Some(f) => f.to_uppercase().collect::<String>() + chars.as_str(),
                    None => String::new(),
                }
            })
            .collect::<String>();

            let content = generator.generate_class(table, &class_name)?;

            // Ensure output directory exists
            std::fs::create_dir_all(&output_dir)?;

            let output_path = format!("{}/{}.cls", output_dir, class_name);

            // Check if file exists and overwrite flag
            if std::path::Path::new(&output_path).exists() && !overwrite {
                tracing::warn!("File {} exists, use --overwrite to replace", output_path);
                continue;
            }

            std::fs::write(&output_path, content)?;
            println!("Generated: {}", output_path);
        } else {
            tracing::warn!("Table {} not found in schema", table_name);
        }
    }

    Ok(())
}

pub async fn handle_extract_schema(pf_file: String, output_file: String) -> Result<()> {
    tracing::info!("Extracting schema from Progress database");

    // Execute Progress script
    let output = Command::new("_progres")
        .arg("-pf")
        .arg(&pf_file)
        .arg("-p")
        .arg("extract-schema.p")
        .arg("-b")
        .output()?;

    if !output.status.success() {
        let stdout = String::from_utf8_lossy(&output.stdout);
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(anyhow::anyhow!(
            "Progress script failed: {}",
            format!("stdout: {}\nstderr:{}", stdout, stderr)
        ));
    }

    // Move generated schema.json to specified output
    if output_file != "schema.json" {
        std::fs::rename("schema.json", &output_file)?;
    }

    println!("Schema extracted to: {}", output_file);
    Ok(())
}
