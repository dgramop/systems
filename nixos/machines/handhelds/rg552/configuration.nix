{ config, lib, pkgs, rg552-nixos, ... }:

let
  # onboard ships 10_onboard-default-settings.gschema.override, which sets
  # docking-enabled=true, and a docked window ignores --size/-x/-y entirely --
  # it derives its rect from dock-expand (full screen width) and dock-height.
  # So dock-height is the only lever that resizes the keyboard, and its schema
  # default of 205px gives ~2mm key rows on this panel: X presents 1920x1152
  # (the DSI panel is 1152x1920 rotated left) on a ~5.4" display, so ~417 DPI.
  # Compact is 115 layout units tall at ~19 units per key row, so 760px puts a
  # row at 760/115*19 ~= 125px ~= 7.6mm, and still leaves room above for the
  # login dialog.
  #
  # Set as a schema default rather than with `gsettings set` because the greeter
  # runs as lightdm, which has no writable dconf database, so a write would be
  # silently dropped. GSETTINGS_SCHEMA_DIR outranks the XDG_DATA_DIRS entry
  # onboard's own wrapper prepends, so these defaults win.
  onboardSchemas = pkgs.runCommand "onboard-schemas-rg552" {
    nativeBuildInputs = [ pkgs.glib ];
  } ''
    mkdir -p $out
    cp ${pkgs.onboard}/share/gsettings-schemas/onboard-*/glib-2.0/schemas/*.xml $out/
    cp ${pkgs.onboard}/share/gsettings-schemas/onboard-*/glib-2.0/schemas/*.override $out/
    cp ${onboardOverride} $out/20_rg552-geometry.gschema.override
    glib-compile-schemas $out
  '';

  onboardOverride = pkgs.writeText "20_rg552-geometry.gschema.override" ''
    [org.onboard.window.landscape]
    dock-height=760

    [org.onboard.window.portrait]
    dock-height=760
  '';

  onboardCmd = pkgs.writeShellScript "onboard-rg552" ''
    export GSETTINGS_SCHEMA_DIR=${onboardSchemas}
    exec ${pkgs.onboard}/bin/onboard "$@"
  '';
in
{
  imports = [
    rg552-nixos.nixosModules.default
    ../../../modules/tailscale-ssh.nix
  ];

  networking.hostName = "rg552";

  # Run `tailscale up` once to register the node.
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # rg552-nixos defaults to `ly`, a TUI greeter with no on-screen keyboard, so
  # on a device with no physical keys for text there is no way to type a
  # password. lightdm-gtk-greeter can spawn one, and `a11y-states = +keyboard`
  # starts it shown rather than behind the a11y toggle, which is a hard target
  # to hit on a 5" touchscreen.
  services.displayManager.ly.enable = false;
  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.gtk = {
      enable = true;
      # The login dialog defaults to vertically centred, which the 760px
      # keyboard would cover -- onboard's shipped override also sets
      # force-to-top, so the keyboard wins the stacking order and the password
      # field would be unreachable. Park the dialog in the upper fifth instead.
      extraConfig = ''
        keyboard = ${onboardCmd}
        a11y-states = +keyboard
        position = 50%,center 20%,center
      '';
    };
  };

  # onboard is the GTK/X11 on-screen keyboard; squeekboard and wvkbd are
  # Wayland-only and this session is X11.
  environment.systemPackages = [ pkgs.onboard ];

  # Written out by hand rather than reusing onboard's own desktop file, so a
  # rename upstream cannot silently drop the autostart.
  environment.etc."xdg/autostart/onboard.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Onboard
    Exec=${onboardCmd}
    X-GNOME-Autostart-enabled=true
  '';

  # The eMMC loses writes under HS400 enhanced strobe: CQE times out, recovery
  # fails, and ext4 reports unwritten extents it cannot convert. rg552-nixos
  # enables both HS400 modes on the sdhci node, so strip them and let the card
  # negotiate HS200. A devicetree overlay cannot express this -- nixpkgs applies
  # overlays with libfdt, which has no /delete-property/ -- hence patching the
  # compiled dtb. The greps make this fail loudly if the properties ever move.
  hardware.deviceTree.dtbSource = pkgs.runCommand "rg552-dtbs-no-hs400" {
    nativeBuildInputs = [ pkgs.dtc ];
  } ''
    cp -r ${config.boot.kernelPackages.kernel}/dtbs $out
    chmod -R u+w $out
    dtb=$out/rockchip/rk3399-anbernic-rg552.dtb
    dtc -I dtb -O dts "$dtb" -o dt.dts
    grep -q 'mmc-hs400-enhanced-strobe;' dt.dts
    grep -q 'mmc-hs400-1_8v;' dt.dts
    sed -i '/mmc-hs400-enhanced-strobe;/d; /mmc-hs400-1_8v;/d' dt.dts
    dtc -I dts -O dtb dt.dts -o "$dtb"
  '';

  system.stateVersion = "25.05";
}
