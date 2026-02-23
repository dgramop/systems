{config, lib, pkgs, ...}:
{
  options = {
    dgramop.enable = lib.mkEnableOption "Enable the MIX check-in web app";
  };

  config = lib.mkIf config.dgramop.enable {
    services.nginx.enable = true;
    services.nginx.virtualHosts."mix.apps.dgramop.xyz" = {
      # Enable SSL/TLS
      enableACME = true;
      forceSSL = true;
    
      # Document root
      root = "${pkgs.dgramop.checker_frontend}/www";
    
      # Locations configuration
      locations."/" = {
        # Serve files, fall back to index.html (SPA pattern)
        tryFiles = "$uri $uri/ /index.html";
        index = "index.html";
      };
    
      locations."/api" = {
        # Proxy API requests to backend
        proxyPass = "http://localhost:8001";
      };
    };

    systemd.services.checker = {
      name = "MIX Checker Backend";
      serviceConfig = {
        ExecStart = "${pkgs.dgramop.checker_backend}/bin/checker";
        WorkingDirectory = "/home/dgramop/checker";
      };
      environment = {
        ROCKET_ENV="prod";
        ROCKET_ADDRESS="127.0.0.1";
        ROCKET_LOG="critical";
        ROCKET_PORT=8001;
      };
    };
  };
}

