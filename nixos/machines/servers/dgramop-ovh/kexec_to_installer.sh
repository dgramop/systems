echo "assuming we mounted and booted into a debian rescue installer in OVH, and have ssh keys setup"

# Then, kexec nixos installer
curl -L https://github.com/nix-community/nixos-images/releases/download/nixos-25.11/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz | tar -xzf- -C /root
./kexec/run

