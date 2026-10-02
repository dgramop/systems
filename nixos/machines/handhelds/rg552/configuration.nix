{ config, lib, pkgs, rg552-nixos, ... }:

{
  imports = [
    rg552-nixos.nixosModules.default
    ../../../modules/tailscale-ssh.nix
  ];

  networking.hostName = "rg552";

  # Run `tailscale up` once to register the node.
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  system.stateVersion = "25.05";
}
