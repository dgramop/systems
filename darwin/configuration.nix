{ pkgs, self, ... }:

{
  # Use Determinate Systems nix — don't let nix-darwin manage nix.conf
  nix.enable = false;

  # Declaratively manage nix.custom.conf (included by Determinate's nix.conf)
  # This nixifies the out-of-band builder config from /etc/nix/nix.custom.conf
  environment.etc."nix/nix.custom.conf".text = ''
    trusted-users = dgramop
    builders = ssh-ng://dgramop@asahi aarch64-linux /var/root/.ssh/id_ed25519 8 2 big-parallel; ssh-ng://dgramop@nuc x86_64-linux /var/root/.ssh/id_ed25519 8 1 big-parallel;
    # Determinate Nix 3.6 build-remote hook silently postpones dispatch when this is on
    # (spent a long afternoon on it — leave off unless you re-verify).
    builders-use-substitutes = false
  '';

  environment.systemPackages = [
    pkgs.vim
    pkgs.home-manager
  ];

  environment.etc."resolver/lan" = {
    text = ''
      nameserver 10.111.3.128
    '';
  };

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
