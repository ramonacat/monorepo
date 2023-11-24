{ lib, modulesPath, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  config = {
    boot.kernelParams = [
      # this is needed for iotop
      "delayacct"
    ];
    security.sudo.wheelNeedsPassword = false;
    nix.settings.trusted-users = [ "@wheel" ];

    networking.useDHCP = false;
    time.timeZone = "Europe/Berlin";
    i18n.defaultLocale = "en_GB.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "de_DE.UTF-8";
      LC_IDENTIFICATION = "de_DE.UTF-8";
      LC_MEASUREMENT = "de_DE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
      LC_NAME = "de_DE.UTF-8";
      LC_NUMERIC = "de_DE.UTF-8";
      LC_PAPER = "de_DE.UTF-8";
      LC_TELEPHONE = "de_DE.UTF-8";
      LC_TIME = "de_DE.UTF-8";
    };

    environment.systemPackages = with pkgs; [
      vim
      gnupg
      git
      htop
      sysstat
      iotop
      tmux
    ];

    networking.networkmanager.enable = true;
    networking.wireless.enable = false;

    programs.zsh.enable = true;

    console.keyMap = "pl";
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [ "nix-command flakes" ];
    system.stateVersion = "22.11";
  };
}
