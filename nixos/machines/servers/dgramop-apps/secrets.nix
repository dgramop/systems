{ config, lib, pkgs, ... }:
{
  services.nginx.virtualHosts."secrets.apps.dgramop.xyz" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8200";
      proxyWebsockets = true; # needed if you need to use WebSocket
      extraConfig =
        # required when the target is also TLS server with multiple hosts
        "proxy_ssl_server_name on;" +
        # required when the server wants to use HTTP Authentication
        "proxy_pass_header Authorization;"
   m     ;
    };
  };

    
  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
    #dev = true;
    #devRootTokenID = "test";
    storageBackend = "file";
    storagePath = "/var/lib/vault";
    extraConfig = "ui = true";
  };
}
