{ lib, pkgs, ... }:
let
  key = builtins.readFile ../../../keys/dgramop.pub;

  publicAddress = "142.54.183.107";
  privateAddress = "10.100.0.2";
  privateGateway = "10.100.0.1";
  mac = "02:00:00:00:a1:01";
in
{
  imports = [
    ../../../modules/common.nix
  ];

  dgramop.common.enable = true;

  microvm = {
    hypervisor = "qemu";
    vcpu = 4;
    mem = 4096;

    interfaces = [
      {
        type = "tap";
        id = "vm-vm1";
        inherit mac;
      }
    ];

    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];

    volumes = [
      {
        image = "/var/lib/microvms/vm1/var.img";
        mountPoint = "/var";
        label = "vm1-var";
        size = 8192;
      }
    ];
  };

  # The public address is routed to us by the host rather than bridged, so the
  # default route's next hop is the host's private address.
  networking.useDHCP = false;
  networking.nameservers = [ "192.187.107.16" "69.30.209.16" ];

  systemd.network.networks."10-vm1" = {
    matchConfig.MACAddress = mac;
    address = [
      "${privateAddress}/24"
      "${publicAddress}/32"
    ];
    routes = [
      {
        Gateway = privateGateway;
        PreferredSource = publicAddress;
      }
    ];
    linkConfig.RequiredForOnline = "routable";
  };

  # systemd-networkd-wait-online is disabled in MicroVMs, so sshd can start
  # before its listen addresses exist.
  boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;

  services.openssh = {
    enable = true;
    listenAddresses = [
      { addr = publicAddress; port = 443; }
      { addr = privateAddress; port = 22; }
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 443 ];

  users.users.dgramop = {
    isNormalUser = true;
    createHome = true;
    group = "users";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ key ];
  };

  users.users.root.openssh.authorizedKeys.keys = [ key ];

  system.stateVersion = "25.11";
}
