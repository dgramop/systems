# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/common.nix
    ../../../modules/desktop.nix
  ];

  dgramop.common.enable = true;
  dgramop.desktop.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  networking.hostName = "nuc"; # Define your hostname.
  networking.networkmanager.enable = true;
  # Let systemd-networkd own the LAN-side ethernet; NM keeps wifi.
  networking.networkmanager.unmanaged = [ "interface-name:enp86s0" ];

  systemd.network.enable = true;
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "enp86s0";
    address = [ "10.111.3.128/8" ];
    networkConfig = {
      IPv6AcceptRA = false;
      LinkLocalAddressing = "no";
    };
    linkConfig.RequiredForOnline = "no";
  };

  # NAT devices on the wired LAN out through the wifi uplink.
  networking.nat = {
    enable = true;
    externalInterface = "wlo1";
    internalInterfaces = [ "enp86s0" ];
  };
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_CA.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  users.users.dgramop = {
    isNormalUser = true;
    description = "Dhruv Gramopadhye";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nixpkgs.config.allowUnfree = true;

  programs.mtr.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.dnsmasq = {
    enable = true;
    settings = {
      listen-address = "127.0.0.1,10.111.3.128";
      bind-interfaces = true;

      server = [ "192.168.8.1" ];

      address = [
        "/nuc/10.111.3.128"
        "/asahi/10.111.3.114"
        "/orin/10.111.3.136"
      ];
    };
  };

  services.tailscale.enable = true;

  networking.firewall.allowedUDPPorts = [ 53 ];

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
