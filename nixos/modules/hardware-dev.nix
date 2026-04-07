{config, lib, pkgs, ...}:
{
  options = {
    dgramop.hardware-dev.enable = lib.mkEnableOption "Enable hardware development tools";
  };

  config = lib.mkIf config.dgramop.hardware-dev.enable {
    environment.systemPackages = with pkgs; [
      # Serial terminals
      picocom
      minicom
      screen

      # USB utilities
      usbutils
    ];

    # Ensure dialout group exists for serial access
    users.groups.dialout = {};
  };
}
