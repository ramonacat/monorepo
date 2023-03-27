{ lib, modulesPath, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  config = {
    boot.supportedFilesystems = [ "bcachefs" ];
    boot.initrd.supportedFilesystems = [ "bcachefs" ];

    boot.kernelPatches = [
      {
        # iotop requires this option to be set
        name = "task-delay-acct";
        patch = null;
        extraConfig = ''
          TASK_DELAY_ACCT y
        '';
      }
      {
        # this is to hopefully make windows audio happier
        name = "scheduler-fast";
        patch = null;
        extraConfig = ''
          HZ 1000
          PREEMPT_VOLUNTARY n
          PREEMPT y
        '';
      }
    ];

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
    ];

    programs.zsh.enable = true;

    console.keyMap = "pl";
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [ "nix-command flakes" ];
    system.stateVersion = "22.11";
  };
}
