{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager.url = "github:nix-community/home-manager?ref=release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {self, nixpkgs, nixpkgs-unstable, flake-utils, home-manager, ...}: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [(final: prev: {
        gnuradio = pkgs-unstable.gnuradio;
      })];
    };

    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    packages.homeConfigurations."mac" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ./home/mac.nix ];
    };

    packages.homeConfigurations."specter" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ./home/specter.nix ];
    };
  }) // {
    nixosConfigurations."dev.specter" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./nixos/machines/specter/configuration.nix
      ];
    }; 
  };
}
