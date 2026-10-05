{ config, lib, pkgs, rg552-nixos, ... }:

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
      extraConfig = ''
        keyboard = ${pkgs.onboard}/bin/onboard
        a11y-states = +keyboard
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
    Exec=${pkgs.onboard}/bin/onboard
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
