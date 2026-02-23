echo "assuming we already have disk-config copied over somehow";
echo "scp disk-config.nix root@<ovh ip>:"

# Finally copy over disk-config and use disko to partition
nix-channel --update;
nix-shell -p disko;
disko --mode disko nixos/machines/servers/dgramop-ovh/disk-config.nix

nixos-generate-config --root /mnt

# TODO: actually copy stuff around
# Add disko module to configuraiton nix
# Add disk-config to configuration nix
# Add   boot.swraid.enable = true; to configuration.nix

# make sure to import both disk-config.nix, then copy hardware-configuration.nix back over and switch to flakified version
nixos-install;
eboot
