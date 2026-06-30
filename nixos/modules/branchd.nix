{ config, lib, pkgs, ... }:

let
  cfg = config.dgramop.branchd;
in {
  options.dgramop.branchd = {
    enable = lib.mkEnableOption "branchd — local web UI showing jj-spr PR stacks";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.dgramop.branchd;
      defaultText = lib.literalExpression "pkgs.dgramop.branchd";
      description = "The branchd package (from the overlay by default).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = ''
        Linux user the daemon runs as. Must own the workspaces / source
        clones and have working `jj` + `gh` auth in their HOME — branchd
        shells out to both.
      '';
      example = "dgramop";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Linux group the daemon runs as.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 80;
      description = ''
        Port to listen on. Privileged (<1024) ports require
        `CAP_NET_BIND_SERVICE` — the systemd unit grants this.
      '';
    };

    bind = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Bind addresses. Empty list = branchd default (tailscale0 IP + 127.0.0.1).
        Each address gets its own listener. Do NOT add 0.0.0.0 — branchd
        surfaces in-progress code and PR titles.
      '';
      example = [ "100.64.0.1" "127.0.0.1" ];
    };

    root = lib.mkOption {
      type = lib.types.str;
      description = "Root directory holding `branch.toml` workspaces (typically `~/trees`).";
      example = "/home/dgramop/trees";
    };

    sources = lib.mkOption {
      type = lib.types.str;
      description = "Root directory holding `<namespace>/<repo>` source clones.";
      example = "/home/dgramop/sources";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = ''
        Extra packages on the daemon's PATH. Defaults already include `jj`,
        `gh`, and `tailscale`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.branchd = {
      description = "branchd — jj-spr PR stack viewer";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "tailscaled.service" ];
      wants = [ "network-online.target" ];

      # PATH for the `jj`, `gh`, `tailscale` subprocess invocations.
      path = [ pkgs.jujutsu pkgs.gh pkgs.tailscale ] ++ cfg.extraPackages;

      # `gh` needs HOME to find its config + auth tokens.
      environment = {
        HOME = config.users.users.${cfg.user}.home;
      };

      serviceConfig = {
        ExecStart = lib.concatStringsSep " " ([
          "${cfg.package}/bin/branchd"
          "--root ${lib.escapeShellArg cfg.root}"
          "--sources ${lib.escapeShellArg cfg.sources}"
          "--port ${toString cfg.port}"
        ] ++ (map (b: "--bind ${lib.escapeShellArg b}") cfg.bind));

        User = cfg.user;
        Group = cfg.group;

        Type = "simple";
        Restart = "on-failure";
        RestartSec = "5s";

        # Privileged-port binding (port 80) without giving the whole process
        # root. Capability is bounded; child processes (jj, gh) don't inherit.
        AmbientCapabilities = lib.mkIf (cfg.port < 1024) [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = lib.mkIf (cfg.port < 1024) [ "CAP_NET_BIND_SERVICE" ];

        # Hardening. We don't ProtectHome — `gh` may refresh OAuth tokens
        # into ~/.config/gh and `jj` reads ~/.jjconfig.toml, both of which
        # need to remain accessible.
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        LockPersonality = true;
      };
    };
  };
}
