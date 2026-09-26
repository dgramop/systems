{ config, lib, pkgs, rg552-nixos, ... }:

{
  imports = [
    rg552-nixos.nixosModules.default
  ];

  networking.hostName = "rg552";

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    # Run `tailscale up --ssh` once to register and enable Tailscale SSH.
    extraUpFlags = [ "--ssh" ];
  };

  system.stateVersion = "25.05";
}
