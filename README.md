ansible_doppelgaenger
==========

Description
------------
Fork of [ansible_doppelgaenger](https://github.com/libraries-fi/ansible_doppelgaenger).
Kifi specific nix development environment for vagrant vms.
Provides all packages necessary for developing and running local services (aside from virtualbox).

Usage
-------------

1. Install the nix package manager (or nixos)
2. add your ssh key to keys.sh on the repo root.
  example:
  ```bash
    #!/usr/bin/env bash
    ssh-add ~/.ssh/<key>
  ```
  TODO: kifinix.py could possibly automate this in the future

3. Run ``nix develop``
4. Then init a profile with ``kifinix init <name> <playbooks_directory> (optional: --legacy)``
  You probably want --legacy if you're planning to use older debian versions.
  (you can create multiple profiles)
5. switch to the profile you created with ``kifinix switch <name>``
6. your active profile will be in ./env/ so just cd into it 
7. Configure ansible-vault password path (vault_password_file) in ansible.cfg.
  TODO: kifinix.py could also be made to do this

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
