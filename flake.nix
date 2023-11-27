{
  # virtualbox is not included in the flake
  # this needs to be installed on your system
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    rust-overlay.url = "github:oxalica/rust-overlay";

    # if old php versions are needed
    # phps.url = "github:fossar/nix-phps";
  };

  outputs = inputs@{ flake-parts, nixpkgs, rust-overlay, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = { pkgs, system, ... }:
        let

          pkgs = import nixpkgs {
            inherit system;  
            overlays = [(import rust-overlay)];
          };
          
          pythonToolchain = pkgs.python311;

          pyPkgs = with pythonToolchain.pkgs;
            [

              # ansible 2.11 stable
              (pythonToolchain.pkgs.buildPythonPackage rec {
                pname = "ansible";
                version = "0.2.11";
                format = "setuptools";

                src = pkgs.fetchFromGitHub {
                  owner = pname;
                  repo = pname;
                  rev = "05f919e21c724fe1bf490f4e8a4a450ebea92c8b";
                  hash = "sha256-qcpul7gTqKPq4ZGtsuUQtm/2MGKaMKaXomB81kvsrd8=";
                };

                dontStrip = true;
                doCheck = false;

                # from: https://github.com/ansible/ansible/blob/stable-2.11/requirements.txt
                propagatedBuildInputs = with pythonToolchain.pkgs; [
                  jinja2
                  pyyaml
                  cryptography
                  packaging
                  setuptools
                  resolvelib
                ];
              })

              #other py packages
              six
            ];

          rustToolchain = pkgs.rust-bin.nightly.latest.default;
          kifinix = pkgs.substituteAll {
            src = ./kifinix.rs;
            name = "kifinix";
            dir = "/bin";

            isExecutable = true;
          };

        in {
          devShells.default = pkgs.mkShell {
            packages = with pkgs;
              pyPkgs ++ [
                kifinix
                xdg-utils
                jq

                # other packages
                ruby
                vagrant
                openssl

                # NOTE: rust-analyzer doesnt work on cargo scripts for now 
                (rustToolchain.override { extensions = [
                  "cargo"
                  "clippy"
                  "rust-src"
                  "rust-analyzer"
                  "rustc"
                  "rustfmt"
                ];})
                
                ansible-language-server
                rubyPackages.solargraph

                # fix for vscode shell prompt escape characters
                bashInteractive
              ];

            shellHook = ''

              # start ssh-agent locally in shell
              eval $(ssh-agent -s)

              echo "
                Welcome to kifinix shell!
            
                Ensure you have a gitlab ssh key set up
                if you already have it, it's usually located in '~/.ssh/...'

                and export SSH_KEYS=<keys>
                or you can put it in .env to make it persistent
              "

              if ! type VBoxManage &> /dev/null; then
                echo "
                  No virtualbox installation detected
                  Make sure it is installed
                "
              fi

              source .env
              ssh-add $SSH_KEYS

              export PS1="\[\033[01;32m\][kifinix>''\\u@''\\h:''\\w]$\[\033[00m\] "
              export VAGRANT_HOME="$PWD/.vagrant.d"
            '';
          };
        };
  };
}
