{
  # virtualbox is not included in the flake
  # this needs to be installed on your system

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # if old php versions are needed
    # phps.url = "github:fossar/nix-phps";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
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
          pythonToolchain = pkgs.python311;

          pyPkgs = with pythonToolchain.pkgs; [

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
            python-lsp-server
          ];

          rustToolchain = pkgs.rust-bin.nightly.latest.default;
          kifinix = pkgs.substituteAll {
            src = ./kifinix.py;
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

                ansible-language-server
                rubyPackages.solargraph

                # fix for vscode shell prompt escape characters
                bashInteractive
              ];

            shellHook = ''

              # start ssh-agent
              eval $(ssh-agent -s) > /dev/null

              ./keys.sh

              if ! type VBoxManage &> /dev/null; then
                echo "
                  No virtualbox installation detected
                  Ensure it is installed
                "
              fi

              export VAGRANT_HOME="$PWD/.vagrant.d"
              export PS1="\[\033[01;32m\][kifinix>\u@\h:\w]$\[\033[00m\] "

            '';
          };
        };
    };
}
