{ config, lib, pkgs, ... }:

# Makes Tailscale SSH open a real PAM session. tailscaled tries `login`, then
# `su`, then falls back to a PAM-less in-process shell with no XDG_RUNTIME_DIR,
# no logind session and a broken `systemctl --user`. On NixOS the `su` path can
# never work: the control plane grants node attr `ssh-behavior-v1` (so tailscaled
# refuses su outright), and NixOS ships shadow's `su`, which lacks the
# `-w/--whitelist-environment` that tailscaled probes for. That leaves `login`.

{
  config = lib.mkIf config.services.tailscale.enable {
    # `extraUpFlags` is ignored unless authKeyFile is set, so `tailscale set` is
    # the only declarative way to keep Tailscale SSH on across a re-auth.
    services.tailscale.extraSetFlags = [ "--ssh" ];

    # The upstream tailscaled unit's PATH has no `login`.
    systemd.services.tailscaled.path = [ pkgs.shadow ];

    # tailscaled passes `login -h <ip>`, and shadow's login then uses the PAM
    # service "remote" instead of "login". NixOS ships no /etc/pam.d/remote, so
    # this fell through to the deny-all `other` stack and login died with
    # "Authentication failure". Mirrors the flags nixpkgs sets on `login`.
    # Only reachable via root-invoked `login`, which is not setuid here.
    security.pam.services.remote = {
      allowNullPassword = true;
      setLoginUid = true;
      showMotd = true;
      startSession = true;
      updateWtmp = true;
    };
  };
}
