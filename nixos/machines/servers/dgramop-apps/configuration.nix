{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ./secrets.nix
    ./cad.nix
    ./ci.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.device = "nodev";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "dgramop-apps";
  time.timeZone = "America/New_York";

  services.nginx = {
    enable = true;
    virtualHosts."apps.dgramop.xyz" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/apps";
    };
  };

  security.acme.acceptTerms = true;
  security.acme.certs = {
    "apps.dgramop.xyz".email = "dgramopadhye@gmail.com";
    "ci.apps.dgramop.xyz".email = "dgramopadhye@gmail.com";
    "secrets.apps.dgramop.xyz".email = "dgramopadhye@gmail.com";
    "cad.apps.dgramop.xyz".email = "dgramopadhye@gmail.com";
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  
  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 16*1024;
  } ];

  environment.systemPackages = with pkgs; [
    vim
    wget
    neovim
    git
    htop
    vault-bin
    ncdu
    fish
    curl
    htop
    python3
    wireguard-tools
    tree
    ripgrep
    file
  ];
  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;
  
  virtualisation.docker.enable = true;

  users.mutableUsers = false;

  users.users.dgramop = {
    isNormalUser = true;
    group = "dgramop";
    extraGroups = [ "docker" "wheel" ];
    home = "/home/dgramop";
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCljmP0GXaGu97J/vOE5kvlKZt262sqx2ADiN0Glt5dMjiP4ubQLmC4vUr4rajV/n1JcTJzp12LSNmIVUQKLZgxLpwKhk7W7EAElT2rCMj6Yr1c2P5B34nGCyDYPjMWahupkZafLHze9zWxtkH+fHicH4GtOXMW4R9nZycwqtefAUsWBSbG023rYgzO9lUz8ZPb846CgwxWdtDoOdf15O58IrRfrWF3QKzWErli3OZ5K4cu70D55xCyGG9+Gpozf1u0kTF80jCb24TNr2CELEo8rqVXmJeVqA5LO1g5putLzzeTt8XL6tBjT2Wu0eQAAVOODee51QXCQ8dM29HaT7rbodeWEBrfAIY0V8FsjGQSpQv0VmcDzTyQH7Se29Pd6kPYP8M3VjPoTK+RMHSOdgTPY7iAgUo5c5qhs4DA3vXI+CgaEopL3AiKOtycYOhkMB/HGcQZiZ126BCRlr7exeM7d5/XQsNjhuLjyAnOxsWNA8DI0IvmRflakka2gVqEYRk= dgramop@Dhruvs-MacBook-Pro.local" ];
    hashedPassword = "$6$I2k9xk.FO/.$XNMVz6QTsXVfQF9Z/obAPhs3oehO3iBOeq2uaJBLwWGxUM3CoJeHuIi3RLQ3Es5ah.woTj2DnzcUiJ7gAHQxc1";
  };

  users.users.troy = {
    shell = pkgs.fish;
    isNormalUser = true;
    group = "troy";
    extraGroups = [ "docker" "wheel" ];
    home = "/home/troy";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOleNd3KStS0Heft6hWM2sxQLpUr0h7yWllS7IUE9Fiu troyneubauer@gmail.com" ];
    hashedPassword = "$6$7YTn8KjBF0xd3ASN$5YtxQ.bzJ1jFnZXF4sDfGMTsj4AG2JvvKf/RBGGBD3HSK1lrjtgXnrBVvSZouJNHngXat125I5y/2FtF1yGrj/";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}

