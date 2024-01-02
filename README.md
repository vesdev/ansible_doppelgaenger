ansible_doppelgaenger
==========

Description
------------
fork of [ansible_doppelgaenger](https://github.com/libraries-fi/ansible_doppelgaenger).
kifi specific nix development environment for vagrant vms.
provides all packages necessary for developing and running local services (aside from virtualbox).

defined IPs that can also be written to /etc/hosts if needed. Requires the ansible inventory to be
in YAML format.

Usage
-------------

1. Install the nix package manager (or nixos)
2. add your ssh key to keys.sh on the repo root
  example:
  ```bash
    #!/usr/bin/env bash
    ssh-add ~/.ssh/<key>
  ```
  TODO: kifinix.py could possibly automate this in the future

2. Run ``nix develop``
3. Then init a profile with ``kifinix init <name> <playbooks_directory> (optional: --legacy)``
  You probably want --legacy if youre planning to use older debian versions.
  (you can create multiple profiles)
4. switch to the profile you created with ``kifinix switch <name>``
5. your active profile will be in env/ so just cd into it 
4. Configure ansible-vault password path (vault_password_file) in ansible.cfg.
  TODO: kifinix.py could also do this

TIP: on nixos you need to configure the network ranges
```nix
  environment.etc = {
    "vbox/networks.conf".text = ''
      * 10.0.0.0/8 192.168.0.0/16
      * 2001::/64
    '';
  }; 

```

Vagrant is ready to run, see a list of configured boxes
with `vagrant status`. IPs will be assigned on first run (in ip_mapping.json).
