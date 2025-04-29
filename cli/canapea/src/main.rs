extern crate lib;

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
  command: Commands
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
}

#[derive(ValueEnum, Copy, Clone, Debug, PartialEq, Eq)]
enum BuildProfile {
  Development,
}

#[derive(ValueEnum, Copy, Clone, Debug, PartialEq, Eq)]
enum Platform {
  Cli,
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
  let args = Cli::parse();

  println!("{args:?}");

  lib::say_hello();
}
