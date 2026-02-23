{pkgs, lib, config, ...}: {
  imports = [
    ./common.nix
  ];

  config = {
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
