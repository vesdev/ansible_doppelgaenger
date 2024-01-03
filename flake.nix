{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
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
        let python = pkgs.python311;
        in {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              ((import ./ansible.nix { inherit pkgs python; })."2.11.12")

              (pkgs.substituteAll {
                src = ./kifinix.py;
                name = "kifinix";
                dir = "/bin";

                isExecutable = true;
              })

              #other py packages
              python.pkgs.six
              python.pkgs.python-lsp-server

              # packages
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

              export KIFINIX_ROOT=$PWD
              export VAGRANT_HOME="$KIFINIX_ROOT/env/.vagrant.d"
              export PS1="\[\033[01;32m\][kifinix>\u@\h:\w]$\[\033[00m\] "
            '';
          };
        };
    };
}
