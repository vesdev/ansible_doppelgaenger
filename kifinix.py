#!/usr/bin/env python

import argparse, os, sys, inspect

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

update_hosts = command.add_parser("update-hosts")

collections = [
    "community.general",
    "community.mysql",
    "community.postgresql",
    "community.docker",
    "ansible.posix",
]

def ansible_cfg(password_file, legacy):

    legacy_server = ''

    if legacy:
        legacy_server = """[galaxy]
    server = https://old-galaxy.ansible.com/"""

    return inspect.cleandoc(fr"""
    [defaults]
    inventory = {kifinix_root}/inventory.rb
    remote_user = root
    ansible_managed =  ansible managed - DO NOT MODIFY!
    collections_paths = ./ansible_collections
    roles_path = ./dev_roles:playbooks/kifi_ansible_roles:./playbooks/kifi_ansible_unmanaged_roles
    library = /opt/ansible-plugins/library
    filter_plugins = ./playbooks/filter_plugins
    timeout = 600
    vault_password_file = {password_file}

    stdout_callback=debug
    stderr_callback=debug

    [ssh_connection]
    pipelining = True
    ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o ControlPath=/tmp/ansible-ssh-%h-%p-%r -o ForwardAgent=yes
    {legacy_server}
    """)

def vagrantfile():
    return inspect.cleandoc(fr"""
    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    # Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
    VAGRANTFILE_API_VERSION = "2"

    require "{kifinix_root}/inventory"

    Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
      define_vagrant_vms config
      config.ssh.forward_agent = true
      config.ssh.insert_key = false
      # config.ssh.keys_only = false
      # Disable /vagrant folder syncing, it takes a lot of space on vm.
      config.vm.synced_folder ".", "/vagrant",
        disabled: true,
        id: "vagrant-root"
      config.vm.box = "debian/buster64"

      config.vm.provision "ansible" do |ansible|
        ansible.playbook = "playbooks/site.yml"
        ansible.inventory_path = "{kifinix_root}/inventory.rb"
        ansible.become = true
        ansible.skip_tags = ["production_only", "fail2ban"]
        ansible.host_key_checking = false
        ansible.raw_ssh_args = ["-o UserKnownHostsFile=/dev/null"]
        ansible.force_remote_user = false
        ansible.extra_vars = {{
          file_sync_no_controlhost: "True",
          # site_content_sync: "True",
        }}
      end
    end
    """)

args = parser.parse_args()
match args.command:
    case "init":
        profile_path = f"{kifinix_root}/.kifinix/{args.name}"
        playbooks_directory = os.path.abspath(args.playbooks_directory)

        os.system(f"mkdir {profile_path}")
        os.chdir(profile_path)

        os.system(f"ln -s {playbooks_directory} playbooks")

        cfg = str.encode(ansible_cfg("", args.legacy))
        fd = os.open(f"{profile_path}/ansible.cfg", os.O_CREAT | os.O_WRONLY)
        os.write(fd, cfg)
        os.close(fd)

        cfg = str.encode(vagrantfile())
        fd = os.open(f"{profile_path}/Vagrantfile", os.O_CREAT | os.O_WRONLY)
        os.write(fd, cfg)
        os.close(fd)

        for collection in collections:
            os.system(f"ansible-galaxy collection install {collection} -p . --force")

        os.system(f"{kifinix_root}/inventory.rb --hosts")

    case "update-hosts":
        profile_path = f"{kifinix_root}/env/"
        os.chdir(profile_path)
        os.system(f"{kifinix_root}/inventory.rb --hosts")

    case "switch":
        if os.path.exists(f"{kifinix_root}/env"):
            os.chdir(f"{kifinix_root}/env")
            os.system("vagrant halt")

            os.chdir(kifinix_root)
            os.remove(f"{kifinix_root}/env")

        profile_path = f"{kifinix_root}/.kifinix/{args.name}"
        os.system(f"ln -s {profile_path} {kifinix_root}/env")

    case "delete":
        profile_path = f"{kifinix_root}/.kifinix/{args.name}"
        os.system(f"rm -rf {profile_path}")

    case _:
        parser.print_help()
