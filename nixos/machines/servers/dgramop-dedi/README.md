
# dgramop-dedi (Nocix)

- Samsung SSD 870 EVO 1TB (`/dev/sda`)
- Dual Intel Xeon L5640 (24 threads), 64GB RAM
- Legacy BIOS boot (GRUB, not systemd-boot)
- Static IP: 142.54.183.106/29, gw 142.54.183.105
- NIC: enp5s0f1

## Deploy with nixos-anywhere

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake '.#servers.dgramop-dedi' \
  root@142.54.183.106
```

This will kexec into the NixOS installer, partition with disko, and install.

## Post-install

After reboot, verify SSH access:
```bash
ssh root@142.54.183.106
```
