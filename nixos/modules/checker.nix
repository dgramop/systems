{config, lib, pkgs, ...}:
{
  options = {
    services.dgramop-checker.enable = lib.mkEnableOption "Enable the MIX check-in web app";
  };

  # TODO: Rocket.toml, and stubs for secrets.toml

  config = lib.mkIf config.services.dgramop-checker.enable {
    security.acme.defaults.email = "dgramopadhye@gmail.com";
    security.acme.acceptTerms = true;
    services.nginx.enable = true;
    services.nginx.virtualHosts."mix.dgramop.xyz" = {
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
      description = "MIX Checker Backend";
      enable = true;
      serviceConfig = {
        User = "checker";
        Group = "checker";
        ExecStart = "${pkgs.dgramop.checker_backend}/bin/checker";
        WorkingDirectory = "/etc/dgramop/checker";
      };
      environment = {
        ROCKET_ENV="prod";
        ROCKET_ADDRESS="127.0.0.1";
        ROCKET_LOG="critical";
        ROCKET_PORT="8001";
      };
    };

    users.users.checker = {
      isSystemUser = true;
      group = "checker";
      home = "/etc/dgramop/checker";
      createHome = true;
    };
    users.groups.checker = {};
    
  };
}

