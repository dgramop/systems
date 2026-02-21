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
    ];

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      # HIL config, chill
      matchBlocks."brothernode-*" = {
        user = "root";
      };
      matchBlocks."192.168.10.*" = {
        strictHostKeyChecking = "no";
        userKnownHostsFile = "/dev/null";
      };
      matchBlocks."*.sitl" = {
        strictHostKeyChecking = "no";
        userKnownHostsFile = "/dev/null";
      };
    };
  };
}
