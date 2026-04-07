{config, lib, pkgs, ...}:
{
  options = {
    dgramop.desktop.enable = lib.mkEnableOption "Enable i3wm desktop environment";
  };

  config = lib.mkIf config.dgramop.desktop.enable {
    # X11 and i3
    services.xserver = {
      enable = true;

      desktopManager = {
        xterm.enable = false;
        wallpaper.mode = "fill";
      };

      displayManager.lightdm = {
        enable = true;
        background = ./bg.jpeg;
      };

      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          rofi
          i3status
        ];
      };

      xkb = {
        layout = "us";
        variant = "";
      };
    };

    services.displayManager.defaultSession = "none+i3";
    programs.i3lock.enable = true;

    # Input
    services.libinput.enable = true;

    # Printing
    services.printing.enable = true;

    # Audio via pipewire
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Desktop packages
    environment.systemPackages = with pkgs; [
      alacritty
      arandr
      nautilus
    ];

    programs.firefox.enable = true;
  };
}
