{
  modulesPath,
  lib,
  pkgs,
  ...
} @ args:
let
 key = builtins.readFile ../../../keys/dgramop.pub;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    ../../../modules/common.nix
    ../../../modules/checker.nix
    ../../../modules/frontpage.nix
    ../../../modules/releases.nix
    ../../../modules/passcs.nix
    ../../../modules/null-black
  ];

  dgramop.common.enable = true;
  services.dgramop-checker.enable = true;
  services.dgramop-passcs.enable = true;
  services.dgramop-frontpage.enable = true;
  services.dgramop-releases.enable = true;
  services.null-black.enable = true;

  boot.loader.grub.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "dgramop" ];

  # Nocix /29 block: 142.54.183.104/29
  # .104 network, .105 gateway, .106 primary, .107-.110 usable, .111 broadcast
  networking.useDHCP = false;
  networking.useNetworkd = true;
  networking.nameservers = [ "192.187.107.16" "69.30.209.16" ];

  systemd.network.networks."10-wan" = {
    matchConfig.Name = "enp5s0f1";
    address = [
      "142.54.183.106/29"
    ];
    routes = [
      { Gateway = "142.54.183.105"; }
    ];
    # The upstream switch only learns this host's MAC, so guest addresses from
    # the /29 are routed through the host rather than bridged; the host has to
    # answer the gateway's ARP for them.
    networkConfig.IPv4ProxyARP = true;
    linkConfig.RequiredForOnline = "routable";
  };

  # Second port — not connected, keep down
  systemd.network.networks."20-unused" = {
    matchConfig.Name = "enp5s0f0";
    linkConfig.RequiredForOnline = "no";
  };

  systemd.network.config.networkConfig.IPv4Forwarding = true;

  systemd.network.netdevs."br-vm".netdevConfig = {
    Name = "br-vm";
    Kind = "bridge";
  };

  # Private host<->guest link, and the routes that carry each guest's public
  # address over it.
  systemd.network.networks."30-br-vm" = {
    matchConfig.Name = "br-vm";
    address = [ "10.100.0.1/24" ];
    routes = [
      { Destination = "142.54.183.107/32"; Gateway = "10.100.0.2"; }
    ];
    linkConfig.RequiredForOnline = "no";
  };

  systemd.network.networks."40-vm-taps" = {
    matchConfig.Name = "vm-*";
    networkConfig.Bridge = "br-vm";
    linkConfig.RequiredForOnline = "no";
  };

  microvm.host.enable = true;
  microvm.vms.vm1.config = import ../../vms/vm1/configuration.nix;

  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  environment.systemPackages = [
    pkgs.home-manager
  ];

  users.users.dgramop = {
    isNormalUser = true;
    createHome = true;
    group = "users";
    extraGroups = [
      "wheel"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [ key ];
  users.users.dgramop.openssh.authorizedKeys.keys = [ key ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  system.stateVersion = "25.11";
}
