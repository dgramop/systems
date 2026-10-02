{config, lib, pkgs, ...}:
let
  stateDir = "/var/lib/passcs";
  photoDir = "${stateDir}/tutor_images";

  # Non-secret half of the old /home/passcs/Rocket.toml. `secret_key` and
  # `token_signing_key` are deliberately absent: Rocket picks them up from
  # ROCKET_SECRET_KEY / ROCKET_TOKEN_SIGNING_KEY in the environment file.
  rocketToml = pkgs.writeText "Rocket.toml" ''
    [default]
    extra = false
    ident = "passCS Webserver"

    onetime_prices_cents = [0, 5100, 4700]
    subscription_prices_cents = [0, 4700, 4300]

    offset_period_secs = 18000
    cookie_token_life_secs = 2678400
    email_token_life_secs = 500000

    tutor_photo_path = "${photoDir}/"

    [release]
    address = "127.0.0.1"
    port = 8000
    workers = 12
    keep_alive = 5
    log_level = "normal"
    subscription_price_ids = ["", "price_1KUgRJABGmiERRLGw4VOiUrv", "price_1KUgRfABGmiERRLGpFK982L4"]
    semester_end = 1777867200
  '';

  commonService = {
    # postgresql-setup is what actually creates the passcs database and role,
    # so ordering on postgresql.service alone would still race it.
    after = [ "network.target" "postgresql-setup.service" ];
    wants = [ "postgresql-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      ROCKET_CONFIG = "${rocketToml}";
      ROCKET_PROFILE = "release";
    };
    serviceConfig = {
      Type = "simple";
      User = "passcs";
      Group = "passcs";
      WorkingDirectory = stateDir;
      EnvironmentFile = "${stateDir}/env";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
in
{
  options = {
    services.dgramop-passcs.enable = lib.mkEnableOption "the passCS tutoring web app";

    services.dgramop-passcs.enableCron = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run the billing/notification loop. It creates real Stripe charges and
        sends real SMS and email, so the credentials in ${stateDir}/env decide
        whether it can actually reach anyone.
      '';
    };
  };

  config = lib.mkIf config.services.dgramop-passcs.enable {
    security.acme.defaults.email = "dgramopadhye@gmail.com";
    security.acme.acceptTerms = true;

    services.nginx.enable = true;
    services.nginx.virtualHosts."passcs.io" = {
      enableACME = true;
      forceSSL = true;
      serverAliases = [ "www.passcs.io" "jobs.passcs.io" ];

      root = "${pkgs.dgramop.passcs_frontend}";

      locations."/" = {
        tryFiles = "$uri /index.html";
        index = "index.html";
      };

      # The trailing slash strips the /api prefix before proxying, which is what
      # the routes in the backend expect.
      locations."/api" = {
        proxyPass = "http://127.0.0.1:8000/";
      };

      # Tutors upload their own photos, so this cannot be served out of the
      # read-only frontend store path that backs `root`.
      locations."/tutor_images/" = {
        alias = "${photoDir}/";
      };
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "passcs" ];
      ensureUsers = [{
        name = "passcs";
        ensureDBOwnership = true;
      }];
    };

    systemd.tmpfiles.rules = [
      # Root-owned so the passcs user cannot tamper with the environment file
      # that systemd reads out of here.
      "d ${stateDir} 0755 root root -"
      # Seeds the photos committed to the frontend repo on first boot; later
      # uploads accumulate here and are never overwritten.
      "C ${photoDir} 0755 passcs passcs - ${pkgs.dgramop.passcs_frontend}/tutor_images"
    ];

    systemd.services.passcs_backend = lib.mkMerge [ commonService {
      description = "The passCS Backend";
      serviceConfig.ExecStart = "${pkgs.dgramop.passcs_backend}/bin/main";
    }];

    systemd.services.passcs_cron = lib.mkMerge [ commonService {
      description = "passCS Cron Scheduler";
      enable = config.services.dgramop-passcs.enableCron;
      serviceConfig.ExecStart = "${pkgs.dgramop.passcs_backend}/bin/cron";
    }];

    users.users.passcs = {
      isSystemUser = true;
      group = "passcs";
      home = stateDir;
    };
    users.groups.passcs = {};
  };
}
