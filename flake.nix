{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";

    jetpack.url = "github:anduril/jetpack-nixos/master";
    jetpack.inputs.nixpkgs.follows = "nixpkgs";

    rg552-nixos.url = "github:dgramop/rg552-nixos";
    rg552-nixos.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager?ref=release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    checker_backend.url = "github:dgramop/checker_backend";
    checker_backend.inputs.nixpkgs.follows = "nixpkgs";
    checker_frontend.url = "github:dgramop/checker_frontend";
    checker_frontend.inputs.nixpkgs.follows = "nixpkgs";

    dgramop_frontend.url = "github:dgramop/dgramop";
    dgramop_frontend.inputs.nixpkgs.follows = "nixpkgs";

    # submodules=1 pulls in templates/raw_templates/new-passcs-frontend, which the
    # email template derivation reads from.
    passcs_backend.url = "github:dgramop/passcs-backend?submodules=1";
    passcs_backend.inputs.nixpkgs.follows = "nixpkgs";
    passcs_frontend.url = "github:dgramop/passcs-frontend";
    passcs_frontend.inputs.nixpkgs.follows = "nixpkgs";

    branch.url = "github:dgramop-specter/branch";
    branch.inputs.nixpkgs.follows = "nixpkgs";

    jj-spr.url = "github:jennings/jj-spr";
    jj-spr.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = {self, nixpkgs, nixpkgs-unstable, flake-utils, jetpack, home-manager, checker_backend, checker_frontend, dgramop_frontend, passcs_backend, passcs_frontend, disko, microvm, branch, nix-darwin, jj-spr, rg552-nixos}: flake-utils.lib.eachDefaultSystem (system: let
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

    packages.homeConfigurations."generic-linux" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./home/generic-linux.nix
        {
          home.username = "root";
          home.homeDirectory = "/root";
        }
      ];
    };

    packages.homeConfigurations."generic-linux-dgramop" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./home/generic-linux.nix
        {
          home.username = "dgramop";
          home.homeDirectory = "/home/dgramop";
        }
      ];
    };

  }) // (let
    overlayer = {...}: { nixpkgs.overlays = [self.overlays.default]; };
  in {
    nixosConfigurations.orin = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        overlayer
        jetpack.nixosModules.default
        ./nixos/machines/servers/orin/configuration.nix
      ];
    };

    nixosConfigurations.nuc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        overlayer
        ./nixos/machines/servers/nuc/configuration.nix
      ];
    };

    nixosConfigurations.rg552 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit rg552-nixos; };
      modules = [
        overlayer
        ./nixos/machines/handhelds/rg552/configuration.nix
      ];
    };

    # Same system as rg552, plus the image-packaging layer. The sd-image module
    # wants `uboot` as a specialArg, and it must be the x86_64 build because it
    # pulls in rkbin.
    nixosConfigurations.rg552-sdimage = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        inherit rg552-nixos;
        uboot = rg552-nixos.packages.x86_64-linux.uboot;
      };
      modules = [
        overlayer
        rg552-nixos.nixosModules.sd-image
        ./nixos/machines/handhelds/rg552/configuration.nix
      ];
    };

    nixosConfigurations.dgramop-dedi = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        overlayer
        disko.nixosModules.disko
        microvm.nixosModules.host
        ./nixos/machines/servers/dgramop-dedi/configuration.nix
      ];
    };

    darwinConfigurations."Dhruvs-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        ./darwin/configuration.nix
      ];
      specialArgs = { inherit self; };
    };

    overlays.default = (final: prev: {
      gnuradio = nixpkgs-unstable.legacyPackages.${prev.system}.gnuradio;
      jj_spr = jj-spr.outputs.packages.${prev.system}.default;
      dgramop = {
        checker_frontend = checker_frontend.outputs.packages.${prev.system}.default;
        checker_backend = checker_backend.outputs.packages.${prev.system}.default;
        dgramop_frontend = dgramop_frontend.outputs.packages.${prev.system}.default;
        passcs_backend = passcs_backend.outputs.packages.${prev.system}.default;
        passcs_frontend = passcs_frontend.outputs.packages.${prev.system}.default;
        branch = branch.outputs.defaultPackage.${prev.system};
        branchd = branch.outputs.packages.${prev.system}.branchd;
      };
    });
  });
}
