{config, lib, pkgs, ...}:
{
  options = {
    services.dgramop-frontpage.enable = lib.mkEnableOption "Enable personal website";
  };

  config = lib.mkIf config.services.dgramop-frontpage.enable {
    security.acme.defaults.email = "dgramopadhye@gmail.com";
    security.acme.acceptTerms = true;
    services.nginx.enable = true;
    services.nginx.virtualHosts."dgramop.xyz" = {
      # Enable SSL/TLS
      enableACME = true;
      forceSSL = true;
      serverAliases = ["dhruv.now" "www.dhruv.now" "www.dgramop.xyz"];

      # Document root
      root = "${pkgs.dgramop.dgramop_frontend}/www";

      # Locations configuration
      locations."/" = {
        # Serve files, fall back to index.html (SPA pattern)
        tryFiles = "$uri $uri/ /index.html";
        index = "index.html";
      };
    };

    services.nginx.virtualHosts."pay.dhruv.now" = {
      enableACME = true;
      forceSSL = true;
      locations."/".return = "302 https://account.venmo.com/u/dgramop";
    };
  };
}

