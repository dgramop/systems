# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.buildMachines = [
    {
      system = "x86_64-linux";
      sshUser = "builder";
      hostName = "nixos-builder";
    }
  ];
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "dgramop-specter-dev"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.extraHosts = ''
    god.sitl 192.168.100.10
    mn.sitl 192.168.100.11
    sn.sitl 192.168.100.12
  '';

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  services.tailscale.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        rofi
        i3status
      ];
    };

  };

  services.libinput = {
    enable = true;
    touchpad.tapping = false;
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  services.datadog-agent = {
    enable = true;
    apiKeyFile = "/var/dhruv/datadog.key";
    site = "us5.datadoghq.com";
    extraConfig = {
      use_dogstatsd = true;
      dogstatsd_port = 8125;
      dogstatsd_non_local_traffic = true;
    };
 };

  services.displayManager.defaultSession = "none+i3";
  programs.i3lock.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dgramop = {
    isNormalUser = true;
    description = "Dhruv Gramopadhye";
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" "libvirt" "kvm" "dialout" ];
    packages = with pkgs; [ git ];
  };
  users.groups.dialout = {};

  environment.shellAliases.vim = "${pkgs.helix}/bin/hx";
  environment.systemPackages = with pkgs; [
    helix
    alacritty
    firefox
    arandr
    nautilus
  ];

  virtualisation.docker.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
    allowedBridges = [ "virbr-lte" "virbr-halow" ];
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.libvirt.unix.manage" &&
          subject.isInGroup("libvirtd")) {
        return polkit.Result.YES;
      }
    });
  '';

  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
