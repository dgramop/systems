{
  modulesPath,
  lib,
  pkgs,
  ...
} @ args:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    ../../../modules/checker.nix
    ../../../modules/frontpage.nix
  ];

  services.dgramop-checker.enable = true;
  services.dgramop-frontpage.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.swraid.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
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

  users.users.root.openssh.authorizedKeys.keys =
  [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCljmP0GXaGu97J/vOE5kvlKZt262sqx2ADiN0Glt5dMjiP4ubQLmC4vUr4rajV/n1JcTJzp12LSNmIVUQKLZgxLpwKhk7W7EAElT2rCMj6Yr1c2P5B34nGCyDYPjMWahupkZafLHze9zWxtkH+fHicH4GtOXMW4R9nZycwqtefAUsWBSbG023rYgzO9lUz8ZPb846CgwxWdtDoOdf15O58IrRfrWF3QKzWErli3OZ5K4cu70D55xCyGG9+Gpozf1u0kTF80jCb24TNr2CELEo8rqVXmJeVqA5LO1g5putLzzeTt8XL6tBjT2Wu0eQAAVOODee51QXCQ8dM29HaT7rbodeWEBrfAIY0V8FsjGQSpQv0VmcDzTyQH7Se29Pd6kPYP8M3VjPoTK+RMHSOdgTPY7iAgUo5c5qhs4DA3vXI+CgaEopL3AiKOtycYOhkMB/HGcQZiZ126BCRlr7exeM7d5/XQsNjhuLjyAnOxsWNA8DI0IvmRflakka2gVqEYRk="
  ]; 

  system.stateVersion = "25.11";
}
