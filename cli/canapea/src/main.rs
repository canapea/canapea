extern crate lib;
extern crate lsp;

use std::str::FromStr;

use clap::{Parser, Subcommand, ValueEnum, builder::ArgPredicate};

const DEFAULT_HOST: &str = "127.0.0.1";

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
    #[command(about = "Builds a Canapea program against a platform")]
    Build {
        #[arg(value_enum, default_value_t = BuildProfile::Development)]
        profile: BuildProfile,

        #[arg(
            value_enum,
            long,
            default_value_t = Platform::Cli,
            help = "The platform to build the application against",
        )]
        platform: Platform,
    },
    #[command(about = "Starts the Canapea language server")]
    #[command(arg_required_else_help = true)]
    LanguageServer {
        #[arg(
            exclusive = true,
            long,
            default_missing_value = "true",
            help = "Use STDIO for communicating with the client"
        )]
        stdio: bool,

        #[arg(
            exclusive = true,
            long,
            help = "Use named UNIX pipes for communicating with the client"
        )]
        pipe: Option<String>,

        #[arg(long, help = "Use TCP socket for communicating with the client")]
        socket: Option<u16>,

        // TODO: Use better input values, this primitive obsession is annoying
        // socket: TcpPort,
        // socket: TcpSocket,
        // TODO: default_value = DEFAULT_HOST to show the user
        #[arg(
            long,
            requires = "socket",
            default_value_if("socket", ArgPredicate::IsPresent, DEFAULT_HOST),
            help = "The host for TCP communication with the client - defaults to localhost."
        )]
        host: Option<String>,
    },
    #[command(
        about = "Formats Canapea code.",
        long_about = "Formats Canapea code, there is no configuration, enjoy the tranquility."
    )]
    Format {
        #[arg(
            default_value = "./**/*.{cnp,canapea}",
            help = "The glob pattern to select the files to be formatted"
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

// #[derive(Debug, Clone, PartialEq, Eq)]
// struct UnixPipePath(String);

// #[derive(Debug, Clone, PartialEq, Eq)]
// struct TcpHost(String);

// #[derive(Debug, Clone, PartialEq, Eq)]
// struct TcpPort(u16);

fn main() {
    let wild_args = wild::args();
    let args = Cli::parse_from(wild_args);

    println!("{args:?}");

    lib::say_hello();

    match args.command {
        Commands::Format { pattern } => {
            lib::format_files(pattern.as_str());
        }
        Commands::LanguageServer {
            stdio,
            pipe,
            host,
            socket,
        } => {
            if stdio {
                lsp::start(lsp::LanguageServerConfig {
                    transport: lsp::TransportKind::Stdio,
                })
            } else if let Some(path) = pipe {
                lsp::start(lsp::LanguageServerConfig {
                    transport: lsp::TransportKind::UnixSocket { path },
                })
            } else if let Some(port) = socket {
                match std::net::IpAddr::from_str(
                    host.unwrap_or(DEFAULT_HOST.to_string()).as_str(),
                ) {
                    Ok(ip) => lsp::start(lsp::LanguageServerConfig {
                        transport: lsp::TransportKind::TcpSocket(
                            std::net::SocketAddr::new(ip, port),
                        ),
                    }),
                    _ => unimplemented!(),
                }
            }
        }
        Commands::Build {
            profile: _,
            platform: _,
        } => {
            unimplemented!()
        }
    }
}
