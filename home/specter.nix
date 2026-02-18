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
    };
  };
}
