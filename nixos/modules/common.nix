{config, lib, pkgs, ...}:
{
  options = {
    dgramop.common.enable = lib.mkEnableOption "Enable common CLI tools";
  };

  config = lib.mkIf config.dgramop.common.enable {
    nix.settings.trusted-users = [ "root" "dgramop" ];

    environment.systemPackages = with pkgs; [
      # Version control
      git
      gh

      # Editor
      helix

      # Directory listing
      tree
      eza

      # Process monitoring
      htop
      btop

      # Search
      ripgrep

      # JSON
      jq

      # HTTP
      wget
      curl

      # Terminal
      tmux

      # File utilities
      file
      ncdu

      # Git diff viewer
      delta

      # Network
      nmap
    ];

    # Shell
    programs.fish.enable = true;
    environment.shells = [ pkgs.fish ];
  };
}
