{
  # virtualbox is not included in the flake
  # this needs to be installed on your system
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    let
      ansible-collections = [
        "community.general"
        "community.mysql"
        "community.postgresql"
        "community.docker"
        "ansible.posix"
      ];
    in flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem = { pkgs, ... }:
        let

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
            ];

            kifinix = pkgs.writeShellScriptBin "kifinix" ''
                if [[ "$1" == "clean" ]]; then 
                  echo "Cleaning up..."
                  vagrant destroy -f
                  rm -f ip_mapping.json
                  rm -f hosts.base
                  rm -f playbooks
                  rm -rf shared
                  rm -rf .vagrant
                fi

                if [[ "$1" == "init" ]]; then
                  echo "Enter playbooks directory!"

                  playbooks_dir= 
                  while true ; do
                    read -r -p "Path: " playbooks_dir
                    if [ -d "$playbooks_dir" ] ; then
                      break
                    fi
                    echo "$playbooks_dir is not a directory!"
                  done

                  ln -s $playbooks_dir playbooks
                  ./inventory.rb --hosts

                  ansible-galaxy collection install ${
                    pkgs.lib.concatStringsSep " " ansible-collections
                  }
                fi

                if [[ "$1" == "hosts" ]] then              
                    ./inventory.rb --hosts
                fi

            '';

        in {
          devShells.default = pkgs.mkShell {
            packages = with pkgs;
              pyPkgs ++ [
                kifinix
                # other packages
                ruby
                vagrant
                openssl

                # fix for vscode shell prompt escape characters
                bashInteractive
              ];

            shellHook = ''

              # start ssh-agent locally in shell
              eval $(ssh-agent) > /dev/null

              echo "
                Welcome to kifinix shell!
              
                Ensure you have a gitlab ssh key set up
                if you already have it, it's usually located in '~/.ssh/...'

                and export GITLAB_SSH_KEY=<path>
                or you can put it in .env to make it persistent
              "

              source .env
              ssh-add $GITLAB_SSH_KEY

              export PS1="\[\033[01;32m\][kifinix>''\\u@''\\h:''\\w]$\[\033[00m\] "
            '';
          };
        };
    };
}
