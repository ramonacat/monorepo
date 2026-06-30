mod kubernetes;
mod pki;

use std::io;

use clap::{CommandFactory, Parser, Subcommand};
use clap_complete::Shell;

#[derive(Debug, Subcommand)]
enum Commands {
    Pki {
        #[command(subcommand)]
        action: pki::Action,
    },
    Kubernetes {
        #[command(subcommand)]
        action: kubernetes::Action,
    },
    Completions {
        shell: Shell,
    },
}

#[derive(Debug, Parser)]
struct Args {
    #[command(subcommand)]
    command: Commands,
}

fn main() {
    let args = Args::parse();

    match args.command {
        Commands::Pki { action } => pki::cli(action),
        Commands::Kubernetes { action } => kubernetes::cli(action),
        Commands::Completions { shell } => {
            let mut command = Args::command();
            let command_name = command.get_name().to_owned();
            clap_complete::generate(shell, &mut command, command_name, &mut io::stdout());
        }
    }
}
