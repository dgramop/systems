{ pkgs, self, ... }:

{
  # Use Determinate Systems nix — don't let nix-darwin manage nix.conf
  nix.enable = false;

  # Declaratively manage nix.custom.conf (included by Determinate's nix.conf)
  # This nixifies the out-of-band builder config from /etc/nix/nix.custom.conf
  environment.etc."nix/nix.custom.conf".text = ''
    trusted-users = dgramop
    builders = ssh-ng://dgramop@orin aarch64-linux - 6 1 big-parallel; ssh-ng://dgramop@nuc x86_64-linux - 8 1 big-parallel; ssh-ng://builder@linux-builder aarch64-linux /etc/nix/builder_ed25519 8 2 - - c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpCV2N4Yi9CbGFxdDFhdU90RStGOFFVV3JVb3RpQzVxQkorVXVFV2RWQ2Igcm9vdEBuaXhvcwo=
    builders-use-substitutes = true
  '';

  environment.systemPackages = [
    pkgs.vim
    pkgs.home-manager
  ];

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
