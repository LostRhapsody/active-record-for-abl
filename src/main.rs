// TODO: Implement dirty tracking to only update changed fields instead of all fields
// This would improve performance by only sending modified field values to the database
// TODO: Got some errors from the test-orderline.p script, bad spots have been commented out, need to fix the methods causing them.

use clap::Parser;
use anyhow::Result;

mod cli;
mod config;
mod schema;
mod generator;
mod utils;

use cli::args::Commands;
use config::settings::Config;

#[derive(Parser)]
#[command(name = "ara-cli")]
#[command(about = "Active Record ORM generator for Progress ABL")]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
    
    /// Path to configuration file
    #[arg(short, long, default_value = "ara-cli.toml")]
    config: String,
    
    /// Path to schema JSON file
    #[arg(short, long, default_value = "schema.json")]
    schema: String,
    
    /// Output directory for generated files
    #[arg(short, long, default_value = "ara")]
    output: String,
    
    /// Overwrite existing files
    #[arg(long)]
    overwrite: bool,
    
    /// Show what would be generated without writing files
    #[arg(long)]
    dry_run: bool,
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    
    let cli = Cli::parse();
    let config = Config::load(&cli.config)?;
    
    match cli.command {
        Commands::Generate { table, tables, all } => {
            cli::commands::handle_generate(config, cli.schema, cli.output, table, tables, all, cli.overwrite, cli.dry_run).await
        }
        Commands::ExtractSchema { pf_file, output } => {
            cli::commands::handle_extract_schema(pf_file, output).await
        }
    }
}
