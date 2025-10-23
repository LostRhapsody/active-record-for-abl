use clap::Subcommand;

#[derive(Subcommand)]
pub enum Commands {
    /// Generate ABL classes from schema
    Generate {
        /// Generate class for specific table
        #[arg(long)]
        table: Option<String>,
        
        /// Generate classes for comma-separated list of tables
        #[arg(long)]
        tables: Option<String>,
        
        /// Generate classes for all tables in schema
        #[arg(long)]
        all: bool,
    },
    
    /// Extract schema from Progress database
    ExtractSchema {
        /// Path to Progress connection file (.pf)
        #[arg(long)]
        pf_file: String,
        
        /// Output JSON file for schema
        #[arg(long, default_value = "schema.json")]
        output: String,
    },
}
