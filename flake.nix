{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager?ref=release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    checker_backend.url = "github:dgramop/checker_backend";
    checker_backend.inputs.nixpkgs.follows = "nixpkgs";
    checker_frontend.url = "github:dgramop/checker_frontend";
    checker_frontend.inputs.nixpkgs.follows = "nixpkgs";

    dgramop_frontend.url = "github:dgramop/dgramop";
    dgramop_frontend.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {self, nixpkgs, nixpkgs-unstable, flake-utils, home-manager, checker_backend, checker_frontend, dgramop_frontend, disko}: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [self.overlays.default];
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
        ./nixos/machines/dev/specter/configuration.nix
      ];
    }; 

    nixosConfigurations."servers.dgramop-apps" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./nixos/machines/servers/dgramop-apps/configuration.nix
      ];
    };

    nixosConfigurations."servers.dgramop-ovh" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./nixos/machines/servers/dgramop-ovh/configuration.nix
      ];
    }; 

    overlays.default = (final: prev: {
      gnuradio = nixpkgs-unstable.legacyPackages.${prev.system}.gnuradio;
      dgramop = {
        inherit checker_backend checker_frontend dgramop_frontend;
      };
    });
  };
}
