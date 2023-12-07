#!/usr/bin/env -S cargo -Zscript
```cargo
[dependencies]
anyhow = "1.0.75"
argh = "0.1.12"
xshell = "0.2.5"
```

use argh::FromArgs;
use xshell::{cmd, Shell};
use std::path::PathBuf;

/// Command line tool for
#[derive(FromArgs)]
struct Kifinix {
    #[argh(subcommand)]
    command: Command,
}

/// Command to execute
#[derive(FromArgs)]
#[argh(subcommand)]
enum Command {
    Clean(Clean),
    Init(Init),
}

/// Clean up the project
#[derive(FromArgs)]
#[argh(subcommand, name = "clean")]
struct Clean {}

/// Initialize the project
#[derive(FromArgs)]
#[argh(subcommand, name = "init")]
struct Init {
    /// playbooks directory
    #[argh(positional)]
    playbooks_path: PathBuf,
}

fn main() -> anyhow::Result<()> {
    let kicli: Kifinix = argh::from_env();

    let sh = Shell::new()?;
    match kicli.command {
        Command::Clean(_) => {
            cmd!(sh, "echo Cleaning up...").run()?;
            cmd!(sh, "vagrant destroy -f").quiet().run()?;
            // NOTE: only use rm incase playbooks is a directory
            // instead of a symlink, so it wont remove the directory
            cmd!(sh, "rm playbooks").quiet().run()?;
            cmd!(sh, "rm -f ip_mapping.json").quiet().run()?;
            cmd!(sh, "rm -f hosts.base").quiet().run()?;
            cmd!(sh, "rm -rf shared").quiet().run()?;
            cmd!(sh, "rm -rf .vagrant").quiet().run()?;
            cmd!(sh, "rm -rf .vagrant.d").quiet().run()?;
            cmd!(sh, "rm ansible.log").quiet().run()?;
            Ok(())
        }
        Command::Init (Init { playbooks_path }) => {
            let ansible_collections = [
                "community.general",
                "community.mysql",
                "community.postgresql",
                "community.docker",
                "ansible.posix",
            ];

            cmd!(
                sh,
                "ln -s {playbooks_path} playbooks"
            )
            .run()?;

            for collection in ansible_collections {
                cmd!(sh, "ansible-galaxy collection install {collection} --force").run()?;
            }

            cmd!(sh, "./inventory.rb --hosts").run()?;
            Ok(())
        }
    }
}
