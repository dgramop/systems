{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=25.11";
  };

  outputs = {self, nixpkgs}: {
    nixosConfigurations."specter-dgramop-nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./nixos/machines/specter/configuration.nix
      ];
    }; 
  };
}
