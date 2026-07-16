{ config, lib, pkgs, ... }:

let
  cfg = config.dgramop.builder-resolve;

  script = pkgs.writeShellScriptBin "builder-resolve" ''
    set -u

    probe() {
      if /sbin/ping -c 1 -t 1 -q "$1" >/dev/null 2>&1; then
        printf '%s' "$1"
      else
        printf '%s' "$2"
      fi
    }

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: h:
      "ip_${name}=$(probe ${h.primary} ${h.fallback})"
    ) cfg.hosts)}

    tmp=$(mktemp)
    {
      printf '##\n# Host Database\n#\n# localhost is used to configure the loopback interface\n# when the system is booting.  Do not change this entry.\n##\n'
      printf '127.0.0.1\tlocalhost\n'
      printf '255.255.255.255\tbroadcasthost\n'
      printf '::1             localhost\n'
      printf '\n'
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: _:
      ''  printf '%s\t${name}\n' "$ip_${name}"''
    ) cfg.hosts)}
    } > "$tmp"

    if ! cmp -s "$tmp" /etc/hosts; then
      # mktemp defaults to 0600; /etc/hosts must be world-readable
      # so mDNSResponder (runs as _mdnsresponder) can consult it.
      chmod 0644 "$tmp"
      mv "$tmp" /etc/hosts
      /usr/bin/dscacheutil -flushcache
      /usr/bin/killall -HUP mDNSResponder 2>/dev/null || true
    else
      rm "$tmp"
    fi
  '';
in {
  options.dgramop.builder-resolve = {
    enable = lib.mkEnableOption "dynamic nix-builder hostname resolution (wired LAN with WiFi fallback)";

    hosts = lib.mkOption {
      description = "Map of hostname -> { primary, fallback } IPs. The daemon rewrites /etc/hosts with whichever address is reachable.";
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          primary  = lib.mkOption { type = lib.types.str; description = "Preferred address (tried first)."; };
          fallback = lib.mkOption { type = lib.types.str; description = "Address used if primary does not respond to ping."; };
        };
      });
      default = {};
    };

    interval = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Probe interval in seconds.";
    };
  };

  config = lib.mkIf cfg.enable {
    launchd.daemons.builder-resolve = {
      serviceConfig = {
        ProgramArguments = [ "${script}/bin/builder-resolve" ];
        StartInterval = cfg.interval;
        RunAtLoad = true;
        StandardOutPath = "/var/log/builder-resolve.log";
        StandardErrorPath = "/var/log/builder-resolve.log";
      };
    };
  };
}
