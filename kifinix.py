#!/usr/bin/env python

import argparse, os, sys

if "KIFINIX_ROOT" not in os.environ:
    sys.exit("kifinix ran outside of the development environment, aborting...")
    
kifinix_root = os.environ["KIFINIX_ROOT"]

parser = argparse.ArgumentParser()
command = parser.add_subparsers(dest="command")

init = command.add_parser("init")
init.add_argument("name")
init.add_argument("playbooks_directory")
init.add_argument("--legacy", action='store_true')

update = command.add_parser("update")
update.add_argument("name")

switch = command.add_parser("switch")
switch.add_argument("name")

delete = command.add_parser("delete")
delete.add_argument("name")

collections = [
    "community.general",
    "community.mysql",
    "community.postgresql",
    "community.docker",
    "ansible.posix",
]

args = parser.parse_args()
match args.command:
    case "init":
        profile_path = f"{kifinix_root}/.kifinix/profiles/{args.name}"
        playbooks_directory = os.path.abspath(args.playbooks_directory)

        os.system(f"mkdir {profile_path}")
        os.chdir(profile_path)

        os.system(f"ln -s {playbooks_directory} playbooks")

        template = "template_legacy" if args.legacy else "template"
        os.system(f"cp -r {kifinix_root}/.kifinix/{template}/* ./")

        for collection in collections:
            os.system(f"ansible-galaxy collection install {collection} -p . --force")

        os.system(f"./inventory.rb --hosts")

    case "switch":
        os.chdir(f"{kifinix_root}/env")
        os.system("vagrant halt")

        os.chdir(kifinix_root)
        profile_path = f"{kifinix_root}/.kifinix/profiles/{args.name}"
        os.system(f"rm -f {kifinix_root}/env")
        os.system(f"ln -s {profile_path} {kifinix_root}/env")

    case "delete":
        profile_path = f"{kifinix_root}/.kifinix/profiles/{args.name}"
        os.system(f"rm -rf {profile_path}")

    case _:
        parser.print_help()
