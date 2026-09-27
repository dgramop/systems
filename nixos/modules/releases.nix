{config, lib, pkgs, ...}:
{
  options = {
    services.dgramop-releases.enable = lib.mkEnableOption "Serve /nix/var/nix/gcroots/dgramop-releases at releases.dhruv.now";
  };

  config = lib.mkIf config.services.dgramop-releases.enable {
    security.acme.defaults.email = "dgramopadhye@gmail.com";
    security.acme.acceptTerms = true;
    services.nginx.enable = true;
    services.nginx.virtualHosts."releases.dhruv.now" = {
      enableACME = true;
      forceSSL = true;

      # Resolves through the gcroot symlink into the linkFarm derivation
      # in /nix/store. Whatever push-releases most recently pinned is what
      # gets served.
      root = "/nix/var/nix/gcroots/dgramop-releases";

      locations."/" = {
        extraConfig = ''
          autoindex on;
          autoindex_exact_size off;
          autoindex_localtime on;
        '';
      };
    };
  };
}
