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

    branch.url = "github:dgramop-specter/branch";
    branch.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {self, nixpkgs, nixpkgs-unstable, flake-utils, home-manager, checker_backend, checker_frontend, dgramop_frontend, disko, branch}: flake-utils.lib.eachDefaultSystem (system: let
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

    packages.homeConfigurations."specter-headless" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ./home/specter-headless.nix ];
    };

    packages.homeConfigurations."generic-linux" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ./home/generic-linux.nix ];
    };
  }) // (let
    overlayer = {...}: { nixpkgs.overlays = [self.overlays.default]; };
  in {
    nixosConfigurations."dev.specter" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        overlayer
        ./nixos/machines/dev/specter/configuration.nix
      ];
    }; 

    nixosConfigurations."servers.dgramop-apps" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        overlayer
        ./nixos/machines/servers/dgramop-apps/configuration.nix
      ];
    };

    nixosConfigurations."servers.dgramop-ovh" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        overlayer
        disko.nixosModules.disko
        ./nixos/machines/servers/dgramop-ovh/configuration.nix
      ];
    }; 

    overlays.default = (final: prev: {
      gnuradio = nixpkgs-unstable.legacyPackages.${prev.system}.gnuradio;
      dgramop = {
        checker_frontend = checker_frontend.outputs.packages.${prev.system}.default;
        checker_backend = checker_backend.outputs.packages.${prev.system}.default;
        dgramop_frontend = dgramop_frontend.outputs.packages.${prev.system}.default;
        branch = branch.outputs.defaultPackage.${prev.system};
      };
    });
  });
}
