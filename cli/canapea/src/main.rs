extern crate lib;
extern crate lsp;

use clap::{Parser, Subcommand, ValueEnum};

#[derive(Debug, Parser)]
#[command(
  name = "canapea",
  version,
  about = "Your friendly Canapea Command Line Interface",
  long_about = None,
)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    // #[command(arg_required_else_help = true)]
    #[command(about = "Builds a Canapea program against a platform")]
    Build {
        #[arg(value_enum, default_value_t = BuildProfile::Development)]
        profile: BuildProfile,

        #[arg(
            value_enum,
            long,
            // require_equals = true,
            // value_name = "WHEN",
            // num_args = 0..=1,
            default_value_t = Platform::Cli,
            // default_missing_value = "cli",
            // about = "The platform to build the application against",
        )]
        platform: Platform,
    },
    #[command(alias = "lsp", about = "Starts the Canapea language server")]
    LanguageServer {
        #[arg(
            value_enum,
            long,
            // require_equals = true,
            // value_name = "WHEN",
            // num_args = 0..=1,
            default_value_t = TransportKind::Stdio,
            // default_missing_value = "cli",
            // about = "The platform to build the application against",
        )]
        transport: TransportKind,
    },

    #[command(
        alias = "fmt",
        about = "Formats Canapea code.",
        long_about = "Formats Canapea code, there is no configuration, enjoy the tranquility."
    )]
    Format {
        #[arg(
            alias = "glob",
            default_value = "./**/*.canapea",
            // about = "The directory look for code to format, supports glob patterns"
            // about = "The directory to format code in",
        )]
        pattern: String,
    },
}

#[derive(ValueEnum, Copy, Clone, Debug, PartialEq, Eq)]
enum BuildProfile {
    Development,
}

#[derive(ValueEnum, Copy, Clone, Debug, PartialEq, Eq)]
enum Platform {
    Cli,
}

#[derive(ValueEnum, Copy, Clone, Debug, PartialEq, Eq)]
enum TransportKind {
    Stdio,
}

// #[derive(ValueEnum, Copy, Clone, Debug, PartialEq, Eq)]
// enum Verbosity {
//   Quiet,
//   Normal,
//   Verbose,
//   // Excessive,
// }

// #[derive(Subcommand, Debug, Clone)]
// #[command()]
// enum Package {
//   #[value()]
//   Add,
// }

fn main() {
    let wild_args = wild::args();
    let args = Cli::parse_from(wild_args);

    println!("{args:?}");

    lib::say_hello();

    match args.command {
        Commands::Format { pattern } => {
            lib::format_files(pattern.as_str());
        }
        Commands::LanguageServer { transport } => {
            // TODO: How to map DTO types to library types automatically?
            lsp::start(lsp::LanguageServerConfig {
                transport: match transport {
                    TransportKind::Stdio => lsp::TransportKind::Stdio,
                },
            });
        }
        _ => (),
    }
}
