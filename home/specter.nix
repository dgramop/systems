{pkgs, lib, config, ...}: {
  imports = [
    ./common.nix
  ];

  config = {
    home.username = "dgramop";
    home.homeDirectory = "/home/dgramop";
    common = {
      enable = true;
      email = "dhruv@specter.co";
      name = "Dhruv Gramopadhye";
      retina = false;
    };

    home.packages = with pkgs; [
      pkg-config
      marktext
      keymapp
      slack
      awscli2
      k9s
    ];

    home.file.".config/i3/config".text = import ./i3.conf.nix { alacritty = pkgs.alacritty; rofi = pkgs.rofi; };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      # HIL config, chill
      matchBlocks."brothernode-*" = {
        user = "root";
      };
      matchBlocks."192.168.10.*" = {
        extraOptions = {
          "StrictHostKeyChecking" = "no";
          "UserKnownHostsFile" = "/dev/null";
        };
      };
      matchBlocks."*.sitl" = {
        extraOptions = {
          "StrictHostKeyChecking" = "no";
          "UserKnownHostsFile" = "/dev/null";
        };
      };
    };
  };
}
