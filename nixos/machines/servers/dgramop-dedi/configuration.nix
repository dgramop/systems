{
  modulesPath,
  lib,
  pkgs,
  ...
} @ args:
let
 key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCljmP0GXaGu97J/vOE5kvlKZt262sqx2ADiN0Glt5dMjiP4ubQLmC4vUr4rajV/n1JcTJzp12LSNmIVUQKLZgxLpwKhk7W7EAElT2rCMj6Yr1c2P5B34nGCyDYPjMWahupkZafLHze9zWxtkH+fHicH4GtOXMW4R9nZycwqtefAUsWBSbG023rYgzO9lUz8ZPb846CgwxWdtDoOdf15O58IrRfrWF3QKzWErli3OZ5K4cu70D55xCyGG9+Gpozf1u0kTF80jCb24TNr2CELEo8rqVXmJeVqA5LO1g5putLzzeTt8XL6tBjT2Wu0eQAAVOODee51QXCQ8dM29HaT7rbodeWEBrfAIY0V8FsjGQSpQv0VmcDzTyQH7Se29Pd6kPYP8M3VjPoTK+RMHSOdgTPY7iAgUo5c5qhs4DA3vXI+CgaEopL3AiKOtycYOhkMB/HGcQZiZ126BCRlr7exeM7d5/XQsNjhuLjyAnOxsWNA8DI0IvmRflakka2gVqEYRk=";
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    ../../../modules/common.nix
    ../../../modules/checker.nix
    ../../../modules/frontpage.nix
    ../../../modules/null-black
  ];

  dgramop.common.enable = true;
  services.dgramop-checker.enable = true;
  services.dgramop-frontpage.enable = true;
  services.null-black.enable = true;

  boot.loader.grub.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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
    linkConfig.RequiredForOnline = "routable";
  };

  # Second port — not connected, keep down
  systemd.network.networks."20-unused" = {
    matchConfig.Name = "enp5s0f0";
    linkConfig.RequiredForOnline = "no";
  };

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
