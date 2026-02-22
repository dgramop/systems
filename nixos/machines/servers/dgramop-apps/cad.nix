{config, lib, pkgs, ...}:
{
  services.nginx.virtualHosts."cad.apps.dgramop.xyz" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/solvespace";
    locations."/".index = "solvespace.html";
  };
}
