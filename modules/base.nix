{ nixpkgs }:
{ lib, modulesPath, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  config =
    let
      nixpkgsPath = "/etc/channels/nixpkgs";
    in
    {
      # this service does nothing useful but breaks rebuilds if it's restarted
      # https://github.com/NixOS/nixpkgs/issues/180175
      systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
      boot.kernelParams = [
        # this is needed for iotop
        "delayacct"
      ];
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
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
      nix.settings.experimental-features = [ "nix-command flakes" ];
      system.stateVersion = "22.11";

      nix.registry.nixpkgs.flake = nixpkgs;

      # alter nixPath so legacy commands like nix-shell can find nixpkgs.
      nix.nixPath = [
        "nixpkgs=${nixpkgsPath}"
      ];
      systemd.tmpfiles.rules = [
        "L+ ${nixpkgsPath}  - - - - ${nixpkgs}"
      ];
    };
}
