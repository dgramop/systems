
# Setup

## In the console
- mount and booted into a debian rescue installer in OVH,
- and have ssh keys setup

## Then, kexec nixos installer on the server
Basically hot-reload the OS
```bash
curl -L https://github.com/nix-community/nixos-images/releases/download/nixos-25.11/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz | tar -xzf- -C /root
./kexec/run
```

## Finally copy over disk-config.nix/clone and use disko to partition
nix-channel --update;
nix-shell -p disko;
disko --mode disko nixos/machines/servers/dgramop-ovh/disk-config.nix

## Generate config
nixos-generate-config --root /mnt

At this point you should be able to nixos-install with a flake path to github?

Copy over configuration and hardware-configuration, OR
Make the following mods:
- Add disko module tarball to configuraiton nix
  ```
  "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
  ```
- Add disk-config to configuration nix
- Add `boot.swraid.enable = true;` to configuration.nix
- Remove disk config friom hardware-configuration, since disko is going to manage this

# make sure to import both disk-config.nix, then copy hardware-configuration.nix back over and switch to flakified version
```bash
nixos-install;
```

In the console, unmount the rescue system, then
```bash
reboot
```
