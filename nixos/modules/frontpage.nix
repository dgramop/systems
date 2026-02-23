{config, lib, pkgs, ...}:
{
  options = {
    services.dgramop-frontpage.enable = lib.mkEnableOption "Enable personal website";
  };

  config = lib.mkIf config.services.dgramop-frontpage.enable {
    security.acme.acceptTerms = true;
    services.nginx.enable = true;
    services.nginx.virtualHosts."dgramop.apps.dgramop.xyz" = {
      # Enable SSL/TLS
      enableACME = true;
      forceSSL = true;
    
      # Document root
      root = "${pkgs.dgramop.dgramop_frontend}/www";
    
      # Locations configuration
      locations."/" = {
        # Serve files, fall back to index.html (SPA pattern)
        tryFiles = "$uri $uri/ /index.html";
        index = "index.html";
      };
    };
  };
}

