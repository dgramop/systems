{ lib, pkgs, ... }:
let
  key = builtins.readFile ../../../keys/dgramop.pub;

  publicAddress = "142.54.183.107";
  privateAddress = "10.100.0.2";
  privateGateway = "10.100.0.1";
  mac = "02:00:00:00:a1:01";

  novncPort = 6080;
  vncPort = 5900;
in
{
  imports = [
    ../../../modules/common.nix
    ../../../modules/desktop.nix
  ];

  dgramop.common.enable = true;

  # Tailnet identity. The MicroVM is still "vm1" on the host side: unit
  # microvm@vm1, state in /var/lib/microvms/vm1, tap vm-vm1.
  networking.hostName = "agent-vm-dedi";

  microvm = {
    hypervisor = "qemu";
    vcpu = 4;
    mem = 8192;

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

    # microvm.nix defaults / to a tmpfs (stateless guests); this overrides that
    # mkDefault so the whole guest survives a restart rather than just /home
    # and /var.
    volumes = [
      {
        image = "/var/lib/microvms/vm1/root.img";
        mountPoint = "/";
        label = "vm1-root";
        size = 32768;
      }
      {
        image = "/var/lib/microvms/vm1/var.img";
        mountPoint = "/var";
        label = "vm1-var";
        size = 8192;
      }
      {
        image = "/var/lib/microvms/vm1/home.img";
        mountPoint = "/home";
        label = "vm1-home";
        size = 131072;
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

  # Bound wildcard rather than per-address: the tailnet address is not known at
  # build time, and ListenAddress would exclude it. Which interface may reach
  # which port is decided by the firewall below instead.
  services.openssh = {
    enable = true;
    ports = [ 22 443 ];
    # Would otherwise open every listed port on every interface, putting 22
    # back on the public address.
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # 443 everywhere (public + host link); 22 only over the tailnet, so the
  # public address does not answer on the port that gets scanned.
  networking.firewall.allowedTCPPorts = [ 443 ];

  services.tailscale = {
    enable = true;
    # extraUpFlags is silently ignored unless authKeyFile is set; extraSetFlags
    # runs `tailscale set` on each start, so --ssh stays on declaratively.
    extraSetFlags = [ "--ssh" ];
  };

  # tailscaled opens a PAM session by exec'ing `login`, which is absent from
  # the unit's default PATH on NixOS. Without it sessions fall back to a
  # PAM-less in-process shell with no XDG_RUNTIME_DIR or logind session.
  systemd.services.tailscaled.path = [ pkgs.shadow ];

  dgramop.desktop.enable = true;

  # Nothing to print to on a headless guest, and this box faces the public
  # internet.
  services.printing.enable = lib.mkForce false;

  # There is no GPU, so X drives a dummy framebuffer that x11vnc can scrape.
  # The dummy driver needs an explicit modeline or it comes up tiny.
  services.xserver = {
    videoDrivers = [ "dummy" ];
    deviceSection = ''
      VideoRam 256000
    '';
    monitorSection = ''
      HorizSync 1.0 - 200.0
      VertRefresh 1.0 - 200.0
      Modeline "1920x1080" 172.80 1920 2040 2248 2576 1080 1081 1084 1118
    '';
    screenSection = ''
      DefaultDepth 24
      SubSection "Display"
        Depth 24
        Modes "1920x1080"
      EndSubSection
    '';
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "dgramop";
  };

  # x11vnc stays on loopback; noVNC is the only thing that reaches it, and it
  # binds the tailnet address exclusively.
  systemd.services.x11vnc = {
    description = "VNC server for the autologin X session";
    after = [ "display-manager.service" ];
    requires = [ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :0 -auth guess -rfbport ${toString vncPort} -localhost -forever -shared -noxdamage -nopw";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  systemd.services.novnc = {
    description = "noVNC web front-end, bound to the tailnet address only";
    after = [ "tailscaled.service" "x11vnc.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.iproute2 pkgs.gawk ];
    serviceConfig = {
      # tailscale0 does not exist until the node is authenticated, so the unit
      # restarts until the address shows up rather than binding a wildcard.
      ExecStart = pkgs.writeShellScript "novnc-tailscale-only" ''
        set -eu
        addr=$(ip -4 -o addr show tailscale0 | awk '{split($4,a,"/"); print a[1]; exit}')
        if [ -z "$addr" ]; then
          echo "tailscale0 has no IPv4 address yet" >&2
          exit 1
        fi
        exec ${pkgs.python3Packages.websockify}/bin/websockify \
          --web=${pkgs.novnc}/share/webapps/novnc \
          "$addr:${toString novncPort}" "127.0.0.1:${toString vncPort}"
      '';
      Restart = "always";
      RestartSec = 10;
      DynamicUser = true;
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 novncPort ];

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
