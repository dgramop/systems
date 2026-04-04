{config, lib, pkgs, ...}:
let
  staticFiles = pkgs.stdenv.mkDerivation {
    name = "null-black-static";
    src = ./.;
    installPhase = ''
      mkdir -p $out
      cp index.html $out/
      cp nullwhite.png $out/
    '';
  };
in
{
  options = {
    services.null-black.enable = lib.mkEnableOption "Enable null.black sunset page";
  };

  config = lib.mkIf config.services.null-black.enable {
    security.acme.defaults.email = "dgramopadhye@gmail.com";
    security.acme.acceptTerms = true;

    services.nginx.enable = true;
    services.nginx.virtualHosts."null.black" = {
      enableACME = true;
      forceSSL = true;
      root = "${staticFiles}";
      locations."/" = {
        index = "index.html";
      };
    };
  };
}
