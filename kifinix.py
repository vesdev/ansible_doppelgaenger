#!/usr/bin/env python

import argparse, os

parser = argparse.ArgumentParser()
command = parser.add_subparsers(dest="command")

init = command.add_parser("init")
init.add_argument("playbooks_directory")

clean = command.add_parser("clean")

args = parser.parse_args()
match args.command:
    case "init":
        ansible_collections = [
            "community.general",
            "community.mysql",
            "community.postgresql",
            "community.docker",
            "ansible.posix",
        ]

        os.system(f"ln -s {args.playbooks_directory} playbooks")
        for collection in ansible_collections:
            os.system(f"ansible-galaxy collection install {collection} --force")

        os.system("./inventory.rb --hosts")

    case "clean":
        os.system(sh, "echo Cleaning up...")
        os.system("vagrant destroy -f")
        # NOTE: only use rm incase playbooks is a directory
        # instead of a symlink, so it wont remove the directory
        os.system("rm playbooks")
        os.system("rm -f ip_mapping.json")
        os.system("rm -f hosts.base")
        os.system("rm -rf shared")
        os.system("rm -rf .vagrant")
        os.system("rm -rf .vagrant.d")
        os.system("rm ansible.log")

    case _:
        parser.print_help()
