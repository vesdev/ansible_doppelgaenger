{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, system, ... }:
        let
          python = pkgs.python311;
          ansible = (import ./ansible.nix { inherit pkgs python; })."2.11.12";
          kifinix = pkgs.substituteAll {
            src = ./kifinix.py;
            name = "kifinix";
            dir = "/bin";

            isExecutable = true;
          };

          minimalPackages = with pkgs; [
            ansible
            kifinix

            ruby
            php

            vagrant
            openssl
            python.pkgs.six

            # fix for vscode shell prompt escape characters
            bashInteractive
            pkgsCross.aarch64-multiplatform.OVMF.fd
          ];

          extraPackages = with pkgs; [
            python.pkgs.python-lsp-server
            ansible-language-server
            rubyPackages.solargraph
            nodePackages.intelephense
            phpPackages.phpstan
          ];

          shellHook = ''
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
        in
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          devShells.default = pkgs.mkShell {
            inherit shellHook;
            packages = minimalPackages ++ extraPackages;
          };

          devShells.minimal = pkgs.mkShell {
            inherit shellHook;
            packages = minimalPackages;
          };
        };
    };
}
