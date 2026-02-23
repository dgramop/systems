{pkgs, lib, config, ...}: {
  imports = [
    ./common.nix
  ];

  config = {
    home.username = "root";
    home.homeDirectory = "/root";
    common = {
      enable = true;
      email = "dgramopadhye@gmail.com";
      name = "Dhruv Gramopadhye";
      retina = false;
    };

    home.packages = with pkgs; [
      pkg-config
      marktext
    ];
  };
}
